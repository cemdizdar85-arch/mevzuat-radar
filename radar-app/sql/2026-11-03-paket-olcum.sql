-- ============================================================================
-- PAKET ÖLÇÜMÜ (03.11.2026, site kolu; Cem "denenmeyenleri yapalım"). ŞEMA DEĞİŞTİRMEZ; sahte üye işlemleri geri alınır.
-- Günlük herkese açık (depo public): YALNIZ SAYI basılır — e-posta, ad, sipariş no, kimlik basılmaz.
--
--  K) GERÇEK KASA İÇERİĞİ, DERS PAKETLİ ÜYE: sahte üye yeterlilik-2 [Hukuk, Vergi] → kasa_soru_idler gerçek paket_soru
--     kimlikleriyle (Hukuk 3 · Vergi 3 · Finansal Muhasebe 3) çağrılır, auth.uid() set_config ile taklit.
--     Beklenen: 6 soru döner, hepsinin veri.soru/siklar/dogru dolu; Finansal Muhasebe 0.
--  O) KART ÖDEMESİ YOLU (iyzico dönüşü kart_siparis_odendi): yeterlilik-1 [Hukuk] açık sahte üye + yeterlilik-1 [Vergi]
--     siparişi odeme_bekliyor → kart_siparis_odendi → paket yeterlilik-2 [Vergi, Hukuk]. (Gerçek kart çekimi YOK.)
--  L) KAYIP SAYIMI (canlı veri, okuma): ödenmiş, süresi sürmekte olan her siparişin paketi hesabında açık mı?
--     Açık değilse neden: hesap yok · hesap var bağlanmamış · başka sınav paketi üstüne yazmış · ders eksik ·
--     paket süresi bitmiş · üyelik iptal kaydı var (bilerek kapatılmış).
--  S) İKİ SINAV ÇAKIŞMASI: ödenmiş süren siparişi iki ayrı sınav ailesinde olan hesap sayısı.
-- Uygulanma: sql-uygula.yml (push ile otomatik). Hepsi NOTICE; ölçü düşerse göç KIRMIZI.
-- ============================================================================
do $$
declare
  a constant uuid := '00000000-0000-4000-8000-0000000c1a01';
  b constant uuid := '00000000-0000-4000-8000-0000000c1a02';
  ids text[]; n int; n_dolu int; n_fm int; v jsonb; r public.paket_uyeler%rowtype;
begin
  begin
    insert into auth.users (id, instance_id, aud, role, email, created_at, updated_at) values
      (a, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'olcu-pk-a@tetikte.invalid', now(), now()),
      (b, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'olcu-pk-b@tetikte.invalid', now(), now());
    delete from public.paket_uyeler where user_id in (a, b);
    insert into public.paket_uyeler (user_id, paket, bitis, dersler) values
      (a, 'yeterlilik-2', current_date + 30, array['Hukuk', 'Vergi Mevzuatı ve Uygulaması']),
      (b, 'yeterlilik-1', current_date + 30, array['Hukuk']);

    -- K) kasa
    select array_agg(id) into ids from (
      (select id from public.paket_soru where sinav = 'smmm' and ders = 'Hukuk' and not ucretsiz order by id limit 3)
      union all (select id from public.paket_soru where sinav = 'smmm' and ders = 'Vergi Mevzuatı ve Uygulaması' and not ucretsiz order by id limit 3)
      union all (select id from public.paket_soru where sinav = 'smmm' and ders = 'Finansal Muhasebe' and not ucretsiz order by id limit 3)) t;
    if coalesce(cardinality(ids), 0) <> 9 then raise exception 'OLCU: kasada 3+3+3 ornek soru bulunamadi (%)', cardinality(ids); end if;
    perform set_config('request.jwt.claims', json_build_object('sub', a::text, 'role', 'authenticated')::text, true);
    perform set_config('request.jwt.claim.sub', a::text, true);
    select count(*), count(*) filter (where k.veri ? 'soru' and k.veri ? 'siklar' and k.veri ? 'dogru'
                                          and length(coalesce(k.veri ->> 'soru', '')) > 20 and (k.veri ->> 'dogru') ~ '^[A-E]$'),
           count(*) filter (where s.ders = 'Finansal Muhasebe')
      into n, n_dolu, n_fm
      from public.kasa_soru_idler(ids) k join public.paket_soru s on s.id = k.id;
    perform set_config('request.jwt.claims', '', true);
    perform set_config('request.jwt.claim.sub', '', true);
    raise notice 'OLCU K kasa: yeterlilik-2 [Hukuk,Vergi] uye 9 kimlik istedi -> % soru dondu, icerigi dolu %, Finansal Muhasebe %', n, n_dolu, n_fm;
    if n <> 6 or n_dolu <> 6 or n_fm <> 0 then raise exception 'OLCU: kasa ders kilidi beklenen gibi degil (% / % / %)', n, n_dolu, n_fm; end if;

    -- O) kart ödemesi yolu
    insert into public.siparisler (siparis_no, paket, tutar, ad_soyad, email, odeme, durum, secilen_dersler)
    values ('TT-20261103-PK01', 'yeterlilik-1', 2988, 'Olcu Pk B', 'olcu-pk-b@tetikte.invalid', 'havale', 'odeme_bekliyor', array['Vergi Mevzuatı ve Uygulaması']);
    v := public.kart_siparis_odendi('TT-20261103-PK01', 'olcu');
    select * into r from public.paket_uyeler where user_id = b;
    raise notice 'OLCU O kart yolu: sonuc % -> paket % dersler %', v ->> 'sonuc', r.paket, r.dersler;
    if v ->> 'sonuc' <> 'ACILDI' or r.paket <> 'yeterlilik-2' or r.dersler <> array['Vergi Mevzuatı ve Uygulaması', 'Hukuk'] then
      raise exception 'OLCU: kart yolu birlestirmedi'; end if;

    raise exception 'OLCU_TAMAM';
  exception when others then
    if sqlerrm <> 'OLCU_TAMAM' then raise; end if;
  end;
  if exists (select 1 from public.siparisler where siparis_no = 'TT-20261103-PK01')
     or exists (select 1 from auth.users where email like 'olcu-pk-%@tetikte.invalid')
     or exists (select 1 from public.paket_uyeler where user_id in (a, b)) then
    raise exception 'OLCU: geri alma iz birakti';
  end if;
end $$;

-- L + S) canlı veri sayımı (yalnız okuma, yalnız sayı)
do $$
declare x record;
begin
  for x in
    with sip as (
      select s.id, s.paket, s.secilen_dersler, coalesce(s.paket_bitis, current_date) as sbitis, public._paket_sinavi(s.paket) as aile,
             coalesce(s.bagli_kullanici, (select u.id from auth.users u where lower(u.email) = lower(s.email) limit 1)) as uid,
             s.bagli_kullanici is not null as bagli
        from public.siparisler s
       where s.durum = 'odendi' and coalesce(s.paket_bitis, current_date) >= current_date
      ),
    d as (
      select sip.*, p.paket as upaket, p.bitis as ubitis, p.dersler as uders, public._paket_sinavi(p.paket) as uaile,
             exists (select 1 from public.uye_islem_kutugu k where k.user_id = sip.uid and k.islem = 'iptal') as iptal
        from sip left join public.paket_uyeler p on p.user_id = sip.uid ),
    k as (
      select d.*, case
        when uid is null then '1 hesap yok (uye olunca acilir)'
        when iptal then '2 uyelik iptal kaydi var (bilerek kapali)'
        when upaket is null then '3 hesap var, paket satiri yok'
        when ubitis < current_date then '4 paket suresi bitmis gorunuyor'
        when lower(upaket) in ('tam', 'kurucu') then '0 ACIK'
        when aile is null then case when lower(upaket) = lower(paket) then '0 ACIK' else '5 baska paket ustune yazmis (son20/diger)' end
        when uaile is distinct from aile then '5 baska sinav paketi ustune yazmis'
        when uders is null or coalesce(array_length(secilen_dersler, 1), 0) = 0 then '0 ACIK'
        when secilen_dersler <@ uders then '0 ACIK'
        else '6 ders eksik (secilen ders hesapta kapali)' end as durum
      from d )
    select durum, count(*) as siparis, count(distinct uid) as hesap from k group by durum order by durum
  loop
    raise notice 'OLCU L odenmis+suren siparis: % -> % siparis, % hesap', x.durum, x.siparis, x.hesap;
  end loop;

  for x in
    select count(*) as hesap from (
      select coalesce(s.bagli_kullanici, (select u.id from auth.users u where lower(u.email) = lower(s.email) limit 1)) as uid
        from public.siparisler s
       where s.durum = 'odendi' and coalesce(s.paket_bitis, current_date) >= current_date and public._paket_sinavi(s.paket) is not null
       group by 1 having count(distinct public._paket_sinavi(s.paket)) > 1 ) t where uid is not null
  loop
    raise notice 'OLCU S iki ayri sinav ailesinde odenmis suren siparisi olan hesap: %', x.hesap;
  end loop;
end $$;
