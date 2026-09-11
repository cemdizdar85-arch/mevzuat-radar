# URETIM PLANI — STAJA BASLAMA (SGS)

> Uretim: **11.09.2026 15:10** (makine; elle duzenlenmez — motor/uretim-plani.ps1). Hedef: **10 tam deneme sinavi**.
> Kaynaklar: ders agirligi = veri/ders-profili.json · yayindaki havuz = veri/sinav/kaydir-secim/sgs-650-secim.json · fabrika = veri/fabrika/kalip-parti-*.json · bedel = veri/fabrika/bedel-kayit.jsonl

## 0 · TEK CUMLE

Fabrikada **3.701** soru uretildi, **1.756**'i tum kapilardan gecti, ama yayinda **630** var. Aradaki **1.114** soru SAGLAM ve rafta duruyor.

## 1 · ''3 BIN KUSUR''UN NEREYE GITTIGI — fabrika hunisi

| Asama | Soru | Pay |
|---|---:|---:|
| FABRIKADA URETILEN | 3.701 | %100,0 |
| hakem hic kosmamis | 108 | %2,9 |
| hakem HAYIR | 761 | %20,6 |
| kor cozum hic kosmamis | 1.217 | %32,9 |
| kor cozum YANLIS | 78 | %2,1 |
| hakem2 hic kosmamis | 1.288 | %34,8 |
| hakem2 HAYIR | 260 | %7,0 |
| simulasyon YANLIS | 202 | %5,5 |
| **TUM KAPILARDAN GECEN** | 1.756 | %47,4 |

**Kapi sistemi calisiyor:** uretilen her 100 sorudan 53'i eleniyor. Bu israf degil, kalite bedeli — elenenler yayina cikmiyor.

> Asamalar **ust uste biner**: hakemden HAYIR alan soruya kor cozum hic kosmaz, o yuzden ''hic kosmamis'' satirlari birbirini kapsar. Toplamlari degil, son satiri oku.

## 2 · DERS DERS: SINAV AGIRLIGI × ELIMIZDEKI

| Ders | Sinavda | Yayinda (v2) | Rafta (hasat) | TOPLAM | Kac deneme cikar | Hedef | ACIK |
|---|---:|---:|---:|---:|---:|---:|---:|
| Finansal Muhasebe | 26 | 213 | 189 | 402 | 15,5 | 260 | — |
| Denetim | 16 | 174 | 116 | 290 | 18,1 | 160 | — |
| Yabanci Dil | 10 | 0 | 98 | 98 | 9,8 | 100 | **2** |
| Maliyet Muhasebesi | 8 | 43 | 101 | 144 | 18,0 | 80 | — |
| Mali Tablolar Analizi | 8 | 14 | 53 | 67 | 8,4 | 80 | **13** |
| Matematik | 8 | 0 | 68 | 68 | 8,5 | 80 | **12** |
| Turkce | 7 | 0 | 57 | 57 | 8,1 | 70 | **13** |
| Is ve Sosyal Guvenlik Hukuku | 6 | 18 | 45 | 63 | 10,5 | 60 | — |
| Vergi Hukuku | 6 | 28 | 52 | 80 | 13,3 | 60 | — |
| Ticaret Hukuku | 6 | 77 | 79 | 156 | 26,0 | 60 | — |
| Borclar Hukuku | 6 | 37 | 48 | 85 | 14,2 | 60 | — |
| Meslek Hukuku | 6 | 26 | 1 | 27 | 4,5 | 60 | **33** |
| Ekonomi | 6 | 0 | 67 | 67 | 11,2 | 60 | — |
| Maliye | 6 | 0 | 85 | 85 | 14,2 | 60 | — |
| Ataturk Ilkeleri ve Inkilap Tarihi | 5 | 0 | 55 | 55 | 11,0 | 50 | — |
| **TOPLAM** | **130** | **630** | **1.114** | **1.744** | | **1.300** | **73** |

**DAR BOGAZ: Meslek Hukuku** — 27 soruyla ancak 4,5 deneme cikar. Deneme sayisini bu ders belirler.

## 3 · BEDEL (olculdu, tahmin degil)

| Kalem | Bedel |
|---|---:|
| Sifirdan soru uretmek (kapilardan gecen basina) | 0,320 USD = **13,12 TL** |
| Raftaki soruyu yayina hazirlamak (sade paneli) | 0,009 USD = **0,37 TL** |
| **1.114 raf sorusunu hasat etmek** | **411 TL** |
| **73 acik soruyu sifirdan uretmek** | **958 TL** |
| Ayni 1.114 soruyu hasat yerine sifirdan uretseydik | 14.616 TL |

Hasat, ayni sayida soruyu sifirdan uretmeye gore **14.205 TL** ucuz (36x).

> Bedel defterinde `varsayim=true`: jeton sayilari GERCEK, USD fiyatlari model liste fiyatindan hesaplaniyor. Kur varsayimi 1 USD = 41 TL.

## 4 · SIRA

1. **Hasat** — 1.114 raf sorusunu sade panelinden gecir, havuza al. (411 TL)
2. **Acik kapatma** — 73 soru sifirdan uret; oncelik dar bogaz dersleri. (958 TL)
3. Toplam: **1.369 TL** ile 10 tam deneme sinavi.

## 5 · DERSI COZULEMEYEN ETIKETLER (hasat disinda kaldi)

| Etiket | Soru |
|---|---:|
| sgs-gm-pilot1 | 10 |
| sgs-kapituru-11eylul | 2 |

Toplam 12 soru. Etikette ders anahtari yok; ders elle atanmali ya da etiket duzeltilmeli.
