#!/usr/bin/env node
// YAYIN BEKÇİSİ — başarıyla biten SGS bulut basımı 90 dk içinde yayına girdi mi?   27.09.2026 · bedel 0
//
// NEDEN (Cem 27.09 "1.2.3 üçünü de yap", GM önerisi 3): 26–27.09 gecesi yayin-bas.yml 10 kez üst üste tetiklendi —
//   9'u birbirini iptal etti, 1'i KGK'nın eksik kabuk sayfası yüzünden düştü (36280796965), sonraki 2'si 'skipped'.
//   k11'in 7 başarılı basımı (55 soru) ELLE tetiklenene kadar yayına girmedi; hiçbir kapı bunu söylemedi.
// NE YAPAR: son 48 saatte 'success' biten her plan-sgs-* bulut-uretim koşusu için, bitişinden SONRA başlamış ve
//   'success' bitmiş bir yayin-bas koşusu arar. 90 dk geçmiş ve yoksa → KIRMIZI. Tek sefer onarım: o an kuyrukta/koşan
//   yayin-bas yoksa `gh workflow run yayin-bas.yml -f parti_indir=true` (bedel 0; aynı plan için ikinci kez tetiklemez —
//   tetiklenen koşu da yayın sayılır, düşerse bir sonraki saat KIRMIZI kalır).
// ÇIKTI: YEŞİL / KIRMIZI / KÖR (gh okunamazsa). KIRMIZI → çıkış 1 (ci-kirmizi-nobetcisi görür).
// 🚫 GÖRMEZ: yayına girip SİTEDE görünmeyen soru (kasa/sayfa içeriği ölçülmez, yalnız yayın koşusunun başarısı) ·
//   SMMM ve KGK basımları (kendi yayın akışları var) · 48 saatten eski basımlar · başarısız biten basımlar.
// ÖZ-SINAV: node arac/yayin-bekcisi.js --sinav  (dogrula.yml)
'use strict';
const { execSync } = require('child_process');

const BEKLE_DK = 90, PENCERE_SA = 48;

// SAF KARAR: basimlar [{id, bitis(ms), baslik}] · yayinlar [{id, basla(ms), sonuc, durum}] · simdi(ms)
function karar(basimlar, yayinlar, simdi) {
  const acik = yayinlar.some(y => y.durum !== 'completed');
  const sonuc = [];
  for (const b of basimlar) {
    const yayinlandi = yayinlar.some(y => y.durum === 'completed' && y.sonuc === 'success' && y.basla >= b.bitis);
    const gecen = (simdi - b.bitis) / 60000;
    let d;
    if (yayinlandi) d = 'YAYINDA';
    else if (gecen < BEKLE_DK) d = 'BEKLIYOR';
    else if (acik) d = 'YAYIN_SIRADA';
    else d = 'YAYINLANMADI';
    sonuc.push({ ...b, durum: d, gecenDk: Math.round(gecen) });
  }
  const kirmizi = sonuc.filter(s => s.durum === 'YAYINLANMADI');
  return { sonuc, kirmizi: kirmizi.length, tetikle: kirmizi.length > 0 };   // açık yayın varken kırmızı doğmaz (YAYIN_SIRADA) → tetikleme de olmaz
}

function sinav() {
  const t0 = Date.parse('2026-09-27T00:00:00Z'), dk = 60000;
  const B = (id, dak) => ({ id, bitis: t0 + dak * dk, baslik: 'Bulut Uretim | veri/sinav/plan-sgs-x.json' });
  const Y = (id, dak, sonuc, durum = 'completed') => ({ id, basla: t0 + dak * dk, sonuc, durum });
  const vakalar = [
    ['bitişten sonra başarılı yayın var → yeşil', [B(1, 0)], [Y(9, 5, 'success')], t0 + 200 * dk, 0, false],
    ['yayın yok, 90 dk geçti → KIRMIZI + tetikle', [B(1, 0)], [], t0 + 120 * dk, 1, true],
    ['yayın yok, 30 dk → bekliyor', [B(1, 0)], [], t0 + 30 * dk, 0, false],
    ['yalnız ÖNCE başlamış yayın → KIRMIZI', [B(1, 60)], [Y(9, 10, 'success')], t0 + 200 * dk, 1, true],
    ['sonraki yayınlar iptal/atlandı → KIRMIZI (26.09 gecesi)', [B(1, 0)], [Y(8, 5, 'cancelled'), Y(9, 20, 'skipped'), Y(10, 30, 'failure')], t0 + 200 * dk, 1, true],
    ['yayın kuyrukta → kırmızı değil, tetikleme yok', [B(1, 0)], [Y(9, 100, null, 'queued')], t0 + 200 * dk, 0, false],
    ['iki basım, biri yayında biri değil → 1 kırmızı', [B(1, 0), B(2, 50)], [Y(9, 10, 'success')], t0 + 300 * dk, 1, true],
  ];
  let hata = 0;
  for (const [ad, b, y, s, beklK, beklT] of vakalar) {
    const r = karar(b, y, s); const iyi = r.kirmizi === beklK && r.tetikle === beklT; if (!iyi) hata++;
    console.log(`  ${iyi ? 'TAMAM' : 'HATA '} ${ad} → kırmızı ${r.kirmizi}, tetikle ${r.tetikle}`);
  }
  console.log(hata ? `YAYIN BEKÇİSİ SINAVI KIRMIZI: ${hata}/${vakalar.length}` : `YAYIN BEKÇİSİ SINAVI YESIL: ${vakalar.length}/${vakalar.length}`);
  return hata;
}

function gh(args) { return JSON.parse(execSync('gh ' + args, { encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] })); }

function ana() {
  if (process.argv.includes('--sinav')) { process.exitCode = sinav() ? 1 : 0; return; }
  const simdi = Date.now(), sinir = simdi - PENCERE_SA * 3600000;
  let basimlar, yayinlar;
  try {
    basimlar = gh('run list --workflow bulut-uretim.yml --limit 100 --json databaseId,status,conclusion,displayTitle,updatedAt')
      .filter(r => r.status === 'completed' && r.conclusion === 'success' && /plan-sgs-/.test(r.displayTitle) && Date.parse(r.updatedAt) >= sinir)
      .map(r => ({ id: r.databaseId, bitis: Date.parse(r.updatedAt), baslik: r.displayTitle }));
    yayinlar = gh('run list --workflow yayin-bas.yml --limit 100 --json databaseId,status,conclusion,createdAt')
      .map(r => ({ id: r.databaseId, basla: Date.parse(r.createdAt), sonuc: r.conclusion, durum: r.status }));
  } catch (e) { console.log('YAYIN BEKÇİSİ: KÖR — gh okunamadı: ' + String(e.message).split('\n')[0]); process.exitCode = 0; return; }
  const r = karar(basimlar, yayinlar, simdi);
  const say = d => r.sonuc.filter(s => s.durum === d).length;
  console.log(`YAYIN BEKÇİSİ: son ${PENCERE_SA} sa başarılı SGS basımı ${basimlar.length} · yayında ${say('YAYINDA')} · bekliyor ${say('BEKLIYOR')} · yayın sırada ${say('YAYIN_SIRADA')} · YAYINLANMADI ${r.kirmizi}`);
  for (const s of r.sonuc.filter(s => s.durum === 'YAYINLANMADI')) console.log(`  ⛔ ${s.id} ${s.baslik.slice(-45)} · ${s.gecenDk} dk önce bitti, sonrasında başarılı yayın yok`);
  if (r.tetikle && process.argv.includes('--onar')) {
    try { execSync('gh workflow run yayin-bas.yml -f parti_indir=true', { stdio: 'inherit' }); console.log('  → yayin-bas.yml tetiklendi (parti_indir=true); bir sonraki kontrolde sonucu görülür'); }
    catch (e) { console.log('  → tetikleme DÜŞTÜ: ' + String(e.message).split('\n')[0]); }
  }
  if (r.kirmizi) { console.log('YAYIN BEKÇİSİ: KIRMIZI'); process.exitCode = 1; } else console.log('YAYIN BEKÇİSİ: YEŞİL');
}

if (require.main === module) ana();
module.exports = { karar };
