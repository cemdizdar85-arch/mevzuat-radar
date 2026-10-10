-- 10.10.2026 (Cem: "dışarıda görünen yer varsa silelim") — kasadaki soru verisinden üretim izi (model adı) kaldırılır.
-- Ölçüldü (10.10): paket_soru 9.003 satırın 8.571'inde veri.olcum.sim.model = 'claude-…' vardı; üye kasa_soru_getir ile
-- veriyi tarayıcıda görebiliyordu. Kaynak motor/kaydir-coz.ps1 (aynı commit'te düzeltildi; yeni basımda alan yok).
-- Yalnız bu anahtar silinir; soru, şıklar, doğru, açıklama ve olcum'un öteki alanları (sim.dogru, sim.tur …) DEĞİŞMEZ.
-- guncelleme damgasına dokunulmaz (istemci önbellekleri ve parti senkronu bu damgaya bakıyor; içerik değişmedi).

update public.paket_soru
   set veri = veri #- '{olcum,sim,model}'
 where veri->'olcum'->'sim' ? 'model';

do $$ declare kalan integer; begin
  select count(*) into kalan from public.paket_soru where veri->'olcum'->'sim' ? 'model';
  if kalan > 0 then raise exception 'model izi kaldı: %', kalan; end if;
end $$;
