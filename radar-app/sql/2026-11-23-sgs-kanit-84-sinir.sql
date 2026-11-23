-- ============================================================================
-- KANIT SORUSU IP SINIRI 200 → 3.000 / 10 dk (23.11.2026, aynı gün)
-- Neden: sayfa Instagram reklamının inişi; telefon operatörleri çok sayıda kişiyi TEK IP'den (CGNAT) çıkarır. 200 sınırında
-- ölçüm betiğinin iki koşusu (2 × 105 çağrı) aynı IP'yi kapattı: reklam trafiğinde gerçek ziyaretçi "çok soru açıldı" görürdü.
-- İçerik zaten yalnız bu 84 soru (banka açılmaz); sınır yalnız veritabanını korur. Fonksiyonun geri kalanı
-- 2026-11-23-sgs-kanit-84.sql ile AYNEN. Öz-sınav göç içinde.
-- ============================================================================
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
  if not public.rate_limit_check('kanit:' || trim(ip), 3000, 600) then
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

do $t$
declare r jsonb;
begin
  r := public.kanit_sorusu('sgs-2026-3', 54);
  if r->>'id' is distinct from 'sgs-c2-fmuh-cokzor-r2/kp-02' then raise exception 'KANIT SINIR: 54 açılmadı'; end if;
  r := public.kanit_sorusu('sgs-2026-3', 33);
  if r->>'hata' is distinct from 'listede yok' then raise exception 'KANIT SINIR: liste dışı açıldı'; end if;
  if position('3000, 600' in pg_get_functiondef('public.kanit_sorusu(text, integer)'::regprocedure)) = 0 then raise exception 'KANIT SINIR: sınır 3000 değil'; end if;
  if not has_function_privilege('anon', 'public.kanit_sorusu(text, integer)', 'execute') then raise exception 'KANIT SINIR: anon kapalı'; end if;
  raise notice 'KANIT SINIR öz-sınav: 3000/10 dk, 54 açık, 33 kapalı';
end $t$;
