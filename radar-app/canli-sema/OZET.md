# Canlı veritabanı fonksiyonları — özet

> Robot yazar (`.github/workflows/canli-sema.yml`); elle düzenlenmez. Tanımlar `fonksiyonlar.sql`, yetkiler `yetki.tsv`.
> Güvenlik kapısı: `arac/rpc-yetki-kapisi.js` + izin listesi `radar-app/acik-rpc.txt`.

- public fonksiyon: **154** · SECURITY DEFINER: 134 · anon çalıştırabilir: 64 · üye çalıştırabilir: 114
- depoda tanımı OLMAYAN (panelden kurulmuş / göçü kayıp): **29**

| fonksiyon | tür | anon | üye |
|---|---|---|---|
| `bedel_kaydi_damga()` | inv | AÇIK | AÇIK |
| `cevap_kaydet(p_token uuid, p_soru_id uuid, p_cevap text, p_dosya text)` | SD | AÇIK | AÇIK |
| `davet_kodu_ata()` | inv | AÇIK | AÇIK |
| `davet_kodu_uret()` | inv | AÇIK | AÇIK |
| `davet_uygula(p_alan_id uuid, p_kod text)` | SD | - | - |
| `destek_takip_iptal(p_token uuid)` | SD | AÇIK | AÇIK |
| `istek_getir(p_token uuid)` | SD | AÇIK | AÇIK |
| `kalip_parti_damga()` | inv | AÇIK | AÇIK |
| `marka_ayna_durum()` | SD | AÇIK | AÇIK |
| `marka_ayna_sahip(p_unvan text, p_tavan integer)` | SD | AÇIK | AÇIK |
| `marka_bulten_durum()` | SD | AÇIK | AÇIK |
| `marka_bulten_itiraz(p_ad text, p_sinif integer[], p_gun integer, p_esik real, p_tavan integer, p_yalniz_acik boolean)` | SD | AÇIK | AÇIK |
| `marka_bulten_mutabakat()` | SD | - | - |
| `marka_bulten_sahip(p_unvan text, p_tavan integer)` | SD | AÇIK | AÇIK |
| `marka_kademe_hesap(p_marka text, p_aday text)` | inv | - | - |
| `marka_kademe_sinav()` | SD | - | - |
| `marka_norm(p text)` | inv | AÇIK | AÇIK |
| `marka_norm_bosluklu(p text)` | inv | AÇIK | AÇIK |
| `marka_norm_sozcuk(p text)` | inv | AÇIK | AÇIK |
| `marka_takip_ac(p_ad text, p_sinif integer[], p_eposta text)` | SD | AÇIK | AÇIK |
| `marka_takip_bekleyen(p_tavan integer)` | SD | - | - |
| `marka_takip_gor(p_jeton text)` | SD | AÇIK | AÇIK |
| `marka_takip_isaretle(p_takip_id uuid, p_kayitlar jsonb)` | SD | - | - |
| `marka_takip_kapat(p_jeton text)` | SD | AÇIK | AÇIK |
| `marka_takip_sayac()` | SD | AÇIK | AÇIK |
| `marka_talep_ac(p_unvan text, p_email text, p_kaynak text)` | SD | AÇIK | AÇIK |
| `marka_talep_sonuc(p_jeton text)` | SD | AÇIK | AÇIK |
| `mukellef_pano(p_token uuid)` | SD | AÇIK | AÇIK |
| `rls_auto_enable()` | SD | AÇIK | AÇIK |
