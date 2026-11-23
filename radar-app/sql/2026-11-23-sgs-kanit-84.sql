-- ============================================================================
-- SGS 21.11.2026 KANIT SAYFASI (Cem 23.11: "bu sayfa bu sayfa diye gerçek olduğunu görsünler")
-- Sayfa: sgs-21-kasim-2026-84.html. 21 Kasım SGS'nin (A kitapçığı) 84 alan sorusunun bilgisi Tetikte'de vardı;
-- sayfa her sınav numarasının karşısındaki Tetikte sorusunu soru + şıklar + doğru + açıklamayla ÜCRETSİZ gösterir.
--
-- GÜVENLİK: paket_soru'ya dokunulmaz (RLS yalnız paketliye açık kalır, ucretsiz bayrağı değişmez — seviye testi /
-- vitrin havuzu etkilenmez). Yeni tablo kanit_soru (liste, n -> id) RLS açık + politika YOK: anon/üye okuyamaz.
-- Tek kapı kanit_sorusu(p_liste, p_n): yalnız kanit_soru'da kayıtlı (liste, n) çiftinin sorusunu döner; kimlikle
-- değil sınav numarasıyla çağrılır, bankanın başka bir sorusu bu yoldan açılamaz. IP başına 10 dakikada 200 çağrı.
-- Eşleşme kaynağı: _yerel-veri-kasasi/sgs-2026-3-eslesme-84.json (ana oturum her çifti okudu, 23.11.2026); her
-- sorunun İLK dayanak kimliği.
-- Öz-sınav göç içinde: 84 satırın 84'ü kasada · liste dışı numara boş · anon çalıştırabilir · tablo anon'a kapalı.
-- Otomatik uygulanır: .github/workflows/sql-uygula.yml
-- ============================================================================
create table if not exists public.kanit_soru (
  liste text not null,
  n     integer not null,
  id    text not null,
  primary key (liste, n)
);
alter table public.kanit_soru enable row level security;
revoke all on public.kanit_soru from anon, authenticated;

delete from public.kanit_soru where liste = 'sgs-2026-3';
insert into public.kanit_soru (liste, n, id) values
  ('sgs-2026-3', 31, 'sgs-t1-fmuh-kolay/kp-42'),
  ('sgs-2026-3', 32, 'smmm-s20-fmuh-g1-cokzor/kp-05'),
  ('sgs-2026-3', 34, 'sgs-d2-fmuh-zor-r1/kp-25'),
  ('sgs-2026-3', 35, 'sgs-t1-fmuh-kolay-b/kp-184'),
  ('sgs-2026-3', 36, 'sgs-t1-fmuh-kolay-b/kp-188'),
  ('sgs-2026-3', 37, 'sgs-t1-fmuh-kolay-b/kp-92'),
  ('sgs-2026-3', 38, 'sgs-t1-ticaret-kolay/kp-17'),
  ('sgs-2026-3', 39, 'sgs-d3-fmuh-kolay-r2/kp-06'),
  ('sgs-2026-3', 40, 'smmm-w9-3-fmuh-kolay/kp-09'),
  ('sgs-2026-3', 41, 'sgs-t2-fmuh-kolay/kp-108'),
  ('sgs-2026-3', 42, 'smmm-gm5-3-fmuh-zor/kp-05'),
  ('sgs-2026-3', 43, 'sgs-c5-fmuh-zor-r1-2/kp-11'),
  ('sgs-2026-3', 44, 'sgs-c5-fmuh-zor-r1-2/kp-17'),
  ('sgs-2026-3', 45, 'sgs-t4-fmuh-kolay/kp-12'),
  ('sgs-2026-3', 46, 'sgs-t1-fmuh-cokzor-b/kp-158'),
  ('sgs-2026-3', 47, 'sgs-k1-fmuh-cokzor/kp-12'),
  ('sgs-2026-3', 49, 'kgk-t3-tms-g1-kolay/kp-06'),
  ('sgs-2026-3', 50, 'sgs-t2-fmuh-kolay/kp-46'),
  ('sgs-2026-3', 51, 'kgk-t3-tms-g4-kolay/kp-02'),
  ('sgs-2026-3', 53, 'sgs-t2-fmuh-zor/kp-51'),
  ('sgs-2026-3', 54, 'sgs-c2-fmuh-cokzor-r2/kp-02'),
  ('sgs-2026-3', 57, 'sgs-d5-maliyet-zor-r1/kp-02'),
  ('sgs-2026-3', 58, 'sgs-k5-maliyet-zor/kp-06'),
  ('sgs-2026-3', 59, 'sgs-p-mta-cokzor-r1-a/kp-07'),
  ('sgs-2026-3', 60, 'smmm-4k-a-maliyet-zor-r1/kp-10'),
  ('sgs-2026-3', 61, 'sgs-t4-fmuh-kolay/kp-18'),
  ('sgs-2026-3', 62, 'sgs-p-maliyet-cokzor-r4-b2/kp-03'),
  ('sgs-2026-3', 63, 'sgs-p-fmuh-cokzor-r3/kp-17'),
  ('sgs-2026-3', 64, 'sgs-t2b-maliyet-cokzor/kp-01'),
  ('sgs-2026-3', 65, 'kgk-t5-fy-g3-zor/kp-04'),
  ('sgs-2026-3', 66, 'sgs-t1-mta-cokzor/kp-11'),
  ('sgs-2026-3', 67, 'sgs-c2-mta-zor-r2/kp-01'),
  ('sgs-2026-3', 68, 'sgs-t2b-mta-zor/kp-19'),
  ('sgs-2026-3', 69, 'sgs-t2b-mta-zor/kp-15'),
  ('sgs-2026-3', 70, 'sgs-t1-mta-cokzor/kp-14'),
  ('sgs-2026-3', 71, 'sgs-t1-mta-kolay/kp-32'),
  ('sgs-2026-3', 72, 'sgs-t2b-mta-kolay/kp-10'),
  ('sgs-2026-3', 73, 'kgk-d1b-tds-kolay-1/kp-22'),
  ('sgs-2026-3', 74, 'sgs-t5-denetim-kolay/kp-07'),
  ('sgs-2026-3', 75, 'sgs-k2-denetim-zor/kp-14'),
  ('sgs-2026-3', 76, 'kgk-d1-tds-zor-1/kp-15'),
  ('sgs-2026-3', 77, 'sgs-t5-denetim-kolay/kp-26'),
  ('sgs-2026-3', 78, 'sgs-t1-denetim-zor/kp-42'),
  ('sgs-2026-3', 80, 'sgs-t1-denetim-zor/kp-39'),
  ('sgs-2026-3', 81, 'sgs-t1-denetim-zor/kp-64'),
  ('sgs-2026-3', 82, 'sgs-k2-denetim-zor/kp-15'),
  ('sgs-2026-3', 83, 'kgk-d1-tds-zor-1/kp-18'),
  ('sgs-2026-3', 84, 'kgk-d1-tds-zor-3/kp-01'),
  ('sgs-2026-3', 85, 'sgs-t1-denetim-kolay/kp-57'),
  ('sgs-2026-3', 86, 'sgs-k7-denetim-zor/kp-03'),
  ('sgs-2026-3', 87, 'sgs-p-denetim-zor-r2/kp-09'),
  ('sgs-2026-3', 89, 'sgs-t1-genel-ekonomi-kolay/kp-31'),
  ('sgs-2026-3', 90, 'sgs-t1-genel-ekonomi-zor/kp-22'),
  ('sgs-2026-3', 91, 'sgs-e16-ekonomi-kolay/kp-14'),
  ('sgs-2026-3', 92, 'sgs-k13b-ekonomi-kolay/kp-01'),
  ('sgs-2026-3', 93, 'sgs-t1-genel-ekonomi-zor/kp-01'),
  ('sgs-2026-3', 94, 'sgs-d5-ekonomi-zor-r2/kp-03'),
  ('sgs-2026-3', 95, 'sgs-k2-maliye-zor/kp-02'),
  ('sgs-2026-3', 97, 'sgs-t4-maliye-kolay/kp-17'),
  ('sgs-2026-3', 98, 'sgs-e16-maliye-kolay/kp-01'),
  ('sgs-2026-3', 99, 'sgs-t4-maliye-kolay/kp-10'),
  ('sgs-2026-3', 101, 'sgs-a6e-meslek-kolay/kp-01'),
  ('sgs-2026-3', 103, 'sgs-c2-meslek-kolay-r3/kp-01'),
  ('sgs-2026-3', 104, 'sgs-a6e-meslek-cokzor/kp-21'),
  ('sgs-2026-3', 105, 'sgs-d3-meslek-cokzor-r1/kp-03'),
  ('sgs-2026-3', 106, 'smmm-4k-a-ymeslek-zor-r6/kp-10'),
  ('sgs-2026-3', 107, 'smmm-w7-2-yhukuk-cokzor/kp-01'),
  ('sgs-2026-3', 108, 'sgs-p-issgk-zor-r3-a/kp-05'),
  ('sgs-2026-3', 109, 'sgs-d3-issgk-cokzor-r4/kp-01'),
  ('sgs-2026-3', 110, 'sgs-p-issgk-zor-r1-a/kp-02'),
  ('sgs-2026-3', 112, 'sgs-k2-issgk-cokzor/kp-05'),
  ('sgs-2026-3', 113, 'smmm-4k-a-yvergi-kolay-r1/kp-14'),
  ('sgs-2026-3', 114, 'sgs-c5-vergi-zor-r2/kp-07'),
  ('sgs-2026-3', 116, 'sgs-c2-vergi-cokzor-r1/kp-01'),
  ('sgs-2026-3', 118, 'sgs-k13b-vergi-zor/kp-02'),
  ('sgs-2026-3', 119, 'sgs-t5-ticaret-zor/kp-12'),
  ('sgs-2026-3', 122, 'sgs-c5-ticaret-cokzor-r1/kp-05'),
  ('sgs-2026-3', 124, 'sgs-t5-ticaret-cokzor/kp-12'),
  ('sgs-2026-3', 125, 'sgs-t1-ticaret-zor/kp-42'),
  ('sgs-2026-3', 126, 'sgs-k5-borclar-zor/kp-04'),
  ('sgs-2026-3', 127, 'sgs-k2-borclar-cokzor/kp-03'),
  ('sgs-2026-3', 128, 'sgs-t1-borclar-kolay/kp-11'),
  ('sgs-2026-3', 129, 'sgs-c5-borclar-zor-r2/kp-05'),
  ('sgs-2026-3', 130, 'sgs-c2-borclar-kolay-r1/kp-04')
;

create or replace function public.kanit_sorusu(p_liste text, p_n integer)
returns jsonb
language plpgsql
security definer
set search_path = public
as $fn$
declare
  ip  text;
  sid text;
  p   record;
  v   jsonb;
  day text;
begin
  ip := split_part(coalesce(
          (current_setting('request.headers', true)::json ->> 'x-forwarded-for'),
          (current_setting('request.headers', true)::json ->> 'x-real-ip'),
          'bilinmiyor'), ',', 1);
  if not public.rate_limit_check('kanit:' || trim(ip), 200, 600) then
    return jsonb_build_object('hata','cok fazla istek');
  end if;
  select k.id into sid from public.kanit_soru k where k.liste = left(coalesce(p_liste,''), 40) and k.n = p_n;
  if sid is null then return jsonb_build_object('hata','listede yok'); end if;
  select ps.id, ps.sinav, ps.ders, ps.konu, ps.veri into p from public.paket_soru ps where ps.id = sid;
  if p.id is null then return jsonb_build_object('hata','soru yok', 'n', p_n); end if;
  v := p.veri;
  day := regexp_replace(coalesce(v->>'dayanak',''), '\s*\(teori notu:[^)]*\)', '', 'gi');
  if day ~* '(mevzuat maddesi yok|\(kaynak metni?\)|kaynak metne göre|\mkural *[0-9]|\[[0-9]/[0-9]\]|\mambar\M|kaynak paket|teori *par[cç]as|uygulama *: *[a-e]? *ş[ıi]kk|sınav tuzağı *\([0-9]|ders notu.{0,40}madde *[0-9]|teori notu)' then
    day := null;
  end if;
  return jsonb_build_object(
    'n', p_n, 'id', p.id, 'sinav', p.sinav, 'ders', p.ders, 'konu', p.konu,
    'soru', v->'soru', 'verilenler', v->'verilenler', 'siklar', v->'siklar', 'dogru', v->'dogru',
    'aciklama', case when jsonb_typeof(v->'sade') = 'object' then v->'sade'->>'dogru' else v->>'sade' end,
    'tuzak', v->'tuzak', 'adimlar', v->'adimlar', 'kural', v->>'kural', 'hap', v->>'hap', 'dayanak', nullif(day,''));
end $fn$;
revoke all on function public.kanit_sorusu(text, integer) from public, anon, authenticated;
grant execute on function public.kanit_sorusu(text, integer) to anon, authenticated;

-- ÖZ-SINAV (tutmazsa göç geri alınır)
do $t$
declare say int; r jsonb;
begin
  select count(*) into say from public.kanit_soru k join public.paket_soru ps on ps.id = k.id where k.liste = 'sgs-2026-3';
  if say <> 84 then raise exception 'KANIT: 84 satırın % tanesi kasada', say; end if;
  select count(*) into say from public.kanit_soru where liste = 'sgs-2026-3';
  if say <> 84 then raise exception 'KANIT: liste % satır (84 bekleniyordu)', say; end if;
  r := public.kanit_sorusu('sgs-2026-3', 33);           -- 33 dışarıda kalan 16'dan biri
  if r->>'hata' is distinct from 'listede yok' then raise exception 'KANIT: liste dışı numara açıldı'; end if;
  r := public.kanit_sorusu('baska', 54);
  if r->>'hata' is distinct from 'listede yok' then raise exception 'KANIT: başka liste adı açıldı'; end if;
  r := public.kanit_sorusu('sgs-2026-3', 54);
  if r->>'id' is distinct from 'sgs-c2-fmuh-cokzor-r2/kp-02' or coalesce(r->>'dogru','') = '' or coalesce(r->>'aciklama','') = '' then
    raise exception 'KANIT: 54 doğru soruyu açmadı';
  end if;
  if not has_function_privilege('anon', 'public.kanit_sorusu(text, integer)', 'execute') then raise exception 'KANIT: anon çalıştıramıyor'; end if;
  if has_table_privilege('anon', 'public.kanit_soru', 'select') then raise exception 'KANIT: tablo anon''a açık'; end if;
  raise notice 'KANIT öz-sınav: 84/84 kasada, liste dışı kapalı, anon yalnız fonksiyon';
end $t$;
