-- RATE LIMIT (17.07.2026): edge fonksiyonlarına MERKEZİ istek sınırı.
-- In-memory sayaç Supabase isolate dağılımında çalışmıyordu; bu Postgres tablosu
-- tüm isolate'lerin gördüğü tek sayaç. rate_limit_check RPC: son p_pencere_sn
-- saniyede bu IP p_limit'i aştıysa false (engelle), değilse kaydeder + true (izin).
create table if not exists public.rate_log (
  ip text not null,
  ts timestamptz not null default now()
);
create index if not exists rate_log_ip_ts on public.rate_log (ip, ts);

create or replace function public.rate_limit_check(p_ip text, p_limit int, p_pencere_sn int default 60)
returns boolean
language plpgsql
security definer
set search_path = public
as $fn$
declare c int;
begin
  if p_ip is null or p_ip = '' then return true; end if;
  -- ara sıra eski kayıt temizliği (her ~20 çağrıda bir) — tablo şişmesin
  if random() < 0.05 then
    delete from rate_log where ts < now() - interval '10 minutes';
  end if;
  select count(*) into c from rate_log
    where ip = p_ip and ts > now() - make_interval(secs => p_pencere_sn);
  if c >= p_limit then return false; end if;   -- limit aşıldı
  insert into rate_log(ip) values (p_ip);
  return true;                                  -- izin
end;
$fn$;

grant execute on function public.rate_limit_check(text, int, int) to anon, authenticated;

-- doğrulama: art arda 3 çağrı — limit 2 verince 3.'de false (engel) görmelisin
select public.rate_limit_check('test-ip', 2, 60) as c1,
       public.rate_limit_check('test-ip', 2, 60) as c2,
       public.rate_limit_check('test-ip', 2, 60) as c3;
