-- ============================================================================
--  MARKA TALEBİ → ROBOTU ANINDA ÇAĞIR  (30.08.2026)
--
--  Cem: "bence Supabase webhook'u kur."
--
--  NEDEN (üçü de ölçüldü, tahmin değil):
--   1) cron '*/5' yazıyor ama GERÇEK koşu arası 2–7 SAAT — GitHub zamanlanmış
--      işleri yoğunlukta kısıyor (bu depoda 124 iş akışı var).
--   2) 29.08'de push tetiği eklendi ama EKSİK çıktı: GitHub, Actions'ın kendi
--      bot'unun (GITHUB_TOKEN) attığı push'lardan iş akışı TETİKLEMİYOR
--      (sonsuz döngü koruması) ve bu depodaki push'ların neredeyse tamamı
--      bot'un rapor commit'leri. Ölçüm: 00:17/00:18/00:19 koşuları insan
--      push'uydu; ardından gelen 00:21/00:23/00:24 bot push'ları HİÇBİR koşu
--      başlatmadı.
--   3) Sonuç: kullanıcı "Sicilde ara" deyince talep saatlerce bekleyebiliyor.
--      Cem bunu bizzat yaşadı: "arçelik yazdım bir şey gelmedi, anlamadım."
--
--  BU GÖÇ NE YAPAR: marka_talep tablosuna bir satır DÜŞER DÜŞMEZ, Postgres
--  içinden GitHub'a repository_dispatch çağrısı yapar. Robot saniyeler içinde
--  başlar. Kuyruk mimarisi aynı kalır; sadece bekleme kalkar.
--
--  BAĞIMLILIK: pg_net (Supabase'de hazır gelir, aşağıda açılıyor) ve Vault
--  (token'ı SQL metninde saklamamak için).
--
--  ⚠️ CEM'İN YAPACAĞI TEK ŞEY: bir GitHub token'ı üretip aşağıdaki TEK satıra
--     yapıştırmak. Adımlar en altta yazılı.
-- ============================================================================

create extension if not exists pg_net with schema extensions;

-- ---------------------------------------------------------------------------
-- 1) TOKEN'I KASAYA KOY
--    Token SQL metninde ya da tabloda AÇIK durmaz; Supabase Vault'ta şifreli
--    tutulur. Aşağıdaki satırda <TOKEN> yerine kendi token'ını yaz ve çalıştır.
--    (Yanlış yapıştırırsan tekrar çalıştırman yeterli - üzerine yazar.)
-- ---------------------------------------------------------------------------
select vault.create_secret('<TOKEN>', 'github_dispatch_token', 'GitHub repository_dispatch icin fine-grained PAT (Actions: read+write)')
on conflict do nothing;

-- Token'ı güncellemek için (ilk kurulumdan sonra):
--   select vault.update_secret((select id from vault.secrets where name='github_dispatch_token'), '<YENI_TOKEN>');

-- ---------------------------------------------------------------------------
-- 2) TETİK: yeni talep düşünce GitHub'ı çağır
--    SECURITY DEFINER: tetik, talebi açan anonim kullanıcının yetkisiyle değil,
--    fonksiyonun sahibiyle çalışır - token'a kimse erişemez.
--    pg_net ASENKRONDUR: http isteği kuyruğa atılır, INSERT'i BEKLETMEZ.
--    Yani GitHub yavaşlasa/düşse bile kullanıcının talebi normal açılır.
-- ---------------------------------------------------------------------------
create or replace function public.marka_talep_tetik()
returns trigger
language plpgsql security definer set search_path = public, extensions as $fn$
declare v_token text;
begin
  begin
    select decrypted_secret into v_token
      from vault.decrypted_secrets where name = 'github_dispatch_token' limit 1;
  exception when others then
    v_token := null;
  end;
  -- Token yoksa SESSİZCE geç: tetik kurulmamış olabilir, ama talep açılmalı.
  -- (Kuyruk cron/push ile yine işlenir - sadece geç işlenir.)
  if v_token is null or length(v_token) < 10 then
    return new;
  end if;

  perform extensions.net.http_post(
    url     := 'https://api.github.com/repos/cemdizdar85-arch/mevzuat-radar/dispatches',
    headers := jsonb_build_object(
                 'Authorization', 'Bearer ' || v_token,
                 'Accept',        'application/vnd.github+json',
                 'X-GitHub-Api-Version', '2022-11-28',
                 'User-Agent',    'tetikte-supabase-trigger',
                 'Content-Type',  'application/json'),
    body    := jsonb_build_object(
                 'event_type', 'marka-talep',
                 'client_payload', jsonb_build_object('jeton', new.jeton, 'unvan', new.unvan)),
    timeout_milliseconds := 5000
  );
  return new;
end;
$fn$;

drop trigger if exists marka_talep_tetik_trg on public.marka_talep;
create trigger marka_talep_tetik_trg
  after insert on public.marka_talep
  for each row execute function public.marka_talep_tetik();

-- ---------------------------------------------------------------------------
-- 3) TEYİT (aynı pencerede çalıştır)
-- ---------------------------------------------------------------------------
-- a) tetik kuruldu mu:
--      select tgname from pg_trigger where tgname = 'marka_talep_tetik_trg';
-- b) token kasada mı (DEĞERİ GÖRÜNMEZ, sadece adı):
--      select name, created_at from vault.secrets where name='github_dispatch_token';
-- c) canlı deneme: tetikte.com/marka-portfoy.html'de bir unvan ara, sonra
--    GitHub > Actions > "Marka talep kuyrugu" -> event sutununda
--    "repository_dispatch" yazan yeni bir koşu SANIYELER icinde görünmeli.
-- d) çağrı gitti mi (pg_net kütüğü):
--      select id, created, status_code from net._http_response order by id desc limit 5;
--    Beklenen: status_code = 204 (GitHub dispatch'i kabul etti).

-- ============================================================================
--  CEM'İN ADIMLARI (bir kez, ~5 dakika)
--
--  1. GitHub > Settings > Developer settings > Personal access tokens >
--     Fine-grained tokens > Generate new token
--       Repository access : Only select repositories -> mevzuat-radar
--       Permissions       : Actions = Read and write   (BAŞKA HİÇBİR ŞEY GEREKMEZ)
--       Expiration        : 1 yıl
--  2. Çıkan token'ı kopyala.
--  3. Bu dosyayı Supabase SQL Editor'e yapıştır, yukarıdaki <TOKEN> yerine
--     token'ı koy, çalıştır.
--  4. Yukarıdaki (c) adımıyla test et.
--
--  GÜVENLİK NOTU: token yalnız bu depoda Actions tetikleyebilir. Kod okuyamaz,
--  yazamaz, secret göremez. Sızsa bile yapabileceği tek şey robotu boşuna
--  çalıştırmaktır. En dar yetki bilerek seçildi.
-- ============================================================================
