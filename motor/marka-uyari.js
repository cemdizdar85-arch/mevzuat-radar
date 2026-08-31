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
function mailGovde(takipAd, kayitlar, jeton) {
  const enYakin = Math.min(...kayitlar.map(k => k.kalan_gun));
  const satir = kayitlar.slice(0, TAVAN).map(k => `
    <tr>
      <td style="padding:10px 12px;border-bottom:1px solid #e6e8eb">
        <div style="font-weight:700;font-size:15px">${esc(k.ad)}</div>
        <div style="font-size:12px;color:#5d6b7c;margin-top:2px">
          başvuru ${esc(k.basvuru_no)}${k.sinif && k.sinif.length ? ' · sınıf ' + esc(k.sinif.join(', ')) : ''}
          · ${esc(k.bulten_no)} sayılı bültende ${esc(k.yayin_tarihi)}
        </div>
        ${k.sahip ? `<div style="font-size:12px;color:#5d6b7c;margin-top:2px"><b>Sahibi:</b> ${esc(k.sahip)}</div>` : ''}
        <div style="font-size:13px;margin-top:6px">
          ${k.kademe === 'YUKSEK'
            ? '<b style="color:#c62828">YAKIN BENZERLİK</b>'
            : '<b style="color:#a1670b">İHTİMAL</b>'}
          — ${esc(k.sebep || '')}${k.ayni_sinif ? ' · <b style="color:#c62828">AYNI SINIF</b>' : ''}
        </div>
        <div style="font-size:12px;color:#5d6b7c;margin-top:4px">
          harf benzerliği %${Math.round((k.benzerlik || 0) * 100)}
          · itiraz son gün <b>${esc(k.itiraz_son)}</b> (<b>${k.kalan_gun} gün</b>)
        </div>
      </td>
    </tr>`).join('');

  return `<div style="font-family:-apple-system,Segoe UI,Roboto,Arial,sans-serif;max-width:640px;margin:0 auto;color:#101418">
  <p style="font-size:16px;margin:0 0 4px"><b>“${esc(takipAd)}” markanıza benzer ${kayitlar.length} yeni başvuru yayımlandı.</b></p>
  <p style="font-size:14px;color:#5d6b7c;margin:0 0 16px">
    En yakın itiraz süresi <b>${enYakin} gün</b> sonra doluyor. İtiraz süresi bültende yayımdan itibaren
    <b>iki aydır (SMK m.18)</b> ve <b>uzatılamaz</b>.</p>
  <table style="width:100%;border-collapse:collapse;border:1px solid #e6e8eb;border-radius:10px">${satir}</table>
  ${kayitlar.length > TAVAN ? `<p style="font-size:12px;color:#5d6b7c">… ${kayitlar.length - TAVAN} başvuru daha var.</p>` : ''}
  <p style="font-size:13px;margin:18px 0 0">
    Ayrıntılı karşılaştırma: <a href="${SITE}/marka-itiraz.html">${SITE}/marka-itiraz.html</a></p>
  <p style="font-size:12px;color:#5d6b7c;margin:14px 0 0;line-height:1.55">
    <b>Kademeler ne demek:</b> <b>YAKIN BENZERLİK</b> = markanız başvuruda bir kelime olarak
    geçiyor ya da kısaltılmış hâline benziyor. <b>İHTİMAL</b> = yazılışı yakın, karıştırılma
    tartışılabilir. Karıştırılma ihtimali görsel, işitsel ve kavramsal benzerliğin
    <b>bütünüyle</b> değerlendirilir (SMK m.6/1); son kararı TÜRKPATENT ve mahkeme verir.
    Biz “bakmaya değer” diyoruz, “itiraz et” demiyoruz.<br><br>
    <b>İtiraz etmeden önce:</b> markanız <b>5 yıldan eski tescilliyse ve kullanmıyorsanız</b>, karşı taraf
    <b>kullanmama def’i</b> ileri sürebilir ve itirazınız reddedilir (SMK m.19/2). Kullanım delillerinizi
    (fatura, reklam, ambalaj) hazırlayın. İtiraz başvurusunu TÜRKPATENT’e siz ya da marka vekiliniz yapar —
    <b>biz dosyalamıyoruz</b>, bu bir bildirimdir, hukuki tavsiye değildir.</p>
  <p style="font-size:11px;color:#8a93a0;margin:16px 0 0">
    Bu nöbeti siz kurdunuz.
    <a href="${SITE}/marka-itiraz.html?nobet=kapat&jeton=${encodeURIComponent(jeton)}">Nöbeti kapat</a></p>
</div>`;
}

async function mailGonder(kime, konu, html) {
  if (!RESEND) throw new Error('RESEND_KEY yok - mail gonderilemez');
  const r = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: { Authorization: 'Bearer ' + RESEND, 'Content-Type': 'application/json' },
    body: JSON.stringify({ from: FROM, to: [kime], subject: konu, html })
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
    /* Konu satiri kademeye gore: her uyariyi ayni sertlikte yazmak, zamanla
       hepsinin okunmamasina yol acar. YUKSEK varsa oyle soylenir. */
    const yuksek = g.k.filter(x => x.kademe === 'YUKSEK').length;
    const konu = yuksek
      ? `“${g.ad}” markanıza YAKIN ${yuksek} başvuru yayımlandı — itiraza ${enYakin} gün`
      : `“${g.ad}” markanıza benzeme ihtimali olan ${g.k.length} başvuru — itiraza ${enYakin} gün`;
    log(`  ${g.eposta} · "${g.ad}" · ${g.k.length} başvuru · en yakın ${enYakin} gün`);
    g.k.slice(0, 4).forEach(x => log(`      [${x.kademe}] ${x.ad} · %${Math.round(x.benzerlik * 100)}${x.ayni_sinif ? ' · AYNI SINIF' : ''} · ${x.kalan_gun} gün · ${x.sebep}`));
    if (KURU) continue;

    try {
      // ÖNCE MAİL, SONRA İŞARET. Tersi, atılamayan uyarıyı sessizce yutar.
      await mailGonder(g.eposta, konu, mailGovde(g.ad, g.k, g.jeton));
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
