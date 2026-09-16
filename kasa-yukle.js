/* kasa-yukle.js — KASA MODU: paket sorularını kilitli kasadan çeker (ADIM 2 · 16.09.2026)
 *
 * Cem 16.09: "depoda soru içeriği kalmasın". Kasa modundaki Kaydır-Çöz sayfası (motor/kasa-kabuk.js
 * üretir) soru taşımaz: <html data-kasa-sayfa="kaydir/sgs/turkce.html">, asıl betik
 * <script type="text/x-tetikte-kasa" id="kasaAna"> içinde çalışmadan bekler ve
 * `const SORULAR=window.__KASA_SORULAR||[]` ile başlar.
 *
 * Akış: paket-kapisi.js kapıyı açar (window.__pkKapi) -> bu dosya paket_soru tablosundan o sayfanın
 * satırlarını sıra ile çeker (RLS: aktif paket + ders) -> window.__KASA_SORULAR -> asıl betiği çalıştırır.
 * Perde çıkarsa kasaya HİÇ istek gitmez. Kasa 0 satır verirse (ders paketinde yok) açıklama gösterilir.
 *
 * Asıl betik DOMContentLoaded/load olaylarına iş bağlıyor (tema düğmesi, #s= kaydırması); bu dosya
 * onu olaylar geçtikten SONRA çalıştırdığı için, çalıştırma anında bu iki olaya yapılan bağlamalar
 * hemen koşturulur. Renk yazılmaz: sayfa jetonları kullanılır.
 */
(function () {
  var kok = document.documentElement;
  var sayfa = kok.getAttribute('data-kasa-sayfa');
  var ana = document.getElementById('kasaAna');
  if (!sayfa || !ana) return;
  var PARCA = 100;

  function esc(t) { return String(t).replace(/[&<>"]/g, function (c) { return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]; }); }
  function mesaj(baslik, metin, dugme) {
    var a = document.getElementById('akis');
    if (!a) return;
    a.innerHTML = '<div role="status" style="max-width:440px;margin:18vh auto 0;padding:26px 22px;text-align:center;' +
      'background:var(--kart);border:1px solid var(--cizgi);border-radius:16px;color:var(--yazi);font-family:inherit">' +
      '<h2 style="margin:0 0 8px;font-size:20px">' + esc(baslik) + '</h2>' +
      '<p style="margin:0 0 16px;line-height:1.6;color:var(--dim)">' + esc(metin) + '</p>' + (dugme || '') + '</div>';
  }
  function dugme(href, yazi) {
    return '<a href="' + esc(href) + '" style="display:block;padding:12px 14px;border-radius:11px;font-weight:750;' +
      'text-decoration:none;border:1px solid var(--cizgi);color:var(--yazi)">' + esc(yazi) + '</a>';
  }

  function calistir(sorular) {
    window.__KASA_SORULAR = sorular;
    var dEkle = document.addEventListener, wEkle = window.addEventListener;
    function sar(orj, hedef) {
      return function (tur, fn, secenek) {
        var gecti = (tur === 'DOMContentLoaded' && document.readyState !== 'loading') ||
                    (tur === 'load' && document.readyState === 'complete');
        if (gecti && typeof fn === 'function') {
          setTimeout(function () { fn.call(hedef, new Event(tur)); }, 0);
          return;
        }
        return orj.call(this, tur, fn, secenek);
      };
    }
    document.addEventListener = sar(dEkle, document);
    window.addEventListener = sar(wEkle, window);
    try {
      var s = document.createElement('script');
      s.textContent = ana.textContent;
      document.body.appendChild(s);
    } finally {
      document.addEventListener = dEkle;
      window.addEventListener = wEkle;
    }
  }

  async function cek(sb) {
    var ilk = await sb.from('paket_soru').select('sira,veri', { count: 'exact' })
      .eq('sayfa', sayfa).order('sira', { ascending: true }).range(0, PARCA - 1);
    if (ilk.error) throw ilk.error;
    var toplam = ilk.count == null ? ilk.data.length : ilk.count;
    var istekler = [];
    for (var i = PARCA; i < toplam; i += PARCA) {
      /* supabase-js sorgusu tembeldir: await/then olmadan GİTMEZ (19.08 dersi). */
      istekler.push(sb.from('paket_soru').select('sira,veri')
        .eq('sayfa', sayfa).order('sira', { ascending: true }).range(i, i + PARCA - 1)
        .then(function (r) { if (r.error) throw r.error; return r.data; }));
    }
    var parcalar = [ilk.data].concat(await Promise.all(istekler));
    var satir = [].concat.apply([], parcalar);
    satir.sort(function (a, b) { return a.sira - b.sira; });
    if (satir.length !== toplam) throw new Error('eksik satır ' + satir.length + '/' + toplam);
    return satir.map(function (x) { return x.veri; });
  }

  var bekle = window.__pkKapi || Promise.resolve({ acik: false, tur: 'hata' });
  bekle.then(async function (k) {
    if (!k || !k.acik) return;             /* perde zaten çizildi */
    mesaj('Sorular yükleniyor…', 'Soru bankası güvenli kasadan getiriliyor.');
    try {
      var sorular = await cek(k.sb);
      if (!sorular.length) {
        return mesaj('Bu ders paketinde yok',
          'Hesabındaki paket bu dersi kapsamıyor. Ders eklemek için paketini güncelleyebilirsin.',
          dugme('../../satin-al.html', 'Paketi güncelle'));
      }
      document.getElementById('akis').innerHTML = '';
      calistir(sorular);
    } catch (e) {
      mesaj('Sorular getirilemedi', 'Bağlantını kontrol edip sayfayı yenile. Sorun sürerse bize yaz.',
        dugme(location.href, 'Yeniden dene'));
    }
  });
})();
