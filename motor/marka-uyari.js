#!/usr/bin/env node
/* ===========================================================================
   MARKA NÖBETİ — UYARI GÖNDERİCİ  (30.08.2026)

   Cem: "uyarı bacağını kur."

   NE YAPAR: marka_takip'teki her aktif nöbet için, Resmî Marka Bülteni
   ambarında benzeyen ve İTİRAZ SÜRESİ AÇIK başvuru var mı bakar; varsa
   e-posta atar ve "yazdım" diye işaretler.

   ÜÇ KURAL (üçü de sunucuda, bu betik onlara güvenir ama TEYİT de eder):
    1) Aynı başvuru iki kez uyarılmaz  -> marka_takip_gonderim
    2) Süresi dolmuş başvuru uyarılmaz -> itiraz_son >= current_date
    3) Kendi markası kendine bildirilmez

   SIRA ÖNEMLİ: önce MAİL GİDER, sonra işaretlenir. Tersi olursa mail
   atılamayan bir kayıt "gönderildi" sayılır ve uyarı SESSİZCE KAYBOLUR.
   Kaçan itiraz süresi geri gelmez; bu yüzden hata durumunda işaretlemiyoruz.

   ENV: SUPABASE_SERVICE_KEY (zorunlu) · RESEND_KEY · RESEND_FROM
   Kullanım:
     node motor/marka-uyari.js            (gönder)
     node motor/marka-uyari.js --kuru     (gönderme, yalnız ölç ve göster)
   =========================================================================== */
'use strict';

const SB_URL = process.env.SUPABASE_URL || 'https://bjrleanjpyujtajmazxn.supabase.co';
const SB_KEY = sir('SUPABASE_SERVICE_KEY');
/* 31.08 CANLI ARIZA: RESEND_KEY'in basinda U+FEFF (BOM) vardi. fetch basligi
   ByteString ister; "character at index 7 has a value of 65279" deyip patladi
   ve uyari maili HIC gitmedi - ustelik sessizce degil, ama tek satirlik bir
   hata olarak. Panele yapistirirken bulasmis olmali.
   Sirlar artik ayiklanir: BOM, sifir genislikli karakterler ve bosluklar. */
function sir(ad) {
  return String(process.env[ad] || '')
    .replace(/^\uFEFF/, '')
    .replace(/[\u200B-\u200D\u2060]/g, '')
    .trim();
}
const RESEND = sir('RESEND_KEY');
const FROM = sir('RESEND_FROM') || 'Tetikte <bildirim@tetikte.com>';
const SITE = 'https://tetikte.com';
const KURU = process.argv.includes('--kuru');
const TAVAN = 25;                    // bir mailde en fazla kaç başvuru

const log = (...s) => console.log(...s);
const esc = s => String(s == null ? '' : s)
  .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');

async function rpc(ad, govde) {
  const r = await fetch(`${SB_URL}/rest/v1/rpc/${ad}`, {
    method: 'POST',
    headers: { apikey: SB_KEY, Authorization: 'Bearer ' + SB_KEY, 'Content-Type': 'application/json' },
    body: JSON.stringify(govde || {})
  });
  const t = await r.text();
  if (!r.ok) throw new Error(`${ad}: HTTP ${r.status} ${t.slice(0, 200)}`);
  return t ? JSON.parse(t) : null;
}

/* --- Mail gövdesi ---------------------------------------------------------
   Tek iş yapar: "şu başvuru senin markana benziyor, süren şu gün doluyor."
   Süslemez, abartmaz, hukuki tavsiye vermez - itirazı vekil yapar.        */
function mailGovde(takipAd, kayitlar, jeton, hatirlatmaMi) {
  const enYakin = Math.min(...kayitlar.map(k => k.kalan_gun));
  const yuksek = kayitlar.filter(k => k.kademe === 'YUKSEK').length;
  const tek = kayitlar.length === 1;

  const satir = kayitlar.slice(0, TAVAN).map(k => `
    <tr><td style="padding:12px 14px;border-bottom:1px solid #e6e8eb">
      <div style="font-weight:700;font-size:16px">${esc(k.ad)}</div>
      <div style="font-size:12px;color:#5d6b7c;margin-top:3px">
        başvuru ${esc(k.basvuru_no)}${k.sinif && k.sinif.length ? ' · sınıf ' + esc(k.sinif.join(', ')) : ''}
        · ${esc(k.bulten_no)} sayılı bültende ${esc(k.yayin_tarihi)}
      </div>
      ${k.sahip ? `<div style="font-size:12px;color:#5d6b7c;margin-top:3px"><b>Başvuru sahibi:</b> ${esc(k.sahip)}</div>` : ''}
      <div style="font-size:13.5px;margin-top:8px">
        ${k.kademe === 'YUKSEK'
          ? '<b style="color:#c62828">YAKIN BENZERLİK</b>'
          : '<b style="color:#a1670b">İHTİMAL</b>'}
        — ${esc(k.sebep || '')}${k.ayni_sinif ? ' · <b style="color:#c62828">AYNI SINIF</b>' : ''}
      </div>
      <div style="font-size:13px;margin-top:6px">
        İtiraz için son gün <b>${esc(k.itiraz_son)}</b> — <b>${k.kalan_gun} gün</b> kaldı.
      </div>
    </td></tr>`).join('');

  const giris = hatirlatmaMi
    ? `<p style="font-size:16px;margin:0 0 10px">Merhaba,</p>
       <p style="font-size:15px;line-height:1.6;margin:0 0 14px">
         <b>“${esc(takipAd)}”</b> markanız için size daha önce yazmıştık ama henüz bir haber
         alamadık. Süre işlediği için bir kez daha hatırlatmak istedik —
         <b>${enYakin} gün</b> kaldı ve bu süre uzatılamıyor.</p>`
    : `<p style="font-size:16px;margin:0 0 10px">Merhaba,</p>
       <p style="font-size:15px;line-height:1.6;margin:0 0 14px">
         <b>“${esc(takipAd)}”</b> markanızı sizin adınıza takip ediyoruz.
         Resmî Marka Bülteni'nde ${tek ? 'markanıza yakın bir başvuru' : `markanıza yakın ${kayitlar.length} başvuru`}
         yayımlandı${yuksek ? '' : ''} ve bunu <b>hemen bilmenizi</b> istedik.</p>`;

  return `<div style="font-family:-apple-system,Segoe UI,Roboto,Arial,sans-serif;max-width:640px;margin:0 auto;color:#101418">
  ${giris}

  <table style="width:100%;border-collapse:collapse;border:1px solid #e6e8eb;border-radius:10px">${satir}</table>
  ${kayitlar.length > TAVAN ? `<p style="font-size:12px;color:#5d6b7c">… ${kayitlar.length - TAVAN} başvuru daha var.</p>` : ''}

  <div style="margin:20px 0 0;padding:16px 18px;background:#f4f7fb;border-left:4px solid #1f6feb;border-radius:8px">
    <div style="font-weight:700;font-size:15px;margin-bottom:6px">Şimdi ne yapalım?</div>
    <p style="font-size:14px;line-height:1.65;margin:0 0 10px">
      <b>Bu maili yanıtlamanız yeterli.</b> Markanızın tescil durumunu, kullanım
      belgelerinizi ve bu başvurunun sizi gerçekten etkileyip etkilemediğini
      birlikte gözden geçirelim; itiraza değer mi değmez mi, bunu boşa masraf
      etmeden konuşalım.</p>
    <p style="font-size:14px;line-height:1.65;margin:0">
      Yanıtınızı <b>bekliyoruz</b>. Bir haber alamazsak süre dolmadan önce size
      <b>bir kez daha yazacağız</b> — ama son günü beklemeyelim, itiraz hazırlığı
      zaman istiyor.</p>
  </div>

  <p style="font-size:14px;line-height:1.6;margin:18px 0 0">
    İtiraz süresi bültende yayımdan itibaren <b>iki aydır (SMK m.18)</b> ve
    <b>uzatılamaz</b>. Bu süre geçtikten sonra aynı gerekçeyle itiraz edilemez;
    o yüzden takibi sizin adınıza biz yapıyoruz.</p>

  <p style="font-size:14px;margin:16px 0 0">
    Karşılaştırmayı kendiniz de görebilirsiniz:
    <a href="${SITE}/marka-itiraz.html">${SITE}/marka-itiraz.html</a></p>

  <p style="font-size:12.5px;color:#5d6b7c;margin:20px 0 0;line-height:1.6">
    <b>Kademeler:</b> <b>YAKIN BENZERLİK</b> = markanız başvuruda bir kelime olarak
    geçiyor ya da kısaltılmış hâline benziyor. <b>İHTİMAL</b> = yazılışı yakın,
    karıştırılma tartışılabilir. Karıştırılma ihtimali görsel, işitsel ve
    kavramsal benzerliğin <b>bütünüyle</b> değerlendirilir (SMK m.6/1).</p>

  <p style="font-size:12.5px;color:#5d6b7c;margin:12px 0 0;line-height:1.6">
    <b>Bilmenizi isteriz:</b> markanız <b>5 yıldan eski tescilliyse ve
    kullanmıyorsanız</b>, karşı taraf <b>kullanmama def'i</b> ileri sürebilir ve
    itirazınız reddedilir (SMK m.19/2) — bu yüzden kullanım delillerinizi
    (fatura, reklam, ambalaj) şimdiden hazırlayın.
    İtiraz başvurusunu TÜRKPATENT'e <b>marka vekiliniz</b> yapar; biz takibi ve
    değerlendirmeyi üstleniyoruz, dosyalama vekilin işidir. Bu bir bildirim ve
    değerlendirmedir, hukuki mütalaa değildir.</p>

  <p style="font-size:14px;margin:22px 0 0">Kolay gelsin,<br>
    <b>Tetikte — Marka Nöbeti</b></p>

  <p style="font-size:11px;color:#8a93a0;margin:18px 0 0">
    Bu nöbeti siz kurdunuz.
    <a href="${SITE}/marka-itiraz.html?nobet=kapat&jeton=${encodeURIComponent(jeton)}">Nöbeti kapat</a></p>
</div>`;
}

async function mailGonder(kime, konu, html) {
  if (!RESEND) throw new Error('RESEND_KEY yok - mail gonderilemez');
  const r = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: { Authorization: 'Bearer ' + RESEND, 'Content-Type': 'application/json' },
    /* reply_to ZORUNLU: mail "bu maili yanitlayin" diyor. Yanit gidecek bir
       adres yoksa cagri bos soz olur. RESEND_YANIT verilmezse gonderen adrese
       doner - o kutu izlenmiyorsa cagri karsiliksiz kalir, Cem'e soruldu. */
    body: JSON.stringify({ from: FROM, to: [kime], subject: konu, html,
                           reply_to: sir('RESEND_YANIT') || FROM })
  });
  const t = await r.text();
  if (!r.ok) throw new Error(`Resend HTTP ${r.status}: ${t.slice(0, 200)}`);
  return t;
}

(async () => {
  if (!SB_KEY) { console.error('!! SUPABASE_SERVICE_KEY yok'); process.exit(1); }

  /* KADEME OZ-SINAVI - gercek veriye dokunmadan, bilinen ciftlerle.
     31.08'de kademe mantigini ELLE sinamistim; o sinav hicbir yerde
     durmuyordu. Mantik degisirse (esik, uzunluk kurali, kelime siniri)
     bozuldugunu kimse fark etmezdi: uyarilar SESSIZCE yanlislasirdi.
     Dusen sinav varsa mail GONDERILMEZ - yanlis uyari yollamaktansa hic
     yollamamak iyidir. */
  try {
    const sinav = await rpc('marka_kademe_sinav');
    const dusen = (sinav || []).filter(x => x.sonuc !== 'GECTI');
    if (dusen.length) {
      console.error('!! KADEME OZ-SINAVI DUSTU - mail gonderilmiyor:');
      dusen.forEach(x => console.error(
        '   ' + x.marka + ' <- ' + x.aday + ': beklenen ' + x.beklenen + ', cikan ' + x.cikan));
      process.exit(1);
    }
    log('Kademe oz-sinavi gecti (' + (sinav || []).length + ' cift).');
  } catch (e) {
    // Sinav CAGRILAMADIYSA da durulur: olculmemis mantikla mail atilmaz.
    console.error('!! Kademe oz-sinavi calistirilamadi: ' + e.message);
    console.error('   SQL basilmamis olabilir (veri/sql-marka-takip.sql). Mail gonderilmiyor.');
    process.exit(1);
  }

  const sayac = (await rpc('marka_takip_sayac'))[0] || {};
  log(`Aktif nöbet: ${sayac.aktif_nobet || 0} · bugüne kadar uyarılan başvuru: ${sayac.uyarilan || 0}`);

  const bekleyen = await rpc('marka_takip_bekleyen', { p_tavan: 2000 });
  if (!bekleyen.length) { log('Bekleyen uyarı yok.'); return; }

  // Nöbet başına grupla: kullanıcıya 30 ayrı mail değil, TEK mail gider.
  const grup = new Map();
  for (const x of bekleyen) {
    if (!grup.has(x.takip_id)) grup.set(x.takip_id, { eposta: x.eposta, jeton: x.jeton, ad: x.takip_ad, k: [] });
    grup.get(x.takip_id).k.push(x);
  }
  log(`${bekleyen.length} eşleşme · ${grup.size} nöbet · ${KURU ? 'KURU (mail YOK)' : 'mail gönderilecek'}`);

  let gonderilen = 0, hatali = 0, isaretlenen = 0;
  for (const [id, g] of grup) {
    const enYakin = Math.min(...g.k.map(x => x.kalan_gun));
    /* KONU SATIRI: ilk uyari mi hatirlatma mi, ve kademe - ucu birden konuda.
       Her uyariyi ayni sertlikte yazmak zamanla hepsinin okunmamasina yol acar;
       hatirlatmanin ayri dille yazilmasi da "bizi hatirliyorlar" duygusunu
       veriyor (Cem: "onlarla ilgilendigimizi gostermemiz lazim"). */
    const hatirlatmaMi = g.k.every(x => x.tur === 'hatirlatma');
    const yuksek = g.k.filter(x => x.kademe === 'YUKSEK').length;
    const konu = hatirlatmaMi
      ? `Hatırlatma: “${g.ad}” markanız için itiraza ${enYakin} gün kaldı`
      : yuksek
        ? `“${g.ad}” markanıza YAKIN ${yuksek} başvuru yayımlandı — itiraza ${enYakin} gün`
        : `“${g.ad}” markanıza benzeme ihtimali olan ${g.k.length} başvuru — itiraza ${enYakin} gün`;
    log(`  ${g.eposta} · "${g.ad}" · ${g.k.length} başvuru · en yakın ${enYakin} gün · ${hatirlatmaMi ? 'HATIRLATMA' : 'ilk uyarı'}`);
    g.k.slice(0, 4).forEach(x => log(`      [${x.kademe}] ${x.ad} · %${Math.round(x.benzerlik * 100)}${x.ayni_sinif ? ' · AYNI SINIF' : ''} · ${x.kalan_gun} gün · ${x.sebep}`));
    if (KURU) continue;

    try {
      // ÖNCE MAİL, SONRA İŞARET. Tersi, atılamayan uyarıyı sessizce yutar.
      await mailGonder(g.eposta, konu, mailGovde(g.ad, g.k, g.jeton, hatirlatmaMi));
      gonderilen++;
      const n = await rpc('marka_takip_isaretle', {
        p_takip_id: id,
        p_kayitlar: g.k.map(x => ({ no: x.basvuru_no, bulten: x.bulten_no }))
      });
      isaretlenen += Number(n) || 0;
    } catch (e) {
      hatali++;
      console.error(`   !! ${g.eposta}: ${e.message}`);
      // İŞARETLEMİYORUZ: sonraki koşu tekrar dener. Kaçan süre geri gelmez.
    }
  }
  log(`\nBITTI: ${gonderilen} mail, ${isaretlenen} başvuru işaretlendi, ${hatali} hata.`);
  if (hatali) process.exit(1);
})().catch(e => { console.error('!! ISTISNA: ' + (e && e.stack || e)); process.exit(1); });
