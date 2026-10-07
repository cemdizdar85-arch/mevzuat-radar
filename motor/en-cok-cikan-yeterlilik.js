#!/usr/bin/env node
/* ============================================================================
 *  YETERLİLİK: EN SIK SORULAN KONULAR SAYFASI (04.10.2026, Cem "2 yapalım")
 *  TEK KAYNAK: veri/sinav/smmm-konu-okuma.json (arac/smmm-konu-okuma.js — her dersin 31 dönemi tek okuyucuyla OKUNDU).
 *  Yeterlilikte her ders ayrı sınav → liste DERS DERS: her dersin en sık sorulan 5 konusu, kaç dönemde sorulduğu, kanıt
 *  (dönem + soru no). Kural: CLAUDE.md "DIŞARI ÇIKAN SINAV RAKAMI ÖNCE SORU METNİYLE DOĞRULANIR".
 *  🚫 GÖRMEZ: okuyucunun konu genişliği seçimi (dersler arası eşit değil; sayfada yazılı) · ambarda olmayan dönem (2020/3).
 *  Kullanım: node motor/en-cok-cikan-yeterlilik.js [--kuru]
 * ==========================================================================*/
'use strict';
const fs = require('fs'), path = require('path');
const KOK = path.join(__dirname, '..');
const KURU = process.argv.includes('--kuru');
const ADET = 5;
const esc = s => String(s == null ? '' : s).replace(/[&<>"]/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
const ok = JSON.parse(fs.readFileSync(path.join(KOK, 'veri', 'sinav', 'smmm-konu-okuma.json'), 'utf8'));

// 07.10: Sık Çıkan Konular Denemesi düğmesi - biçim (soru/süre) set dizininden, tek kaynak (motor/sik-konu-deneme-bas.js)
const SIK_KURAL = (() => { try { const d = JSON.parse(fs.readFileSync(path.join(KOK, 'veri', 'deneme', 'smmm-sik-dizin.json'), 'utf8')); return d.kural.slice(0, 2).map(esc).join(' · ') + ' · konu konu karne'; } catch (e) { console.error('KIRMIZI: veri/deneme/smmm-sik-dizin.json okunamadı (önce node motor/sik-konu-deneme-bas.js)'); process.exit(4); } })();
const DONEM = ok.donem, PENCERE = ok.pencere;
const dizin = JSON.parse(fs.readFileSync(path.join(KOK, 'veri', 'soru-dizini.json'), 'utf8')).sinavlar.find(x => x.kod === 'smmm');
const dersSira = dizin.dersler.map(d => d.ad), dersSayfa = {}; dizin.dersler.forEach(d => { dersSayfa[d.ad] = d.sayfa; });
const srt = d => { const [y, n] = d.split('/'); return +y * 10 + +n; };
const gorunen = k => k.replace(/ › /g, ' — ');   // "GVK › Ücret gelirleri" → "GVK — Ücret gelirleri" (konu adında ":" zaten var)

const D = {};
for (const x of ok.kararlar) {
  const r = ((D[x.ders] = D[x.ders] || {})[x.konu] = D[x.ders][x.konu] || { konu: x.konu, kanit: [] });
  if (!r.kanit.some(z => z.donem === x.donem && z.soru === x.soru)) r.kanit.push({ donem: x.donem, soru: x.soru });
}
const eksik = Object.keys(D).filter(d => !dersSayfa[d]);
if (eksik.length) { console.error('KIRMIZI: ders sayfası yok: ' + eksik.join(', ')); process.exit(3); }
const dersTop = {};
for (const d of dersSira) {
  dersTop[d] = Object.values(D[d] || {}).map(r => {
    const don = [...new Set(r.kanit.map(z => z.donem))].sort((p, q) => srt(p) - srt(q));
    r.kanit.sort((p, q) => srt(p.donem) - srt(q.donem) || String(p.soru).localeCompare(String(q.soru), 'tr', { numeric: true }));
    return { ...r, don: don.length, soru: r.kanit.length, son: don[don.length - 1] };
  }).sort((p, q) => q.don - p.don || q.soru - p.soru || srt(q.son) - srt(p.son)).slice(0, ADET);
}
const tarih = ok.olcum.split('-').reverse().join('.');
const bolum = dersSira.map(d => `  <h2 id="${esc(dersSayfa[d].replace(/^.*\/|\.html$/g, ''))}">${esc(d)}</h2>
  <ol class="ek-liste">
${dersTop[d].map((x, i) => `<li class="ek-satir"><span class="ek-no">${i + 1}</span><div class="ek-govde"><h3 class="ek-ad">${esc(gorunen(x.konu))}</h3><p class="ek-alt">sorulduğu dönem: <b>${x.don} / ${DONEM}</b> · en son <b>${esc(x.son)}</b></p><details class="ek-kanit"><summary>Kanıt: hangi sınav, kaçıncı soru</summary><p>${esc(x.kanit.map(z => z.donem + ' s.' + z.soru).join(' · '))}</p></details></div><span class="ek-cubuk" aria-hidden="true"><i style="width:${Math.round(100 * x.don / DONEM)}%"></i></span></li>`).join('\n')}
  </ol>
  <p class="ders-git"><a href="${esc(dersSayfa[d])}">${esc(d)} sorularını çöz →</a></p>`).join('\n');
const ilk = dersSira.map(d => ({ d, x: dersTop[d][0] })).filter(z => z.x).sort((p, q) => q.x.don - p.x.don)[0];

const SSS = [
  ['SMMM Yeterlilik sınavında en çok hangi konular çıkıyor?', `Yeterlilikte her ders ayrı sınavdır; bu yüzden liste ders ders verildi. ${PENCERE} arasındaki ${DONEM} dönemde en düzenli sorulan konulardan biri ${ilk.d} dersinde "${gorunen(ilk.x.konu)}" (${ilk.x.don} dönem). Her konunun altında çıktığı sınav ve soru numarası yazıyor.`],
  ['Bu sayılar nasıl hesaplandı?', `Her dersin ${DONEM} dönemlik çıkmış sorusu baştan sona tek bir okuyucu tarafından okundu ve her soru (çok parçalıysa her alt soru) ölçtüğü konuya bağlandı. Aynı konu her dönemde aynı adla işaretlendi. Sayı, o konudan kaç ayrı sınav döneminde soru geldiğidir.`],
  ['2026 test formatı bu listeyi değiştiriyor mu?', '2026/1 ve 2026/2 dönemleri çoktan seçmeli test olarak yapıldı ve sayıma dahil. Test formatında bir derste 20 soru olduğu için konu yelpazesi klasik sınava göre geniş; eski dönemlerde sık sorulan konular yine en güvenli başlangıç noktasıdır.'],
  ['Listede olmayan konulara çalışmalı mıyım?', 'Evet. Liste "nereden başlamalı" sorusunun cevabıdır, sınırı değildir.'],
];

const html = `<!doctype html>
<html lang="tr">
<head>
<meta charset="utf-8">
<script src="tema-bas.js"></script>
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>SMMM Yeterlilik: Ders Ders En Sık Sorulan Konular (kanıtlı) | Tetikte</title>
<meta name="description" content="SMMM Yeterlilik (bitirme) sınavında ${PENCERE} arası ${DONEM} dönemde her dersin en sık sorulan ${ADET} konusu. Çıkmış sorular okunarak sayıldı; her konunun altında sınav ve soru numarası.">
<link rel="canonical" href="https://tetikte.com/en-cok-cikan-konular-yeterlilik.html">
<meta property="og:title" content="SMMM Yeterlilik: ders ders en sık sorulan konular (kanıtlı)">
<meta property="og:description" content="Çıkmış sorular okunarak sayıldı; her rakamın yanında sınav ve soru numarası.">
<meta property="og:url" content="https://tetikte.com/en-cok-cikan-konular-yeterlilik.html">
<meta property="og:type" content="article">
<link rel="icon" type="image/svg+xml" href="favicon.svg">
<link rel="stylesheet" href="stil.css">
<!-- ÜRETİLEN SAYFA: motor/en-cok-cikan-yeterlilik.js ← veri/sinav/smmm-konu-okuma.json (elle düzenlenmez). Ölçüm: ${tarih} -->
<script type="application/ld+json">${JSON.stringify({ '@context': 'https://schema.org', '@type': 'FAQPage', mainEntity: SSS.map(([q, a]) => ({ '@type': 'Question', name: q, acceptedAnswer: { '@type': 'Answer', text: a } })) })}</script>
<style>
*{box-sizing:border-box}
body{margin:0;background:var(--bg);color:var(--ink);font-family:-apple-system,"Segoe UI",system-ui,Roboto,Arial,sans-serif;line-height:1.55}
a{color:var(--link)}
.wrap{max-width:860px;margin:0 auto;padding:24px 18px 90px}
.top{font-size:13px;color:var(--dim);margin-bottom:14px}
h1{font-size:clamp(25px,4.4vw,34px);letter-spacing:-.6px;margin:6px 0 8px;line-height:1.2}
.alt{color:var(--muted);font-size:16px;margin:0 0 18px}
.yontem{font-size:13.5px;color:var(--muted);background:var(--kagit);border:1px solid var(--line);border-radius:12px;padding:12px 14px;margin:0 0 22px}
.icindekiler{font-size:14px;margin:0 0 8px;line-height:1.9}
h2{font-size:19px;margin:30px 0 12px}
.ek-liste{list-style:none;margin:0;padding:0;display:grid;gap:8px}
.ek-satir{display:grid;grid-template-columns:34px 1fr 120px;gap:12px;align-items:center;background:var(--kagit);border:1px solid var(--line);border-radius:12px;padding:12px 14px}
.ek-no{font-weight:800;font-size:18px;color:var(--amber);text-align:center}
.ek-ad{margin:0;font-size:16px;line-height:1.3}
.ek-alt{margin:2px 0 0;font-size:13px;color:var(--muted)}
.ek-kanit{margin-top:4px;font-size:12.5px;color:var(--muted)}
.ek-kanit summary{cursor:pointer;color:var(--link)}
.ek-kanit p{margin:4px 0 0;line-height:1.5}
.ek-cubuk{height:8px;border-radius:99px;background:var(--line);overflow:hidden}
.ek-cubuk i{display:block;height:100%;background:var(--amber-dolgu);border-radius:99px}
.ders-git{margin:8px 0 0;font-weight:700;font-size:14px}
@media(max-width:640px){.ek-satir{grid-template-columns:28px 1fr;}.ek-cubuk{grid-column:2}}
.sik-deneme{display:flex;gap:14px;align-items:center;justify-content:space-between;flex-wrap:wrap;border:1px solid var(--line2);border-left:4px solid var(--amber);border-radius:14px;background:var(--kagit);padding:14px 16px;margin:0 0 20px}
.sik-deneme b{display:block;font-size:16px;color:var(--ink)}
.sik-deneme span{font-size:13.5px;color:var(--muted)}
.sik-deneme a{font-weight:700;text-decoration:none;white-space:nowrap}
.kapi{display:grid;grid-template-columns:1fr 1fr;gap:12px;margin:8px 0 0}
.kapi a{display:block;background:var(--kagit);border:1px solid var(--line2);border-radius:14px;padding:16px;text-decoration:none;color:var(--ink)}
.kapi a b{display:block;font-size:16px;margin-bottom:4px}
.kapi a span{font-size:13.5px;color:var(--muted)}
@media(max-width:640px){.kapi{grid-template-columns:1fr}}
.sss h3{font-size:16px;margin:16px 0 4px}.sss p{margin:0;color:var(--muted)}
</style>
</head>
<body>
<div class="wrap">
  <div class="top"><a href="index.html">Tetikte</a> · <a href="sorular.html">Sınavlar</a> · Yeterlilik: en sık sorulan konular</div>
  <main>
  <h1>SMMM Yeterlilik: ders ders en sık sorulan konular</h1>
  <p class="alt">${PENCERE} arasındaki ${DONEM} sınav döneminin çıkmış sorularını <b>tek tek okuyarak</b> saydık. Yeterlilikte her ders ayrı sınav olduğu için liste ders ders; her konunun altında hangi sınavda kaçıncı soru olarak çıktığı yazıyor.</p>

  <!-- 07.10 Sık Çıkan Konular Denemesi (Cem "ücretli olsun, üstte görünsün"): liste ücretsiz, deneme paketli. Biçim set dizininden. -->
  <div class="sik-deneme"><div><b>🔒 Bu konulardan deneme çöz</b><span>Pakete dahil · ${SIK_KURAL}</span></div><a href="sinav-gibi.html?tur=sik&amp;sinav=smmm">Denemeyi aç →</a></div>
  <p class="yontem"><b>Yöntem:</b> her dersin ${DONEM} dönemlik sorusunu tek bir okuyucu baştan sona okudu; çok parçalı sorularda her alt soru ölçtüğü konuya bağlandı ve aynı konu her dönemde aynı adla işaretlendi. Sayı, o konudan <b>kaç ayrı sınav döneminde</b> soru geldiğidir. Kaynak: TÜRMOB-TESMER'in yayımladığı klasik sınav soru ve komisyon cevapları (2016/1–2025/3) ile 2026 test kitapçıkları; 2020/3 dönemi elimizde olmadığı için sayılmadı. Konu genişliği derse göre değişir (ör. Hukuk'ta kanun alanı + konu). Ölçüm: ${tarih}.</p>
  <p class="icindekiler">${dersSira.map(d => `<a href="#${esc(dersSayfa[d].replace(/^.*\/|\.html$/g, ''))}">${esc(d)}</a>`).join(' · ')}</p>
${bolum}

  <h2>Bu konularda nerede olduğunu gör</h2>
  <div class="kapi">
    <a href="seviye-testi.html"><b>30 soruda seviyeni ölç</b><span>Ücretsiz. Bitince geçme ihtimalini ve en zayıf alanını görürsün.</span></a>
    <a href="index.html?sinav=yeterlilik#ekran"><b>Günün sorusunu çöz</b><span>Her şıkkın neden doğru ya da yanlış olduğu, dayandığı maddeyle.</span></a>
  </div>

  <section class="sss">
  <h2>Sık sorulanlar</h2>
${SSS.map(([q, a]) => `  <h3>${esc(q)}</h3>\n  <p>${esc(a)}</p>`).join('\n')}
  </section>
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
if (KURU) { for (const d of dersSira) { console.log('— ' + d); dersTop[d].forEach((x, i) => console.log('  ' + (i + 1) + '. ' + gorunen(x.konu) + ' ' + x.don + '/' + DONEM + ' son ' + x.son)); } process.exit(0); }
fs.writeFileSync(path.join(KOK, 'en-cok-cikan-konular-yeterlilik.html'), html, 'utf8');
console.log('en-cok-cikan-konular-yeterlilik.html: ' + dersSira.length + ' ders × ' + ADET + ' konu (kaynak veri/sinav/smmm-konu-okuma.json)');
