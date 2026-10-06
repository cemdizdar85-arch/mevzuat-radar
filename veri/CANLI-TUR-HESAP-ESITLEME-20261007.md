# Canlı tur — hesaba eşitleme (07.10.2026)

Ne ölçülüyor: 07.10'da yayına giren dört değişiklik gerçek Supabase'te iki cihaz arasında çalışıyor mu.
Yerelde sahte istemciyle ölçüldü (commit'ler f4fc9efa · 693d0be1 · 73be3e17 · 2d5c6d25); canlıda **ölçülmedi**.

**Kim yapar:** Cem (test hesabıyla; Claude parola girmez). Süre ~10 dk. Bedel 0.
**Hesap:** gerçek öğrenci hesabı değil, Cem'in test hesabı (paketsiz). Kişi verisi URL'ye yazılmaz.

## A cihazı (telefon)
1. tetikte.com/ogrenci.html → test hesabıyla giriş.
2. tetikte.com/seviye-testi.html?sinav=yeterlilik → testi bitir, en az 2 soruyu bilerek yanlış yap.
3. tetikte.com/seviye-testi.html (SGS) → testi bitir, en az 2 yanlış.
4. Hesabım'ı aç → not al: Yeterlilik ve SGS geçme yüzdesi, "kutuda N".

## B cihazı (bilgisayar, gizli pencere = temiz tarayıcı)
5. tetikte.com/ogrenci.html → aynı hesapla giriş.
   - Beklenen: "Staja Giriş / Yeterlilik" sekmesi; iki yüzde A'dakiyle aynı; Yeterlilik'te ders ders durum.
   - Beklenen: "kutuda N" A'dakiyle aynı.
6. tetikte.com/yanlislarim.html → aynı sorular "tekrar bekliyor".
7. tetikte.com/seviye-testi.html → "Teste başla" → **kilit** görünmeli ("… gün sonra açılır").

## Sonuç
Her adım için ✅ / ❌ yaz; ❌ varsa ekran görüntüsü + saat. Claude ölçer:
`ogrenci_sonuc` (seviye satırları, sinav sgs/smmm) ve `ogrenci_ilerleme.veri.kutu` (yönetim panelinden ya da SQL Editor).
