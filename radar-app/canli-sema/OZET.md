# Canlı veritabanı fonksiyonları — özet

> Robot yazar (`.github/workflows/canli-sema.yml`); elle düzenlenmez. Tanımlar `fonksiyonlar.sql`, yetkiler `yetki.tsv`.
> Güvenlik kapısı: `arac/rpc-yetki-kapisi.js` + izin listesi `radar-app/acik-rpc.txt`.

- public fonksiyon: **154** · SECURITY DEFINER: 134 · anon çalıştırabilir: 61 · üye çalıştırabilir: 110
- depoda tanımı OLMAYAN (panelden kurulmuş / göçü kayıp): **3**

| fonksiyon | tür | anon | üye |
|---|---|---|---|
| `bedel_kaydi_damga()` | inv | AÇIK | AÇIK |
| `kalip_parti_damga()` | inv | AÇIK | AÇIK |
| `rls_auto_enable()` | SD | AÇIK | AÇIK |
