#!/usr/bin/env node
/* ============================================================================
 *  AMBAR DÜZELTME — GVK m.103 tarife tablosu (Cem 05.10 "1.2.3", iş emri satır 16)
 *  KUSUR (ölçüldü 05.10): resmî PDF'te m.103 tablo; metne çevrilince oran sütunu dağıldı. Ambar kaydı "…(1.697.500" diye kesik
 *    bitiyor, oranlar ("% % % % 40 oranında vergilendirilir") m.104 kaydının BAŞINA taşmış. Yazar ve hakem dilim/oran eşleşmesini
 *    bu kayıttan okuyamıyor.
 *  DÜZELTME: aynı resmî metin (veri/mevzuat-hazir/gvk.txt 3078–3109), SATIR DÜZENİNE sokulur; yeni bilgi EKLENMEZ.
 *    Kapılar: (1) yeni m.103 metnindeki her sayı eski m.103 + m.104 taşmasında VAR (yeni sayı yok) · (2) parantezli 2026 tutarları
 *    ambardaki GVGT SERİ NO:332 m.3 [3/3] ile birebir · (3) m.104 yalnız taşan önekten temizlenir, kalan metni aynen kalır.
 *  kaynak_ad DEĞİŞMEZ (soruların kaynak_adlar bağı korunur; m.104'ün adı kusurlu kalır — bilerek).
 *  ETKİ (ölçüldü 05.10): Yeterlilik sitesinde m.103/104'ü kaynak gösteren soru 0 · parti dosyalarında SMMM 4, SGS 6 · eski kasa
 *    (soru_havuzu kanun 193 madde 103) 62 soru, hepsi yayin=false. Dayanak nöbetçisi damga değişimini görür.
 *  YEDEK: _yerel-veri-kasasi/teori-yedek/gvk103-104-20261005.json (yazmadan önce).
 *  Kullanım: node arac/ambar-gvk103-duzelt-20261005.js [--yaz]
 * ==========================================================================*/
'use strict';
const fs = require('fs'), path = require('path');
const KOK = path.join(__dirname, '..'), YAZ = process.argv.includes('--yaz');
const K = process.env.SUPABASE_SERVICE_KEY; if (!K) { console.error('SUPABASE_SERVICE_KEY yok'); process.exit(2); }
const B = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar', H = { apikey: K, Authorization: 'Bearer ' + K, 'Content-Type': 'application/json' };
const AD103 = 'GVK (193 s.K.) m.103', AD104 = 'GVK (193 s.K.) m.104 - TL) fazlası % % % % 40 oranında vergilendirilir. Verginin hesaplanması';
const YENI103 = 'Madde 103 – (Değişik:5/12/2019-7194/17 md.) Gelir vergisine tabi gelirler; '
  + '18.000 TL’ye (190.000 TL) kadar % 15; '
  + '40.000 TL’nin (400.000 TL) 18.000 TL’si (190.000 TL) için 2.700 TL (28.500 TL), fazlası % 20; '
  + '98.000 TL’nin (1.000.000 TL) 40.000 TL’si (400.000 TL) için 7.100 TL (70.500 TL) (ücret gelirlerinde 148.000 TL’nin (1.500.000 TL) 40.000 TL’si (400.000 TL) için 7.100 TL (70.500 TL)), fazlası % 27; '
  + '500.000 TL’nin (5.300.000 TL) 98.000 TL’si (1.000.000 TL) için 22.760 TL (232.500 TL) (ücret gelirlerinde 500.000 TL’nin (5.300.000 TL) 148.000 TL’si (1.500.000 TL) için 36.260 TL (367.500 TL)), fazlası % 35; '
  + '500.000 TL’den fazlasının (5.300.000 TL) 500.000 TL’si (5.300.000 TL) için 163.460 TL (1.737.500 TL) (ücret gelirlerinde 500.000 TL’den (5.300.000 TL) fazlasının 500.000 TL’si (5.300.000 TL) için 159.460 TL (1.697.500 TL)), fazlası % 40 oranında vergilendirilir.';
const sayilar = s => [...new Set((String(s).match(/\d{1,3}(?:\.\d{3})+|\d+/g) || []))];
const getir = async ad => (await (await fetch(B + '?select=id,kaynak_ad,metin&kaynak_ad=eq.' + encodeURIComponent(ad), { headers: H })).json());
(async () => {
  const [a] = await getir(AD103), [b] = await getir(AD104);
  const s332 = (await getir('GELİR VERGİSİ GENEL TEBLİĞİ (SERİ NO:332) m.3 [3/3]'))[0];
  if (!a || !b || !s332) { console.error('KIRMIZI: kayıt bulunamadı (m.103/m.104/Seri 332)'); process.exit(3); }
  const ONEK = 'TL) fazlası % % % % 40 oranında vergilendirilir. ';
  if (!b.metin.startsWith(ONEK)) { console.error('KIRMIZI: m.104 beklenen taşma önekiyle başlamıyor — zaten düzeltilmiş olabilir'); process.exit(3); }
  const yeni104 = b.metin.slice(ONEK.length);
  // kapı 1: yeni sayı yok
  const eski = new Set([...sayilar(a.metin), ...sayilar(ONEK)]), yeniS = sayilar(YENI103).filter(x => !eski.has(x));
  if (yeniS.length) { console.error('KIRMIZI: eski metinde olmayan sayı: ' + yeniS.join(', ')); process.exit(3); }
  // kapı 2: 2026 tutarları Seri 332 ile
  const parantez = [...YENI103.matchAll(/\((\d{1,3}(?:\.\d{3})+) TL\)/g)].map(m => m[1]), yok = [...new Set(parantez)].filter(x => !s332.metin.includes(x));
  if (yok.length) { console.error('KIRMIZI: Seri 332 m.3/3\'te olmayan 2026 tutarı: ' + yok.join(', ')); process.exit(3); }
  for (const o of ['% 15', '% 20', '% 27', '% 35', '% 40']) if (!YENI103.includes(o)) { console.error('KIRMIZI: oran eksik ' + o); process.exit(3); }
  console.log('KAPILAR YEŞİL · yeni sayı 0 · 2026 tutarı ' + new Set(parantez).size + '/' + new Set(parantez).size + ' Seri 332 ile tutuyor · 5 oran yerinde');
  console.log('m.103 ' + a.metin.length + ' → ' + YENI103.length + ' kr · m.104 ' + b.metin.length + ' → ' + yeni104.length + ' kr');
  if (!YAZ) { console.log('KURU: --yaz ile yazılır'); return; }
  const yd = path.join(KOK, '..', '_yerel-veri-kasasi', 'teori-yedek');   // depo DIŞI (git'e girmeyen veri kasası) fs.mkdirSync(yd, { recursive: true });
  fs.writeFileSync(path.join(yd, 'gvk103-104-20261005.json'), JSON.stringify({ tarih: new Date().toISOString(), m103: a, m104: b }, null, 1));
  for (const [x, m] of [[a, YENI103], [b, yeni104]]) {
    const r = await fetch(B + '?id=eq.' + x.id, { method: 'PATCH', headers: { ...H, Prefer: 'return=representation' }, body: JSON.stringify({ metin: m }) });
    if (!r.ok) { console.error('YAZILAMADI ' + r.status + ' ' + (await r.text()).slice(0, 200)); process.exit(1); }
    const g = (await getir(x.kaynak_ad))[0];
    console.log((g.metin === m ? 'YAZILDI + GERİ OKUNDU (birebir)' : 'KIRMIZI geri okuma farklı') + ' · ' + x.kaynak_ad.slice(0, 40));
  }
})();
