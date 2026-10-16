# ai-search

Natural language → `SearchIntent` JSON for CHỐT HỜI.

## Secret

```bash
supabase secrets set OPENAI_API_KEY=sk-...
```

Never put the key in Flutter, Git, or logs. Flutter only calls:

```dart
supabase.functions.invoke('ai-search', body: {'query': query});
```

## Deploy

```bash
supabase link --project-ref <your-project-ref>
supabase functions deploy ai-search
```

## Contract

**POST** `{ "query": "Tìm laptop dưới 25 triệu để code" }`

**Success**

```json
{ "success": true, "data": { "category": "laptop", "brands": [], "maxPrice": 25000000, ... }, "source": "openai" }
```

**Client error**

```json
{ "success": false, "message": "...", "code": "EMPTY_QUERY" }
```

When OpenAI is down but the query is valid, the function may still return
`success: true` with `source: "fallback"` so the app keeps searching.
