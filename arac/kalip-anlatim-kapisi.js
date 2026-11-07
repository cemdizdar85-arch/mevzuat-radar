#!/usr/bin/env node
// ============================================================================
//  KAPI-KALIP — OLUMSUZ KÖKTE ŞABLON ANLATIM + TUTAR TERİMİNE "KANUN SABİTLER" (07.11.2026, B34, Cem "kural koymadığın ne varsa koy") · 0 USD
//    KALIP-ADIM   : olumsuz kökte adım "Öteki dört ifade kuralın bir şartını düşürüyor" der; oysa dördü kurala uyduğu için elenir
//    KALIP-YONTEM : olumsuz kökte yöntem "şartı eksik ya da başka hükme ait ifadeyi ele" der
//    KALIP-HESAP  : hesap kökünde (kaç ₺, kaç gün…) adım "Beş ifadeyi kuralın şartlarıyla" ya da "Öteki dört ifade kuralın" der
//    KALIP-TESHIS : doğru şıkta "Hangi ifade kuralın kendisiyle örtüşüyor?" ya da "şartlarından birini başka bir hükümle" şablonu
//    KALIP-CEVAP  : (B35) desen, harita, yöntem, sınavda alanı doğru şıkkı ya da "III yanlıştır" cevabını söyler
//    KALIP-GUNDELIK: (B35) muhasebe, vergi, hukuk, denetim dersinde konu örneği arkadaş, kantin, harçlık benzetmesi
//    KALIP-DAYANAK: (B35) dayanak başlığında harfsiz yazım, yapışık BÖLÜM, dipnot rakamı
//    KALIP-KIM    : taraflarca konan tutara (vade farkı, iskonto, kur farkı, taşıma gideri, işçilik ücreti) "kanun sabitler"
//  NİYE VAR (ölçüldü 07.11, yerel 15.968 soru): smmm-4k-a-yvergi-kolay-r4/kp-19 ve Vergi'de 36 soru; bu cümleler depodaki kodda YOK, geçmiş ajan yazımından geldi.
//  DÜZEY: arac/soru-kalite-kapisi.js üzerinden yalnız 2026-11-08 ve sonrası soruda DURDURUR, eskide NOT-KALIP (yayındaki soru düşmez).
//  🚫 GÖRMEZ: bu cümlelerin başka yazılışı · kelime listesindeki olumsuz kök dışındaki kök (örn. "yukarıdakilerden hangileri indirilemez" listede, başka fiil görmez) ·
//    anlamca yanlış ama şablon olmayan cümle (o hakem kural 7'de, yakalama oranı ÖLÇÜLMEDİ).
//  Kullanım: node arac/kalip-anlatim-kapisi.js --sinav [--mutasyon] | --kasa [klasör]
// ============================================================================
'use strict';
const fs = require('fs'), path = require('path');
const MUT = process.env.KALIP_MUTASYON || '';
const OLUMSUZ = /(değildir|girmez|olamaz|yanlıştır|yanlış olan\w*|bulunmaz|sayılmaz|yapılamaz|indirilemez|gerekmez|dahil değildir|uygulanmaz|kabul edilmez)\s*\??\s*$/i;
const HESAP = /(kaç\s*(₺|tl|gün|ay|yıl|lira)|kaç\s+₺|tutarı kaçtır|kaçtır|ne kadardır)\S*\s*\??\s*$/i;
const ADIM = /Öteki dört ifade kuralın/, BES = /Beş ifadeyi kuralın şartlarıyla/;
const YONTEM = /şartı eksik ya da başka hükme/;
const TESHIS = /Hangi ifade kuralın kendisiyle örtüşüyor|şartlarından birini başka bir hükümle/;
const CEVAP = /(doğru (şık|seçenek|cevap)\s+[^.]{0,60}(dır|dir|tir|tır)\b|\b(I{1,3}|IV|V) numaralı (ifade|öncül)[^.]{0,40}yanlış|ifade yanlıştır)/i;
const GUNDELIK = /(arkadaşın|kantin|harçlı)/i, MESLEK = /muhasebe|vergi|hukuk|denetim|finansal|maliyet|sermaye|meslek|bankacılık|sigorta/i;
const DAYANAK = /(Yonetmeligi|Tebligi|Kar Payi)|[A-ZÇĞİÖŞÜ]{4,} BÖLÜM|\bRDÜNCÜ\b|[a-zçğıöşü]{3}\d(?![\d.,])/;
const TUTAR = /^(vade farkı|iskonto|kur farkı|taşıma gideri|işçilik ücreti|külçe altın bedeli|cif değeri)$/i;
function kusurlar(k) {
  if (!k || typeof k !== 'object' || !k.soru) return [];
  const kok = String(k.soru).trim(), c = [];
  const ol = MUT !== 'olumsuz-yok' && OLUMSUZ.test(kok), he = MUT !== 'hesap-yok' && HESAP.test(kok);
  const ad = Array.isArray(k.adimlar) ? k.adimlar.map(a => String((a && a.anlatim) || '')).join(' ') : '';
  const g = (k.konu_giris && typeof k.konu_giris === 'object') ? k.konu_giris : {};
  if (ol && ADIM.test(ad)) c.push({ tur: 'KALIP-ADIM', not: 'olumsuz kökte öteki şıklar şartı eksik diye anlatılmış' });
  if (ol && MUT !== 'yontem-yok' && YONTEM.test(String(g.yontemler || ''))) c.push({ tur: 'KALIP-YONTEM', not: 'olumsuz kökte şart eksikliği yöntemi' });
  if (he && (ADIM.test(ad) || BES.test(ad))) c.push({ tur: 'KALIP-HESAP', not: 'hesap sorusunda ifade karşılaştırması' });
  const d = k.teshis && k.teshis[k.dogru];
  if (MUT !== 'teshis-yok' && d && TESHIS.test(String(d.ayirt || '') + ' ' + String(d.yanilgi || ''))) c.push({ tur: 'KALIP-TESHIS', not: 'doğru şık teşhisi şablon' });
  if (MUT !== 'kim-yok' && Array.isArray(g.terimler)) for (const t of g.terimler) if (t && TUTAR.test(String(t.ad || '').trim()) && /kanun sabitler/i.test(String(t.kim || ''))) c.push({ tur: 'KALIP-KIM', not: t.ad + ' · ' + t.kim });
  if (MUT !== 'cevap-yok') for (const a of ['desen', 'harita', 'yontemler', 'sinavda']) if (CEVAP.test(String(g[a] || ''))) { c.push({ tur: 'KALIP-CEVAP', not: a }); break; }
  if (MUT !== 'gundelik-yok' && MESLEK.test(String(k.ders || k.konu || '')) && GUNDELIK.test(String(g.ornek || '') + ' ' + String(g.panel_ornek || ''))) c.push({ tur: 'KALIP-GUNDELIK', not: 'konu örneği gündelik benzetme' });
  if (MUT !== 'dayanak-yok' && DAYANAK.test(String(k.dayanak || ''))) c.push({ tur: 'KALIP-DAYANAK', not: String(k.dayanak).slice(0, 50) });
  return c;
}
function sinav() {
  const kok = 'Buna göre hangisi KDV matrahına girmez?', ad = [{ anlatim: 'Öteki dört ifade kuralın bir şartını düşürüyor.' }];
  const V = [
    ['olumsuz kök + adım şablonu', { soru: kok, adimlar: ad }, 'KALIP-ADIM'],
    ['olumsuz kök + yöntem şablonu', { soru: kok, konu_giris: { yontemler: 'şartı eksik ya da başka hükme ait ifadeyi ele' } }, 'KALIP-YONTEM'],
    ['indirilemez kökü', { soru: 'Hangileri indirilemez?', adimlar: ad }, 'KALIP-ADIM'],
    ['hesap kökü + ifade', { soru: 'Terkin edilecek tutar kaç ₺\'dir?', adimlar: ad }, 'KALIP-HESAP'],
    ['doğru şık teşhis şablonu', { soru: 'Hangisi doğrudur?', dogru: 'A', teshis: { A: { ayirt: 'Hangi ifade kuralın kendisiyle örtüşüyor?' } } }, 'KALIP-TESHIS'],
    ['tutar terimine kanun sabitler', { soru: 'x', konu_giris: { terimler: [{ ad: 'Vade farkı', kim: 'kanun sabitler' }] } }, 'KALIP-KIM'],
    ['olumlu kökte adım şablonu serbest', { soru: 'Hangisi doğrudur?', adimlar: ad }, null],
    ['olumlu kökte yöntem serbest', { soru: 'Hangisi doğrudur?', konu_giris: { yontemler: 'şartı eksik ya da başka hükme ait ifadeyi ele' } }, null],
    ['"değildir" kök ortasında serbest', { soru: 'Kurum mükellef değildir, buna göre hangisi doğrudur?', adimlar: ad }, null],
    ['kanun tanımına kanun sabitler serbest', { soru: 'x', konu_giris: { terimler: [{ ad: 'Mükellef', kim: 'kanun sabitler' }] } }, null],
    ['boş kim serbest', { soru: 'x', konu_giris: { terimler: [{ ad: 'İskonto', kim: '' }] } }, null],
    ['özet cevabı söylüyor', { soru: 'x', konu_giris: { desen: 'III numaralı ifade bu yüzden yanlıştır.' } }, 'KALIP-CEVAP'],
    ['tuzağı söylemek serbest', { soru: 'x', konu_giris: { desen: 'Tuzak m.24 bendini atlamaktır.' } }, null],
    ['meslek dersinde gündelik örnek', { soru: 'x', ders: 'Vergi Mevzuatı', konu_giris: { ornek: 'Kantinden aldığın yemek' } }, 'KALIP-GUNDELIK'],
    ['Türkçe dersinde gündelik serbest', { soru: 'x', ders: 'Türkçe', konu_giris: { ornek: 'Kantinden aldığın yemek' } }, null],
    ['harfsiz dayanak', { soru: 'x', dayanak: 'Etik Ilkeler Yonetmeligi m.3' }, 'KALIP-DAYANAK'],
    ['dipnot rakamı', { soru: 'x', dayanak: 'VUK m.30 Tarh8' }, 'KALIP-DAYANAK'],
    ['temiz dayanak', { soru: 'x', dayanak: 'KDVK m.24, m.25; TMS 32' }, null],
    ['eksik alan patlamaz', { soru: 'x' }, null],
  ];
  let ok = 0;
  for (const [ad2, k, b] of V) { const r = kusurlar(k).map(x => x.tur); const d = b ? r.includes(b) : r.length === 0; if (d) ok++; else console.log('  DÜŞTÜ:', ad2, r.join(',')); }
  const y = ok === V.length; console.log((y ? 'KAPI-KALIP ÖZ-SINAVI YEŞİL' : 'KAPI-KALIP ÖZ-SINAVI KIRMIZI') + ` (${ok}/${V.length})` + (MUT ? ' · KALIP_MUTASYON=' + MUT : '')); return y;
}
function kasa(dir) {
  const o = { soru: 0, kusurlu_soru: 0 }, tur = {};
  for (const f of fs.readdirSync(dir).filter(f => /^kalip-parti-.*\.json$/.test(f))) { let p; try { p = JSON.parse(fs.readFileSync(path.join(dir, f), 'utf8').replace(/^﻿/, '')); } catch (e) { continue; }
    for (const kp of Object.keys(p)) { if (!/^kp-/.test(kp) || !p[kp] || !p[kp].soru) continue; o.soru++; const ks = kusurlar(p[kp]); if (ks.length) { o.kusurlu_soru++; ks.forEach(b => { tur[b.tur] = (tur[b.tur] || 0) + 1; }); } } }
  o.tur = tur; return o;
}
module.exports = { kusurlar };
if (require.main === module) {
  const a = process.argv.slice(2);
  if (a[0] === '--sinav') {
    if (a.includes('--mutasyon')) {
      if (!sinav()) process.exit(1);
      const { spawnSync } = require('child_process'); const ler = ['olumsuz-yok', 'hesap-yok', 'yontem-yok', 'teshis-yok', 'kim-yok', 'cevap-yok', 'gundelik-yok', 'dayanak-yok']; let tut = 0;
      for (const m of ler) { const r = spawnSync(process.execPath, [__filename, '--sinav'], { env: { ...process.env, KALIP_MUTASYON: m }, encoding: 'utf8' }); const kr = r.status !== 0; if (kr) tut++; console.log('  mutasyon ' + m + ' ' + (kr ? 'KIRMIZI (doğru)' : 'YEŞİL (YANLIŞ)')); }
      console.log('MUTASYON: ' + tut + '/' + ler.length + ' mutasyon KIRMIZI'); process.exit(tut === ler.length ? 0 : 1);
    }
    process.exit(sinav() ? 0 : 1);
  }
  if (a[0] === '--kasa') { console.log(JSON.stringify(kasa(a[1] || path.join(__dirname, '..', 'veri', 'fabrika')))); process.exit(0); }
  console.log('kullanım: --sinav [--mutasyon] | --kasa [klasör]'); process.exit(2);
}
