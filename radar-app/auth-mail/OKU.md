# Auth mail şablonları (Supabase → Authentication → Emails → Templates)

05.10.2026 Cem ("şifre yenilemek isteyenlerde aynı şey geçerli" → "3 yap").

- `confirmation.html` = **Confirm signup** gövdesi (08.10.2026, e-posta onayı açılırken; aynı kurumsal kabuk). Konu: `konular.json` → confirmation.
- `recovery.html` = **Reset password** gövdesi (Source sekmesine aynen yapıştır). Konu: `konular.json` → recovery.
- Değişkenler Supabase'in: `{{ .ConfirmationURL }}` (bağlantı; ogrenci.html'e döner, `resetPasswordForEmail` redirectTo) · `{{ .Email }}`.
- Biçim satır içi: mail istemcileri `<style>` siler.
- Otomatik yazma: `.github/workflows/auth-mail-sablon.yml` kip=yaz — 05.10'da SUPABASE_ACCESS_TOKEN bu ayara **403** verdi (yetkisi yok).
  O yüzden şimdilik panelden elle yapıştırılır; auth yetkili anahtar gelirse akış kendisi yazar.
