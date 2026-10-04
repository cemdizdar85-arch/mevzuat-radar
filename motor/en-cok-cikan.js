#!/usr/bin/env node
/* ============================================================================
 *  EN ÇOK ÇIKAN KONULAR SAYFASI (04.10.2026, Cem: "en çok çıkan konulardan ... bizi tanıtacak, rakiplerden öne geçirecek")
 *
 *  ⛔ 04.10 YENİDEN YAZILDI — Cem: "sınav konuları önemli, doğru bilgi verelim, yanlış olmasın". İlk sürüm konu ETİKETİ sayımıyla
 *  (veri/fabrika/sgs-konu-kapsama.json) basılmıştı; etiketler parçalıydı, rakamlar düşüktü (muhasebe bilgi sistemi 16 → okunarak 28).
 *  Sayfa yayından çekildi. Artık TEK KAYNAK: veri/sinav/sgs-konu-okuma.json (arac/sgs-konu-okuma.js — her aday çıkmış soru
 *  tek tek OKUNDU, e=1 olanlar sayılır). Her satırın altında kanıt: dönem + A kitapçığı soru no. Kural: CLAUDE.md
 *  "DIŞARI ÇIKAN SINAV RAKAMI ÖNCE SORU METNİYLE DOĞRULANIR".
 *
 *  NE YAPAR: düz HTML basar (arama motoru listeyi okusun). Soru AÇMAZ; seviye testine, örnek sorulara, ders sayfasına yönlendirir.
 *  ÖLÇÜ: "kaç sınav döneminde soruldu" (32 dönem, 2016/1–2026/2). Sayı ALT SINIRDIR (aday ifadesi geçmeyen soru sayılmadı).
 *  🚫 GÖRMEZ: 82 aday konu dışındaki konular (sayfada yazılı) · Matematik (formül OCR'ı bozuk, sayı eksik → listeye alınmaz) ·
 *     konu genişliği eşit değil ("kıymetli evrak" geniş, "Lozan" dar) · okuyucunun sınırda kararı.
 *  Kullanım: node motor/en-cok-cikan.js sgs [--kuru]
 * ==========================================================================*/
'use strict';
const fs = require('fs'), path = require('path');
const KOK = path.join(__dirname, '..');
const SINAV = process.argv[2] || 'sgs';
const KURU = process.argv.includes('--kuru');
const ADET = 20;
if (SINAV !== 'sgs') { console.error('şimdilik yalnız sgs (Yeterlilik okunarak sayılmadı)'); process.exit(2); }

const esc = s => String(s == null ? '' : s).replace(/[&<>"]/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
const ok = JSON.parse(fs.readFileSync(path.join(KOK, 'veri', 'sinav', 'sgs-konu-okuma.json'), 'utf8'));
const DONEM = ok.donem, PENCERE = ok.pencere;
// okuma dosyasındaki kısa ders adı → sitedeki ders adı
const DERS = { 'Muhasebe': 'Finansal Muhasebe', 'İktisat': 'Ekonomi', 'Atatürk İlkeleri': 'Atatürk İlkeleri ve İnkılap Tarihi' };
const dersAd = d => DERS[d] || d;
const dizin = JSON.parse(fs.readFileSync(path.join(KOK, 'veri', 'soru-dizini.json'), 'utf8')).sinavlar.find(x => x.kod === 'sgs');
const dersSayfa = {}, dersSoru = {}; dizin.dersler.forEach(d => { dersSayfa[d.ad] = d.sayfa; dersSoru[d.ad] = d.sinav_soru; });

const srt = d => { const [y, n] = d.split('/'); return +y * 10 + +n; };
const K = {};
for (const x of ok.kararlar) { if (!x.e) continue; const r = K[x.konu] = K[x.konu] || { ders: dersAd(x.ders), konu: x.konu, kanit: [] }; r.kanit.push(x); }
const hepsi = Object.values(K).map(r => {
  const don = [...new Set(r.kanit.map(z => z.donem))].sort((p, q) => srt(p) - srt(q));
  r.kanit.sort((p, q) => srt(p.donem) - srt(q.donem) || p.soru - q.soru);
  return { ...r, don: don.length, soru: r.kanit.length, son: don[don.length - 1] };
}).sort((p, q) => q.don - p.don || q.soru - p.soru || srt(q.son) - srt(p.son));
const top = hepsi.filter(x => x.ders !== 'Matematik').slice(0, ADET);
const eksikDers = top.filter(x => !dersSayfa[x.ders]).map(x => x.ders);
if (eksikDers.length) { console.error('KIRMIZI: ders sayfası bulunamadı: ' + [...new Set(eksikDers)].join(', ')); process.exit(3); }
const dersSay = {}; top.forEach(x => { dersSay[x.ders] = (dersSay[x.ders] || 0) + 1; });
const dersSira = Object.keys(dersSay).sort((a, b) => dersSay[b] - dersSay[a]);
const tarih = ok.olcum.split('-').reverse().join('.');

const kanitYaz = r => r.kanit.map(z => `${z.donem} s.${z.soru}`).join(' · ');
const satirlar = top.map((x, i) => `<li class="ek-satir"><span class="ek-no">${i + 1}</span><div class="ek-govde"><h3 class="ek-ad">${esc(x.konu)}</h3><p class="ek-alt">${esc(x.ders)} · sorulduğu dönem: <b>${x.don} / ${DONEM}</b> · en son <b>${esc(x.son)}</b></p>`
  + `<details class="ek-kanit"><summary>Kanıt: hangi sınav, kaçıncı soru (${x.soru} soru)</summary><p>${esc(kanitYaz(x))}</p></details></div>`
  + `<span class="ek-cubuk" aria-hidden="true"><i style="width:${Math.round(100 * x.don / DONEM)}%"></i></span>`
  + `<a class="ek-git" href="${esc(dersSayfa[x.ders])}">Soru çöz →</a></li>`).join('\n');
const dersOzet = dersSira.map(d => `<li><b>${esc(d)}</b>: listede ${dersSay[d]} konu · sınavda ${dersSoru[d] || '?'} soru</li>`).join('');

const SSS = [
  ['Staja Giriş Sınavında en çok hangi konular çıkıyor?', `${PENCERE} arasındaki ${DONEM} sınav döneminde, okuyarak saydığımız konular içinde en sık sorulan "${top[0].konu}" (${top[0].don} dönem). Her satırın altında o konunun çıktığı sınav ve soru numarası yazıyor.`],
  ['Bu sayılar nasıl hesaplandı?', `${DONEM} dönemin çıkmış soru kitapçığında ${ok.aday_konu} aday konuyla ilgili sözcüklerin geçtiği ${ok.aday_soru} soru tek tek okundu. Sözcük yalnız bir şıkta ya da bağlamda geçiyorsa soru sayılmadı; yalnız o konuyu gerçekten soran sorular sayıldı. Sayı, o konudan kaç ayrı sınav döneminde en az bir soru geldiğidir.`],
  ['Listede olmayan konulara çalışmalı mıyım?', 'Evet. Liste "nereden başlamalı" sorusunun cevabıdır, sınırı değildir. Her ders sınavda kendi ağırlığıyla yer alır; listede az görünen bir ders de puanını etkiler. Matematik bu listede yok çünkü kitapçıklardaki formüller metne güvenilir biçimde çevrilemedi; sayısı eksik çıkardı.'],
  ['Sayılar kesin mi?', 'Sayılar alt sınırdır: aynı konu hiç beklenmedik bir sözcükle sorulduysa sayıya girmemiş olabilir. Fazla sayım yoktur; her sayılan soru okunarak doğrulandı ve sınav-soru numarasıyla listelendi.'],
];

const html = `<!doctype html>
<html lang="tr">
<head>
<meta charset="utf-8">
<script src="tema-bas.js"></script>
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Staja Giriş Sınavı: Son 10 Yılda En Sık Sorulan ${ADET} Konu (kanıtlı) | Tetikte</title>
<meta name="description" content="SMMM Staja Giriş Sınavında ${PENCERE} arası ${DONEM} sınav döneminde en sık sorulan ${ADET} konu. Çıkmış sorular tek tek okunarak sayıldı; her konunun altında sınav ve soru numarası.">
<link rel="canonical" href="https://tetikte.com/en-cok-cikan-konular-sgs.html">
<meta property="og:title" content="Staja Giriş: son 10 yılda en sık sorulan ${ADET} konu (kanıtlı)">
<meta property="og:description" content="Çıkmış sorular tek tek okunarak sayıldı; her rakamın yanında sınav ve soru numarası.">
<meta property="og:url" content="https://tetikte.com/en-cok-cikan-konular-sgs.html">
<meta property="og:type" content="article">
<link rel="icon" type="image/svg+xml" href="favicon.svg">
<link rel="stylesheet" href="stil.css">
<!-- ÜRETİLEN SAYFA: motor/en-cok-cikan.js ← veri/sinav/sgs-konu-okuma.json (elle düzenlenmez). Ölçüm: ${tarih} -->
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
h2{font-size:19px;margin:30px 0 12px}
.ek-liste{list-style:none;margin:0;padding:0;display:grid;gap:8px}
.ek-satir{display:grid;grid-template-columns:34px 1fr 120px auto;gap:12px;align-items:center;background:var(--kagit);border:1px solid var(--line);border-radius:12px;padding:12px 14px}
.ek-no{font-weight:800;font-size:18px;color:var(--amber);text-align:center}
.ek-ad{margin:0;font-size:16px;line-height:1.3}
.ek-alt{margin:2px 0 0;font-size:13px;color:var(--muted)}
.ek-kanit{margin-top:4px;font-size:12.5px;color:var(--muted)}
.ek-kanit summary{cursor:pointer;color:var(--link)}
.ek-kanit p{margin:4px 0 0;line-height:1.5}
.ek-cubuk{height:8px;border-radius:99px;background:var(--line);overflow:hidden}
.ek-cubuk i{display:block;height:100%;background:var(--amber-dolgu);border-radius:99px}
.ek-git{font-weight:700;font-size:13.5px;white-space:nowrap;text-decoration:none}
@media(max-width:640px){.ek-satir{grid-template-columns:28px 1fr;}.ek-cubuk{grid-column:2}.ek-git{grid-column:2}}
.ozet{margin:0;padding-left:18px;color:var(--muted)}
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
  <div class="top"><a href="index.html">Tetikte</a> · <a href="sorular.html">Sınavlar</a> · En sık sorulan konular</div>
  <main>
  <h1>Staja Giriş Sınavı: son 10 yılda en sık sorulan ${ADET} konu</h1>
  <p class="alt">${PENCERE} arasındaki ${DONEM} sınav döneminin çıkmış sorularını <b>tek tek okuyarak</b> saydık. Her konunun altında, o konunun hangi sınavda kaçıncı soru olarak çıktığı yazıyor; kendin kontrol edebilirsin.</p>
  <p class="yontem"><b>Yöntem:</b> ${ok.aday_konu} aday konuyla ilgili sözcüklerin geçtiği ${ok.aday_soru} soru okundu; sözcük yalnız bir şıkta geçiyorsa soru sayılmadı. Sayı, o konudan <b>kaç ayrı sınav döneminde</b> en az bir soru geldiğidir ve <b>alt sınırdır</b>. Soru numaraları A kitapçığına göredir. Kaynak: ${DONEM - 5} dönem TESMER'in yayımladığı kitapçık; 2024/2–2025/3 arası 5 dönem başka bir sitede yayımlanmış kitapçık. Matematik formüller metne güvenilir çevrilemediği için listede yok. Ölçüm: ${tarih}.</p>

  <h2>İlk ${ADET} konu</h2>
  <ol class="ek-liste">
${satirlar}
  </ol>

  <h2>Ders ders özet</h2>
  <ul class="ozet">${dersOzet}</ul>

  <h2>Bu konularda nerede olduğunu gör</h2>
  <div class="kapi">
    <a href="seviye-testi.html"><b>30 soruda seviyeni ölç</b><span>Ücretsiz. Bitince geçme ihtimalini ve en zayıf alanını görürsün.</span></a>
    <a href="kaydir/vitrin/sgs.html"><b>Örnek soruları çöz</b><span>Her şıkkın neden doğru ya da yanlış olduğu, dayandığı maddeyle.</span></a>
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
const hedef = path.join(KOK, 'en-cok-cikan-konular-sgs.html');
if (KURU) { top.forEach((x, i) => console.log(String(i + 1).padStart(2), x.ders, '›', x.konu, x.don + '/' + DONEM, 'son ' + x.son)); process.exit(0); }
fs.writeFileSync(hedef, html, 'utf8');
console.log('en-cok-cikan-konular-sgs.html: ' + top.length + ' konu, ' + dersSira.length + ' ders (kaynak veri/sinav/sgs-konu-okuma.json)');
