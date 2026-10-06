/* kutu-esitle.js — YANLIŞ KUTUSU HESABA BAĞLI (07.10.2026, Cem "yanlış kutusu da hesaba bağla")
 *
 * Sorun (ölçüldü 07.10): yanlış kutusu (localStorage kc_kutu) yalnız PAKETLİ üyenin Kaydır-Çöz sayfasında hesaba
 * taşınıyordu (ilerleme-web.js, paket-kapisi.js yükler). Seviye testi ve "sınav gibi çöz"ün kutuya attığı yanlışlar,
 * Hesabım'daki "bugün tekrar" sayısı ve Yanlışlarım sayfası yalnız o tarayıcıdaydı. Kayıt ekranı ise "yanlış yaptığın
 * sorular hesabına kaydedilir" diyor.
 *
 * Bu dosya AYNI hesap kaydını kullanır: public.ogrenci_ilerleme → veri.kutu (mobil/uygulama/ilerleme.js biçimi:
 * { id: {tur,due,yanlis,konu,ders,donem,t} | {yok:1,t} }, soru başına en yeni t kazanır). ilerleme-web.js ve uygulama
 * aynı alanı okur/yazar; bu dosya onların yerini almaz, sayfası olmayan yerlerde (Hesabım, Yanlışlarım, seviye testi,
 * sınav gibi) aynı işi yapar. Tablo RLS: yalnız kendi satırı; paket şartı YOK (ücretsiz üye de eşitlenir).
 *
 * Üç yönlü birleştirme: cihazda "son eşitlenen kutu" izi (kc_kutu_es) tutulur.
 *   - izde yok, cihazda var       → bu cihazda eklendi  → hesaba (t = şimdi)
 *   - izde var, cihazda farklı    → bu cihazda değişti  → hesaba (t = şimdi)
 *   - izde var, cihazda yok       → bu cihazda çıkarıldı → hesaba {yok:1} (öbür cihaz da çıkarsın)
 *   - değişmemiş                  → hesaptaki kazanır (başka cihazdaki tekrar/çıkarma buraya gelir)
 *   İz yoksa (bu cihazda ilk eşitleme): hesapta olmayan yerel kayıt t=1 ile eklenir (ilerleme-web.js ile aynı kural:
 *   hesaptaki daha yeni karar kazanır, silme yok).
 * Sonra kc_kutu hesaptakinin aynısı olur. Hesaba ulaşılamazsa (ağ, tablo, oturum yok) HİÇBİR ŞEYE DOKUNMAZ.
 * Değişince document'e 'tetikte-kutu' olayı atar (sayfa yeniden çizer).
 *
 * 07.10 2. tur: kc_kayit (çözülen / doğru % / en zor konu) da eşitlenir — bkz. kayitDegisim/kayitKur.
 *
 * Öz-sınav: arac/kutu-esitle-sinavi.js (dogrula.yml; --mutasyon).
 * GÖRMEZ: kc_oyun (skor girdisi) bu dosyada eşitlenmez (ilerleme-web.js paketli sayfada taşır);
 * yeni cihazda "çözülen" = hesaptaki her sorunun SON cevabı (aynı soruya cihazdaki tekrar cevaplar tek sayılır);
 * ilerleme-web.js'in yazdığı kayıtta konu/ders yok → o cevaplar yeni cihazda "en zor konu"ya girmez;
 * kc_ileri (vade ileri alma) cihazda kalır; iki cihazda aynı anda değişen aynı soruda "eşitlemesi sonra olan" kazanır
 * (t = eşitleme anı, değişim anı değil).
 */
(function () {
  var betik = document.currentScript;
  var KOK = betik ? betik.src.replace(/kutu-esitle\.js.*$/, '') : '/';
  var SB_URL = 'https://bjrleanjpyujtajmazxn.supabase.co', SB_KEY = 'sb_publishable_kTZpYwrL7skw8Ryj5Vs8_Q_-5_Fhkcg';
  var IZ = 'kc_kutu_es', calisiyor = null, tekrar = false;

  function oku(k, v) { try { var x = JSON.parse(localStorage.getItem(k) || 'null'); return x == null ? v : x; } catch (e) { return v; } }
  function anahtarVar() { try { return Object.keys(localStorage).some(function (k) { return k.indexOf('-auth-token') > -1; }); } catch (e) { return false; } }
  function yukle(src) {
    return new Promise(function (tamam, hata) {
      var s = document.createElement('script'); s.src = src; s.onload = tamam; s.onerror = hata;
      (document.head || document.documentElement).appendChild(s);
    });
  }
  async function istemci() {
    if (window.__pkSb) return window.__pkSb;
    /* paket-kapisi.js olan sayfada (sınav gibi) onun istemcisi beklenir: kütüphane iki kez yüklenmesin */
    if (window.__pkKapi) { try { var k = await window.__pkKapi; if (k && k.sb) return k.sb; } catch (e) {} if (window.__pkSb) return window.__pkSb; }
    if (window.TetikteUye && TetikteUye.hazir) { try { await TetikteUye.hazir; } catch (e) {} if (window.__pkSb) return window.__pkSb; }
    if (!(window.supabase && window.supabase.createClient)) await yukle(KOK + 'kutuphane/supabase-2.112.3.js');
    return window.__pkSb || (window.__pkSb = window.supabase.createClient(SB_URL, SB_KEY));
  }
  function kisa(s) { return s == null ? '' : String(s).slice(0, 80); }
  function kayit(x, t) { return { tur: x.tur, due: x.due, yanlis: x.yanlis || 0, konu: kisa(x.konu), ders: kisa(x.ders), donem: x.donem || 0, t: t }; }
  function iz(x) { return { tur: x.tur, due: x.due, yanlis: x.yanlis || 0 }; }
  function farkli(a, b) { return !a || !b || a.tur !== b.tur || a.due !== b.due || (a.yanlis || 0) !== (b.yanlis || 0); }

  /* SAF: (yerel kutu, iz | null, hesaptaki kutu haritası, şimdi) → { hesaba: {id: kayıt}, } — öz-sınav için ayrı */
  function degisimler(yerel, izler, uzak, simdi) {
    var d = {}, yerelId = {};
    yerel.forEach(function (x) {
      if (!x || x.id == null) return;
      var id = String(x.id); yerelId[id] = 1;
      if (!izler) { if (!uzak[id]) d[id] = kayit(x, 1); return; }
      if (!izler[id] || farkli(izler[id], x)) d[id] = kayit(x, simdi);
    });
    if (izler) for (var id in izler) if (!yerelId[id] && uzak[id] && !uzak[id].yok) d[id] = { yok: 1, t: simdi };
    return d;
  }
  /* hesaptaki haritadan cihaz kutusu; cihazdaki kimlik tipi (sayı/metin) korunur */
  function kutuKur(uzak, yerel) {
    var tip = {}; yerel.forEach(function (x) { if (x && x.id != null) tip[String(x.id)] = x.id; });
    var k = [];
    for (var id in uzak) { var x = uzak[id]; if (!x || x.yok) continue;
      k.push({ id: id in tip ? tip[id] : id, konu: x.konu, ders: x.ders, donem: x.donem, tur: x.tur, due: x.due, yanlis: x.yanlis }); }
    return k;
  }

  /* 07.10 (2. tur, Cem "1.2.3"): ÇÖZÜLEN / DOĞRU % (kc_kayit) da hesaba. kc_kayit bir cevap günlüğüdür
     [{id,konu,ders,donem,dogru,t}], hesapta soru başına SON cevap durur: veri.kayit = { id: {d:1|0, t, k?, ders?, donem?} }
     (ilerleme-web.js {d,t} yazar; bu dosya konu/ders'i de ekler ki başka cihazda "en zor konu" çıkabilsin).
     Silme yok: günlük yalnız büyür (sayfanın "sıfırla"sı hesaptakini silmez — ilerleme-web.js ile aynı). */
  var KAYIT_TAVAN = 500, BUYUK = 1200000;   /* hesap satırı tavanı 1,5 MB (SQL); 1,2 MB üstünde konu/ders yazılmaz */
  function kayitDegisim(log, uzak, buyuk) {
    var son = {}, d = {};
    log.forEach(function (r) { if (!r || r.id == null) return; var id = String(r.id), t = r.t || 1; if (!son[id] || t >= son[id].t) son[id] = { r: r, t: t }; });
    for (var id in son) {
      var r = son[id].r, t = son[id].t, u = uzak[id];
      if (u && (u.t || 0) >= t) continue;
      d[id] = buyuk ? { d: r.dogru ? 1 : 0, t: t } : { d: r.dogru ? 1 : 0, t: t, k: String(r.konu || '').slice(0, 60), ders: String(r.ders || '').slice(0, 60), donem: r.donem || 0 };
    }
    return d;
  }
  function kayitKur(log, uzak, tip) {
    var sonYerel = {}, yeni = log.slice();
    log.forEach(function (r) { if (r && r.id != null) { var id = String(r.id); sonYerel[id] = Math.max(sonYerel[id] || 0, r.t || 1); } });
    for (var id in uzak) {
      var u = uzak[id]; if (!u || !u.t || u.t <= (sonYerel[id] || 0)) continue;
      yeni.push({ id: id in tip ? tip[id] : id, konu: u.k || '', ders: u.ders || '', donem: u.donem || 0, dogru: !!u.d, t: u.t });
    }
    yeni.sort(function (a, b) { return ((a && a.t) || 0) - ((b && b.t) || 0); });
    return yeni.slice(-KAYIT_TAVAN);
  }

  async function esitle() {
    if (calisiyor) { tekrar = true; return calisiyor; }
    calisiyor = (async function () {
      try {
        if (!anahtarVar()) return 'yerel';
        var sb = await istemci();
        var o = await sb.auth.getSession(), uid = o && o.data && o.data.session && o.data.session.user && o.data.session.user.id;
        if (!uid) return 'yerel';
        if (!window.TTIlerleme) await yukle(KOK + 'mobil/uygulama/ilerleme.js');
        var IL = window.TTIlerleme; if (!IL) return 'yerel';
        IL.yenidenOku();
        if ((await IL.esitle(sb, uid)) === 'yerel') return 'yerel';
        var yerel = oku('kc_kutu', []); if (!Array.isArray(yerel)) yerel = [];
        var izler = oku(IZ, null);
        var d = degisimler(yerel, izler && typeof izler === 'object' ? izler : null, IL.veri().kutu || {}, Date.now());
        var log = oku('kc_kayit', []); if (!Array.isArray(log)) log = [];
        var buyuk = JSON.stringify(IL.veri()).length > BUYUK;
        var dk = kayitDegisim(log, IL.veri().kayit || {}, buyuk);
        if (Object.keys(d).length || Object.keys(dk).length) {
          IL.haritaYaz('kutu', d); IL.haritaYaz('kayit', dk);
          if ((await IL.esitle(sb, uid)) === 'yerel') return 'yerel';
        }
        var yeni = kutuKur(IL.veri().kutu || {}, yerel), yeniIz = {};
        yeni.forEach(function (x) { yeniIz[String(x.id)] = iz(x); });
        var tip = {}; log.concat(yerel).forEach(function (x) { if (x && x.id != null) tip[String(x.id)] = x.id; });
        var yeniLog = kayitKur(log, IL.veri().kayit || {}, tip);
        var logDegisti = yeniLog.length !== log.length || JSON.stringify(yeniLog) !== JSON.stringify(log.slice(-KAYIT_TAVAN));
        var degisti = JSON.stringify(yeni) !== JSON.stringify(yerel) || logDegisti;
        try { if (JSON.stringify(yeni) !== JSON.stringify(yerel)) localStorage.setItem('kc_kutu', JSON.stringify(yeni)); localStorage.setItem(IZ, JSON.stringify(yeniIz));
              if (logDegisti) localStorage.setItem('kc_kayit', JSON.stringify(yeniLog)); } catch (e) {}
        if (degisti) try { document.dispatchEvent(new CustomEvent('tetikte-kutu', { detail: { adet: yeni.length } })); } catch (e) {}
        return degisti ? 'guncellendi' : 'esit';
      } catch (e) { return 'yerel'; }
    })();
    var sonuc = await calisiyor; calisiyor = null;
    if (tekrar) { tekrar = false; return esitle(); }
    return sonuc;
  }

  window.ttKutuEsitle = { esitle: esitle, degisimler: degisimler, kutuKur: kutuKur, kayitDegisim: kayitDegisim, kayitKur: kayitKur };
  /* açılışta bir kez (oturum anahtarı yoksa hiçbir istek gitmez) + sekmeden çıkarken */
  if (anahtarVar()) esitle();
  document.addEventListener('visibilitychange', function () { if (document.visibilityState === 'hidden' && anahtarVar()) esitle(); });
})();
