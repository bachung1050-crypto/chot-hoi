// CHỐT HỜI — Edge Function: ai-search
// Natural language → SearchIntent JSON via OpenAI (OPENAI_API_KEY secret only).
// Never invents products, prices, ratings, sellers, or marketplaces.

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

const MAX_QUERY_LENGTH = 500;
const OPENAI_TIMEOUT_MS = 20_000;
const OPENAI_MODEL = "gpt-4o-mini";

/** Prefer the app origin when present; otherwise allow localhost Flutter web. */
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

type SearchIntent = {
  category: string | null;
  brands: string[];
  minPrice: number | null;
  maxPrice: number | null;
  minRam: number | null;
  useCase: string | null;
  keyword: string | null;
  features: string[];
};

const EMPTY_INTENT: SearchIntent = {
  category: null,
  brands: [],
  minPrice: null,
  maxPrice: null,
  minRam: null,
  useCase: null,
  keyword: null,
  features: [],
};

const SYSTEM_PROMPT = `You are the search intent parser for CHỐT HỜI, a Vietnamese shopping comparison app.

You must extract structured shopping search intent from the user query.

Never invent products, prices, ratings, reviews, sellers or marketplaces.

Return ONLY valid JSON with this exact schema:
{
  "category": string | null,
  "brands": string[],
  "minPrice": number | null,
  "maxPrice": number | null,
  "minRam": number | null,
  "useCase": string | null,
  "keyword": string | null,
  "features": string[]
}

Rules:
- category: product type label in Vietnamese or English when clear (e.g. "laptop", "điện thoại", "tai nghe"); otherwise null
- brands: brand names as commonly written (ASUS, Lenovo, Samsung, Sony, Apple, …)
- minPrice / maxPrice: Vietnamese dong integers (e.g. 25 triệu → 25000000)
- minRam: integer GB when mentioned (e.g. 16)
- useCase: prefer "coding", "gaming", "office", "design" when identifiable; otherwise null
- keyword: free-text leftover only when structured fields are weak; otherwise null
- features: short tags if relevant (e.g. "noise_cancelling"); else []
- Prices under ~1000 without a unit mean triệu VND`;

function jsonResponse(req: Request, body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders(req), "Content-Type": "application/json" },
  });
}

function errorResponse(
  req: Request,
  status: number,
  code: string,
  message: string,
): Response {
  return jsonResponse(req, { success: false, message, code }, status);
}

function asNumber(value: unknown): number | null {
  if (value == null) return null;
  const n = typeof value === "number" ? value : Number(value);
  return Number.isFinite(n) ? Math.round(n) : null;
}

function normalizeIntent(raw: Record<string, unknown>): SearchIntent {
  const brands = raw.brands;
  const features = raw.features;
  let useCase = typeof raw.useCase === "string" ? raw.useCase : typeof raw.use_case === "string" ? raw.use_case : null;
  if (useCase === "code") useCase = "coding";

  return {
    category: typeof raw.category === "string" ? raw.category : null,
    brands: Array.isArray(brands) ? brands.map(String).filter(Boolean) : [],
    minPrice: asNumber(raw.minPrice ?? raw.min_price),
    maxPrice: asNumber(raw.maxPrice ?? raw.max_price),
    minRam: asNumber(raw.minRam ?? raw.min_ram),
    useCase,
    keyword: typeof raw.keyword === "string" ? raw.keyword : null,
    features: Array.isArray(features) ? features.map(String).filter(Boolean) : [],
  };
}

// --- Local fallback (same spirit as Flutter FallbackSearchIntentParser) ---

const CATEGORY_KEYWORDS: Record<string, string[]> = {
  laptop: ["laptop", "may tinh xach tay", "notebook", "macbook"],
  "điện thoại": ["dien thoai", "smartphone", "iphone", "phone"],
  "tai nghe": ["tai nghe", "headphone", "earbuds", "airpods"],
  chuột: ["chuot", "mouse"],
  "bàn phím": ["ban phim", "keyboard"],
  "màn hình": ["man hinh", "monitor"],
  smartwatch: ["smartwatch", "dong ho thong minh", "apple watch"],
  "gia dụng": ["gia dung", "robot hut bui"],
  "thời trang": ["thoi trang", "giay", "sneaker"],
  "phụ kiện": ["phu kien", "sac du phong", "pin du phong"],
};

const KNOWN_BRANDS = [
  "ASUS", "Lenovo", "Apple", "Samsung", "Sony", "HP", "Dell", "Acer", "MSI",
  "Xiaomi", "Oppo", "Logitech", "Razer", "LG", "Huawei",
];

const BRAND_ALIASES: Record<string, string> = {
  iphone: "Apple",
  macbook: "Apple",
  ipad: "Apple",
  airpods: "Apple",
  galaxy: "Samsung",
};

const USE_CASE: Record<string, string[]> = {
  coding: ["code", "coding", "lap trinh", "dev", "developer"],
  gaming: ["game", "gaming"],
  office: ["van phong", "hoc tap", "sinh vien"],
  design: ["do hoa", "design", "edit video"],
};

function stripDiacritics(input: string): string {
  return input
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/đ/g, "d")
    .replace(/Đ/g, "d")
    .toLowerCase()
    .trim();
}

function toVnd(amountText: string, unit: string | undefined): number {
  const amount = Number(amountText.replace(",", "."));
  const multiplier =
    unit === "k" || unit === "nghin"
      ? 1000
      : unit === "trieu" || unit === "tr" || unit === "m"
      ? 1_000_000
      : amount < 1000
      ? 1_000_000
      : 1;
  return Math.round(amount * multiplier);
}

function fallbackParse(query: string): SearchIntent {
  const text = stripDiacritics(query);
  let category: string | null = null;
  for (const [label, keywords] of Object.entries(CATEGORY_KEYWORDS)) {
    if (keywords.some((k) => text.includes(k))) {
      category = label;
      break;
    }
  }

  const brands = new Set<string>();
  for (const brand of KNOWN_BRANDS) {
    if (new RegExp(`\\b${stripDiacritics(brand)}\\b`).test(text)) brands.add(brand);
  }
  for (const [alias, brand] of Object.entries(BRAND_ALIASES)) {
    if (text.includes(alias)) brands.add(brand);
  }

  const maxMatch = text.match(/(?:duoi|toi da|khong qua|tam|<)\s*(\d+(?:[.,]\d+)?)\s*(trieu|tr|m|k|nghin)?/);
  const minMatch = text.match(/(?:tu|tren|>)\s*(\d+(?:[.,]\d+)?)\s*(trieu|tr|m|k|nghin)?/);
  const ramMatch = text.match(/(?:ram\s*)?(\d+)\s*gb(?:\s*ram)?|ram\s*(\d+)/);

  let useCase: string | null = null;
  for (const [key, words] of Object.entries(USE_CASE)) {
    if (words.some((w) => text.includes(w))) {
      useCase = key;
      break;
    }
  }

  const minRam = ramMatch ? Number(ramMatch[1] ?? ramMatch[2]) : null;
  const maxPrice = maxMatch ? toVnd(maxMatch[1], maxMatch[2]) : null;
  const minPrice = minMatch ? toVnd(minMatch[1], minMatch[2]) : null;
  const hasStructure = !!(category || brands.size || maxPrice || minPrice || minRam || useCase);

  return {
    category,
    brands: [...brands],
    minPrice,
    maxPrice,
    minRam: Number.isFinite(minRam) ? minRam : null,
    useCase,
    keyword: hasStructure ? null : query.trim(),
    features: minRam ? [`ram_${minRam}gb`] : [],
  };
}

async function parseWithOpenAi(query: string, apiKey: string): Promise<SearchIntent> {
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
        temperature: 0,
        response_format: { type: "json_object" },
        messages: [
          { role: "system", content: SYSTEM_PROMPT },
          { role: "user", content: query },
        ],
      }),
    });

    if (response.status === 429) {
      throw Object.assign(new Error("rate_limit"), { code: "AI_RATE_LIMITED" });
    }
    if (!response.ok) {
      // Do not forward OpenAI body (may leak details).
      throw Object.assign(new Error("openai_http"), { code: "AI_UNAVAILABLE" });
    }

    const body = await response.json();
    const content = body.choices?.[0]?.message?.content;
    if (typeof content !== "string" || !content.trim()) {
      throw Object.assign(new Error("empty_openai"), { code: "AI_INVALID_RESPONSE" });
    }

    let parsed: unknown;
    try {
      parsed = JSON.parse(content);
    } catch {
      throw Object.assign(new Error("bad_json"), { code: "AI_INVALID_RESPONSE" });
    }
    if (!parsed || typeof parsed !== "object") {
      throw Object.assign(new Error("bad_shape"), { code: "AI_INVALID_RESPONSE" });
    }

    return normalizeIntent(parsed as Record<string, unknown>);
  } finally {
    clearTimeout(timer);
  }
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders(req) });
  }

  if (req.method !== "POST") {
    return errorResponse(req, 405, "METHOD_NOT_ALLOWED", "Only POST is supported");
  }

  let body: unknown;
  try {
    body = await req.json();
  } catch {
    return errorResponse(req, 400, "INVALID_JSON", "Request body must be valid JSON");
  }

  if (!body || typeof body !== "object") {
    return errorResponse(req, 400, "INVALID_BODY", "Request body must be a JSON object");
  }

  const query = (body as { query?: unknown }).query;
  if (typeof query !== "string") {
    return errorResponse(req, 400, "MISSING_QUERY", "Field \"query\" is required");
  }
  const trimmed = query.trim();
  if (!trimmed) {
    return errorResponse(req, 400, "EMPTY_QUERY", "Query must not be empty");
  }
  if (trimmed.length > MAX_QUERY_LENGTH) {
    return errorResponse(req, 400, "QUERY_TOO_LONG", `Query must be at most ${MAX_QUERY_LENGTH} characters`);
  }

  const apiKey = Deno.env.get("OPENAI_API_KEY");
  if (!apiKey) {
    // Soft-degrade so Flutter still gets a usable intent without exposing secrets.
    return jsonResponse(req, {
      success: true,
      data: fallbackParse(trimmed),
      source: "fallback",
      code: "AI_NOT_CONFIGURED",
    });
  }

  try {
    const data = await parseWithOpenAi(trimmed, apiKey);
    return jsonResponse(req, { success: true, data, source: "openai" });
  } catch (error) {
    const code =
      error && typeof error === "object" && "code" in error && typeof (error as { code: unknown }).code === "string"
        ? (error as { code: string }).code
        : error instanceof DOMException && error.name === "AbortError"
        ? "AI_TIMEOUT"
        : "AI_UNAVAILABLE";

    // Prefer a usable fallback intent over a hard failure for the shopping UX.
    return jsonResponse(req, {
      success: true,
      data: fallbackParse(trimmed),
      source: "fallback",
      code,
      message: "AI service unavailable",
    });
  }
});
