# KVKK yurt dışına aktarım — hukukçuya not (04.09.2026)

**Kim yazdı:** GM (Claude), Cem'in "kurumsal firma olacağız, müşteri verisi güvenli
yerde olsun" kararı üzerine. **Kim karar verecek:** Cem'in hukukçusu. Bu not
karar değil, **ölçülmüş olgu listesi + seçilecek dayanak seçenekleri**dir.

## 1. Ölçülmüş durum (04.09.2026, canlı)

| Sağlayıcı | Ne taşıyor | Ülke | Kanıt |
|---|---|---|---|
| Supabase (Pro plan) | üye hesabı + şifre özeti, beyanname/marka/evrak verisi, site formları (`form_kayit`) | Almanya, Frankfurt | uç başlığı `x-sb-edge-region=eu-central-1`; Supabase kendisi Cloudflare arkasında (İstanbul düğümü) |
| Resend | üye e-posta adresi, form bildirimi içeriği (ad, e-posta, mesaj) | ABD | Resend hizmet şartları |
| GitHub Pages | yalnız statik sayfa; kişisel veri tutmaz | ABD | — |
| Anthropic API | Net Cevap aracında kullanıcının yazdığı soru metni (kimlikle eşleşmez) | ABD | `radar-app/edge/net-cevap.ts` |
| ~~web3forms~~ | 04.09.2026'da zincirden ÇIKARILDI (19 sayfa + sipariş formu oradan geçiyordu) | — | commit `8c8e1ee7` |

Kayıt açık (`disable_signup=false`), e-posta onayı açık (`mailer_autoconfirm=false`).
Yani **aktarım bugün fiilen var**; kvkk.html'deki eski "aktarım yapılmıyor" cümlesi
04.09'da olguya göre düzeltildi (bkz. `kvkk.html` 4. bölüm).

## 2. Karar bekleyen soru

KVKK m.9 (7499 s. Kanunla değişik, 2024) uyarınca yurt dışına aktarım için:

1. **Yeterlilik kararı** (m.9/2): Kurul'un o ülke için yeterlilik kararı — Almanya/ABD
   için Kurul'un yayımlanmış kararı var mı, hukukçu teyit edecek (GM ölçmedi).
2. **Uygun güvence** (m.9/4): en pratik yol **standart sözleşme** (Kurul'un yayımladığı
   metin; imzadan sonra **5 iş günü içinde Kurul'a bildirim**). Alternatif: bağlayıcı
   şirket kuralları (bize uymaz), yazılı taahhütname + Kurul izni (uzun).
3. **Açık rıza** yalnız **arızî** aktarımlar için (m.9/6-a). Bizim aktarımımız sürekli
   ve sistematik → **açık rızaya dayandırılamaz** (29.07'de bu sebeple metinden çıkarıldı).

GM'nin ön fikri: **2 — standart sözleşme**, her sağlayıcı için ayrı. Sağlayıcıların
kendi DPA'ları (Supabase DPA, Resend DPA, Anthropic ticari şartlar) standart
sözleşmenin yerine geçmez ama ekinde "işleyen taahhütleri" olarak kullanılır.

## 3. Hukukçudan istenen çıktı

- Her sağlayıcı için dayanak seçimi (yeterlilik / standart sözleşme).
- Standart sözleşme metinlerinin imza sırası ve Kurul bildirimi takvimi.
- kvkk.html 4. bölümdeki "hazırlanmaktadır" cümlesinin yerine geçecek kesin cümle.
- Aydınlatma metninde eksik bulduğu başka nokta.

## 4. GM'nin hazır tutacağı belgeler (Cem "yap" derse)

- Sağlayıcı sözleşme klasörü: Supabase DPA + Resend DPA + Anthropic ticari şartlar
  (PDF olarak indirilip `_yerel-veri-kasasi/sozlesmeler/` altında; git'e girmez).
- Veri envanteri tablosu (yukarıdaki tablo, alan alan: hangi tablo, hangi kolon, ne süre).
