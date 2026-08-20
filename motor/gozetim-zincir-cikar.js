// ============================================================================
//  GOZETIM TEBLIG ZINCIRI — RG basliklarindan numara + tur cikarir.
//  veri/rg-gozetim-haritasi.json  ->  veri/gozetim-teblig-zinciri.json
//
//  NEDEN NODE (20.08.2026): ayni isi yapan motor/rg-gozetim-cikar.ps1
//  etiketleri KARISTIRIYORDU. Olculdu: 160 kaydin 15'i yanlisti —
//    asil→olmasi gereken mulga : 4   (gercek yururlukten kaldirma "asil" sayilmis)
//    mulga→olmasi gereken degisiklik : 6
//    mulga→olmasi gereken asil : 5
//  Yani "mulga" etiketi hem fazla hem eksik basiliyordu ve o alana bakip
//  "bu teblig yururlukten kalkmis" demek YANLIS sonuc veriyordu (19.08'de tam
//  bunu yaptim ve 2019/6 ile 2026/17'yi mulga sandim).
//  Sebep PS 5.1'in metin isleme tuhafliklari (BOM/ANSI okuma, tipografik
//  kesme isaretini ' tirnak sayma, ozel bosluk siniflarinin bozulmasi).
//  Node tarafinda dosya her zaman UTF-8 okunur; bu sinif hata kapanir.
//
//  KENDI KENDINI DENETLER: yazmadan once her kaydin turu, basligindan yeniden
//  turetilenle karsilastirilir. Bir tane bile tutmazsa YAZMAZ ve kirmizi doner.
//
//  Kullanim:
//    node motor/gozetim-zincir-cikar.js .            # olcum (yazmaz)
//    node motor/gozetim-zincir-cikar.js . -uygula    # yazar
// ============================================================================
const fs = require('fs'), path = require('path');
const KOK = process.argv[2] || '.';
const UYGULA = process.argv.includes('-uygula');

const ICERI = /İthalatta\s+(Gözetim|Korunma|Haksız\s+Rekabetin|Kota|Bazı\s+Ürünlerin)/;
const NO_DESENI = /(?:Tebliğ\s*)?No\s*:?\s*(\d{4}\s*\/\s*\d+)/;
const MULGA = /Yürürlükten\s+Kaldırıl/;
const DEGISIK = /Değişiklik\s+Yapılmasına/;

// HTML varliklari cozulur, dar/kirilmayan bosluklar normal bosluga cevrilir.
// Karakterler KACIS DIZISIYLE yazilir — dosyaya ciplak gomulurse bozulabiliyor.
const BOSLUK = /[   -​  　]/g;
function coz(s) {
  return String(s || '')
    .replace(/&amp;/g, '&').replace(/&lt;/g, '<').replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"').replace(/&#(\d+);/g, (_, d) => String.fromCharCode(d))
    .replace(/&#x([0-9a-f]+);/gi, (_, d) => String.fromCharCode(parseInt(d, 16)))
    .replace(/&nbsp;/g, ' ')
    .replace(BOSLUK, ' ')
    .trim();
}
const turBul = b => MULGA.test(b) ? 'mulga' : (DEGISIK.test(b) ? 'degisiklik' : 'asil');

const haritaYol = path.join(KOK, 'veri/rg-gozetim-haritasi.json');
const h = JSON.parse(fs.readFileSync(haritaYol, 'utf8').replace(/^﻿/, ''));
const kayitlar = h.kayit || [];

const iceri = [], disari = [];
for (const k of kayitlar) {
  const b = coz(k.baslik);
  (ICERI.test(b) ? iceri : disari).push({ tarih: k.tarih, kod: k.kod, url: k.url, baslik: b });
}
// KOVA KURALI: iceri + disari = taranan. Tutmazsa desen ya da kodlama bozuk.
if (iceri.length + disari.length !== kayitlar.length) { console.log('KIRMIZI: kova toplami tutmadi'); process.exit(1); }
if (!iceri.length) { console.log('KIRMIZI: hicbir kayit eslesmedi — desen bozuk olabilir'); process.exit(1); }

const zincir = {};
let noYok = 0, say = { asil: 0, degisiklik: 0, mulga: 0 };
for (const x of iceri) {
  const m = x.baslik.match(NO_DESENI);
  if (!m) { noYok++; continue; }
  const no = m[1].replace(/\s/g, '');
  const tur = turBul(x.baslik);
  say[tur]++;
  (zincir[no] = zincir[no] || []).push({ tarih: x.tarih, kod: x.kod, url: x.url, tur, baslik: x.baslik });
}

// ---- KENDI KENDINI DENETLE ----
let hatali = 0;
for (const no in zincir) for (const k of zincir[no]) if (k.tur !== turBul(k.baslik)) hatali++;
console.log('ham kayit: ' + kayitlar.length + ' | ithalat tedbiri: ' + iceri.length + ' | ilgisiz: ' + disari.length);
console.log('teblig numarasi: ' + Object.keys(zincir).length + ' | no cikmayan: ' + noYok);
console.log('asil / degisiklik / mulga: ' + say.asil + ' / ' + say.degisiklik + ' / ' + say.mulga);
console.log('kendi denetimi — etiketi basligiyla tutmayan kayit: ' + hatali);
if (hatali) { console.log('KIRMIZI: etiket tutarsiz, YAZILMADI'); process.exit(1); }

if (!UYGULA) { console.log('OLCUM MODU — yazilmadi. Yazmak icin: -uygula'); process.exit(0); }
fs.writeFileSync(path.join(KOK, 'veri/gozetim-teblig-zinciri.json'), JSON.stringify({
  aciklama: 'Ithalat gozetim/korunma tebligleri numaraya gore kronolojik zincir. "tur" alani basliktan turetilir: Yururlukten Kaldiril -> mulga, Degisiklik Yapilmasina -> degisiklik, digeri -> asil. Yazmadan once her kayit yeniden denetlenir.',
  kaynak: 'veri/rg-gozetim-haritasi.json (RG taramasi)',
  uretici: 'motor/gozetim-zincir-cikar.js',
  ham_kayit: kayitlar.length,
  ithalat_tedbiri: iceri.length,
  ilgisiz: disari.length,
  teblig_sayisi: Object.keys(zincir).length,
  tur_dagilimi: say,
  zincir
}, null, 1));
console.log('Yazildi: veri/gozetim-teblig-zinciri.json');
