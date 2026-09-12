# URETIM PLANI — STAJA BASLAMA (SGS)

> Uretim: **11.09.2026 18:38** (makine; elle duzenlenmez — motor/uretim-plani.ps1). Hedef: **10 tam deneme sinavi**.
> Kaynaklar: ders agirligi = veri/ders-profili.json · yayindaki havuz = veri/sinav/kaydir-secim/sgs-650-secim.json · fabrika = veri/fabrika/kalip-parti-*.json · bedel = veri/fabrika/bedel-kayit.jsonl

## 0 · TEK CUMLE

Fabrikada **3.724** soru uretildi, **1.687**'i tum kapilardan gecti, ama yayinda **630** var. Aradaki **1.045** soru SAGLAM ve rafta duruyor.

## 1 · ''3 BIN KUSUR''UN NEREYE GITTIGI — fabrika hunisi

| Asama | Soru | Pay |
|---|---:|---:|
| FABRIKADA URETILEN | 3.724 | %100,0 |
| hakem hic kosmamis | 130 | %3,5 |
| hakem HAYIR | 830 | %22,3 |
| kor cozum hic kosmamis | 1.242 | %33,4 |
| kor cozum YANLIS | 78 | %2,1 |
| hakem2 hic kosmamis | 1.310 | %35,2 |
| hakem2 HAYIR | 260 | %7,0 |
| simulasyon YANLIS | 200 | %5,4 |
| **TUM KAPILARDAN GECEN** | 1.687 | %45,3 |

**Kapi sistemi calisiyor:** uretilen her 100 sorudan 55'i eleniyor. Bu israf degil, kalite bedeli — elenenler yayina cikmiyor.

> Asamalar **ust uste biner**: hakemden HAYIR alan soruya kor cozum hic kosmaz, o yuzden ''hic kosmamis'' satirlari birbirini kapsar. Toplamlari degil, son satiri oku.

## 2 · DERS DERS: SINAV AGIRLIGI × ELIMIZDEKI

| Ders | Sinavda | Yayinda (v2) | Rafta (hasat) | TOPLAM | Kac deneme cikar | Hedef | ACIK |
|---|---:|---:|---:|---:|---:|---:|---:|
| Finansal Muhasebe | 26 | 213 | 174 | 387 | 14,9 | 260 | — |
| Denetim | 16 | 174 | 107 | 281 | 17,6 | 160 | — |
| Yabanci Dil | 10 | 0 | 97 | 97 | 9,7 | 100 | **3** |
| Maliyet Muhasebesi | 8 | 43 | 92 | 135 | 16,9 | 80 | — |
| Mali Tablolar Analizi | 8 | 14 | 52 | 66 | 8,2 | 80 | **14** |
| Matematik | 8 | 0 | 61 | 61 | 7,6 | 80 | **19** |
| Turkce | 7 | 0 | 56 | 56 | 8,0 | 70 | **14** |
| Is ve Sosyal Guvenlik Hukuku | 6 | 18 | 37 | 55 | 9,2 | 60 | **5** |
| Vergi Hukuku | 6 | 28 | 48 | 76 | 12,7 | 60 | — |
| Ticaret Hukuku | 6 | 77 | 76 | 153 | 25,5 | 60 | — |
| Borclar Hukuku | 6 | 37 | 45 | 82 | 13,7 | 60 | — |
| Meslek Hukuku | 6 | 26 | 1 | 27 | 4,5 | 60 | **33** |
| Ekonomi | 6 | 0 | 61 | 61 | 10,2 | 60 | — |
| Maliye | 6 | 0 | 83 | 83 | 13,8 | 60 | — |
| Ataturk Ilkeleri ve Inkilap Tarihi | 5 | 0 | 55 | 55 | 11,0 | 50 | — |
| **TOPLAM** | **130** | **630** | **1.045** | **1.675** | | **1.300** | **88** |

**DAR BOGAZ: Meslek Hukuku** — 27 soruyla ancak 4,5 deneme cikar. Deneme sayisini bu ders belirler.

## 3 · CEVAP BICIMI — ''Nobetci anlatsin / Sen coz'' sayfasi

**KILITLI KARAR (Cem, 11.09):** cevaplar Kaydir-Coz sayfasi olarak uretilir.
Sartname STANDART-CEVAP-KALIBI.md · builder motor/kaydir-coz.ps1 (onbellekten basar, API yok, **bedel 0**).

Sayfanin doldurdugu alanlar raftaki sorularda ne kadar hazir:

| Alan | Dolu | Oran | Ne ise yarar |
|---|---:|---:|---|
| sade | 841 | %79,6 | panel (2 sik + kavramlar) |
| adimlar | 1.039 | %98,3 | adim adim cozum |
| konu_giris | 1.048 | %99,1 | Nobetci anlatsin girisi |
| ikiz | 343 | %32,5 | Sen coz ikizi (hesap) |
| teori_ikiz | 668 | %63,2 | Sen coz ikizi (teori) |
| sema | 799 | %75,6 | yevmiye / T-hesabi |
| cozum_tablo | 348 | %32,9 | cozum tablosu |
| hap | 1.057 | %100,0 | hap bilgi |
| sinav_taktigi | 1.057 | %100,0 | sinav taktigi |
| teshis | 1.057 | %100,0 | teshis (ne sanmistin) |

**SONUC:** eksik olan tek alan **sade** (%79,6). Sayfanin geri kalanini besleyen alanlar uretimde zaten dolduruluyor — hap/taktik/teshis %100, konu girisi %99,1, adimlar %98,3, ikiz (hesap+teori) %95,6. Bu yuzden hasat bedeli = **yalniz sade paneli**.

## 4 · BEDEL (olculdu, tahmin degil)

| Kalem | Bedel |
|---|---:|
| Sifirdan soru uretmek (kapilardan gecen basina) | 0,337 USD = **13,81 TL** |
| Raftaki soruyu yayina hazirlamak (sade paneli) | 0,009 USD = **0,37 TL** |
| **1.045 raf sorusunu hasat etmek** | **386 TL** |
| **88 acik soruyu sifirdan uretmek** | **1.216 TL** |
| Ayni 1.045 soruyu hasat yerine sifirdan uretseydik | 14.437 TL |

Hasat, ayni sayida soruyu sifirdan uretmeye gore **14.051 TL** ucuz (37x).

> Bedel defterinde `varsayim=true`: jeton sayilari GERCEK, USD fiyatlari model liste fiyatindan hesaplaniyor. Kur varsayimi 1 USD = 41 TL.

## 5 · SIRA

1. **Hasat** — 1.045 raf sorusunu sade panelinden gecir, havuza al. (386 TL)
2. **Acik kapatma** — 88 soru sifirdan uret; oncelik dar bogaz dersleri. (1.216 TL)
3. Toplam: **1.601 TL** ile 10 tam deneme sinavi.

## 6 · DERSI COZULEMEYEN ETIKETLER (hasat disinda kaldi)

| Etiket | Soru |
|---|---:|
| sgs-gm-pilot1 | 10 |
| sgs-kapituru-11eylul | 2 |

Toplam 12 soru. Etikette ders anahtari yok; ders elle atanmali ya da etiket duzeltilmeli.
