-- Phase 5.2C: flexible product specs (JSONB). No per-attribute columns.
-- Category-appropriate keys only (do not put "ram" on headphones/mice/etc.).

alter table public.products
  add column if not exists specs jsonb not null default '{}'::jsonb;

comment on column public.products.specs is
  'Category-specific product specs (e.g. ram/cpu for laptops; anc/battery for headphones).';

-- ASUS Vivobook S 14 OLED (laptop)
update public.products
set specs = '{
  "ram": "16GB",
  "cpu": "Intel Core Ultra 7",
  "storage": "512GB SSD",
  "gpu": "Intel Arc",
  "screen": "14 inch OLED",
  "use_cases": ["coding", "office", "design"]
}'::jsonb
where slug = 'asus-vivobook-s14-oled';

-- Lenovo LOQ 15 (gaming laptop)
update public.products
set specs = '{
  "ram": "16GB",
  "cpu": "AMD Ryzen 7 7435HS",
  "storage": "512GB SSD",
  "gpu": "NVIDIA RTX 4050",
  "screen": "15.6 inch 144Hz",
  "use_cases": ["gaming", "coding"]
}'::jsonb
where slug = 'lenovo-loq-15';

-- MacBook Air M3 13 inch (laptop)
update public.products
set specs = '{
  "ram": "16GB",
  "cpu": "Apple M3",
  "storage": "512GB SSD",
  "gpu": "Apple M3 GPU",
  "screen": "13.6 inch Liquid Retina",
  "use_cases": ["coding", "office", "design"]
}'::jsonb
where slug = 'macbook-air-m3-13';

-- Samsung Galaxy S25 Ultra (phone)
update public.products
set specs = '{
  "ram": "12GB",
  "storage": "256GB",
  "chip": "Snapdragon 8 Elite",
  "display": "6.9 inch Dynamic AMOLED",
  "battery": "5000mAh",
  "use_cases": ["photography", "productivity"]
}'::jsonb
where slug = 'samsung-galaxy-s25-ultra';

-- iPhone 16 Pro (phone)
update public.products
set specs = '{
  "ram": "8GB",
  "storage": "256GB",
  "chip": "Apple A18 Pro",
  "display": "6.3 inch Super Retina XDR",
  "battery": "All-day",
  "use_cases": ["photography", "productivity"]
}'::jsonb
where slug = 'iphone-16-pro';

-- Sony WH-1000XM6 (headphone) — no ram
update public.products
set specs = '{
  "anc": "Industry-leading noise cancelling",
  "battery": "40 hours",
  "driver": "30mm",
  "connectivity": "Bluetooth 5.3",
  "use_cases": ["travel", "music"]
}'::jsonb
where slug = 'sony-wh-1000xm6';

-- AirPods Pro 2 (headphone) — no ram
update public.products
set specs = '{
  "anc": "Active Noise Cancellation",
  "battery": "6 hours (buds)",
  "chip": "H2",
  "connectivity": "Bluetooth",
  "use_cases": ["commute", "calls"]
}'::jsonb
where slug = 'airpods-pro-2';

-- Dell UltraSharp U2723QE (monitor) — no ram
update public.products
set specs = '{
  "size": "27 inch",
  "resolution": "4K UHD 3840x2160",
  "panel": "IPS Black",
  "refresh_rate": "60Hz",
  "ports": "USB-C 90W",
  "use_cases": ["office", "design"]
}'::jsonb
where slug = 'dell-u2723qe';

-- Keychron K8 Pro (keyboard) — no ram
update public.products
set specs = '{
  "switch": "Hot-swappable mechanical",
  "layout": "TKL 87-key",
  "connectivity": "Wireless / Wired / Bluetooth",
  "battery": "Rechargeable",
  "use_cases": ["coding", "office"]
}'::jsonb
where slug = 'keychron-k8-pro';

-- Logitech MX Master 3S (mouse) — no ram
update public.products
set specs = '{
  "sensor": "8K DPI MagSpeed",
  "connectivity": "Logi Bolt / Bluetooth",
  "buttons": "7 programmable",
  "battery": "70 days",
  "use_cases": ["office", "productivity"]
}'::jsonb
where slug = 'logitech-mx-master-3s';

-- Samsung Galaxy Watch 7 (watch) — no ram key
update public.products
set specs = '{
  "size": "44mm",
  "display": "Super AMOLED",
  "battery": "Up to 40 hours",
  "os": "Wear OS",
  "sensors": "BioActive",
  "use_cases": ["fitness", "notifications"]
}'::jsonb
where slug = 'samsung-galaxy-watch-7';

-- Xiaomi Watch 2 Pro (watch) — no ram key
update public.products
set specs = '{
  "size": "46mm",
  "display": "1.43 inch AMOLED",
  "battery": "Up to 5 days",
  "os": "Wear OS",
  "connectivity": "Bluetooth / GPS",
  "use_cases": ["fitness", "notifications"]
}'::jsonb
where slug = 'xiaomi-watch-2-pro';
