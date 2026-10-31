#!/usr/bin/env node
/* ============================================================================
 *  AMBAR — THP reeskont karşı hesabı uygulama notu + iki etiket/OCR onarımı (Cem 31.10, üç öneri onaylı) · BEDEL 0
 *  ÖLÇÜLEN (31.10): THP 122/137/322/337/422 işleyiş metinleri karşı hesabı "652 Reeskont Faiz Giderleri / 642 Faiz Gelirleri" verir.
 *    Bu RESMÎ LAFIZDIR (MSUGT Sıra No 1, RG 26.12.1992/21447; GİB'in bugünkü Sıra No 1 eki 213_Teblig1MS_Ek5.pdf aynı lafzı taşır).
 *    MSUGT Sıra No 2 (RG 16.12.1993/21790) B.13 ile 647 Reeskont Faiz Gelirleri açıldı, C.12 ile "652" hesabı "657" olarak düzeltildi;
 *    122/322/337 metinleri yeniden yazılmadı. → LAFZA DOKUNULMAZ; her kaydın SONUNA tarihli uygulama notu eklenir
 *    (THP kayıtlarındaki mevcut kalıp: "(03.08 eklendi …)", "(02.10.2026: … resmî kod 397.)"). Not metinde olduğu için
 *    ambar-ara / hakem / kör kaydı açınca görür.
 *  AYRICA: THP 437 "317- Diğer Borç Senetleri Reeskontu" OCR hatası → resmî metinde "337." (GİB Ek5) · THP 647/657 başlığındaki
 *    "Sira No:1" yanlış: iki hesap Sıra No 2 ile açıldı/düzeltildi → "Sira No:2 (RG 16.12.1993/21790)".
 *  Aynı dönüşüm depodaki kaynak dosyaya da (veri/mevzuat/msugt-thp-tam.json) uygulanır: elle tetiklenen tam yükleme
 *    (yukle.yml) ambarı bu dosyadan yeniden kurarsa not ve onarımlar kaybolmaz.
 *  Kapı: her eski ifade kayıtta TAM 1 kez; not zaten varsa kayıt atlanır (yeniden koşmak güvenli). Ambar = dosya (önce) değilse DURUR.
 *  Soru-dayanak nöbetçisi THP satırını izlemez (ambar-kaynak-duzelt-20261006.ps1 notu) → yayından çekme etkisi yok.
 *  YEDEK: C:\TETIKTE-YEDEK\ambar-thp-<zaman>.json (yazmadan önce).
 *  Kullanım: node arac/ambar-thp-reeskont-notu-20261031.js [--yaz]
 * ==========================================================================*/
'use strict';
const fs = require('fs'), path = require('path');
const YAZ = process.argv.includes('--yaz');
const K = process.env.SUPABASE_SERVICE_KEY; if (!K) { console.error('SUPABASE_SERVICE_KEY yok'); process.exit(2); }
const B = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar', H = { apikey: K, Authorization: 'Bearer ' + K, 'Content-Type': 'application/json' };
const DOSYA = path.join(__dirname, '..', 'veri', 'mevzuat', 'msugt-thp-tam.json');
const NOT = ' (31.10.2026 UYGULAMA NOTU: MSUGT Sıra No 2 (RG 16.12.1993/21790) ile 652→657 değişti, 647 Reeskont Faiz Gelirleri açıldı; uygulamada karşı hesap 647/657.)';
const ETIKET1 = 'MSUGT Sira No:1 Tekduzen Hesap Plani - ', ETIKET2 = 'MSUGT Sira No:2 (RG 16.12.1993/21790) Tekduzen Hesap Plani - ';
// [kod, eski ifade, yeni ifade] — eski ifade TAM 1 kez geçmeli
const ISLER = [
  ...['122', '137', '322', '337', '422'].map(k => [k, null, NOT]),            // null = sona not ekle
  ['437', '"317- Diğer Borç Senetleri Reeskontu', '"337- Diğer Borç Senetleri Reeskontu'],
  ['647', ETIKET1, ETIKET2],
  ['657', ETIKET1, ETIKET2],
];
const say = (s, x) => s.split(x).length - 1;
function donustur(metin, eski, yeni) {
  if (eski === null) { if (metin.includes('UYGULAMA NOTU: MSUGT Sıra No 2')) return { atla: 'not zaten var' }; return { metin: metin + yeni }; }
  if (say(metin, yeni) === 1 && say(metin, eski) === 0) return { atla: 'zaten onarılmış' };
  if (say(metin, eski) !== 1) return { hata: 'eski ifade ' + say(metin, eski) + ' kez' };
  return { metin: metin.replace(eski, yeni) };
}
(async () => {
  const ham = fs.readFileSync(DOSYA, 'utf8'), dj = JSON.parse(ham.replace(/^\uFEFF/, ''));
  const belgeler = dj.belgeler || dj; const plan = [], yedek = [];
  for (const [kod, eski, yeni] of ISLER) {
    const r = await (await fetch(B + '?select=*&kaynak_ad=like.' + encodeURIComponent('THP ' + kod + ' -%'), { headers: H })).json();
    if (r.length !== 1) { console.error('KIRMIZI: THP ' + kod + ' ambarda ' + r.length + ' kayıt'); process.exit(3); }
    const a = r[0], d = belgeler.filter(x => x.kaynak_ad === a.kaynak_ad);
    if (d.length !== 1) { console.error('KIRMIZI: THP ' + kod + ' dosyada ' + d.length + ' kayıt'); process.exit(3); }
    const ta = donustur(a.metin, eski, yeni), td = donustur(d[0].metin, eski, yeni);
    if (ta.hata || td.hata) { console.error('KIRMIZI: THP ' + kod + ' ambar:' + (ta.hata || 'ok') + ' dosya:' + (td.hata || 'ok')); process.exit(3); }
    if (!ta.atla && !td.atla && a.metin !== d[0].metin) { console.error('KIRMIZI: THP ' + kod + ' ambar ≠ dosya (önce) — elle bak'); process.exit(3); }
    plan.push({ kod, a, d: d[0], ta, td }); yedek.push(a);
    console.log(`THP ${kod}: ambar ${ta.atla ? 'ATLA (' + ta.atla + ')' : a.metin.length + ' → ' + ta.metin.length + ' kr'} · dosya ${td.atla ? 'ATLA' : d[0].metin.length + ' → ' + td.metin.length + ' kr'}`);
  }
  if (!YAZ) { console.log('KURU: --yaz ile yazılır'); return; }
  const zaman = new Date().toISOString().replace(/[-:]/g, '').replace(/\..+/, '').replace('T', '-');
  const yf = path.join('C:\\TETIKTE-YEDEK', 'ambar-thp-' + zaman + '.json'); fs.mkdirSync(path.dirname(yf), { recursive: true });
  fs.writeFileSync(yf, JSON.stringify({ tarih: new Date().toISOString(), kayitlar: yedek }, null, 1)); console.log('YEDEK ' + yf);
  let hamYeni = ham;
  for (const p of plan) {
    if (!p.td.atla) { const e = JSON.stringify(p.d.metin), y = JSON.stringify(p.td.metin); if (say(hamYeni, e) !== 1) { console.error('KIRMIZI: dosyada THP ' + p.kod + ' metni ' + say(hamYeni, e) + ' kez — dosya yazılmadı'); process.exit(3); } hamYeni = hamYeni.replace(e, () => y); }
    if (p.ta.atla) continue;
    const w = await fetch(B + '?id=eq.' + p.a.id, { method: 'PATCH', headers: { ...H, Prefer: 'return=minimal' }, body: JSON.stringify({ metin: p.ta.metin }) });
    if (!w.ok) { console.error('YAZILAMADI THP ' + p.kod + ' ' + w.status); process.exit(1); }
    const g = (await (await fetch(B + '?select=metin,arama_fold&id=eq.' + p.a.id, { headers: H })).json())[0];
    console.log(`THP ${p.kod}: ` + (g.metin === p.ta.metin ? 'YAZILDI + GERİ OKUNDU (birebir)' : 'KIRMIZI geri okuma farklı') + ' · arama_fold ' + (g.arama_fold ? 'dolu' : 'BOŞ'));
  }
  fs.writeFileSync(DOSYA, hamYeni);   // yaln\u0131z de\u011Fi\u015Fen metin dizgileri yerinde de\u011Fi\u015Fir (dosyan\u0131n PowerShell JSON bi\u00E7imi korunur)
  console.log('DOSYA yazıldı: veri/mevzuat/msugt-thp-tam.json');
})();
