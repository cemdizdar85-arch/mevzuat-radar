/* icerik-koruma.js — PAKETLİ İÇERİKTE KOPYA/YAZDIRMA KİLİDİ + TELİF ŞERİDİ (09.10.2026)
 *
 * Cem 09.10: "sitede soruyu görün, bilgisayara indiremesin; bu işi en iyi yapan nasıl yapıyorsa aynısı."
 * UWorld sözleşmesi (terms_conditions.aspx, 09.10 okundu): test sürerken pano (kopyala/yapıştır/yazdır/
 * diske kaydet) kapatılır, ekranda telif uyarısı durur ("Please do not save, print, cut, copy or paste
 * anything while a test is active"), ekran görüntüsü ve kopya sözleşme ihlalidir.
 * Bu dosya o katmanın tarayıcı ayağıdır; kasa-yukle.js paketli sayfada yükler, sinav-gibi.html doğrudan bağlar.
 *
 * NE YAPAR: metin seçimi kapalı (not/yorum kutuları hariç) · sağ tık, kopyala/kes, sürükle kapalı ·
 * Ctrl/Cmd+C/S/P/U, F12 ve Ctrl+Shift+I/J/C engeli · yazdırmada sayfa boş + uyarı · altta telif şeridi.
 *
 * ⚠ DÜRÜST SINIR (KAPI KURMA KURALLARI m.3): bunlar KİLİT DEĞİL, kapı tokmağı. Tarayıcı araçlarını bilen
 * biri 10 saniyede aşar; ekran görüntüsünü ve kamerayı tarayıcı engelleyemez. Asıl kilit sunucuda:
 * radar-app/sql/2026-10-09-kasa-olcer.sql (sayılan, tavanlı okuma) + cihaz-kapisi.js (tek ekran, filigran).
 * Erişilebilirlik: metin DOM'da kalır, ekran okuyucu etkilenmez; klavye ile gezinme (ok tuşları) dokunulmaz.
 * Renk yazılmaz: sayfa jetonları (Kaydır-Çöz: --bg/--kart/--yazi · site: --taban/--panel/--ink).
 */
(function () {
  if (window.ttKoruma) return;
  window.ttKoruma = true;
  var st = document.createElement('style');
  st.textContent =
    'html.tt-koruma body{-webkit-user-select:none;user-select:none;-webkit-touch-callout:none}' +
    'html.tt-koruma input,html.tt-koruma textarea,html.tt-koruma [contenteditable="true"]{-webkit-user-select:text;user-select:text}' +
    '#ttTelif{position:fixed;left:0;right:0;bottom:0;z-index:2147482000;font:12px/1.4 -apple-system,"Segoe UI",system-ui,Roboto,Arial,sans-serif;' +
    'text-align:center;padding:4px 10px calc(4px + env(safe-area-inset-bottom,0px));pointer-events:none;' +
    'color:var(--dim,var(--ink));background:color-mix(in srgb,var(--kart,var(--panel)) 85%,transparent);opacity:.85}' +
    '@media print{html.tt-koruma body>*{display:none!important}html.tt-koruma body:before{content:"Bu içerik telif hakkıyla korunur; yazdırılamaz. © Tetikte";display:block;padding:40px;font:16px sans-serif}}';
  (document.head || document.documentElement).appendChild(st);
  document.documentElement.classList.add('tt-koruma');

  function dur(e) { e.preventDefault(); return false; }
  ['contextmenu', 'copy', 'cut', 'dragstart'].forEach(function (t) { document.addEventListener(t, function (e) {
    var h = e.target; if (h && h.closest && h.closest('input,textarea,[contenteditable="true"]')) return;   /* not kutusu serbest */
    dur(e);
  }, true); });
  document.addEventListener('keydown', function (e) {
    var k = (e.key || '').toLowerCase(), m = e.ctrlKey || e.metaKey;
    if (e.target && e.target.closest && e.target.closest('input,textarea,[contenteditable="true"]') && !(m && (k === 'p' || k === 's' || k === 'u'))) return;
    if ((m && (k === 'c' || k === 's' || k === 'p' || k === 'u' || k === 'a')) || k === 'f12' || (m && e.shiftKey && (k === 'i' || k === 'j' || k === 'c'))) dur(e);
  }, true);
  window.addEventListener('beforeprint', function () { try { document.title = 'Yazdırma kapalı — Tetikte'; } catch (e) {} });

  function serit() {
    if (document.getElementById('ttTelif') || !document.body) return;
    var d = document.createElement('div'); d.id = 'ttTelif'; d.setAttribute('role', 'contentinfo');
    d.textContent = '© Tetikte · Bu sorular kişisel çalışman içindir. Kopyalanması, kaydedilmesi, ekran görüntüsü alınması ve paylaşılması sözleşmeye aykırıdır; hesap kapatılır.';
    document.body.appendChild(d);
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', serit); else serit();
})();
