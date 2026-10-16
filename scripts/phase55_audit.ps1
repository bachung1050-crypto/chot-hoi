# Phase 5.5 live audit — no secrets logged beyond publishable key presence
$ErrorActionPreference = 'Stop'
$envJson = Get-Content -Raw (Join-Path $PSScriptRoot '..\env.json') | ConvertFrom-Json
$base = $envJson.SUPABASE_URL
$key = $envJson.SUPABASE_PUBLISHABLE_KEY
$fn = "$base/functions/v1"
$hdr = @{
  Authorization = "Bearer $key"
  apikey        = $key
  'Content-Type' = 'application/json'
}

function Invoke-Fn([string]$name, [hashtable]$body, [int]$timeout = 60) {
  $json = ($body | ConvertTo-Json -Depth 8 -Compress)
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
  try {
    $r = Invoke-RestMethod -Uri "$fn/$name" -Method POST -Headers $hdr -Body $bytes -TimeoutSec $timeout
    return @{ ok = $true; data = $r }
  } catch {
    $msg = $_.Exception.Message
    $detail = $null
    if ($_.ErrorDetails -and $_.ErrorDetails.Message) { $detail = $_.ErrorDetails.Message }
    return @{ ok = $false; error = $msg; detail = $detail }
  }
}

function Rest-Get([string]$path) {
  return Invoke-RestMethod -Uri "$base/rest/v1/$path" -Headers @{ apikey = $key; Authorization = "Bearer $key" }
}

Write-Host '=== DB SAMPLE COUNTS (list length, capped) ==='
$tables = @(
  'products?select=id&is_active=eq.true',
  'marketplace_products?select=id&is_active=eq.true',
  'price_history?select=id&limit=1000',
  'reviews?select=id&limit=1000',
  'review_summaries?select=id',
  'brands?select=id',
  'categories?select=id',
  'marketplaces?select=id'
)
foreach ($t in $tables) {
  $name = $t.Split('?')[0]
  $rows = Rest-Get $t
  Write-Host ("{0}: {1}" -f $name, @($rows).Count)
}

Write-Host ''
Write-Host '=== ASUS Vivobook price_history ==='
$asus = Rest-Get "products?name=ilike.*Vivobook*&select=id,name,rating,review_count,marketplace_products(id,current_price,marketplaces(code))"
$asusRow = @($asus)[0]
Write-Host ("product={0} rating={1} reviews={2}" -f $asusRow.name, $asusRow.rating, $asusRow.review_count)
$mpIds = @($asusRow.marketplace_products | ForEach-Object { $_.id })
Write-Host ("listings={0}" -f $mpIds.Count)
foreach ($m in @($asusRow.marketplace_products)) {
  Write-Host ("  {0} price={1}" -f $m.marketplaces.code, $m.current_price)
}
$ph = Rest-Get ("price_history?marketplace_product_id=eq.{0}&select=price,recorded_at&order=recorded_at.asc" -f $mpIds[0])
Write-Host ("price_history_points_cheapest={0}" -f @($ph).Count)
if (@($ph).Count -gt 0) {
  $prices = @($ph | ForEach-Object { [double]$_.price })
  Write-Host ("  low={0} high={1} first={2} last={3}" -f ($prices | Measure-Object -Minimum).Minimum, ($prices | Measure-Object -Maximum).Maximum, $prices[0], $prices[-1])
}

Write-Host ''
Write-Host '=== ai-search tests ==='
$queries = @(
  'Tim laptop duoi 25 trieu de code',
  'Tim dien thoai Samsung duoi 20 trieu',
  'Tai nghe Sony chong on',
  'Laptop ASUS RAM 16GB',
  'Tim MacBook',
  ''
)
foreach ($q in $queries) {
  $label = if ([string]::IsNullOrEmpty($q)) { '(empty)' } else { $q }
  $res = Invoke-Fn 'ai-search' @{ query = $q }
  if (-not $res.ok) {
    Write-Host ("FAIL ai-search [{0}]: {1}" -f $label, $res.error)
    continue
  }
  $d = $res.data
  if ($q -eq '') {
    Write-Host ("empty -> success={0} code={1}" -f $d.success, $d.code)
  } else {
    $intent = $d.data
    Write-Host ("OK [{0}] success={1} cat={2} brands={3} max={4} minRam={5} use={6}" -f `
      $label, $d.success, $intent.category, ($intent.brands -join ','), $intent.maxPrice, $intent.minRam, $intent.useCase)
  }
}

Write-Host ''
Write-Host '=== full intent query ==='
$fullQ = 'Tim laptop duoi 25 trieu de code, RAM it nhat 16GB, uu tien ASUS hoac Lenovo'
$res = Invoke-Fn 'ai-search' @{ query = $fullQ }
$intent = $res.data.data
Write-Host ($intent | ConvertTo-Json -Compress)

Write-Host ''
Write-Host '=== ai-recommend score authority (request score=87, AI must echo 87) ==='
$recBody = @{
  intent = @{ category = 'laptop'; brands = @('ASUS'); maxPrice = 25000000; minRam = 16; useCase = 'coding' }
  product = @{
    name = 'ASUS Vivobook S 14 OLED'
    brand = 'ASUS'
    currentPrice = 21330300
    originalPrice = 24628800
    rating = 4.8
    reviewCount = 890
    chotHoiScore = 87
    priceHistory = @(@{ price = 22000000 }, @{ price = 21330300 })
    priceScore = 90
    specScore = 85
    reviewScore = 88
    priceHistoryScore = 70
    preferenceScore = 100
  }
}
$rec = Invoke-Fn 'ai-recommend' $recBody
if ($rec.ok) {
  Write-Host ("success={0} source={1} echoScore={2} data.score={3} verdict={4}" -f `
    $rec.data.success, $rec.data.source, $rec.data.chotHoiScore, $rec.data.data.score, $rec.data.data.verdict)
} else {
  Write-Host ("FAIL ai-recommend: {0}" -f $rec.error)
}

Write-Host ''
Write-Host '=== ai-review-summary ==='
$revBody = @{
  product = @{ id = $asusRow.id; name = $asusRow.name; brand = 'ASUS' }
  reviews = @(
    @{ rating = 5; title = 'Tot'; content = 'Man OLED dep, pin on'; verifiedPurchase = $true; sentiment = 'positive' },
    @{ rating = 4; title = 'Ok'; content = 'Ram 16GB du code'; verifiedPurchase = $true; sentiment = 'positive' },
    @{ rating = 3; title = 'Tam'; content = 'Loa trung binh'; verifiedPurchase = $false; sentiment = 'neutral' }
  )
  totalReviewCount = 890
}
$rev = Invoke-Fn 'ai-review-summary' $revBody 90
if ($rev.ok) {
  $rd = $rev.data
  Write-Host ("success={0} source={1} hasSummary={2} aiScore={3}" -f `
    $rd.success, $rd.source, [bool]$rd.data.summary, $rd.data.aiScore)
} else {
  Write-Host ("FAIL ai-review-summary: {0} {1}" -f $rev.error, $rev.detail)
}

Write-Host ''
Write-Host '=== ai-agent SearchProducts ==='
$agent = Invoke-Fn 'ai-agent' @{ message = 'Tim laptop ASUS duoi 25 trieu de code' } 90
if ($agent.ok) {
  $a = $agent.data
  Write-Host ("success={0} products={1} actions={2} score={3} verdict={4}" -f `
    $a.success, @($a.products).Count, ($a.actions -join '|'), $a.score, $a.verdict)
  if (@($a.products).Count -gt 0) {
    Write-Host ("  first={0} price={1}" -f $a.products[0].name, $a.products[0].currentPrice)
  }
} else {
  Write-Host ("FAIL ai-agent: {0}" -f $agent.error)
}

Write-Host ''
Write-Host '=== ai-agent ComparePrices ==='
$cmp = Invoke-Fn 'ai-agent' @{ message = ("So sanh gia san pham id {0} tren cac san" -f $asusRow.id) } 90
if ($cmp.ok) {
  Write-Host ("success={0} actions={1}" -f $cmp.data.success, ($cmp.data.actions -join '|'))
  Write-Host ("  sources={0}" -f ($cmp.data.sources -join '|'))
} else {
  Write-Host ("FAIL compare: {0}" -f $cmp.error)
}

Write-Host ''
Write-Host '=== ai-agent SaveProduct (anon) ==='
$save = Invoke-Fn 'ai-agent' @{ message = ("Luu san pham voi productId {0}" -f $asusRow.id) } 60
if ($save.ok) {
  Write-Host ("success={0} action_required={1} actions={2}" -f `
    $save.data.success, $save.data.action_required, ($save.data.actions -join '|'))
} else {
  Write-Host ("FAIL save: {0}" -f $save.error)
}

Write-Host ''
Write-Host '=== ai-agent CreatePriceAlert (anon) ==='
$alert = Invoke-Fn 'ai-agent' @{ message = ("Nhac toi khi san pham {0} xuong 20000000" -f $asusRow.id) } 60
if ($alert.ok) {
  Write-Host ("success={0} action_required={1} actions={2}" -f `
    $alert.data.success, $alert.data.action_required, ($alert.data.actions -join '|'))
} else {
  Write-Host ("FAIL alert: {0}" -f $alert.error)
}

Write-Host ''
Write-Host '=== error hardening ==='
foreach ($pair in @(
  @{ n = 'ai-search'; b = @{} },
  @{ n = 'ai-agent'; b = @{ message = '' } },
  @{ n = 'ai-recommend'; b = @{} }
)) {
  $r = Invoke-Fn $pair.n $pair.b 30
  if ($r.ok) {
    Write-Host ("{0} empty/invalid -> success={1} code={2}" -f $pair.n, $r.data.success, $r.data.code)
  } else {
    Write-Host ("{0} empty/invalid -> HTTP error (stable): {1}" -f $pair.n, $r.error)
  }
}

Write-Host ''
Write-Host '=== DONE ==='
