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
  /* 10.10: tavan hatası sunucuda kendi kütük satırını geri alıyordu (kütükte TAVAN 0) -> ayrı çağrıyla kalıcı yazılır
     (radar-app/sql/2026-10-10-kasa-tavan-gevset.sql). Bildirim düşerse sayfa yine çalışır. */
  function tavanBildir(sb, e) {
    try {
      var p = (String(e && e.message || '').match(/KASA_TAVAN:(\w+)/) || [])[1] || '10dk';
      if (sb) sb.rpc('kasa_tavan_bildir', { p_sayfa: sayfa, p_pencere: p }).then(function () {}, function () {});
    } catch (x) {}
  }
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

  /* 11.10 SET + ARKA PLAN CEVAP KAYDI (Cem "askıya almadan önce doğru ölçüyor muyuz emin olmamız lazım" → "set + arka plan
     kaydı bunu yapalım"; SQL radar-app/sql/2026-10-11-kasa-set-cevap.sql). 10.10 ölçümü: bir hesap 3.567 farklı soru "çekti",
     o gün 7 çözdü — sayfa dersin TAMAMINI indiriyordu, sayaç inen soruyu sayıyordu.
     Şablon destekliyorsa (__KASA_FIHRIST, motor/kaydir-coz.ps1 11.10+): önce dersin İÇERİKSİZ fihristi (kimlik, sıra, zorluk,
     konu, dönem; sayılmaz) → seviye sırası burada kurulur → ilk 40 soru → öğrenci son 10 karta yaklaşınca sıradaki 20
     (__kasaSonraki). Her cevap ARKA PLANDA kasa_cevap_yaz'a gider (öğrenci beklemez; doğru/yanlış sunucuda hesaplanır).
     Derin bağlantı (#s=N) ve tek kart (?tek=1) eski yoldan (hepsi). */
  var setli = ana.textContent.indexOf('__KASA_FIHRIST') > -1 && !/#s=\d+/.test(location.hash) && !/[?&]tek=1/.test(location.search);
  var SET_ILK = 40, SET_ADET = 20;
  function fihristCek(sb) {
    return sb.rpc('kasa_ders_fihrist', { p_sayfa: sayfa })
      .then(function (r) { if (r.error) throw r.error; return r.data || []; });
  }
  function parcaCek(sb, ids) {
    return sb.rpc('kasa_soru_parca', { p_sayfa: sayfa, p_ids: ids })
      .then(function (r) {
        if (r.error) throw r.error;
        var m = {}; (r.data || []).forEach(function (x) { m[x.id] = x.veri; });
        return ids.map(function (id) { return m[id]; }).filter(Boolean);   /* fihrist sırası korunur */
      });
  }
  /* SEVİYE SIRASI — şablondaki SIRA_NOTU (motor/kaydir-coz.ps1, "05.10 SEVİYEYE GÖRE SIRA") ile AYNI kural; biri değişirse
     öteki de değişir. Şablon __KASA_SIRALI görünce kendi sıralamasını yapmaz (çifte sıralama yok). */
  function seviyeSirala(fih) {
    try {
      if (/[?&]vitrin=1/.test(location.search) || !fih.length) return fih;
      var yet = /\/smmm\//.test(location.pathname), ders = String(fih[0].ders || '');
      var g = []; try { g = JSON.parse(localStorage.getItem(yet ? 'sv_sonuclar_yet' : 'sv_sonuclar') || '[]'); } catch (e) {}
      var son = Array.isArray(g) && g.length ? g[g.length - 1] : null;
      if (!son) return fih;
      var d = (son.dersler && son.dersler[ders]) || null, x;
      if (!d) { x = (son.gruplar || []).find(function (y) { return y.ad === ders; }); if (x) d = { dogru: x.dogru, soru: x.soru }; }
      if (d && d.soru < 3 && d.grup) { x = (son.gruplar || []).find(function (y) { return y.ad === d.grup; }); if (x && x.soru >= 3) d = { dogru: x.dogru, soru: x.soru }; }
      if (!d || !d.soru) return fih;
      var oran = d.dogru / d.soru;
      var SIRA = oran < 0.5 ? { kolay: 0, orta: 1, zor: 2, cokzor: 3 } : (oran >= 0.75 ? { cokzor: 0, zor: 1, orta: 2, kolay: 3 } : null);
      if (!SIRA) return fih;
      var zr = function (f) { var m = String(f.id || '').match(/-(kolay|orta|zor|cokzor)(?=[-\/]|$)/); return f.zorluk || (m && m[1]) || 'orta'; };
      return fih.map(function (f, i) { return { f: f, i: i }; })
        .sort(function (a, b) { return (SIRA[zr(a.f)] - SIRA[zr(b.f)]) || (a.i - b.i); })
        .map(function (o) { return o.f; });
    } catch (e) { return fih; }
  }
  async function setliAc(k) {
    var fih = await fihristCek(k.sb);
    if (!fih.length) {
      return mesaj('Bu ders paketinde yok',
        'Hesabındaki paket bu dersi kapsamıyor. Ders eklemek için paketini güncelleyebilirsin.',
        dugme('../../satin-al.html', 'Paketi güncelle'));
    }
    var sira = seviyeSirala(fih), yuklu = {}, imlec = 0, bekliyor = null, durdu = false;
    function siradakiIdler(adet) {
      var ids = [];
      while (imlec < sira.length && ids.length < adet) { var id = sira[imlec++].id; if (!yuklu[id]) ids.push(id); }
      return ids;
    }
    function isle(sorular) { sorular.forEach(function (s) { yuklu[s.id] = 1; }); return sorular; }
    function hata(e) {
      if (tavanMi(e)) { tavanBildir(k.sb, e); durdu = true; uyar('Soru sınırına ulaştın: kalan sorular şimdilik getirilmedi.'); }
      else uyar('Sorular getirilemedi. Bağlantını kontrol edip sayfayı yenile.');
    }
    var ilk = isle(await parcaCek(k.sb, siradakiIdler(SET_ILK)));
    window.__KASA_FIHRIST = fih;
    window.__KASA_TOPLAM = fih.length;
    window.__KASA_SIRALI = true;
    window.__KASA_DEVAM = imlec < sira.length;
    window.__kasaSonraki = function () {
      if (bekliyor || durdu || imlec >= sira.length) return bekliyor || Promise.resolve();
      var ids = siradakiIdler(SET_ADET);
      bekliyor = parcaCek(k.sb, ids).then(function (gelen) {
        bekliyor = null;
        if (typeof window.__kasaEkle === 'function') window.__kasaEkle(isle(gelen), imlec < sira.length);
      }, function (e) { bekliyor = null; imlec -= ids.length; hata(e); });
      return bekliyor;
    };
    /* yanlış kutusundan "Şimdi çöz": henüz inmemiş soruyu tek başına getirir, akışın sonuna ekler; dönüş: kart sırası (-1 = yok) */
    window.__kasaIdGetir = function (id) {
      if (yuklu[id]) return Promise.resolve(-1);
      return parcaCek(k.sb, [id]).then(function (g) {
        if (!g.length || typeof window.__kasaEkle !== 'function') return -1;
        window.__kasaEkle(isle(g), imlec < sira.length);
        return (window.__KASA_SORULAR || []).length - 1;
      }, function (e) { hata(e); return -1; });
    };
    /* arka plan cevap kaydı: beklenmez, hata sessiz (ölçüm eksik sayar, fazla saymaz) */
    window.__kasaCevap = function (id, secim) {
      try { k.sb.rpc('kasa_cevap_yaz', { p_sayfa: sayfa, p_id: id, p_secim: secim || '?' }).then(function () {}, function () {}); } catch (e) {}
    };
    document.getElementById('akis').innerHTML = '';
    calistir(ilk);
  }

  var bekle = window.__pkKapi || Promise.resolve({ acik: false, tur: 'hata' });
  bekle.then(async function (k) {
    if (!k || !k.acik) return;             /* perde zaten çizildi */
    koruma();
    mesaj('Sorular yükleniyor…', 'Soru bankası güvenli kasadan getiriliyor.');
    if (setli) {
      try { await setliAc(k); }
      catch (e) {
        if (tavanMi(e)) { tavanBildir(k.sb, e); return tavanMesaji(e); }
        mesaj('Sorular getirilemedi', 'Bağlantını kontrol edip sayfayı yenile. Sorun sürerse bize yaz.',
          dugme(location.href, 'Yeniden dene'));
      }
      return;
    }
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
        catch (e) { if (tavanMi(e)) tavanBildir(k.sb, e); uyar(tavanMi(e) ? 'Soru sınırına ulaştın: kalan sorular bugün getirilmedi.' : 'Soruların bir kısmı getirilemedi. Bağlantını kontrol edip sayfayı yenile.'); }
        if (typeof window.__kasaEkle === 'function') window.__kasaEkle(kalan); else window.__KASA_DEVAM = false;
      } catch (e) {
        if (tavanMi(e)) { tavanBildir(k.sb, e); return tavanMesaji(e); }
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
      if (tavanMi(e)) { tavanBildir(k.sb, e); return tavanMesaji(e); }
      mesaj('Sorular getirilemedi', 'Bağlantını kontrol edip sayfayı yenile. Sorun sürerse bize yaz.',
        dugme(location.href, 'Yeniden dene'));
    }
  });
})();
