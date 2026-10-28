#!/usr/bin/env node
// ============================================================================
//  HESAP TABLOSU KAPISI (28.10.2026) — açıklamadaki "🧮 Hesap" tablosunun yeşil sonuç satırı DOĞRU şıkla tutmalı
//
//  OLAY (ölçüldü 28.10, paket_soru 10.410 soru): sade kipte 4.233 soruda tablo çıkıyordu; 20'sinde SON satır ("Kontrol",
//    "Sağlama", "Toplam", "Kalan KDV") yanlış bir şıkkın rakamıydı ve yeşil "sonuç" boyanıyordu (ör. maliyet "Kontrol:
//    üçüncü mamul = 90.000", doğru B) 144.000). Cem: "doğru şekilde, yanlışımız yok … deme".
//  KURAL (motor/kaydir-coz.ps1 28.10 bloğu; bu araç O KODU dosyadan okur, kopya tutmaz):
//    sonuç satırı = değeri doğru şıkla tutan SON satır (%16 = 0,16 = 16 eşdeğer); hiçbir satır tutmazsa tablo ÇİZİLMEZ.
//  node arac/hesap-tablosu-kapisi.js --sinav        yapay vakalar (kod kaydir-coz.ps1'den)
//  node arac/hesap-tablosu-kapisi.js --mutasyon     kural bozulunca sınav düşer mi
//  node arac/hesap-tablosu-kapisi.js --kasa         bankanın TAMAMI (SUPABASE_SERVICE_KEY): kaç tablo, kaçının sonucu doğru şık
//  🚫 GÖRMEZ: tablonun ara satırlarının doğruluğu (yalnız sonuç satırı ↔ doğru şık) · rakamsız sonuç (ör. "olumsuz") yazısı.
// ============================================================================
'use strict';
const fs = require('fs'), path = require('path');
const MUT = process.env.HT_MUTASYON || '';
const kod = fs.readFileSync(path.join(__dirname, '..', 'motor', 'kaydir-coz.ps1'), 'utf8');
const rkSatir = (kod.match(/const rk=t=>\([^\n]+/) || [])[0], tutSatir = (kod.match(/const dS=rk\([^\n]+/) || [])[0];
if (!rkSatir || !tutSatir) { console.log('KAPI-HT: kaydir-coz.ps1 içinde rk/tutar kuralı bulunamadı — kod değişmiş'); process.exit(1); }
// eslint-disable-next-line no-new-func
const kur = new Function('s', rkSatir + '\n' + tutSatir + '\nreturn tutar;');
function sonucSatiri(s, satirlar) {
  if (MUT === 'son-satir') return satirlar.length - 1;
  const tutar = kur(s); let sonI = -1; satirlar.forEach((x, i) => { if (tutar(x)) sonI = i; }); return sonI;
}
function tabloSatirlari(s) {
  const tb = s.tablo; const teori = !!(s.teori || s.tip === 'teori' || (tb && tb.basliklar && tb.basliklar[0] === 'Adım'));
  if (!tb || !tb.satirlar || !tb.satirlar.length || teori || s.tip === 'kayit') return null;
  const hi = tb.satirlar.findIndex(r => /^HESAP$/i.test(String(r[0] || '').trim())), bas = hi >= 0 ? hi + 1 : 0;
  const L = tb.satirlar.slice(bas).map(r => ({ ad: String(r[0] || '').trim(), deger: String(r[r.length - 1] || '').trim() })).filter(x => x.ad && x.deger && x.deger !== '-' && !/^VERİLENLER$/i.test(x.ad));
  return L.length >= 2 && L.length <= 14 ? L : null;
}
// sonuç satırının rakamı yanlış bir şıkta geçiyor mu (doğru şıkta da geçmiyorsa)
function yanlisSikta(s, x) {
  const tutar = kur(s); if (tutar(x)) return false;
  return Object.keys(s.siklar || {}).some(h => h !== s.dogru && kur(Object.assign({}, s, { dogru: h }))(x));
}

function sinav() {
  const V = []; const t = (a, k) => V.push([a, !!k]);
  const s1 = { dogru: 'B', siklar: { A: '90.000', B: '144.000', C: '200.000' }, tablo: { satirlar: [['HESAP', '-'], ['Birinci mamul', '144.000'], ['Kontrol: üçüncü mamul', '90.000']] } };
  const L1 = tabloSatirlari(s1), i1 = sonucSatiri(s1, L1);
  t('kontrol satırı yanlış şıkta: sonuç = doğru şıkla tutan satır (1. satır)', i1 === 0);
  t('yeşil satır yanlış şıkkın rakamı DEĞİL', !yanlisSikta(s1, L1[i1]));
  const s2 = { dogru: 'A', siklar: { A: '0,16', B: '0,20' }, tablo: { satirlar: [['HESAP', '-'], ['Getiri', '0,24'], ['Treynor oranı', '%16']] } };
  t('%16 = 0,16 eşdeğer tutar', sonucSatiri(s2, tabloSatirlari(s2)) === 1);
  const s3 = { dogru: 'D', siklar: { C: '8.750.000 TL', D: '9.000.000 TL' }, tablo: { satirlar: [['HESAP', '-'], ['Sermaye', '175.000.000'], ['Yüzde beşi', '8.750.000']] } };
  t('hiçbir satır doğru şıkla tutmuyor → tablo çizilmez (-1)', sonucSatiri(s3, tabloSatirlari(s3)) === -1);
  const s4 = { dogru: 'C', siklar: { C: '9' }, tip: 'teori', tablo: { satirlar: [['A', '1'], ['B', '9']] } };
  t('kuram sorusunda tablo yok', tabloSatirlari(s4) === null);
  V.forEach(([a, k]) => console.log((k ? '  ✓ ' : '  ✗ ') + a));
  const g = V.filter(v => v[1]).length; console.log('KAPI-HT ÖZ-SINAV: ' + g + '/' + V.length + (MUT ? ' (mutasyon ' + MUT + ')' : '')); return g === V.length;
}

async function kasa() {
  const K = process.env.SUPABASE_SERVICE_KEY; if (!K) { console.log('SUPABASE_SERVICE_KEY yok'); process.exit(1); }
  const H = { apikey: K, Authorization: 'Bearer ' + K }, T = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/';
  let out = []; for (let o = 0; ; o += 500) { const r = await (await fetch(T + 'paket_soru?select=id,v:veri&order=id&limit=500&offset=' + o, { headers: H })).json(); out.push(...r); if (r.length < 500) break; }
  const S = { soru: out.length, tabloAday: 0, cizilen: 0, cizilmeyen: 0, yesilYanlisSikta: 0 }, liste = [];
  for (const x of out) { const s = x.v || {}, L = tabloSatirlari(s); if (!L) continue; S.tabloAday++;
    const i = sonucSatiri(s, L); if (i < 0) { S.cizilmeyen++; liste.push(x.id); continue; } S.cizilen++; if (yanlisSikta(s, L[i])) S.yesilYanlisSikta++; }
  console.log('KAPI-HT KASA: ' + JSON.stringify(S));
  if (process.argv.includes('--liste')) liste.forEach(id => console.log('  tablosuz: ' + id));
  return S.yesilYanlisSikta === 0;
}

const a = process.argv.slice(2);
if (a.includes('--mutasyon')) {
  const r = require('child_process').spawnSync(process.execPath, [__filename, '--sinav'], { env: Object.assign({}, process.env, { HT_MUTASYON: 'son-satir' }), encoding: 'utf8' });
  console.log('  mutasyon son-satir ' + (r.status ? 'KIRMIZI (doğru)' : 'YEŞİL — SINAV KÖR') + '\nMUTASYON: ' + (r.status ? 1 : 0) + '/1 → KIRMIZI'); process.exit(r.status ? 0 : 1);
} else if (a.includes('--sinav')) process.exit(sinav() ? 0 : 1);
else if (a.includes('--kasa')) kasa().then(ok => process.exit(ok ? 0 : 1));
else { console.log('kullanım: --sinav | --mutasyon | --kasa [--liste]'); process.exit(1); }
