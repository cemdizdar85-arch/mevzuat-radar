#!/usr/bin/env node
/* ============================================================================
 *  AMBAR EKLEME — GVK m.22 (menkul sermaye iratlarında istisna: kâr payının yarısı) · 05.10.2026, Cem "1.2.3" (GM1)
 *  NİYE: ambarda GVK m.21'den sonra doğrudan m.23 var; m.22 ne ayrı kayıt ne komşu kayıtta (ölçüldü: kaynak_ad '%193%m.22%' yalnız
 *    "gec. m.22"; m.21 metninde iz yok). Yeterlilik gm6 MSİ yazarı kâr payı sorusunu kaynaksız kaldığı için yazamadı.
 *  KAYNAK: veri/mevzuat-hazir/gvk.txt (mevzuat.gov.tr 1.4.193 metni, 05.08.2026 indirme) satır 479–503 + 516–529.
 *    Aradaki 504–515 SAYFA ALTI DİPNOTU (m.21/m.22 değişiklik notları + sayfa no) — ALINMAZ (VUK m.283 dipnot sızıntısı dersi).
 *  YALNIZ EKLEME: var olan hiçbir kayıt değişmez (dayanak nöbetçisi var olan kaydın parmak izine bakar; ekleme onu tetiklemez).
 *  Aynı kaynak_ad zaten varsa YAZMAZ (çift kayıt yok). Yazdıktan sonra geri okur, metni birebir kıyaslar.
 *  🚫 GÖRMEZ: 05.08.2026'dan sonraki olası m.22 değişikliği (yerel kopya tarihi) · Cumhurbaşkanı kararıyla değişen istisna oranı (5. fıkra yetkisi).
 *  Kullanım: node arac/ambar-gvk22-ekle-20261005.js [--yaz]   (--yaz yoksa KURU: yalnız gösterir)
 * ==========================================================================*/
'use strict';
const fs = require('fs'), path = require('path');
const KOK = path.join(__dirname, '..');
const YAZ = process.argv.includes('--yaz');
const sat = fs.readFileSync(path.join(KOK, 'veri/mevzuat-hazir/gvk.txt'), 'utf8').replace(/^﻿/, '').split(/\r?\n/);
const al = (b, s) => sat.slice(b - 1, s).map(x => x.trim()).filter(Boolean).join(' ').replace(/\s+/g, ' ').trim();   // satır no 1 tabanlı, uçlar dahil
if (!/^Menkul sermaye iratlarında:/.test(sat[478]) || !/^Madde 22 –/.test(sat[479]) || !/^3\. Tam mükellef/.test(sat[515].trim()) || !/^ALTINCI BÖLÜM/.test(sat[529])) {
  console.error('KIRMIZI: gvk.txt satır düzeni beklenenden farklı (yerel kopya değişmiş) — yazılmadı'); process.exit(3);
}
const BASLIK = 'Menkul sermaye iratlarında';
const p1 = BASLIK + ': ' + al(480, 503);
const p2 = al(516, 529);
if (/değiştirilmiştir|teselsül ettirilmiştir/.test(p1 + p2)) { console.error('KIRMIZI: dipnot metni sızmış'); process.exit(3); }
const kay = [
  { tur: 'kanun-madde', kaynak_ad: `GVK (193 s.K.) m.22 - ${BASLIK} [1/2]`, baslik: BASLIK, metin: p1, kaynak_url: 'https://www.mevzuat.gov.tr/mevzuatmetin/1.4.193.pdf' },
  { tur: 'kanun-madde', kaynak_ad: `GVK (193 s.K.) m.22 - ${BASLIK} [2/2]`, baslik: BASLIK, metin: p2, kaynak_url: 'https://www.mevzuat.gov.tr/mevzuatmetin/1.4.193.pdf' }];
for (const k of kay) console.log(k.kaynak_ad + ' · ' + k.metin.length + ' kr\n  ' + k.metin.slice(0, 160) + ' … ' + k.metin.slice(-120));
if (!YAZ) { console.log('KURU: --yaz ile yazılır'); process.exit(0); }
(async () => {
  const K = process.env.SUPABASE_SERVICE_KEY; if (!K) { console.error('SUPABASE_SERVICE_KEY yok'); process.exit(2); }
  const B = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar', H = { apikey: K, Authorization: 'Bearer ' + K, 'Content-Type': 'application/json' };
  for (const k of kay) {
    const v = await (await fetch(B + '?select=id&kaynak_ad=eq.' + encodeURIComponent(k.kaynak_ad), { headers: H })).json();
    if (v.length) { console.log('ZATEN VAR (yazılmadı): ' + k.kaynak_ad); continue; }
    const r = await fetch(B, { method: 'POST', headers: { ...H, Prefer: 'return=representation' }, body: JSON.stringify(k) });
    if (!r.ok) { console.error('YAZILAMADI ' + r.status + ': ' + (await r.text()).slice(0, 300)); process.exit(1); }
    const id = (await r.json())[0].id;
    const g = (await (await fetch(B + '?select=id,kaynak_ad,metin,arama_fold&id=eq.' + id, { headers: H })).json())[0];
    console.log((g && g.metin === k.metin ? 'YAZILDI + GERİ OKUNDU (birebir)' : 'KIRMIZI: geri okuma farklı') + ' · ' + id + ' · arama_fold ' + (g && g.arama_fold ? 'dolu' : 'BOŞ'));
  }
})();
