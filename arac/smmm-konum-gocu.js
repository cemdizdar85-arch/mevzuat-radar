#!/usr/bin/env node
// ============================================================================
//  BİTİRME KALDIĞIN YER GÖÇÜ (12.10.2026, bedel 0) — Cem: "bu zaten var diye biliyorum, yoksa kesin olsun"
//
//  NEDEN: uygulama (Play 1.8.1, 09.10 derlemesi) ve eski site kaydı kaldığın yeri SIRA NUMARASIYLA tutar
//    (ogrenci_ilerleme.veri.konum[yol] = {i,t}, veri.son = {yol,i,t}). paket_soru.sira değişince (yeni soru sırası ya da
//    her yayında araya giren yeni soru) i başka soruyu gösterir. Uygulama gömülü olduğu için yeni derleme mağazaya çıkana
//    kadar istemciden düzeltilemez → sunucuda, yayınla AYNI işte çevrilir.
//  NASIL: yayından ÖNCE --yedekle eski sırayı (sayfa → kimlikler sıra düzeninde; içerik YOK) dosyaya yazar. Yayından SONRA
//    --goc o dosyayla her hesabın bitirme konumunu çevirir: eski i → kimlik → yeni i; kayda kimlik (q) de yazılır
//    (site kartı kimlikten bulur, ilerleme-web.js). Yeni t verilir → cihazdaki eski kayıt bir sonraki eşitlemede yenisine yenilir.
//    Yazım satır başına KOŞULLU (degisim aynıysa): arada cihaz yazdıysa o satır atlanır, sayılır, ezilmez.
//  YALNIZ kaydir/smmm/* konumları. Sıra değişmediyse (eski i = yeni i) satıra dokunulmaz (q eksikse bile).
//  🚫 GÖRMEZ: seviye testine göre cihazda yeniden sıralanmış görünüm (kasa-yukle.js seviyeSirala: kayıt o görünümün
//    sırasını tutar, sunucu öğrencinin seviye sonucunu bilmez → çeviri sira düzenini varsayar) · hiç eşitlenmemiş cihaz
//    kaydı (girişsiz/çevrimdışı) · kasadan çıkan soru (kimlik yeni sırada yoksa kayıt olduğu gibi kalır, sayılır).
//  EKRANA kişi kimliği / soru metni BASILMAZ (bulut günlüğü herkese açık): yalnız sayı.
//
//  node arac/smmm-konum-gocu.js --yedekle <dosya>                 eski sırayı yaz
//  node arac/smmm-konum-gocu.js --goc <eski> [--yeni <dosya>] [--yaz]   KURU (varsayılan) / yaz; --yeni: kasa yerine dosya (prova)
//  node arac/smmm-konum-gocu.js --sinav | --mutasyon
//  28.10 (Cem "SGS'de aynı konu art arda gelmesin" → motor/sgs-ders-sira.js): --kod sgs ile AYNI göç kaydir/sgs/* için
//    (paket_soru.sinav=sgs). Varsayılan smmm (eski çağrılar aynen). Bir koşu tek sınavın sayfalarına dokunur.
// ============================================================================
'use strict';
const fs = require('fs');
const SB = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/';
const MUT = process.env.GOC_MUTASYON || '';
const KOD = (() => { const a = process.argv, i = a.indexOf('--kod'); const k = i >= 0 ? a[i + 1] : 'smmm'; if (!/^(smmm|sgs)$/.test(k)) throw new Error('--kod smmm|sgs'); return k; })();
const SAYFA = new RegExp('^kaydir/' + KOD + '/[a-z0-9-]+\\.html$');

function basliklar() {
  const K = process.env.SUPABASE_SERVICE_KEY; if (!K) throw new Error('SUPABASE_SERVICE_KEY yok');
  return { apikey: K, Authorization: 'Bearer ' + K, 'User-Agent': 'tetikte-konum-gocu/1.0', 'Content-Type': 'application/json' };
}
async function siraOku() {
  const h = basliklar(), s = {};
  for (let i = 0; ; i += 1000) {
    const r = await fetch(SB + 'paket_soru?select=id,sayfa,sira&sinav=eq.' + KOD + '&order=sayfa.asc,sira.asc,id.asc&limit=1000&offset=' + i, { headers: h });
    if (!r.ok) throw new Error('paket_soru HTTP ' + r.status);
    const p = await r.json(); p.forEach(x => { (s[x.sayfa] = s[x.sayfa] || []).push(x.id); }); if (p.length < 1000) break;
  }
  return s;
}

// SAF: bir hesabın verisi + eski/yeni sıra → {veri (yeni nesne), degisen, ...sayaçlar}
function cevir(veri, eski, yeni, simdi) {
  const v = JSON.parse(JSON.stringify(veri || {})), say = { kayit: 0, cevrilen: 0, ayni: 0, kayip: 0, kimlikli: 0 };
  const yeniKonum = {}; for (const y in yeni) { yeniKonum[y] = {}; yeni[y].forEach((id, i) => { yeniKonum[y][id] = i; }); }
  function bir(k, yol) {
    if (!k || !SAYFA.test(yol) || typeof k.i !== 'number') return null;
    say.kayit++;
    let id = MUT === 'kimlik-yok' ? null : (k.q || (eski[yol] || [])[k.i]);
    if (k.q) say.kimlikli++;
    if (!id || !(yol in yeniKonum) || !(id in yeniKonum[yol])) { say.kayip++; return null; }
    const ni = yeniKonum[yol][id];
    if (ni === k.i && k.q === id) { say.ayni++; return null; }
    if (ni === k.i) { say.ayni++; return null; }   // sıra değişmedi: dokunma
    say.cevrilen++;
    return Object.assign({}, k, { i: ni, q: id, t: simdi });
  }
  let degisen = false;
  for (const yol of Object.keys(v.konum || {})) { const n = bir(v.konum[yol], yol); if (n) { v.konum[yol] = n; degisen = true; } }
  if (v.son && v.son.yol) {
    // son, konum[son.yol] ile aynı anda yazılır; konum çevrildiyse son da aynı karta
    const k = v.konum && v.konum[v.son.yol];
    if (k && k.t === simdi) { v.son = Object.assign({}, v.son, { i: k.i, q: k.q, t: simdi }); degisen = true; }
  }
  return Object.assign({ veri: v, degisen }, say);
}

async function goc(eskiDosya, yeniDosya, yaz) {
  const eski = JSON.parse(fs.readFileSync(eskiDosya, 'utf8')).sayfalar;
  const yeni = yeniDosya ? JSON.parse(fs.readFileSync(yeniDosya, 'utf8')).sayfalar : await siraOku();
  let sayfaFark = 0; for (const y in yeni) if (JSON.stringify(eski[y] || []) !== JSON.stringify(yeni[y])) sayfaFark++;
  const h = basliklar(), simdi = Date.now(), T = { hesap: 0, kayit: 0, cevrilen: 0, ayni: 0, kayip: 0, kimlikli: 0, yazilan: 0, atlanan: 0, satir: 0 };
  for (let i = 0; ; i += 500) {
    const r = await fetch(SB + 'ogrenci_ilerleme?select=user_id,veri,degisim&order=user_id.asc&limit=500&offset=' + i, { headers: h });
    if (!r.ok) throw new Error('ogrenci_ilerleme HTTP ' + r.status);
    const p = await r.json(); T.satir += p.length;
    for (const x of p) {
      const c = cevir(x.veri, eski, yeni, simdi);
      if (c.kayit) T.hesap++;
      ['kayit', 'cevrilen', 'ayni', 'kayip', 'kimlikli'].forEach(k => { T[k] += c[k]; });
      if (!c.degisen || !yaz) continue;
      // KOŞULLU yazım: arada cihaz eşitlediyse (degisim değişti) satır atlanır
      const f = 'user_id=eq.' + encodeURIComponent(x.user_id) + (x.degisim == null ? '&degisim=is.null' : '&degisim=eq.' + encodeURIComponent(x.degisim));
      const w = await fetch(SB + 'ogrenci_ilerleme?' + f, { method: 'PATCH', headers: Object.assign({ Prefer: 'return=representation' }, h),
        body: JSON.stringify({ veri: c.veri, degisim: simdi, guncelleme: new Date().toISOString() }) });
      if (!w.ok) throw new Error('yazım HTTP ' + w.status);
      if ((await w.json()).length) T.yazilan++; else T.atlanan++;
    }
    if (p.length < 500) break;
  }
  console.log(`KONUM GÖÇÜ (${KOD}) · ${yaz ? 'YAZ' : 'KURU'} · sırası değişen sayfa ${sayfaFark}/${Object.keys(yeni).length} · ilerleme satırı ${T.satir} · ${KOD} konumlu hesap ${T.hesap}`);
  console.log(`  ${KOD} konum kaydı ${T.kayit} · çevrilen ${T.cevrilen} · sırası aynı ${T.ayni} · kimliği bulunamayan ${T.kayip} · zaten kimlikli ${T.kimlikli}` + (yaz ? ` · yazılan hesap ${T.yazilan} · arada değiştiği için atlanan ${T.atlanan}` : ''));
  return T;
}

function sinav() {
  let hata = 0; const t = (ad, k) => { console.log((k ? '  geçti: ' : '  DÜŞTÜ: ') + ad); if (!k) hata++; };
  const Y = 'kaydir/smmm/vergi.html', eski = { [Y]: ['a', 'b', 'c', 'd', 'e'] }, yeni = { [Y]: ['d', 'e', 'a', 'b', 'c'] };
  if (KOD === 'smmm') {
  const v = { surum: 1, konum: { [Y]: { i: 3, t: 5 }, 'kaydir/sgs/turkce.html': { i: 2, t: 5 } }, son: { yol: Y, i: 3, t: 5 }, cevap: { x: { s: 'ok' } } };
  const c = cevir(v, eski, yeni, 99);
  t('eski i=3 (d) → yeni i=0, kimlik yazılır', c.veri.konum[Y].i === 0 && c.veri.konum[Y].q === 'd' && c.veri.konum[Y].t === 99);
  t('son da aynı karta çevrilir', c.veri.son.i === 0 && c.veri.son.q === 'd');
  t('SGS konumuna dokunulmaz', c.veri.konum['kaydir/sgs/turkce.html'].i === 2 && c.veri.konum['kaydir/sgs/turkce.html'].t === 5);
  t('cevap kayıtları aynen', JSON.stringify(c.veri.cevap) === JSON.stringify(v.cevap));
  t('girdi değişmez (saf)', v.konum[Y].i === 3);
  t('kimlikli kayıt (q) i yerine kimlikten çevrilir', cevir({ konum: { [Y]: { i: 0, q: 'c', t: 1 } } }, eski, yeni, 9).veri.konum[Y].i === 4);
  t('sıra değişmediyse dokunulmaz', cevir({ konum: { [Y]: { i: 1, t: 1 } } }, eski, eski, 9).degisen === false);
  const k = cevir({ konum: { [Y]: { i: 9, t: 1 } } }, eski, yeni, 9);
  t('eski sırada olmayan i: kayıt kalır, kayıp sayılır', k.degisen === false && k.kayip === 1);
  const k2 = cevir({ konum: { [Y]: { i: 1, t: 1 } } }, eski, { [Y]: ['a', 'c'] }, 9);
  t('kasadan çıkan soru: kayıt kalır, kayıp sayılır', k2.degisen === false && k2.kayip === 1);
  t('konumsuz eski hesap bozulmaz', cevir({ surum: 1 }, eski, yeni, 9).degisen === false);
  }
  // 28.10 --kod sgs: SGS koşusu SGS konumunu çevirir, bitirmeye dokunmaz (aynı saf işlev, desen KOD'dan)
  if (KOD === 'sgs') {
    const S = 'kaydir/sgs/turkce.html', es = { [S]: ['a', 'b', 'c'] }, ys = { [S]: ['c', 'a', 'b'] };
    const cs = cevir({ konum: { [S]: { i: 2, t: 1 }, [Y]: { i: 3, t: 1 } } }, es, ys, 7);
    t('--kod sgs: SGS konumu çevrilir (c: 2 → 0)', cs.veri.konum[S].i === 0 && cs.veri.konum[S].q === 'c');
    t('--kod sgs: bitirme konumuna dokunulmaz', cs.veri.konum[Y].i === 3 && cs.veri.konum[Y].t === 1);
    const ck = cevir({ konum: { [S]: { i: 0, q: 'b', t: 1 } } }, es, ys, 7);
    t('--kod sgs: kimlikli kayıt kimlikten çevrilir (b → 2)', ck.veri.konum[S].i === 2);
    const cm = MUT === 'kimlik-yok' ? cevir({ konum: { [S]: { i: 2, t: 1 } } }, es, ys, 7) : cs;
    t('--kod sgs: eski i kimliğe çözülür', cm.veri.konum[S].i === 0);
  }
  console.log(hata ? `ÖZ-SINAV DÜŞTÜ (${hata})` : 'ÖZ-SINAV GEÇTİ'); return hata;
}

if (require.main === module) {
  const a = process.argv.slice(2), d = f => a[a.indexOf(f) + 1];
  (async () => {
    if (a.includes('--mutasyon')) {
      const { spawnSync } = require('child_process');
      const r = spawnSync(process.execPath, [__filename, '--sinav', '--kod', KOD], { env: Object.assign({}, process.env, { GOC_MUTASYON: 'kimlik-yok' }), encoding: 'utf8' });
      console.log(`  mutasyon kimlik-yok  ${r.status ? 'KIRMIZI (doğru)' : 'YEŞİL — SINAV KÖR'}\nMUTASYON: ${r.status ? 1 : 0}/1 → KIRMIZI`); process.exitCode = r.status ? 0 : 1;
    } else if (a.includes('--sinav')) process.exitCode = sinav() ? 1 : 0;
    else if (a.includes('--yedekle')) {
      const s = await siraOku(); fs.writeFileSync(d('--yedekle'), JSON.stringify({ alindi: new Date().toISOString(), sayfalar: s }));
      console.log(`ESKİ SIRA YEDEĞİ: ${Object.keys(s).length} sayfa · ${Object.values(s).reduce((t, l) => t + l.length, 0)} soru`);
    } else if (a.includes('--goc')) await goc(d('--goc'), a.includes('--yeni') ? d('--yeni') : null, a.includes('--yaz'));
    else { console.log('kullanım: --yedekle <dosya> | --goc <eski> [--yeni <dosya>] [--yaz] | --sinav | --mutasyon'); process.exitCode = 1; }
  })().catch(e => { console.log('KONUM GÖÇÜ DÜŞTÜ: ' + e.message); process.exitCode = 1; });
}
module.exports = { cevir };
