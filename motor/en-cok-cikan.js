#!/usr/bin/env node
/* ============================================================================
 *  EN ÇOK ÇIKAN KONULAR SAYFASI (04.10.2026, Cem: "en çok çıkan konulardan ... bizi tanıtacak, rakiplerden öne geçirecek";
 *  "1.2.3 üçünü de yap": dönem sayısı ölçüsü + sayfa + Instagram karuseli)
 *
 *  NE YAPAR: çıkmış sınav kitapçıklarının konu analizinden "son 10 yılda en çok çıkan 30 konu" sayfasını DÜZ HTML olarak basar
 *  (arama motoru doğrudan okusun diye liste sayfanın içinde). Soru AÇMAZ: soru bankası pakette kalır; sayfa seviye testine,
 *  örnek sorulara ve ders sayfasına (paket kapısı) yönlendirir.
 *  ÖLÇÜ: "kaç sınav döneminde soruldu" (32 dönem, 2016+). "Kaç soru" DEĞİL - Finansal Muhasebe'de her yevmiye satırı ayrı
 *  soru sayıldığı için soru sayısı şişkin görünür (hafıza: smmm-analiz FM ~39 "soru"/sınav).
 *  KAYNAK: veri/fabrika/sgs-konu-kapsama.json (arac/... kapsama tablosu; fabrika YEREL, depoya girmez) -> bu betik YEREL koşar,
 *  çıktı (en-cok-cikan-konular-sgs.html) depoya girer. Tablo tazelenince yeniden koşulur.
 *  🚫 GÖRMEZ: çıkmış soruyu konuya bağlayan köprünün hatası (köprü yanlışsa sayı da yanlış - sayfada yöntem notu var) ·
 *     konu adlarının Türkçe görünen biçimi elle yazılmış ADLAR sözlüğünden gelir; sözlükte olmayan konu ASCII adıyla düşer (uyarı basar).
 *  Kullanım: node motor/en-cok-cikan.js sgs [--kuru]
 * ==========================================================================*/
'use strict';
const fs = require('fs'), path = require('path');
const KOK = path.join(__dirname, '..');
const SINAV = process.argv[2] || 'sgs';
const KURU = process.argv.includes('--kuru');
if (SINAV !== 'sgs') { console.error('şimdilik yalnız sgs (Yeterlilik konu adları gruplanmadan basılmaz - parçalı adlar düşük sayı veriyor)'); process.exit(2); }

// Çıkmış analizindeki katlanmış konu adı -> sayfada görünen Türkçe ad (elle, 04.10)
const ADLAR = {
  'ucret yonetmeligi': 'Meslek mensubu ücret yönetmeliği', 'cumle tamamlama': 'Cümle tamamlama', 'muhasebe bilgi sistemi': 'Muhasebe bilgi sistemi',
  'baglac kullanimi': 'Bağlaç kullanımı', 'yazim kurallari': 'Yazım kuralları', 'preposition secimi': 'Edat (preposition) seçimi',
  'noktalama isaretleri': 'Noktalama işaretleri', 'ortak maliyet dagitimi': 'Ortak maliyet dağıtımı', 'limit hesabi': 'Limit hesabı',
  'anlatim bozuklugu': 'Anlatım bozukluğu', 'kelime bilgisi': 'Kelime bilgisi', 'dikey yuzde analizi': 'Dikey yüzde analizi',
  'nakit akis tablosu': 'Nakit akış tablosu', 'uluslararasi muhasebe kuruluslari': 'Uluslararası muhasebe kuruluşları',
  'turev hesabi': 'Türev hesabı', 'disiplin cezalari': 'Disiplin cezaları', 'denetim kaniti yeterliligi': 'Denetim kanıtının yeterliliği',
  'toplu is sozlesmesi': 'Toplu iş sözleşmesi', 'hisse senedi satisi': 'Hisse senedi satışı', 'kelime bilgisi (fiil secimi)': 'Kelime bilgisi: fiil seçimi',
  'sebepsiz zenginlesme': 'Sebepsiz zenginleşme', 'depozito iadesi kaydi': 'Depozito iadesi kaydı', 'yatay analiz': 'Yatay analiz',
  'denklem cozme': 'Denklem çözme', 'genel islem kosullari': 'Genel işlem koşulları', 'analitik prosedurler': 'Analitik prosedürler',
  'tms 40 yatirim amacli gayrimenkul': 'TMS 40 yatırım amaçlı gayrimenkuller', 'donem kari zarari hesabi': 'Dönem kârı / zararı hesabı',
  'denetim kaniti guvenilirligi': 'Denetim kanıtının güvenilirliği', 'lozan konferansi': 'Lozan Konferansı',
  'net isletme sermayesi': 'Net işletme sermayesi', 'siparis maliyet sistemi': 'Sipariş maliyet sistemi',
};
const esc = s => String(s == null ? '' : s).replace(/[&<>"]/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
const slug = s => String(s).toLocaleLowerCase('tr').replace(/ç/g, 'c').replace(/ğ/g, 'g').replace(/ı/g, 'i').replace(/ö/g, 'o').replace(/ş/g, 's').replace(/ü/g, 'u').replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');

const kap = JSON.parse(fs.readFileSync(path.join(KOK, 'veri', 'fabrika', 'sgs-konu-kapsama.json'), 'utf8'));
const DONEM = kap.pencere || 32, YIL = kap.yil || 2016;
const dizin = JSON.parse(fs.readFileSync(path.join(KOK, 'veri', 'soru-dizini.json'), 'utf8')).sinavlar.find(x => x.kod === 'sgs');
const dersSayfa = {}, dersSoru = {}; dizin.dersler.forEach(d => { dersSayfa[d.ad] = d.sayfa; dersSoru[d.ad] = d.sinav_soru; });
const top = kap.satirlar.slice().sort((a, b) => b.don - a.don || b.son - a.son || String(b.sonD).localeCompare(String(a.sonD))).slice(0, 30);
const eksikAd = top.filter(x => !ADLAR[x.konu]).map(x => x.konu);
if (eksikAd.length) console.warn('⚠ Türkçe adı olmayan konu (ASCII görünecek): ' + eksikAd.join(', '));
const eksikDers = top.filter(x => !dersSayfa[x.ders]).map(x => x.ders);
if (eksikDers.length) { console.error('KIRMIZI: ders sayfası bulunamadı: ' + [...new Set(eksikDers)].join(', ')); process.exit(3); }
const dersSay = {}; top.forEach(x => { dersSay[x.ders] = (dersSay[x.ders] || 0) + 1; });
const dersSira = Object.keys(dersSay).sort((a, b) => dersSay[b] - dersSay[a]);
const tarih = new Date().toLocaleDateString('tr-TR', { day: '2-digit', month: '2-digit', year: 'numeric' });
const enCok = dersSira[0];

const satirlar = top.map((x, i) => {
  const ad = ADLAR[x.konu] || x.konu;
  return `<li class="ek-satir"><span class="ek-no">${i + 1}</span><div class="ek-govde"><h3 class="ek-ad">${esc(ad)}</h3><p class="ek-alt">${esc(x.ders)} · sorulduğu dönem: <b>${x.don} / ${DONEM}</b> · en son <b>${esc(x.sonD)}</b></p></div>`
    + `<span class="ek-cubuk" aria-hidden="true"><i style="width:${Math.round(100 * x.don / DONEM)}%"></i></span>`
    + `<a class="ek-git" href="${esc(dersSayfa[x.ders])}">Soru çöz →</a></li>`;
}).join('\n');
const dersOzet = dersSira.map(d => `<li><b>${esc(d)}</b>: listede ${dersSay[d]} konu · sınavda ${dersSoru[d] || '?'} soru</li>`).join('');

const SSS = [
  ['Staja Giriş Sınavında en çok hangi konular çıkıyor?', `Son ${YIL} sonrası ${DONEM} sınav döneminde en sık sorulan konu "${ADLAR[top[0].konu] || top[0].konu}" (${top[0].don} dönem). Listenin tamamı yukarıda; her satırda konunun kaç dönemde sorulduğu ve en son ne zaman çıktığı yazıyor.`],
  ['Bu sayılar nasıl hesaplandı?', `TESMER'in yayımladığı çıkmış soru kitapçıklarındaki her soru bir konuya bağlandı; her konu için, ${YIL}'dan bu yana kaç ayrı sınav döneminde en az bir soru geldiği sayıldı. Soru sayısı değil dönem sayısı kullanıldı, çünkü tek bir dönemde aynı konudan çok soru gelmesi o konunun her sınavda çıkacağı anlamına gelmez.`],
  ['Listede olmayan konulara çalışmalı mıyım?', 'Evet. Liste "nereden başlamalı" sorusunun cevabıdır, sınırı değildir. Her ders sınavda kendi ağırlığıyla yer alır (ders ders özet yukarıda); listede az görünen bir ders de puanını etkiler.'],
  [`En çok hangi dersten konu var?`, `Bu ilk 30'da en çok konu ${enCok} dersinden (${dersSay[enCok]} konu). Ders ağırlığı ise TESMER'in ders dağılımına göre: örneğin Finansal Muhasebe sınavda ${dersSoru['Finansal Muhasebe'] || 26} soru.`],
];

const html = `<!doctype html>
<html lang="tr">
<head>
<meta charset="utf-8">
<script src="tema-bas.js"></script>
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Staja Giriş Sınavı: Son 10 Yılda En Çok Çıkan 30 Konu (2026) | Tetikte</title>
<meta name="description" content="SMMM Staja Giriş Sınavında ${YIL}'dan bu yana ${DONEM} sınav döneminde en sık sorulan 30 konu: her konunun kaç dönemde çıktığı ve en son ne zaman sorulduğu. Çıkmış kitapçıkların konu analizi.">
<link rel="canonical" href="https://tetikte.com/en-cok-cikan-konular-sgs.html">
<meta property="og:title" content="Staja Giriş: son 10 yılda en çok çıkan 30 konu">
<meta property="og:description" content="Çıkmış kitapçıkların konu analizi: hangi konu kaç sınav döneminde soruldu.">
<meta property="og:url" content="https://tetikte.com/en-cok-cikan-konular-sgs.html">
<meta property="og:type" content="article">
<link rel="icon" type="image/svg+xml" href="favicon.svg">
<link rel="stylesheet" href="stil.css">
<!-- ÜRETİLEN SAYFA: motor/en-cok-cikan.js (elle düzenlenmez; veri tazelenince yeniden basılır). Basım: ${tarih} -->
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
  <div class="top"><a href="index.html">Tetikte</a> · <a href="sorular.html">Sınavlar</a> · En çok çıkan konular</div>
  <main>
  <h1>Staja Giriş Sınavı: son 10 yılda en çok çıkan 30 konu</h1>
  <p class="alt">${YIL}'dan bu yana yapılan ${DONEM} sınav döneminin çıkmış soru kitapçıklarını konu konu saydık. Aşağıdaki liste, hangi konunun kaç dönemde sorulduğunu ve en son ne zaman çıktığını gösterir.</p>
  <p class="yontem"><b>Yöntem:</b> TESMER'in yayımladığı çıkmış soru kitapçıklarındaki her soru bir konuya bağlandı. Sayı, o konudan <b>kaç ayrı sınav döneminde</b> en az bir soru geldiğidir (soru sayısı değil). Konu eşleştirmesi Tetikte analizidir; kesin konu kapsamı için TESMER yönergesi esastır. Veri: ${tarih}.</p>

  <h2>İlk 30 konu</h2>
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
if (KURU) { console.log('kuru: ' + top.length + ' konu, ' + dersSira.length + ' ders; ilk: ' + (ADLAR[top[0].konu] || top[0].konu) + ' (' + top[0].don + '/' + DONEM + ')'); process.exit(0); }
fs.writeFileSync(hedef, html, 'utf8');
console.log('en-cok-cikan-konular-sgs.html: ' + top.length + ' konu, ' + dersSira.length + ' ders');
