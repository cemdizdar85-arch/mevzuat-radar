#!/usr/bin/env node
// ============================================================================
//  KAPI-TERIM — TERİM NOTUNDA "KİM BELİRLER" HESAP KALEMİNE BELİRLEYİCİ UYDURMASIN (07.11.2026, Cem "kural oluştur") · 0 USD
//  Konu özeti terim satırını `konu_giris.terimler[].kim` + `kaynak` ile basar (motor/kaydir-coz.ps1). `kim` zorunlu ve kapalı listeydi;
//  gerçek hayatta kimsenin "koymadığı", kayıttan gelen ya da formülle çıkan kalemde model listeden en yakınını seçiyordu.
//    TERIM-KIM : dönem stoku, ortalama stok, devir hızı, finansal analiz oranı → "piyasa fiyatlar" / "işletme yönetimi ..." yazmış
//  Bu kalemlerde doğrusu `kim` BOŞ bırakmaktır; sayfa boş kim'i basmaz, `kaynak` kalır.
//  NİYE VAR (ölçüldü 06-07.11): smmm-4k-a-yfta-kolay-r6/kp-01 "Dönem Sonu Stok · piyasa fiyatlar", "Ortalama Stok · işletme yönetimi
//    tahmin eder". Sayılar commit mesajında ve SORU-URETIM-SOZLESMESI.md B33'te (yerel önbellek, tazeliği ölçülmedi).
//  DÜZEY: arac/soru-kalite-kapisi.js üzerinden YALNIZ B33 eşiğinden yeni soruda DURDURUR, eskide NOT-TERIM (yayındaki soru düşmez).
//  🚫 GÖRMEZ: bu dar ad listesi dışındaki terim (yükleme oranı, kapasite kullanım oranı, faiz oranı bilerek dışarıda: yönetim ya da piyasa
//    meşru olabilir) · "kanun sabitler" / "Tekdüzen tanımlar" gibi öbür seçeneklerin yanlış kullanımı · `tanim` metninin doğruluğu.
//    Geniş denetim açıklama hakemi kural 6'dadır (arac/aciklama-hakemi-cekirdek.ps1); yakalama oranı ÖLÇÜLMEDİ.
//  Kullanım: node arac/terim-kim-kapisi.js --sinav [--mutasyon] | --kasa [önbellek klasörü]
// ============================================================================
'use strict';
const fs = require('fs'), path = require('path');
const MUT = process.env.TERIM_MUTASYON || '';

// Bu sözcükler varsa terim artık hesap kalemi değil, seçim/tahmin konusudur: yönetim ya da piyasa meşru olabilir.
const SECIM = /yöntem|politika|seçim|hedef|bütçe|standart|tahmin/;
const STOK = /ortalama stok|dönem (başı|sonu) (stok|yarı mamul|mamul|ticari mal)|stok tutarı/;
const DEVIR = /devir (hızı|süresi)/;
const ORAN = /(cari|asit-? ?test|likidite|nakit|kaldıraç|özkaynak\w*|borçlanma|kârlılık|karlılık) oran/;
const BELIRLEYEN = /piyasa fiyatlar|işletme yönetimi|yönetim tahmin/;

const kucuk = s => String(s || '').toLocaleLowerCase('tr-TR');
function hesapKalemi(ad) {
  const a = kucuk(ad);
  if (MUT !== 'secim-yok' && SECIM.test(a)) return false;
  return (MUT !== 'stok-yok' && STOK.test(a)) || (MUT !== 'devir-yok' && DEVIR.test(a)) || (MUT !== 'oran-yok' && ORAN.test(a));
}
function kusurlar(k) {
  const g = k && k.konu_giris; if (!g || typeof g !== 'object' || !Array.isArray(g.terimler)) return [];
  const c = [];
  for (const t of g.terimler) {
    if (!t || !t.ad || !t.kim) continue;
    if (MUT !== 'belirleyen-yok' && BELIRLEYEN.test(kucuk(t.kim)) && hesapKalemi(t.ad)) c.push({ tur: 'TERIM-KIM', not: t.ad + ' · ' + t.kim });
  }
  return c;
}

function sinav() {
  const K = (ad, kim) => ({ konu_giris: { terimler: [{ ad, kim, tanim: '.', kaynak: 'soruda verilir' }] } });
  const V = [
    // yakalamalı (gerçek kayıtlardan)
    ['Dönem Sonu Stok', 'piyasa fiyatlar', 1], ['Ortalama Stok', 'işletme yönetimi tahmin eder ya da belirler', 1],
    ['Dönem başı stok', 'piyasa fiyatlar (satış bedeli, alış bedeli gibi gerçekleşen tutarlar)', 1], ['Stok devir hızı', 'işletme yönetimi tahmin eder ya da belirler', 1],
    ['Aktif devir hızı', 'işletme yönetimi tahmin eder ya da belirler', 1], ['Cari oran', 'işletme yönetimi tahmin eder ya da belirler', 1],
    ['Asit-test oranı', 'işletme yönetimi tahmin eder ya da belirler', 1], ['Dönem sonu yarı mamul stoku', 'işletme yönetimi tahmin eder ya da belirler', 1],
    ['Kaldıraç oranı', 'piyasa fiyatlar', 1],
    // yanlış alarm vermemeli
    ['Ortalama stok yöntemi', 'işletme yönetimi tahmin eder ya da belirler', 0], ['Faiz oranı', 'piyasa fiyatlar', 0], ['Faydalı ömür', 'işletme yönetimi tahmin eder ya da belirler', 0],
    ['Satış bedeli', 'piyasa fiyatlar', 0], ['Yükleme oranı', 'işletme yönetimi tahmin eder ya da belirler', 0], ['Hedef cari oran', 'işletme yönetimi tahmin eder ya da belirler', 0],
    ['Ortalama Stok', '', 0], ['Stok devir hızı', 'Tekdüzen hesap planı ya da standart tanımlar', 0], ['Stok değer düşüklüğü', 'işletme yönetimi tahmin eder ya da belirler', 0],
  ];
  let ok = 0;
  for (const [ad, kim, b] of V) { const v = kusurlar(K(ad, kim)).length; if ((v > 0) === !!b) ok++; else console.log('  DÜŞTÜ: ' + ad + ' · ' + kim); }
  const bos = [kusurlar({}), kusurlar({ konu_giris: 'metin' }), kusurlar({ konu_giris: { terimler: [null, {}] } })].every(x => x.length === 0);
  if (bos) ok++; else console.log('  DÜŞTÜ: eksik alan patlamamalı');
  const top = V.length + 1, y = ok === top;
  console.log((y ? 'KAPI-TERIM ÖZ-SINAVI YEŞİL' : 'KAPI-TERIM ÖZ-SINAVI KIRMIZI') + ` (${ok}/${top})` + (MUT ? ' · TERIM_MUTASYON=' + MUT : ''));
  return y;
}

function kasa(dir) {
  const o = { dosya: 0, soru: 0, kusurlu_soru: 0, kusur: 0 }, ad = {};
  for (const f of fs.readdirSync(dir).filter(f => /^kalip-parti-.*\.json$/.test(f))) {
    let p; try { p = JSON.parse(fs.readFileSync(path.join(dir, f), 'utf8').replace(/^﻿/, '')); } catch (e) { continue; }
    o.dosya++;
    for (const kp of Object.keys(p)) {
      if (!/^kp-/.test(kp) || !p[kp] || !p[kp].soru) continue; o.soru++;
      const ks = kusurlar(p[kp]); if (ks.length) { o.kusurlu_soru++; o.kusur += ks.length; ks.forEach(b => { const a = b.not.split(' · ')[0]; ad[a] = (ad[a] || 0) + 1; }); }
    }
  }
  o.en_sik = Object.entries(ad).sort((a, b) => b[1] - a[1]).slice(0, 12);
  return o;
}

module.exports = { kusurlar };
if (require.main === module) {
  const a = process.argv.slice(2);
  if (a[0] === '--sinav') {
    if (a.includes('--mutasyon')) {
      if (!sinav()) { console.log('MUTASYON koşulmadı: bozulmamış öz-sınav zaten KIRMIZI'); process.exit(1); }
      const { spawnSync } = require('child_process');
      const ler = ['stok-yok', 'devir-yok', 'oran-yok', 'belirleyen-yok', 'secim-yok'];
      let tutan = 0;
      for (const m of ler) { const r = spawnSync(process.execPath, [__filename, '--sinav'], { env: { ...process.env, TERIM_MUTASYON: m }, encoding: 'utf8' }); const kr = r.status !== 0; if (kr) tutan++; console.log('  mutasyon ' + m + ' ' + (kr ? 'KIRMIZI (doğru)' : 'YEŞİL (YANLIŞ)')); }
      console.log('MUTASYON: ' + tutan + '/' + ler.length + ' mutasyon KIRMIZI'); process.exit(tutan === ler.length ? 0 : 1);
    }
    process.exit(sinav() ? 0 : 1);
  }
  if (a[0] === '--kasa') { console.log(JSON.stringify(kasa(a[1] || path.join(__dirname, '..', 'veri', 'fabrika')), null, 1)); process.exit(0); }
  console.log('kullanım: --sinav [--mutasyon] | --kasa [klasör]'); process.exit(2);
}
