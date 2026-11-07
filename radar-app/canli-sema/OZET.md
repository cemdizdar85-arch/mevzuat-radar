# Canlı veritabanı fonksiyonları — özet

> Robot yazar (`.github/workflows/canli-sema.yml`); elle düzenlenmez. Tanımlar `fonksiyonlar.sql`, yetkiler `yetki.tsv`.
> Güvenlik kapısı: `arac/rpc-yetki-kapisi.js` + izin listesi `radar-app/acik-rpc.txt`.

- public fonksiyon: **185** · SECURITY DEFINER: 162 · anon çalıştırabilir: 54 · üye çalıştırabilir: 125
- depoda tanımı OLMAYAN (panelden kurulmuş / göçü kayıp): **3**

| fonksiyon | tür | anon | üye |
|---|---|---|---|
| `bedel_kaydi_damga()` | inv | AÇIK | AÇIK |
| `kalip_parti_damga()` | inv | AÇIK | AÇIK |
| `rls_auto_enable()` | SD | AÇIK | AÇIK |
