#!/usr/bin/env node
/* ============================================================================
 *  SINAV NÖBETİ — SMMM adayını ilgilendiren resmî duyurular, kaynağıyla (05.10.2026, Cem "Sınav Nöbeti haber hattını kuralım")
 *  NEDEN: Fuat Hoca'nın en çok izlenen 4 reels'inin 3'ü HABER (26.09 ölçümü: "2026'da bitirme test" 374B). Haberi insan
 *  elle takip ediyor; bizde robot var. Bu betik TESMER (WordPress REST) + TÜRMOB (Haberler sayfası) duyurularını okur,
 *  sınavla ilgili olanları süzer, birikimli kayda yazar ve sitede kaynaklı listeyi basar.
 *  ⛔ Yalnız RESMÎ BAŞLIK + TARİH + LİNK. Özet/yorum YAZILMAZ (okunmamış duyuruya yorum = "önce resmî kaynak, sonra yaz" ihlali).
 *  ÇIKTI: veri/sinav-nobeti.json (birikimli; robot çıktısı, elle düzenlenmez) + sinav-nobeti.html
 *  🚫 GÖRMEZ: başlığında sınav kelimesi olmayan ama sınavı etkileyen duyuru · Resmî Gazete (kanun nöbetçisi ayrı) ·
 *     GİB/KGK (KGK bağlantılarında başlık yok) · TESMER REST'in son 50 kaydı dışındaki geçmiş.
 *  Kullanım: node motor/sinav-nobeti.js [--kuru]
 * ==========================================================================*/
'use strict';
const fs = require('fs'), path = require('path');
const KOK = path.join(__dirname, '..');
const KURU = process.argv.includes('--kuru');
const KAYIT = path.join(KOK, 'veri', 'sinav-nobeti.json');
const UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) tetikte-sinav-nobeti/1.0';
const esc = s => String(s == null ? '' : s).replace(/[&<>"]/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
const decode = s => String(s).replace(/&#(\d+);/g, (m, d) => String.fromCharCode(+d)).replace(/&#x([0-9a-f]+);/gi, (m, h) => String.fromCharCode(parseInt(h, 16)))
  .replace(/&amp;/g, '&').replace(/&quot;/g, '"').replace(/&#39;|&apos;/g, "'").replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&nbsp;/g, ' ').trim();
// motor/duyuru-nobetcisi.ps1 SinavMi ile AYNI kural (iki yerde: biri mail, biri sayfa) — değişirse ikisi birlikte
function sinavMi(metin) {
  if (/(webinar|\bCIA\b)/i.test(metin)) return false;
  return /(s[ıiIİ]nav|SGS|staj|SMMM|YMM|yeterlilik|ba[ğg][ıiIİ]ms[ıiIİ]z denet|ba[şs]vuru|sonu[çc]lar|itiraz|takvim|hesap makin)/i.test(metin);
}
const isoTr = s => { const m = String(s).match(/^(\d{2})\.(\d{2})\.(\d{4})$/); return m ? `${m[3]}-${m[2]}-${m[1]}` : String(s).slice(0, 10); };
const trTarih = iso => { const [y, a, g] = iso.split('-'); return `${g}.${a}.${y}`; };

async function tesmer() {
  const r = await fetch('https://www.tesmer.org.tr/?rest_route=/wp/v2/posts&per_page=50&_fields=title,link,date', { headers: { 'User-Agent': UA } });
  if (!r.ok) throw new Error('TESMER ' + r.status);
  return (await r.json()).map(p => ({ kurum: 'TESMER', url: p.link, baslik: decode(p.title.rendered), tarih: String(p.date).slice(0, 10) }));
}
async function turmob() {
  const r = await fetch('https://www.turmob.org.tr/Haberler', { headers: { 'User-Agent': UA } });
  if (!r.ok) throw new Error('TÜRMOB ' + r.status);
  const h = await r.text(), out = [];
  const re = /href="?(\/haberler\/[0-9a-f-]{36}\/[^"\s>]*)"?\s*>\s*<p[^>]*>[\s\S]*?(\d{2}\.\d{2}\.\d{4})\s*<\/p>\s*<span>([\s\S]*?)<\/span>/g;
  let m; while ((m = re.exec(h))) out.push({ kurum: 'TÜRMOB', url: 'https://www.turmob.org.tr' + m[1], baslik: decode(m[3]), tarih: isoTr(m[2]) });
  return out;
}

(async () => {
  const kayit = fs.existsSync(KAYIT) ? JSON.parse(fs.readFileSync(KAYIT, 'utf8')) : { aciklama: '', duyurular: [] };
  const durum = [];
  let gelen = [];
  for (const [ad, f] of [['TESMER', tesmer], ['TÜRMOB', turmob]]) {
    try { const l = await f(); durum.push({ kurum: ad, okunan: l.length, durum: l.length ? 'YESIL' : 'KIRMIZI' }); gelen = gelen.concat(l); }
    catch (e) { durum.push({ kurum: ad, okunan: 0, durum: 'KIRMIZI', hata: e.message }); }
  }
  const var_ = new Set(kayit.duyurular.map(d => d.url));
  const yeni = gelen.filter(d => sinavMi(d.baslik) && !var_.has(d.url));
  const tum = kayit.duyurular.concat(yeni.map(d => ({ ...d, gorulme: new Date().toISOString().slice(0, 10) })))
    .sort((p, q) => q.tarih.localeCompare(p.tarih) || p.baslik.localeCompare(q.baslik, 'tr'));
  durum.forEach(d => console.log(`${d.kurum.padEnd(7)} ${d.durum} okunan ${d.okunan}${d.hata ? ' HATA ' + d.hata : ''}`));
  console.log(`sınav duyurusu: yeni ${yeni.length} · toplam ${tum.length}`);
  if (durum.every(d => d.durum === 'KIRMIZI')) { console.error('KIRMIZI: hiçbir kaynak okunamadı — sayfa ve kayıt değiştirilmedi'); process.exitCode = 3; return; }
  if (KURU) { tum.slice(0, 12).forEach(d => console.log(' ', d.tarih, d.kurum, d.baslik)); return; }
  const icerik = { aciklama: 'Sınav Nöbeti: TESMER + TÜRMOB duyurularından SMMM sınavıyla ilgili olanlar (yalnız resmî başlık + tarih + link). Üreten motor/sinav-nobeti.js; elle düzenlenmez.', duyurular: tum };
  const eskiMetin = fs.existsSync(KAYIT) ? fs.readFileSync(KAYIT, 'utf8') : '';
  const yeniMetin = JSON.stringify(icerik, null, 1);
  if (eskiMetin !== yeniMetin) fs.writeFileSync(KAYIT, yeniMetin);   // değişmediyse dokunma (boş commit olmasın)

  const satir = tum.slice(0, 60).map(d => `<li class="sn-satir"><div class="sn-ust"><span class="sn-kurum">${esc(d.kurum)}</span><time datetime="${esc(d.tarih)}">${esc(trTarih(d.tarih))}</time></div><a class="sn-baslik" href="${esc(d.url)}" rel="noopener" target="_blank">${esc(d.baslik)}</a><span class="sn-kaynak">Kaynak: ${esc(new URL(d.url).hostname.replace(/^www\./, ''))} →</span></li>`).join('\n');
  const html = `<!doctype html>
<html lang="tr">
<head>
<meta charset="utf-8">
<script src="tema-bas.js"></script>
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Sınav Nöbeti: SMMM Sınav Duyuruları (TESMER, TÜRMOB) | Tetikte</title>
<meta name="description" content="SMMM Staja Giriş ve Yeterlilik sınavlarıyla ilgili TESMER ve TÜRMOB duyuruları tek listede: başvuru, sonuç, itiraz, takvim. Her satır resmî duyurunun kendisine bağlanır.">
<link rel="canonical" href="https://tetikte.com/sinav-nobeti.html">
<link rel="icon" type="image/svg+xml" href="favicon.svg">
<link rel="stylesheet" href="stil.css">
<!-- ÜRETİLEN SAYFA: motor/sinav-nobeti.js (elle düzenlenmez) -->
<style>
*{box-sizing:border-box}
body{margin:0;background:var(--bg);color:var(--ink);font-family:-apple-system,"Segoe UI",system-ui,Roboto,Arial,sans-serif;line-height:1.55}
a{color:var(--link)}
.wrap{max-width:820px;margin:0 auto;padding:24px 18px 90px}
.top{font-size:13px;color:var(--dim);margin-bottom:14px}
h1{font-size:clamp(25px,4.4vw,34px);letter-spacing:-.6px;margin:6px 0 8px;line-height:1.2}
.alt{color:var(--muted);font-size:16px;margin:0 0 18px}
.yontem{font-size:13.5px;color:var(--muted);background:var(--kagit);border:1px solid var(--line);border-radius:12px;padding:12px 14px;margin:0 0 22px}
.sn-liste{list-style:none;margin:0;padding:0;display:grid;gap:8px}
.sn-satir{background:var(--kagit);border:1px solid var(--line);border-radius:12px;padding:12px 14px;display:grid;gap:4px}
.sn-ust{display:flex;gap:10px;align-items:center;font-size:12.5px;color:var(--muted)}
.sn-kurum{font-weight:800;color:var(--amber);letter-spacing:.5px}
.sn-baslik{font-size:16px;font-weight:700;line-height:1.35;color:var(--ink);text-decoration:none;overflow-wrap:anywhere}
.sn-baslik:hover{text-decoration:underline}
.sn-kaynak{font-size:12.5px;color:var(--dim)}
</style>
</head>
<body>
<div class="wrap">
  <div class="top"><a href="index.html">Tetikte</a> · <a href="sorular.html">Sınavlar</a> · Sınav Nöbeti</div>
  <main>
  <h1>Sınav Nöbeti: SMMM sınav duyuruları</h1>
  <p class="alt">Staja Giriş ve Yeterlilik sınavlarıyla ilgili TESMER ve TÜRMOB duyuruları tek listede. Her satır, duyurunun resmî sayfasına gider.</p>
  <p class="yontem"><b>Nasıl çalışır:</b> robotumuz TESMER ve TÜRMOB duyuru sayfalarını gün içinde birkaç kez okur; başlığı sınavla ilgili olanları buraya ekler. Burada yalnız resmî başlık ve tarih durur; ayrıntı ve bağlayıcı metin her zaman kurumun kendi sayfasındadır.</p>
  <ol class="sn-liste">
${satir}
  </ol>
  </main>
</div>
<script src="menu.js" defer></script>
<link rel="stylesheet" href="komut.css">
<script src="komut.js" defer></script>
<link rel="stylesheet" href="stil-acik.css">
<script data-goatcounter="https://mevzuatradar.goatcounter.com/count" async src="//gc.zgo.at/count.js"></script>
</body>
</html>
`;
  const hedef = path.join(KOK, 'sinav-nobeti.html');
  const eskiH = fs.existsSync(hedef) ? fs.readFileSync(hedef, 'utf8') : '';
  if (eskiH !== html) fs.writeFileSync(hedef, html);
  console.log('sinav-nobeti.html: ' + Math.min(60, tum.length) + ' satır' + (eskiH === html ? ' (değişmedi)' : ''));
})().catch(e => { console.error('HATA ' + e.message); process.exitCode = 1; });
