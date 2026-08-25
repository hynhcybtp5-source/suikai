begin;
insert into public.categories (
  id, kind, name, active, sort_order, type, legacy_key,
  name_th, name_shn, name_en, name_my, is_active
)
values
  ('10000000-0000-4000-8000-000000000001','store','ร้านอาหาร',true,0,'store','store_food','ร้านอาหาร','လၢၼ်ႉတၢင်းၵိၼ်','Restaurant','စားသောက်ဆိုင်',true),
  ('10000000-0000-4000-8000-000000000002','store','ร้านกาแฟ',true,1,'store','store_cafe','ร้านกาแฟ','လၢၼ်ႉၵေႃႇၾီႇ','Coffee shop','ကော်ဖီဆိုင်',true),
  ('10000000-0000-4000-8000-000000000003','store','ร้านซ่อมรถ',true,2,'store','store_auto_repair','ร้านซ่อมรถ','လၢၼ်ႉမႄးလူတ်ႉ','Auto repair','ကားပြင်ဆိုင်',true),
  ('10000000-0000-4000-8000-000000000004','store','ร้านหมูกะทะ',true,3,'store','store_hotpot','ร้านหมูกะทะ','လၢၼ်ႉမူၵရထ','Hot-pot restaurant','ဟော့ပေါ့ဆိုင်',true),
  ('10000000-0000-4000-8000-000000000005','store','ร้านปิ้งย่าง',true,4,'store','store_grill','ร้านปิ้งย่าง','လၢၼ်ႉပိင်ႈယၢင်ႈ','Grill restaurant','အကင်ဆိုင်',true),
  ('10000000-0000-4000-8000-000000000006','store','ร้านซุปเปอร์มาร์เก็ต',true,5,'store','store_supermarket','ร้านซุปเปอร์มาร์เก็ต','သုၵ်ႉပိူဝ်ႇမႃးၵႅတ်ႉ','Supermarket','စူပါမားကတ်',true),
  ('10000000-0000-4000-8000-000000000007','store','ร้านเสริมสวย',true,6,'store','store_beauty','ร้านเสริมสวย','လၢၼ်ႉႁၢင်ႈလီ','Beauty salon','အလှပြင်ဆိုင်',true),
  ('10000000-0000-4000-8000-000000000008','store','สัตว์เลี้ยง',true,7,'store','store_pets','สัตว์เลี้ยง','သတ်းလဵင်ႉ','Pets','အိမ်မွေးတိရစ္ဆာန်',true),
  ('10000000-0000-4000-8000-000000000009','store','ร้านขายยา',true,8,'store','store_pharmacy','ร้านขายยา','လၢၼ်ႉယႃႈယႃ','Pharmacy','ဆေးဆိုင်',true),
  ('10000000-0000-4000-8000-000000000010','store','มือถือ แท็บเล็ต',true,9,'store','store_mobile','มือถือ แท็บเล็ต','ၾူၼ်း လႄႈ တႅပ်ႉလဵတ်ႉ','Phones and tablets','ဖုန်းနှင့် တက်ဘလက်',true),
  ('10000000-0000-4000-8000-000000000011','store','อุปกรณ์อิเล็กทรอนิกส์',true,10,'store','store_electronics','อุปกรณ์อิเล็กทรอนิกส์','ၶိူင်ႈဢီႇလႅၵ်ႉထရေႃးၼိၵ်ႉ','Electronics','အီလက်ထရွန်နစ်',true),
  ('10000000-0000-4000-8000-000000000012','store','แฟชั่น เสื้อผ้า',true,11,'store','store_fashion','แฟชั่น เสื้อผ้า','ၾႅတ်ႉသျိၼ်ႇ လႄႈ ၶူဝ်းၼုင်ႈ','Fashion and clothing','ဖက်ရှင်နှင့် အဝတ်အစား',true),
  ('10000000-0000-4000-8000-000000000013','store','บ้านและสวน',true,12,'store','store_home','บ้านและสวน','ႁိူၼ်း လႄႈ သူၼ်','Home and garden','အိမ်နှင့် ဥယျာဉ်',true),
  ('10000000-0000-4000-8000-000000000014','store','บริการ',true,13,'store','store_services','บริการ','ဝၢၼ်ႈသၢင်ႈ','Services','ဝန်ဆောင်မှု',true),
  ('10000000-0000-4000-8000-000000000015','store','อื่นๆ',true,14,'store','store_other','อื่นๆ','တၢင်ႇမဵဝ်း','Other','အခြား',true),
  ('20000000-0000-4000-8000-000000000001','listing','ยานพาหนะ',true,0,'listing','listing_vehicles','ยานพาหนะ','လူတ်ႉလႄႈယၢၼ်ႇ','Vehicles','ယာဉ်',true),
  ('20000000-0000-4000-8000-000000000002','listing','มือถือ & แท็บเล็ต',true,1,'listing','listing_mobile','มือถือ & แท็บเล็ต','ၾူၼ်း လႄႈ တႅပ်ႉလဵတ်ႉ','Phones & Tablets','ဖုန်း/တက်ဘလက်',true),
  ('20000000-0000-4000-8000-000000000003','listing','บ้าน & สวน',true,2,'listing','listing_home','บ้าน & สวน','ႁိူၼ်း လႄႈ သူၼ်','Home & Garden','အိမ်/ဥယျာဉ်',true),
  ('20000000-0000-4000-8000-000000000004','listing','แฟชั่น',true,3,'listing','listing_fashion','แฟชั่น','ၾႅတ်ႉသျိၼ်ႇ','Fashion','အဝတ်အစား',true),
  ('20000000-0000-4000-8000-000000000005','listing','เครื่องมือ & อุปกรณ์',true,4,'listing','listing_tools','เครื่องมือ & อุปกรณ์','ၶိူင်ႈမိုဝ်း လႄႈ ၶိူင်ႈၸႂ်ႉ','Tools & equipment','ကိရိယာနှင့် ပစ္စည်း',true),
  ('20000000-0000-4000-8000-000000000006','listing','อาหาร & เครื่องดื่ม',true,5,'listing','listing_food','อาหาร & เครื่องดื่ม','တၢင်းၵိၼ် လႄႈ ၼမ်ႉ','Food & drinks','အစားအသောက်နှင့် သောက်စရာ',true),
  ('20000000-0000-4000-8000-000000000007','listing','อิเล็กทรอนิกส์',true,6,'listing','listing_electronics','อิเล็กทรอนิกส์','ဢီႇလႅၵ်ႉထရေႃးၼိၵ်ႉ','Electronics','အီလက်ထရွန်နစ်',true),
  ('20000000-0000-4000-8000-000000000008','listing','อื่นๆ',true,7,'listing','listing_other','อื่นๆ','တၢင်ႇမဵဝ်း','Other','အခြား',true)
on conflict (id) do update set
  legacy_key = excluded.legacy_key,
  name_th = excluded.name_th,
  name_shn = excluded.name_shn,
  name_en = excluded.name_en,
  name_my = excluded.name_my,
  sort_order = excluded.sort_order,
  updated_at = now();
commit;
