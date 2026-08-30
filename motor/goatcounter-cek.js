#!/usr/bin/env node
/* ============================================================================
 *  GOATCOUNTER GECMIS CEKICI (30.08.2026)
 *
 *  NEDEN: 30.08'de damping kartlarina olay sayaci konuldu, ama olay verisi
 *  o gunden ONCESI icin YOKTUR (sayac hic yoktu - uretilmemis veri geri
 *  alinamaz). Buna karsilik SAYFA GORUNTULEME gecmisi GoatCounter'da duruyor.
 *  Kartin gosterim sayisi TABAN TRAFIK olmadan yorumlanamaz: "karti 40 kisi
 *  gordu" ancak "sayfayi 400 kisi acti" ile bir sey soyler.
 *
 *  ANAHTAR NEREDE: panel disariya kapali (olculdu: /api/v0/me -> 401).
 *  Anahtar bu depoya YAZILMAZ, betige GECIRILMEZ, sohbete YAPISTIRILMAZ.
 *  Yalniz ortam degiskeninden okunur:  GOATCOUNTER_TOKEN
 *  CI'da GitHub secret olarak tanimlanir (Settings > Secrets > Actions).
 *
 *  CEM'IN YAPACAGI (bir kez, 2 dakika):
 *    1. https://mevzuatradar.goatcounter.com  -> giris
 *    2. Settings (Ayarlar) > API tokens > "Add token"
 *       izin: yalnizca "Read statistics" (baska kutu isaretleme)
 *    3. Cikan anahtari GitHub'da secret olarak kaydet:
 *       repo > Settings > Secrets and variables > Actions > New repository secret
 *       Ad: GOATCOUNTER_TOKEN   Deger: <anahtar>
 *    Anahtari bana gonderme; secret'a koydugunu soylemen yeter.
 *
 *  Kullanim:
 *    GOATCOUNTER_TOKEN=... node motor/goatcounter-cek.js            # son 90 gun
 *    GOATCOUNTER_TOKEN=... node motor/goatcounter-cek.js --gun 365
 *  Cikti: motor/cikti/goatcounter-taban.json  (+ konsol ozeti)
 *  Anahtar yoksa: KIRMIZI degil, "anahtar yok" der ve 0 ile ciker (CI'yi
 *  bosuna kirmizi yakmaz - henuz kurulmamis olmasi bir kusur degil).
 * ==========================================================================*/
'use strict';
const fs = require('fs'), path = require('path');

const KOK = path.resolve(__dirname, '..');
const SITE = 'https://mevzuatradar.goatcounter.com';
const TOKEN = process.env.GOATCOUNTER_TOKEN;

const args = process.argv.slice(2);
const gi = args.indexOf('--gun');
const GUN = gi > -1 ? Math.max(1, parseInt(args[gi + 1], 10) || 90) : 90;

if (!TOKEN) {
  console.log('GOATCOUNTER_TOKEN yok - cekim yapilmadi.');
  console.log('Kurulum: panelde Settings > API tokens > "Read statistics" izniyle bir anahtar uret,');
  console.log('GitHub repo secret adi GOATCOUNTER_TOKEN olarak kaydet. Anahtar depoya yazilmaz.');
  process.exit(0);
}

const gunEkle = n => new Date(Date.now() + n * 86400000).toISOString().slice(0, 10);

async function api(yol) {
  const r = await fetch(SITE + yol, { headers: { Authorization: 'Bearer ' + TOKEN, 'Content-Type': 'application/json' } });
  if (r.status === 401 || r.status === 403) throw new Error('anahtar reddedildi (401/403) - izin "Read statistics" mi?');
  if (!r.ok) throw new Error(`${yol} -> HTTP ${r.status}`);
  return r.json();
}

(async () => {
  const bas = gunEkle(-GUN), bit = gunEkle(0);
  const q = `?start=${bas}&end=${bit}&limit=200`;
  const hit = await api('/api/v0/stats/hits' + q);

  const satir = (hit.hits || []).map(h => ({
    yol: h.path_name || h.path || '(bilinmiyor)',
    ziyaret: h.count || 0,
    olayMi: !!h.event,
  })).sort((a, b) => b.ziyaret - a.ziyaret);

  const sayfalar = satir.filter(x => !x.olayMi);
  const olaylar = satir.filter(x => x.olayMi);
  const bul = re => sayfalar.filter(x => re.test(x.yol)).reduce((a, x) => a + x.ziyaret, 0);

  const rapor = {
    aralik: { baslangic: bas, bitis: bit, gun: GUN },
    toplamSayfaGoruntuleme: sayfalar.reduce((a, x) => a + x.ziyaret, 0),
    tabanTrafik: { 'gtip.html': bul(/gtip\.html/), 'risk-taramasi.html': bul(/risk-taramasi\.html/), 'toplu-gtip.html': bul(/toplu-gtip\.html/) },
    olaylar: olaylar.map(x => ({ ad: x.yol, adet: x.ziyaret })),
    enCok: sayfalar.slice(0, 20),
  };

  fs.mkdirSync(path.join(KOK, 'motor', 'cikti'), { recursive: true });
  fs.writeFileSync(path.join(KOK, 'motor', 'cikti', 'goatcounter-taban.json'), JSON.stringify(rapor, null, 1), 'utf8');

  console.log(`=== GOATCOUNTER TABAN (${bas} .. ${bit}) ===`);
  console.log(`toplam sayfa goruntuleme: ${rapor.toplamSayfaGoruntuleme}`);
  console.log(`taban trafik -> gtip.html ${rapor.tabanTrafik['gtip.html']} · risk-taramasi ${rapor.tabanTrafik['risk-taramasi.html']} · toplu-gtip ${rapor.tabanTrafik['toplu-gtip.html']}`);
  if (olaylar.length) {
    console.log('\nolaylar:');
    for (const o of rapor.olaylar) console.log(`  ${o.ad.padEnd(42)} ${o.adet}`);
    const kart = rapor.olaylar.filter(o => /damping-(onlem|sorusturma)-karti/.test(o.ad)).reduce((a, o) => a + o.adet, 0);
    const taban = rapor.tabanTrafik['gtip.html'] || 0;
    if (kart && taban) console.log(`\n  damping karti gosterimi / gtip.html goruntulemesi = ${kart}/${taban} = %${(100 * kart / taban).toFixed(1)}`);
  } else {
    console.log('\nolay kaydi yok. (Sayac 30.08.2026\'da kuruldu; oncesi icin olay verisi YOKTUR.)');
  }
  console.log('\nRapor -> motor/cikti/goatcounter-taban.json');
})().catch(e => { console.error('KIRMIZI:', e.message); process.exit(1); });
