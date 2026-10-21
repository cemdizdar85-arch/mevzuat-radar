/* ============================================================================
   ✕ KAPISI — "sitede ✕ ile kapanmayan bildirim / pencere / şerit / perde var mı?"

   NEDEN VAR (15.10.2026, Cem: "telefonda bildirim geliyor, x bastırmıyor, çıkamıyor;
   x işareti olmayan ya da x işaretine basınca kapanmayan bir şey istemiyorum")
   Elle tarama (Playwright, 79 sayfa × telefon + bilgisayar) şunları buldu: ders sayfasının telif
   şeridi ✕'siz ve dokunulamaz; Meta çerez bandı her sayfada ✕'siz ve satın almada telefonda
   "Devam" düğmesini örtüyor; ödeme perdesi ✕'siz. Düzeltme 682fa755. Hiçbir kapı bunu görmüyordu:
   mobil taşma kapısı fixed katmanı bilerek saymaz, canlı tarama yalnız alt menü örtmesine bakar.

   NE ÖLÇER (her sayfayı telefon 390x844 + bilgisayar 1366x860 açarak)
   Ekrandaki her sabit (position:fixed) katman için — iç içe olanlardan yalnız en dıştaki:
     A. ✕ YOK        : içinde ✕ / × düğmesi ya da aria-label "Kapat" yok.
     B. ✕ EKRAN DIŞI : ✕ var ama ekranın dışında (kaydırmadan ulaşılamaz).
     C. ✕ ÖRTÜLÜ     : ✕'in ortasında başka bir öğe var (dokunuş ona gider). 15.10 "Devam" vakası.
     D. KAPANMADI    : ✕'e GERÇEK fare olayıyla (CDP Input) dokunuldu, katman yerinde kaldı
                       (sayfa başka adrese geçtiyse kapandı sayılır: perde ✕'i Soru Çöz'e götürür).
     E. ✕ KÜÇÜK      : ✕'in dokunma alanı 40 px'ten dar ya da kısa (15.10 elle denemede ekip cevabı
                       bildiriminin ✕'i 19×25 px çıktı — telefonda parmakla tutmuyor).
   Katman sayılan: görünür, ekranda, alanı ekranın %1,5'inden büyük, içinde en az 12 harf yazı.
   pointer-events:none olup yazı taşıyan şerit de sayılır (15.10 telif şeridi vakası: dokunulamıyordu).
   ÜYE SENARYOLARI (sırayla, paralel değil — yerel depo paylaşılıyor): "/_uye/" önekinde Supabase
   kütüphanesi SAHTE istemciyle değişir (oturum açık, tam paket; soru metinleri vitrin sayfalarından,
   ağ yok); paket kapısı, cihaz kapısı, ilerleme ve Nöbetçi notu sitenin GERÇEK koduyla çalışır.
     ders-sgs / ders-smmm : 22 soru → set kutusu (+ smmm'de 10. cevapta Nöbetçi notu), telif + tekrar şeridi
     cihaz-baska          : sunucu "başka ekranda açık" der → yoklama → perde
     cihaz-sinir          : açılışta "cihaz sınırı" perdesi
     ekip                 : oturum jetonu + ekibe_soru cevabı taklit → "Ekibe sorduğun sorunun cevabı geldi"
     duvar                : üyesiz araç sayfasında 5 bedava sorgu biter → duvar
   Her senaryonun BEKLENEN penceresi çıkmazsa kusur K (kapı kör kaldı) — sessiz geçmez.

   MUAF (bildirim değil, kalıcı gezinme/eylem çubuğu — her biri bilerek, eklemek GEREKÇE ister):
     #ttAltMenu (telefon alt menüsü) · #mbar (satın almada "Ödenecek — Devam" çubuğu) ·
     #mrxFab (Araçlar düğmesi) · #ckFiligran (paylaşım koruması filigranı: üyenin e-postası %7 saydam,
     dokunulamaz, bilerek kalıcı) · nav/header içindeki sabit üst çubuk (sitenin başlığı).
   SIRA: katmanlar en üstteki (z-index) önce sınanır — kullanıcı da önce onu kapatır; altındaki ✕ ancak
   üstteki kapandıktan sonra ulaşılabilir olmalı (C kuralı o anda ölçülür).

   BU KAPI ŞUNU GÖRMEZ:
     - Yalnız tıklayınca açılan pencereler (kutu ekranı, Nöbetçi anlatıyor, çizerek çöz) — sayfa
       açılışında ve 22 cevaplık akışta kendiliğinden çıkanlar ölçülür.
     - Sunucu cevabının GERÇEK biçimi: sahte istemci bugünkü alan adlarını taklit eder; sunucu
       cevabı değişirse (ör. cihaz_kontrol durum adı) kapı eskisini sınamaya devam eder.
     - "Kaldığın yerden" şeridi (hesapta kayıt ister), yanlış kutusu "Şimdi çöz" akışı.
     - Gerçek iPhone Safari / Android dokunma katmanı (Chrome başsız fare olayı ölçülür).
     - position:absolute ile sabitlenmiş ya da iframe içindeki katman.

   KULLANIM
     node arac/x-kapisi.js                  bütün sayfalar (rapor veri/x-kapisi-raporu.json)
     node arac/x-kapisi.js a.html b.html    yalnız bunlar (rapor yazılmaz)
     node arac/x-kapisi.js --sinav [--mutasyon]
   ============================================================================ */
'use strict';
const http = require('http');
const fs   = require('fs');
const path = require('path');
const { tarayiciAc, bekle } = require('./tarayici.js');

const KOK       = path.resolve(__dirname, '..');
const PORT      = 8147;                 // kontrast 8137, acilis 8141, mobil tasma 8143
const EKRANLAR  = [{ ad: 'telefon', w: 390, h: 844, mobil: true }, { ad: 'bilgisayar', w: 1366, h: 860, mobil: false }];
const BEKLE_MS  = 3000;
const PARALEL   = 4;
const RAPOR_YOL = path.join(KOK, 'veri', 'x-kapisi-raporu.json');
const EN_AZ_PX  = 40;                   // ✕ dokunma alanı (Apple 44, Google 48 önerir; 40 alt sınır)
const JETON_ANAHTAR = 'sb-bjrleanjpyujtajmazxn-auth-token';   // menu.js ekip bildirimi bu biçimi okur

/* Sayfa içinde koşar: katmanları ve ✕ adaylarını bulur. MUT yalnız öz-sınavın mutasyon turunda dolu. */
const KATMAN_BUL = function (MUT) {
  const vw = innerWidth, vh = innerHeight, out = [];
  const MUAF = /^(ttAltMenu|mbar|mrxFab|ckFiligran)$/;
  const gor = el => { const c = getComputedStyle(el); if (c.display === 'none' || c.visibility === 'hidden' || +c.opacity === 0) return false;
    const r = el.getBoundingClientRect(); return r.width > 2 && r.height > 2 && r.bottom > 0 && r.top < vh && r.right > 0 && r.left < vw; };
  const ad = el => el.tagName.toLowerCase() + (el.id ? '#' + el.id : '') + (typeof el.className === 'string' && el.className.trim() ? '.' + el.className.trim().split(/\s+/).slice(0, 2).join('.') : '');
  const hepsi = document.querySelectorAll('body *');
  for (let i = 0; i < hepsi.length; i++) {
    const el = hepsi[i], c = getComputedStyle(el);
    if (c.position !== 'fixed' || !gor(el)) continue;
    let ic = false; for (let p = el.parentElement; p && p !== document.body; p = p.parentElement) if (getComputedStyle(p).position === 'fixed') { ic = true; break; }
    if (ic) continue;
    if (MUT !== 'muaf' && (MUAF.test(el.id) || el.closest('nav,header') || /^(NAV|HEADER)$/.test(el.tagName))) continue;
    const yazi = (el.innerText || '').replace(/\s+/g, ' ').trim();
    const r = el.getBoundingClientRect();
    if (yazi.length < 12 || (r.width * r.height) / (vw * vh) < 0.015) continue;
    if (MUT === 'pe' && c.pointerEvents === 'none') continue;
    const varlik = b => { const c2 = getComputedStyle(b), r2 = b.getBoundingClientRect(); return c2.display !== 'none' && c2.visibility !== 'hidden' && +c2.opacity !== 0 && r2.width > 2 && r2.height > 2; };   /* ✕ ekran dışında olabilir: B ayrı ölçülür */
    const xler = [...el.querySelectorAll('button,a,[role=button]')].filter(b => varlik(b) &&
      (/^[✕×✖]$/.test((b.textContent || '').trim()) || (MUT === 'kapatYok' ? true : /^kapat$|^close$/i.test((b.getAttribute('aria-label') || '').trim()))));
    const x = xler[0];
    let k = null;
    if (x) {
      const b = x.getBoundingClientRect(), cx = b.left + b.width / 2, cy = b.top + b.height / 2;
      const ekranda = MUT === 'ekran' || (cx > 0 && cx < vw && cy > 0 && cy < vh);
      const h = ekranda ? document.elementFromPoint(Math.min(Math.max(cx, 0), vw - 1), Math.min(Math.max(cy, 0), vh - 1)) : null;
      k = { cx, cy, ekranda, ust: MUT === 'ortme' || (!!h && (h === x || x.contains(h))), ustAd: h ? ad(h) : '', w: Math.round(b.width), h: Math.round(b.height) };
    }
    if (!el.dataset.xKapiNo) el.dataset.xKapiNo = String(Math.random()).slice(2, 10);
    out.push({ oge: ad(el), no: el.dataset.xKapiNo, yazi: yazi.slice(0, 70), x: k, z: parseInt(c.zIndex, 10) || 0, sira: i });
  }
  return out;
};
const VAR_MI = function (no) { const el = document.querySelector('[data-x-kapi-no="' + no + '"]'); if (!el || !el.isConnected) return false;
  const c = getComputedStyle(el); const r = el.getBoundingClientRect(); return c.display !== 'none' && c.visibility !== 'hidden' && +c.opacity !== 0 && r.width > 2 && r.height > 2; };

async function sekmeAc(t, e) {
  const c = await t.cdp.cagir('Target.createTarget', { url: 'about:blank' });
  const a = await t.cdp.cagir('Target.attachToTarget', { targetId: c.targetId, flatten: true });
  await t.cdp.cagir('Emulation.setDeviceMetricsOverride', { width: e.w, height: e.h, deviceScaleFactor: 1, mobile: e.mobil }, a.sessionId);
  await t.cdp.cagir('Page.enable', {}, a.sessionId);
  return { hedef: c.targetId, oturum: a.sessionId };
}
async function js(t, s, ifade) {
  const r = await t.cdp.cagir('Runtime.evaluate', { expression: ifade, returnByValue: true, awaitPromise: true }, s.oturum);
  if (r.exceptionDetails) throw new Error((r.exceptionDetails.exception && r.exceptionDetails.exception.description || r.exceptionDetails.text || 'sayfa ici hata').slice(0, 120));
  return r.result.value;
}
async function dokun(t, s, x, y) {
  for (const type of ['mouseMoved', 'mousePressed', 'mouseReleased'])
    await t.cdp.cagir('Input.dispatchMouseEvent', { type, x, y, button: 'left', clickCount: 1 }, s.oturum);
}
/* Bir ekran durumunu ölçer: her katman için A/B/C/D. Kapanan katmandan sonra yeniden bakar (altında başkası olabilir). */
async function denetle(t, s, etiket, mut) {
  const bulgu = [], bakildi = new Set();
  for (let tur = 0; tur < 8; tur++) {
    let adres0; try { adres0 = await js(t, s, 'location.href'); } catch (e) { break; }
    const kat = (await js(t, s, '(' + KATMAN_BUL.toString() + ')(' + JSON.stringify(mut || '') + ')')).filter(k => !bakildi.has(k.no))
      .sort((a, b) => (mut !== 'sira' ? b.z - a.z : 0) || (mut !== 'sira' ? b.sira - a.sira : a.sira - b.sira));   /* en üstteki önce: kullanıcı da önce onu kapatır */
    if (!kat.length) break;
    const k = kat[0]; bakildi.add(k.no);
    const satir = { yer: etiket, oge: k.oge, yazi: k.yazi };
    if (!k.x) { bulgu.push({ ...satir, kusur: 'A', neden: '✕ YOK' }); continue; }
    if (!k.x.ekranda) { bulgu.push({ ...satir, kusur: 'B', neden: '✕ ekran dışında' }); continue; }
    if (!k.x.ust) { bulgu.push({ ...satir, kusur: 'C', neden: '✕ örtülü (üstünde ' + k.x.ustAd + ')' }); continue; }
    if (mut !== 'boyut' && Math.min(k.x.w, k.x.h) < EN_AZ_PX) { bulgu.push({ ...satir, kusur: 'E', neden: '✕ küçük ' + k.x.w + '×' + k.x.h + ' px (en az ' + EN_AZ_PX + ')' }); continue; }
    if (mut === 'tikla') { bulgu.push({ ...satir, kusur: '', neden: 'kapandı' }); continue; }
    await dokun(t, s, k.x.cx, k.x.cy);
    await bekle(600);
    let adres1 = adres0, kaldi = false;
    try { adres1 = await js(t, s, 'location.href'); if (adres1 === adres0) kaldi = await js(t, s, '(' + VAR_MI.toString() + ')(' + JSON.stringify(k.no) + ')'); } catch (e) { adres1 = '?'; }
    if (kaldi) bulgu.push({ ...satir, kusur: 'D', neden: '✕\'e dokunuldu, kapanmadı' });
    else bulgu.push({ ...satir, kusur: '', neden: adres1 !== adres0 ? 'kapandı (sayfadan çıktı)' : 'kapandı' });
    if (adres1 !== adres0) break;
  }
  return bulgu;
}

/* ---- üye senaryoları: /_uye/ önekinde Supabase kütüphanesi SAHTE istemci (sitenin kendi kodu aynen koşar) ---- */
function sahteSupabase() {
  const K = [];
  for (const f of ['sgs', 'smmm', 'ornek-sgs', 'ornek-smmm']) {
    let satir = null; try { satir = fs.readFileSync(path.join(KOK, 'kaydir/vitrin/' + f + '.html'), 'utf8').split('\n').find(l => l.startsWith('const SORULAR=')); } catch (e) {}
    if (satir) JSON.parse(satir.slice('const SORULAR='.length).replace(/;\s*$/, '')).filter(s => s.siklar && s.dogru && !(s.oyun && s.oyun.tur)).forEach(s => K.push(s));
  }
  if (!K.length) return null;
  const sira = []; for (let n = 0; n < 60; n++) sira.push(Object.assign(JSON.parse(JSON.stringify(K[n % K.length])), { id: 'xk-' + n + '/' + K[n % K.length].id, konu: 'Konu ' + (n % 4) }));
  const fih = sira.map((s, i) => ({ id: s.id, sira: i + 1, ders: s.ders, konu: s.konu, donem: '', zorluk: null, toplam: sira.length }));
  const V = {}; sira.forEach(s => { V[s.id] = s; });
  /* cihaz_kontrol cevabı adresteki ?xkcihaz= ile yönlenir: baska (açılışta tamam, yoklamada "başka ekran") · sinir (açılışta sınır) */
  return `(function(){ var F=${JSON.stringify(fih)}, V=${JSON.stringify(V)}, CIHAZ=(location.search.match(/[?&]xkcihaz=(\\w+)/)||[])[1]||'';
 function sorgu(tablo){ var q={ select:function(){return q;}, eq:function(){return q;}, is:function(){return q;}, in:function(){return q;}, order:function(){return q;}, limit:function(){return q;},
   upsert:function(){return q;}, insert:function(){return q;}, update:function(){return q;},
   maybeSingle:function(){ return Promise.resolve({data:null,error:null}); }, single:function(){ return Promise.resolve({data:null,error:null}); },
   then:function(r,j){ return Promise.resolve({data: tablo==='paket_uyeler' ? [{paket:'tam',bitis:null,dersler:null}] : [], error:null}).then(r,j); } }; return q; }
 var oturum={ access_token:'sahte', user:{ id:'00000000-0000-0000-0000-00000000x0e1', email:'kapi@tetikte.test' } };
 var istemci={ auth:{ getSession:function(){ return Promise.resolve({data:{session:oturum},error:null}); }, getUser:function(){ return Promise.resolve({data:{user:oturum.user},error:null}); },
     onAuthStateChange:function(){ return {data:{subscription:{unsubscribe:function(){}}}}; }, signOut:function(){ return Promise.resolve({}); } },
   from:sorgu,
   rpc:function(ad,p){
     if(ad==='kasa_ders_fihrist') return Promise.resolve({data:F,error:null});
     if(ad==='kasa_soru_parca') return Promise.resolve({data:p.p_ids.map(function(id){return {id:id,veri:V[id]};}),error:null});
     if(ad==='kasa_soru_getir') return Promise.resolve({data:F.slice(p.p_bas,p.p_bas+p.p_adet).map(function(f){return {sira:f.sira,toplam:F.length,veri:V[f.id]};}),error:null});
     if(ad==='cihaz_kontrol'){
       if(CIHAZ==='sinir') return Promise.resolve({data:{durum:'cihaz_siniri',sinir:3,cihazlar:[{etiket:'iPhone · Safari',son_gorulme:'2026-10-14'},{etiket:'Windows · Chrome',son_gorulme:'2026-10-13'},{etiket:'Android · Chrome',son_gorulme:'2026-10-12'}]},error:null});
       if(CIHAZ==='baska' && !p.p_devral) return Promise.resolve({data:{durum:'baska_ekran',aktif_etiket:'iPhone · Safari'},error:null});
       return Promise.resolve({data:{durum:'tamam'},error:null}); }
     return Promise.resolve({data:null,error:null}); },
   channel:function(){ var c={on:function(){return c;},subscribe:function(){return c;}}; return c; }, removeChannel:function(){} };
 window.supabase={ createClient:function(){ return istemci; } }; })();`;
}
const TUR = { '.html': 'text/html; charset=utf-8', '.js': 'text/javascript; charset=utf-8', '.json': 'application/json; charset=utf-8', '.css': 'text/css; charset=utf-8',
  '.svg': 'image/svg+xml', '.png': 'image/png', '.jpg': 'image/jpeg', '.woff2': 'font/woff2', '.webp': 'image/webp' };
function sunucuAc(taklit) {
  return new Promise(coz => {
    const s = http.createServer((q, r) => {
      let yol = decodeURIComponent(q.url.split('?')[0]);
      const uye = yol.startsWith('/_uye/'); if (uye) yol = yol.slice(5);
      if (uye && /\/kutuphane\/supabase-[\d.]+\.js$/.test(yol) && taklit) { r.writeHead(200, { 'Content-Type': TUR['.js'] }); return r.end(taklit); }
      const tam = path.join(KOK, yol);
      if (!tam.startsWith(KOK)) { r.writeHead(403); return r.end(); }
      fs.readFile(tam, (h, v) => { if (h) { r.writeHead(404); return r.end(); } r.writeHead(200, { 'Content-Type': TUR[path.extname(tam).toLowerCase()] || 'application/octet-stream', 'Cache-Control': 'no-store' }); r.end(v); });
    }).listen(PORT, '127.0.0.1', () => coz(s));
  });
}
const goruldu = (t, s, secici) => js(t, s, '(function(){ var e=document.querySelector(' + JSON.stringify(secici) + '); if(!e) return false; var c=getComputedStyle(e); return c.display!=="none"&&c.visibility!=="hidden"; })()').catch(() => false);
const kor = (etiket, oge, ne) => ({ yer: etiket, oge, yazi: '', kusur: 'K', neden: ne + ' çıkmadı — senaryo ölçülemedi (kapı kör kaldı)' });
/* Her senaryo: { ad, yol, hazirla?(t,s) (sayfa açılmadan), akis(t,s,etiket) -> bulgu[] }. Beklenen pencere görülmezse K. */
const SENARYOLAR = [
  { ad: 'ders-sgs', yol: '_uye/kaydir/sgs/turkce.html', akis: (t, s, e) => dersAkisi(t, s, e, false) },
  { ad: 'ders-smmm', yol: '_uye/kaydir/smmm/finansal-muhasebe.html', akis: (t, s, e) => dersAkisi(t, s, e, true) },
  { ad: 'cihaz-baska', yol: '_uye/kaydir/smmm/finansal-muhasebe.html?xkcihaz=baska', akis: async (t, s, e) => {
      await bekle(10600);   /* cihaz-kapisi.js iki yoklama arası en az 10 sn */
      await js(t, s, 'window.dispatchEvent(new Event("focus")); true'); await bekle(1500);
      const var_ = await goruldu(t, s, '#ckPerde');
      return var_ ? await denetle(t, s, e) : [kor(e, 'div#ckPerde', '"Hesabın başka bir cihazda açıldı" perdesi')]; } },
  { ad: 'cihaz-sinir', yol: '_uye/kaydir/smmm/finansal-muhasebe.html?xkcihaz=sinir', akis: async (t, s, e) => {
      const var_ = await goruldu(t, s, '#ckPerde');
      return var_ ? await denetle(t, s, e) : [kor(e, 'div#ckPerde', '"Cihaz sınırına ulaştın" perdesi')]; } },
  // 21.10: ?ana=1 - 96665e24 (18.10) oturumlu uyeyi index.html'den ogrenci.html'e yonlendiriyor (menu.js orada bildirimi bilerek
  //   gostermez); senaryo yonlendirmeye takilip 'bildirim cikmadi, olculemedi' diyordu. Uye ana sayfayi ?ana=1 ile (logo bagi) gorur.
  { ad: 'ekip', yol: '_uye/index.html?ana=1', hazirla: async (t, s) => {
      /* menu.js: yerel depodaki oturum jetonuyla ekibe_soru REST isteği; istek taklit edilir (ağ yok) */
      await t.cdp.cagir('Page.addScriptToEvaluateOnNewDocument', { source: '(function(){ try{ localStorage.setItem(' + JSON.stringify(JETON_ANAHTAR) + ', JSON.stringify({access_token:"sahte",user:{id:"00000000-0000-0000-0000-0000000000e1"}})); }catch(e){}' +
        ' var f=window.fetch; window.fetch=function(u,o){ if(/\\/rest\\/v1\\/ekibe_soru/.test(String(u))) return Promise.resolve(new Response("[{\\"id\\":1}]",{status:200,headers:{"Content-Type":"application/json"}})); return f.apply(this,arguments); }; })();' }, s.oturum); },
    akis: async (t, s, e) => {
      const var_ = await goruldu(t, s, '#ttEkipBildirim');
      return var_ ? await denetle(t, s, e) : [kor(e, 'div#ttEkipBildirim', '"Ekibe sorduğun sorunun cevabı geldi" bildirimi')]; } },
  { ad: 'duvar', yol: 'asgari-kv.html', akis: async (t, s, e) => {
      await js(t, s, '(function(){ for(var i=0;i<9;i++) try{ ttSorguKapisi("xkapi"); }catch(x){} return true; })()').catch(() => false);
      await bekle(400);
      const var_ = await goruldu(t, s, '#ttDuvar');
      return var_ ? await denetle(t, s, e) : [kor(e, 'div#ttDuvar', '"5 bedava sorgu" duvarı')]; } }
];
async function dersAkisi(t, s, etiket, notuBekle) {
  const bulgu = await denetle(t, s, etiket + ' [açılış]');
  for (let i = 0; i < 22; i++) {
    await js(t, s, '(function(i){ var k=document.querySelectorAll("#akis > .kart")[i]; if(!k) return false; k.scrollIntoView(); var s=k.querySelectorAll(".sik"); var b=s[i%3===0?1:0]; if(b) b.click(); return true; })(' + i + ')').catch(() => false);
    await bekle(120);
    if (i === 10) {
      await bekle(2400);   /* nobetci-notu.js 10. cevaptan 1,4 sn sonra açar */
      const nn = await goruldu(t, s, '#ttNn.acik');
      bulgu.push(...await denetle(t, s, etiket + ' [11. cevap sonrası]'));
      if (notuBekle && !nn) bulgu.push(kor(etiket + ' [11. cevap sonrası]', 'div#ttNn', 'Nöbetçi notu'));
    }
  }
  /* set kutusu 20. kart GEÇİLİNCE (kaydırma olayıyla) açılır; arka sekmede zamanlayıcı kısıldığından açıkça kaydırılır */
  /* şablon: i = round(akis.scrollTop / akis.clientHeight); i % 20 === 0 iken biten setin özeti (kaydir-coz.ps1 "10.10") */
  const sayac = await js(t, s, '(function(){ var k=document.querySelectorAll("#akis > .kart"), a=document.getElementById("akis"); if(a){ a.style.scrollBehavior="auto"; a.style.scrollSnapType="none"; a.scrollTo({top:20*a.clientHeight,behavior:"instant"}); a.dispatchEvent(new Event("scroll")); } return k.length; })()').catch(() => 0);
  await bekle(2200);
  const sk = await js(t, s, '!!document.querySelector(".setOzet")').catch(() => false);
  bulgu.push(...await denetle(t, s, etiket + ' [22. cevap sonrası]'));
  if (!(sayac >= 21 && sk)) bulgu.push(kor(etiket + ' [22. cevap sonrası]', 'div.setOzet', 'set kutusu (kart ' + sayac + ')'));
  return bulgu;
}

/* ---- öz-sınav ---- */
const SAR = (govde, w) => 'data:text/html;charset=utf-8,' + encodeURIComponent('<!doctype html><html><head><meta name="viewport" content="width=device-width,initial-scale=1"><style>body{margin:0;font:16px sans-serif;height:2000px}</style></head><body>' + govde + '</body></html>');
const BANT = (ic, ek) => '<div id="b" style="position:fixed;left:0;right:0;bottom:0;padding:14px 50px 14px 14px;background:#eee;' + (ek || '') + '">Bildirim: bu bir deneme bildirimidir, okunur.' + ic + '</div>';
const KAPAT = '<button aria-label="Kapat" style="position:absolute;right:4px;top:4px;width:40px;height:40px" onclick="this.parentNode.remove()">✕</button>';
const VAKALAR = [
  { ad: '✕\'li bildirim, dokununca kapanır', kusur: '', html: BANT(KAPAT) },
  { ad: '✕\'siz bildirim (15.10 Meta bandı)', kusur: 'A', html: BANT('<button>Reddet</button><button>Kabul et</button>') },
  { ad: '✕ var, üstünü başka katman örtüyor (15.10 "Devam" vakası)', kusur: 'C',
    html: BANT(KAPAT) + '<div style="position:fixed;right:0;bottom:0;width:120px;height:120px;background:#c00;z-index:9"></div>' },
  { ad: '✕ var, dokununca kapanmıyor', kusur: 'D', html: BANT('<button aria-label="Kapat" style="position:absolute;right:4px;top:4px;width:40px;height:40px">✕</button>') },
  { ad: '✕ ekranın dışında (uzun pencere, ✕ üstte kaybolmuş)', kusur: 'B',
    html: '<div id="b" style="position:fixed;left:0;right:0;top:-300px;height:900px;background:#eee;padding:10px">Uzun pencere yazısı burada okunur.<button aria-label="Kapat" style="position:absolute;right:4px;top:4px;width:40px;height:40px" onclick="this.parentNode.remove()">✕</button></div>' },
  { ad: 'dokunulamaz yazılı şerit ✕\'siz (15.10 telif şeridi)', kusur: 'A', html: BANT('', 'pointer-events:none') },
  { ad: 'alt menü (#ttAltMenu) — bildirim değil, yanlış alarm olmamalı', kusur: null,
    html: '<div id="ttAltMenu" style="position:fixed;left:0;right:0;bottom:0;height:64px;background:#eee">Ana sayfa Sınavlar Yanlışlar Hesabım</div>' },
  { ad: 'küçük sabit düğme (tema) — yanlış alarm olmamalı', kusur: null, html: '<button style="position:fixed;left:10px;bottom:10px;width:34px;height:34px">☾</button>' },
  { ad: '✕ 19×25 px (15.10 ekip cevabı bildirimi)', kusur: 'E',
    html: BANT('<button aria-label="Kapat" style="position:absolute;right:4px;top:4px;width:19px;height:25px;padding:0" onclick="this.parentNode.remove()">✕</button>') },
  { ad: 'iki pencere üst üste: önce üstteki kapanır, alttakinin ✕\'i sonra açılır (15.10 set kutusu + Nöbetçi notu)', kusur: '',
    html: BANT(KAPAT) + '<div id="u" style="position:fixed;inset:0;z-index:50;background:rgba(0,0,0,.4)"><div style="background:#fff;margin:40px;padding:20px;position:relative">Üstteki pencere yazısı burada.' +
      '<button aria-label="Kapat" style="position:absolute;right:4px;top:4px;width:44px;height:44px" onclick="document.getElementById(\'u\').remove()">✕</button></div></div>' },
  { ad: '✕ yazısız "Kapat" etiketli düğme kabul', kusur: '', html: BANT('<button aria-label="Kapat" style="position:absolute;right:4px;top:4px;width:40px;height:40px" onclick="this.parentNode.remove()">×</button>') },
  { ad: '✕ sayfadan çıkarıyor (perde → Soru Çöz) = kapandı', kusur: '',
    html: '<div id="b" style="position:fixed;inset:0;background:#fff;padding:20px">Bu bölüm pakete dahil, giriş yap.<a aria-label="Kapat" href="about:blank#ok" style="position:absolute;right:8px;top:8px;width:44px;height:44px">✕</a></div>' }
];
const MUTASYONLAR = ['kapatYok', 'ortme', 'tikla', 'ekran', 'pe', 'muaf', 'boyut', 'sira'];
async function sinav(t, mutasyonMu) {
  const s = await sekmeAc(t, EKRANLAR[0]);
  const tur = async (mut) => {
    let dogru = 0; const yanlis = [];
    for (const v of VAKALAR) {
      await t.cdp.cagir('Page.navigate', { url: SAR(v.html) }, s.oturum); await bekle(300);
      const b = await denetle(t, s, v.ad, mut);
      const olculen = v.kusur === null ? (b.length ? 'katman sayıldı' : null) : (b[0] ? b[0].kusur : 'katman bulunmadı');
      if (olculen === v.kusur) dogru++; else yanlis.push(v.ad + ' (beklenen ' + JSON.stringify(v.kusur) + ', ölçülen ' + JSON.stringify(olculen) + ')');
    }
    return { dogru, yanlis };
  };
  const temel = await tur('');
  console.log('✕ KAPISI OZ-SINAVI: ' + temel.dogru + '/' + VAKALAR.length + ' vaka dogru');
  temel.yanlis.forEach(y => console.log('  YANLIS: ' + y));
  let kod = temel.yanlis.length ? 1 : 0;
  if (mutasyonMu) {
    let dusen = 0;
    for (const m of MUTASYONLAR) {
      const r = await tur(m), dustu = r.yanlis.length > 0; if (dustu) dusen++;
      console.log('  MUTASYON ' + m.padEnd(9) + (dustu ? ' -> sinav KIRMIZI (iyi)' : ' -> sinav YESIL kaldi (SINAV EKSIK)'));
    }
    console.log('  Mutasyon: ' + dusen + '/' + MUTASYONLAR.length + ' -> KIRMIZI');
    if (dusen < MUTASYONLAR.length) kod = 1;
  }
  try { await t.cdp.cagir('Target.closeTarget', { targetId: s.hedef }); } catch (e) {}
  return kod;
}

function raporYaz(icerik) {
  try {
    const yeni = JSON.stringify({ tarih: new Date().toISOString().slice(0, 19).replace('T', ' '), ...icerik }, null, 2);
    const notrle = j => j.replace(/("tarih"\s*:\s*)"[^"]*"/, '$1"@@ZAMAN@@"').replace(/\r\n/g, '\n').trim();
    let eski = null; try { eski = fs.readFileSync(RAPOR_YOL, 'utf8'); } catch (e) {}
    if (eski !== null && notrle(eski) === notrle(yeni)) return;
    fs.writeFileSync(RAPOR_YOL, yeni + '\n');
  } catch (e) { console.log('  (rapor yazilamadi: ' + e.message + ')'); }
}

(async function () {
  const arg = process.argv.slice(2);
  const ci = process.env.CI === 'true' || process.env.GITHUB_ACTIONS === 'true';
  const t = await tarayiciAc();
  if (t.hata) {
    console.log('✕ KAPISI: KOR — tarayici acilmadi (' + t.hata + ').');
    if (!arg.includes('--sinav')) raporYaz({ durum: 'KOR', sebep: t.hata, ci });
    process.exit(ci ? 1 : 0);
  }
  if (arg.includes('--sinav')) {
    let kod = 1;
    try { kod = await sinav(t, arg.includes('--mutasyon')); } catch (e) { console.log('OZ-SINAV KOR — ' + e.message); }
    t.kapat(); process.exit(kod);
  }
  const secili = arg.filter(a => a.endsWith('.html'));
  const sayfalar = secili.length ? secili : fs.readdirSync(KOK).filter(f => f.endsWith('.html')).filter(f => !/-yedek|^_/.test(f)).sort();
  /* --senaryo ad,ad : yalnız bu üye senaryoları (deneme için); seçili sayfa verilince senaryo koşmaz */
  const sIdx = arg.indexOf('--senaryo'), sAd = sIdx > -1 ? String(arg[sIdx + 1] || '').split(',') : null;
  const senaryolar = secili.length && !sAd ? [] : SENARYOLAR.filter(x => !sAd || sAd.includes(x.ad));
  const kokSayfalar = sAd ? [] : sayfalar.filter(f => !/^kaydir\//.test(f));
  const taklit = sahteSupabase();
  const sunucu = await sunucuAc(taklit);
  const bitir = kod => { try { t.kapat(); } catch (e) {} try { sunucu.close(); } catch (e) {} process.exit(kod); };

  const isler = [];
  for (const e of EKRANLAR) for (const f of kokSayfalar) isler.push({ e, f });
  const sOlcum = senaryolar.length * EKRANLAR.length;
  console.log('✕ KAPISI: ' + kokSayfalar.length + ' sayfa + ' + senaryolar.length + ' üye senaryosu × ' + EKRANLAR.map(e => e.ad + ' ' + e.w).join(' + ') + ' = ' + (isler.length + sOlcum) + ' ölçüm.');
  const bulgu = [], korList = [];
  let sira = 0;
  const isci = async () => {
    while (sira < isler.length) {
      const is = isler[sira++]; const etiket = is.e.ad + ' ' + is.f; let s = null;
      try {
        s = await sekmeAc(t, is.e);
        await t.cdp.cagir('Page.navigate', { url: 'http://127.0.0.1:' + PORT + '/' + is.f + '?xkapi=' + Date.now() }, s.oturum);
        await bekle(BEKLE_MS);
        bulgu.push(...await denetle(t, s, etiket));
      } catch (e) { korList.push({ yer: etiket, sebep: String(e.message).slice(0, 100) }); }
      finally { if (s) try { await t.cdp.cagir('Target.closeTarget', { targetId: s.hedef }); } catch (e) {} }
    }
  };
  await Promise.all(Array.from({ length: PARALEL }, isci));
  /* üye senaryoları SIRAYLA: yerel depo (oturum jetonu, sayaç) sekmeler arasında paylaşılıyor; her senaryodan sonra silinir */
  for (const e of EKRANLAR) for (const sn of senaryolar) {
    const etiket = e.ad + ' [' + sn.ad + '] ' + sn.yol.replace(/^_uye\//, ''); let s = null;
    try {
      if (!taklit) throw new Error('sahte istemci kurulamadı (kaydir/vitrin SORULAR okunamadı)');
      s = await sekmeAc(t, e);
      if (sn.hazirla) await sn.hazirla(t, s);
      await t.cdp.cagir('Page.navigate', { url: 'http://127.0.0.1:' + PORT + '/' + sn.yol + (sn.yol.includes('?') ? '&' : '?') + 'xkapi=' + Date.now() }, s.oturum);
      await bekle(BEKLE_MS + 1000);
      bulgu.push(...await sn.akis(t, s, etiket));
    } catch (er) { korList.push({ yer: etiket, sebep: String(er.message).slice(0, 100) }); }
    finally {
      if (s) { try { await js(t, s, 'try{localStorage.clear();sessionStorage.clear();}catch(e){} true'); } catch (er) {}
               try { await t.cdp.cagir('Target.closeTarget', { targetId: s.hedef }); } catch (er) {} }
    }
  }
  const kor_ = korList;

  const kusur = bulgu.filter(b => b.kusur), temiz = bulgu.filter(b => !b.kusur);
  const cesit = {}; temiz.forEach(b => { cesit[b.oge] = (cesit[b.oge] || 0) + 1; });
  const toplam = isler.length + sOlcum;
  if (!secili.length && !sAd) raporYaz({
    durum: kusur.length ? 'KIRMIZI' : (kor_.length ? 'KOR' : 'YESIL'), ci,
    ekranlar: EKRANLAR.map(e => e.ad + ' ' + e.w + 'x' + e.h), olcum_toplam: toplam, KOR: kor_.length,
    senaryolar: senaryolar.map(x => x.ad),
    katman_sayisi: bulgu.length, kusurlu: kusur.length, kapanan_katman_cesidi: cesit,
    kusurlar: kusur, olculemeyenler: kor_
  });
  console.log('  Ölçülen ' + (toplam - kor_.length) + '/' + toplam + (kor_.length ? ' · KOR ' + kor_.length : '') +
              ' · katman ' + bulgu.length + ' · ✕ ile kapanan ' + temiz.length + ' · KUSUR ' + kusur.length);
  Object.keys(cesit).sort().forEach(k => console.log('    kapandı ' + String(cesit[k]).padStart(3) + ' × ' + k));
  if (arg.includes('--ayrinti')) for (const b of temiz) console.log('    ✓ ' + b.yer + ' · <' + b.oge + '> ' + b.neden);
  for (const b of kusur.slice(0, 25)) console.log('  KIRMIZI [' + b.kusur + '] ' + b.yer + ' · <' + b.oge + '> ' + b.neden + '  "' + b.yazi.slice(0, 50) + '"');
  for (const k of kor_) console.log('  KOR ' + k.yer + '  <- ' + k.sebep);
  if (kusur.length || kor_.length) { console.log('  Ayrinti: veri/x-kapisi-raporu.json — her bildirim/pencere sağ üstte ✕ ile kapanmalı (Cem 15.10).'); bitir(1); }
  console.log('  Temiz — ✕\'siz ya da ✕\'i çalışmayan katman yok.');
  bitir(0);
})().catch(e => { console.log('✕ KAPISI: KOR — ' + e.message); process.exit(1); });
