/* ============================================================================
   BOT KORUMASI (Cloudflare Turnstile) — HAZIR, KAPALI
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

   BU DOSYA ŞUNU GÖRMEZ / YAPMAZ:
     - Reklam engelleyici challenges.cloudflare.com'u keserse token alınamaz;
       ttCaptchaToken() 15 sn sonra undefined döner — panel açıksa o kişi
       giriş yapamaz ve hata mesajı görür (sayfaların trHata'sı). Ölçülmedi:
       Türkiye'de bu engelin ne kadar yaygın olduğu.
     - Canlı sınav sayfası (canli-deneme.html) giriş istemez; oraya bağlı DEĞİL.
   ============================================================================ */
(function(){
  var AYAR = window.TT_CAPTCHA = window.TT_CAPTCHA || { ACIK: false, SITE_ANAHTARI: '' };
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

  /* Her giriş/üyelik çağrısı için TAZE token (Turnstile token'ı tek kullanımlıktır).
     Kapalıyken ya da alınamazsa undefined döner — çağıran sayfa kırılmaz. */
  window.ttCaptchaToken = function(){
    if (!AYAR.ACIK || !AYAR.SITE_ANAHTARI) return Promise.resolve(undefined);
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
        setTimeout(function(){ kapat(undefined); }, 15000);
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
  };
})();
