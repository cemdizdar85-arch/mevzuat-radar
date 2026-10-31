/* katman-tarama.js — UYGULAMA PROVASI İÇİN ✕ VE KATMAN TARAMASI (28.10.2026, Cem: "telefonda çarpı geldi basamadık ilerleyemedik
 * olmasın, tek tek Apple ve Play Store incele")
 *
 * cihaz-akis.js (Android, CDP) ve cihaz-akis-ios.js (iOS, prova köprüsü) bunu kullanır. Sayfaya gönderilen ifadeler ES5'tir
 * (iOS WebKit). Üç ölçüm:
 *   1. ✕ ADAYI: bilinen ✕ sınıfları + metni yalnız ✕/×/✖ olan ya da aria-label'ı "kapat/close" olan her görünür düğme.
 *      Her biri: dokunma alanı ≥ 24 px mi (44 altı UYARI) · o noktada en üstte kendisi mi (örtülü değil) · gerçek dokunuştan
 *      sonra KAYBOLDU mu (kendisi ya da kapsadığı katman). Kapanmayan/örtülü ✕ = DUSTU.
 *   2. ÇIKIŞSIZ KATMAN: ekranın ≥ %25'ini kaplayan, en üstte duran sabit (fixed) katman, içinde dokunulabilir hiçbir düğme ya da
 *      bağlantı yoksa = DUSTU ("ilerleyemedik"). Alt menü (#sekmeCubugu) sayılmaz.
 *   3. SÜRÜM ŞERİDİ: eski sürüm taklidiyle (TT_KATALOG.surum) surum-uyari.js yeniden yüklenir; şerit çizilmeli ve ✕ kapatmalı.
 * GÖRMEZ: yalnız girişli üyede çıkan katmanlar (giriş otomasyona verilmez) · 12 sn seviye bildirimi · Nöbetçi notu (10 cevapta bir)
 *   · ✕'i olmayan ama "Tamam/Kapat" yazılı düğmeyle kapanan katmanın o düğmesinin gerçekten kapattığı (çıkış var sayılır).
 */
'use strict';
const X_SINIF = '.tuKapat,[aria-label="Kapat"],.ttSeritX,.pk-x,#kutuKapat,.oyunX,.kagitKapat,#ttSurumX,.op-x';

/* görünür ✕ adaylarını işaretler (data-kt=n) ve sayısını döndürür */
const ADAY_ISARETLE = `(function(){
  var X=${JSON.stringify(X_SINIF)}, n=0;
  [].slice.call(document.querySelectorAll('[data-kt]')).forEach(function(e){ e.removeAttribute('data-kt'); });
  var adaylar=[].slice.call(document.querySelectorAll(X)).concat([].slice.call(document.querySelectorAll('button,a,[role=button]')).filter(function(e){
    var t=(e.innerText||'').replace(/\\s+/g,''); var a=(e.getAttribute('aria-label')||'');
    return /^[✕×✖]$/.test(t) || /kapat|close/i.test(a); }));
  adaylar.forEach(function(e){ if(e.hasAttribute('data-kt')) return; var r=e.getBoundingClientRect(), s=getComputedStyle(e);
    if(r.width>0&&r.height>0&&r.top<innerHeight&&r.bottom>0&&s.visibility!=='hidden'&&+s.opacity>0.05) e.setAttribute('data-kt', String(n++)); });
  return n; })()`;

/* n numaralı aday: boyut + tanım + hâlâ görünür mü */
const ADAY_BILGI = (n) => `(function(){ var e=document.querySelector('[data-kt="${n}"]'); if(!e) return null;
  var r=e.getBoundingClientRect(), s=getComputedStyle(e), gor=r.width>0&&r.height>0&&s.visibility!=='hidden'&&+s.opacity>0.05&&document.documentElement.contains(e);
  var k=e.closest('[id]'); return { gor:gor, w:Math.round(r.width), h:Math.round(r.height),
    ad:(e.id?'#'+e.id:'')+(typeof e.className==='string'&&e.className?'.'+e.className.split(' ')[0]:'')+'<'+e.tagName+'>'+(k&&k!==e?' in #'+k.id:'') }; })()`;

/* çıkışsız katmanlar: kaplayan, en üstte duran, içinde dokunulabilir çıkış olmayan fixed öğeler */
const CIKISSIZ = `(function(){ var V=innerWidth*innerHeight, l=[];
  [].slice.call(document.body.querySelectorAll('*')).forEach(function(e){
    var s=getComputedStyle(e); if(s.position!=='fixed'||s.visibility==='hidden'||+s.opacity<0.05||s.pointerEvents==='none'||s.display==='none') return;
    if(e.id==='sekmeCubugu'||e.closest('#sekmeCubugu')) return;
    var r=e.getBoundingClientRect(), w=Math.max(0,Math.min(r.right,innerWidth)-Math.max(r.left,0)), h=Math.max(0,Math.min(r.bottom,innerHeight)-Math.max(r.top,0));
    if(w*h<V*0.25) return;
    var u=document.elementFromPoint(Math.max(r.left,0)+w/2, Math.max(r.top,0)+h/2); if(!u||!(u===e||e.contains(u))) return;
    var cikis=[].slice.call(e.querySelectorAll('button,a,[role=button],input,select,textarea,label')).some(function(b){
      var q=b.getBoundingClientRect(); if(!(q.width>0&&q.height>0&&q.top<innerHeight&&q.bottom>0)) return false;
      var v=document.elementFromPoint(q.left+q.width/2, q.top+q.height/2); return !!v&&(v===b||b.contains(v)); });
    var kaydir=e.scrollHeight>e.clientHeight+4;   /* içi kaydırılıyorsa çıkış aşağıda olabilir */
    if(!cikis&&!kaydir) l.push((e.id?'#'+e.id:'')+(typeof e.className==='string'&&e.className?'.'+e.className.split(' ')[0]:'')+'<'+e.tagName+'> '+Math.round(100*w*h/V)+'%');
  }); return l; })()`;

/* sürüm şeridini eski sürüm taklidiyle zorla açar (kritik: en_dusuk altı) */
/* 28.10 ilk koşu: <script src="surum-uyari.js?kt=…"> uygulamanın yerel sunucusunda çalışmadı (iki platformda da şerit yok) →
   dosya fetch ile okunur ve aynı kodla çalıştırılır (setTimeout 1500 içinde bak()). Sürüm verisi gerçek köprüden (tetikte.com). */
const SURUM_TAKLIT = (surum) => `(function(){ try{ localStorage.removeItem('tt_surum_kapat'); }catch(e){}
  var o=document.getElementById('ttSurum'); if(o) o.remove();
  window.TT_KATALOG=window.TT_KATALOG||{}; window.__ktEskiSurum=window.TT_KATALOG.surum; window.TT_KATALOG.surum=${JSON.stringify(surum)};
  window.__ktSurumHata='';
  fetch('surum-uyari.js').then(function(r){ return r.text(); }).then(function(t){ (new Function(t))(); }).catch(function(e){ window.__ktSurumHata='betik: '+e; });
  return 1; })()`;
const SURUM_TANI = `(function(){ var p=''; try{ p=window.Capacitor&&Capacitor.getPlatform?Capacitor.getPlatform():'web'; }catch(e){}
  return fetch('veri/uygulama-surum.json',{cache:'no-store'}).then(function(r){ return r.text().then(function(t){ return 'platform '+p+' · veri '+r.status+' '+t.slice(0,60).replace(/\\s+/g,' ')+' · '+(window.__ktSurumHata||''); }); })
    .catch(function(e){ return 'platform '+p+' · veri HATA '+e+' · '+(window.__ktSurumHata||''); }); })()`;
const SURUM_GERI = `(function(){ if(window.TT_KATALOG&&window.__ktEskiSurum) window.TT_KATALOG.surum=window.__ktEskiSurum; return !!document.getElementById('ttSurum'); })()`;

/* A = { js, bul, dokun, bekle, sonuc } — iki provanın kendi ilkel işlevleri */
async function katmanTara(A, ad) {
  const cik = await A.js(CIKISSIZ);
  A.sonuc(ad + ': çıkışsız (dokunulacak yeri olmayan) katman yok', !(cik && cik.length), cik && cik.length ? cik.slice(0, 3).join(' | ') : '');
  let kapanan = 0, toplam = 0;
  for (let tur = 0; tur < 8; tur++) {
    const n = await A.js(ADAY_ISARETLE); if (!n) break;
    toplam++;
    const b = await A.js(ADAY_BILGI(0)); if (!b) break;
    if (Math.min(b.w, b.h) < 24) { A.sonuc(ad + ': ✕ dokunma alanı yeterli (' + b.ad + ')', false, b.w + '×' + b.h + ' px'); return; }
    if (Math.min(b.w, b.h) < 44) console.log('UYARI ' + ad + ': ✕ ' + b.ad + ' ' + b.w + '×' + b.h + ' px (44 altı)');
    const o = await A.bul('[data-kt="0"]');
    if (!o) break;
    if (!o.ustte) { A.sonuc(ad + ': ✕ örtülü değil (' + b.ad + ')', false, 'üstünde ' + o.ortu); return; }
    await A.dokun(o); await A.bekle(1300);
    const s = await A.js(ADAY_BILGI(0));
    if (s && s.gor) { A.sonuc(ad + ': ✕ dokununca kapandı (' + b.ad + ')', false, 'hâlâ görünür'); return; }
    kapanan++;
  }
  if (!toplam) console.log('BILGI ' + ad + ': açık ✕ yok');
  else A.sonuc(ad + ': ' + kapanan + ' ✕ örtülü değil ve dokununca kapandı', kapanan === toplam, kapanan + '/' + toplam);
}

/* sürüm şeridi: çizilmeli, alt menüyü örtmemeli, ✕ kapatmalı (önce sarı, sonra kırmızı "güncelleme gerekli") */
async function surumSeridi(A) {
  for (const [ad, surum] of [['sarı "yeni sürüm hazır"', '1.8.1'], ['kırmızı "güncelleme gerekli"', '1.7.0']]) {
    await A.js(SURUM_TAKLIT(surum));
    let var_ = false; for (let i = 0; i < 12 && !var_; i++) { await A.bekle(700); var_ = await A.js('!!document.getElementById("ttSurum")'); }
    A.sonuc('sürüm şeridi ' + ad + ' çizildi', var_, 'taklit sürüm ' + surum + (var_ ? '' : ' · ' + (await A.js(SURUM_TANI))));
    if (var_) {
      const alt = await A.bul('#sekmeCubugu button');
      A.sonuc('sürüm şeridi açıkken alt menü dokunulabilir', !!(alt && alt.ustte), alt && !alt.ustte ? 'üstünde ' + alt.ortu : '');
      await katmanTara(A, 'sürüm şeridi ' + ad);
    }
    await A.js(SURUM_GERI);
  }
}

module.exports = { katmanTara, surumSeridi, X_SINIF, ADAY_ISARETLE, CIKISSIZ };
