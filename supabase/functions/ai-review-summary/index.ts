// CHỐT HỜI — Edge Function: ai-review-summary (Phase 5.3B)
// Analyzes real marketplace reviews for ONE product and upserts public.review_summaries.
// OPENAI_API_KEY from Edge secrets — never from Flutter.
// Writes with service role (anon cannot insert due to RLS).

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

const OPENAI_TIMEOUT_MS = 25_000;
const OPENAI_MODEL = "gpt-4o-mini";
const MAX_REVIEWS = 40;

function corsHeaders(req: Request): Record<string, string> {
  const origin = req.headers.get("Origin") ?? "";
  const allowed =
    origin.startsWith("http://localhost") ||
    origin.startsWith("http://127.0.0.1") ||
    origin.endsWith(".supabase.co")
      ? origin || "*"
      : origin || "*";

  return {
    "Access-Control-Allow-Origin": allowed,
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
  };
}

type ReviewIn = {
  rating?: number;
  title?: string | null;
  content?: string | null;
  verifiedPurchase?: boolean;
  sentiment?: string | null;
  authorName?: string | null;
  reviewDate?: string | null;
};

type ProductIn = {
  id?: string;
  name?: string;
  brand?: string;
};

type SummaryOut = {
  summary: string;
  pros: string[];
  cons: string[];
  highlights: string[];
  warnings: string[];
  sentiment: "positive" | "neutral" | "negative";
  confidence: number;
  totalReviews: number;
  aiScore: number | null;
  model: string;
  generatedAt: string;
};

function jsonResponse(req: Request, body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders(req), "Content-Type": "application/json" },
  });
}

function asStrings(value: unknown, max = 6): string[] {
  if (!Array.isArray(value)) return [];
  return value.map(String).map((s) => s.trim()).filter(Boolean).slice(0, max);
}

function normalizeSentiment(raw: unknown): "positive" | "neutral" | "negative" {
  const value = String(raw ?? "neutral").trim().toLowerCase();
  if (value === "positive" || value === "negative" || value === "neutral") return value;
  if (value.includes("pos")) return "positive";
  if (value.includes("neg")) return "negative";
  return "neutral";
}

function statsFallback(product: ProductIn, reviews: ReviewIn[], totalReviews: number): SummaryOut {
  if (reviews.length === 0) {
    return {
      summary: "Chưa đủ dữ liệu để phân tích đánh giá.",
      pros: [],
      cons: [],
      highlights: [],
      warnings: [],
      sentiment: "neutral",
      confidence: 0,
      totalReviews,
      aiScore: null,
      model: "fallback",
      generatedAt: new Date().toISOString(),
    };
  }

  const avg = reviews.reduce((s, r) => s + Number(r.rating || 0), 0) / reviews.length;
  let positive = 0;
  let neutral = 0;
  let negative = 0;
  for (const r of reviews) {
    const sentiment = String(r.sentiment ?? "").toLowerCase();
    const rating = Number(r.rating || 0);
    if (sentiment === "positive" || rating >= 4) positive++;
    else if (sentiment === "negative" || rating <= 2) negative++;
    else neutral++;
  }
  const sentiment = positive >= negative && positive >= neutral
    ? "positive"
    : negative > positive
    ? "negative"
    : "neutral";

  const c5 = reviews.filter((r) => Number(r.rating) === 5).length;
  const c4 = reviews.filter((r) => Number(r.rating) === 4).length;
  const c3 = reviews.filter((r) => Number(r.rating) === 3).length;
  const cLow = reviews.filter((r) => Number(r.rating) <= 2).length;

  return {
    summary:
      `Dựa trên ${totalReviews} đánh giá thực tế của ${product.name ?? "sản phẩm"}, ` +
      `điểm trung bình ${avg.toFixed(1)}/5. Phân bố: ${c5}×5★, ${c4}×4★, ${c3}×3★, ${cLow}×≤2★. ` +
      `AI tạm thời không khả dụng nên chưa có tóm tắt nội dung chi tiết.`,
    pros: [],
    cons: [],
    highlights: [
      ...(positive > 0 ? [`${positive} đánh giá mang sắc thái tích cực.`] : []),
      ...(neutral > 0 ? [`${neutral} đánh giá mang sắc thái trung lập.`] : []),
    ],
    warnings: [
      ...(negative > 0 ? [`${negative} đánh giá mang sắc thái tiêu cực.`] : []),
      "Chưa tạo được tóm tắt AI từ nội dung review — chỉ thống kê từ database.",
    ],
    sentiment,
    confidence: totalReviews >= 10 ? 0.55 : 0.35,
    totalReviews,
    aiScore: Math.round((avg / 5) * 100),
    model: "fallback-stats",
    generatedAt: new Date().toISOString(),
  };
}

function sanitize(raw: Record<string, unknown>, totalReviews: number, model: string): SummaryOut {
  const confidenceRaw = raw.confidence;
  const confidence = typeof confidenceRaw === "number"
    ? Math.max(0, Math.min(1, confidenceRaw))
    : typeof confidenceRaw === "string"
    ? Math.max(0, Math.min(1, Number(confidenceRaw) || 0))
    : 0.5;

  const summary = typeof raw.summary === "string" && raw.summary.trim()
    ? raw.summary.trim()
    : "Chưa đủ dữ liệu để phân tích đánh giá.";

  let aiScore: number | null = null;
  if (typeof raw.aiScore === "number") aiScore = Math.round(Math.max(0, Math.min(100, raw.aiScore)));
  else if (typeof raw.ai_score === "number") aiScore = Math.round(Math.max(0, Math.min(100, raw.ai_score)));

  return {
    summary,
    pros: asStrings(raw.pros, 6),
    cons: asStrings(raw.cons, 6),
    highlights: asStrings(raw.highlights, 5),
    warnings: asStrings(raw.warnings, 5),
    sentiment: normalizeSentiment(raw.sentiment),
    confidence,
    totalReviews,
    aiScore,
    model,
    generatedAt: new Date().toISOString(),
  };
}

const SYSTEM_PROMPT = `Bạn là trợ lý phân tích đánh giá sản phẩm của CHỐT HỜI (app so sánh giá Việt Nam).

Nhiệm vụ: đọc các review THẬT được cung cấp và trả về JSON STRICT (không markdown):
{
  "summary": string,
  "pros": string[],
  "cons": string[],
  "highlights": string[],
  "warnings": string[],
  "sentiment": "positive" | "neutral" | "negative",
  "confidence": number,
  "aiScore": number
}

Quy tắc:
- Chỉ dùng thông tin xuất hiện trong reviews. KHÔNG bịa thông số, giá, marketplace, hay trải nghiệm không có trong input.
- Viết tiếng Việt, ngắn gọn, trung lập.
- pros/cons: tối đa 5–6 ý, cụ thể.
- highlights: điểm được nhiều người nhắc đến.
- warnings: rủi ro / phàn nàn lặp lại.
- sentiment chỉ một trong: positive, neutral, negative.
- confidence từ 0 đến 1.
- aiScore 0–100 phản ánh mức độ tích cực tổng thể (không phải Chốt Hời Score mua hàng).
- Nếu reviews mâu thuẫn, nêu cả hai phía trong summary/warnings.`;

async function analyzeWithOpenAi(
  product: ProductIn,
  reviews: ReviewIn[],
  totalReviews: number,
  apiKey: string,
): Promise<SummaryOut> {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), OPENAI_TIMEOUT_MS);
  try {
    const compact = reviews.slice(0, MAX_REVIEWS).map((r) => ({
      rating: Number(r.rating || 0),
      title: r.title ?? "",
      content: (r.content ?? "").slice(0, 500),
      verifiedPurchase: !!r.verifiedPurchase,
      sentiment: r.sentiment ?? null,
    }));

    const response = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      signal: controller.signal,
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: OPENAI_MODEL,
        temperature: 0.2,
        response_format: { type: "json_object" },
        messages: [
          { role: "system", content: SYSTEM_PROMPT },
          {
            role: "user",
            content: JSON.stringify({
              product: { id: product.id, name: product.name, brand: product.brand },
              totalReviewCount: totalReviews,
              reviewsSent: compact.length,
              reviews: compact,
            }),
          },
        ],
      }),
    });

    if (!response.ok) throw new Error(`OpenAI HTTP ${response.status}`);
    const body = await response.json();
    const content = body.choices?.[0]?.message?.content;
    if (!content || typeof content !== "string") throw new Error("Empty OpenAI response");
    const parsed = JSON.parse(content) as Record<string, unknown>;
    return sanitize(parsed, totalReviews, OPENAI_MODEL);
  } finally {
    clearTimeout(timer);
  }
}

async function upsertSummary(productId: string, summary: SummaryOut): Promise<void> {
  const url = Deno.env.get("SUPABASE_URL");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!url || !serviceKey) {
    console.warn("Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY — skip DB write");
    return;
  }

  const admin = createClient(url, serviceKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const meta = JSON.stringify({
    highlights: summary.highlights,
    warnings: summary.warnings,
    sentiment: summary.sentiment,
    confidence: summary.confidence,
  });

  const row = {
    product_id: productId,
    total_reviews: summary.totalReviews,
    positive_summary: summary.summary,
    negative_summary: meta,
    pros: summary.pros,
    cons: summary.cons,
    ai_score: summary.aiScore,
    model: summary.model,
    generated_at: summary.generatedAt,
  };

  const { data: existing, error: selectError } = await admin
    .from("review_summaries")
    .select("id")
    .eq("product_id", productId)
    .order("generated_at", { ascending: false })
    .limit(1);

  if (selectError) {
    console.warn("select review_summaries failed", selectError.message);
    return;
  }

  if (existing && existing.length > 0) {
    const { error } = await admin.from("review_summaries").update(row).eq("id", existing[0].id);
    if (error) console.warn("update review_summaries failed", error.message);
    // Remove older duplicates for this product (keep newest updated row).
    await admin
      .from("review_summaries")
      .delete()
      .eq("product_id", productId)
      .neq("id", existing[0].id);
  } else {
    const { error } = await admin.from("review_summaries").insert(row);
    if (error) console.warn("insert review_summaries failed", error.message);
  }
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders(req) });
  }
  if (req.method !== "POST") {
    return jsonResponse(req, { success: false, code: "METHOD_NOT_ALLOWED" }, 405);
  }

  let body: Record<string, unknown> = {};
  try {
    body = await req.json();
  } catch {
    return jsonResponse(req, { success: false, code: "BAD_JSON" }, 400);
  }

  const product = (body.product && typeof body.product === "object" ? body.product : {}) as ProductIn;
  const reviews = Array.isArray(body.reviews) ? (body.reviews as ReviewIn[]) : [];
  const totalReviews = typeof body.totalReviewCount === "number"
    ? body.totalReviewCount
    : reviews.length;

  if (!product.id) {
    return jsonResponse(req, { success: false, code: "MISSING_PRODUCT_ID" }, 400);
  }

  let source = "fallback";
  let summary = statsFallback(product, reviews, totalReviews);

  try {
    const apiKey = Deno.env.get("OPENAI_API_KEY");
    if (apiKey && reviews.length > 0) {
      summary = await analyzeWithOpenAi(product, reviews, totalReviews, apiKey);
      source = "openai";
    } else if (!apiKey) {
      source = "fallback";
    } else {
      source = "empty";
      summary = statsFallback(product, [], totalReviews);
    }
  } catch (error) {
    const message = error instanceof Error ? error.message : "Unknown error";
    summary = statsFallback(product, reviews, totalReviews);
    source = "fallback";
    await upsertSummary(product.id, summary).catch(() => {});
    return jsonResponse(req, {
      success: true,
      data: summary,
      source,
      warning: message,
    });
  }

  try {
    await upsertSummary(product.id, summary);
  } catch (error) {
    console.warn("upsert threw", error);
  }

  return jsonResponse(req, { success: true, data: summary, source });
});
