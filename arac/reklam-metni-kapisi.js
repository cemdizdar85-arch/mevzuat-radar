#!/usr/bin/env node
/* ============================================================================
   REKLAM METNİ KAPISI — "bu reklam metni yayına çıkarsa ceza/kapatma riski var mı?"
   29.09.2026, Cem "reklam metni kapısını kur"

   NİYE VAR: sayı iddiası kapısı (arac/sayi-iddia-kapisi.js) yalnız SİTE
   sayfalarını tarar; Instagram/Meta reklam metni depo dışında kalıyordu.
   Dayanaklar (hafıza hukuk-5580-reklam-riski, 24.09 GM kaynağından doğruladı):
     • Ticari Reklam ve Haksız Ticari Uyg. Yön. m.9 — iddianın ispatı reklam verende
     • aynı Yön. m.18/8 (01.08.2026) — YZ ile üretilmiş karakter AÇIKÇA belirtilir
     • Reklam Kurulu 371. toplantı (16.07.2026): "reklam" ibaresiz YZ ders
       uygulaması videosu 1.083.706 TL; 366./355. "en çok kazandıran kurs" cezaları
     • 5580 m.3 + Danıştay 8.D E.2022/3829: "kurs/eğitim" dili = MEB izni tartışması
     • SMMM sınavlarını TÜRMOB yapar, ÖSYM değil; kurum adı/logosu yalnız
       "bağlantısı yoktur" uyarısında geçer (Yön. m.11/1-a)

   TARANAN: pazarlama/reklam/*.md — bir dosya = bir reklam (görseldeki yazı +
   seslendirme + açıklama metni). '_' ya da 'README' ile başlayan dosya taranmaz.
   Dosya başı beyan ŞART:
       ---
       tur: reklam | organik        (reklam → "Reklam" ibaresi zorunlu)
       yz: evet | hayir             (evet → "Yapay zekâ ile üretilmiştir" zorunlu)
       ---
   KURALLAR (her biri ayrı KIRMIZI):
     K-BEYAN  tur/yz satırı yok ya da değeri tanımsız
     K-REKLAM tur: reklam ama metinde tek başına "Reklam" ya da "#reklam" yok
     K-YZ     yz: evet ama "yapay zekâ ile üretilmiştir" yok
     K-KELIME yasak söz (kurs, eğitim, hoca, öğretmen, MEB, onaylı, Türkiye geneli,
              en çok/en iyi/…, garanti, %100, lider, ÖSYM, resmî deneme …)
     K-KURUM  TÜRMOB/TESMER "bağlantısı/ilgisi yoktur" cümlesi DIŞINDA geçiyor
     K-DENEME "canlı deneme" geçiyor ama resmî sınavla bağlantı yok uyarısı yok
     K-SAYI   soru sayısı iddiası sitedeki sayıyı aşıyor (sayi-iddia-kapisi.js
              ile AYNI mantık ve AYNI karşı sayı: kaydir/<sınav>/index.html)
   GEÇ: aynı ya da üst satırda "reklam-kapi:gec <gerekçe, en az 10 harf>"
        (ör. "eğitim" kelimesi alıntı içinde). Gerekçesiz geç = KIRMIZI.
        K-BEYAN/K-REKLAM/K-YZ/K-DENEME geçilemez.

   🚫 BU KAPI ŞUNLARI GÖRMEZ ("ölçülmedi" sayılır):
     • Görseldeki / videodaki yazı dosyaya yazılmadıysa (kapı yalnız .md okur)
     • "SMMM" unvanının kişi için kullanılması (sınav adıyla ayırt edilemiyor)
     • Anlam: "en" kalıbı dışındaki üstünlük iddiaları ("rakipsiz" listede; yeni
       ifadeler listeye eklenmedikçe geçer), karşılaştırmalı reklam, fiyat doğruluğu
     • Meta reklam yöneticisine elle yazılan, depoya girmeyen metin

   Kullanım:  node arac/reklam-metni-kapisi.js           (depoyu tarar)
              node arac/reklam-metni-kapisi.js --sinav   (öz-sınav)
              node arac/reklam-metni-kapisi.js <dosya.md> (tek dosya — yayından önce)
   Çıkış:     0 temiz · 1 kırmızı ya da KÖR (sitedeki sayı okunamadı)
   Bedel:     0 (yalnız dosya okur)
   İÇ NOT:    <!-- ... --> yorumları yayınlanmaz, TARANMAZ ("Reklam" ibaresi de orada sayılmaz).
   Mutasyon:  REK_MUTASYON=kelime|kurum|reklam|yz|sayi|gec|beyan|yorum → öz-sınav KIRMIZI düşmeli
   ============================================================================ */
'use strict';
const fs = require('fs');
const path = require('path');
const { metniTara, sitedekiSayilar } = require('./sayi-iddia-kapisi.js');

const KOK = path.resolve(__dirname, '..');
const KLASOR = path.join('pazarlama', 'reklam');
const MUT = process.env.REK_MUTASYON || '';

// Türkçe küçük harf: İ→i, I→ı (ICU'dan bağımsız; 23.09 Linux 'İ' dersi)
const kucuk = s => s.replace(/İ/g, 'i').replace(/I/g, 'ı').toLowerCase().replace(/â/g, 'a').replace(/î/g, 'i').replace(/û/g, 'u');
const H = '\\p{L}';   // harf sınıfı; \b Türkçe harfte çalışmaz

// [ad, desen (küçük harfli metne), neden]
const YASAK = [
  ['kurs', `(?<!${H})kurs`, '5580: "kurs" = MEB izinli kurum çağrışımı'],
  ['eğitim/eğitmen', `(?<!${H})eğit(?:im|men)`, '5580 m.3: "eğitim-öğretim sunmak" MEB iznine tabi'],
  ['hoca', `(?<!${H})hoca`, '"hoca" yok → Nöbetçi (smmm-unvan-ve-reklam-siniri)'],
  ['öğretmen', `(?<!${H})öğretmen`, '5580 + unvan sınırı'],
  ['MEB/Bakanlık', `(?<!${H})(?:meb|milli eğitim|bakanlık)(?!${H})`, 'Yön. ek liste 4: sahte kurum onayı (337. toplantı 347.128 TL)'],
  ['onaylı', `(?<!${H})onayl[ıi](?!${H})`, 'onay iddiası belge ister'],
  ['Türkiye geneli', `türkiye(?:'?nin| geneli| çapında)`, 'ölçek iddiası ispat ister (24.09 kaldırıldı)'],
  ['en + üstünlük', `(?<!${H})en (?:çok|iyi|kapsamlı|başarılı|güncel|doğru|hızlı|ucuz|uygun|büyük|kaliteli)(?!${H})`, 'Yön. m.9: üstünlük iddiası belge ister (366./355. toplantı)'],
  ['garanti', `(?<!${H})garanti`, 'sonuç vaadi ispatlanamaz'],
  ['kesin geçer', `kesin(?:likle)? geç`, 'sonuç vaadi ispatlanamaz'],
  ['%100 / yüzde yüz', `(?:%\\s*100|yüzde yüz)(?!\\d)`, 'sonuç/isabet vaadi ispatlanamaz'],
  ['lider/bir numara', `(?<!${H})(?:lider|bir numara|1 numara|rakipsiz|birinci sırada)`, 'üstünlük iddiası belge ister'],
  ['ÖSYM', `(?<!${H})ösym(?!${H})`, 'SMMM sınavlarını TÜRMOB yapar; ÖSYM adı yanlış ve kurum adı kullanımı'],
  ['resmî deneme/sınav', `resm[iî] (?:deneme|provas)`, 'resmî sınavla bağlantı çağrışımı'],
];
const KURUM = /(?<!\p{L})(türmob|tesmer)(?!\p{L})/u;
const KURUM_UYARI = /(bağlantıs[ıi]|ilgis[ıi]|ilişkis[ıi]) (yoktur|yok|bulunmamaktadır)|resm[iî] (değil|olmayan)/u;
const REKLAM_IBARE = /(?:^|[^\p{L}#])reklam(?!\p{L})|#reklam(?!\p{L})/imu;
const YZ_IBARE = /yapay zeka (ile|kullanılarak) üretilmiştir/u;   // kucuk() â→a çevirir
const DENEME_UYARI = /resm[iî] sınav\p{L}*.{0,40}(bağlantıs[ıi]|ilgis[ıi]) (yoktur|yok)|(bağlantıs[ıi]|ilgis[ıi]) (yoktur|yok).{0,60}resm[iî] sınav/u;

function beyanOku(metin) {
  const m = /^﻿?---\r?\n([\s\S]*?)\r?\n---/.exec(metin);
  const b = {};
  if (m) for (const s of m[1].split(/\r?\n/)) { const k = /^\s*([a-z]+)\s*:\s*(.*?)\s*$/.exec(s); if (k) b[k[1]] = kucuk(k[2]); }
  return { beyan: b, govdeBas: m ? m[0].length : 0 };
}

function gecisVarMi(satirlar, i) {
  for (const s of [satirlar[i] || '', satirlar[i - 1] || '']) {
    const m = /reklam-kapi:gec\s*([^\n]*?)(?:-->|$)/.exec(s);
    if (m) {
      const gerekce = m[1].replace(/[^a-zçğıöşüA-ZÇĞİÖŞÜ]/g, '');
      return { var: true, gecerli: MUT === 'gec' ? true : gerekce.length >= 10 };
    }
  }
  return { var: false };
}

/* Dönüş: [{kural, satir, bulgu, neden, hukum}] ; hukum KIRMIZI | GEC */
function reklamiTara(dosyaAdi, ham, sayilar) {
  const bulgular = [];
  const satirlar = ham.split('\n');
  const { beyan, govdeBas } = beyanOku(ham);
  // <!-- iç not --> yayınlanmaz → satır numarası bozulmadan boşlukla doldurulur (sayi-iddia-kapisi ile aynı).
  // Geç işareti ham satırdan okunur (gecisVarMi), yorum silinse de kaybolmaz.
  const govde = MUT === 'yorum' ? ham.slice(govdeBas) : ham.slice(govdeBas).replace(/<!--[\s\S]*?-->/g, s => s.replace(/[^\n]/g, ' '));
  const govdeK = kucuk(govde);
  const satirNo = poz => ham.slice(0, govdeBas + poz).split('\n').length;   // 1 tabanlı
  const ekle = (kural, satir, bulgu, neden, gecilebilir) => {
    let hukum = 'KIRMIZI';
    if (gecilebilir) { const g = gecisVarMi(satirlar, satir - 1); if (g.var) hukum = g.gecerli ? 'GEC' : 'KIRMIZI'; }
    bulgular.push({ kural, satir, bulgu, neden, hukum });
  };

  // K-BEYAN
  const turOk = beyan.tur === 'reklam' || beyan.tur === 'organik';
  const yzOk = beyan.yz === 'evet' || beyan.yz === 'hayir' || beyan.yz === 'hayır';
  if (MUT !== 'beyan') {
    if (!turOk) ekle('K-BEYAN', 1, `tur: ${beyan.tur ?? '(yok)'}`, 'dosya başında "tur: reklam | organik" şart', false);
    if (!yzOk) ekle('K-BEYAN', 1, `yz: ${beyan.yz ?? '(yok)'}`, 'dosya başında "yz: evet | hayir" şart', false);
  }
  // K-REKLAM
  if (beyan.tur === 'reklam' && MUT !== 'reklam' && !REKLAM_IBARE.test(govde))
    ekle('K-REKLAM', 1, '"Reklam" ibaresi yok', 'Reklam Kurulu 371. toplantı: ibaresiz video 1.083.706 TL', false);
  // K-YZ
  if (beyan.yz === 'evet' && MUT !== 'yz' && !YZ_IBARE.test(govdeK))
    ekle('K-YZ', 1, '"Yapay zekâ ile üretilmiştir" yok', 'Yön. m.18/8 (01.08.2026): YZ karakteri açıkça belirtilir', false);
  // K-DENEME
  if (/canlı deneme/u.test(govdeK) && !DENEME_UYARI.test(govdeK))
    ekle('K-DENEME', satirNo(govdeK.indexOf('canlı deneme')), '"canlı deneme" var, resmî sınavla bağlantı uyarısı yok',
      'canli-deneme.html ile aynı satır: "resmî sınavlarla bağlantısı yoktur"', false);
  // K-KELIME
  if (MUT !== 'kelime') {
    for (const [ad, desen, neden] of YASAK) {
      for (const m of govdeK.matchAll(new RegExp(desen, 'gu'))) {
        ekle('K-KELIME', satirNo(m.index), `${ad}: "${govde.substr(m.index, Math.max(m[0].length, 12)).split('\n')[0].trim()}"`, neden, true);
      }
    }
  }
  // K-KURUM: cümle bazında (nokta/ünlem/soru/satır sonu)
  if (MUT !== 'kurum') {
    const cumleRe = /[^.!?\n]+[.!?]?/gu;
    for (const c of govdeK.matchAll(cumleRe)) {
      const k = KURUM.exec(c[0]);
      if (k && !KURUM_UYARI.test(c[0])) ekle('K-KURUM', satirNo(c.index + k.index), `"${k[1].toUpperCase()}" uyarı cümlesi dışında`, 'Yön. m.11/1-a: kurum adı/logosu kullanılamaz', true);
    }
  }
  // K-SAYI (site kapısıyla aynı mantık)
  if (MUT !== 'sayi') {
    for (const b of metniTara(dosyaAdi, govde, sayilar)) {
      if (!b.hukum.startsWith('KIRMIZI') && b.hukum !== 'GEC') continue;
      ekle('K-SAYI', b.satir + ham.slice(0, govdeBas).split('\n').length - 1, `"${b.iddia}" = ${b.deger} · ${b.karsiAd} ${b.karsi}`, 'Yön. m.9: sayı iddiası sitedeki yayın sayısını aşamaz', true);
    }
  }
  return bulgular;
}

function dosyalar(kok, tekDosya) {
  if (tekDosya) return [path.resolve(tekDosya)];
  const d = path.join(kok, KLASOR);
  if (!fs.existsSync(d)) return [];
  return fs.readdirSync(d).filter(a => /\.md$/i.test(a) && !/^(_|readme)/i.test(a)).map(a => path.join(d, a));
}

function depoyuTara(kok, tekDosya) {
  const { sayilar, kor } = sitedekiSayilar(kok);
  const liste = dosyalar(kok, tekDosya);
  const sonuc = liste.map(f => ({ dosya: path.relative(kok, f).replace(/\\/g, '/'), bulgular: reklamiTara(path.basename(f), fs.readFileSync(f, 'utf8'), sayilar) }));
  return { sayilar, kor, sonuc };
}

function yazdir(r) {
  let kir = 0, gec = 0;
  for (const s of r.sonuc) {
    const k = s.bulgular.filter(b => b.hukum === 'KIRMIZI').length;
    kir += k; gec += s.bulgular.filter(b => b.hukum === 'GEC').length;
    console.log(`${k ? '✗ ' : 'ok'} ${s.dosya}`);
    for (const b of s.bulgular) console.log(`   ${b.hukum === 'GEC' ? 'gec' : ' ✗ '} ${b.kural} satır ${b.satir}: ${b.bulgu} — ${b.neden}`);
  }
  for (const k of r.kor) console.log(`  KÖR ${k}`);
  const durum = r.kor.length ? 'KÖR' : kir ? 'KIRMIZI' : 'YEŞİL';
  console.log(`REKLAM METNİ: ${durum} · taranan reklam ${r.sonuc.length} · kırmızı ${kir} · gerekçeli geç ${gec} · kör ${r.kor.length}`);
  console.log('GÖRMEZ: dosyaya yazılmamış görsel/video yazısı · kişi için "SMMM" unvanı · listede olmayan üstünlük ifadesi · Meta paneline elle yazılan metin');
  return durum === 'YEŞİL' ? 0 : 1;
}

/* ---------------------------------------------------------------- ÖZ-SINAV */
function ozSinav() {
  const say = { sgs: 4388, smmm: 2729, kgk: null };
  const R = '---\ntur: reklam\nyz: hayir\n---\n';
  const Y = '---\ntur: reklam\nyz: evet\n---\n';
  const O = '---\ntur: organik\nyz: hayir\n---\n';
  const V = [
    // [ad, metin, beklenen kırmızı kurallar (sıralı, virgüllü) ]
    ['temiz reklam', R + 'Reklam\nBu soruyu biliyorsun, değil mi? Yanlışını böyle öğrenirsin. tetikte.com', ''],
    ['#reklam etiketi de sayılır', R + 'Tuzağın adını öğren. #reklam #smmm', ''],
    ['organikte ibare aranmaz', O + 'Tam Yıl Tuzağı: TMS 38.', ''],
    ['beyansız dosya', 'Reklam\nsoru çöz', 'K-BEYAN,K-BEYAN'],
    ['ibaresiz reklam', R + 'Bu soruyu biliyorsun, değil mi?', 'K-REKLAM'],
    ['YZ ibaresi eksik', Y + 'Reklam\nSORU fısıldar: "D. Kesin D."', 'K-YZ'],
    ['YZ ibaresi var (şapkalı)', Y + 'Reklam · Yapay zekâ ile üretilmiştir.\nSORU fısıldar.', ''],
    ['kurs dili', R + 'Reklam\nKursa gitmeden hazırlan.', 'K-KELIME'],
    ['eğitim + hoca', R + 'Reklam\nEn iyi eğitim, hocasız.', 'K-KELIME,K-KELIME,K-KELIME'],
    ['MEB onaylı', R + 'Reklam\nMEB onaylı soru bankası', 'K-KELIME,K-KELIME'],
    ['Türkiye geneli + İ büyük harf', R + 'Reklam\nTÜRKİYE GENELİ DENEME', 'K-KELIME'],
    ['%100 garanti', R + 'Reklam\n%100 başarı garantisi', 'K-KELIME,K-KELIME'],
    ['ÖSYM adı', R + 'Reklam\nÖSYM tarzı sorular', 'K-KELIME'],
    ['TÜRMOB uyarı dışında', R + 'Reklam\nTÜRMOB sınavına hazır ol.', 'K-KURUM'],
    ['TÜRMOB uyarı içinde (serbest)', R + 'Reklam\nTetikte\'nin kendi denemesidir; TÜRMOB ve TESMER\'in yaptığı resmî sınavlarla bağlantısı yoktur.', ''],
    ['canlı deneme uyarısız', R + 'Reklam\n4 Ekim canlı deneme, ücretsiz.', 'K-DENEME'],
    ['canlı deneme uyarılı', R + 'Reklam\n4 Ekim canlı deneme. Resmî sınavla bağlantısı yoktur.', ''],
    ['sayı fazla', R + 'Reklam\n30.000 soru seni bekliyor', 'K-SAYI'],
    ['sayı doğru', R + 'Reklam\n7.000\'den fazla soru', ''],
    ['gerekçeli geç', R + 'Reklam\n"Kursa gitme" diyenlere cevap. <!-- reklam-kapi:gec rakip kurumun sloganı alıntı, 29.09 -->', ''],
    ['gerekçesiz geç', R + 'Reklam\nKursa gitme. <!-- reklam-kapi:gec -->', 'K-KELIME'],
    ['yanlış alarm yok: "en" başka sözle', R + 'Reklam\nEn son soruyu sen çöz. Seni en zor anında yakalar.', ''],
    ['yanlış alarm yok: "reklamcılık" ibare sayılmaz', R + 'Reklamcılık dersi sorusu', 'K-REKLAM'],
    ['iç not (yorum) taranmaz', R + '<!-- eski kart "Kursa gitme." 5580 yüzünden çıktı -->\nReklam\nBildiğini sandığın soru eler.', ''],
    ['yorumdaki "Reklam" ibare sayılmaz', R + '<!-- Reklam ibaresi eklenecek -->\nBildiğini sandığın soru eler.', 'K-REKLAM'],
  ];
  let hata = 0;
  for (const [ad, metin, bek] of V) {
    const b = reklamiTara('vaka.md', metin, say).filter(x => x.hukum === 'KIRMIZI').map(x => x.kural).sort().join(',');
    const ok = b === bek.split(',').filter(Boolean).sort().join(',');
    if (!ok) { hata++; console.log(`  ✗ ${ad}: ${b || '(temiz)'} (beklenen ${bek || '(temiz)'})`); }
    else console.log(`  ok ${ad}`);
  }
  console.log(`REKLAM METNİ ÖZ-SINAVI: ${hata ? 'KIRMIZI' : 'YEŞİL'} (${V.length - hata}/${V.length})${MUT ? ' · mutasyon: ' + MUT : ''}`);
  return hata ? 1 : 0;
}

if (require.main === module) {
  const arg = process.argv.slice(2);
  if (arg.includes('--sinav')) process.exit(ozSinav());
  process.exit(yazdir(depoyuTara(KOK, arg.find(a => /\.md$/i.test(a)))));
}
module.exports = { reklamiTara };
