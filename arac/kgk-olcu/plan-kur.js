// Plan kurucu (t4–t8 aracının dalga parametreli hâli, 29.10). Grup başına kolay/zor/cokzor satırı; konu dosyası hazır dosyadaki sorulardan.
// ⛔ ZORUNLU KAPI (29.10, Cem "gm önerilerini yap" — öneri B): her hazır dosya teslim denetiminden (hazir-soru-denetle.ps1) ve
//   çizim kapısından (kgk-ek-kapi.js KGK-CZ) KUSURSUZ geçmeden plan YAZILMAZ. Neden (23.10 ölçüldü): spk-g5 okumaya teslim denetimi
//   koşulmadan gitti; 21 sorunun 11'i bulutta KAPI-Ş'den düştü, dört tur okuma boşa gitti.
// ⛔ ZORUNLU KAPI 3 (30.10): konu-profil.js denetle — grup konu konu gerçek sınav karışımını tutmuyorsa plan YAZILMAZ.
//   03.11: + gizli izler (tek harf ad · yıllı kök · şık boy oranı) + B30 kalıp (ders dışı kalıp · tek tipe yığma).
// ⛔ ZORUNLU KAPI 4 (03.11): olcu-satiri.js — soru başı ölçü satırı (B31); her soru GEÇER değilse plan YAZILMAZ.
// node plan-kur.js <depo> <dalga> <planAdi>=<grup1>+<grup2>,...  [--usd-soru 0.06]
const fs = require('fs'), path = require('path'), cp = require('child_process');
const arg = process.argv.slice(2); let usd = 0.06; const ui = arg.indexOf('--usd-soru'); if (ui >= 0) { usd = +arg[ui + 1]; arg.splice(ui, 2); }
const [depo, dalga, tanimS] = arg;
// Kök tavanı (03.11, Cem "Evet, kur"): modülün GERÇEK p90'ı — konu-profil-gercek.json (çıkmış 2016+, metin↔etiket bağı İÇERİKLE,
//   kalip/bagla.js; kalip/tavan-olc.js). Eski 784/661 SGS ders sözlüğüyle sınıflanmış anatomi dosyasından geliyordu (1.663 sorunun
//   1.012'si sınıfsız); ara sürüm (sıra bağı) %18–35 yanlış modülden ölçmüştü. Hedef uzunluk (medyan) konu-profil.js'te; burası tek soru üst sınırı.
const DERS = {
  tds: ['Türkiye Denetim Standartları', 'b) Türkiye Denetim Standartları', 653], tms: ['Türkiye Muhasebe Standartları', 'a) Türkiye Muhasebe Standartları', 707],
  fy: ['Finansal Yönetim', 'c) Finansal Yönetim', 366], ky: ['Kurumsal Yönetim', 'c) Kurumsal Yönetim', 341], spk: ['Sermaye Piyasası Mevzuatı', 'ç) Sermaye Piyasası Mevzuatı', 428],
  banka: ['Bankacılık Mevzuatı', 'd) Bankacılık Mevzuatı', 501], sigorta: ['Sigortacılık ve Özel Emeklilik Mevzuatı', 'e) Sigortacılık ve Özel Emeklilik', 519],
  tsrs: ['Kurumsal Sürdürülebilirlik Raporlaması', 'f) Sürdürülebilirlik Raporlaması', 995], gds: ['Sürdürülebilirlik Denetimi', 'g) Sürdürülebilirlik Denetimi', 780]
};
let kusur = 0;
for (const tanim of tanimS.split(',')) {
  const [plan, gruplarS] = tanim.split('='); const sat = []; let n = 0;
  // 30.10: plan-kgk-t8-tsrs-c adı 22.10'daki bitmiş plana aitti, yeni plan onu ezdi (72c6f12b; geri alındı eb6d99bd). Var olan plan adı YAZILMAZ.
  if (fs.existsSync(path.join(depo, `veri/sinav/plan-kgk-${dalga}-${plan}.json`))) { kusur++; console.log(`⛔ plan-kgk-${dalga}-${plan}.json ZATEN VAR — başka ad seç`); continue; }
  for (const g of gruplarS.split('+')) {
  // zorunlu kapı 3 (30.10, Cem "evet, koy"): konu konu gerçek sınav profili (konu-profil.js; eşikler gerçek sorularla kalibre,
  //   gerçekten kurulan grupların %91'i geçer, t1–t8 gruplarımızın 131'inden 1'i). Grubun üç zorluk dosyası birlikte ölçülür.
  const kp = cp.spawnSync(process.execPath, [path.join(__dirname, 'konu-profil.js'), 'denetle', path.join(depo, 'veri', 'fabrika'), `^hazir-kgk-${dalga}-`, g], { encoding: 'utf8' });
  if (kp.status !== 0) { kusur++; console.log(`⛔ KONU PROFİLİ ${g} — plan YAZILMAZ\n${(kp.stdout || kp.stderr || '').trim()}`); continue; }
  // zorunlu kapı 4 (03.11, sözleşme B31 "her kural ölçülür"): soru başı ölçü satırı — her soru GEÇER olmalı (ÖLÇÜLMEDİ geçer sayılmaz).
  //   Satırlar <IS>\olcu\<dalga>-<grup>.tsv'ye yazılır; teslim raporunun parçasıdır.
  const os = cp.spawnSync(process.execPath, [path.join(__dirname, 'olcu-satiri.js'), path.join(depo, 'veri', 'fabrika'), dalga, g, '--yaz'], { encoding: 'utf8' });
  if (os.status !== 0) { kusur++; console.log(`⛔ ÖLÇÜ SATIRI ${g} — plan YAZILMAZ: ${((os.stdout || '').trim().split('\n').pop()) || os.stderr} (ayrıntı olcu\\${dalga}-${g}.tsv)`); continue; }
  for (const z of ['kolay', 'zor', 'cokzor']) {
    const et = `kgk-${dalga}-${g}-${z}`, hz = `veri/fabrika/hazir-${et}.json`, kd = `veri/sinav/konu/${et}.json`;
    const A = JSON.parse(fs.readFileSync(path.join(depo, hz), 'utf8').replace(/^﻿/, '')); if (!A.length) continue;
    const [d, da, tavan] = DERS[g.split('-')[0]];
    // zorunlu kapı 1: teslim denetimi (KUSUR satırı sayılır)
    const t = cp.spawnSync('powershell', ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', path.join(depo, 'arac', 'hazir-soru-denetle.ps1'), '-Dosya', hz, '-IkizEtiket', et, '-Tavan', String(tavan)], { cwd: depo, encoding: 'utf8' });
    const oz = ((t.stdout || '').match(/ozet: (\d+)\/(\d+) soru kusursuz/) || []);
    if (!oz.length || oz[1] !== oz[2]) { kusur++; console.log(`⛔ TESLİM DENETİMİ ${et}: ${oz[0] || 'özet okunamadı'} — plan YAZILMAZ`); continue; }
    // zorunlu kapı 2: çizim kapısı
    const c = cp.spawnSync(process.execPath, [path.join(depo, 'arac', 'kgk-ek-kapi.js'), '--dosya', path.join(depo, hz)], { encoding: 'utf8' });
    const cz = ((c.stdout || '').match(/KGK-CZ/g) || []).length;
    if (cz) { kusur++; console.log(`⛔ ÇİZİM KAPISI ${et}: ${cz} soru KGK-CZ — plan YAZILMAZ`); continue; }
    fs.writeFileSync(path.join(depo, kd), JSON.stringify(A.map(q => q.konu), null, 2) + '\n');
    sat.push({ ders: d, dersAd: da, etiket: et, adet: A.length, zorluk: z, sinav: 'KGK', konuDosya: kd, toplu: true, disla: '', tur: 1, hazirSoru: hz, tavan });
    n += A.length;
  }
  }
  if (kusur) continue;
  fs.writeFileSync(path.join(depo, `veri/sinav/plan-kgk-${dalga}-${plan}.json`), JSON.stringify(sat, null, 2) + '\n');
  console.log(`plan-kgk-${dalga}-${plan}: ${sat.length} satır · ${n} soru · tavan ${(Math.ceil(n * usd * 10) / 10).toFixed(1)} USD (${usd}/soru; ölçülen t8 SPK 0,043–0,05/soru)`);
}
process.exit(kusur ? 1 : 0);
