// CHỐT HỜI — Edge Function: ai-agent (Phase 5.4)
// Tool-calling shopping assistant. Numbers come from Supabase tools only.
// OPENAI_API_KEY from Edge secrets — never from Flutter.

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient, type SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

const OPENAI_MODEL = "gpt-4o-mini";
const OPENAI_TIMEOUT_MS = 45_000;
const MAX_TOOL_ROUNDS = 5;

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

function jsonResponse(req: Request, body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders(req), "Content-Type": "application/json" },
  });
}

type AgentResult = {
  success: boolean;
  message: string;
  intent?: string;
  products: Array<Record<string, unknown>>;
  actions: string[];
  sources: string[];
  verdict?: string | null;
  score?: number | null;
  action_required?: string | null;
  code?: string;
};

const SYSTEM_PROMPT = `Bạn là Chốt Hời AI, trợ lý mua sắm của ứng dụng CHỐT HỜI (so sánh giá Việt Nam).

Nguyên tắc bắt buộc:
- Chỉ dùng dữ liệu từ TOOL. Không bịa sản phẩm, giá, rating, review, marketplace, lịch sử giá, score.
- Nếu thiếu dữ liệu: nói rõ "Chưa có đủ dữ liệu...".
- Score chỉ lấy từ GetChotHoiScore — không tự tính/bịa score.
- Trả lời tiếng Việt, ngắn gọn, giúp quyết định mua hay không.
- Phân biệt: dữ liệu thật (giá/rating) vs nhận định (đáng mua hay không dựa trên score tool).

Khi đủ thông tin, trả lời người dùng. Có thể kèm JSON phụ ở cuối trong block:
<<<RESULT>>>
{"intent":"...","verdict":"ĐÁNG MUA|CÂN NHẮC|CHƯA NÊN MUA|null","score":number|null,"productIds":["..."]}
<<<END>>>
`;

const TOOLS = [
  {
    type: "function",
    function: {
      name: "SearchProducts",
      description: "Tìm sản phẩm theo từ khóa, brand, category, khoảng giá từ database CHỐT HỜI.",
      parameters: {
        type: "object",
        properties: {
          keyword: { type: "string" },
          category: { type: "string", description: "slug hoặc tên loại: laptop, dien-thoai, tai-nghe,..." },
          brands: { type: "array", items: { type: "string" } },
          minPrice: { type: "number" },
          maxPrice: { type: "number" },
          limit: { type: "number" },
        },
      },
    },
  },
  {
    type: "function",
    function: {
      name: "ComparePrices",
      description: "So sánh giá hiện tại của một sản phẩm trên các sàn (marketplace_products).",
      parameters: {
        type: "object",
        properties: { productId: { type: "string" } },
        required: ["productId"],
      },
    },
  },
  {
    type: "function",
    function: {
      name: "GetPriceHistory",
      description: "Lấy lịch sử giá của listing rẻ nhất (hoặc marketplaceProductId chỉ định).",
      parameters: {
        type: "object",
        properties: {
          productId: { type: "string" },
          marketplaceProductId: { type: "string" },
          limit: { type: "number" },
        },
      },
    },
  },
  {
    type: "function",
    function: {
      name: "GetReviews",
      description: "Lấy review thô từ mọi marketplace của sản phẩm.",
      parameters: {
        type: "object",
        properties: {
          productId: { type: "string" },
          limit: { type: "number" },
        },
        required: ["productId"],
      },
    },
  },
  {
    type: "function",
    function: {
      name: "GetReviewSummary",
      description: "Lấy AI review summary đã cache trong review_summaries.",
      parameters: {
        type: "object",
        properties: { productId: { type: "string" } },
        required: ["productId"],
      },
    },
  },
  {
    type: "function",
    function: {
      name: "GetChotHoiScore",
      description: "Tính Chốt Hời Score deterministic cho sản phẩm theo intent (budget/brand/RAM/useCase).",
      parameters: {
        type: "object",
        properties: {
          productId: { type: "string" },
          maxPrice: { type: "number" },
          brands: { type: "array", items: { type: "string" } },
          minRam: { type: "number" },
          useCase: { type: "string" },
        },
        required: ["productId"],
      },
    },
  },
  {
    type: "function",
    function: {
      name: "SaveProduct",
      description: "Lưu sản phẩm vào danh sách yêu thích của user đang đăng nhập.",
      parameters: {
        type: "object",
        properties: { productId: { type: "string" } },
        required: ["productId"],
      },
    },
  },
  {
    type: "function",
    function: {
      name: "CreatePriceAlert",
      description: "Tạo/cập nhật cảnh báo giá khi sản phẩm xuống targetPrice (VND).",
      parameters: {
        type: "object",
        properties: {
          productId: { type: "string" },
          targetPrice: { type: "number" },
        },
        required: ["productId", "targetPrice"],
      },
    },
  },
] as const;

function adminClient(): SupabaseClient {
  const url = Deno.env.get("SUPABASE_URL")!;
  const key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  return createClient(url, key, { auth: { persistSession: false, autoRefreshToken: false } });
}

function userClient(req: Request): SupabaseClient | null {
  const url = Deno.env.get("SUPABASE_URL");
  const anon = Deno.env.get("SUPABASE_ANON_KEY");
  const auth = req.headers.get("Authorization");
  if (!url || !anon || !auth) return null;
  return createClient(url, anon, {
    global: { headers: { Authorization: auth } },
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

function ramGb(specs: Record<string, unknown> | null | undefined): number | null {
  const raw = specs?.ram;
  if (raw == null) return null;
  const m = String(raw).match(/(\d+)\s*(gb|g)?/i);
  return m ? Number(m[1]) : null;
}

function mapProduct(row: Record<string, unknown>) {
  const brand = row.brands as { name?: string } | null;
  const category = row.categories as { slug?: string; name?: string } | null;
  const listings = Array.isArray(row.marketplace_products) ? row.marketplace_products as Record<string, unknown>[] : [];
  const active = listings
    .filter((l) => l.is_active !== false)
    .sort((a, b) => Number(a.current_price) - Number(b.current_price));
  const cheapest = active[0];
  const specs = (row.specs && typeof row.specs === "object" ? row.specs : {}) as Record<string, unknown>;
  return {
    id: row.id,
    name: row.name,
    brand: brand?.name ?? "",
    category: category?.slug ?? "",
    categoryName: category?.name ?? "",
    rating: Number(row.rating ?? 0),
    reviewCount: Number(row.review_count ?? 0),
    currentPrice: cheapest ? Number(cheapest.current_price) : null,
    originalPrice: cheapest ? Number(cheapest.original_price ?? cheapest.current_price) : null,
    marketplaceProductId: cheapest?.id ?? null,
    specs,
    ramGb: ramGb(specs),
    listingCount: active.length,
  };
}

/** Strip Vietnamese diacritics for robust category matching. */
function foldVi(input: string): string {
  return input
    .toLowerCase()
    .replace(/đ/g, "d")
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "");
}

/** Map free-text category / keyword hints → DB `categories.slug`. */
function resolveCategorySlug(raw: string | null | undefined, keyword = ""): string | null {
  const text = foldVi(`${raw ?? ""} ${keyword}`);
  if (!text.trim()) return null;
  // Accept both free text ("dien thoai") and DB slugs ("dien-thoai").
  if (/(laptop|macbook|notebook)/.test(text)) return "laptop";
  if (/(dien[-\s]?thoai|smartphone|\bphone\b|iphone)/.test(text)) return "dien-thoai";
  if (/(tai[-\s]?nghe|headphone|earbuds|airpods)/.test(text)) return "tai-nghe";
  if (/(man[-\s]?hinh|monitor)/.test(text)) return "man-hinh";
  if (/(ban[-\s]?phim|keyboard)/.test(text)) return "ban-phim";
  if (/(chuot|mouse)/.test(text)) return "chuot-may-tinh";
  if (/(smartwatch|dong[-\s]?ho)/.test(text)) return "smartwatch";
  return null;
}

function matchesCategorySlug(productSlug: string, want: string): boolean {
  if (!want) return true;
  if (productSlug === want) return true;
  // Never treat smartwatch as phone.
  if (want === "dien-thoai") return productSlug === "dien-thoai";
  return productSlug === want || productSlug.includes(want);
}

async function searchProducts(db: SupabaseClient, args: Record<string, unknown>) {
  const limit = Math.min(Number(args.limit ?? 8), 20);
  let query = db
    .from("products")
    .select("id,name,slug,rating,review_count,specs,brands(name),categories(slug,name),marketplace_products(id,current_price,original_price,is_active,marketplace_id,marketplaces(code,name))")
    .eq("is_active", true)
    .limit(40);

  const keyword = typeof args.keyword === "string" ? args.keyword.trim() : "";
  // Prefer brand/name tokens; avoid dumping the whole NL sentence into ilike when structured filters exist.
  const brands = Array.isArray(args.brands) ? args.brands.map(String) : [];
  const searchToken = brands[0] ||
    (keyword.length > 0 && keyword.length <= 40 ? keyword : "");
  if (searchToken) {
    query = query.or(`name.ilike.%${searchToken}%,description.ilike.%${searchToken}%`);
  }

  const { data, error } = await query;
  if (error) return { error: error.message, products: [] };

  let products = (data ?? []).map((r) => mapProduct(r as Record<string, unknown>));

  if (brands.length) {
    const lower = brands.map((b) => b.toLowerCase());
    products = products.filter((p) => lower.some((b) => p.brand.toLowerCase().includes(b)));
  }

  const categorySlug = resolveCategorySlug(
    typeof args.category === "string" ? args.category : null,
    keyword,
  );
  if (categorySlug) {
    products = products.filter((p) => matchesCategorySlug(p.category, categorySlug));
  }

  const maxPrice = typeof args.maxPrice === "number" ? args.maxPrice : null;
  const minPrice = typeof args.minPrice === "number" ? args.minPrice : null;
  if (maxPrice != null) products = products.filter((p) => p.currentPrice != null && p.currentPrice! <= maxPrice);
  if (minPrice != null) products = products.filter((p) => p.currentPrice != null && p.currentPrice! >= minPrice);

  products = products.filter((p) => p.currentPrice != null).slice(0, limit);
  return { products, count: products.length, categorySlug };
}

async function comparePrices(db: SupabaseClient, productId: string) {
  const { data, error } = await db
    .from("marketplace_products")
    .select("id,current_price,original_price,is_active,seller_name,rating,review_count,marketplaces(code,name)")
    .eq("product_id", productId)
    .eq("is_active", true)
    .order("current_price");
  if (error) return { error: error.message };
  const offers = (data ?? []).map((row) => {
    const m = row.marketplaces as { code?: string; name?: string } | null;
    return {
      marketplaceProductId: row.id,
      marketplace: m?.name ?? m?.code ?? "unknown",
      code: m?.code ?? null,
      currentPrice: Number(row.current_price),
      originalPrice: row.original_price == null ? null : Number(row.original_price),
      rating: row.rating == null ? null : Number(row.rating),
      reviewCount: Number(row.review_count ?? 0),
      sellerName: row.seller_name,
    };
  });
  return { offers, cheapest: offers[0] ?? null };
}

async function getPriceHistory(db: SupabaseClient, args: Record<string, unknown>) {
  let mpId = typeof args.marketplaceProductId === "string" ? args.marketplaceProductId : null;
  const productId = typeof args.productId === "string" ? args.productId : null;
  if (!mpId && productId) {
    const { data } = await db
      .from("marketplace_products")
      .select("id,current_price")
      .eq("product_id", productId)
      .eq("is_active", true)
      .order("current_price")
      .limit(1);
    mpId = data?.[0]?.id ?? null;
  }
  if (!mpId) return { error: "Không xác định được marketplace_product_id", points: [] };

  const limit = Math.min(Number(args.limit ?? 30), 90);
  const { data, error } = await db
    .from("price_history")
    .select("price,original_price,recorded_at")
    .eq("marketplace_product_id", mpId)
    .order("recorded_at", { ascending: true })
    .limit(limit);
  if (error) return { error: error.message, points: [] };

  const points = (data ?? []).map((p) => ({
    price: Number(p.price),
    originalPrice: p.original_price == null ? null : Number(p.original_price),
    recordedAt: p.recorded_at,
  }));
  if (points.length === 0) return { marketplaceProductId: mpId, points: [], note: "Chưa có đủ dữ liệu lịch sử giá." };

  const prices = points.map((p) => p.price);
  const first = prices[0];
  const last = prices[prices.length - 1];
  const lowest = Math.min(...prices);
  const highest = Math.max(...prices);
  const avg = Math.round(prices.reduce((a, b) => a + b, 0) / prices.length);
  const changePercent = first === 0 ? 0 : ((last - first) / first) * 100;
  return {
    marketplaceProductId: mpId,
    points: points.slice(-12),
    stats: { lowest, highest, average: avg, last, changePercent: Number(changePercent.toFixed(2)) },
  };
}

async function getReviews(db: SupabaseClient, productId: string, limit = 20) {
  const { data: listings } = await db.from("marketplace_products").select("id").eq("product_id", productId).eq("is_active", true);
  const ids = (listings ?? []).map((l) => l.id as string);
  if (!ids.length) return { reviews: [], count: 0 };
  const { data, error } = await db
    .from("reviews")
    .select("rating,title,content,sentiment,verified_purchase,review_date,author_name")
    .in("marketplace_product_id", ids)
    .order("review_date", { ascending: false })
    .limit(Math.min(limit, 40));
  if (error) return { error: error.message, reviews: [] };
  return { reviews: data ?? [], count: (data ?? []).length };
}

async function getReviewSummary(db: SupabaseClient, productId: string) {
  const { data, error } = await db
    .from("review_summaries")
    .select("positive_summary,negative_summary,pros,cons,ai_score,total_reviews,model,generated_at")
    .eq("product_id", productId)
    .order("generated_at", { ascending: false })
    .limit(1);
  if (error) return { error: error.message };
  if (!data?.length) return { summary: null, note: "Chưa có review summary. Hãy mở Product Detail để AI tạo lần đầu." };
  const row = data[0];
  return {
    summary: row.positive_summary,
    pros: row.pros,
    cons: row.cons,
    aiScore: row.ai_score == null ? null : Number(row.ai_score),
    totalReviews: row.total_reviews,
    model: row.model,
    generatedAt: row.generated_at,
    meta: row.negative_summary,
  };
}

/** Mirrors Flutter RecommendationScorer history band (no invented points). */
function priceHistoryScore(currentPrice: number | null, points: Array<{ price: number }>): number {
  if (!points.length || currentPrice == null) return 50;
  const prices = points.map((p) => p.price).filter((n) => Number.isFinite(n));
  if (prices.length < 2) return 50;
  const first = prices[0];
  const last = prices[prices.length - 1];
  const lowest = Math.min(...prices);
  const highest = Math.max(...prices);
  const average = prices.reduce((a, b) => a + b, 0) / prices.length;
  const changePercent = first === 0 ? 0 : ((last - first) / first) * 100;

  let trendScore = 60;
  if (changePercent <= -2) trendScore = Math.max(70, Math.min(100, Math.round(75 + Math.min(20, -changePercent))));
  else if (changePercent >= 2) trendScore = Math.max(20, Math.min(55, Math.round(45 - Math.min(25, changePercent))));

  let valueScore = 50;
  if (average > 0) {
    const cheaperThanAvg = (average - currentPrice) / average;
    valueScore = Math.max(20, Math.min(100, Math.round(50 + cheaperThanAvg * 100)));
  }
  if (lowest > 0 && currentPrice <= Math.round(lowest * 1.02)) valueScore = Math.max(valueScore, 92);
  else if (highest > 0 && currentPrice >= Math.round(highest * 0.98)) valueScore = Math.min(valueScore, 35);

  return Math.max(0, Math.min(100, Math.round(trendScore * 0.55 + valueScore * 0.45)));
}

function scoreProduct(
  product: ReturnType<typeof mapProduct>,
  intent: { maxPrice?: number | null; brands?: string[]; minRam?: number | null; useCase?: string | null },
  extras: { historyPoints?: Array<{ price: number }>; reviewAiScore?: number | null } = {},
) {
  const price = product.currentPrice ?? 0;
  // price 30%
  let priceScore = 80;
  if (intent.maxPrice != null) {
    if (price <= intent.maxPrice) {
      const ratio = intent.maxPrice === 0 ? 1 : price / intent.maxPrice;
      if (ratio >= 0.55 && ratio <= 0.95) priceScore = 100;
      else if (ratio < 0.55) priceScore = Math.round(70 + ratio * 40);
      else priceScore = Math.round(100 - (ratio - 0.95) * 200);
      priceScore = Math.max(70, Math.min(100, priceScore));
    } else {
      const over = (price - intent.maxPrice) / intent.maxPrice;
      priceScore = Math.max(0, Math.min(55, Math.round(60 - over * 120)));
    }
  }

  // spec 25%
  let spec = 40;
  const ram = product.ramGb;
  if (intent.minRam != null) {
    if (ram == null) spec -= 5;
    else if (ram >= intent.minRam) spec += 25;
    else if (ram >= Math.ceil(intent.minRam * 0.75)) spec += 5;
    else spec -= 15;
  }
  if (intent.useCase) {
    const uses = Array.isArray((product.specs as { use_cases?: unknown }).use_cases)
      ? ((product.specs as { use_cases: unknown[] }).use_cases).map(String)
      : [];
    const u = intent.useCase.toLowerCase();
    if (
      uses.some(
        (x) =>
          x.toLowerCase().includes(u) ||
          ((u === "code" || u === "coding") && x.toLowerCase().includes("coding")),
      )
    ) {
      spec += 20;
    }
  }
  spec = Math.max(0, Math.min(100, Math.round(spec)));

  // review 20% — rating/review_count (+ optional review_summaries.ai_score)
  let review = 50;
  const hasRating = product.reviewCount > 0 || product.rating > 0;
  let aiNorm: number | null = null;
  if (typeof extras.reviewAiScore === "number" && extras.reviewAiScore >= 0) {
    aiNorm = extras.reviewAiScore <= 10 ? Math.round(extras.reviewAiScore * 10) : Math.round(extras.reviewAiScore);
    aiNorm = Math.max(0, Math.min(100, aiNorm));
  }
  if (hasRating) {
    const ratingPart = Math.max(0, Math.min(100, (product.rating / 5) * 100));
    const volume = product.reviewCount >= 500 ? 10 : product.reviewCount >= 100 ? 6 : product.reviewCount >= 20 ? 3 : 0;
    review = Math.round(ratingPart * 0.85 + volume + 5);
  }
  if (aiNorm != null) {
    review = hasRating ? Math.round(review * 0.7 + aiNorm * 0.3) : aiNorm;
  }
  if (!hasRating && aiNorm == null) review = 50;

  // history 15% — real price_history or neutral 50
  const history = priceHistoryScore(product.currentPrice, extras.historyPoints ?? []);

  // preference 10%
  let preference = 70;
  if (intent.brands && intent.brands.length) {
    preference = intent.brands.some((b) => product.brand.toLowerCase() === b.toLowerCase()) ? 100 : 25;
  }

  const total = Math.round(priceScore * 0.3 + spec * 0.25 + review * 0.2 + history * 0.15 + preference * 0.1);
  const score = Math.max(0, Math.min(100, total));
  const verdict = score >= 80 ? "ĐÁNG MUA" : score >= 60 ? "CÂN NHẮC" : "CHƯA NÊN MUA";
  return {
    productId: product.id,
    score,
    verdict,
    breakdown: { priceScore, specScore: spec, reviewScore: review, priceHistoryScore: history, preferenceScore: preference },
  };
}

async function getChotHoiScore(db: SupabaseClient, args: Record<string, unknown>) {
  const productId = String(args.productId ?? "");
  const { data, error } = await db
    .from("products")
    .select("id,name,slug,rating,review_count,specs,brands(name),categories(slug,name),marketplace_products(id,current_price,original_price,is_active)")
    .eq("id", productId)
    .maybeSingle();
  if (error || !data) return { error: error?.message ?? "Không tìm thấy sản phẩm" };
  const product = mapProduct(data as Record<string, unknown>);

  let historyPoints: Array<{ price: number }> = [];
  if (product.marketplaceProductId) {
    const { data: hist } = await db
      .from("price_history")
      .select("price,recorded_at")
      .eq("marketplace_product_id", product.marketplaceProductId)
      .order("recorded_at", { ascending: true })
      .limit(30);
    historyPoints = (hist ?? []).map((h) => ({ price: Number(h.price) }));
  }

  let reviewAiScore: number | null = null;
  const { data: summaries } = await db
    .from("review_summaries")
    .select("ai_score")
    .eq("product_id", productId)
    .order("generated_at", { ascending: false })
    .limit(1);
  if (summaries?.[0]?.ai_score != null) reviewAiScore = Number(summaries[0].ai_score);

  return scoreProduct(
    product,
    {
      maxPrice: typeof args.maxPrice === "number" ? args.maxPrice : null,
      brands: Array.isArray(args.brands) ? args.brands.map(String) : [],
      minRam: typeof args.minRam === "number" ? args.minRam : null,
      useCase: typeof args.useCase === "string" ? args.useCase : null,
    },
    { historyPoints, reviewAiScore },
  );
}

async function saveProduct(userDb: SupabaseClient | null, productId: string) {
  if (!userDb) {
    return { ok: false, action_required: "Vui lòng đăng nhập để sử dụng tính năng này." };
  }
  const { data: userData, error: userError } = await userDb.auth.getUser();
  if (userError || !userData.user) {
    return { ok: false, action_required: "Vui lòng đăng nhập để sử dụng tính năng này." };
  }
  const userId = userData.user.id;
  const { data: existing } = await userDb
    .from("saved_products")
    .select("id")
    .eq("user_id", userId)
    .eq("product_id", productId)
    .maybeSingle();
  if (existing) return { ok: true, message: "Sản phẩm đã có trong danh sách đã lưu." };
  const { error } = await userDb.from("saved_products").insert({ user_id: userId, product_id: productId });
  if (error) return { ok: false, error: error.message };
  return { ok: true, message: "Đã lưu sản phẩm." };
}

async function createPriceAlert(userDb: SupabaseClient | null, admin: SupabaseClient, productId: string, targetPrice: number) {
  if (!userDb) {
    return { ok: false, action_required: "Vui lòng đăng nhập để sử dụng tính năng này." };
  }
  const { data: userData, error: userError } = await userDb.auth.getUser();
  if (userError || !userData.user) {
    return { ok: false, action_required: "Vui lòng đăng nhập để sử dụng tính năng này." };
  }
  const userId = userData.user.id;

  const { data: listing } = await admin
    .from("marketplace_products")
    .select("id,current_price")
    .eq("product_id", productId)
    .eq("is_active", true)
    .order("current_price")
    .limit(1)
    .maybeSingle();
  if (!listing) return { ok: false, error: "Không tìm thấy listing để theo dõi giá." };

  const values = {
    marketplace_product_id: listing.id,
    target_price: Math.round(targetPrice),
    current_price: Number(listing.current_price),
    is_active: true,
    triggered_at: null,
  };

  const { data: existing } = await userDb
    .from("price_alerts")
    .select("id")
    .eq("user_id", userId)
    .eq("product_id", productId)
    .limit(1);

  if (!existing?.length) {
    const { error } = await userDb.from("price_alerts").insert({ user_id: userId, product_id: productId, ...values });
    if (error) return { ok: false, error: error.message };
  } else {
    const { error } = await userDb.from("price_alerts").update(values).eq("id", existing[0].id);
    if (error) return { ok: false, error: error.message };
  }
  return {
    ok: true,
    message: `Đã tạo cảnh báo khi giá ≤ ${Math.round(targetPrice).toLocaleString("vi-VN")}đ.`,
    targetPrice: Math.round(targetPrice),
  };
}

async function executeTool(
  name: string,
  args: Record<string, unknown>,
  admin: SupabaseClient,
  userDb: SupabaseClient | null,
  actions: string[],
  sources: Set<string>,
  productBag: Map<string, Record<string, unknown>>,
  userMessage = "",
) {
  try {
    switch (name) {
      case "SearchProducts": {
        actions.push("Đã tìm sản phẩm");
        sources.add("products");
        sources.add("marketplace_products");
        // Enrich from the original user utterance — model often omits/mis-sets category.
        const enriched: Record<string, unknown> = { ...args };
        const fromUser = resolveCategorySlug(null, userMessage);
        const fromArgs = resolveCategorySlug(
          typeof enriched.category === "string" ? enriched.category : null,
          typeof enriched.keyword === "string" ? enriched.keyword : "",
        );
        // Prefer category inferred from the full user message over a weak/missing tool arg.
        if (fromUser) enriched.category = fromUser;
        else if (fromArgs) enriched.category = fromArgs;

        if ((!Array.isArray(enriched.brands) || (enriched.brands as unknown[]).length === 0)) {
          const folded = foldVi(userMessage);
          const known = ["asus", "lenovo", "apple", "samsung", "sony", "dell", "xiaomi", "logitech", "keychron"];
          const found = known.filter((b) => folded.includes(b));
          if (found.length) {
            enriched.brands = found.map((b) => b.charAt(0).toUpperCase() + b.slice(1));
            if ((enriched.brands as string[])[0] === "Asus") (enriched.brands as string[])[0] = "ASUS";
          }
        }
        const result = await searchProducts(admin, enriched);
        for (const p of result.products ?? []) productBag.set(String(p.id), p as Record<string, unknown>);
        return result;
      }
      case "ComparePrices": {
        actions.push("Đã so sánh giá");
        sources.add("marketplace_products");
        return await comparePrices(admin, String(args.productId ?? ""));
      }
      case "GetPriceHistory": {
        actions.push("Đã kiểm tra lịch sử giá");
        sources.add("price_history");
        return await getPriceHistory(admin, args);
      }
      case "GetReviews": {
        actions.push("Đã đọc đánh giá");
        sources.add("reviews");
        return await getReviews(admin, String(args.productId ?? ""), Number(args.limit ?? 20));
      }
      case "GetReviewSummary": {
        actions.push("Đã kiểm tra đánh giá");
        sources.add("review_summaries");
        return await getReviewSummary(admin, String(args.productId ?? ""));
      }
      case "GetChotHoiScore": {
        actions.push("Đã tính Chốt Hời Score");
        sources.add("recommendation_scorer");
        return await getChotHoiScore(admin, args);
      }
      case "SaveProduct": {
        actions.push("Đã thử lưu sản phẩm");
        sources.add("saved_products");
        return await saveProduct(userDb, String(args.productId ?? ""));
      }
      case "CreatePriceAlert": {
        actions.push("Đã thử tạo cảnh báo giá");
        sources.add("price_alerts");
        return await createPriceAlert(userDb, admin, String(args.productId ?? ""), Number(args.targetPrice ?? 0));
      }
      default:
        return { error: `Unknown tool: ${name}` };
    }
  } catch (error) {
    return { error: error instanceof Error ? error.message : "Tool failed" };
  }
}

function parseResultBlock(content: string): { message: string; meta: Record<string, unknown> } {
  const match = content.match(/<<<RESULT>>>([\s\S]*?)<<<END>>>/);
  if (!match) return { message: content.trim(), meta: {} };
  const message = content.replace(match[0], "").trim();
  try {
    return { message, meta: JSON.parse(match[1].trim()) as Record<string, unknown> };
  } catch {
    return { message: content.trim(), meta: {} };
  }
}

async function runAgent(req: Request, message: string): Promise<AgentResult> {
  const apiKey = Deno.env.get("OPENAI_API_KEY");
  const admin = adminClient();
  const userDb = userClient(req);
  const actions: string[] = [];
  const sources = new Set<string>();
  const productBag = new Map<string, Record<string, unknown>>();

  if (!apiKey) {
    // Soft fallback: keyword search only
    const fallback = await searchProducts(admin, { keyword: message, limit: 5 });
    actions.push("Đã tìm sản phẩm");
    sources.add("products");
    return {
      success: true,
      message: fallback.products.length
        ? `AI tạm thời không khả dụng. Đây là một số sản phẩm khớp từ khóa trong database.`
        : "Chốt Hời AI chưa lấy được dữ liệu này. AI tạm thời không khả dụng.",
      intent: "fallback_search",
      products: fallback.products,
      actions,
      sources: [...sources],
      code: "AI_NOT_CONFIGURED",
    };
  }

  const messages: Array<Record<string, unknown>> = [
    { role: "system", content: SYSTEM_PROMPT },
    { role: "user", content: message },
  ];

  let actionRequired: string | null = null;
  let lastScore: number | null = null;
  let lastVerdict: string | null = null;

  for (let round = 0; round < MAX_TOOL_ROUNDS; round++) {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), OPENAI_TIMEOUT_MS);
    let response: Response;
    try {
      response = await fetch("https://api.openai.com/v1/chat/completions", {
        method: "POST",
        signal: controller.signal,
        headers: {
          Authorization: `Bearer ${apiKey}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          model: OPENAI_MODEL,
          temperature: 0.2,
          tools: TOOLS,
          tool_choice: "auto",
          messages,
        }),
      });
    } finally {
      clearTimeout(timer);
    }

    if (!response.ok) {
      throw Object.assign(new Error(`OpenAI HTTP ${response.status}`), { code: "AI_UNAVAILABLE" });
    }

    const body = await response.json();
    const choice = body.choices?.[0]?.message;
    if (!choice) throw Object.assign(new Error("empty"), { code: "AI_INVALID_RESPONSE" });

    const toolCalls = Array.isArray(choice.tool_calls) ? choice.tool_calls : [];
    if (toolCalls.length === 0) {
      const content = typeof choice.content === "string" ? choice.content : "";
      const { message: finalMessage, meta } = parseResultBlock(content);
      const productIds = Array.isArray(meta.productIds) ? meta.productIds.map(String) : [];
      const products = productIds.length
        ? productIds.map((id) => productBag.get(id)).filter(Boolean) as Record<string, unknown>[]
        : [...productBag.values()].slice(0, 5);

      return {
        success: true,
        message: finalMessage || "Chốt Hời AI đã xử lý xong yêu cầu của bạn.",
        intent: typeof meta.intent === "string" ? meta.intent : "assistant",
        products,
        actions: [...new Set(actions)],
        sources: [...sources],
        verdict: typeof meta.verdict === "string" ? meta.verdict : lastVerdict,
        score: typeof meta.score === "number" ? meta.score : lastScore,
        action_required: actionRequired,
      };
    }

    messages.push({
      role: "assistant",
      content: choice.content ?? null,
      tool_calls: toolCalls,
    });

    for (const call of toolCalls) {
      const name = call.function?.name as string;
      let args: Record<string, unknown> = {};
      try {
        args = JSON.parse(call.function?.arguments ?? "{}");
      } catch {
        args = {};
      }
      const result = await executeTool(name, args, admin, userDb, actions, sources, productBag, message);
      if (result && typeof result === "object") {
        if ("action_required" in result && typeof (result as { action_required?: string }).action_required === "string") {
          actionRequired = (result as { action_required: string }).action_required;
        }
        if ("score" in result && typeof (result as { score?: number }).score === "number") {
          lastScore = (result as { score: number }).score;
        }
        if ("verdict" in result && typeof (result as { verdict?: string }).verdict === "string") {
          lastVerdict = (result as { verdict: string }).verdict;
        }
      }
      messages.push({
        role: "tool",
        tool_call_id: call.id,
        content: JSON.stringify(result),
      });
    }
  }

  return {
    success: true,
    message: "Chốt Hời AI chưa tổng hợp xong câu trả lời. Vui lòng thử lại với câu hỏi ngắn hơn.",
    intent: "timeout_rounds",
    products: [...productBag.values()].slice(0, 5),
    actions: [...new Set(actions)],
    sources: [...sources],
    verdict: lastVerdict,
    score: lastScore,
    action_required: actionRequired,
    code: "AI_MAX_ROUNDS",
  };
}

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders(req) });
  if (req.method !== "POST") return jsonResponse(req, { success: false, code: "METHOD_NOT_ALLOWED" }, 405);

  let body: Record<string, unknown> = {};
  try {
    body = await req.json();
  } catch {
    return jsonResponse(req, { success: false, code: "BAD_JSON", message: "Invalid JSON" }, 400);
  }

  const message = typeof body.message === "string" ? body.message.trim() : "";
  if (!message) {
    return jsonResponse(req, { success: false, code: "EMPTY_MESSAGE", message: "message is required" }, 400);
  }

  try {
    const result = await runAgent(req, message);
    return jsonResponse(req, result);
  } catch (error) {
    const code = error && typeof error === "object" && "code" in error
      ? String((error as { code: unknown }).code)
      : "AI_UNAVAILABLE";
    return jsonResponse(req, {
      success: false,
      message: "Chốt Hời AI chưa lấy được dữ liệu này.",
      intent: "error",
      products: [],
      actions: [],
      sources: [],
      code,
    });
  }
});
