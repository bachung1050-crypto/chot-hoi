-- Phase 5.3A: seed demo reviews for marketplace_products.
-- Idempotent: removes previous demo-seed rows (external_review_id like 'demo-seed-%') then re-inserts.
-- Does NOT touch review_summaries.

delete from public.reviews
where external_review_id like 'demo-seed-%';

with listing as (
  select
    mp.id as marketplace_product_id,
    p.slug as product_slug,
    coalesce(c.slug, '') as category_slug,
    row_number() over (order by p.name, mp.id) as listing_ord
  from public.marketplace_products mp
  join public.products p on p.id = mp.product_id
  left join public.categories c on c.id = p.category_id
  where mp.is_active = true
),
review_slot as (
  -- 7 reviews per listing: ratings 5,5,5,4,4,3,2
  select *
  from (values
    (1, 5),
    (2, 5),
    (3, 5),
    (4, 4),
    (5, 4),
    (6, 3),
    (7, 2)
  ) as t(slot, rating)
),
authors as (
  select *
  from (values
    (1, 'Minh Anh'),
    (2, 'Hoàng Long'),
    (3, 'Thu Hà'),
    (4, 'Quốc Bảo'),
    (5, 'Ngọc Trâm'),
    (6, 'Đức Huy'),
    (7, 'Lan Chi'),
    (8, 'Tuấn Kiệt'),
    (9, 'Phương Anh'),
    (10, 'Hữu Phúc')
  ) as t(ord, author_name)
),
titles as (
  select *
  from (values
    (5, 1, 'Rất hài lòng'),
    (5, 2, 'Đáng tiền'),
    (5, 3, 'Dùng ổn định'),
    (4, 1, 'Tốt nhưng chưa hoàn hảo'),
    (4, 2, 'Khá ổn trong tầm giá'),
    (3, 1, 'Tạm được'),
    (2, 1, 'Còn điểm chưa ưng')
  ) as t(rating, variant, title)
),
-- Category-aware Vietnamese content pools (rating + variant → text)
contents as (
  select *
  from (values
    -- laptop
    ('laptop', 5, 1, 'Máy chạy rất mượt, màn hình đẹp, code khá thoải mái cả ngày.'),
    ('laptop', 5, 2, 'Hiệu năng mạnh, khởi động nhanh, bàn phím gõ êm. Rất đáng mua.'),
    ('laptop', 5, 3, 'Pin dùng được cả buổi, tản nhiệt ổn, không bị nóng khi làm việc.'),
    ('laptop', 4, 1, 'Hiệu năng tốt nhưng loa hơi nhỏ, phải gắn loa ngoài khi xem phim.'),
    ('laptop', 4, 2, 'Máy đẹp và mượt, chỉ tiếc cổng kết nối hơi ít so với nhu cầu của mình.'),
    ('laptop', 3, 1, 'Máy ổn trong tầm giá nhưng pin chưa thực sự tốt nếu mang đi họp nhiều.'),
    ('laptop', 2, 1, 'Chạy được việc văn phòng nhưng nóng và ồn khi mở nhiều tab trình duyệt.'),
    -- phone
    ('dien-thoai', 5, 1, 'Camera chụp rất đẹp, máy mượt, pin dùng cả ngày thoải mái.'),
    ('dien-thoai', 5, 2, 'Màn hình sắc nét, sạc nhanh, trải nghiệm tổng thể rất ổn.'),
    ('dien-thoai', 5, 3, 'Máy cầm chắc tay, hiệu năng mạnh, dùng app nặng vẫn mượt.'),
    ('dien-thoai', 4, 1, 'Máy tốt nhưng hơi nặng nếu cầm lâu bằng một tay.'),
    ('dien-thoai', 4, 2, 'Camera ổn, pin ổn, chỉ thấy giá còn cao so với bản tiền nhiệm.'),
    ('dien-thoai', 3, 1, 'Dùng được việc hàng ngày nhưng nóng nhẹ khi chơi game lâu.'),
    ('dien-thoai', 2, 1, 'Hình ảnh đẹp nhưng thời lượng pin chưa đạt kỳ vọng của mình.'),
    -- headphone
    ('tai-nghe', 5, 1, 'Chống ồn rất tốt, đeo êm, nghe nhạc cả ngày không mỏi.'),
    ('tai-nghe', 5, 2, 'Âm thanh chi tiết, micro gọi rõ, kết nối Bluetooth ổn định.'),
    ('tai-nghe', 5, 3, 'Pin trâu, chống ồn đỉnh trong tầm giá mình từng dùng.'),
    ('tai-nghe', 4, 1, 'Chống ồn tốt nhưng hộp sạc hơi to so với túi nhỏ.'),
    ('tai-nghe', 4, 2, 'Âm bass ổn, chỉ cần chỉnh EQ một chút là nghe rất đã.'),
    ('tai-nghe', 3, 1, 'Nghe ổn nhưng cảm giác ép tai sau khoảng 2–3 giờ.'),
    ('tai-nghe', 2, 1, 'Chống ồn tạm được nhưng dễ rớt kết nối ở nơi đông người.'),
    -- mouse
    ('chuot-may-tinh', 5, 1, 'Chuột êm, scroll mag tốc độ cao rất tiện khi làm việc spreadsheet.'),
    ('chuot-may-tinh', 5, 2, 'Cầm vừa tay, pin lâu, cử chỉ ngang rất hữu ích khi thiết kế.'),
    ('chuot-may-tinh', 5, 3, 'Độ nhạy tốt, không delay, dùng cả ngày vẫn thoải mái.'),
    ('chuot-may-tinh', 4, 1, 'Chuột rất tốt nhưng giá hơi cao so với chuột văn phòng thường.'),
    ('chuot-may-tinh', 4, 2, 'Êm và chính xác, chỉ tiếc phần mềm Logi Options hơi nặng.'),
    ('chuot-may-tinh', 3, 1, 'Dùng ổn nhưng cần thời gian làm quen với nút ngón cái.'),
    ('chuot-may-tinh', 2, 1, 'Cầm hơi to với tay nhỏ, dễ mỏi sau vài giờ.'),
    -- keyboard
    ('ban-phim', 5, 1, 'Gõ rất đã, hot-swap tiện, kết nối không dây ổn định.'),
    ('ban-phim', 5, 2, 'Layout TKL gọn, đèn đẹp, phù hợp làm việc và coding.'),
    ('ban-phim', 5, 3, 'Switch êm, build chắc, pin dùng được khá lâu.'),
    ('ban-phim', 4, 1, 'Bàn phím ngon nhưng firmware cần cập nhật mới hết lỗi nhỏ.'),
    ('ban-phim', 4, 2, 'Gõ thích nhưng keycap bóng hơi nhanh nếu dùng nhiều.'),
    ('ban-phim', 3, 1, 'Ổn trong tầm giá, tiếng gõ hơi to với không gian văn phòng yên tĩnh.'),
    ('ban-phim', 2, 1, 'Kết nối Bluetooth đôi lúc trễ khi đổi thiết bị liên tục.'),
    -- monitor
    ('man-hinh', 5, 1, 'Màu chuẩn, góc nhìn rộng, USB-C cấp nguồn laptop rất tiện.'),
    ('man-hinh', 5, 2, '4K sắc nét, làm design và văn phòng đều ổn.'),
    ('man-hinh', 5, 3, 'Đứng vững, hình ảnh đẹp, không bị sáng không đều.'),
    ('man-hinh', 4, 1, 'Hình đẹp nhưng chân đế chiếm khá nhiều diện tích bàn.'),
    ('man-hinh', 4, 2, 'Màu ổn, chỉ muốn có refresh cao hơn cho làm việc đa nhiệm.'),
    ('man-hinh', 3, 1, 'Màn ổn nhưng cần chỉnh lại độ sáng mặc định khá cao.'),
    ('man-hinh', 2, 1, 'Chất lượng ổn nhưng xước nhẹ trên viền khi mở hộp.'),
    -- smartwatch
    ('smartwatch', 5, 1, 'Theo dõi sức khỏe ổn, màn đẹp, pin dùng được vài ngày.'),
    ('smartwatch', 5, 2, 'Thông báo rõ, đo nhịp tim ổn, đeo cả ngày không khó chịu.'),
    ('smartwatch', 5, 3, 'Thiết kế đẹp, GPS ổn khi chạy bộ buổi sáng.'),
    ('smartwatch', 4, 1, 'Tính năng đủ dùng nhưng app đôi lúc sync chậm.'),
    ('smartwatch', 4, 2, 'Đẹp và tiện, pin chưa đạt mức quảng cáo nếu bật AOD.'),
    ('smartwatch', 3, 1, 'Đeo được việc cơ bản nhưng cảm biến SpO2 chưa thực sự tin.'),
    ('smartwatch', 2, 1, 'Màn đẹp nhưng nóng máy và hao pin khi dùng GPS lâu.'),
    -- fallback / other
    ('other', 5, 1, 'Sản phẩm đúng mô tả, dùng ổn định, đóng gói cẩn thận.'),
    ('other', 5, 2, 'Chất lượng tốt, giao hàng nhanh, sẽ mua lại.'),
    ('other', 5, 3, 'Dùng một thời gian vẫn ổn, không gặp lỗi đáng kể.'),
    ('other', 4, 1, 'Ổn trong tầm giá, còn vài điểm nhỏ cần cải thiện.'),
    ('other', 4, 2, 'Hài lòng nhìn chung, chỉ hơi lâu mới quen thao tác.'),
    ('other', 3, 1, 'Tạm ổn nhưng chưa thật sự ấn tượng so với kỳ vọng.'),
    ('other', 2, 1, 'Chưa đúng kỳ vọng, đang cân nhắc đổi sang mẫu khác.')
  ) as t(category_slug, rating, variant, content)
),
expanded as (
  select
    l.marketplace_product_id,
    rs.slot,
    rs.rating,
    case
      when rs.rating >= 4 then 'positive'
      when rs.rating = 3 then 'neutral'
      else 'negative'
    end as sentiment,
    coalesce(a.author_name, 'Khách hàng') as author_name,
    coalesce(ti.title, 'Đánh giá sản phẩm') as title,
    coalesce(c.content, o.content) as content,
    -- most verified; every 5th review unverified for diversity
    (rs.slot % 5) <> 0 as verified_purchase,
    format('demo-seed-%s-%s', l.marketplace_product_id::text, rs.slot) as external_review_id,
    -- spread across ~90 days, staggered by listing + slot
    (now() at time zone 'utc')
      - ((rs.slot * 11 + (l.listing_ord % 7) * 3) || ' days')::interval
      - ((rs.slot * 37 + l.listing_ord) || ' minutes')::interval as review_date
  from listing l
  cross join review_slot rs
  left join authors a
    on a.ord = ((l.listing_ord + rs.slot - 2) % 10) + 1
  left join titles ti
    on ti.rating = rs.rating
   and ti.variant = case
     when rs.rating = 5 then ((rs.slot - 1) % 3) + 1
     when rs.rating = 4 then ((rs.slot - 1) % 2) + 1
     else 1
   end
  left join contents c
    on c.category_slug = l.category_slug
   and c.rating = rs.rating
   and c.variant = case
     when rs.rating = 5 then ((rs.slot - 1) % 3) + 1
     when rs.rating = 4 then ((rs.slot - 1) % 2) + 1
     else 1
   end
  left join contents o
    on o.category_slug = 'other'
   and o.rating = rs.rating
   and o.variant = case
     when rs.rating = 5 then ((rs.slot - 1) % 3) + 1
     when rs.rating = 4 then ((rs.slot - 1) % 2) + 1
     else 1
   end
)
insert into public.reviews (
  marketplace_product_id,
  external_review_id,
  rating,
  title,
  content,
  author_name,
  review_date,
  verified_purchase,
  sentiment
)
select
  marketplace_product_id,
  external_review_id,
  rating,
  title,
  content,
  author_name,
  review_date,
  verified_purchase,
  sentiment
from expanded
on conflict (marketplace_product_id, external_review_id) do nothing;
