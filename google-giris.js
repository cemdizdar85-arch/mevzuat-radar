/* ============================================================================
   GOOGLE İLE DEVAM ET — site (27.09.2026, Cem: mobilde 1.6.0 ile kuruldu, siteye de)
   Web akışı: sb.auth.signInWithOAuth → Supabase /authorize → Google → Supabase /callback → bu sayfa
   (#access_token; supabase-js detectSessionInUrl oturumu kendisi kurar). Uygulamadaki signInWithIdToken DEĞİL.

   KULLANIM (sayfada, supabase istemcisi KURULMADAN ÖNCE yüklenir — dönüşte ?sonra= geri konur):
     <script src="google-giris.js"></script>  ...  window.ttGoogle.kur({ sb: sb, kap: kutuElemani, ayrac: true })

   ONAY: düğmenin ÜSTÜNDE "Devam ederek üyelik sözleşmesini ve aydınlatma metnini kabul etmiş olursun."
   Tıklama anı bu sekmede (sessionStorage) saklanır; dönüşte user_metadata.kosul_kabul YOKSA e-postalı üyelikle AYNI
   alanlar yazılır: hesap_turu 'ogrenci' · kaynak 'site-google' · kosul_kabul (tıklama anı) · pazarlama_rizasi false ·
   riza_tarihi null. Pazarlama rızası Google'da VERİLMİŞ SAYILMAZ (İYS) — ayrıca istenir.
   Var olan hesap (kosul_kabul dolu) Google'la bağlanırsa hiçbir alana dokunulmaz.

   CAPTCHA: signInWithOAuth captchaToken ALMAZ; Supabase captcha koruması e-posta/şifre uçlarındadır, /authorize'da
   değil. captcha.js açılsa da bu düğmeye bir şey eklenmez.

   RENK: Google marka kuralı — beyaz zemin, #1f1f1f yazı, #747775 çerçeve, renkli G. Bu üç sabit bilerek sabittir
   (tema jetonu olursa koyu temada Google düğmesi olmaktan çıkar); renk-sabiti tabanında bu dosyaya 3 yazıldı.

   BU DOSYA ŞUNU GÖRMEZ / YAPMAZ:
     - Supabase → Authentication → URL Configuration listesinde dönüş adresi yoksa Supabase kişiyi "Site URL"e
       gönderir (27.09 ölçümü: Site URL http://localhost:3000, tetikte.com listede YOK). Bunu koddan düzeltemez.
     - Kişi Google'a gidip başka sekmede dönerse onay anı o sekmede yoktur → kosul_kabul YAZILMAZ (yanlış onay
       yazmaktansa boş bırakır; sonraki Google tıklamasında yazılır).
   ============================================================================ */
(function(){
  'use strict';
  var ONAY = 'tt_google_onay', ARAMA = 'tt_google_arama';
  var ss = { al: function(k){ try { return sessionStorage.getItem(k); } catch(e){ return null; } },
             koy: function(k, v){ try { sessionStorage.setItem(k, v); } catch(e){} },
             sil: function(k){ try { sessionStorage.removeItem(k); } catch(e){} } };

  /* Google'dan dönüş: ?sonra= gibi arama kısmı redirectTo'ya konmaz (izin listesi tam adresle eşleşsin diye);
     burada geri konur. Hash'e dokunulmaz — supabase-js onu okuyacak. */
  var donus = /(?:^#|&)(?:access_token|error_description|error)=/.test(location.hash);
  var donusHatasi = '';
  if (donus) {
    var ara = ss.al(ARAMA);
    if (ara && !location.search) { try { history.replaceState(history.state, '', location.pathname + ara + location.hash); } catch(e){} }
    ss.sil(ARAMA);
    var hp = new URLSearchParams(location.hash.replace(/^#/, ''));
    if (hp.get('error') || hp.get('error_description')) {
      var ac = hp.get('error_description') || '';
      /* kişi Google penceresinde "İptal"e bastıysa hata yazma */
      donusHatasi = /access_denied|cancel/i.test((hp.get('error') || '') + ' ' + ac) && !/expired|invalid/i.test(ac)
        ? '' : 'Google girişi tamamlanmadı. Tekrar dene ya da e-postayla devam et.';
    }
  }

  var G_SVG = '<svg viewBox="0 0 48 48" aria-hidden="true" focusable="false"><path fill="#EA4335" d="M24 9.5c3.5 0 6.6 1.2 9.1 3.6l6.8-6.8C35.8 2.4 30.3 0 24 0 14.6 0 6.6 5.4 2.7 13.3l7.9 6.1C12.5 13.6 17.8 9.5 24 9.5z"/><path fill="#4285F4" d="M46.1 24.5c0-1.6-.1-3.1-.4-4.5H24v9h12.4c-.5 2.9-2.2 5.3-4.6 6.9l7.4 5.7c4.3-4 6.9-9.9 6.9-17.1z"/><path fill="#FBBC05" d="M10.6 28.6c-.5-1.4-.8-3-.8-4.6s.3-3.2.8-4.6l-7.9-6.1C1 16.6 0 20.2 0 24s1 7.4 2.7 10.7l7.9-6.1z"/><path fill="#34A853" d="M24 48c6.5 0 11.9-2.1 15.9-5.8l-7.4-5.7c-2.1 1.4-4.8 2.3-8.5 2.3-6.2 0-11.5-4.1-13.4-9.9l-7.9 6.1C6.6 42.6 14.6 48 24 48z"/></svg>';

  function stilKoy(){
    if (document.getElementById('ttGoogleStil')) return;
    var s = document.createElement('style'); s.id = 'ttGoogleStil';
    s.textContent =
      '.tt-google-not{font-size:12.5px;line-height:1.5;color:var(--muted);margin:0 0 8px}' +
      '.tt-google-not a{color:var(--amber)}' +
      '.tt-google{display:flex;align-items:center;justify-content:center;gap:12px;width:100%;box-sizing:border-box;min-height:44px;padding:10px 16px;' +
        'border-radius:999px;border:1px solid #747775;background:#fff;color:#1f1f1f;' +
        'font-family:inherit;font-size:15px;font-weight:600;line-height:1.2;cursor:pointer}' +
      '.tt-google:hover{box-shadow:0 1px 3px color-mix(in srgb,var(--ink) 30%,transparent)}' +
      '.tt-google:focus-visible{outline:2px solid var(--amber);outline-offset:2px}' +
      '.tt-google:disabled{opacity:.6;cursor:wait}' +
      '.tt-google svg{width:20px;height:20px;flex:none}' +
      '.tt-google-hata{font-size:13px;color:var(--red);margin:6px 0 0}' +
      '.tt-google-hata:empty{display:none}' +
      '.tt-google-ayrac{display:flex;align-items:center;gap:10px;margin:14px 0 2px;font-size:12.5px;color:var(--muted)}' +
      '.tt-google-ayrac::before,.tt-google-ayrac::after{content:"";flex:1;border-top:1px solid var(--line)}';
    document.head.appendChild(s);
  }

  /* İlk Google girişinde onay alanları — e-postalı üyelikle AYNI anahtarlar (ogrenci.html signUp). */
  async function ilkGiris(sb, user){
    if (!user) return;
    var googleMu = (user.app_metadata && (user.app_metadata.provider === 'google' ||
      (user.app_metadata.providers || []).indexOf('google') > -1)) ||
      (user.identities || []).some(function(i){ return i && i.provider === 'google'; });
    var onay = ss.al(ONAY);
    if (!googleMu || !onay) return;
    var meta = user.user_metadata || {};
    ss.sil(ONAY);
    if (meta.kosul_kabul) return;
    await sb.auth.updateUser({ data: { hesap_turu: meta.hesap_turu || 'ogrenci', kaynak: meta.kaynak || 'site-google',
      kosul_kabul: onay, pazarlama_rizasi: false, riza_tarihi: null } });
  }

  function kur(o){
    var sb = o && o.sb, kap = o && o.kap;
    if (!sb || !kap || !sb.auth || !sb.auth.signInWithOAuth) return;
    stilKoy();
    kap.innerHTML =
      '<p class="tt-google-not">Devam ederek <a href="uyelik-sozlesmesi.html" target="_blank" rel="noopener">üyelik sözleşmesini</a> ve ' +
      '<a href="kvkk.html" target="_blank" rel="noopener">aydınlatma metnini</a> kabul etmiş olursun.</p>' +
      '<button type="button" class="tt-google">' + G_SVG + '<span>Google ile devam et</span></button>' +
      '<p class="tt-google-hata" role="alert"></p>' +
      (o.ayrac ? '<div class="tt-google-ayrac">ya da e-postayla</div>' : '');
    var b = kap.querySelector('.tt-google'), h = kap.querySelector('.tt-google-hata');
    h.textContent = donusHatasi;
    b.addEventListener('click', async function(){
      h.textContent = ''; b.disabled = true;
      ss.koy(ONAY, new Date().toISOString());
      ss.koy(ARAMA, location.search || '');
      try {
        var r = await sb.auth.signInWithOAuth({ provider: 'google', options: { redirectTo: location.origin + location.pathname } });
        if (r && r.error) throw r.error;
        /* başarılıysa sayfa Google'a gider; buraya dönülmez */
      } catch(e) {
        ss.sil(ONAY); ss.sil(ARAMA);
        h.textContent = 'Google girişi açılamadı. Tekrar dene ya da e-postayla devam et.';
        b.disabled = false;
      }
    });
    /* onAuthStateChange içinde doğrudan Supabase çağrısı kilitlenebilir (supabase-js uyarısı) → setTimeout */
    sb.auth.onAuthStateChange(function(olay, oturum){
      if (!oturum || (olay !== 'SIGNED_IN' && olay !== 'INITIAL_SESSION')) return;
      setTimeout(function(){ ilkGiris(sb, oturum.user).catch(function(){}); }, 0);
    });
  }

  window.ttGoogle = { kur: kur, ilkGiris: ilkGiris };
})();
