/* kasa-yukle.js — KASA MODU: paket sorularını kilitli kasadan çeker (ADIM 2 · 16.09.2026)
 *
 * Cem 16.09: "depoda soru içeriği kalmasın". Kasa modundaki Kaydır-Çöz sayfası (motor/kasa-kabuk.js
 * üretir) soru taşımaz: <html data-kasa-sayfa="kaydir/sgs/turkce.html">, asıl betik
 * <script type="text/x-tetikte-kasa" id="kasaAna"> içinde çalışmadan bekler ve
 * `const SORULAR=window.__KASA_SORULAR||[]` ile başlar.
 *
 * Akış: paket-kapisi.js kapıyı açar (window.__pkKapi) -> bu dosya kasa_soru_getir fonksiyonundan o sayfanın
 * satırlarını sıra ile çeker (paket + ders kuralı sunucuda; 09.10'dan beri SAYILAN ve TAVANLI okuma, tabloya
 * doğrudan erişim kapalı) -> window.__KASA_SORULAR -> asıl betiği çalıştırır.
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

  /* 09.10 KASA ÖLÇER (Cem "indiremesin, en iyisi nasıl yapıyorsa aynısı"): tabloya doğrudan okuma kapandı
     (radar-app/sql/2026-10-09-kasa-olcer.sql). Satırlar yalnız kasa_soru_getir(p_sayfa, p_bas, p_adet<=100)
     fonksiyonundan gelir: her çekim üye adına sayılır, tavan (10 dk 1.500 · gün 4.000 · hafta 12.000) aşılınca
     'KASA_TAVAN:<pencere>' hatası döner. Her satırda 'toplam' var (sayfanın paketli üyeye görünen satır sayısı).
     mobil/uygulama/uygulama.js dersIndir AYNI çağrıyı kullanır (hazirla-sinavi.js ölçer). */
  function parca(sb, bas, adet) {
    /* supabase-js sorgusu tembeldir: await/then olmadan GİTMEZ (19.08 dersi). */
    return sb.rpc('kasa_soru_getir', { p_sayfa: sayfa, p_bas: bas, p_adet: adet })
      .then(function (r) { if (r.error) throw r.error; return r.data || []; });
  }
  function tavanMi(e) { return /KASA_TAVAN/.test(String((e && (e.message || e.details || e.hint)) || e)); }
  function tavanMesaji(e) {
    var p = (String(e && e.message || '').match(/KASA_TAVAN:(\w+)/) || [])[1];
    var ne = p === '10dk' ? 'son 10 dakikada' : p === 'gun' ? 'bugün' : p === 'hafta' ? 'bu hafta' : 'kısa sürede';
    mesaj('Soru sınırına ulaştın',
      'Hesabın ' + ne + ' olağan çalışmanın çok üstünde soru çekti; güvenlik için bir süre durduruldu. ' +
      'Gerçekten çalışıyorsan ' + (p === '10dk' ? 'birkaç dakika' : 'yarın') + ' yeniden dene; sorun sürerse bize yaz.',
      dugme('../../ogrenci.html', 'Hesabım'));
  }
  async function cek(sb) {
    var ilk = await parca(sb, 0, PARCA);
    var toplam = ilk.length ? +ilk[0].toplam : 0;
    var istekler = [];
    for (var i = PARCA; i < toplam; i += PARCA) istekler.push(parca(sb, i, PARCA));
    var parcalar = [ilk].concat(await Promise.all(istekler));
    var satir = [].concat.apply([], parcalar);
    satir.sort(function (a, b) { return a.sira - b.sira; });
    if (satir.length !== toplam) throw new Error('eksik satır ' + satir.length + '/' + toplam);
    return satir.map(function (x) { return x.veri; });
  }
  /* 09.10 kopya/yazdırma kilidi + telif şeridi (icerik-koruma.js): kapı açılınca, sorulardan önce yüklenir. */
  function koruma() {
    try {
      var me = document.querySelector('script[src$="kasa-yukle.js"]');
      var s = document.createElement('script'); s.src = (me ? me.getAttribute('src').replace(/kasa-yukle\.js$/, '') : '') + 'icerik-koruma.js';
      document.body.appendChild(s);
    } catch (e) {}
  }

  /* 07.10 PARÇA PARÇA (Cem "1 yap"): ölçüldü - SGS Finansal Muhasebe 1.100 soru, soru başı ~14 KB → ilk soru ~15 MB inince
     görünüyordu. Şablon destekliyorsa (__kasaEkle, motor/kaydir-coz.ps1 07.10+) ilk ILK satır gelince sayfa açılır, kalanı arkadan
     tek seferde eklenir (seviye sırası şablonda korunur). Derin bağlantı (#s=N) ve tek kart (?tek=1) eski yoldan (hepsi) - sıra
     numarası tam listeye göre. Kalan getirilemezse ilk parçanın bekleyenleri yine eklenir, uyarı çıkar. */
  var ILK = 40;
  var parcali = ana.textContent.indexOf('__kasaEkle') > -1 && !/#s=\d+/.test(location.hash) && !/[?&]tek=1/.test(location.search);
  async function kalaniCek(sb, toplam) {
    var satir = [], bas = ILK, TOPLU = 4;
    while (bas < toplam) {
      var istek = [];
      for (var j = 0; j < TOPLU && bas + j * PARCA < toplam; j++) istek.push(parca(sb, bas + j * PARCA, PARCA));
      var gelen = await Promise.all(istek);
      gelen.forEach(function (p) { satir = satir.concat(p); });
      bas += TOPLU * PARCA;
    }
    satir.sort(function (a, b) { return a.sira - b.sira; });
    return satir.map(function (x) { return x.veri; });
  }
  function uyar(metin) {
    var u = document.createElement('div'); u.setAttribute('role', 'status');
    u.style.cssText = 'position:fixed;left:50%;transform:translateX(-50%);bottom:18px;z-index:2147480000;max-width:92%;padding:10px 16px;' +
      'border-radius:12px;background:var(--kart);color:var(--yazi);border:1px solid var(--cizgi);font-size:14px';
    u.textContent = metin; document.body.appendChild(u); setTimeout(function () { u.remove(); }, 9000);
  }

  var bekle = window.__pkKapi || Promise.resolve({ acik: false, tur: 'hata' });
  bekle.then(async function (k) {
    if (!k || !k.acik) return;             /* perde zaten çizildi */
    koruma();
    mesaj('Sorular yükleniyor…', 'Soru bankası güvenli kasadan getiriliyor.');
    if (parcali) {
      try {
        var ilk = await parca(k.sb, 0, ILK);
        if (!ilk.length) {
          return mesaj('Bu ders paketinde yok',
            'Hesabındaki paket bu dersi kapsamıyor. Ders eklemek için paketini güncelleyebilirsin.',
            dugme('../../satin-al.html', 'Paketi güncelle'));
        }
        var toplam = +ilk[0].toplam, devam = toplam > ilk.length;
        window.__KASA_DEVAM = devam;
        document.getElementById('akis').innerHTML = '';
        calistir(ilk.sort(function (a, b) { return a.sira - b.sira; }).map(function (x) { return x.veri; }));
        if (!devam) return;
        var kalan = [];
        try { kalan = await kalaniCek(k.sb, toplam); }
        catch (e) { uyar(tavanMi(e) ? 'Soru sınırına ulaştın: kalan sorular bugün getirilmedi.' : 'Soruların bir kısmı getirilemedi. Bağlantını kontrol edip sayfayı yenile.'); }
        if (typeof window.__kasaEkle === 'function') window.__kasaEkle(kalan); else window.__KASA_DEVAM = false;
      } catch (e) {
        if (tavanMi(e)) return tavanMesaji(e);
        mesaj('Sorular getirilemedi', 'Bağlantını kontrol edip sayfayı yenile. Sorun sürerse bize yaz.',
          dugme(location.href, 'Yeniden dene'));
      }
      return;
    }
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
      if (tavanMi(e)) return tavanMesaji(e);
      mesaj('Sorular getirilemedi', 'Bağlantını kontrol edip sayfayı yenile. Sorun sürerse bize yaz.',
        dugme(location.href, 'Yeniden dene'));
    }
  });
})();
