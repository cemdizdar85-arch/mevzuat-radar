/* Tetikte — dönüşüm ölçümü (Meta Pixel + Conversions API + GoatCounter aynası).
   29.09.2026, Cem: "dönüşüm kodları ve Instagram reklam işleri — ne gerekiyorsa yapalım".

   menu.js tarafından yüklenir (PERDE-BASI'ndan ÖNCE → perde açıkken de çalışır).

   ⛔ PIKSEL_ID BOŞKEN: Meta'ya HİÇBİR ŞEY gitmez, çerez kurulmaz, onay bandı ÇIKMAZ.
      Yalnız dönüşümler GoatCounter'a olay olarak yazılır (çerezsiz, IP saklamaz —
      gizlilik politikasının bugünkü "çerez kullanmaz" sözüyle uyumlu).
   ✅ PIKSEL_ID DOLUNCA (AYNI commit'te gizlilik-politikasi.html §3 + kvkk.html §4 güncellenir):
      - alt bantta "Kabul et / Reddet" (eşit ağırlık); karar localStorage 'ttReklamOnay'.
      - Kabul → fbevents.js yüklenir, PageView + dönüşüm olayları hem tarayıcıdan (fbq)
        hem sunucudan (edge 'meta-olay' → Conversions API) aynı event_id ile gider,
        Meta ikisini tekilleştirir. E-posta Meta'ya yalnız SHA-256 özetiyle gider.
      - Ret / karar yok → Meta'ya hiçbir şey gitmez (sunucu yolu da KAPALI: KVKK yurt dışı
        aktarım rızası tarayıcıdaki onaya bağlı).

   DÖNÜŞÜMLER sayfalara dokunmadan fetch kancasıyla yakalanır (başarılı yanıttan SONRA):
     quick-task konu 'ACILIS PERDESI' | 'ON KAYIT'         → Lead (içerik: perde / on-kayit)
     quick-task 'SEVIYE TESTI' + edge karne-gonder          → Lead (seviye-testi)
     quick-task 'CANLI DENEME kayit'                        → Lead (canli-deneme)
     quick-task 'YENİ SİPARİŞ' | 'YENİ ABONELİK'            → InitiateCheckout (value = tutar)
     auth/v1/signup                                         → CompleteRegistration (eposta)
     PUT auth/v1/user gövdesinde 'kosul_kabul' (ilk Google) → CompleteRegistration (google)
   ⚠ Purchase BURADA ATILMAZ: sipariş 'odeme_bekliyor' doğar (havale). Para gelince
     ttDonusum('Purchase',{value,currency:'TRY'}) — yeri iyzico/onay akışı kurulunca belli olur.
   Aynı içerik aynı sayfa yüklemesinde bir kez sayılır (karne + quick-task çifti). */
(function(){
if (window.ttDonusum) return;

var PIKSEL_ID = '1369179971705020';   /* 09.10.2026 Cem "kur o zaman" (B, KVKK m.9 riski Cem'de): dataset "Tetikte", portföy Dizdar Denetim, reklam hesabı Tetikte Reklam */
/* 09.10.2026: edge 'meta-olay' CANLIDA YOK (?tani=1 → NOT_FOUND) ve META_CAPI_TOKEN üretilmedi → sunucu yolu KAPALI.
   Açmak: edge yayınla + secret'lar (META_PIXEL_ID, META_CAPI_TOKEN) + ?tani=1 ile ölç, sonra true. */
var CAPI_ACIK = false;
var CAPI_UC = 'https://bjrleanjpyujtajmazxn.supabase.co/functions/v1/meta-olay';
var SB_ANAHTAR = 'sb_publishable_kTZpYwrL7skw8Ryj5Vs8_Q_-5_Fhkcg';
var ONAY_ANAHTAR = 'ttReklamOnay';

function ls(k, v){
  try { if (v === undefined) return localStorage.getItem(k); localStorage.setItem(k, v); } catch(e) { return null; }
}
function onayVar(){ return !!PIKSEL_ID && ls(ONAY_ANAHTAR) === '1'; }

/* ---- GoatCounter aynası (her zaman; kişisel veri yok, yalnız yol) ---- */
var gcKuyruk = [];
function gcSay(ad, icerik){
  var yol = 'donusum/' + ad + (icerik ? '/' + icerik : '');
  if (window.goatcounter && typeof window.goatcounter.count === 'function') {
    window.goatcounter.count({ path: yol, title: 'dönüşüm: ' + ad, event: true });
  } else if (gcKuyruk.length < 12) {
    gcKuyruk.push(yol);
    if (gcKuyruk.length === 1) setTimeout(function gcBosalt(){
      if (window.goatcounter && window.goatcounter.count) {
        gcKuyruk.splice(0).forEach(function(y){ window.goatcounter.count({ path: y, title: 'dönüşüm (gecikmeli)', event: true }); });
      } else if (gcKuyruk.length) { setTimeout(gcBosalt, 1500); }
    }, 1500);
  }
}

/* ---- Meta ---- */
var pikselYuklendi = false, bekleyen = [];
function pikselYukle(){
  if (pikselYuklendi || !onayVar()) return;
  pikselYuklendi = true;
  /* Meta'nın resmî yükleyicisi (fbevents.js), okunur biçimde */
  var f = window.fbq = function(){ f.callMethod ? f.callMethod.apply(f, arguments) : f.queue.push(arguments); };
  if (!window._fbq) window._fbq = f;
  f.push = f; f.loaded = true; f.version = '2.0'; f.queue = [];
  var s = document.createElement('script'); s.async = true; s.src = 'https://connect.facebook.net/en_US/fbevents.js';
  (document.head || document.documentElement).appendChild(s);
  window.fbq('init', PIKSEL_ID);
  var pv = olayKimligi();
  window.fbq('track', 'PageView', {}, { eventID: pv });
  capiGonder('PageView', pv, {}, '');
  bekleyen.splice(0).forEach(function(o){ metaGonder(o[0], o[1], o[2]); });
}

function olayKimligi(){
  try { if (crypto.randomUUID) return crypto.randomUUID(); } catch(e) {}
  return Date.now().toString(36) + Math.random().toString(36).slice(2, 10);
}
function cerez(ad){
  var m = document.cookie.match(new RegExp('(?:^|; )' + ad + '=([^;]*)'));
  return m ? decodeURIComponent(m[1]) : '';
}
function ozet(eposta){
  eposta = (eposta || '').trim().toLowerCase();
  if (!eposta || !window.crypto || !crypto.subtle || !window.TextEncoder) return Promise.resolve('');
  return crypto.subtle.digest('SHA-256', new TextEncoder().encode(eposta)).then(function(b){
    return Array.prototype.map.call(new Uint8Array(b), function(x){ return ('0' + x.toString(16)).slice(-2); }).join('');
  }, function(){ return ''; });
}
function capiGonder(ad, kimlik, veri, eposta){
  if (!CAPI_ACIK) return;
  ozet(eposta).then(function(em){
    try {
      /* fetch değil sarılmamış asıl fetch: kanca kendi isteğini yeniden saymasın */
      asilFetch(CAPI_UC, { method: 'POST', keepalive: true,
        headers: { 'Content-Type': 'application/json', apikey: SB_ANAHTAR, Authorization: 'Bearer ' + SB_ANAHTAR },
        body: JSON.stringify({ olay: ad, event_id: kimlik, url: location.href, fbp: cerez('_fbp'), fbc: cerez('_fbc'),
          em: em, value: veri.value, currency: veri.currency, content_name: veri.content_name }) })
        .catch(function(){});
    } catch(e) {}
  });
}
function metaGonder(ad, veri, eposta){
  var kimlik = olayKimligi();
  var standart = /^(Lead|CompleteRegistration|InitiateCheckout|Purchase|ViewContent|AddPaymentInfo|Subscribe)$/.test(ad);
  window.fbq(standart ? 'track' : 'trackCustom', ad, veri, { eventID: kimlik });
  capiGonder(ad, kimlik, veri, eposta);
}

var sayilan = {};
function ttDonusum(ad, veri, eposta){
  veri = veri || {};
  var anahtar = ad + '|' + (veri.content_name || '');
  if (sayilan[anahtar]) return;
  sayilan[anahtar] = 1;
  gcSay(ad, veri.content_name);
  if (!onayVar()) return;
  if (!pikselYuklendi) { bekleyen.push([ad, veri, eposta]); return; }
  metaGonder(ad, veri, eposta);
}
window.ttDonusum = ttDonusum;

/* ---- fetch kancası ---- */
var asilFetch = window.fetch ? window.fetch.bind(window) : null;
function tutarOku(t){
  var m = /([\d.]+(?:,\d+)?)\s*TL/.exec(t || '');
  if (!m) return undefined;
  var n = parseFloat(m[1].replace(/\./g, '').replace(',', '.'));
  return isFinite(n) ? n : undefined;
}
function eslestir(url, yontem, govde){
  var j = null;
  try { j = typeof govde === 'string' ? JSON.parse(govde) : null; } catch(e) {}
  j = j || {};
  var eposta = j.email || j.eposta || '';
  if (/\/functions\/v1\/quick-task/.test(url)) {
    var k = String(j.subject || '');
    /* 06.10: bildirim konuları Türkçeleşti; eski yazım da tanınır (önbellekteki eski sayfalar) */
    if (/^(ACILIS PERDESI|Açılış perdesi)/i.test(k)) return ['Lead', { content_name: 'perde' }, eposta];
    if (/^(ON KAYIT|Ön kayıt)/i.test(k))       return ['Lead', { content_name: 'on-kayit' }, eposta];
    if (/^(SEVIYE TESTI|Seviye testi)/i.test(k))   return ['Lead', { content_name: 'seviye-testi' }, eposta];
    if (/^(CANLI DENEME kayit|Canlı deneme kaydı)/i.test(k)) return ['Lead', { content_name: 'canli-deneme' }, eposta];
    if (/^YENİ (SİPARİŞ|ABONELİK)/.test(k)) {
      var v = tutarOku(k);
      return ['InitiateCheckout', v !== undefined ? { content_name: /ABONELİK/.test(k) ? 'radar-abonelik' : 'soru-bankasi', value: v, currency: 'TRY' }
                                                  : { content_name: /ABONELİK/.test(k) ? 'radar-abonelik' : 'soru-bankasi' }, eposta];
    }
    return null;
  }
  if (/\/functions\/v1\/karne-gonder/.test(url)) return ['Lead', { content_name: 'seviye-testi' }, eposta];
  if (/\/auth\/v1\/signup/.test(url)) return ['CompleteRegistration', { content_name: 'eposta' }, eposta];
  if (/\/auth\/v1\/user(\?|$)/.test(url) && /^PUT$/i.test(yontem || '') && /kosul_kabul/.test(govde || '')) {
    return ['CompleteRegistration', { content_name: 'google' }, ''];
  }
  return null;
}
if (asilFetch) {
  window.fetch = function(girdi, ayar){
    var p = asilFetch(girdi, ayar);
    try {
      var url = typeof girdi === 'string' ? girdi : (girdi && girdi.url) || '';
      var yontem = (ayar && ayar.method) || (girdi && girdi.method) || 'GET';
      var govde = ayar && typeof ayar.body === 'string' ? ayar.body : '';
      var es = govde || /auth\/v1\/signup/.test(url) ? eslestir(url, yontem, govde) : null;
      if (es) p.then(function(r){ if (r && r.ok) ttDonusum(es[0], es[1], es[2]); }, function(){});
    } catch(e) {}
    return p;
  };
}

/* ---- onay bandı (yalnız PIKSEL_ID doluyken ve karar yokken) ---- */
function bantGoster(){
  if (!PIKSEL_ID || document.getElementById('ttReklamBant')) return;
  var d = document.createElement('div');
  d.id = 'ttReklamBant';
  d.setAttribute('role', 'dialog'); d.setAttribute('aria-label', 'Reklam ölçümü izni');
  /* perdenin (z-index 99999) üstünde: perde açıkken de karar verilebilsin */
  d.style.cssText = 'position:fixed;left:12px;right:12px;bottom:12px;z-index:100000;max-width:640px;margin:0 auto;'
    + 'background:#12151c;color:#e8eaed;border:1px solid #2c323d;border-radius:12px;padding:14px 16px;'
    + 'font:13.5px/1.55 -apple-system,"Segoe UI",system-ui,Roboto,Arial,sans-serif;box-shadow:0 8px 30px rgba(0,0,0,.45)';
  d.innerHTML = '<p style="margin:0 0 10px">Instagram/Facebook reklamlarımızın işe yarayıp yaramadığını ölçmek için '
    + '<b>Meta pikselini</b> kullanmak istiyoruz. Kabul edersen bu tarayıcıya Meta çerezi konur ve ziyaretin '
    + 'yurt dışındaki Meta sunucularına aktarılır. Reddedersen site aynen çalışır. '
    + '<a href="/gizlilik-politikasi.html#cerez" style="color:#ffc24b">Ayrıntı</a></p>'
    + '<div style="display:flex;gap:8px;flex-wrap:wrap">'
    + '<button type="button" data-k="0" style="flex:1;min-width:120px;min-height:44px;background:#1b2029;color:#e8eaed;border:1px solid #3a414e;border-radius:10px;font:inherit;font-weight:700;cursor:pointer">Reddet</button>'
    + '<button type="button" data-k="1" style="flex:1;min-width:120px;min-height:44px;background:#1b2029;color:#e8eaed;border:1px solid #3a414e;border-radius:10px;font:inherit;font-weight:700;cursor:pointer">Kabul et</button>'
    + '</div>';
  d.addEventListener('click', function(e){
    var b = e.target.closest && e.target.closest('button[data-k]');
    if (!b) return;
    ls(ONAY_ANAHTAR, b.getAttribute('data-k'));
    d.parentNode.removeChild(d);
    if (b.getAttribute('data-k') === '1') pikselYukle();
  });
  document.body.appendChild(d);
}
/* Gizlilik sayfasındaki "tercihimi değiştir" bağlantısı için */
window.ttReklamOnayDegistir = function(){
  var eski = ls(ONAY_ANAHTAR);
  try { localStorage.removeItem(ONAY_ANAHTAR); } catch(e) {}
  if (eski === '1') { location.reload(); return; }   /* yüklenmiş pikseli sökmenin temiz yolu */
  bantGoster();
};

function basla(){
  if (!PIKSEL_ID) return;
  var k = ls(ONAY_ANAHTAR);
  if (k === '1') pikselYukle();
  else if (k !== '0') bantGoster();
}
if (document.body) basla(); else document.addEventListener('DOMContentLoaded', basla);

/* Sayfa bazlı niyet olayı: satın alma sayfasına giriş */
if (/(?:^|\/)(satin-al|radar-fiyat)\.html$/.test(location.pathname)) {
  ttDonusum('ViewContent', { content_name: /radar/.test(location.pathname) ? 'radar-fiyat' : 'satin-al' });
}
})();
