-- ============================================================================
--  MARKA AYNASI — TÜRKPATENT sicilinin kendi kopyamız  (29.08.2026)
--
--  Cem: "kendi aynamız kuralım bir yere bağımlı olmayalım... günlük
--  güncellememizi yaparsak zaten bundan sonra hep doğru gitmiş oluruz ve
--  kimseye muhtaç olmayız."
--
--  NEDEN
--  Bugüne kadar her unvan araması TMview'e canlı gidiyordu. Üç sonucu vardı:
--   1) CORS kapalı olduğu için tarayıcı çağıramıyor -> robot kuyruğu -> bekleme
--   2) tek sorguda 10.000 kayıt tavanı
--   3) kaynak bir gün kapanırsa/yavaşlarsa ürünün marka ayağı durur
--  Ayna üçünü birden kapatır: arama ANLIK bir SQL sorgusuna döner.
--
--  ÖLÇÜM (29.08, TMview'den):
--    toplam TR kaydı ............ 2.820.840
--    tescilli (yaşayan) ......... 573.303
--    dilim ölçüsü ............... bir ay ~10.787 (tavana değiyor), bir gün ~652
--    dilim süzgeci .............. fADateRanges: ["2026-01-01..2026-06-30"]
--                                 (dizi + "başlangıç..bitiş" METNİ; başka
--                                 hiçbir biçim kabul edilmiyor - HTTP 400)
--
--  BOYUT: satır ~200 bayt -> ~560 MB veri + indeksler. Supabase Pro'da 8 GB var.
--
--  GİZLİLİK / RLS: bu tablo DIŞARI KAPALI (policy yok). Dışarıya yalnız
--  aşağıdaki SECURITY DEFINER fonksiyon açılır ve o da tavanlı. Alacak/ihale
--  kasası deseninin aynısı: veri bizde, cevap ölçülü.
--
--  Supabase SQL Editor'de BİR KEZ çalıştır.
-- ============================================================================

create table if not exists public.marka_ayna (
  st13        text primary key,              -- TMview'in kalıcı kimliği (TR50...)
  no          text,                          -- başvuru numarası (2026-097164)
  ad          text,
  ad_norm     text,                          -- aramada kullanılan sadeleştirilmiş ad
  basvuru     date,
  tescil      date,
  bitis       date,                          -- KESİN koruma bitişi (detay ucundan; boş olabilir)
  durum       text,                          -- sicildeki durum (Registered/Ended/...)
  sinif       text,                          -- Nice sınıfları, virgüllü
  sahip       text,
  sahip_norm  text,                          -- unvan aramasında kullanılan sadeleştirilmiş sahip
  vekil       text,
  yenileme    int  default 0,                -- yenileme kaydı sayısı (detay ucundan)
  son_yenileme date,
  detay       boolean default false,         -- detay ucundan zenginleştirildi mi
  guncelleme  timestamptz default now()
);

alter table public.marka_ayna enable row level security;
-- POLICY YOK = dışarıya kapalı. Erişim yalnız aşağıdaki fonksiyonla.

-- Unvan araması: sahip adına göre. Sicilde unvan yazımı oynadığı için
-- normalize edilmiş sütun üzerinde ÖNEK araması yapılır.
create index if not exists marka_ayna_sahip_idx   on public.marka_ayna (sahip_norm text_pattern_ops);
create index if not exists marka_ayna_ad_idx      on public.marka_ayna (ad_norm text_pattern_ops);
create index if not exists marka_ayna_basvuru_idx on public.marka_ayna (basvuru);
create index if not exists marka_ayna_bitis_idx   on public.marka_ayna (bitis) where bitis is not null;

-- Hasat ilerlemesi: 2,8 milyon kayıt tek koşuda çekilemez. Hangi tarih dilimi
-- bitti, kütüğe yazılır; robot ertesi gece kaldığı yerden devam eder.
create table if not exists public.marka_ayna_dilim (
  dilim      text primary key,               -- "2026-01-01..2026-01-07"
  adet       int,
  cekilen    int,
  durum      text default 'bekliyor',        -- bekliyor | bitti | hata
  deneme     int default 0,
  guncelleme timestamptz default now()
);
alter table public.marka_ayna_dilim enable row level security;

-- ---------------------------------------------------------------------------
--  DIŞARIYA AÇILAN TEK KAPI: unvandan marka listesi
--  Tavanlı (varsayılan 2.000), yalnız gerekli sütunlar.
-- ---------------------------------------------------------------------------
create or replace function public.marka_ayna_sahip(p_unvan text, p_tavan int default 2000)
returns table (
  st13 text, no text, ad text, basvuru date, tescil date, bitis date,
  durum text, sinif text, sahip text, vekil text, yenileme int, son_yenileme date, detay boolean
)
language plpgsql security definer set search_path = public as $fn$
declare v_n text;
begin
  if p_unvan is null or length(btrim(p_unvan)) < 3 then
    raise exception 'Unvan en az 3 karakter olmali';
  end if;
  -- Sadeleştirme SQL tarafında da yapılır ki istemci ile robot AYNI kuralı kullansın.
  v_n := lower(btrim(p_unvan));
  v_n := translate(v_n, 'çğıöşüâîû', 'cgiosuaiu');
  v_n := regexp_replace(v_n, '[^a-z0-9]', '', 'g');
  if length(v_n) < 3 then raise exception 'Unvan en az 3 harf icermeli'; end if;

  return query
    select m.st13, m.no, m.ad, m.basvuru, m.tescil, m.bitis, m.durum, m.sinif,
           m.sahip, m.vekil, m.yenileme, m.son_yenileme, m.detay
    from public.marka_ayna m
    where m.sahip_norm like v_n || '%'
    order by m.bitis nulls last, m.basvuru desc
    limit least(greatest(p_tavan, 1), 5000);
end;
$fn$;

revoke all on function public.marka_ayna_sahip(text, int) from public;
grant execute on function public.marka_ayna_sahip(text, int) to anon, authenticated;

-- Ayna sağlığı: sayfa "ayna hazır mı" diye sorabilsin diye küçük bir özet.
create or replace function public.marka_ayna_durum()
returns table (kayit bigint, detayli bigint, dilim_bitti bigint, dilim_toplam bigint, son_guncelleme timestamptz)
language sql security definer set search_path = public as $fn$
  select (select count(*) from public.marka_ayna),
         (select count(*) from public.marka_ayna where detay),
         (select count(*) from public.marka_ayna_dilim where durum='bitti'),
         (select count(*) from public.marka_ayna_dilim),
         (select max(guncelleme) from public.marka_ayna);
$fn$;
revoke all on function public.marka_ayna_durum() from public;
grant execute on function public.marka_ayna_durum() to anon, authenticated;

-- Bastıktan sonra TEK SATIRLIK TEYİT (aynı pencerede):
--   select * from public.marka_ayna_durum();
-- Beklenen: hepsi 0 (tablo boş, robot henüz koşmadı) ve HATA YOK.
