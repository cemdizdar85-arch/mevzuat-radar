# KART OKUYUCULARI — MODÜL NOTLARI (05.11, ilk iki dalganın 23 okuyucusunun bulduklarından; KART-DOLDURMA-TALIMAT-KGK.md'ye EK, bağlayıcı)

## Hepsi
- Bu dalgadaki kartlar son 10 yılda en çok BİR kez sorulmuş konular: çıkmış örnek az (çoğu 1 soru). `ne_sorar`'ı o tek sorudan + konunun
  dayanak metninden yaz; tek sorunun kalıbı konunun tek kalıbı değildir.
- ⚠ KONU BAĞI HATASI yaygın (ilk dalgada 80+): `kart-ornek.js` başka konunun sorusunu gösterebilir (en çok 13.06.2021, 12.09.2015, 15.05.2016
  kitapçıkları; BDS sorusu TMS kartında, hukuk/VUK sorusu TDS kartında). Yanlış bağlı soruyu `ne_sorar`'a KATMA, yazım notuna "örnek alma: <dönem S#>" yaz.
- Hesap planı: Tekdüzen THP ambarda VAR (`"THP 100 - Kasa"` …, desen `"THP %"`); BOBİ kökünde KGK FRS planı. "Hesap planı ambarda yok" YAZMA.
- 1.1.2027 ve sonrası yürürlüklü metin dayanak OLAMAZ (TFRS 18 ve sonuç değişiklikleri, RG 28.07.2026 TSRS 2 değişikliği, Sigortacılık Tekdüzen Hesap
  Planı Tebliği, Finansal Raporlama Yön. 2023 metni m.5, Finansal Tabloların Sunumu Tebliği 2023).
- Parçalayıcı hatası: içinde "a) (Mülga" bendi olan bazı yürürlükteki maddeler ambarda yok (BES Yön. m.3, TCK m.4 …) — bulamazsan "AMBARDA YOK" yaz, uydurma.

## TMS
- ⭐ 05.11 e9b408cb: TMS 7, TMS 34, TMS 29, TFRS 16, TMS 8, TMS 10'un 2026'da YÜRÜRLÜKTEKİ (TFRS 18 öncesi) metni ambarda, AYRI adla:
  `"TMS 7 (TFRS 18 oncesi, 2026'da yururlukte) p.%"` (aynı desen TMS 34/29/8/10, TFRS 16). Düz `"TMS 7 p.%"` 1.1.2027 sonrası (TFRS 18 değişik) metni verir.
  2026 sorusu bu altı standartta YALNIZ "TFRS 18 oncesi" kayıtlarına dayanır; dayanakta o adı yaz. TMS 1 ambarda zaten 2026 metni (TFRS 18 geçen kayıt 0, ölçüldü 05.11).
  TMS 8 "TFRS 18 oncesi" kümesinde sahte "p.1 - Tanımlar" parçası var (aslında p.5 devamı) — p.1 adına dayanma.
- Bozuk: BOBİ 10.21 · TMS 32 UR8 · Kavramsal Çerçeve 4.66 · TMS 36 p.117 · "TFRS 8 p.1" kayıtları karışık · "TMS 1 p.36"/"p.106" başlığı kaymış.
- Ambarda yok: TMS/TFRS Uygulama Kapsamı Kurul Kararı · KGK Ortak Kontrol İlke Kararı · KGK Finansal Tablo Örnekleri Rehberi.

## TDS
- KKS 1 ambarda YOK ve mülga → KYS 1/KYS 2'ye bağla, soru KYS adıyla.
- Bozuk/kesik: BDS 720 p.23T matris (yalnız kaçınma satırı, BDS 705 p.29T) · BDS 315 p.21–26 iki sütunlu · BDS 505 p.15 kesik · BDS 220 p.36(a) eksik ·
  BDS 530 Ek 2–3 yok. Kayma: BDS 700 p.24/28, 315 p.28, 501 p.4–8, 540 p.18, 705 p.20–27, 805 p.16–17, 320 p.9/14, 330 p.12/15, KYS 2 p.18–26, Etik A410.17/18, A540.16/17.
- BDS 315 ve BDS 600 ambarda REVİZE; eski sürüme dayanan çıkmış soru (eski risk listesi, "önemli olmayan birim") örnek alınmaz.

## FY
- Resmî metin yok → `"Teori Notu - %"`, `"TEORI - %"`; resmî tebliğ varsa (ör. SPK VII-128.3 varant) o önce gelir.
- Bozuk notlar: faaliyet (devir hızı) oranları Pay/Payda · reeskont iç/dış iskonto · F/K "SINAV TUZAĞI (1)" · "Net işletme sermayesi ve negatif olma koşulu" ters cümle
  → bu konularda "formül kökte veri". Ambar bütçe notu KAMU bütçesi (işletme bütçelemesi değil).

## KY
- II-17.1 ilkeleri m.17 [1/24]…[24/24] içinde; m.5/5 fıkra ayrımı kayıp. Adillik/eşitlikte TEORİ notları çelişik → Tebliğ hükmü.

## SPK
- Güncel (değişik) tebliğ; mülga II-27.2, eski Kotasyon Yön. dayanak değil. 6362 m.57/6 yetki: kanun Ticaret Bakanlığı (2025 anahtarı SPK — kanun esas).

## Sigorta
- Makam bugün SEDDK (CBK 47 m.19). 305dce6b ile girdi: Finansal Raporlama Yön., Mali Bünye Yön., Bilgilendirme Yön., BES Yön., BES Kısmen Ödeme Yön.,
  Finansal Tabloların Sunumu 2008/1, MSS Genel Şartları (genel), SEDDK genelgeleri 2022/8, 2024/1(+2024/16, 2025/4), 2025/5, 2024/10 (mülga), 2024/32, 2025/33, 2024/13.
  Yok: Hayat Grubu Sigortaları Yön. · Bağımsız Denetçilik MSS Genel Şartları · yürürlükteki sigorta hesap planı tebliği. Sermaye yeterliliği: RG 31.12.2024 değişikliği (üç aylık).

## Banka
- Oran/eşik yalnız ambardan. 305dce6b ile girdi: YP Net Genel Pozisyon Yön., BS ve İş Süreçleri Bağımsız Denetimi Yön., Yıllık Faaliyet Raporu Yön.,
  Kurumsal Yönetim İlkeleri Yön. (ilkeler "m.6" kaydına yapışık), Birleşme/Devir/Bölünme Yön. 5411 m.63/64 7407 sonrası; sigortalı mevduat tutarı ambarda yok.
