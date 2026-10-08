#!/usr/bin/env bash
# KAYNAK SAYACI SUNUCU ÖZ-SINAVI (08.10.2026) — radar-app/sql/*kaynak-sayac.sql göçünü GERÇEK Postgres'te uygular.
# Nerede: dogrula.yml (ubuntu runner'ında Postgres kurulu gelir). Bu makinede (Windows) Postgres yok → yerelde koşmaz.
# Ne ölçer:
#   1) göçün kendi içindeki öz-sınavı (biçim, olay, tavan 3000, günde 60 etiket, CHECK, yetkiler) YEŞİL mi
#   2) GERÇEK ROLLERLE: anon ziyaret sayabiliyor · anon üye/yönetim çağıramıyor · anon tabloyu okuyamıyor ·
#      yeni hesap 1 kez 'uye' sayılıyor, ikinci kez sayılmıyor · 3 günlük hesap sayılmıyor · yönetici tabloyu görüyor,
#      yönetici olmayan göremiyor · hesap silinince "sayıldı" kaydı düşüyor, sayaç kalıyor
#   3) MUTASYON: göçün kilit koşulları tek tek bozulur; her bozmada sınav KIRMIZI düşmelidir
# Supabase taklidi: anon/authenticated rolleri, auth.users (id, created_at), auth.uid() = request.jwt.claim.sub,
#   public şemasında Supabase'in varsayılan yetkileri (yeni tablo/fonksiyon anon'a AÇIK doğar — revoke'un sınanması için).
# 🚫 GÖRMEZ: PostgREST/ağ geçidi katmanı (canlı ölçüm ayrı) · Supabase'in gerçek auth tetikleyicileri · eşzamanlı
#   iki sekme yarışı (uye çift sayım koruması iki katmanlı; yalnız biri bozulursa bu sınav YEŞİL kalır — bilerek).
set -uo pipefail
KOK="$(cd "$(dirname "$0")/.." && pwd)"
GOC="$(ls "$KOK"/radar-app/sql/*kaynak-sayac.sql 2>/dev/null | head -1)"
[ -n "$GOC" ] || { echo "KIRMIZI: kaynak-sayac göç dosyası yok"; exit 1; }

if ! command -v psql >/dev/null; then sudo apt-get update -qq && sudo apt-get install -y -qq postgresql >/dev/null; fi
sudo systemctl start postgresql.service 2>/dev/null || sudo service postgresql start >/dev/null 2>&1 || true
for i in $(seq 1 20); do sudo -u postgres psql -X -qtAc "select 1" >/dev/null 2>&1 && break; sleep 1; done
PSQL=(sudo -u postgres psql -X -q -v ON_ERROR_STOP=1)

kur() {   # $1 = veritabanı adı → Supabase taklidi kurulu boş veritabanı
  sudo -u postgres dropdb --if-exists "$1" >/dev/null 2>&1
  sudo -u postgres createdb "$1" || return 1
  "${PSQL[@]}" -d "$1" >/dev/null <<'SQL'
do $$ begin
  if not exists (select 1 from pg_roles where rolname = 'anon') then create role anon nologin; end if;
  if not exists (select 1 from pg_roles where rolname = 'authenticated') then create role authenticated nologin; end if;
end $$;
create schema auth;
create table auth.users (id uuid primary key, created_at timestamptz not null default now());
create function auth.uid() returns uuid language sql stable as $f$ select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid $f$;
grant usage on schema auth to anon, authenticated;
grant execute on function auth.uid() to anon, authenticated;
grant usage on schema public to anon, authenticated;
alter default privileges in schema public grant all on tables to anon, authenticated;
alter default privileges in schema public grant execute on functions to anon, authenticated;
create table public.yoneticiler (user_id uuid primary key);
SQL
}

DUS=0
vaka() { if [ "$2" = "$3" ]; then echo "GEÇTİ $1"; else echo "DÜŞTÜ $1 (beklenen '$3', gelen '$2')"; DUS=$((DUS+1)); fi; }
# rol + kullanıcıyla tek sorgu; çıktı ya değer ya HATA
sor() {   # $1 db  $2 rol  $3 sub(uuid|-)  $4 sql
  local sub="$3"; [ "$sub" = "-" ] && sub=""
  "${PSQL[@]}" -d "$1" -tA -c "select set_config('request.jwt.claim.sub', '$sub', false)" -c "set role $2" -c "$4" 2>/dev/null | tail -1 || true
}
sor_hata() {   # aynı, ama yalnız hata verip vermediği: HATA | GECTI
  local sub="$3"; [ "$sub" = "-" ] && sub=""
  if "${PSQL[@]}" -d "$1" -tA -c "select set_config('request.jwt.claim.sub', '$sub', false)" -c "set role $2" -c "$4" >/dev/null 2>&1; then echo GECTI; else echo HATA; fi
}

U1=11111111-1111-1111-1111-111111111111   # yeni hesap
U2=22222222-2222-2222-2222-222222222222   # 3 günlük hesap
U3=33333333-3333-3333-3333-333333333333   # yönetici

sinav() {   # $1 göç dosyası  $2 db  → DUS'u artırır
  local db="$2" cikti
  kur "$db" || { echo "DÜŞTÜ veritabanı kurulamadı"; DUS=$((DUS+1)); return; }
  if ! cikti=$("${PSQL[@]}" -d "$db" -1 -f - < "$1" 2>&1); then   # stdin: postgres kullanıcısı depo klasörünü okuyamayabilir
    echo "DÜŞTÜ göç uygulanamadı: $(echo "$cikti" | grep -m1 -E 'ERROR|HATA' | cut -c1-200)"; DUS=$((DUS+1)); return
  fi
  vaka "göç içi öz-sınav YEŞİL" "$(echo "$cikti" | grep -c 'OZ-SINAV YESIL')" "1"
  vaka "göç içi öz-sınav satır bırakmadı" "$("${PSQL[@]}" -d "$db" -tAc "select count(*) from public.kaynak_sayac")" "0"
  "${PSQL[@]}" -d "$db" -c "insert into auth.users (id, created_at) values ('$U1', now()), ('$U2', now() - interval '3 days'), ('$U3', now()); insert into public.yoneticiler values ('$U3');" >/dev/null
  vaka "anon ziyaret sayar"                    "$(sor "$db" anon - "select public.kaynak_say('deneme','ziyaret')")" "t"
  vaka "anon test sayar"                       "$(sor "$db" anon - "select public.kaynak_say('deneme','test')")" "t"
  vaka "anon bozuk etiket sayamaz"             "$(sor "$db" anon - "select public.kaynak_say('<b>','ziyaret')")" "f"
  vaka "anon kaynak_uye çağıramaz"             "$(sor_hata "$db" anon - "select public.kaynak_uye('deneme')")" "HATA"
  vaka "anon yonetim_kaynak çağıramaz"         "$(sor_hata "$db" anon - "select public.yonetim_kaynak(60)")" "HATA"
  vaka "anon _kaynak_artir çağıramaz"          "$(sor_hata "$db" anon - "select public._kaynak_artir(current_date,'x','uye')")" "HATA"
  vaka "anon tabloyu okuyamaz"                 "$(sor_hata "$db" anon - "select count(*) from public.kaynak_sayac")" "HATA"
  vaka "anon tabloya yazamaz"                  "$(sor_hata "$db" anon - "insert into public.kaynak_sayac values (current_date,'x','uye',99)")" "HATA"
  vaka "üye tabloya doğrudan yazamaz"          "$(sor_hata "$db" authenticated "$U1" "update public.kaynak_sayac set adet = 999")" "HATA"
  vaka "yeni hesap: uye sayılır"               "$(sor "$db" authenticated "$U1" "select public.kaynak_uye('deneme')")" "t"
  vaka "yeni hesap: ikinci kez sayılmaz"       "$(sor "$db" authenticated "$U1" "select public.kaynak_uye('deneme')")" "f"
  vaka "yeni hesap: başka etiketle de sayılmaz" "$(sor "$db" authenticated "$U1" "select public.kaynak_uye('baska')")" "f"
  vaka "3 günlük hesap sayılmaz"               "$(sor "$db" authenticated "$U2" "select public.kaynak_uye('deneme')")" "f"
  vaka "üye anon olayı da sayabilir"           "$(sor "$db" authenticated "$U2" "select public.kaynak_say('deneme','ziyaret')")" "t"
  vaka "yönetici olmayan tabloyu göremez"      "$(sor_hata "$db" authenticated "$U1" "select public.yonetim_kaynak(60)")" "HATA"
  vaka "yönetici: deneme satırı (ziyaret 2, test 1, uye 1)" \
       "$(sor "$db" authenticated "$U3" "select e->>'etiket' || ' ' || (e->>'ziyaret') || ' ' || (e->>'test') || ' ' || (e->>'uye') from jsonb_array_elements(public.yonetim_kaynak(60)) e where e->>'etiket' = 'deneme'")" \
       "deneme 2 1 1"
  vaka "yönetici: kişi verisi alanı yok"       "$(sor "$db" authenticated "$U3" "select count(*) from jsonb_array_elements(public.yonetim_kaynak(60)) e, jsonb_object_keys(e) k where k not in ('gun','etiket','ziyaret','test','uye')")" "0"
  "${PSQL[@]}" -d "$db" -c "delete from auth.users where id = '$U1'" >/dev/null
  vaka "hesap silinince sayıldı kaydı düşer"   "$("${PSQL[@]}" -d "$db" -tAc "select count(*) from public.kaynak_uye_sayildi")" "0"
  vaka "hesap silinince sayaç kalır"           "$("${PSQL[@]}" -d "$db" -tAc "select adet from public.kaynak_sayac where etiket='deneme' and olay='uye'")" "1"
  vaka "sayaç tablosunda yalnız 4 sütun"       "$("${PSQL[@]}" -d "$db" -tAc "select string_agg(column_name, ',' order by ordinal_position) from information_schema.columns where table_schema='public' and table_name='kaynak_sayac'")" "gun,etiket,olay,adet"
}

if [ "${1:-}" != "--yalniz-mutasyon" ]; then
  echo "== SINAV: $(basename "$GOC")"
  sinav "$GOC" ks_sinav
  echo "KAYNAK SAYACI SUNUCU ÖZ-SINAVI: düşen $DUS"
  [ "$DUS" -eq 0 ] || exit 1
fi

# --- MUTASYON: her bozma KIRMIZI düşmeli ---
declare -a MAD MESKI MYENI
m() { MAD+=("$1"); MESKI+=("$2"); MYENI+=("$3"); }
m tavan     "where k.adet < 3000"                                                       ""
m kota      ">= 60 then"                                                                ">= 6000 then"
m anon-uye  "if coalesce(p_olay,'') not in ('ziyaret','test') then return false; end if;" ""
m uye-grant "revoke all on function public.kaynak_uye(text) from public, anon;"          ""
m yonetim   "if auth.uid() is null or not exists (select 1 from public.yoneticiler y where y.user_id = auth.uid()) then" "if false then"
m hesap-gun "olus < now() - interval '2 days'"                                          "olus < now() - interval '20 days'"
m tablo     "revoke all on public.kaynak_sayac from anon, authenticated;"               ""
m check     "constraint kaynak_sayac_etiket_bicim check (etiket ~ '^[a-z0-9][a-z0-9_-]{0,31}\$')," ","
m rpc-desen "or p_etiket !~ '^[a-z0-9][a-z0-9_-]{0,31}\$'"                               ""
m olay-chk  "constraint kaynak_sayac_olay check (olay in ('ziyaret','test','uye')),"     ","
KACAN=0; TMP="$(mktemp -d)"
for i in "${!MAD[@]}"; do
  hedef="$TMP/${MAD[$i]}-kaynak-sayac.sql"
  if ! ESKI="${MESKI[$i]}" YENI="${MYENI[$i]}" node -e "const fs=require('fs');const s=fs.readFileSync(process.argv[1],'utf8');const e=process.env.ESKI;if(!s.includes(e))process.exit(3);fs.writeFileSync(process.argv[2],s.split(e).join(process.env.YENI))" "$GOC" "$hedef"; then
    echo "SINAV BAYAT: mutasyon hedefi göçte yok → ${MAD[$i]}"; KACAN=$((KACAN+1)); continue
  fi
  DUS=0; sinav "$hedef" "ks_m$i" >/dev/null 2>&1
  if [ "$DUS" -gt 0 ]; then echo "KIRMIZI (doğru) ${MAD[$i]} — $DUS vaka düştü"; else echo "YEŞİL KALDI (sınav kör) ${MAD[$i]}"; KACAN=$((KACAN+1)); fi
done
echo "MUTASYON: $(( ${#MAD[@]} - KACAN ))/${#MAD[@]} KIRMIZI"
[ "$KACAN" -eq 0 ] || exit 1
