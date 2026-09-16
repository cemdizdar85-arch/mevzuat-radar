-- ============================================================================
--  ADIM 2 — PAKET SORU KASASI (ADIM2-PAKET-KASASI-PLANI.md madde 1 + 5)
--  Kaynak taslak: TASLAK-2026-09-15-paket-soru.sql. Cem kararları 16.09.2026:
--    K1 ders bazlı erişim EVET · K2 seviye testi cevap kontrolü sunucuda EVET.
--
--  Taslaktan farkı (16.09, site oturumu):
--    * seviye_kontrol IP'yi TARAYICIDAN almıyor. Taslakta p_ip istemciden geliyordu ve
--      boş gönderilince hız sınırı hiç işlemiyordu. Şimdi PostgREST'in ilettiği
--      x-forwarded-for başlığı okunuyor (istemci sahteleyemez; Supabase ağ geçidi yazar).
--    * sınır 40 kontrol / 10 dk (test 30 soru).
--
--  Basmadan önce ölçüldü (16.09): paket_soru 404 · ucretsiz_soru 404 · rpc/seviye_kontrol 404
--  (ad çakışması yok) · rate_limit_check(text,int,int) canlı, true döndü ·
--  paket_uyeler.dersler kolonu var (kurucu satırında null).
--
--  BASIM: düşük trafik saatinde, eşzamanlı sağlık izlemesiyle (14.09 PostgREST 503 dersi).
--  Bu tablo auth.users'a FK taşımıyor. Basınca UYGULANDI.md'ye satır.
-- ============================================================================

-- 1) KASA: yayındaki her Kaydır-Çöz sorusu tek satır -----------------------------
create table if not exists public.paket_soru (
  id          text primary key,                         -- 'etiket/kp-NN' (sayfadaki id ile aynı)
  sinav       text not null check (sinav in ('sgs','smmm','kgk')),
  ders        text not null,                            -- sayfadaki ekran adı ('Finansal Muhasebe')
  konu        text,
  sayfa       text not null,                            -- 'kaydir/sgs/finansal-muhasebe.html'
  sira        integer not null,                         -- sayfadaki sırası (#s= bağlantıları bozulmasın)
  ucretsiz    boolean not null default false,           -- vitrin / seviye testi sorusu
  veri        jsonb not null,                           -- TAM soru nesnesi (doğru + açıklama dahil)
  guncelleme  timestamptz not null default now()
);
create index if not exists paket_soru_ders_sira on public.paket_soru (sinav, ders, sira);

alter table public.paket_soru enable row level security;
revoke all on public.paket_soru from anon;
revoke all on public.paket_soru from authenticated;
grant select on public.paket_soru to authenticated;     -- yazma YOK: yalnız sunucu anahtarı (yükleyici)

-- Paket -> sınav eşlemesi uye-durumu.js paketSinavlari() ile BİREBİR (16.09 okundu):
--   boş / tam / kurucu -> hepsi · yeterlilik-kgk -> smmm+kgk · sgs, sgs-*, sinav-249 -> sgs ·
--   yeterlilik, yeterlilik-*, smmm -> smmm · kgk, kgk-* -> kgk.
-- 'son15' (Son 15 Gün planı) tarayıcıda da hiçbir sınavı açmıyor -> burada da soru erişimi VERMEZ.
drop policy if exists paket_soru_paketli_okur on public.paket_soru;
create policy paket_soru_paketli_okur on public.paket_soru
  for select to authenticated
  using (
    exists (
      select 1 from public.paket_uyeler pu
      where pu.user_id = auth.uid()
        and (pu.bitis is null or pu.bitis >= current_date)
        and (
          coalesce(nullif(lower(trim(pu.paket)),''),'tam') in ('tam','kurucu')
          or (paket_soru.sinav = 'sgs'  and (lower(trim(pu.paket)) = 'sgs' or lower(trim(pu.paket)) like 'sgs-%'
                                             or lower(trim(pu.paket)) = 'sinav-249'))
          or (paket_soru.sinav = 'smmm' and (lower(trim(pu.paket)) in ('yeterlilik','smmm','yeterlilik-kgk')
                                             or lower(trim(pu.paket)) like 'yeterlilik-%'))
          or (paket_soru.sinav = 'kgk'  and (lower(trim(pu.paket)) in ('kgk','yeterlilik-kgk')
                                             or lower(trim(pu.paket)) like 'kgk-%'))
        )
        -- K1: dersler NULL = tüm dersler; dolu ise yalnız seçilenler (satin-al.html ders adlarıyla)
        and (pu.dersler is null or paket_soru.ders = any(pu.dersler))
    )
  );

-- 2) ÜCRETSİZ GÖRÜNÜM: anonim okur, CEVAPSIZ ---------------------------------------
-- Beyaz liste: yalnız soruyu çözmek için gereken alanlar. Doğru şık, açıklama, teşhis, tuzak,
-- hap, kural, dayanak, çözüm tablosu GİTMEZ (K2).
create or replace view public.ucretsiz_soru as
  select id, sinav, ders, konu, sayfa, sira,
         jsonb_build_object('id', veri->'id', 'ders', veri->'ders', 'konu', veri->'konu', 'tip', veri->'tip',
                            'donem', veri->'donem', 'soru', veri->'soru', 'siklar', veri->'siklar',
                            'verilen', veri->'verilen', 'verilenler', veri->'verilenler') as veri
  from public.paket_soru
  where ucretsiz;
revoke all on public.ucretsiz_soru from anon, authenticated;
grant select on public.ucretsiz_soru to anon, authenticated;
-- NOT: görünüm tablo sahibinin yetkisiyle okur (security_invoker kapalı) — anonim kişi tabloya
-- DEĞİL, yalnız bu beyaz listeye erişir.

-- 3) SEVİYE TESTİ CEVAP KONTROLÜ: tek soru, tek cevap, sunucu IP'siyle hız sınırlı (K2) ----
-- Uyarlamalı test her cevaptan sonra doğru/yanlış bilmek zorunda ve sonuç ekranı "doğrusu X" gösterir;
-- bu yüzden doğru HARF döner, AÇIKLAMA dönmez (açıklama pakette). Bilinen sınır: bir IP 10 dakikada
-- 40 ücretsiz sorunun harfini öğrenebilir — ücretsiz katmanın bilinçli bedeli.
create or replace function public.seviye_kontrol(p_id text, p_secim text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $fn$
declare
  d  text;
  ip text;
begin
  ip := split_part(coalesce(
          (current_setting('request.headers', true)::json ->> 'x-forwarded-for'),
          (current_setting('request.headers', true)::json ->> 'x-real-ip'),
          'bilinmiyor'), ',', 1);
  if not public.rate_limit_check('seviye:' || trim(ip), 40, 600) then
    return jsonb_build_object('hata','cok fazla istek');
  end if;
  select veri->>'dogru' into d from public.paket_soru where id = p_id and ucretsiz;
  if d is null then return jsonb_build_object('hata','soru yok'); end if;
  return jsonb_build_object('dogru_mu', upper(coalesce(p_secim,'')) = upper(d), 'dogru', d);
end $fn$;
revoke all on function public.seviye_kontrol(text,text) from public;
grant execute on function public.seviye_kontrol(text,text) to anon, authenticated;

-- DOĞRULAMA (basımdan sonra, UYGULANDI.md'ye yazılır):
--   anonim:  paket_soru                                  -> 401/0 satır
--   anonim:  ucretsiz_soru veri içinde 'dogru' anahtarı  -> yok
--   anonim:  rpc/seviye_kontrol 41. çağrı / 10 dk        -> {"hata":"cok fazla istek"}
--   paketsiz üye: paket_soru                             -> 0 satır
--   'kurucu' üye: paket_soru count                       = yükleyicinin yazdığı satır sayısı (4.042, 16.09 kuru)
