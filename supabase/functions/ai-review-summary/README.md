# ai-review-summary

Phase 5.3B — analyzes real `reviews` for one product and upserts `review_summaries`.

## Request

```json
{
  "product": { "id": "uuid", "name": "...", "brand": "..." },
  "reviews": [
    {
      "rating": 5,
      "title": "...",
      "content": "...",
      "verifiedPurchase": true,
      "sentiment": "positive"
    }
  ],
  "totalReviewCount": 28
}
```

## Response

```json
{
  "success": true,
  "source": "openai",
  "data": {
    "summary": "...",
    "pros": [],
    "cons": [],
    "highlights": [],
    "warnings": [],
    "sentiment": "positive",
    "confidence": 0.9,
    "totalReviews": 28,
    "aiScore": 88,
    "model": "gpt-4o-mini",
    "generatedAt": "..."
  }
}
```

## Secrets

- `OPENAI_API_KEY` (required for AI; otherwise stats fallback)
- `SUPABASE_SERVICE_ROLE_KEY` + `SUPABASE_URL` (auto) to write `review_summaries`

```bash
npx supabase functions deploy ai-review-summary --use-api --project-ref waqwyegneuhmhlnjwjnd
```
