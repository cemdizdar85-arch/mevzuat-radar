#!/usr/bin/env node
/* ============================================================================
 *  CANLI TARAMA (03.10.2026, Cem "1.2.3 üçünü de yap" — GM önerisi 3)
 *
 *  NEDEN: 03.10'da mobil alt menü ana sayfayı telefonda TAM EKRAN örttü (index.html'in genel
 *  "nav{position:fixed;top:0}" kuralı <nav> alt menüyü yakaladı). Yerel kapılar (mobil taşma, kontrast)
 *  YAKALAMADI: taşma kapısı sabit konumlu öğeyi bilerek saymaz, kontrast kapısı örtmeyi görmez.
 *  Hatayı elle koşulan CANLI tarama buldu. Bu betik o taramanın robotudur.
 *
 *  NE YAPAR: tetikte.com'da (önizleme kapısıyla) her sayfayı telefon (390) + masaüstü (1280) açar ve ölçer:
 *    TASMA    belge yatayda pencereden geniş (sw > iw+1)
 *    ORTME    alt menü (#ttAltMenu) ekranın alt şeridinde değil (üst kenarı ekranın yarısından yukarıda)
 *    EKSIK    sayfanın beklenen öğesi yok
 *    HATA     sayfa yüklenirken JavaScript hatası
 *    PERDE    önizleme kapısı varken açılış perdesi duruyor
 *    MENU     alt menü olması gereken yerde yok / olmaması gereken yerde var
 *    KALIP    ders/vitrin sayfası eski kalıpta ("Bilmiyorum" yok ya da demo düğmesi ?demo=1 koşulsuz)
 *  KIRMIZIda çıkış 1 + (iş akışında) Cem'e e-posta. Rapor dosyaya yazılır, depoya yazılmaz.
 *
 *  🚫 GÖRMEZ: tıklayınca açılan içerik · oturum isteyen içerik (Hesabım paneli, paketli soru) · listede
 *     olmayan sayfa · renk/kontrast (ayrı kapı) · 390/1280 dışı genişlik · Cloudflare/ağ kesintisi
 *     (o zaman "KOR" der, temiz demez).
 *  Öz-sınav: node motor/canli-tarama.js --sinav [--mutasyon]  (data: sayfalarla, ağ gerekmez)
 * ==========================================================================*/
'use strict';
const fs = require('fs'), path = require('path');
const { tarayiciAc, bekle } = require(path.join(__dirname, '..', 'arac', 'tarayici.js'));
const MUT = process.env.CT_MUTASYON || '';

/* [sayfa, beklenen öğeler, alt menü telefonda olmalı mı, kalıp denetimi] */
const SAYFALAR = [
  ['index.html', ['#nav', '#nasil .na', '.v2-uc .v2-kart'], true, false],
  ['sorular.html', ['.sc-sinav'], true, false],
  ['yanlislarim.html', ['#ylKutu', '#durum'], true, false],
  ['satin-al.html?paket=sgs', ['#akd1', '#akd2', '#ozetKart', '#kodAc'], false, false],
  ['seviye-testi.html', ['#svBasla'], false, false],
  ['fiyat.html', ['body'], true, false],
  ['ogrenci.html', ['#ogGiris'], true, false],
  ['kaydir/sgs/turkce.html', ['body'], false, true],
  ['kaydir/vitrin/sgs.html', ['body'], false, true],
  ['kaydir/vitrin/smmm.html', ['body'], false, true],
  ['kaydir/smmm/finansal-muhasebe.html', ['body'], false, true],   // Yeterlilik kabuğu (smmm-kasa-yayin -SiteKabuk kurar)
];

/* Sayfada koşan ölçüm (bozma anahtarları öz-sınav içindir) */
const OLCUM = `(function(mut){
  var n=document.getElementById('ttAltMenu'), r=n&&n.getBoundingClientRect(), gor=n&&getComputedStyle(n).display!=='none';
  return { sw:document.documentElement.scrollWidth, iw:innerWidth, ih:innerHeight,
    menuVar:!!(n&&gor), menuUst:(n&&gor)?Math.round(r.top):null,
    perde:!!document.getElementById('mrPerde'), hata:(window.__h||[]).slice(0,5) };
})`;

function degerlendir(o, beklenen, menuGerek, telefon, kalip, eksik, kaynak, en) {
  const ihlal = [];
  // telefon taklidinde tasan sayfa pencereyi de genisletir (iw=sw olur; 03.10 canli 443/443) -> olcu EKRAN genisligi
  const ekran = en || o.iw;
  if (MUT !== 'tasma' && o.sw > ekran + 1) ihlal.push('TASMA ' + o.sw + '>' + ekran);
  if (MUT !== 'ortme' && o.menuVar && o.menuUst !== null && o.menuUst < o.ih * 0.5) ihlal.push('ORTME alt menü üst kenarı ' + o.menuUst + 'px (ekran ' + o.ih + ')');
  if (MUT !== 'eksik' && eksik.length) ihlal.push('EKSIK ' + eksik.join(', '));
  if (MUT !== 'hata' && o.hata.length) ihlal.push('HATA ' + o.hata.join(' | '));
  if (o.perde) ihlal.push('PERDE önizleme kapısına rağmen perde var');
  if (telefon && menuGerek !== null && MUT !== 'menu') {
    if (menuGerek && !o.menuVar) ihlal.push('MENU alt menü yok');
    if (!menuGerek && o.menuVar) ihlal.push('MENU alt menü burada olmamalı');
  }
  if (kalip && MUT !== 'kalip' && kaynak !== null) {
    if (kaynak.indexOf('class="bilmiyorum"') < 0) ihlal.push('KALIP "Bilmiyorum" yok (eski kalıp)');
    if (kaynak.indexOf('id="kutuIleri"') > -1 && kaynak.indexOf('demo=1') < 0) ihlal.push('KALIP demo düğmesi herkese açık');
  }
  return ihlal;
}

async function sayfaOlc(t, o, url, beklenen) {
  await t.cdp.cagir('Page.navigate', { url }, o); await bekle(url.startsWith('data:') ? 600 : 4500);
  const r = await t.cdp.cagir('Runtime.evaluate', { returnByValue: true,
    expression: '(' + OLCUM + ')(' + JSON.stringify(MUT) + ')' }, o);
  const v = r.result.value;
  const e = await t.cdp.cagir('Runtime.evaluate', { returnByValue: true,
    expression: JSON.stringify(beklenen) + '.filter(function(q){return !document.querySelector(q);})' }, o);
  return { o: v, eksik: e.result.value };
}
async function sekme(t, en, telefon) {
  const c = await t.cdp.cagir('Target.createTarget', { url: 'about:blank' });
  const a = await t.cdp.cagir('Target.attachToTarget', { targetId: c.targetId, flatten: true });
  const o = a.sessionId;
  await t.cdp.cagir('Emulation.setDeviceMetricsOverride', { width: en, height: 844, deviceScaleFactor: 1, mobile: telefon }, o);
  await t.cdp.cagir('Page.enable', {}, o);
  await t.cdp.cagir('Page.addScriptToEvaluateOnNewDocument', { source: "window.__h=[];addEventListener('error',function(e){__h.push(String(e.message).slice(0,140))});addEventListener('unhandledrejection',function(e){__h.push('red: '+String(e.reason&&e.reason.message||e.reason).slice(0,140))});" }, o);
  return { o, id: c.targetId };
}

async function sinav(t) {
  const sar = b => 'data:text/html;charset=utf-8,' + encodeURIComponent('<!doctype html><meta name=viewport content="width=device-width,initial-scale=1"><body style="margin:0">' + b + '</body>');
  const MENU = '<div id="ttAltMenu" style="position:fixed;left:0;right:0;bottom:0;height:56px">m</div>';
  const VAKA = [
    ['temiz sayfa + doğru menü', sar('<h1 id=x>Başlık</h1>' + MENU), ['#x'], true, null, []],
    ['yatay taşma', sar('<div style="width:600px;height:10px"></div>' + MENU), [], true, null, ['TASMA']],
    ['menü ekranı örtüyor (03.10 vakası)', sar('<style>div#ttAltMenu{top:0}</style><h1 id=x>B</h1>' + MENU), ['#x'], true, null, ['ORTME']],
    ['beklenen öğe yok', sar('<p>b</p>' + MENU), ['#yok'], true, null, ['EKSIK']],
    ['js hatası', sar('<script>window.__h=window.__h||[];setTimeout(function(){ yokFonk(); },0)</script>' + MENU), [], true, null, ['HATA']],
    ['menü olmamalı ama var', sar('<p>b</p>' + MENU), [], false, null, ['MENU']],
    ['eski kalıp', sar('<p>b</p>'), [], null, '<button id="kutuIleri">x</button>', ['KALIP', 'KALIP']],
    ['yeni kalıp temiz', sar('<p>b</p>'), [], null, '<button class="bilmiyorum"></button>(/[?&]demo=1/)<button id="kutuIleri">', []],
  ];
  const s = await sekme(t, 390, true);
  let dogru = 0; const yanlis = [];
  for (const [ad, url, bek, menu, kaynak, beklenenTur] of VAKA) {
    const r = await sayfaOlc(t, s.o, url, bek);
    const ih = degerlendir(r.o, bek, menu, true, kaynak !== null, r.eksik, kaynak, 390);
    const turler = ih.map(x => x.split(' ')[0]).sort().join(',');
    const ok = turler === beklenenTur.slice().sort().join(',');
    if (ok) dogru++; else yanlis.push(ad + ' (beklenen [' + beklenenTur + '], ölçülen [' + turler + '])');
  }
  console.log('CANLI TARAMA OZ-SINAVI' + (MUT ? ' [mutasyon ' + MUT + ']' : '') + ': ' + dogru + '/' + VAKA.length);
  yanlis.forEach(y => console.log('  YANLIS: ' + y));
  return yanlis.length ? 1 : 0;
}

(async () => {
  const args = process.argv.slice(2);
  const t = await tarayiciAc();
  if (t.hata) { console.log('CANLI TARAMA: KOR — tarayıcı açılmadı (' + t.hata + ')'); process.exit(args.includes('--sinav') ? 1 : 0); }
  if (args.includes('--sinav')) {
    let kod = await sinav(t);
    t.kapat();
    if (args.includes('--mutasyon') && !MUT) {
      const { execFileSync } = require('child_process'); let dusen = 0; const M = ['tasma', 'ortme', 'eksik', 'hata', 'menu', 'kalip'];
      for (const m of M) {
        let kirmizi = false;
        try { execFileSync(process.execPath, [__filename, '--sinav'], { env: { ...process.env, CT_MUTASYON: m }, stdio: 'pipe' }); } catch (e) { kirmizi = true; }
        console.log('  MUTASYON ' + m.padEnd(6) + (kirmizi ? ' -> sınav KIRMIZI (iyi)' : ' -> sınav YEŞİL kaldı (SINAV EKSIK)'));
        if (kirmizi) dusen++;
      }
      console.log('  Mutasyon: ' + dusen + '/' + M.length + ' -> KIRMIZI'); if (dusen < M.length) kod = 1;
    }
    process.exit(kod);
  }
  const ci = args.indexOf('--cikti'), cikti = ci > -1 ? args[ci + 1] : null;
  const ti = args.indexOf('--taban'), TABAN = ti > -1 ? args[ti + 1] : 'https://tetikte.com';
  const satir = []; let kirmizi = 0, kor = 0;
  for (const [en, tel] of [[390, true], [1280, false]]) {
    const s = await sekme(t, en, tel);
    await t.cdp.cagir('Page.navigate', { url: TABAN + '/index.html?kapi=tetikte2026' }, s.o); await bekle(3000);
    for (const [sayfa, bek, menu, kalip] of SAYFALAR) {
      let kaynak = null;
      if (kalip && en === 390) { try { const y = await fetch(TABAN + '/' + sayfa, { cache: 'no-store' }); kaynak = y.ok ? await y.text() : null; } catch (e) { kaynak = null; } }
      let ih;
      try { const r = await sayfaOlc(t, s.o, TABAN + '/' + sayfa, bek); ih = degerlendir(r.o, bek, menu, tel, kalip && en === 390, r.eksik, kaynak, en); }
      catch (e) { kor++; ih = ['KOR ' + e.message]; }
      if (ih.length) kirmizi++;
      satir.push((ih.length ? 'KIRMIZI ' : 'temiz   ') + String(en).padEnd(5) + sayfa + (ih.length ? '  -> ' + ih.join(' · ') : ''));
    }
    try { await t.cdp.cagir('Target.closeTarget', { targetId: s.id }); } catch (e) {}
  }
  t.kapat();
  const ozet = 'CANLI TARAMA: ' + (SAYFALAR.length * 2) + ' ölçüm · KIRMIZI ' + kirmizi + (kor ? ' (KOR ' + kor + ')' : '');
  console.log(ozet); satir.forEach(x => console.log('  ' + x));
  if (cikti) fs.writeFileSync(cikti, ozet + '\n\n' + satir.join('\n') + '\n', 'utf8');
  process.exit(kirmizi ? 1 : 0);
})().catch(e => { console.error('CANLI TARAMA KOR:', e.message); process.exit(1); });
