// ============================================================================
//  GOZETIM TABLOSU OKUYUCU — mevzuat.gov.tr .doc (UTF-16LE Word HTML) icinden
//  GTIP tablosunu cikarir. Nobetci (gozetim-nobeti.js) BUNU KULLANMAZ; nobetci
//  yalniz eksigi sayar. Bu modul, yeni bir teblig partisi okunacagi zaman elle
//  cagrilir ve ciktisi HER ZAMAN once sitedeki mevcut veriyle SINANIR.
//
//  NEDEN .doc: mevzuat.gov.tr'nin .doc surumu cogu tebligde Word HTML'i ve tablo
//  GERCEK <tr>/<td> hucreleriyle geliyor; rowspan cozulunce birlesik hucreler de
//  dogru okunuyor. PDF'in duz metninde sutunlari TAHMIN etmek zorundayiz ve
//  yaniliyoruz (19.08 olcumu: pdftotext -layout, sitedeki 54 tebligin 61
//  degerini yanlis okudu). -table modu dogru okuyor ama xpdf'e ozel, CI'da yok.
//
//  ICINDEKI IKI SIGORTA — ikisi de gercek hatadan dogdu:
//   (1) DEGER SUTUNU BASLIKTAN secilir ("Kiymet"/"Dolari" gecen sutun).
//       Onceki surum "en cok sayi iceren sutun" diyordu ve 2023/8'de sira-no
//       kolonuna kanip 13 kodun degerini 1,2,3,4… diye okudu.
//   (2) SAYAC DENETIMI: secilen sutun 1,2,3,4… diye akiyorsa kuskulu isaretlenir
//       ve o teblig otomatik yazilmaz.
//  Ayrica: pozisyon kodlari (9025.11, 70.13, 36.04) da taninir — bazi tebligler
//  kodu 12 hane yazmaz. Deger sutunu HIC yoksa "sartsiz gozetim"dir; deger
//  UYDURULMAZ, durum oyle kaydedilir.
// ============================================================================
const TAM = /^\d{4}\.\d{2}\.\d{2}\.\d{2}\.\d{2}$/;
const POZ = /^\d{2,4}\.\d{2}(\.\d{2})?$/;
const SAYI = /^\d{1,3}(?:\.\d{3})*(?:,\d+)?$|^\d+(?:,\d+)?$/;
const temiz = s => (s || '').replace(/[+*\s]+$/, '').trim();

function duz(h) {
  return h.replace(/<[^>]*>/g, ' ')
    .replace(/&nbsp;/g, ' ').replace(/&amp;/g, '&').replace(/&lt;/g, '<').replace(/&gt;/g, '>')
    .replace(/&#(\d+);/g, (_, d) => String.fromCharCode(d))
    .replace(/\s+/g, ' ').trim();
}

// rowspan/colspan cozulerek izgaraya acilir — birlesik hucreler kaybolmasin
function izgara(tabloHtml) {
  const satirlar = [...tabloHtml.matchAll(/<tr[^>]*>([\s\S]*?)<\/tr>/gi)].map(m => m[1]);
  const grid = [], bekleyen = {};
  for (const s of satirlar) {
    const satir = []; let c = 0;
    const koy = v => {
      while (bekleyen[c] && bekleyen[c].kalan > 0) { satir[c] = bekleyen[c].metin; bekleyen[c].kalan--; c++; }
      satir[c] = v; c++;
    };
    for (const h of [...s.matchAll(/<t[dh]([^>]*)>([\s\S]*?)<\/t[dh]>/gi)]) {
      const metin = duz(h[2]);
      const rs = parseInt((h[1].match(/rowspan\s*=\s*"?(\d+)/i) || [])[1] || '1', 10);
      const cs = parseInt((h[1].match(/colspan\s*=\s*"?(\d+)/i) || [])[1] || '1', 10);
      for (let k = 0; k < cs; k++) { const sut = c; koy(metin); if (rs > 1) bekleyen[sut] = { metin, kalan: rs - 1 }; }
    }
    while (bekleyen[c] && bekleyen[c].kalan > 0) { satir[c] = bekleyen[c].metin; bekleyen[c].kalan--; c++; }
    grid.push(satir);
  }
  return grid;
}

// 1,2,3,4… gibi akiyorsa bu bir sira-no kolonudur, kiymet degil
function sayacMi(d) {
  if (d.length < 4) return false;
  const s = d.map(v => parseFloat(String(v).replace(/\./g, '').replace(',', '.')));
  let a = 0;
  for (let i = 1; i < s.length; i++) if (s[i] === s[i - 1] + 1) a++;
  return a >= s.length - 2;
}

function tabloCoz(html) {
  let enIyi = null;
  for (const m of html.matchAll(/<table[^>]*>([\s\S]*?)<\/table>/gi)) {
    const g = izgara(m[0]);
    const kodSay = {};
    g.forEach(r => r.forEach((v, i) => { const t = temiz(v); if (t && (TAM.test(t) || POZ.test(t))) kodSay[i] = (kodSay[i] || 0) + 1; }));
    const kodSut = Object.keys(kodSay).sort((a, b) => kodSay[b] - kodSay[a])[0];
    if (kodSut === undefined) continue;

    // (1) SUTUN BASLIKTAN
    let degSut, kaynak = 'baslik', kuskulu = false;
    for (const r of g) {
      for (let i = 0; i < r.length; i++) {
        if (i == kodSut || !r[i]) continue;
        const t = temiz(r[i]);
        if (/k[ıi]ymet|dolar[ıi]/i.test(r[i]) && !TAM.test(t) && !POZ.test(t)) { degSut = i; break; }
      }
      if (degSut !== undefined) break;
    }
    if (degSut === undefined) {
      const dSay = {};
      g.forEach(r => {
        const k = temiz(r[kodSut]);
        if (!TAM.test(k) && !POZ.test(k)) return;
        r.forEach((v, i) => { if (i != kodSut && v && SAYI.test(temiz(v))) dSay[i] = (dSay[i] || 0) + 1; });
      });
      degSut = Object.keys(dSay).sort((a, b) => dSay[b] - dSay[a])[0];
      kaynak = 'siklik'; kuskulu = true;
    }

    const tam = {}, poz = {}, ham = [];
    let kodVar = 0;
    for (const r of g) {
      const k = temiz(r[kodSut]);
      if (!TAM.test(k) && !POZ.test(k)) continue;
      kodVar++;
      const d = degSut === undefined ? '' : temiz(r[degSut]);
      if (!SAYI.test(d)) continue;
      if (TAM.test(k)) { if (!tam[k]) { tam[k] = d; ham.push(d); } }
      else if (!poz[k]) { poz[k] = d; ham.push(d); }
    }
    if (!kodVar) continue;
    if (ham.length && sayacMi(ham)) { kuskulu = true; kaynak += '+sayac-suphesi'; }   // (2)

    if (!enIyi || kodVar > enIyi.kodVar) {
      const birim = (m[0].match(/\(\s*(ABD\s*[Dd]olar[ıi]\s*\/[^)<\n]{1,30})\)/i)
        || html.match(/\(\s*(ABD\s*[Dd]olar[ıi]\s*\/[^)<\n]{1,30})\)/i) || [])[1];
      const sartsiz = (Object.keys(tam).length + Object.keys(poz).length) === 0;
      const sartsizKod = [];
      if (sartsiz) for (const r of g) { const k = temiz(r[kodSut]); if (TAM.test(k) || POZ.test(k)) sartsizKod.push(k); }
      enIyi = { tam, poz, sartsiz, sartsizKod, kodVar, kuskulu, kaynak, birim: birim ? birim.replace(/\s+/g, ' ').replace(/\*/g, '').trim() : null };
    }
  }
  return enIyi;
}

// "ABD doları/ton", "ABD Doları/Kg.", "/Brüt Kg", "/Kilogram" → tek bicim
function birimDuzelt(b) {
  let s = (b || '').replace(/\s+/g, ' ').replace(/\.$/, '').trim();
  s = s.replace(/^abd\s*dolar[ıi]/i, 'ABD Doları');
  s = s.replace(/\/\s*br[üu]t\s*/i, '/');
  s = s.replace(/\/\s*kilogram/i, '/Kg').replace(/\/\s*kg/i, '/Kg');
  s = s.replace(/\/\s*ton/i, '/Ton').replace(/\/\s*adet/i, '/Adet');
  return s;
}

// mevzuat.gov.tr .doc'unu getirir; UTF-16LE HTML degilse null
async function belgeGetir(mevzuatNo) {
  const r = await fetch('https://www.mevzuat.gov.tr/MevzuatMetin/yonetmelik/9.5.' + mevzuatNo + '.doc',
    { headers: { 'User-Agent': 'Mozilla/5.0' } });
  if (!r.ok) return null;
  const b = Buffer.from(await r.arrayBuffer());
  if (b.slice(0, 2).toString('hex') !== 'fffe') return null;
  return b.toString('utf16le');
}

// Belge gercekten O teblige mi ait? Tutmuyorsa kayit REDDEDILIR.
function kimlikTutuyorMu(html, teblig) {
  const no = teblig.replace('/', '\\s*/\\s*');
  return new RegExp('NO\\s*:?\\s*' + no, 'i').test(duz(html));
}

module.exports = { duz, izgara, tabloCoz, birimDuzelt, belgeGetir, kimlikTutuyorMu, TAM, POZ, SAYI };
