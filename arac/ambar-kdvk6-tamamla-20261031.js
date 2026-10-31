#!/usr/bin/env node
/* ============================================================================
 *  AMBAR DÜZELTME — KDVK (3065 s.K.) m.6/b yarıda kesik (Cem 31.10, madde 2)
 *  KUSUR (ölçüldü 31.10): ambar kaydı "…Hizmetin Türkiye'de yapılmasını veya hizmetten" diye bitiyor (210 kr).
 *    Kesilen kuyruk ("Türkiye'de faydalanılmasını, İfade eder.") m.7 kaydının ADINA ve metninin BAŞINA taşmış.
 *  DÜZELTME: resmî metin = mevzuat.gov.tr/mevzuatmetin/1.5.3065.pdf (PDF oluşturma 09.09.2026), m.6 satırı birebir.
 *    Yeni bilgi EKLENMEZ: eski metin yeni metnin ÖNEKİ olmak zorunda; eklenen kuyruk m.7 kaydında da geçmek zorunda.
 *  kaynak_ad DEĞİŞMEZ (soruların kaynak bağı korunur). m.7 kaydının kusurlu adı/öneki BU İŞİN DIŞINDA (bilerek).
 *  YEDEK: C:\TETIKTE-YEDEK\ambar-kdvk6-<zaman>.json (yazmadan önce).
 *  Kullanım: node arac/ambar-kdvk6-tamamla-20261031.js [--yaz]
 * ==========================================================================*/
'use strict';
const fs = require('fs'), path = require('path');
const YAZ = process.argv.includes('--yaz');
const K = process.env.SUPABASE_SERVICE_KEY; if (!K) { console.error('SUPABASE_SERVICE_KEY yok'); process.exit(2); }
const B = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar', H = { apikey: K, Authorization: 'Bearer ' + K, 'Content-Type': 'application/json' };
const AD6 = "KDVK (3065 s.K.) m.6 - İşlemlerin Türkiye'de yapılması";
const AD7 = "KDVK (3065 s.K.) m.7 - Türkiye'de faydalanılmasını, İfade eder. Uluslararası taşıma işleri";
const YENI6 = "İşlemlerin Türkiye'de yapılması: Madde 6 – İşlemlerin Türkiye'de yapılması: a) Malların teslim anında Türkiye'de bulunmasını, "
  + "b) (Değişik : 27/1/2000 - 4503/3 md.) Hizmetin Türkiye'de yapılmasını veya hizmetten Türkiye'de faydalanılmasını, İfade eder.";
const getir = async ad => (await (await fetch(B + '?select=*&kaynak_ad=eq.' + encodeURIComponent(ad), { headers: H })).json());
(async () => {
  const r6 = await getir(AD6), r7 = await getir(AD7);
  if (r6.length !== 1) { console.error('KIRMIZI: m.6 kaydı tek değil (' + r6.length + ')'); process.exit(3); }
  const a = r6[0];
  if (a.metin === YENI6) { console.log('ZATEN TAM: m.6 metni resmî metinle aynı (' + a.metin.length + ' kr). Yazılmadı.'); return; }
  if (!YENI6.startsWith(a.metin)) { console.error('KIRMIZI: eski m.6 metni yeni metnin öneki değil — elle bak'); process.exit(3); }
  const kuyruk = YENI6.slice(a.metin.length).trim();
  if (!r7.length || !r7[0].metin.startsWith(kuyruk)) { console.error('KIRMIZI: eklenen kuyruk m.7 taşmasında yok: ' + kuyruk); process.exit(3); }
  console.log('KAPILAR YEŞİL · eski metin önek · eklenen kuyruk m.7 taşmasıyla aynı: "' + kuyruk + '"');
  console.log('m.6 ' + a.metin.length + ' → ' + YENI6.length + ' kr · id ' + a.id);
  if (!YAZ) { console.log('KURU: --yaz ile yazılır'); return; }
  const zaman = new Date().toISOString().replace(/[-:]/g, '').replace(/\..+/, '').replace('T', '-');
  const yd = 'C:\\TETIKTE-YEDEK'; fs.mkdirSync(yd, { recursive: true });
  const yf = path.join(yd, 'ambar-kdvk6-' + zaman + '.json');
  fs.writeFileSync(yf, JSON.stringify({ tarih: new Date().toISOString(), kayit: a }, null, 1));
  console.log('YEDEK ' + yf);
  const w = await fetch(B + '?id=eq.' + a.id, { method: 'PATCH', headers: { ...H, Prefer: 'return=minimal' }, body: JSON.stringify({ metin: YENI6 }) });
  if (!w.ok) { console.error('YAZILAMADI ' + w.status + ' ' + (await w.text()).slice(0, 200)); process.exit(1); }
  const g = (await getir(AD6))[0];
  console.log((g.metin === YENI6 ? 'YAZILDI + GERİ OKUNDU (birebir)' : 'KIRMIZI geri okuma farklı') + ' · ' + g.metin.length + ' kr · arama_fold '
    + (g.arama_fold && /faydalan/.test(g.arama_fold) ? 'tazelendi' : 'TAZELENMEDİ'));
})();
