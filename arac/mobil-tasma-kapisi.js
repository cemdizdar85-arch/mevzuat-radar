/* ============================================================================
   MOBİL TAŞMA KAPISI — "telefonda (375px) içerik ekrandan taşıyor mu?"

   NEDEN VAR (01.10.2026, Cem "1.2.3 üçünü de yap")
   7a42436b fiyat gösterimini değiştirdi ("1.000 kurucudan sonra … (KDV dahil …)").
   satin-al.html'de fiyat sütunu flex:none olduğu için satır sütunu genişletti;
   375px'te fiyat 441px'te KESİLDİ ("2.490 T…"), paket adı tek kelimelik sütuna
   sıkıştı. Sayfa yatay kaymıyordu (scrollWidth 375) — yani "sayfa kayıyor mu"
   diye bakan bir kontrol bunu GÖRMEZDİ. Kurulu kapıların hiçbiri telefona
   bakmıyordu; kırık elle telefon ölçümünde bulundu (9f861826 sonrası düzeltildi).

   NE ÖLÇER (her sayfayı 375x812 mobil öykünmeyle gerçekten açarak)
   A. YATAY KAYMA: sayfa ekrandan geniş (scrollWidth > ekran).
   B. KESİK İÇERİK: yazı/düğme/girdi/görsel taşıyan öğe ekranın sağından çıkıyor
      ve kullanıcı onu kaydırarak da göremiyor.

   YANLIŞ ALARM FRENLERİ (öz-sınavda her biri bir vaka)
   - overflow-x:auto/scroll kabın içi sayılmaz (kaydırılabilir tablo, grafik).
   - Kırpan bir kabın (html/body DEĞİL) TAMAMEN dışında kalan öğe sayılmaz
     (kayan slaytın görünmeyen karesi). Kısmen görünen = kesik = sayılır.
   - position:fixed öğe ve içi sayılmaz (perde, alt menü, Araçlar düğmesi).
   - İçi boş süs kutusu B'de sayılmaz (sayfayı kaydırıyorsa A yakalar).
   - Yalnız EN DIŞTAKİ taşan öğe raporlanır (iç içe 8 span tek kusurdur).

   CIRCIR: ilk kurulumda var olan borç veri/mobil-tasma-taban.json'a yazılır
   (ORTAM -> sayfa -> kesik öğe sayısı + yatay kayma; "linux" = bulut, "win32" = Cem'in
   makinesi — yazı tipi farkı yüzünden ayrı, 02.10 ölçüldü). Tabanı AŞAN ya da tabanda olmayan
   sayfadaki yeni kusur KIRMIZI. Borç ödenince taban kendiliğinden inmez:
   node arac/mobil-tasma-kapisi.js --tazele

   BU KAPI ŞUNU GÖRMEZ:
     - Gerçek telefon yazı tipi (Android Roboto, iPhone SF) ölçülmez: bulut Linux yazı tipiyle,
       Cem'in makinesi Windows yazı tipiyle ölçer (02.10: Linux daha geniş, taşma orada önce çıkar).
     - 375 ve 320px dışındaki genişlikler (768px tablet, yatay telefon) ölçülmez.
     - 320px ölçümü yeniden yükleme yapmaz: genişliği yalnız AÇILIŞTA okuyan betik
       (JS ile kurulan yerleşim) 375'teki halinde kalır.
     - Kullanıcı etkileşimiyle açılan içerik (paket seçince açılan ders kutusu,
       sipariş sonrası havale ekranı) — yalnız açılıştaki hal ölçülür.
     - Ağdan geç gelen içerik bekleme süresini (3,5 sn) aşarsa ölçülmez.
     - Dikey sorunlar (üst üste binme, çok uzun sayfa), küçük dokunma hedefi.
     - kaydir/ altındaki sayfalar (yalnız kökteki .html'ler).

   Kullanım:  node arac/mobil-tasma-kapisi.js              (kökteki bütün .html)
              node arac/mobil-tasma-kapisi.js satin-al.html
              node arac/mobil-tasma-kapisi.js --tazele      (tabanı bugüne indir/kur)
              node arac/mobil-tasma-kapisi.js --sinav [--mutasyon]
   API maliyeti SIFIR. Dış bağlantı YOK. Bağımlılık YOK (arac/tarayici.js).
   ============================================================================ */
'use strict';
const { spawn } = require('child_process');
const fs   = require('fs');
const path = require('path');
const { tarayiciAc, bekle } = require('./tarayici.js');

const KOK       = path.resolve(__dirname, '..');
const PORT      = 8143;                // kontrast 8137, acilis 8141
const GENISLIK  = 375, YUKSEKLIK = 812;
/* 02.10 (Cem "1.2.3 yap"): 320px eski/küçük telefon. Sayfa YENİDEN YÜKLENMEZ - 375 ölçümünden
   sonra ekran daraltılır, yerleşim yeniden kurulur, yeniden ölçülür. Taban anahtarı "sayfa@320". */
const DAR       = 320;
const BEKLE_MS  = 3500;
const RAPOR_YOL = path.join(KOK, 'veri', 'mobil-tasma-raporu.json');
const TABAN_YOL = path.join(KOK, 'veri', 'mobil-tasma-taban.json');

/* Sayfa içinde koşar. MUT yalnız öz-sınavın mutasyon turunda dolu. */
const SAYFA_OLCUM = function(MUT){
  const vw = document.documentElement.clientWidth;
  const sinir = vw + 1 + (MUT === 'sinir' ? 300 : 0);
  const IZLI = { IMG:1, INPUT:1, BUTTON:1, SELECT:1, TEXTAREA:1, VIDEO:1, CANVAS:1, SVG:1, svg:1, TABLE:1 };
  const tasan = new Set();
  const hepsi = document.querySelectorAll('body *');
  for (let i = 0; i < hepsi.length; i++) {
    const el = hepsi[i];
    const st = getComputedStyle(el);
    if (st.display === 'none' || st.visibility === 'hidden') continue;
    const r = el.getBoundingClientRect();
    if (!r.width || !r.height || r.right <= sinir) continue;
    if (MUT !== 'bos' && !IZLI[el.tagName] && !(el.innerText || '').trim()) continue;   /* içi boş süs */
    if (MUT !== 'sabit' && st.position === 'fixed') continue;
    let muaf = false;
    for (let p = el.parentElement; p && p !== document.body && p !== document.documentElement; p = p.parentElement) {
      const ps = getComputedStyle(p);
      if (MUT !== 'sabit' && ps.position === 'fixed') { muaf = true; break; }
      const ox = ps.overflowX;
      if (MUT !== 'kaydir' && (ox === 'auto' || ox === 'scroll')) { muaf = true; break; }
      if (ox === 'hidden' || ox === 'clip') {
        const pr = p.getBoundingClientRect();
        /* kabın tamamen dışında = görünmeyen slayt (bilerek); kısmen görünen = kesik */
        if (MUT === 'tam-gizli' || r.left >= pr.right - 1 || r.right <= pr.left + 1) { muaf = true; break; }
      }
    }
    if (!muaf) tasan.add(el);
  }
  /* yalnız en dıştaki taşan öğe */
  const kok = [...tasan].filter(el => { for (let p = el.parentElement; p; p = p.parentElement) if (tasan.has(p)) return false; return true; });
  const ad = el => el.tagName.toLowerCase() + (el.id ? '#' + el.id : '') +
    (typeof el.className === 'string' && el.className.trim() ? '.' + el.className.trim().split(/\s+/).slice(0, 2).join('.') : '');
  const sw = document.documentElement.scrollWidth;
  return {
    vw, sw,
    kayma: MUT === 'sw' ? false : sw > vw + 1,
    kesik: kok.slice(0, 12).map(el => ({ oge: ad(el), sag: Math.round(el.getBoundingClientRect().right),
                                          yazi: (el.innerText || '').replace(/\s+/g, ' ').trim().slice(0, 50) })),
    kesikSayi: kok.length
  };
};

/* ---- öz-sınav vakaları: { ad, html, kayma, kesik } — beklenen sonuç ---- */
const SAR = govde => '<!doctype html><html><head><meta name="viewport" content="width=device-width,initial-scale=1">' +
  '<style>body{margin:0;font:16px sans-serif}</style></head><body>' + govde + '</body></html>';
const VAKALAR = [
  { ad: 'satin-al 01.10 (flex:none fiyat sütunu, body kırpıyor)', kayma: false, kesik: true,
    html: SAR('<style>html,body{overflow-x:hidden}</style><label style="display:flex;gap:12px;padding:14px">' +
      '<span>Staja Başlama — soru bankası</span><span style="flex:none;margin-left:auto;text-align:right">' +
      '<b>2.490 TL + KDV</b><span style="display:block;white-space:nowrap">1.000 kurucudan sonra 4.990 TL + KDV (KDV dahil 5.988 TL)</span></span></label>') },
  { ad: 'geniş yazı kutusu sayfayı kaydırıyor', kayma: true, kesik: true,
    html: SAR('<div style="width:600px">Bu kutu ekrandan geniş, sayfa yana kayar.</div>') },
  { ad: 'kaydırılabilir tablo (overflow-x:auto) — yanlış alarm olmamalı', kayma: false, kesik: false,
    html: SAR('<div style="overflow-x:auto"><table style="width:700px"><tr><td>Uzun tablo hücresi, kaydırılarak okunur</td></tr></table></div>') },
  { ad: 'görünmeyen slayt (kırpan kabın tamamen dışında) — yanlış alarm olmamalı', kayma: false, kesik: false,
    html: SAR('<div style="overflow:hidden;position:relative;height:60px"><div style="position:absolute;left:0;width:100%">Birinci slayt</div>' +
      '<div style="position:absolute;left:100%;width:100%">İkinci slayt görünmüyor</div></div>') },
  { ad: 'sabit (fixed) geniş şerit — yanlış alarm olmamalı', kayma: false, kesik: false,
    html: SAR('<div style="position:fixed;top:0;left:0;width:500px">Açılış perdesi gibi sabit katman</div><p>Sayfa</p>') },
  { ad: 'içi boş süs (kırpılmış kahraman) — yanlış alarm olmamalı', kayma: false, kesik: false,
    html: SAR('<div style="overflow:hidden;position:relative;height:120px"><div style="position:absolute;right:-100px;width:250px;height:100px;background:#888"></div>Kahraman</div>') },
  { ad: 'temiz sayfa', kayma: false, kesik: false,
    html: SAR('<h1>Başlık</h1><p>Kısa bir paragraf, ekrana sığar.</p><button>Düğme</button>') },
  { ad: 'kısmen kırpılmış yazı (sarmalayıcı overflow:hidden)', kayma: false, kesik: true,
    html: SAR('<div style="overflow:hidden;width:100%"><div style="width:500px">Bu yazının sonu ekranın dışında kalır ve okunamaz.</div></div>') },
  { ad: 'içi boş geniş kutu sayfayı kaydırıyor (yalnız A görür)', kayma: true, kesik: false,
    html: SAR('<div style="width:600px;height:10px"></div><p>Yazı</p>') },
  { ad: '350px kutu: 375\'te sığar', kayma: false, kesik: false,
    html: SAR('<div style="width:350px">Bu kutu 375 ekrana sığar ama 320 ekrana sığmaz.</div>') },
  { ad: '350px kutu: 320\'de taşar (dar ekran ölçülüyor mu)', genislik: DAR, kayma: true, kesik: true,
    html: SAR('<div style="width:350px">Bu kutu 375 ekrana sığar ama 320 ekrana sığmaz.</div>') }
];
const MUTASYONLAR = ['sinir', 'kaydir', 'tam-gizli', 'sabit', 'bos', 'sw', 'dar'];

async function ekran(t, oturum, genislik){
  await t.cdp.cagir('Emulation.setDeviceMetricsOverride',
    { width: genislik, height: YUKSEKLIK, deviceScaleFactor: 2, mobile: true }, oturum);
}
async function sekmeAc(t){
  const c = await t.cdp.cagir('Target.createTarget', { url: 'about:blank' });
  const a = await t.cdp.cagir('Target.attachToTarget', { targetId: c.targetId, flatten: true });
  await ekran(t, a.sessionId, GENISLIK);
  await t.cdp.cagir('Page.enable', {}, a.sessionId);
  return { hedef: c.targetId, oturum: a.sessionId };
}
async function olc(t, oturum, mut){
  const r = await t.cdp.cagir('Runtime.evaluate',
    { expression: '(' + SAYFA_OLCUM.toString() + ')(' + JSON.stringify(mut || '') + ')', returnByValue: true }, oturum);
  if (r.exceptionDetails) throw new Error(r.exceptionDetails.text || 'sayfa ici hata');
  return r.result.value;
}

async function sinav(t, mutasyonMu){
  const s = await sekmeAc(t);
  const tur = async (mut) => {
    let dogru = 0; const yanlis = [];
    for (const v of VAKALAR) {
      await ekran(t, s.oturum, mut === 'dar' ? GENISLIK : (v.genislik || GENISLIK));
      await t.cdp.cagir('Page.navigate', { url: 'data:text/html;charset=utf-8,' + encodeURIComponent(v.html) }, s.oturum);
      await bekle(250);
      const o = await olc(t, s.oturum, mut);
      const ok = o.kayma === v.kayma && (o.kesikSayi > 0) === v.kesik;
      if (ok) dogru++; else yanlis.push(v.ad + ' (beklenen kayma=' + v.kayma + ' kesik=' + v.kesik +
                                         ', olculen kayma=' + o.kayma + ' kesik=' + o.kesikSayi + ')');
    }
    return { dogru, yanlis };
  };
  const temel = await tur('');
  console.log('MOBIL TASMA OZ-SINAVI: ' + temel.dogru + '/' + VAKALAR.length + ' vaka dogru');
  temel.yanlis.forEach(y => console.log('  YANLIS: ' + y));
  let kod = temel.yanlis.length ? 1 : 0;
  if (mutasyonMu) {
    /* Kural 8: her fren/kosul bozulunca sinav KIRMIZI dusmeli */
    let dusen = 0;
    for (const m of MUTASYONLAR) {
      const r = await tur(m);
      const dustu = r.yanlis.length > 0;
      if (dustu) dusen++;
      console.log('  MUTASYON ' + m.padEnd(10) + (dustu ? ' -> sinav KIRMIZI (iyi)' : ' -> sinav YESIL kaldi (SINAV EKSIK)'));
    }
    console.log('  Mutasyon: ' + dusen + '/' + MUTASYONLAR.length + ' -> KIRMIZI');
    if (dusen < MUTASYONLAR.length) kod = 1;
  }
  try { await t.cdp.cagir('Target.closeTarget', { targetId: s.hedef }); } catch (e) {}
  return kod;
}

function raporYaz(icerik){
  try {
    const yeni = JSON.stringify({ tarih: new Date().toISOString().slice(0, 19).replace('T', ' '), ...icerik }, null, 2);
    const notrle = j => j.replace(/("tarih"\s*:\s*)"[^"]*"/, '$1"@@ZAMAN@@"').replace(/\r\n/g, '\n').trim();
    let eski = null; try { eski = fs.readFileSync(RAPOR_YOL, 'utf8'); } catch (e) {}
    if (eski !== null && notrle(eski) === notrle(yeni)) return;
    fs.writeFileSync(RAPOR_YOL, yeni);
  } catch (e) { console.log('  (rapor yazilamadi: ' + e.message + ')'); }
}

(async function(){
  const arg = process.argv.slice(2);
  const ci = process.env.CI === 'true' || process.env.GITHUB_ACTIONS === 'true';
  const t = await tarayiciAc();
  if (t.hata) {
    console.log('MOBIL TASMA KAPISI: KOR — tarayici acilmadi (' + t.hata + ').');
    if (!arg.includes('--sinav')) raporYaz({ durum: 'KOR', sebep: t.hata, ci });
    process.exit(ci ? 1 : 0);
  }
  if (arg.includes('--sinav')) {
    let kod = 1;
    try { kod = await sinav(t, arg.includes('--mutasyon')); } catch (e) { console.log('OZ-SINAV KOR — ' + e.message); }
    t.kapat(); process.exit(kod);
  }

  const secili = arg.filter(a => a.endsWith('.html'));
  const sayfalar = secili.length ? secili
    : fs.readdirSync(KOK).filter(f => f.endsWith('.html')).filter(f => !/-yedek|^_/.test(f)).sort();
  const sunucu = spawn(process.execPath, [path.join(KOK, 'arac', 'yerel-sunucu.js')],
                       { env: { ...process.env, PORT: String(PORT) }, stdio: 'ignore' });
  await bekle(700);
  const bitir = kod => { try { t.kapat(); } catch (e) {} try { sunucu.kill(); } catch (e) {} process.exit(kod); };

  console.log('MOBIL TASMA KAPISI: ' + sayfalar.length + ' sayfa · ' + GENISLIK + 'x' + YUKSEKLIK + ' · bekleme ' + (BEKLE_MS / 1000) + ' sn.');
  const sonuc = [];
  for (const sayfa of sayfalar) {
    let s = null;
    try {
      s = await sekmeAc(t);
      await t.cdp.cagir('Page.navigate', { url: 'http://127.0.0.1:' + PORT + '/' + sayfa + '?kapi=' + Date.now() }, s.oturum);
      await bekle(BEKLE_MS);
      const o = await olc(t, s.oturum, '');
      sonuc.push({ sayfa, kayma: o.kayma, sw: o.sw, kesikSayi: o.kesikSayi, kesik: o.kesik });
      await ekran(t, s.oturum, DAR);
      await bekle(400);
      const d = await olc(t, s.oturum, '');
      sonuc.push({ sayfa: sayfa + '@' + DAR, kayma: d.kayma, sw: d.sw, kesikSayi: d.kesikSayi, kesik: d.kesik });
    } catch (e) {
      sonuc.push({ sayfa, olculemedi: true, sebep: String(e.message).slice(0, 80) });
    } finally {
      if (s) try { await t.cdp.cagir('Target.closeTarget', { targetId: s.hedef }); } catch (e) {}
    }
  }

  const olculen = sonuc.filter(s => !s.olculemedi), olculemeyen = sonuc.filter(s => s.olculemedi);
  /* 02.10 ölçüldü: taban ORTAM BAŞINA. Aynı iletisim.html 375px'te Windows'ta temiz, GitHub
     Linux runner'ında 394px'e taşıyor (yazı tipi farkı). Windows'ta kurulan taban bulutta kapıyı
     kalıcı kırmızı yapıyordu. Bulut tabanı bulutta kurulur: gh workflow run mobil-tasma-taban.yml */
  const ORTAM = process.platform;
  let butun = {};
  try { butun = JSON.parse(fs.readFileSync(TABAN_YOL, 'utf8')); } catch (e) {}
  if (arg.includes('--tazele')) {
    if (secili.length) { console.log('  --tazele yalniz butun sayfalarla kosar.'); bitir(1); }
    if (olculemeyen.length) { console.log('  KOR sayfa var (' + olculemeyen.length + '), taban yazilmadi.'); bitir(1); }
    const taban = {};
    for (const s of olculen) if (s.kesikSayi || s.kayma) taban[s.sayfa] = { kesik: s.kesikSayi, kayma: s.kayma };
    butun[ORTAM] = taban;
    fs.writeFileSync(TABAN_YOL, JSON.stringify(butun, null, 2) + '\n');
    console.log('  Taban yazildi (' + ORTAM + '): ' + Object.keys(taban).length + ' kayitta borc. ' + path.relative(KOK, TABAN_YOL));
    bitir(0);
  }

  const taban = butun[ORTAM] || null;
  if (!taban) { console.log('  KOR — bu ortamin (' + ORTAM + ') tabani yok (' + path.relative(KOK, TABAN_YOL) + '). Kur: node arac/mobil-tasma-kapisi.js --tazele' + (ci ? '  (bulutta: gh workflow run mobil-tasma-taban.yml)' : '')); bitir(1); }

  const yeni = [], borc = [], odenen = [];
  for (const s of olculen) {
    const b = taban[s.sayfa] || { kesik: 0, kayma: false };
    if (s.kesikSayi > b.kesik || (s.kayma && !b.kayma)) yeni.push(s);
    else if (s.kesikSayi || s.kayma) borc.push(s);
    if (s.kesikSayi < b.kesik || (!s.kayma && b.kayma)) odenen.push(s.sayfa);
  }
  /* 02.10: birkaç sayfalık deneme koşusu raporu YAZMAZ - rapor depoda izleniyor; kısmi koşu
     onu ezip ana klasörü kirletiyordu (başka oturumun birleştirmesini durdurdu). */
  if (!secili.length) raporYaz({
    durum: yeni.length ? 'KIRMIZI' : (olculemeyen.length ? 'KOR' : 'YESIL'), ci,
    genislik: [GENISLIK, DAR], sayfa_toplam: sayfalar.length, olcum_toplam: sayfalar.length * 2, olculen: olculen.length, KOR: olculemeyen.length,
    yeni_kusur_sayfa: yeni.length, taban_borcu_sayfa: borc.length,
    yeni_kusur: yeni.map(s => ({ sayfa: s.sayfa, kayma: s.kayma, sw: s.sw, kesik: s.kesik })),
    taban_borcu: borc.map(s => ({ sayfa: s.sayfa, kayma: s.kayma, kesik: s.kesik.slice(0, 4) })),
    odenen_borc: odenen,
    olculemeyenler: olculemeyen.map(s => ({ sayfa: s.sayfa, sebep: s.sebep }))
  });
  console.log('  Olculen ' + olculen.length + '/' + (sayfalar.length * 2) + ' (sayfa x 375/' + DAR + ')' + (olculemeyen.length ? ' · KOR ' + olculemeyen.length : '') +
              ' · YENI kusur ' + yeni.length + ' sayfa · taban borcu ' + borc.length + ' sayfa' +
              (odenen.length ? ' · odenen borc ' + odenen.length + ' (tabani indir: --tazele)' : ''));
  for (const s of yeni.slice(0, 15)) {
    console.log('  KIRMIZI ' + s.sayfa + (s.kayma ? '  [sayfa yana kayiyor, genislik ' + s.sw + 'px]' : ''));
    for (const k of s.kesik.slice(0, 4)) console.log('      kesik <' + k.oge + '> sag ' + k.sag + 'px  "' + k.yazi + '"');
  }
  for (const s of olculemeyen) console.log('  KOR ' + s.sayfa + '  <- ' + s.sebep);
  if (yeni.length || olculemeyen.length) { console.log('  Ayrinti: veri/mobil-tasma-raporu.json'); bitir(1); }
  console.log('  Temiz - tabanin ustunde yeni tasma yok.');
  bitir(0);
})().catch(e => { console.log('MOBIL TASMA KAPISI: KOR — ' + e.message); process.exit(1); });
