# ai-recommend

Phase 5.2B — explains the deterministic **Chốt Hời Score** for the #1 Search Result pick.

The score in the request body is authoritative. This function never invents products, prices, ratings, or a new score.

## Request

```json
{
  "product": {
    "name": "...",
    "brand": "...",
    "currentPrice": 21330000,
    "originalPrice": 24628800,
    "rating": 4.8,
    "reviewCount": 890,
    "chotHoiScore": 82,
    "priceHistory": [],
    "pros": [],
    "cons": []
  },
  "intent": {
    "category": "laptop",
    "brands": ["ASUS", "Lenovo"],
    "maxPrice": 25000000,
    "minRam": 16,
    "useCase": "coding"
  }
}
```

## Response

```json
{
  "success": true,
  "source": "openai",
  "chotHoiScore": 82,
  "data": {
    "summary": "...",
    "verdict": "ĐÁNG MUA",
    "reasons": ["..."],
    "warnings": ["..."],
    "priceInsight": "...",
    "reviewInsight": "...",
    "matchInsight": "...",
    "score": 82
  }
}
```

## Secrets

Uses the same `OPENAI_API_KEY` as `ai-search`. Without it, returns a deterministic template explanation.

```bash
npx.cmd supabase functions deploy ai-recommend --use-api
```
