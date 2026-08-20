// ============================================================================
//  GOZETIM NOBETCISI — izlenen teblig listesi bir daha SESSIZCE geride kalmasin.
//
//  NEDEN VAR (20.08.2026): 11.07'de kurulan hasat motoruna okuyacagi teblig
//  listesi ELLE yaziliyordu. Eslemede 182 teblig kayitliydi; "kacini okuduk"
//  sorusu 11 Temmuz'dan 19 Agustos'a kadar HIC sorulmadi. Sorulunca cikan: 54.
//  Liste elle tutuldugu surece yine geride kalir.
//
//  NEDEN YAZMIYOR, YALNIZ BAKIYOR: once otomatik YAZAN bir surum yazildi ve
//  denendi. Tablo sutunu secerken 2023/8'de "sira no" kolonunu kiymet sanip
//  13 kodun degerini (4 / 5,5 / 6 …) 1,2,3,4… diye YANLIS okudu. Denenmeseydi
//  veriyi bozacakti. Bu yuzden nobetci deger YAZMAZ; eksigi ve celiskiyi
//  gorunur kilar, okuma insan kararlidir.
//
//  KIRMIZI OLCUSU: eslemede kayitli olup gtip-durum.json'da OLMAYAN bir teblig,
//  motor/hafiza/gozetim-bekleyen-elle.json listesinde de yoksa → KIRMIZI.
//  Yani "bilerek disarida" olan her teblig GEREKCESIYLE yazili olmak zorunda;
//  gerekcesiz eksik birikemez.
//
//  Dis bagimliligi yok: node + fetch. (PDF yolu bilerek kullanilmiyor —
//  pdftotext -layout sutunlari kaydiriyor, -table ise xpdf'e ozel ve CI'da yok.)
// ============================================================================
const fs = require('fs'), path = require('path');
const KOK = process.argv[2] || '.';
const J = f => JSON.parse(fs.readFileSync(f, 'utf8').replace(/^﻿/, ''));

const esleme = J(path.join(KOK, 'motor/hafiza/eslesme-gozetim.json')).esleme;
const durum = J(path.join(KOK, 'veri/gtip-durum.json'));
let bekleyen = {};
try { bekleyen = J(path.join(KOK, 'motor/hafiza/gozetim-bekleyen-elle.json')).teblig || {}; } catch (e) { }

const sitede = new Set();
for (const k in durum) for (const r of (durum[k] || [])) if (r && r.teblig) sitede.add(r.teblig);

const eksik = Object.keys(esleme).filter(t => esleme[t] && !sitede.has(t)).sort();
const gerekcesiz = eksik.filter(t => !bekleyen[t]);

// Yururlukten kalkmis olabilecekler: bekleyen listesinde "birlesik metin sunmuyor"
// gerekcesiyle duranlar. Bunlardan biri BIRDEN metin sunmaya baslarsa haber ver —
// demek ki teblig aslinda yasiyor ve okunmasi gerekiyor.
(async () => {
  const dirilen = [];
  const kontrolEdilecek = eksik.filter(t => bekleyen[t] && bekleyen[t].tur === 'kaynak-yok');
  for (const teb of kontrolEdilecek) {
    const mno = String(esleme[teb]);
    let canli = false;
    for (const uzanti of ['pdf', 'doc']) {
      try {
        const r = await fetch('https://www.mevzuat.gov.tr/MevzuatMetin/yonetmelik/9.5.' + mno + '.' + uzanti,
          { headers: { 'User-Agent': 'Mozilla/5.0' }, redirect: 'manual' });
        if (r.status === 200) {
          const b = Buffer.from(await r.arrayBuffer());
          const bas = b.slice(0, 4).toString();
          if (b.length > 5000 && (bas === '%PDF' || b.slice(0, 2).toString('hex') === 'fffe')) { canli = true; break; }
        }
      } catch (e) { }
    }
    if (canli) dirilen.push(teb);
  }

  const rapor = {
    tarih: new Date().toISOString().slice(0, 10),
    eslemedeTeblig: Object.keys(esleme).filter(t => esleme[t]).length,
    sitedeTeblig: sitede.size,
    kodSayisi: Object.keys(durum).length,
    eksik: eksik.length,
    okunmayiBekleyen: eksik.filter(t => bekleyen[t] && bekleyen[t].tur === 'okunmadi').length,
    kaynagiOlmayan: eksik.filter(t => bekleyen[t] && bekleyen[t].tur === 'kaynak-yok').length,
    gerekcesizEksik: gerekcesiz,
    kaynagiDirilen: dirilen,
    durum: (gerekcesiz.length === 0 && dirilen.length === 0) ? 'TEMIZ' : 'INCELENECEK'
  };
  fs.writeFileSync(path.join(KOK, 'veri/gozetim-nobet-raporu.json'), JSON.stringify(rapor, null, 1));

  console.log('eslemede: ' + rapor.eslemedeTeblig + ' | sitede izlenen: ' + rapor.sitedeTeblig +
    ' | kod: ' + rapor.kodSayisi);
  console.log('eksik: ' + rapor.eksik + ' → okunmayi bekleyen: ' + rapor.okunmayiBekleyen +
    ' | kaynagi olmayan: ' + rapor.kaynagiOlmayan + ' | gerekcesiz: ' + gerekcesiz.length);
  if (gerekcesiz.length) console.log('GEREKCESIZ EKSIK: ' + gerekcesiz.join(' '));
  if (dirilen.length) console.log('KAYNAGI DIRILEN (artik okunabilir): ' + dirilen.join(' '));
  console.log('DURUM: ' + rapor.durum);
  if (rapor.durum !== 'TEMIZ') process.exitCode = 1;
})();
