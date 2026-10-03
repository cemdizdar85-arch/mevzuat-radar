#!/usr/bin/env node
/* ============================================================================
 *  SÜRE NÖBETÇİSİ (03.10.2026, Cem "1.2.3 üçünü de yap" — GM önerisi 1)
 *
 *  NEDEN: 03.10'da yayının 80 dakikaya çıktığı bulundu. Sebeplerden biri motor/kaydir-coz.ps1'deki Türkçe sözlük
 *  kurulumuydu: betiğin içindeki not "100 sn" diyordu ama o ölçüm 04.09'da 36 partiyle yapılmıştı; parti sayısı 70 katına
 *  çıktı, not eskidi, kimse görmedi. Öteki sebep: her yayında 11.765 sistem kaydı boşuna iniyordu (34 dk).
 *  Notları bekçilemek yerine GERÇEK SÜRE izlenir: bir adım sessizce büyürse burada görünür.
 *
 *  NE YAPAR: izlenen akışların son başarılı koşularını GitHub'dan okur (adım adım başlangıç/bitiş). Son koşunun her adımını
 *  ÖNCEKİ koşuların ortancasıyla kıyaslar. ALARM: süre > 2 × ortanca VE süre − ortanca ≥ 10 dk (küçük adımda gürültü olmasın).
 *  Çıkış 1 = alarm (iş akışı Cem'e e-posta atar) · 0 = temiz · KÖR = veri yok/erişim yok (temiz DEMEZ, çıkış 0 + KOR satırı).
 *  GÖRMEZ: iş miktarı koşudan koşuya değişen akış (bulut-uretim: plan büyüklüğü) · başarısız/iptal koşular (yarım süre yanıltır) · 3'ten az geçmişi olan akış (ortanca yok) · yavaş ama hep yavaş adım
 *  (taban zaten yavaşsa artış yok - mutlak tavan bu nöbetçide yok) · tek koşuluk sıçrama ile kalıcı artışı ayırmaz.
 *  Öz-sınav: node motor/sure-nobetcisi.js --sinav [--mutasyon]
 * ==========================================================================*/
'use strict';
// bulut-uretim.yml IZLENMEZ: suresi basilan planin buyuklugune bagli (03.10 ilk kosu: 'Uret' 39 dk / ortanca 17 dk = yanlis alarm)
const AKISLAR = ['yayin-bas.yml', 'smmm-kasa-yayin.yml'];
const KAT = 2, ESIK_DK = 10, GECMIS = 6;
const MUT = process.env.SN_MUTASYON || '';

function ortanca(a) { const s = a.slice().sort((x, y) => x - y); const m = s.length >> 1; return s.length % 2 ? s[m] : (s[m - 1] + s[m]) / 2; }
/* kosular: [{ id, adimlar: { ad: dakika } }] en yenisi başta */
function degerlendir(akis, kosular) {
  if (kosular.length < 4) return { kor: akis + ': ' + kosular.length + ' başarılı koşu var, en az 4 gerekir (ortanca için 3 geçmiş)' };
  const [son, ...gecmis] = kosular; const alarm = [], satir = [];
  for (const [ad, dk] of Object.entries(son.adimlar)) {
    const g = gecmis.map(k => k.adimlar[ad]).filter(x => typeof x === 'number');
    if (g.length < 3) continue;
    const o = ortanca(g);
    const kat = MUT === 'kat' ? 0 : KAT, esik = MUT === 'esik' ? 1e9 : ESIK_DK;
    if (dk > kat * o && dk - o >= esik) alarm.push(akis + ' · ' + ad + ': ' + dk.toFixed(1) + ' dk (önceki ' + g.length + ' koşunun ortancası ' + o.toFixed(1) + ' dk)');
    satir.push(ad + ' ' + dk.toFixed(1) + '/' + o.toFixed(1));
  }
  return { alarm, satir };
}

async function cek(akis, token, repo) {
  const H = { Authorization: 'Bearer ' + token, Accept: 'application/vnd.github+json', 'User-Agent': 'tetikte-sure-nobetcisi' };
  const r = await fetch('https://api.github.com/repos/' + repo + '/actions/workflows/' + akis + '/runs?status=success&per_page=' + GECMIS, { headers: H });
  if (!r.ok) throw new Error(akis + ' koşu listesi HTTP ' + r.status);
  const runs = (await r.json()).workflow_runs || []; const out = [];
  for (const run of runs) {
    const j = await fetch('https://api.github.com/repos/' + repo + '/actions/runs/' + run.id + '/jobs', { headers: H });
    if (!j.ok) continue;
    const adimlar = {};
    for (const job of (await j.json()).jobs || []) for (const st of job.steps || []) {
      if (!st.started_at || !st.completed_at || st.conclusion !== 'success') continue;
      adimlar[st.name] = (new Date(st.completed_at) - new Date(st.started_at)) / 60000;
    }
    out.push({ id: run.id, adimlar });
  }
  return out;
}

function sinav() {
  const k = (a) => ({ id: 0, adimlar: a });
  const gecmis = [k({ indir: 34, bas: 43, kur: 0.7 }), k({ indir: 35, bas: 42, kur: 0.6 }), k({ indir: 33, bas: 44, kur: 0.8 })];
  const VAKA = [
    ['sabit süre - alarm yok', [k({ indir: 34, bas: 43, kur: 0.7 }), ...gecmis], 0],
    ['hızlandı (03.10 optimizasyonu) - alarm yok', [k({ indir: 4, bas: 6, kur: 0.7 }), ...gecmis], 0],
    ['bir adım 2,5 katına çıktı - ALARM', [k({ indir: 86, bas: 43, kur: 0.7 }), ...gecmis], 1],
    ['küçük adım 3 katı ama +1,4 dk - alarm yok (gürültü)', [k({ indir: 34, bas: 43, kur: 2.1 }), ...gecmis], 0],
    ['+16 dk ama 2 katın altında - alarm yok (kat koşulu)', [k({ indir: 50, bas: 43, kur: 0.7 }), ...gecmis], 0],
    ['geçmiş yetersiz - KÖR', [k({ indir: 34 }), k({ indir: 34 })], -1],
  ];
  let dogru = 0;
  for (const [ad, kosular, bek] of VAKA) {
    const s = degerlendir('deneme', kosular); const olc = s.kor ? -1 : s.alarm.length;
    if (olc === bek) dogru++; else console.log('  YANLIS: ' + ad + ' (beklenen ' + bek + ', ölçülen ' + olc + ')');
  }
  console.log('SURE NOBETCISI OZ-SINAVI' + (MUT ? ' [mutasyon ' + MUT + ']' : '') + ': ' + dogru + '/' + VAKA.length);
  return dogru === VAKA.length ? 0 : 1;
}

(async () => {
  const args = process.argv.slice(2);
  if (args.includes('--sinav')) {
    let kod = sinav();
    if (args.includes('--mutasyon') && !MUT) {
      const { execFileSync } = require('child_process'); let dusen = 0;
      for (const m of ['kat', 'esik']) { let kir = false; try { execFileSync(process.execPath, [__filename, '--sinav'], { env: { ...process.env, SN_MUTASYON: m }, stdio: 'pipe' }); } catch (e) { kir = true; }
        console.log('  MUTASYON ' + m + (kir ? ' -> sınav KIRMIZI (iyi)' : ' -> sınav YEŞİL kaldı (SINAV EKSIK)')); if (kir) dusen++; }
      if (dusen < 2) kod = 1;
    }
    process.exit(kod);
  }
  const token = process.env.GH_TOKEN || process.env.GITHUB_TOKEN, repo = process.env.GITHUB_REPOSITORY || 'cemdizdar85-arch/mevzuat-radar';
  if (!token) { console.log('SURE NOBETCISI: KOR - GH_TOKEN yok'); process.exit(0); }
  const fs = require('fs'); const ci = args.indexOf('--cikti'); const rapor = []; let alarm = 0;
  for (const akis of AKISLAR) {
    try {
      const s = degerlendir(akis, await cek(akis, token, repo));
      if (s.kor) { rapor.push('KOR  ' + s.kor); continue; }
      alarm += s.alarm.length; s.alarm.forEach(a => rapor.push('ALARM ' + a));
      rapor.push('     ' + akis + ' (son/ortanca dk): ' + s.satir.join(' · '));
    } catch (e) { rapor.push('KOR  ' + akis + ': ' + e.message); }
  }
  const ozet = 'SURE NOBETCISI: ' + AKISLAR.length + ' akış · ALARM ' + alarm;
  console.log(ozet); rapor.forEach(x => console.log('  ' + x));
  if (ci > -1) fs.writeFileSync(args[ci + 1], ozet + '\n\n' + rapor.join('\n') + '\n', 'utf8');
  process.exit(alarm ? 1 : 0);
})();
