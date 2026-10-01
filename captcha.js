/* ============================================================================
   BOT KORUMASI (Cloudflare Turnstile) — SİTE TARAFI AÇIK (01.10), SUPABASE PANELİ KAPALI
   23.09.2026, Cem "2 yap": turnstile'lı formlar hazır dursun, canlıya alınmasın.

   NEDEN: 23.09'da e-posta onayı kapatıldı; sahte hesap açmak kolaylaştı. Koruma
   4 Ekim sonrasına bırakıldı ama saldırı gelirse AYNI GÜN açılabilsin diye
   kod şimdiden 5 sayfada (ogrenci, radar-app, evrak-app, marka-app, deneme)
   10 giriş/üyelik çağrısına bağlı.

   KAPALIYKEN (ACIK:false) SİTEDE HİÇBİR ŞEY DEĞİŞMEZ: ttCaptchaToken() ağa
   gitmez, undefined döner; supabase-js zaten her istekte boş
   gotrue_meta_security gönderiyor, gövde bayt bayt aynı kalır.

   ⛔ AÇMA SIRASI — SIRA ÖNEMLİ:
     1) Cloudflare → Turnstile → site ekle (tetikte.com), mod "Invisible"
        (ya da "Managed") → SİTE ANAHTARI + GİZLİ ANAHTAR alınır.
     2) Bu dosyada SITE_ANAHTARI yazılır, ACIK:true yapılır, yayına alınır.
        Bu adım TEK BAŞINA ZARARSIZDIR: Supabase'de captcha kapalıyken
        gönderilen token yok sayılır.
     3) 5 sayfada giriş + üyelik tarayıcıda denenir.
     4) ANCAK SONRA Supabase → Authentication → Attack Protection →
        "Enable Captcha protection" → Turnstile + GİZLİ ANAHTAR → Save.
     TERS SIRA (önce panel) = sitede KİMSE giriş yapamaz, üye olamaz.

   📱 MAĞAZA UYGULAMASI (26.09.2026): bu dosya uygulamaya da kopyalanır (mobil/hazirla.js) ve uygulamanın
     üye ol / giriş / şifre yenileme çağrılarına bağlıdır. Uygulama sayfası tetikte.com'dan DEĞİL, telefonun
     içinden açılır: Android https://localhost, iPhone capacitor://localhost. Bu yüzden panel açılmadan önce:
       a) Turnstile sitesinin alan adlarına "localhost" da eklenir,
       b) captcha açık bu dosyayla yeni uygulama sürümü derlenir ve İKİ telefonda giriş + üyelik denenir
          (ÖLÇÜLMEDİ: Turnstile'ın iPhone capacitor:// adresinde çalışıp çalışmadığı),
       c) kullanıcıların çoğu bu sürüme geçmeden panel açılmaz — eski sürümde giriş tamamen durur.

   BU DOSYA ŞUNU GÖRMEZ / YAPMAZ:
     - Reklam engelleyici challenges.cloudflare.com'u keserse token alınamaz;
       ttCaptchaToken() 15 sn sonra undefined döner — panel açıksa o kişi
       giriş yapamaz ve hata mesajı görür (sayfaların trHata'sı). Ölçülmedi:
       Türkiye'de bu engelin ne kadar yaygın olduğu.
     - Canlı sınav sayfası (canli-deneme.html) giriş istemez; oraya bağlı DEĞİL.
   ============================================================================ */
(function(){
  /* 01.10.2026 Cem: AÇILDI (adım 2). Site anahtarı herkese açıktır, gizli anahtar yalnız Supabase panelinde. */
  var AYAR = window.TT_CAPTCHA = window.TT_CAPTCHA || { ACIK: true, SITE_ANAHTARI: '0x4AAAAAAFLbkRtRcjMK9cnY' };
  var BETIK = 'https://challenges.cloudflare.com/turnstile/v0/api.js?render=explicit';
  var betikSozu = null;

  function betikYukle(){
    if (window.turnstile) return Promise.resolve();
    if (betikSozu) return betikSozu;
    betikSozu = new Promise(function(coz, reddet){
      var s = document.createElement('script');
      s.src = BETIK; s.async = true;
      s.onload = function(){ coz(); };
      s.onerror = function(){ betikSozu = null; reddet(new Error('turnstile betigi yuklenemedi')); };
      document.head.appendChild(s);
    });
    return betikSozu;
  }

  /* 02.10.2026 Cem "1.2.3 yap": ÖN-ALIM + TEKRAR. 01.10 ölçümü (Cem'in Chrome'u, 3 deneme):
     token düğmeye basınca isteniyordu → 6–8 sn bekleme, 3'te 1 15 sn'de gelmedi.
     Şimdi: sayfa açılınca bir token arka planda alınır ve bekletilir (Turnstile token'ı
     300 sn geçerli, tek kullanımlık → 270 sn'den eskisi atılır). Düğmeye basınca hazırsa
     anında verilir ve yerine yenisi alınmaya başlanır; gelmezse bir kez daha denenir. */
  var OMUR_MS = 270000, SURE_MS = 20000;
  var hazir = null;      // { token, an }
  var yolda = null;      // arka planda süren alım sözü

  function tekAl(){
    return betikYukle().then(function(){
      return new Promise(function(coz){
        var kap = document.createElement('div');
        kap.style.cssText = 'position:fixed;right:12px;bottom:12px;z-index:100000';
        document.body.appendChild(kap);
        var bitti = false, kimlik = null;
        var kapat = function(deger){
          if (bitti) return; bitti = true;
          try { if (kimlik !== null) window.turnstile.remove(kimlik); } catch(e){}
          if (kap.parentNode) kap.parentNode.removeChild(kap);
          coz(deger);
        };
        setTimeout(function(){ kapat(undefined); }, SURE_MS);
        try {
          kimlik = window.turnstile.render(kap, {
            sitekey: AYAR.SITE_ANAHTARI,
            appearance: 'interaction-only',          // yalnız etkileşim gerekirse görünür
            callback: function(token){ kapat(token); },
            'error-callback': function(){ kapat(undefined); },
            'expired-callback': function(){ kapat(undefined); }
          });
        } catch(e){ kapat(undefined); }
      });
    }).catch(function(){ return undefined; });
  }

  /* Arka planda bir token al ve beklet (aynı anda tek alım). */
  function onAl(){
    if (yolda) return yolda;
    yolda = tekAl().then(function(t){
      yolda = null;
      if (t) hazir = { token: t, an: Date.now() };
      return t;
    });
    return yolda;
  }
  function bekleyeniAl(){
    if (hazir && Date.now() - hazir.an < OMUR_MS){ var t = hazir.token; hazir = null; return t; }
    hazir = null; return undefined;
  }

  /* Her giriş/üyelik çağrısı için TEK KULLANIMLIK token. Kapalıyken ya da iki denemede
     alınamazsa undefined döner — çağıran sayfa kırılmaz. */
  window.ttCaptchaToken = function(){
    if (!AYAR.ACIK || !AYAR.SITE_ANAHTARI) return Promise.resolve(undefined);
    var t = bekleyeniAl();
    if (t){ onAl(); return Promise.resolve(t); }
    var dene = function(){ return onAl().then(function(){ return bekleyeniAl(); }); };
    return dene().then(function(t1){
      if (t1){ onAl(); return t1; }
      return dene().then(function(t2){ if (t2) onAl(); return t2; });
    });
  };

  /* Sayfa açılınca ilk token'ı arka planda hazırla. */
  if (AYAR.ACIK && AYAR.SITE_ANAHTARI){
    if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', function(){ onAl(); });
    else onAl();
  }
})();
