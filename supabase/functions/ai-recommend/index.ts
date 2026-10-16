// CHỐT HỜI — Edge Function: ai-recommend (Phase 5.2B)
// Explains an already-computed Chốt Hời score for ONE product (#1 pick).
// OPENAI_API_KEY from Edge secrets only — never from Flutter.
// Score in the request is authoritative; AI must not change it.

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

const OPENAI_TIMEOUT_MS = 20_000;
const OPENAI_MODEL = "gpt-4o-mini";

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

type Intent = {
  category?: string | null;
  brands?: string[];
  maxPrice?: number | null;
  minPrice?: number | null;
  minRam?: number | null;
  useCase?: string | null;
  keyword?: string | null;
  features?: string[];
};

type ProductPayload = {
  name?: string;
  brand?: string;
  currentPrice?: number;
  originalPrice?: number | null;
  rating?: number;
  reviewCount?: number;
  chotHoiScore?: number;
  score?: number;
  priceHistory?: unknown[];
  pros?: string[];
  cons?: string[];
  specsSummary?: string;
  specs?: Record<string, unknown>;
  ramGb?: number | null;
  useCases?: string[];
  categoryId?: string;
  priceScore?: number;
  specScore?: number;
  reviewScore?: number;
  priceHistoryScore?: number;
  preferenceScore?: number;
};

type Explanation = {
  summary: string;
  verdict: string;
  reasons: string[];
  warnings: string[];
  priceInsight: string;
  reviewInsight: string;
  matchInsight: string;
  /** Echo only — Flutter keeps its deterministic score. */
  score: number;
};

function jsonResponse(req: Request, body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders(req), "Content-Type": "application/json" },
  });
}

function verdictForScore(score: number): string {
  if (score >= 80) return "ĐÁNG MUA";
  if (score >= 60) return "CÂN NHẮC";
  return "CHƯA NÊN MUA";
}

function millions(value: number): string {
  const m = value / 1_000_000;
  const text = Number.isInteger(m) ? String(m) : m.toFixed(2).replace(/\.?0+$/, "").replace(".", ",");
  return `${text} triệu`;
}

function asScore(product: ProductPayload): number {
  const raw = product.chotHoiScore ?? product.score ?? 0;
  const n = typeof raw === "number" ? raw : Number(raw);
  if (!Number.isFinite(n)) return 0;
  return Math.max(0, Math.min(100, Math.round(n)));
}

function hasHistory(product: ProductPayload): boolean {
  return Array.isArray(product.priceHistory) && product.priceHistory.length > 0;
}

function hasReviews(product: ProductPayload): boolean {
  const rating = Number(product.rating ?? 0);
  const count = Number(product.reviewCount ?? 0);
  return rating > 0 || count > 0;
}

function fallbackExplain(product: ProductPayload, intent: Intent): Explanation {
  const score = asScore(product);
  const verdict = verdictForScore(score);
  const price = Number(product.currentPrice ?? 0);
  const max = intent.maxPrice ?? null;
  const reasons: string[] = [];
  const warnings: string[] = [];

  if (Array.isArray(product.pros)) {
    for (const p of product.pros.map(String).filter(Boolean).slice(0, 2)) reasons.push(p);
  }
  if (max != null && price > 0 && price <= max) reasons.push("Giá nằm trong ngân sách đã nêu");
  if (hasReviews(product) && Number(product.rating) >= 4.5) {
    reasons.push(`Rating tốt ${Number(product.rating).toFixed(1)}★`);
  }
  if (intent.brands?.length && product.brand && intent.brands.includes(product.brand)) {
    reasons.push(`Thương hiệu ${product.brand} đúng ưu tiên`);
  }

  if (!hasHistory(product)) warnings.push("Chưa có đủ dữ liệu lịch sử giá.");
  if (!hasReviews(product)) warnings.push("Chưa có đủ dữ liệu đánh giá.");
  if (Array.isArray(product.cons)) {
    for (const c of product.cons.map(String).filter(Boolean).slice(0, 2)) warnings.push(c);
  }

  let priceInsight = price > 0 ? `Giá hiện tại ${millions(price)}.` : "Chưa có đủ dữ liệu giá.";
  if (max != null && price > 0) {
    priceInsight = price <= max
      ? `${millions(price)}, thấp hơn ngân sách ${millions(max)}.`
      : `${millions(price)}, vượt ngân sách ${millions(max)}.`;
  }

  const reviewInsight = hasReviews(product)
    ? `${Number(product.rating ?? 0).toFixed(1)}★ từ ${Number(product.reviewCount ?? 0)} lượt đánh giá.`
    : "Chưa có đủ dữ liệu đánh giá.";

  const useLabel = intent.useCase === "coding" || intent.useCase === "code"
    ? "lập trình"
    : intent.useCase === "gaming"
    ? "chơi game"
    : intent.useCase === "office"
    ? "văn phòng"
    : "nhu cầu của bạn";

  const summary = score >= 80
    ? `Phù hợp tốt với nhu cầu ${useLabel} — điểm khớp ${score}/100.`
    : score >= 60
    ? `Khá phù hợp với nhu cầu ${useLabel} (điểm ${score}/100).`
    : `Có thể cân nhắc cho nhu cầu ${useLabel} (điểm ${score}/100).`;

  return {
    summary,
    verdict,
    reasons: reasons.slice(0, 4),
    warnings: warnings.slice(0, 3),
    priceInsight,
    reviewInsight,
    matchInsight: `Điểm Chốt Hời deterministic ${score}/100; AI không thay đổi điểm này.`,
    score,
  };
}

function sanitizeExplanation(raw: Record<string, unknown>, score: number): Explanation {
  const fallback = fallbackExplain({ chotHoiScore: score }, {});
  const strings = (value: unknown): string[] =>
    Array.isArray(value) ? value.map(String).map((s) => s.trim()).filter(Boolean) : [];

  const summary = typeof raw.summary === "string" && raw.summary.trim()
    ? raw.summary.trim()
    : fallback.summary;

  return {
    summary,
    verdict: verdictForScore(score), // never trust AI verdict against score bands
    reasons: strings(raw.reasons).slice(0, 5),
    warnings: strings(raw.warnings).slice(0, 4),
    priceInsight: typeof raw.priceInsight === "string" && raw.priceInsight.trim()
      ? raw.priceInsight.trim()
      : fallback.priceInsight,
    reviewInsight: typeof raw.reviewInsight === "string" && raw.reviewInsight.trim()
      ? raw.reviewInsight.trim()
      : fallback.reviewInsight,
    matchInsight: typeof raw.matchInsight === "string" && raw.matchInsight.trim()
      ? raw.matchInsight.trim()
      : fallback.matchInsight,
    score,
  };
}

const SYSTEM_PROMPT = `Bạn là trợ lý mua sắm của CHỐT HỜI (ứng dụng so sánh giá Việt Nam).

Nhiệm vụ: GIẢI THÍCH Chốt Hời Score đã được hệ thống tính sẵn (deterministic).
Bạn KHÔNG được thay đổi, làm tròn lại, hay đề xuất score khác.

Trả về ĐÚNG JSON (không markdown) với schema:
{
  "summary": string,
  "verdict": "ĐÁNG MUA" | "CÂN NHẮC" | "CHƯA NÊN MUA",
  "reasons": string[],
  "warnings": string[],
  "priceInsight": string,
  "reviewInsight": string,
  "matchInsight": string
}

Quy tắc verdict theo score đã cho:
- score >= 80 → "ĐÁNG MUA"
- 60–79 → "CÂN NHẮC"
- < 60 → "CHƯA NÊN MUA"

Nội dung phải:
- giải thích vì sao sản phẩm đạt score hiện tại
- giải thích giá so với ngân sách (nếu có)
- giải thích rating/review nếu có
- giải thích price history nếu có
- giải thích mức độ phù hợp với nhu cầu (useCase/brands/RAM…)
- nêu cảnh báo khi dữ liệu thiếu
- không bịa thông số, review, price history, marketplace, URL
- nếu thiếu dữ liệu: viết rõ "Chưa có đủ dữ liệu..." — không suy đoán
- viết tiếng Việt, ngắn gọn, thân thiện

RAM (dùng product.specs.ram / product.ramGb — KHÔNG bịa):
- nếu ramGb >= intent.minRam: nói "RAM {n}GB đáp ứng yêu cầu tối thiểu."
- nếu ramGb < intent.minRam: nói "RAM {n}GB thấp hơn yêu cầu tối thiểu {minRam}GB."
- nếu không có specs.ram / ramGb null: nói "Chưa có dữ liệu RAM để xác minh."
- KHÔNG dùng dung lượng ổ cứng (storage) hay kích thước màn hình làm RAM.`;

async function explainWithOpenAi(
  product: ProductPayload,
  intent: Intent,
  apiKey: string,
): Promise<Explanation> {
  const score = asScore(product);
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), OPENAI_TIMEOUT_MS);

  try {
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
              chotHoiScore: score,
              product: {
                name: product.name ?? "",
                brand: product.brand ?? "",
                currentPrice: product.currentPrice ?? null,
                originalPrice: product.originalPrice ?? null,
                rating: product.rating ?? 0,
                reviewCount: product.reviewCount ?? 0,
                priceHistoryPresent: hasHistory(product),
                priceHistoryCount: Array.isArray(product.priceHistory) ? product.priceHistory.length : 0,
                // Send compact history samples only (no invention if empty)
                priceHistorySample: hasHistory(product)
                  ? product.priceHistory!.slice(-6)
                  : [],
                pros: product.pros ?? [],
                cons: product.cons ?? [],
                specsSummary: product.specsSummary ?? "",
                specs: product.specs ?? {},
                ramGb: product.ramGb ?? null,
                useCases: product.useCases ?? [],
                scoreBreakdown: {
                  priceScore: product.priceScore,
                  specScore: product.specScore,
                  reviewScore: product.reviewScore,
                  priceHistoryScore: product.priceHistoryScore,
                  preferenceScore: product.preferenceScore,
                },
              },
              intent,
              rules: {
                doNotChangeScore: true,
                missingHistoryMeans: "Chưa có đủ dữ liệu lịch sử giá",
                missingReviewsMeans: "Chưa có đủ dữ liệu đánh giá",
              },
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
    return sanitizeExplanation(parsed, score);
  } finally {
    clearTimeout(timer);
  }
}

function readProduct(body: Record<string, unknown>): ProductPayload | null {
  if (body.product && typeof body.product === "object") {
    return body.product as ProductPayload;
  }
  // Legacy shortlist: explain only the first / best candidate.
  if (Array.isArray(body.candidates) && body.candidates.length > 0) {
    const first = body.candidates[0] as Record<string, unknown>;
    return {
      name: typeof first.name === "string" ? first.name : "",
      brand: typeof first.brand === "string" ? first.brand : "",
      currentPrice: typeof first.price === "number" ? first.price : typeof first.currentPrice === "number" ? first.currentPrice : undefined,
      rating: typeof first.rating === "number" ? first.rating : undefined,
      reviewCount: typeof first.reviewCount === "number" ? first.reviewCount : undefined,
      chotHoiScore: typeof first.score === "number" ? first.score : typeof first.chotHoiScore === "number" ? first.chotHoiScore : undefined,
      priceHistory: Array.isArray(first.priceHistory) ? first.priceHistory : [],
      pros: Array.isArray(first.pros) ? first.pros.map(String) : [],
      cons: Array.isArray(first.cons) ? first.cons.map(String) : [],
      priceScore: typeof first.priceScore === "number" ? first.priceScore : undefined,
      specScore: typeof first.specScore === "number" ? first.specScore : undefined,
      reviewScore: typeof first.reviewScore === "number" ? first.reviewScore : undefined,
      priceHistoryScore: typeof first.priceHistoryScore === "number" ? first.priceHistoryScore : undefined,
      preferenceScore: typeof first.preferenceScore === "number" ? first.preferenceScore : undefined,
    };
  }
  return null;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders(req) });
  }

  if (req.method !== "POST") {
    return jsonResponse(req, { success: false, code: "METHOD_NOT_ALLOWED", message: "POST only" }, 405);
  }

  let body: Record<string, unknown> = {};
  try {
    body = await req.json();
  } catch {
    return jsonResponse(req, { success: false, code: "BAD_JSON", message: "Invalid JSON body" }, 400);
  }

  const product = readProduct(body);
  if (!product) {
    return jsonResponse(req, { success: false, code: "MISSING_PRODUCT", message: "product is required" }, 400);
  }

  const intent = (body.intent && typeof body.intent === "object" ? body.intent : {}) as Intent;
  const score = asScore(product);

  try {
    const apiKey = Deno.env.get("OPENAI_API_KEY");
    const data = apiKey
      ? await explainWithOpenAi(product, intent, apiKey)
      : fallbackExplain(product, intent);

    return jsonResponse(req, {
      success: true,
      data,
      source: apiKey ? "openai" : "fallback",
      // Echo score so clients can verify AI did not invent a new number.
      chotHoiScore: score,
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : "Unknown error";
    return jsonResponse(req, {
      success: true,
      data: fallbackExplain(product, intent),
      source: "fallback",
      warning: message,
      chotHoiScore: score,
    });
  }
});
