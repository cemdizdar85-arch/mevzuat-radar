// VİTRİN SORUSU SEÇİCİ (09.09.2026, Cem: "koyacağımız sorular sınavın en zor ve dikkat çeken soruları olmalı";
// 09.09 akşam Cem: "vitrinde çok çıkan sorular olmalı, 1 tane değil")
// Ana sayfadaki gösterimlik karta girecek soruları HİSLE değil ÖLÇÜTLE seçer. Kaynak: basılı Kaydır-Çöz
// sayfalarındaki SORULAR verisi (kaydir/<sinav>/*.html) — hakem, simülasyon, çıkmış dönem sayımı orada hazır.
//
// Ölçütler (hepsi veride ölçülü, hiçbiri hafızadan değil):
//   ŞART  hakem EVET · öğrenci simülasyonu ikizi çözmüş · çıkma sayısı ≥ 3 dönem
//   PUAN  çıkma sayısı ×2 · hesaplı (tablolu) +2 · çözüm tablosu satırı /10 · dört tuzak dolu +1
//   ÇEŞİT aynı konudan 1
//
// ⛔ 13.09.2026 — ÜÇ DEĞİŞİKLİK (Cem: "her gün 1 soru koy, hep güncel"; havuz 10 → 70, sınava 69 gün):
//
//  1) ÇIKMA SAYISI = KARTTAKİ ROZETLE AYNI ÖLÇÜ: max(s.donem, cikmis.donemler.length).
//     Önceki sürüm YALNIZ cikmis.donemler'e bakıyordu. Gece yayınlanan havuzda (tetikte-robot "havuz
//     tazelendi") o alan boş, s.donem dolu. Ölçüldü (3.191 soru): eski ölçüyle kapıdan geçen 152 aday,
//     benzersiz konu 52; Finansal Muhasebe 2, Denetim/Maliyet/MTA/Ticaret 0 — vitrin Türkçe ve İngilizce
//     sorularıyla dolacaktı. Rozet ölçüsüyle 838 aday, 204 konu; FM 274, Denetim 120, Maliyet 92.
//     Ziyaretçi kartta "📌 N dönemde çıktı"yı kaydir-coz.ps1'in max(...) ölçüsüyle görüyor; seçici başka
//     bir sayıyla seçerse vitrin vaadi ile kartın söylediği ayrışır.
//
//  2) DERS KOTASI = SINAVDAKİ AĞIRLIK (veri/sinav-tek-sayfa.json → dersler[].sinav_soru).
//     Önceki kural "ders başına en çok 3" idi: 15 derste eşit pay, Finansal Muhasebe'ye (sınavda 26 soru,
//     en ağır ders) Atatürk İlkeleri (5 soru) kadar yer. Cem vitrinin "en çok sorulan" dersleri
//     göstermesini istedi; yerler sınav ağırlığına göre dağıtılır, her derse en az 1.
//
//  3) SIRA = DERSLER SERPİŞTİRİLİR. Günlük robot (vitrin-kart.js) günün sorusunu "yılın günü mod adet"
//     ile seçiyor; liste puana göre dizili kalırsa FM art arda 15 gün gelirdi. Her ders kendi kotası
//     boyunca eşit aralıkla dağıtılır.
//
// Kullanım: node motor/vitrin-soru-sec.js sgs [adet=10] [--kuru]
//   → veri/sinav/kaydir-secim/vitrin-<sinav>-secim.json  (kaydir-coz.ps1 -SecimDosya için)
//   --kuru: dağılımı yazar, DOSYAYA YAZMAZ.
// Basım: motor/vitrin-bas.ps1 -Sinav sgs -Adet 70  (seçim + kaydir/vitrin/<sinav>.html)
const fs = require('fs');
const path = require('path');
const argv = process.argv.slice(2);
const kuru = argv.includes('--kuru');
const konumlu = argv.filter(a => !a.startsWith('--'));
const sinav = konumlu[0] || 'sgs';
const adet = parseInt(konumlu[1] || '10', 10);
const EN_AZ_DONEM = 3;
const kok = path.resolve(__dirname, '..');
const dizin = path.join(kok, 'kaydir', sinav);
if (!fs.existsSync(dizin)) { console.error('Kaydır-Çöz sayfası yok: ' + dizin + ' (önce kaydir-yayin.ps1 -Sinav ' + sinav + ')'); process.exit(2); }

// ⛔ 13.09: robot dosyaları bazen BOM'lu yazılıyor. Ölçüldü: veri/sinav-tek-sayfa.json 10:51'de BOM'lu
// geldi, JSON.parse reddetti, seçici SESSİZCE eşit ağırlığa düştü ve Finansal Muhasebe 70'te 5 yer aldı.
// Her JSON okuması BOM'u atarak yapılır.
function jsonOku(yol) { return JSON.parse(fs.readFileSync(yol, 'utf8').replace(/^﻿/, '')); }

// Türkçe harfleri katlar: SORULAR'da "Türkçe", sinav-tek-sayfa'da "Turkce" yazıyor.
function katla(s) {
  return String(s || '').split('|')[0].toLocaleLowerCase('tr')
    .replace(/ç/g, 'c').replace(/ğ/g, 'g').replace(/ı/g, 'i').replace(/i̇/g, 'i')
    .replace(/ö/g, 'o').replace(/ş/g, 's').replace(/ü/g, 'u').replace(/\s+/g, ' ').trim();
}

// --- sınav ağırlıkları (ölçülü kaynak) ---
const agirlik = {};
try {
  const ts = jsonOku(path.join(kok, 'veri', 'sinav-tek-sayfa.json'));
  const kodEsle = { sgs: 'SGS', smmm: 'SMMM', kgk: 'KGK', spk: 'SPL' };
  for (const d of (ts.dersler || [])) {
    if (d.sinav !== kodEsle[sinav]) continue;
    const n = parseInt(d.sinav_soru, 10);
    if (n > 0) agirlik[katla(d.ders)] = n;
  }
} catch (e) { console.warn('sinav-tek-sayfa.json okunamadı - dersler EŞİT ağırlıkla dağıtılacak'); }

// Parti gövdesi bu makinede var mı (kaydir-coz.ps1 soruyu veri/fabrika/kalip-parti-<etiket>.json'dan okur).
const partiOnbellek = {}; let _basilamaz = 0;
function partiVar(etiket, id) {
  if (!(etiket in partiOnbellek)) {
    const y = path.join(kok, 'veri', 'fabrika', 'kalip-parti-' + etiket + '.json');
    try { partiOnbellek[etiket] = fs.existsSync(y) ? Object.keys(jsonOku(y)) : null; }
    catch (e) { partiOnbellek[etiket] = null; }
  }
  const k = partiOnbellek[etiket];
  return !!(k && k.includes(id));
}
const adaylar = []; let toplam = 0;
for (const f of fs.readdirSync(dizin)) {
  if (!f.endsWith('.html') || f === 'index.html') continue;
  const h = fs.readFileSync(path.join(dizin, f), 'utf8');
  const m = h.match(/const SORULAR=(\[\{[\s\S]*?\}\]);\r?\n/);   // git autocrlf: yerelde CRLF olabilir
  if (!m) { console.warn('SORULAR bulunamadı: ' + f); continue; }
  let liste; try { liste = JSON.parse(m[1]); } catch (e) { console.warn('JSON okunamadı: ' + f); continue; }
  for (const s of liste) {
    toplam++;
    const o = s.olcum || {};
    if (String(o.hakem) !== 'EVET') continue;
    if (!(o.sim && o.sim.dogru === true)) continue;
    // (1) KARTTAKİ ROZETLE AYNI ÖLÇÜ
    const donem = Math.max(parseInt(s.donem, 10) || 0,
      (s.cikmis && Array.isArray(s.cikmis.donemler)) ? s.cikmis.donemler.length : 0);
    if (donem < EN_AZ_DONEM) continue;
    const satir = (s.tablo && s.tablo.satirlar) ? s.tablo.satirlar.length : 0;
    const hesapli = !s.teori && satir > 2;
    const tuzak = s.tuzak ? Object.keys(s.tuzak).length : 0;
    const puan = donem * 2 + (hesapli ? 2 : 0) + satir / 10 + (tuzak >= 4 ? 1 : 0);
    const [etiket, id] = String(s.id).split('/');
    // (4) BASILABİLİR Mİ — 13.09 ölçüldü: 70 seçildi, kaydir-coz.ps1 "70 istendi -> 63 bulundu" dedi.
    // 7 sorunun partisi (gece bulutta yayınlanan sgs-d3-*) bu makinenin veri/fabrika/ klasöründe YOK
    // (git dışı). Basılamayacak soru seçilirse havuz eksik kalır; yerine basılabilen aday girsin.
    if (!partiVar(etiket, id)) { _basilamaz++; continue; }
    adaylar.push({ etiket, id, ders: s.ders, konu: s.konu, donem, kurtarma: false,
      _dk: katla(s.ders), _puan: Math.round(puan * 100) / 100, _hesapli: hesapli, _satir: satir,
      _capa: (s.capa && s.capa.kaynak) || '' });
  }
}
adaylar.sort((a, b) => b._puan - a._puan);

// --- her ders için konusu tekil, puana göre dizili aday listesi (konu teklik TÜM derslerde ortak) ---
const konuGordu = new Set();
const dersListe = {};
for (const a of adaylar) {
  const k = katla(a.konu);
  if (konuGordu.has(k)) continue;
  konuGordu.add(k);
  (dersListe[a._dk] = dersListe[a._dk] || []).push(a);
}
const dersler = Object.keys(dersListe);
if (!dersler.length) { console.error('hiç aday yok'); process.exit(3); }

// --- (2) KOTA: sınav ağırlığına orantılı, her derse en az 1, elde olandan fazla değil ---
const enAz = Math.min(...Object.values(agirlik).concat([5]));
const w = {}; dersler.forEach(d => { w[d] = agirlik[d] || enAz; });
const wToplam = dersler.reduce((t, d) => t + w[d], 0);
const hedefAdet = Math.min(adet, dersler.reduce((t, d) => t + dersListe[d].length, 0));
const kota = {}; const artik = [];
dersler.forEach(d => {
  const ham = hedefAdet * w[d] / wToplam;
  kota[d] = Math.min(dersListe[d].length, Math.max(1, Math.floor(ham)));
  artik.push({ d, kalan: ham - Math.floor(ham) });
});
let dagitilan = dersler.reduce((t, d) => t + kota[d], 0);
// fazla dağıtıldıysa (en az 1 kuralı yüzünden) en küçük artıklı ağır derslerden geri al
artik.sort((a, b) => a.kalan - b.kalan);
for (const { d } of artik) { if (dagitilan <= hedefAdet) break; if (kota[d] > 1) { kota[d]--; dagitilan--; } }
// eksik kaldıysa büyük artık sırasıyla, sonra ağırlık sırasıyla, elde aday olan derse ekle
artik.sort((a, b) => b.kalan - a.kalan);
let tur = 0;
while (dagitilan < hedefAdet && tur < 1000) {
  let eklendi = false;
  const sira = tur === 0 ? artik.map(x => x.d) : dersler.slice().sort((a, b) => w[b] - w[a]);
  for (const d of sira) {
    if (dagitilan >= hedefAdet) break;
    if (kota[d] < dersListe[d].length) { kota[d]++; dagitilan++; eklendi = true; }
  }
  if (!eklendi) break;
  tur++;
}

// --- (3) SERPİŞTİRME: her ders kendi kotası boyunca eşit aralıkla ---
const secim = [];
dersler.forEach(d => {
  dersListe[d].slice(0, kota[d]).forEach((a, r) => {
    secim.push(Object.assign({}, a, { _anahtar: (r + 0.5) / kota[d] }));
  });
});
secim.sort((a, b) => (a._anahtar - b._anahtar) || (w[b._dk] - w[a._dk]) || (b._puan - a._puan));

const hedef = path.join(kok, 'veri', 'sinav', 'kaydir-secim', 'vitrin-' + sinav + '-secim.json');
const temiz = secim.map(({ etiket, id, ders, konu, donem, kurtarma }) => ({ etiket, id, ders, konu, donem, kurtarma }));
if (!kuru) fs.writeFileSync(hedef, JSON.stringify(temiz, null, 2) + '\n', 'utf8');
console.log('taranan ' + toplam + ' · basılamaz (parti bu makinede yok) ' + _basilamaz + ' · ≥' + EN_AZ_DONEM + ' dönem aday ' + adaylar.length +
  ' · tekil konu ' + dersler.reduce((t, d) => t + dersListe[d].length, 0) +
  ' · seçilen ' + secim.length + (kuru ? ' (KURU - dosyaya yazılmadı)' : ' → ' + path.relative(kok, hedef)));
console.log('ders kotası (sınav ağırlığı → yer):');
dersler.slice().sort((a, b) => w[b] - w[a]).forEach(d => {
  console.log('  ' + String(w[d]).padStart(2) + ' soru → ' + String(kota[d]).padStart(2) + ' yer · ' + d + ' (elde ' + dersListe[d].length + ')');
});
console.log('ilk 20 günün sırası:');
secim.slice(0, 20).forEach((s, i) => console.log('  ' + String(i).padStart(2) + ' | ' + s.donem + ' dönem | ' + s.ders + ' | ' + s.konu + ' | ' + (s._hesapli ? 'hesaplı' : 'teori')));
if (!secim.length) { console.error('hiç aday yok'); process.exit(3); }
