-- ============================================================================
--  ⏸ TASLAK — BASILMADI. Adım 2 (ADIM2-PAKET-KASASI-PLANI.md madde 1 + 5).
--  Basma koşulu: kart ödemesi onayı haftası + Cem'in 3 kararı. Basmadan önce:
--    1) information_schema ile tablo/politika adları çakışıyor mu bak (30.08 dersi:
--       "create if not exists" var olan eksik şemayı SESSİZCE bırakır).
--    2) DÜŞÜK TRAFİK saatinde bas, eşzamanlı sağlık izle (14.09: auth.users FK'lı tablo
--       basılırken PostgREST ~2-3 dk 503 verdi).
--    3) UYGULANDI.md'ye satır + ölçüm.
--
--  VARSAYILAN KARARLAR (GM önerisi, Cem teyidi BEKLİYOR — değişirse bu dosya değişir):
--    K1 ders bazlı erişim: EVET  -> paket_uyeler.dersler doluysa yalnız o dersler.
--    K2 seviye testi cevap kontrolü sunucuda: EVET -> ücretsiz görünümde doğru şık YOK.
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

-- Paket -> sınav eşlemesi (fiyat-motoru.js kimlikleri): sgs · yeterlilik-N / yeterlilik-tum -> smmm ·
-- kgk-M / kgk-tum -> kgk · yeterlilik-kgk -> smmm+kgk · tam / kurucu -> hepsi.
drop policy if exists paket_soru_paketli_okur on public.paket_soru;
create policy paket_soru_paketli_okur on public.paket_soru
  for select to authenticated
  using (
    exists (
      select 1 from public.paket_uyeler pu
      where pu.user_id = auth.uid()
        and (pu.bitis is null or pu.bitis >= current_date)
        and (
          coalesce(pu.paket,'tam') in ('tam','kurucu')
          or (paket_soru.sinav = 'sgs'  and pu.paket like 'sgs%')
          or (paket_soru.sinav = 'smmm' and (pu.paket like 'yeterlilik%'))
          or (paket_soru.sinav = 'kgk'  and (pu.paket like 'kgk%' or pu.paket = 'yeterlilik-kgk'))
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
grant select on public.ucretsiz_soru to anon, authenticated;
-- NOT: görünüm tablo sahibinin yetkisiyle okur (security_invoker kapalı) — anonim kişi tabloya
-- DEĞİL, yalnız bu beyaz listeye erişir. Basmadan önce `select veri from ucretsiz_soru limit 1`
-- anonim anahtarla denenip 'dogru' anahtarı olmadığı ÖLÇÜLECEK.

-- 3) SEVİYE TESTİ CEVAP KONTROLÜ: tek soru, tek cevap, hız sınırlı (K2) ------------
create or replace function public.seviye_kontrol(p_id text, p_secim text, p_ip text default '')
returns jsonb
language plpgsql
security definer
set search_path = public
as $fn$
declare d text;
begin
  if p_ip <> '' and not public.rate_limit_check('seviye:'||p_ip, 60, 600) then
    return jsonb_build_object('hata','cok fazla istek');
  end if;
  select veri->>'dogru' into d from public.paket_soru where id = p_id and ucretsiz;
  if d is null then return jsonb_build_object('hata','soru yok'); end if;
  -- yalnız doğru/yanlış ve doğru harf döner; açıklama DÖNMEZ (açıklama pakette)
  return jsonb_build_object('dogru_mu', upper(coalesce(p_secim,'')) = d, 'dogru', d);
end $fn$;
revoke all on function public.seviye_kontrol(text,text,text) from public;
grant execute on function public.seviye_kontrol(text,text,text) to anon, authenticated;

-- DOĞRULAMA (basımdan sonra, UYGULANDI.md'ye yazılır):
--   anonim:  select count(*) from paket_soru            -> 0 satır (RLS)
--   anonim:  select veri ? 'dogru' from ucretsiz_soru   -> hepsi false
--   paketsiz üye: paket_soru                            -> 0 satır
--   'kurucu' üye: paket_soru count                      = yükleyicinin yazdığı satır sayısı
