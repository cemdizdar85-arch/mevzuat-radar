/* sinav-sonucu.js — "GERÇEK SINAV SONUCUNU BİZE YAZ" kutusu (16.09.2026)
 *
 * NEDEN: seviye testinin geçme ihtimali bugün VARSAYIMLA hesaplanıyor (seviye-model.js: zorluk etiketleri
 * gerçek adaylarla ölçülmedi, geçme sınırı TESMER yönergesindeki aralıktan kestiriliyor). UWorld ve NBME'nin
 * "geçme ihtimali" iddiası, aynı testi VE gerçek sınavı çözmüş binlerce kişinin verisinden geliyor. Bizde o
 * veri ancak adayın kendi sonucunu yazmasıyla birikir. 21.11.2026'dan sonra kalibrasyon bu kayıtlarla yapılır.
 *
 * NE TOPLAR: sınav · dönem · sonuç (geçti/kaldı/girmedi) · puan (isteğe bağlı) · e-posta (isteğe bağlı) +
 * BU CİHAZIN son seviye testi tahmini ve cihaz oturum kimliği (tahmin ile gerçeği eşleştirmek için; kimlik
 * kc_oturum, kişiye değil tarayıcıya ait). Kayıt sitenin tek form kapısından gider: radar-app/edge/form-al.ts
 * (canlı adı quick-task) -> Frankfurt kasası + bize mail. Köken listesi, bal küpü, hız sınırı sunucuda.
 *
 * KULLANIM: sayfaya <div id="ssKutu"></div> koy + <script src="sinav-sonucu.js" defer></script>
 * (KOK göreli yol için betiğin kendi src'sinden çıkarılır). Renk yazılmaz, sayfanın jetonları kullanılır.
 */
(function () {
  var betik = document.currentScript;
  var KOK = betik ? betik.src.replace(/sinav-sonucu\.js.*$/, '') : '';
  var SB = 'https://bjrleanjpyujtajmazxn.supabase.co';
  var KEY = 'sb_publishable_kTZpYwrL7skw8Ryj5Vs8_Q_-5_Fhkcg';
  /* Dönem listesi elle tazelenir; sınav takvimi değişince buraya bakılır (veri/sinav-takvimi.json ile aynı dönemler). */
  var DONEMLER = ['2026/3 (Kasım 2026)', '2027/1', '2027/2', 'daha eski'];

  function kur() {
    var kap = document.getElementById('ssKutu');
    if (!kap) return;
    var stil = document.createElement('style');
    stil.textContent =
      '#ssKutu .ss-kutu{background:var(--panel);border:1px solid var(--line);border-radius:14px;padding:16px 18px;margin:16px 0}' +
      '#ssKutu summary{cursor:pointer;font-weight:750;color:var(--ink);font-size:15.5px}' +
      '#ssKutu p{font-size:13.5px;line-height:1.6;color:var(--muted);margin:8px 0 12px}' +
      '#ssKutu .ss-satir{display:flex;gap:10px;flex-wrap:wrap;margin:0 0 10px}' +
      '#ssKutu select,#ssKutu input{font:inherit;font-size:15px;padding:10px 12px;border-radius:9px;' +
      'border:1px solid var(--line2);background:var(--bg);color:var(--ink);flex:1 1 180px;box-sizing:border-box}' +
      '#ssKutu button{font:inherit;font-size:15px;font-weight:750;cursor:pointer;border-radius:10px;padding:11px 18px;' +
      'border:1px solid var(--amber);background:var(--amber);color:var(--bg)}' +
      '#ssKutu button:disabled{opacity:.5;cursor:default}' +
      '#ssKutu .ss-durum{font-size:14px;margin-top:10px;min-height:1.3em;color:var(--muted)}' +
      '#ssKutu .ss-durum.ok{color:var(--green)} #ssKutu .ss-durum.hata{color:var(--red)}' +
      '#ssKutu .ss-gizli{position:absolute;left:-9999px;width:1px;height:1px}';
    document.head.appendChild(stil);

    var secenek = DONEMLER.map(function (d) { return '<option>' + d + '</option>'; }).join('');
    kap.innerHTML =
      '<details class="ss-kutu">' +
      '<summary>Sınava girdin mi? Gerçek sonucunu yaz — ölçümü seninle düzeltelim</summary>' +
      '<p>Bu testin verdiği ihtimal bugün varsayımla hesaplanıyor. Gerçek sonucunu yazarsan, hesabı senin gibi adayların gerçek puanlarıyla yeniden ayarlıyoruz. Puan zorunlu değil; geçtim/kaldım bile işe yarar.</p>' +
      '<form id="ssForm" novalidate>' +
      '<div class="ss-satir">' +
      '<select id="ssSinav" aria-label="Sınav"><option value="sgs">Staja Giriş (SGS)</option><option value="yeterlilik">SMMM Yeterlilik</option><option value="kgk">KGK Bağımsız Denetçilik</option></select>' +
      '<select id="ssDonem" aria-label="Dönem">' + secenek + '</select>' +
      '</div>' +
      '<div class="ss-satir">' +
      '<select id="ssDurum" aria-label="Sonuç"><option value="">Sonucun</option><option value="gecti">Geçtim</option><option value="kaldi">Kaldım</option><option value="girmedi">Girmedim</option></select>' +
      '<input type="text" id="ssPuan" inputmode="decimal" placeholder="puanın (isteğe bağlı)" aria-label="Puanın">' +
      '<input type="email" id="ssEposta" placeholder="e-posta (isteğe bağlı)" autocomplete="email" aria-label="E-posta">' +
      '</div>' +
      '<input type="text" id="ssHp" name="_hp" class="ss-gizli" tabindex="-1" autocomplete="off" aria-hidden="true">' +
      '<button type="submit" id="ssGonder">Sonucumu gönder</button>' +
      '<div class="ss-durum" id="ssDurum2" role="status"></div>' +
      '</form></details>';

    document.getElementById('ssForm').addEventListener('submit', function (e) {
      e.preventDefault();
      var d = document.getElementById('ssDurum2');
      var durum = document.getElementById('ssDurum').value;
      var puanHam = document.getElementById('ssPuan').value.trim().replace(',', '.');
      var eposta = document.getElementById('ssEposta').value.trim();
      if (!durum) { d.textContent = 'Sonucunu seç (geçtim / kaldım / girmedim).'; d.className = 'ss-durum hata'; return; }
      if (puanHam && !(parseFloat(puanHam) >= 0 && parseFloat(puanHam) <= 100)) { d.textContent = 'Puan 0 ile 100 arasında olmalı ya da boş kalmalı.'; d.className = 'ss-durum hata'; return; }
      if (eposta && !/^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(eposta)) { d.textContent = 'E-postayı doğru yaz ya da boş bırak.'; d.className = 'ss-durum hata'; return; }
      /* tahmin ile gerçeği eşleştirmek için bu cihazın son seviye testi sonucu */
      var tahmin = '-', tahminTarih = '-', oturum = '-';
      try {
        var g = JSON.parse(localStorage.getItem('sv_sonuclar') || '[]');
        if (g.length) { var s = g[g.length - 1]; tahmin = '%' + s.gecme; tahminTarih = String(s.tarih || '').slice(0, 10); }
        oturum = localStorage.getItem('kc_oturum') || '-';
      } catch (x) {}
      var dugme = document.getElementById('ssGonder'); dugme.disabled = true;
      d.textContent = 'Gönderiliyor…'; d.className = 'ss-durum';
      fetch(SB + '/functions/v1/quick-task', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', apikey: KEY, Authorization: 'Bearer ' + KEY, Accept: 'application/json' },
        body: JSON.stringify({
          subject: 'SINAV SONUCU ' + document.getElementById('ssSinav').value,
          from_name: 'Tetikte Kalibrasyon', email: eposta || '-',
          sinav: document.getElementById('ssSinav').value, donem: document.getElementById('ssDonem').value,
          sonuc: durum, puan: puanHam || '-', tahminimiz: tahmin, tahmin_tarihi: tahminTarih,
          cihaz: oturum, _hp: document.getElementById('ssHp').value
        })
      }).then(function (r) { if (!r.ok) throw 0; return r.json().catch(function () { return {}; }); })
        .then(function () { d.textContent = 'Teşekkürler, aldık. Ölçümü bu tür sonuçlarla düzeltiyoruz.'; d.className = 'ss-durum ok'; document.getElementById('ssForm').reset(); })
        .catch(function () { d.textContent = 'Şu an gönderilemedi. Biraz sonra yeniden dene.'; d.className = 'ss-durum hata'; dugme.disabled = false; });
    });
  }

  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', kur); else kur();
})();
