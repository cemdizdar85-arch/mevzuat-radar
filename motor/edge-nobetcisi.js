// motor/edge-nobetcisi.js — CANLI UÇ FONKSİYON = DEPO NÖBETÇİSİ (15.09.2026)
//
// NEDEN: fonksiyonlar Supabase panelinden ELLE yükleniyor. 14.09'da karne-gonder ve net-cevap depoda
// yeni, canlıda eski kaldı; aradaki sürede karne maili eski unvanla gitti, kimse fark etmedi.
// Her fonksiyon kendi kod imzasını `?surum=1` ile söyler (arac/edge-imza.js). Bu nöbetçi her gün:
//   1) depodaki imza satırı dosyanın gerçek imzasıyla tutuyor mu (tutmuyorsa kod değişmiş, imza tazelenmemiş)
//   2) canlı fonksiyonun söylediği imza depodakiyle aynı mı
// HÜKÜM: YEŞİL hepsi eşit · SARI canlı eski ama depo değişikliği 24 saatten yeni (yayın bekliyor)
//        KIRMIZI canlı 24 saatten uzun süredir eski ya da depoda imza bayat · KÖR canlıya ulaşılamadı
// Anahtar İSTEMEZ (yayımlanabilir anahtarla GET). Ücretli çağrı yapmaz: ?surum=1 dalı kimlik/hız/LLM'den önce döner.
//
//   node motor/edge-nobetcisi.js           ölç
//   node motor/edge-nobetcisi.js --sinav   öz-sınav (ağ yok)
'use strict';
const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');
const { imzaHesapla, imzaOku, ESLEME, KLASOR } = require('../arac/edge-imza.js');

const SB = 'https://bjrleanjpyujtajmazxn.supabase.co/functions/v1/';
const ANAHTAR = 'sb_publishable_kTZpYwrL7skw8Ryj5Vs8_Q_-5_Fhkcg';
const TOLERANS_SAAT = 24;

function satirHukmu(k) {
  if (!k.depoImza || k.depoImza !== k.hesapImza) return 'KIRMIZI';
  if (k.canli === null) return 'KÖR';
  if (k.canli === k.depoImza) return 'YEŞİL';
  return k.yasSaat != null && k.yasSaat < TOLERANS_SAAT ? 'SARI' : 'KIRMIZI';
}
function genelHukum(satirlar) {
  const h = satirlar.map(satirHukmu);
  if (h.includes('KIRMIZI')) return 'KIRMIZI';
  if (h.includes('KÖR')) return 'KÖR';
  if (h.includes('SARI')) return 'SARI';
  return 'YEŞİL';
}

async function canliImza(ad) {
  try {
    const r = await fetch(SB + ad + '?surum=1', { headers: { apikey: ANAHTAR, Authorization: 'Bearer ' + ANAHTAR } });
    const govde = await r.text();
    try { const j = JSON.parse(govde); if (j && typeof j.surum === 'string') return { imza: j.surum, durum: r.status }; } catch (e) {}
    return { imza: 'ESKI-SURUM-UCU-YOK', durum: r.status };
  } catch (e) { return { imza: null, durum: 'ag-hatasi' }; }
}

function sinav() {
  let h = 0; const t = (ad, k) => { console.log((k ? '  geçti: ' : '  DÜŞTÜ: ') + ad); if (!k) h++; };
  const s = (o) => Object.assign({ depoImza: 'a', hesapImza: 'a', canli: 'a', yasSaat: 100 }, o);
  t('hepsi eşit YEŞİL', satirHukmu(s({})) === 'YEŞİL');
  t('canlı eski, depo değişikliği 3 saatlik SARI', satirHukmu(s({ canli: 'b', yasSaat: 3 })) === 'SARI');
  t('canlı eski, 30 saatlik KIRMIZI', satirHukmu(s({ canli: 'b', yasSaat: 30 })) === 'KIRMIZI');
  t('canlıda sürüm ucu yok KIRMIZI', satirHukmu(s({ canli: 'ESKI-SURUM-UCU-YOK' })) === 'KIRMIZI');
  t('depoda imza bayat KIRMIZI (canlı eşit olsa bile)', satirHukmu(s({ hesapImza: 'z' })) === 'KIRMIZI');
  t('ağ hatası KÖR', satirHukmu(s({ canli: null })) === 'KÖR');
  t('genel: bir KIRMIZI her şeyi ezer', genelHukum([s({}), s({ canli: 'b', yasSaat: 50 }), s({ canli: null })]) === 'KIRMIZI');
  t('genel: KÖR SARI\'yı ezer', genelHukum([s({ canli: 'b', yasSaat: 1 }), s({ canli: null })]) === 'KÖR');
  console.log(h ? `ÖZ-SINAV DÜŞTÜ (${h})` : 'ÖZ-SINAV GEÇTİ');
  return h;
}

async function ana() {
  if (process.argv.includes('--sinav')) process.exit(sinav() ? 1 : 0);
  const satirlar = [];
  for (const [ad, dosya] of Object.entries(ESLEME)) {
    const tam = path.join(KLASOR, dosya);
    const ham = fs.readFileSync(tam, 'utf8');
    let yasSaat = null;
    try { const ts = Number(execSync(`git log -1 --format=%ct -- "${path.relative(process.cwd(), tam).replace(/\\/g, '/')}"`).toString().trim()); if (ts) yasSaat = (Date.now() / 1000 - ts) / 3600; } catch (e) {}
    const c = await canliImza(ad);
    satirlar.push({ ad, dosya, depoImza: imzaOku(ham), hesapImza: imzaHesapla(ham), canli: c.imza, durum: c.durum, yasSaat });
  }
  const hukum = genelHukum(satirlar);
  console.log(`UÇ FONKSİYON NÖBETÇİSİ · ${hukum}`);
  for (const k of satirlar) {
    const hh = satirHukmu(k);
    const not = hh === 'YEŞİL' ? 'canlı = depo'
      : k.depoImza !== k.hesapImza ? `depoda imza bayat (node arac/edge-imza.js --yaz)`
      : k.canli === null ? `canlıya ulaşılamadı (${k.durum})`
      : k.canli === 'ESKI-SURUM-UCU-YOK' ? `canlıda sürüm ucu yok: imzalı sürüm hiç yüklenmemiş (HTTP ${k.durum})`
      : `canlı ${k.canli} ≠ depo ${k.depoImza} · depo değişikliği ${k.yasSaat == null ? '?' : Math.round(k.yasSaat)} saat önce · panelden yüklenmeli`;
    console.log(`  ${hh.padEnd(7)} ${k.ad.padEnd(14)} ${not}`);
  }
  const neden = satirlar.filter(k => satirHukmu(k) !== 'YEŞİL').map(k => `${k.ad}: ${satirHukmu(k)}`).join(', ') || 'hepsi eşit';
  if (process.env.GITHUB_STEP_SUMMARY) {
    fs.appendFileSync(process.env.GITHUB_STEP_SUMMARY, [`### Uç fonksiyon nöbetçisi: ${hukum}`, '', '| fonksiyon | hüküm | depo | canlı | depo yaşı (saat) |', '|---|---|---|---|---:|']
      .concat(satirlar.map(k => `| ${k.ad} | ${satirHukmu(k)} | ${k.depoImza} | ${k.canli} | ${k.yasSaat == null ? '' : Math.round(k.yasSaat)} |`)).join('\n') + '\n');
    const tip = hukum === 'YEŞİL' ? 'notice' : hukum === 'SARI' ? 'warning' : 'error';
    console.log(`::${tip} title=uc fonksiyon nobeti ${hukum}::${neden}`);
  }
  if (process.env.GITHUB_OUTPUT) fs.appendFileSync(process.env.GITHUB_OUTPUT, `hukum=${hukum}\nneden=${neden}\n`);
  process.exit(hukum === 'KIRMIZI' ? 2 : hukum === 'KÖR' ? 3 : 0);
}

if (require.main === module) ana();
module.exports = { satirHukmu, genelHukum };
