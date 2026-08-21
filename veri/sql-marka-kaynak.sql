-- ============================================================================
--  MARKA TALEBİNE KAYNAK ETİKETİ (21.08.2026) - "hangi video üye getirdi?"
--
--  Instagram paketinde her videonun linki kendi etiketiyle veriliyor:
--    tetikte.com/marka-portfoy.html?k=v6
--  Sayfa bu etiketi talebe yaziyor; boylece hangi videonun tarama (ve ardindan
--  uyelik) getirdigi haftalik gorulur. Etiket yoksa alan bos kalir.
--
--  SITE BU SQL BASILMADAN DA CALISIR: istemci once 3 parametreli cagriyi dener,
--  fonksiyon yoksa 2 parametreli eski imzaya duser (geriye uyumlu).
--  Supabase SQL Editor'de bir kez calistir.
-- ============================================================================

alter table public.marka_talep add column if not exists kaynak text;

create or replace function public.marka_talep_ac(p_unvan text, p_email text default null, p_kaynak text default null) returns text language plpgsql security definer set search_path = public as $fn$ declare v_jeton text; v_gunluk int; begin if p_unvan is null or length(btrim(p_unvan)) < 3 or length(p_unvan) > 160 then raise exception 'Unvan 3-160 karakter olmali'; end if; select count(*) into v_gunluk from public.marka_talep where created_at > now() - interval '1 day'; if v_gunluk > 3000 then raise exception 'Gunluk sorgu tavani doldu, yarin tekrar dene'; end if; v_jeton := replace(gen_random_uuid()::text,'-','') || replace(gen_random_uuid()::text,'-',''); insert into public.marka_talep(jeton, unvan, email, user_id, kaynak) values (v_jeton, btrim(p_unvan), nullif(btrim(coalesce(p_email,'')),''), auth.uid(), left(nullif(btrim(coalesce(p_kaynak,'')),''),40)); return v_jeton; end; $fn$;

grant execute on function public.marka_talep_ac(text, text, text) to anon, authenticated;

-- Haftalik okuma (SQL Editor'de elle):
-- select kaynak, count(*) talep, count(email) mail_birakan, min(created_at) ilk, max(created_at) son
-- from public.marka_talep where created_at > now() - interval '30 days' group by kaynak order by talep desc;
