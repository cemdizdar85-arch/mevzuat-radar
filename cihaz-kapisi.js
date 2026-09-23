/* cihaz-kapisi.js — HESAP PAYLAŞIM KORUMASI, istemci ayağı (23.09.2026)
 *
 * Cem 23.09: "1.2.3 üçünü de yapalım, açılışı beklemeyelim". Paket alan birinin şifresini
 * başkalarına vermesine karşı, profesyonel platformlardaki katmanlar:
 *   (1) TEK AKTİF EKRAN — sayfa açılınca bu cihaz ekranı alır; eski cihaz bir sonraki
 *       yoklamada (en geç 60 sn / sekmeye dönünce) "Hesabın başka bir cihazda açıldı" görür.
 *   (2) EN FAZLA 3 CİHAZ — 4. cihaz girmeye çalışınca "cihaz sınırı" ekranı; eskisi
 *       Hesabım → Cihazlarım'dan çıkarılır (30 günde en fazla 2 çıkarma).
 *   (3) FİLİGRAN — paketli sayfada üyenin e-postası silik yazar (ekran görüntüsü dağıtan
 *       kendini ifşa eder).
 * Veritabanı ayağı: radar-app/sql/2026-09-23-hesap-paylasim-korumasi.sql
 * (cihaz_kontrol · cihazlarim · cihaz_cikar). Alarm ayağı: motor/uye-alarmi.ps1.
 *
 * YALNIZ PAKETLİ İÇERİKTE çalışır: paket-kapisi.js aktif paket görünce koru()'yu çağırır.
 * Ücretsiz üye, canlı deneme, radar/evrak/marka etkilenmez.
 *
 * ⛔ ARIZADA ÜYE İÇERİDE KALIR (fail-open): sayfa önce açılır, kontrol sonra gelir.
 * Fonksiyon basılmamışsa (PGRST202/404) ya da ağ düşerse HİÇBİR ŞEY kapanmaz; yalnız
 * konsola bir kez yazılır. Paralı müşteriyi bizim arızamız yüzünden dışarıda bırakmayız.
 *
 * BU DOSYA ŞUNU GÖRMEZ / YAPAMAZ:
 *   - Soru içeriği bugün sayfa dosyasında açık (Adım 2 kasası gelene kadar); tarayıcı
 *     araçlarını bilen biri perdeyi kaldırabilir. Olağan paylaşımı durdurur, uzmanı değil.
 *   - Cihaz kimliği tarayıcı hafızasındadır; hafızayı silen "yeni cihaz" olur — bu da
 *     3 cihaz sınırına sayılır (bilerek).
 *   - Aynı cihazda iki sekme tek ekran sayılır.
 * Renk yazılmaz: sayfa jetonları (Kaydır-Çöz: --bg/--kart/--yazi · site: --taban/--panel/--ink).
 */
(function () {
  if (window.ttCihaz) return;
  var ANAHTAR = 'tt_cihaz';
  var YOKLAMA_MS = 60000;
  var kapali = false;          // fonksiyon yoksa (SQL basılmamış) bütün katman susar
  var sonYoklama = 0;
  var zamanlayici = null;

  function kimlik() {
    var v = null;
    try { v = localStorage.getItem(ANAHTAR); } catch (e) {}
    if (v && /^[a-z0-9-]{8,64}$/i.test(v)) return v;
    v = (window.crypto && crypto.randomUUID) ? crypto.randomUUID()
      : ('c' + Date.now().toString(36) + Math.random().toString(36).slice(2, 12));
    try { localStorage.setItem(ANAHTAR, v); } catch (e) {}
    return v;
  }

  function etiket() {
    var u = navigator.userAgent || '';
    var os = /iPhone/.test(u) ? 'iPhone' : /iPad/.test(u) ? 'iPad' : /Android/.test(u) ? 'Android'
      : /Windows/.test(u) ? 'Windows' : /Mac OS X|Macintosh/.test(u) ? 'Mac' : /Linux/.test(u) ? 'Linux' : 'Cihaz';
    var tr = /Edg\//.test(u) ? 'Edge' : /SamsungBrowser/.test(u) ? 'Samsung' : /OPR\//.test(u) ? 'Opera'
      : /Firefox\//.test(u) ? 'Firefox' : /CriOS|Chrome\//.test(u) ? 'Chrome' : /Safari\//.test(u) ? 'Safari' : 'Tarayıcı';
    return os + ' · ' + tr;
  }

  function fonksiyonYok(hata) {
    var t = (hata && (hata.code || '') + ' ' + (hata.message || '')) || '';
    return /PGRST202|404|Could not find the function/i.test(t);
  }

  async function rpc(sb, ad, args) {
    if (kapali || !sb) return null;
    try {
      var r = await sb.rpc(ad, args);
      if (r.error) {
        if (fonksiyonYok(r.error)) {
          kapali = true;
          console.warn('[cihaz-kapisi] ' + ad + ' yok — radar-app/sql/2026-09-23-hesap-paylasim-korumasi.sql basılmamış; koruma KAPALI, sayfa açık kalır.');
        }
        return null;
      }
      return r.data || null;
    } catch (e) { return null; }
  }

  function kontrol(sb, devral) {
    return rpc(sb, 'cihaz_kontrol', { p_cihaz: kimlik(), p_etiket: etiket(), p_devral: !!devral });
  }
  function listele(sb) { return rpc(sb, 'cihazlarim', { p_cihaz: kimlik() }); }
  function cikar(sb, hedef) { return rpc(sb, 'cihaz_cikar', { p_hedef: hedef }); }

  function kokAdres() {
    var s = document.querySelector('script[src*="cihaz-kapisi.js"]');
    return s ? s.src.replace(/cihaz-kapisi\.js.*$/, '') : '/';
  }

  function stilKur() {
    if (document.getElementById('ckStil')) return;
    var st = document.createElement('style');
    st.id = 'ckStil';
    st.textContent =
      '#ckPerde{position:fixed;inset:0;z-index:2147483000;display:flex;align-items:center;justify-content:center;padding:22px;' +
      'background:var(--bg,var(--taban));color:var(--yazi,var(--ink));font-family:-apple-system,"Segoe UI",system-ui,Roboto,Arial,sans-serif}' +
      '#ckPerde .ck-kutu{max-width:440px;width:100%;text-align:center;background:var(--kart,var(--panel));border:1px solid var(--cizgi,var(--line));border-radius:16px;padding:28px 22px}' +
      '#ckPerde h2{margin:0 0 8px;font-size:21px;letter-spacing:-.3px}' +
      '#ckPerde p{margin:0 0 16px;font-size:14.5px;line-height:1.6;color:var(--dim)}' +
      '#ckPerde ul{list-style:none;padding:0;margin:0 0 16px;text-align:left;font-size:14px}' +
      '#ckPerde li{padding:8px 10px;border:1px solid var(--cizgi,var(--line));border-radius:9px;margin:6px 0}' +
      '#ckPerde button,#ckPerde a{display:block;width:100%;box-sizing:border-box;margin:8px 0 0;padding:12px 14px;border-radius:11px;font:inherit;font-weight:750;font-size:15px;' +
      'cursor:pointer;text-decoration:none;text-align:center;border:1px solid var(--cizgi,var(--line2));background:transparent;color:var(--yazi,var(--ink))}' +
      '#ckPerde .ck-ana{background:var(--mavi,var(--accent2));border-color:transparent;color:var(--ustYazi,var(--taban))}' +
      '#ckFiligran{position:fixed;inset:0;z-index:2147482000;pointer-events:none;overflow:hidden;user-select:none;-webkit-user-select:none}' +
      '#ckFiligran .ck-ic{position:absolute;left:-50%;top:-50%;width:200%;height:200%;transform:rotate(-24deg);' +
      'display:flex;flex-wrap:wrap;align-content:flex-start;gap:70px 90px;padding:40px;opacity:.07;color:var(--yazi,var(--ink));font:600 13px/1 system-ui,sans-serif}';
    (document.head || document.documentElement).appendChild(st);
  }

  function perdeKaldir() {
    var p = document.getElementById('ckPerde');
    if (p) p.parentNode.removeChild(p);
    if (document.body) document.body.style.overflow = '';
  }

  function perdeGoster(html) {
    stilKur();
    perdeKaldir();
    var d = document.createElement('div');
    d.id = 'ckPerde';
    d.setAttribute('role', 'dialog'); d.setAttribute('aria-modal', 'true');
    d.innerHTML = '<div class="ck-kutu">' + html + '</div>';
    document.body.appendChild(d);
    document.body.style.overflow = 'hidden';
    return d;
  }

  function kacis(t) { var e = document.createElement('div'); e.textContent = String(t == null ? '' : t); return e.innerHTML; }

  function baskaEkran(sb, sonuc) {
    var d = perdeGoster(
      '<div aria-hidden="true" style="font-size:26px;margin-bottom:6px">📱</div>' +
      '<h2>Hesabın başka bir cihazda açıldı</h2>' +
      '<p>Paketin aynı anda tek ekranda açık olabilir. Şu an açık olan: <b>' + kacis(sonuc && sonuc.aktif_etiket) + '</b>.<br>' +
      'Buradan devam edersen o cihazdaki ekran kapanır.</p>' +
      '<button type="button" class="ck-ana" id="ckDevam">Burada devam et</button>');
    d.querySelector('#ckDevam').onclick = async function () {
      this.disabled = true;
      var r = await kontrol(sb, true);
      if (!r || r.durum === 'tamam') { perdeKaldir(); return; }
      if (r.durum === 'cihaz_siniri') { cihazSiniri(r); return; }
      this.disabled = false;
    };
  }

  function cihazSiniri(sonuc) {
    var liste = ((sonuc && sonuc.cihazlar) || []).map(function (c) {
      var t = c.son_gorulme ? new Date(c.son_gorulme).toLocaleDateString('tr-TR') : '';
      return '<li>' + kacis(c.etiket || 'Cihaz') + (t ? ' <span style="color:var(--dim)">· son: ' + t + '</span>' : '') + '</li>';
    }).join('');
    perdeGoster(
      '<div aria-hidden="true" style="font-size:26px;margin-bottom:6px">🔒</div>' +
      '<h2>Cihaz sınırına ulaştın</h2>' +
      '<p>Paketin en fazla <b>' + ((sonuc && sonuc.sinir) || 3) + ' cihazda</b> kullanılabilir. Bu cihazı eklemek için kayıtlı cihazlarından birini çıkar.</p>' +
      (liste ? '<ul>' + liste + '</ul>' : '') +
      '<a class="ck-ana" href="' + kokAdres() + 'ogrenci.html#cihazlarim">Cihazlarımı yönet</a>');
  }

  function filigran(kullanici) {
    if (document.getElementById('ckFiligran')) return;
    stilKur();
    var yazi = (kullanici && kullanici.email) || ('üye ' + String((kullanici && kullanici.id) || '').slice(0, 8));
    var d = document.createElement('div');
    d.id = 'ckFiligran'; d.setAttribute('aria-hidden', 'true');
    var ic = document.createElement('div'); ic.className = 'ck-ic';
    for (var i = 0; i < 90; i++) { var s = document.createElement('span'); s.textContent = yazi; ic.appendChild(s); }
    d.appendChild(ic);
    document.body.appendChild(d);
  }

  async function yokla(sb) {
    if (kapali || document.hidden) return;
    var simdi = Date.now();
    if (simdi - sonYoklama < 10000) return;
    sonYoklama = simdi;
    var r = await kontrol(sb, false);
    if (!r) return;
    if (r.durum === 'baska_ekran') baskaEkran(sb, r);
    else if (r.durum === 'cihaz_siniri') cihazSiniri(r);
  }

  async function koru(sb, kullanici) {
    try {
      var ilk = await kontrol(sb, true);             // sayfa açılışı: bu cihaz ekranı alır
      if (kapali || !ilk) return;                    // SQL yok / ağ düştü: sayfa açık kalır
      if (ilk.durum === 'cihaz_siniri') { cihazSiniri(ilk); return; }
      if (ilk.durum !== 'tamam') return;
      filigran(kullanici);
      sonYoklama = Date.now();
      if (zamanlayici) clearInterval(zamanlayici);
      zamanlayici = setInterval(function () { yokla(sb); }, YOKLAMA_MS);
      document.addEventListener('visibilitychange', function () { if (!document.hidden) yokla(sb); });
      window.addEventListener('focus', function () { yokla(sb); });
    } catch (e) { /* arızada üye içeride kalır */ }
  }

  window.ttCihaz = { kimlik: kimlik, etiket: etiket, kontrol: kontrol, listele: listele, cikar: cikar, koru: koru };
})();
