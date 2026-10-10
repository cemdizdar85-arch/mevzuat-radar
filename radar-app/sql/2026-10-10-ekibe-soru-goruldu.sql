-- 10.10.2026 (Cem "sitede cevabımızı görsün, bildirim gitsin") — "Ekibe sor" cevabı üyenin hesabında + sitede bildirim.
-- Üye kendi satırlarını zaten okuyabiliyor (ekibe_soru_oku: user_id = auth.uid()); yazma hakkı YOK.
-- cevap_goruldu: cevabı Hesabım'da gördüğü an. Boşsa menu.js sitenin her sayfasında "cevabın geldi" bildirimi gösterir.
-- Üye yalnız bu RPC ile, yalnız KENDİ cevaplanmış satırlarına damga vurabilir (başka alan değişmez).

alter table public.ekibe_soru add column if not exists cevap_goruldu timestamptz;

create or replace function public.ekibe_cevap_goruldu()
returns integer language plpgsql security definer set search_path = public as $$
declare n integer;
begin
  if auth.uid() is null then return 0; end if;
  update public.ekibe_soru set cevap_goruldu = now()
   where user_id = auth.uid() and durum = 'cevaplandi' and cevap_goruldu is null;
  get diagnostics n = row_count;
  return n;
end $$;
revoke all on function public.ekibe_cevap_goruldu() from public, anon;
grant execute on function public.ekibe_cevap_goruldu() to authenticated;
