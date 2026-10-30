// İSRAF KAPISI — `dayanak` alıntısı ambar metnine birebir mi, kesik mi, işaretsiz atlama var mı (0 USD, model yok).
// Neden: KGK t6–t8 son okumasında (r5) çıkarılan 152 sorunun 32'si `dayanak` yüzünden düştü; okuyucu hakkı beş tur boyunca
// zaten düşecek soruya harcandı. Bu kapı yazımın hemen arkasında koşar; KUSUR'lu soru okuyucuya gitmeden yazara döner.
// Kural (BRIF-T6/t6 eki): önekli alıntı TAM cümle; ";" ":" "," üzerinde kesip nokta koyma; atlanan her parça yerine "...";
// kendi notun dayanak'a yazılmaz.
//   node alinti-kapi.js <hazir.json> [<hazir2.json> ...]      → soru başına KUSUR satırları, çıkış kodu = KUSUR'lu soru sayısı (≤ 99)
//   node alinti-kapi.js --sinav                                → öz-sınav (elle kurulmuş vakalar, ağ yok)
// 🚫 GÖRMEZ: aciklama/teshis/sade'deki önekli alıntılar (ön denetim NOT olarak bakar) · alıntının DOĞRU paragrafta olup olmadığı
//   (yalnız kaynak_adlar kayıtlarının birleşiminde arar) · bent alıntısında giriş cümlesinin taşınması · başlık ya da bent
//   işaretinden ("madde 32 -", "4.15", "(1)") sonra başlayan alıntıyı ortadan başlamış saymaz.
const fs = require('fs'), path = require('path'), cp = require('child_process');
const ONB = path.join(__dirname, '..', 'veri', 'fabrika', 'alinti-onbellek.json');   // depoda: önbellek gitignore'daki fabrika'da (30.10 arac/'a taşındı)

function N(s) {
  return String(s || '').normalize('NFC').replace(/­/g, '').replace(/[’‘`´]/g, "'").replace(/["“”«»]/g, '')
    .replace(/[–—−]/g, '-').replace(/…/g, '...').replace(/\s+/g, ' ').toLocaleLowerCase('tr').trim();
}
const NOT_RX = /kökte veri olarak|soruda verilmiştir|kökte verilmiştir/i;
// Harfli bent ("(b) …") BİLEREK yok: r5'i geçmiş 111 t7 sorusunun 30'unda bent giriş cümlesiz alıntılanmış ve okuyucu kabul etmiş
// (yanlış alarm %27); r5'te bentten çıkan 3 soru kaçar — okuyucu turu yakalar.
const ONCULSUZ_RX = /^(bu (durumda|nedenle|çerçevede|kapsamda|tür|itibarla|sebeple)|bununla birlikte|buna (karşılık|göre)|aksi (takdirde|hâlde|halde)|dolayısıyla|sonuç olarak|söz konusu|öte yandan|belirtilen )/;

// Dayanağı parçalara ayırır: her parça {metin, elipsOnce, elipsSonra}. Ayraçlar: "..." (atlama) · kaynak adı + ":" ve " | " (yeni alıntı).
function parcala(dayanak, adlar) {
  let d = String(dayanak || '').replace(/…/g, '...').trim();
  for (const ad of [...adlar].filter(Boolean).sort((a, b) => b.length - a.length)) d = d.split(ad + ':').join(' \u0001 ');
  d = d.replace(/\s+\|\s+/g, ' \u0001 ');
  const out = []; let tamp = '', elOnce = false;
  const toks = d.split(/(\s*(?:\.\s?\.\s?\.|\[\.\.\.\]|\(\.\.\.\))\s*|\s*\u0001\s*)/);
  for (const t of toks) {
    if (/\u0001/.test(t)) { if (tamp.trim()) out.push({ metin: tamp.trim(), elipsOnce: elOnce, elipsSonra: false }); tamp = ''; elOnce = false; }
    else if (/^\s*(\.\s?\.\s?\.|\[\.\.\.\]|\(\.\.\.\))\s*$/.test(t)) { if (tamp.trim()) out.push({ metin: tamp.trim(), elipsOnce: elOnce, elipsSonra: true }); tamp = ''; elOnce = true; }
    else tamp += t;
  }
  if (tamp.trim()) out.push({ metin: tamp.trim(), elipsOnce: elOnce, elipsSonra: false });
  return out;
}

// metinler: kaynak metinleri (ham). Dönüş: kusur cümleleri.
function denetle(dayanak, metinler, adlar = []) {
  const kus = [];
  if (!String(dayanak || '').trim()) return kus;
  const govde = metinler.map(N).join(' \u0000 ');
  for (const p of parcala(dayanak, adlar)) {
    const cumleler = p.metin.split(/(?<=[.!?])\s+(?=\S)/).map(s => s.trim()).filter(Boolean);
    let konum = -1;
    for (let ci = 0; ci < cumleler.length; ci++) {
      const c = cumleler[ci];
      if (NOT_RX.test(c)) { kus.push(`KENDİ NOTU dayanak'ta: "${c.slice(0, 80)}"`); konum = -1; continue; }
      let n = N(c);
      // kısa önek ("TMS 16 p.16, p.17 ve p.19:") kaynakta yoksa soy — yalnız parçanın İLK cümlesinde
      if (ci === 0) for (let t = 0; t < 3 && n && govde.indexOf(n) < 0; t++) { const j = n.indexOf(': '); if (j < 0 || j > 140) break; n = n.slice(j + 2).trim(); }
      if (/:$/.test(n) && ci === cumleler.length - 1 && govde.indexOf(n) < 0) continue;   // yalnız önekten ibaret parça
      if (!n || n.length < 3) continue;
      const i0 = konum >= 0 ? govde.indexOf(n, konum) : govde.indexOf(n);
      if (i0 < 0) {
        const kirp = n.replace(/[.!?]+$/, '');
        const j = kirp !== n ? govde.indexOf(kirp, Math.max(konum, 0)) : -1;
        if (j >= 0) { kus.push(`KESİK ALINTI: "…${c.slice(-60)}" ambarda "${govde.slice(j + kirp.length, j + kirp.length + 30).trim()}…" diye sürüyor — tam cümle ya da "..." koy`); konum = j + kirp.length; continue; }
        kus.push(`AMBARDA BİREBİR YOK: "${c.slice(0, 90)}${c.length > 90 ? '…' : ''}"`); konum = -1; continue;
      }
      // ÖNCÜLSÜZ: alıntının ilk cümlesi önceki cümleye bağlanan sözcükle ya da harfli bentle başlıyor, giriş cümlesi alıntıda yok
      // (t6–t8 r5'te 14 soru yalnız bundan çıktı: "Bu durumda", "Aksi takdirde", "Dolayısıyla", "(d) …", "g) …").
      if (konum < 0 && ONCULSUZ_RX.test(n)) kus.push(`ÖNCÜLSÜZ ALINTI: "${c.slice(0, 60)}" önceki cümleye/giriş cümlesine bağlı — o cümleyi de alıntıya al`);
      if (konum >= 0) {
        const ara = govde.slice(konum, i0).trim();
        if (ara) kus.push(`İŞARETSİZ ATLAMA: "${c.slice(0, 60)}" öncesinde ambarda ${ara.length} kr atlanmış ("${ara.slice(0, 40)}…") — araya "..." koy`);
      } else if (!p.elipsOnce) {
        const once = govde.slice(Math.max(0, i0 - 40), i0).replace(/\s+$/, '');
        if (/[a-zçğıöşüâîû,]$/.test(once)) kus.push(`ORTADAN BAŞLIYOR: "${c.slice(0, 60)}" ambarda cümle ortası ("…${once.slice(-35)}") — baştan al ya da önüne "..." koy`);
      }
      konum = i0 + n.length;
      if (ci === cumleler.length - 1 && !p.elipsSonra && !/[.!?)]$/.test(n)) {
        const sonra = govde.slice(konum, konum + 25).trim();
        if (sonra && !/^[.!?\u0000]/.test(sonra)) kus.push(`KESİK ALINTI: "…${c.slice(-50)}" ambarda "${sonra}…" diye sürüyor — "..." koy`);
      }
    }
  }
  return [...new Set(kus)];
}

function anahtar() {
  let K = (process.env.SUPABASE_SERVICE_KEY || '').trim();
  if (!K) K = (cp.spawnSync('powershell', ['-NoProfile', '-Command', "[Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User')"], { encoding: 'utf8' }).stdout || '').trim();
  if (!K) { console.error('SUPABASE_SERVICE_KEY yok'); process.exit(120); } return K;
}
async function metinGetir(adlar) {
  const onb = fs.existsSync(ONB) ? JSON.parse(fs.readFileSync(ONB, 'utf8')) : {};
  const eksik = [...new Set(adlar)].filter(a => !(a in onb));
  if (eksik.length) {
    const K = anahtar(), H = { apikey: K, Authorization: 'Bearer ' + K, 'User-Agent': 'mevzuat-radar-robot/1.0' };
    const B = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar?select=kaynak_ad,metin&kaynak_ad=eq.';
    for (let i = 0; i < eksik.length; i += 6) {
      await Promise.all(eksik.slice(i, i + 6).map(async a => {
        for (let t = 1; ; t++) {
          try { const r = await fetch(B + encodeURIComponent(a), { headers: H, signal: AbortSignal.timeout(45000) }); const j = await r.json(); if (!Array.isArray(j)) throw new Error(JSON.stringify(j).slice(0, 120)); onb[a] = j.map(x => x.metin).join('\n'); return; }
          catch (e) { if (t >= 4) { console.error(`AMBAR OKUNAMADI (${a}): ${e.message} — KAPI KOŞMADI`); process.exit(121); } await new Promise(z => setTimeout(z, 2500 * t)); }
        }
      }));
    }
    fs.writeFileSync(ONB, JSON.stringify(onb));
  }
  return onb;
}

async function main(dosyalar) {
  let kusurlu = 0, toplam = 0;
  for (const f of dosyalar) {
    const A = JSON.parse(fs.readFileSync(f, 'utf8').replace(/^﻿/, ''));
    const onb = await metinGetir(A.flatMap(q => q.kaynak_adlar || []));
    A.forEach((q, i) => {
      toplam++;
      const adlar = q.kaynak_adlar || [];
      const yok = adlar.filter(a => !onb[a]);
      const k = denetle(q.dayanak, adlar.map(a => onb[a]).filter(Boolean), adlar);
      if (yok.length) k.push(`kaynak_adlar ambarda yok: ${yok.join(' · ')}`);
      if (k.length) { kusurlu++; console.log(`KUSUR ${path.basename(f)}[${i}] ${q.konu}`); k.forEach(x => console.log('   ' + x)); }
    });
  }
  console.log(`ALINTI KAPISI: ${toplam} soru · KUSUR'lu ${kusurlu}`);
  process.exit(Math.min(kusurlu, 99));
}

function ozSinav() {
  const M = ['Maliyet unsurları madde 16 - (1) Maddi duran varlığın maliyeti, indirimler ve ticari iskontolar düşüldükten sonraki satın alma fiyatıdır. İkinci cümle burada; ve devam eder. Üçüncü cümle biter.',
             'Tipik tuzaklar: D0 ile D1\'i karistirmak (formul GELECEK yilin temettusunu ister) ve g\'nin temettu degil KAR buyumesi sanilmasi.'];
  const AD = ['TMS 16 p.16 - Maliyet', 'Finansal Kiralama K. (6361 s.K.) m.32'];
  const V = [
    ['tam alıntı', 'TMS 16 p.16: Maddi duran varlığın maliyeti, indirimler ve ticari iskontolar düşüldükten sonraki satın alma fiyatıdır.', 0],
    ['bent işaretinden başlıyor', 'TMS 16 p.16 - Maliyet: (1) Maddi duran varlığın maliyeti, indirimler ve ticari iskontolar düşüldükten sonraki satın alma fiyatıdır.', 0],
    ['noktalı adlı önek', 'Finansal Kiralama K. (6361 s.K.) m.32: Üçüncü cümle biter.', 0],
    ['elipsli atlama', 'TMS 16 p.16: Maddi duran varlığın maliyeti, indirimler ve ticari iskontolar düşüldükten sonraki satın alma fiyatıdır. ... Üçüncü cümle biter.', 0],
    ['işaretsiz atlama', 'TMS 16 p.16: Maddi duran varlığın maliyeti, indirimler ve ticari iskontolar düşüldükten sonraki satın alma fiyatıdır. Üçüncü cümle biter.', 1],
    ['noktalı kesik', 'Teori Notu - x: Tipik tuzaklar: D0 ile D1\'i karistirmak (formul GELECEK yilin temettusunu ister).', 1],
    ['noktasız kesik elipssiz', 'TMS 16 p.16: İkinci cümle burada', 1],
    ['noktasız kesik elipsli', 'TMS 16 p.16: İkinci cümle burada ...', 0],
    ['ortadan başlıyor', 'TMS 16 p.16: indirimler ve ticari iskontolar düşüldükten sonraki satın alma fiyatıdır.', 1],
    ['elipsle ortadan', 'TMS 16 p.16: ... indirimler ve ticari iskontolar düşüldükten sonraki satın alma fiyatıdır.', 0],
    ['kendi notu', 'TMS 16 p.16: Üçüncü cümle biter. Oran kökte veri olarak verilmiştir.', 1],
    ['uydurma', 'TMS 16 p.16: Maliyet her zaman fatura bedelidir.', 1],
    ['iki önek | ile', 'TMS 16 p.16: Üçüncü cümle biter. | Teori Notu - x: Tipik tuzaklar: D0 ile D1\'i karistirmak (formul GELECEK yilin temettusunu ister) ve g\'nin temettu degil KAR buyumesi sanilmasi.', 0],
    ['boş', '', 0],
    ['öncülsüz bağlaç', 'TMS 16 p.16: ... Bu durumda maliyet artar.', 1],
    ['fıkra numarası öncülsüz değil', 'TMS 16 p.16 - Maliyet: (1) Maddi duran varlığın maliyeti, indirimler ve ticari iskontolar düşüldükten sonraki satın alma fiyatıdır.', 0],
  ];
  let h = 0; for (const [ad, d, bek] of V) { const k = denetle(d, M, AD); if ((k.length > 0 ? 1 : 0) !== bek) { h++; console.log(`  DÜŞTÜ: ${ad} → ${k.length} kusur (beklenen ${bek ? 'KUSUR' : 'temiz'}) ${k.join(' | ')}`); } }
  console.log(h ? `ALINTI KAPISI ÖZ-SINAV KIRMIZI: ${h}/${V.length}` : `ALINTI KAPISI ÖZ-SINAV YEŞİL: ${V.length}/${V.length}`); process.exit(h ? 1 : 0);
}

module.exports = { denetle, N, metinGetir, parcala };
if (require.main === module) { const a = process.argv.slice(2); if (a[0] === '--sinav') ozSinav(); else if (a.length) main(a); else { console.log('kullanım: node alinti-kapi.js <hazir.json> ... | --sinav'); process.exit(2); } }
