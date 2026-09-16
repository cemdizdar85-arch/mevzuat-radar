// motor/kasa-kabuk.js — KASA MODU: Kaydır-Çöz sayfasını SORUSUZ KABUĞA çevirir (ADIM 2 · 16.09.2026)
//
// Cem 16.09: "depoda soru içeriği kalmasın". Hangi sayfaların kasa modunda olduğu TEK yerde:
// arac/kasa-modu.json ({"sayfalar":["kaydir/sgs/turkce.html", ...]}). Pilot: Türkçe.
//
// Sıra (yayin-bas.yml): sayfaları bas -> cevap dağılımı kapısı -> kasa-soru-yukle.js --yaz -> BU DOSYA --yaz -> ite.
// Sayfayı okuyan diğer betikler (dizin, deneme seti, seviye havuzu, cevap dağılımı) KABUKTAN ÖNCE koşar.
//
//   node motor/kasa-kabuk.js           KURU: eşdeğerliği ölçer, hiçbir dosyaya yazmaz
//   node motor/kasa-kabuk.js --yaz     eşdeğerlik tamsa sayfayı kabukla değiştirir
//   node motor/kasa-kabuk.js --sinav   öz-sınav (ağ yok)
//
// ⛔ EŞDEĞERLİK KAPISI (KUSUR-ONARIM-PROTOKOLU): kabuk yalnız kasadaki satırlar sayfadaki SORULAR ile
//    sayıca ve ALAN ALAN (anahtar sırası bağımsız) aynıysa yazılır. Tek fark -> o sayfa YAZILMAZ, çıkış 2.
//    Kasadaki satır sayfadan fazla/eksikse de durur (eski soru kasada kalmış ya da yükleme yarım).
'use strict';
const fs = require('fs');
const path = require('path');
const { sorulariCek } = require('./kasa-soru-yukle');

const KOK = path.resolve(__dirname, '..');
const SB = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/';
const UA = 'tetikte-kasa-kabuk/1.0';
const ISARET = 'data-kasa-sayfa=';

function kasaModu() {
  const y = path.join(KOK, 'arac', 'kasa-modu.json');
  const d = JSON.parse(fs.readFileSync(y, 'utf8').replace(/^﻿/, ''));
  return (d.sayfalar || []).map(String);
}

function kabukMu(html) { return html.includes(ISARET); }

// Anahtar sırasından bağımsız kanonik metin (jsonb anahtarları yeniden sıralar).
function kanonik(x) {
  if (Array.isArray(x)) return '[' + x.map(kanonik).join(',') + ']';
  if (x && typeof x === 'object') return '{' + Object.keys(x).sort().map(k => JSON.stringify(k) + ':' + kanonik(x[k])).join(',') + '}';
  return JSON.stringify(x);
}

// Sayfayı kabuğa çevirir. Sayfa yapısı beklenenden farklıysa HATA atar (tahminle yazmaz).
function kabukKur(html, yol) {
  if (kabukMu(html)) throw new Error('zaten kabuk');
  const bas = html.indexOf('const SORULAR=');
  if (bas < 0 || html.indexOf('const SORULAR=', bas + 1) >= 0) throw new Error('const SORULAR= tam bir kez olmalı');
  const dizi = bas + 'const SORULAR='.length;
  if (html[dizi] !== '[') throw new Error('SORULAR dizi değil');
  // dizinin kapanışını dize-farkında bul
  let d = 0, z = false, e = false, son = -1;
  for (let k = dizi; k < html.length; k++) {
    const c = html[k];
    if (z) { if (e) e = false; else if (c === '\\') e = true; else if (c === '"') z = false; continue; }
    if (c === '"') z = true; else if (c === '[') d++;
    else if (c === ']') { d--; if (d === 0) { son = k; break; } }
  }
  if (son < 0) throw new Error('SORULAR kapanmadı');
  if (html[son + 1] !== ';') throw new Error('SORULAR sonrası ; yok');
  const acilis = html.lastIndexOf('<script', bas);
  if (acilis < 0 || !html.startsWith('<script>', acilis)) throw new Error('asıl betik <script> ile açılmıyor');
  if (html.indexOf('</script>', acilis) < bas) throw new Error('SORULAR asıl betiğin içinde değil');
  const kapanis = html.indexOf('</script>', son);
  if (kapanis < 0) throw new Error('asıl betik kapanmıyor');
  const govdeSon = html.lastIndexOf('</body>');
  if (govdeSon < kapanis) throw new Error('</body> asıl betikten sonra değil');
  const htmlAc = html.search(/<html[\s>]/i);
  if (htmlAc < 0 || htmlAc > acilis) throw new Error('<html> etiketi yok');

  const derinlik = yol.split('/').length - 1;
  const onek = '../'.repeat(derinlik);
  let y = html.slice(0, acilis)
    + '<script type="text/x-tetikte-kasa" id="kasaAna">'
    + html.slice(acilis + '<script>'.length, bas)
    + 'const SORULAR=window.__KASA_SORULAR||[];'
    + html.slice(son + 2, govdeSon)
    + '<script src="' + onek + 'kasa-yukle.js"></script>'
    + html.slice(govdeSon);
  y = y.slice(0, htmlAc + 5) + ' ' + ISARET + JSON.stringify(yol) + y.slice(htmlAc + 5);
  return y;
}

async function kasaSatirlari(yol) {
  const K = process.env.SUPABASE_SERVICE_KEY;
  if (!K) throw new Error('SUPABASE_SERVICE_KEY yok');
  const h = { apikey: K, Authorization: 'Bearer ' + K, 'User-Agent': UA };
  const out = [];
  for (let i = 0; ; i += 200) {
    const r = await fetch(SB + 'paket_soru?select=id,sira,veri&sayfa=eq.' + encodeURIComponent(yol) + '&order=sira.asc,id.asc&limit=200&offset=' + i, { headers: h });
    if (!r.ok) throw new Error(`kasa okunamadı HTTP ${r.status} ${(await r.text()).slice(0, 160)}`);
    const p = await r.json();
    out.push(...p);
    if (p.length < 200) break;
  }
  return out;
}

function esdeger(sorular, satirlar) {
  const fark = [];
  if (sorular.length !== satirlar.length) fark.push(`sayı: sayfa ${sorular.length} · kasa ${satirlar.length}`);
  const n = Math.min(sorular.length, satirlar.length);
  for (let i = 0; i < n; i++) {
    const s = satirlar[i];
    if (s.sira !== i) { fark.push(`sıra ${i}: kasada sira=${s.sira}`); continue; }
    if (String(s.id) !== String(sorular[i].id)) { fark.push(`sıra ${i}: kimlik ${sorular[i].id} ≠ ${s.id}`); continue; }
    if (kanonik(s.veri) !== kanonik(sorular[i])) fark.push(`sıra ${i} (${s.id}): içerik farklı`);
  }
  return fark;
}

function sinav() {
  let hata = 0; const t = (ad, k) => { console.log((k ? '  geçti: ' : '  DÜŞTÜ: ') + ad); if (!k) hata++; };
  const html = '<!doctype html><html lang="tr"><head><script src="../../paket-kapisi.js"></script></head><body><div id="akis"></div>\n'
    + '<script>\nconst A=1;\nconst SORULAR=[{"id":"e/kp-01","soru":"a ] [ \\" x"}];\nfunction f(){ return SORULAR.length; }\nwindow.addEventListener(\'load\',f);\n</script></body></html>';
  const k = kabukKur(html, 'kaydir/sgs/turkce.html');
  t('kabukta soru metni yok', !k.includes('kp-01') && !k.includes('a ] ['));
  t('kabuk işaretli', k.includes('data-kasa-sayfa="kaydir/sgs/turkce.html"'));
  t('asıl betik bekleyen tipte', k.includes('<script type="text/x-tetikte-kasa" id="kasaAna">\nconst A=1;\nconst SORULAR=window.__KASA_SORULAR||[];\nfunction f()'));
  t('yükleyici </body> önünde, doğru derinlikte', k.includes('<script src="../../kasa-yukle.js"></script></body></html>'));
  t('kapı betiği yerinde', k.includes('<script src="../../paket-kapisi.js"></script>'));
  let atti = false; try { kabukKur(k, 'kaydir/sgs/turkce.html'); } catch (e) { atti = true; }
  t('kabuk ikinci kez kurulmaz', atti);
  atti = false; try { kabukKur(html.replace('const SORULAR=', 'const SORULAR=[];const SORULAR='), 'x/y.html'); } catch (e) { atti = true; }
  t('iki SORULAR -> durur', atti);
  const S = [{ id: 'a', x: 1, y: { p: 1, q: [1, 2] } }, { id: 'b' }];
  t('anahtar sırası farkı eşdeğer', esdeger(S, [{ id: 'a', sira: 0, veri: { y: { q: [1, 2], p: 1 }, x: 1, id: 'a' } }, { id: 'b', sira: 1, veri: { id: 'b' } }]).length === 0);
  t('içerik farkı yakalanır', esdeger(S, [{ id: 'a', sira: 0, veri: { id: 'a', x: 2, y: { p: 1, q: [1, 2] } } }, { id: 'b', sira: 1, veri: { id: 'b' } }]).length === 1);
  t('sayı farkı yakalanır', esdeger(S, [{ id: 'a', sira: 0, veri: S[0] }]).length === 1);
  t('dizi sırası farkı yakalanır', esdeger(S, [{ id: 'a', sira: 0, veri: { id: 'a', x: 1, y: { p: 1, q: [2, 1] } } }, { id: 'b', sira: 1, veri: { id: 'b' } }]).length === 1);
  console.log(hata ? `ÖZ-SINAV DÜŞTÜ (${hata})` : 'ÖZ-SINAV GEÇTİ');
  return hata;
}

async function ana() {
  if (process.argv.includes('--sinav')) { process.exitCode = sinav() ? 1 : 0; return; }
  const liste = kasaModu();
  // --tam-mi: yayında sayfa basımından HEMEN SONRA koşar. Kasa modundaki sayfa bu koşuda tam basılmadıysa
  // (hâlâ kabuksa) sayfayı okuyan betikler (cevap dağılımı, dizin, deneme seti, seviye havuzu) o dersi
  // SESSİZCE boş sayar — cevap-dagilimi.json'da dersin tabanı silinir (16.09 okuyucu taraması). Burada durulur.
  if (process.argv.includes('--tam-mi')) {
    const kabuk = liste.filter(y => fs.existsSync(path.join(KOK, y)) && kabukMu(fs.readFileSync(path.join(KOK, y), 'utf8')));
    if (kabuk.length) { console.error('⛔ kasa modundaki sayfa bu koşuda tam basılmadı (hâlâ kabuk): ' + kabuk.join(', ')); process.exitCode = 1; return; }
    console.log(`kasa modundaki ${liste.length} sayfanın hepsi tam basılı — okuyucular güvenle koşabilir`);
    return;
  }
  const yaz = process.argv.includes('--yaz');
  console.log(`KASA KABUK · ${yaz ? 'YAZ' : 'KURU'} · kasa modunda ${liste.length} sayfa`);
  let dusen = 0;
  for (const yol of liste) {
    const tam = path.join(KOK, yol);
    if (!fs.existsSync(tam)) { console.log(`  ⛔ ${yol}: dosya yok`); dusen++; continue; }
    const html = fs.readFileSync(tam, 'utf8');
    if (kabukMu(html)) { console.log(`  = ${yol}: zaten kabuk`); continue; }
    const sorular = sorulariCek(html);
    const satirlar = await kasaSatirlari(yol);
    const fark = esdeger(sorular, satirlar);
    if (fark.length) {
      console.log(`  ⛔ ${yol}: EŞDEĞERLİK DÜŞTÜ (${fark.length} fark) — sayfa YAZILMADI`);
      fark.slice(0, 8).forEach(f => console.log('     ' + f));
      dusen++; continue;
    }
    const kabuk = kabukKur(html, yol);
    console.log(`  ✓ ${yol}: ${sorular.length} soru kasayla birebir · ${(html.length / 1048576).toFixed(2)} MB -> ${(kabuk.length / 1024).toFixed(0)} KB`);
    if (yaz) fs.writeFileSync(tam, kabuk, 'utf8');
  }
  if (!yaz) console.log('  KURU — hiçbir dosyaya yazılmadı.');
  if (dusen) process.exitCode = 2;
}

if (require.main === module) ana().catch(e => { console.error('KASA KABUK DÜŞTÜ: ' + e.message); process.exitCode = 1; return; });
module.exports = { kabukKur, kabukMu, kanonik, esdeger };
