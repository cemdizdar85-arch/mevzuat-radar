#!/usr/bin/env node
/* ===========================================================================
   MUTABAKAT NÖBETÇİSİ — "kütük mü doğru, tablo mu?"  (30.08.2026)

   Cem: "2 yapalım."

   NEDEN VAR: marka_bulten_durum() sayıları KÜTÜKTEN okuyor, çünkü 100 bin
   satırı saymak zaman aşımına düşüyordu. Hızlı ama bir varsayıma dayanıyor:
   "robot kaç kayıt yazdığını doğru yazdı." O varsayım kırılırsa ekran
   "7.860 kayıt" der, tabloda 7.400 vardır ve KIMSE FARK ETMEZ. Eksik
   markalar için uyarı gitmez, itiraz süresi sessizce akar.

   Bu nöbetçi o boşluğu kapatır: bülten bülten kütükle tabloyu karşılaştırır.

   ÜÇ DURUM (kör kalma kuralı - "sessiz" diye bir sonuç yok):
     YEŞİL  : tüm bültenlerde kütük = tablo
     KIRMIZI: en az bir bültende fark var -> hangisi, kaç kayıt
     KÖR    : ölçüm yapılamadı (anahtar yok / sorgu düştü) -> "temiz" DEMEZ

   ENV: SUPABASE_SERVICE_KEY
   Kullanım: node motor/marka-mutabakat.js
   =========================================================================== */
'use strict';

const SB_URL = process.env.SUPABASE_URL || 'https://bjrleanjpyujtajmazxn.supabase.co';
const SB_KEY = process.env.SUPABASE_SERVICE_KEY || '';
const fs = require('fs');
const path = require('path');

const RAPOR = path.join(__dirname, '..', 'veri', 'marka-mutabakat-raporu.json');
const log = (...s) => console.log(...s);

function yaz(durum, ozet, ayrinti) {
  try {
    fs.writeFileSync(RAPOR, JSON.stringify({
      tarih: new Date().toISOString().slice(0, 16).replace('T', ' '),
      durum, ozet, ayrinti
    }, null, 1));
  } catch (e) { console.error('rapor yazilamadi: ' + e.message); }
}

(async () => {
  if (!SB_KEY) {
    // KÖR: ölçemedik. "Temiz" demek yerine körlüğü ilan ediyoruz.
    log('KOR: SUPABASE_SERVICE_KEY yok - mutabakat OLCULEMEDI.');
    log('     Bu "kayip yok" demek DEGILDIR; olcum yapilamadi.');
    yaz('KOR', 'anahtar yok, olcum yapilamadi', []);
    process.exit(1);
  }

  let satir;
  try {
    const r = await fetch(`${SB_URL}/rest/v1/rpc/marka_bulten_mutabakat`, {
      method: 'POST',
      headers: { apikey: SB_KEY, Authorization: 'Bearer ' + SB_KEY, 'Content-Type': 'application/json' },
      body: '{}'
    });
    const t = await r.text();
    if (!r.ok) throw new Error(`HTTP ${r.status} ${t.slice(0, 200)}`);
    satir = JSON.parse(t);
  } catch (e) {
    log('KOR: mutabakat sorgusu dustu -> ' + e.message);
    log('     Bu "kayip yok" demek DEGILDIR.');
    yaz('KOR', 'sorgu dustu: ' + e.message, []);
    process.exit(1);
  }

  if (!Array.isArray(satir) || !satir.length) {
    log('KOR: yutulmus bulten yok ya da cevap bos - karsilastirilacak sey yok.');
    yaz('KOR', 'karsilastirilacak bulten yok', []);
    process.exit(1);
  }

  const bozuk = satir.filter(x => Number(x.fark) !== 0);
  const kutukToplam = satir.reduce((a, x) => a + Number(x.kutuk), 0);
  const tabloToplam = satir.reduce((a, x) => a + Number(x.tablo), 0);

  log(`Karsilastirilan bulten : ${satir.length}`);
  log(`Kutuk toplami          : ${kutukToplam}`);
  log(`Tablo toplami          : ${tabloToplam}`);

  if (!bozuk.length) {
    log('\nYESIL: her bultende kutuk = tablo. Sessiz kayip yok.');
    yaz('YESIL', `${satir.length} bulten, ${tabloToplam} kayit, fark yok`, []);
    return;
  }

  log(`\nKIRMIZI: ${bozuk.length} bultende FARK VAR (toplam ${tabloToplam - kutukToplam} kayit)`);
  bozuk.slice(0, 20).forEach(x => {
    const y = Number(x.fark) < 0 ? 'TABLODA EKSIK' : 'tabloda FAZLA';
    log(`   bulten ${x.bulten_no} (${x.yayin_tarihi}): kutuk ${x.kutuk} · tablo ${x.tablo} · ${y} ${Math.abs(x.fark)}`);
  });
  if (bozuk.length > 20) log(`   ... ${bozuk.length - 20} bulten daha`);
  log('\nNE YAPMALI: ilgili bulteni yeniden yut ->');
  log('  Actions > Marka Bulteni > Run workflow > mod: zorla · adet: 1');
  log('  (kutuk kaydini "bitti"den cikarmak icin --zorla gerekir)');
  yaz('KIRMIZI', `${bozuk.length} bultende fark`, bozuk.slice(0, 50));
  process.exit(1);
})().catch(e => {
  console.error('!! ISTISNA: ' + (e && e.stack || e));
  yaz('KOR', 'istisna: ' + (e && e.message), []);
  process.exit(1);
});
