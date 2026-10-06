#!/usr/bin/env node
/* ============================================================================
 *  VİTRİN HESAP — ana sayfa kahraman kartının soruları (06.10.2026, Cem: "bekçi koyalım ... çok mail geliyor,
 *  otomatikleştiremiyor muyuz").
 *
 *  NE YAPAR: arac/vitrin-hesap-liste.json'daki ELLE OKUNMUŞ kimlikleri kasadan (paket_soru) okur, ana sayfanın
 *  oynatıcısına hazır biçimde veri/vitrin-hesap.json'a yazar. KENDİLİĞİNDEN DÜŞÜRÜR:
 *    · ücretsizden çıkmış soru (06.10 olayı: havuz yayını bir soruyu ücretliye aldı, ana sayfada yarım saat açıkta kaldı)
 *    · vitrin dışlama listesindeki soru (public.vitrin_aciklama_dislanan - kusurlu anlatım)
 *    · anlatımı eksik (doğru açıklaması / en sık yanlışın tuzağı yok) ya da şıkkı uzun (> 40 harf, karta sığmaz) soru
 *  Onarılan sorunun yeni metni kendiliğinden gelir (içerik her koşuda kasadan). Sınavda hiç soru kalmazsa ana sayfa
 *  robotun günün sorusunu oynatır (index.html). MAİL ATMAZ; sabah kontrolü (motor/sabah-kontrol.js) tek satır yazar.
 *  Gösterilen yanlış = sorunun İLK TUZAK şıkkı (üretimde en tipik yanlış). Dayanaktaki iç not ("teori notu") silinir.
 *
 *  ⛔ GÜNLÜK PUBLIC: ekrana yalnız sayı ve kimlik basılır (soru metni yok). Çıktı dosyası public'tir ama yalnız
 *     ücretsiz soruları taşır (ana sayfada zaten gösterilen içerik).
 *  🚫 GÖRMEZ: anlatımın DOĞRULUĞU (elle okuma işi; listeye girerken yapılır) · onarımda anlamı değişen sorunun yeniden
 *     okunması (yeni metin okunmadan yayına girer - onarım hattının kapıları geçerli).
 *
 *  Kullanım: SUPABASE_SERVICE_KEY=... node motor/vitrin-hesap.js [--kuru]
 *            node motor/vitrin-hesap.js --sinav   (ağsız öz-sınav)
 * ==========================================================================*/
'use strict';
const fs = require('fs'), path = require('path');
const KOK = path.join(__dirname, '..');
const SB = 'https://bjrleanjpyujtajmazxn.supabase.co', SK = (process.env.SUPABASE_SERVICE_KEY || '').trim();
const HEDEF = path.join(KOK, 'veri', 'vitrin-hesap.json');
const SIK_EN_UZUN = 40;

const temizDayanak = s => String(s || '').replace(/\s*\(teori notu:[^)]*\)/i, '').replace(/\s*teori notu:.*$/i, '').trim();
const buyukBas = s => { s = String(s || '').trim(); return s ? s.charAt(0).toLocaleUpperCase('tr') + s.slice(1) : s; };

/* tek soru -> kart ya da düşme nedeni (saf işlev, öz-sınavlı) */
function kartKur(satir, disli) {
  if (!satir) return { neden: 'kasada yok' };
  if (satir.ucretsiz !== true) return { neden: 'ücretsiz değil' };
  if (disli) return { neden: 'vitrin dışlama listesinde' };
  const v = satir.veri || {}, sk = v.siklar || {};
  if (!v.soru || Object.keys(sk).length !== 5 || !sk[v.dogru]) return { neden: 'soru/şık eksik' };
  if (Object.values(sk).some(s => String(s).length > SIK_EN_UZUN)) return { neden: 'şık uzun' };
  const sen = Object.keys(v.tuzak || {}).filter(h => h !== v.dogru && sk[h] != null)[0], t = (v.tuzak || {})[sen] || {};
  const aciklama = (v.sade || {}).dogru;
  if (!sen || !t.metin || !aciklama || /^undefined$/i.test(String(aciklama).trim())) return { neden: 'anlatım eksik' };
  return { kart: { id: satir.id, ders: String(satir.ders || '').split('|')[0].trim(), soru: v.soru, siklar: sk, secim: sen, dogru: v.dogru,
    tuzak_ad: t.ad || '', tuzak_metin: t.metin, aciklama,
    // 07.10 'Sen çöz': ziyaretçi hangi yanlışı seçerse onun tuzağı anlatılır
    tuzaklar: Object.fromEntries(Object.entries(v.tuzak || {}).filter(([hf, x]) => hf !== v.dogru && sk[hf] != null && x && x.metin).map(([hf, x]) => [hf, { ad: x.ad || '', metin: x.metin }])), kural: buyukBas(v.kural), dayanak: temizDayanak(v.dayanak) } };
}

async function sb(yol) {
  const r = await fetch(SB + '/rest/v1/' + yol, { headers: { apikey: SK, Authorization: 'Bearer ' + SK } });
  if (!r.ok) throw new Error(yol.split('?')[0] + ' http ' + r.status); return r.json();
}

async function ana() {
  if (!SK) throw new Error('SUPABASE_SERVICE_KEY yok');
  const liste = JSON.parse(fs.readFileSync(path.join(KOK, 'arac', 'vitrin-hesap-liste.json'), 'utf8'));
  const tum = [...(liste.sgs || []), ...(liste.yeterlilik || [])];
  const satirlar = await sb('paket_soru?select=id,ders,ucretsiz,veri&id=in.(' + encodeURIComponent(tum.map(x => '"' + x + '"').join(',')) + ')');
  const disli = new Set((await sb('vitrin_aciklama_dislanan?select=id')).map(x => x.id));
  const cikti = { uretici: 'motor/vitrin-hesap.js', liste: 'arac/vitrin-hesap-liste.json', sinavlar: {}, dusen: [] };
  for (const s of ['sgs', 'yeterlilik']) {
    cikti.sinavlar[s] = [];
    for (const id of liste[s] || []) {
      const k = kartKur(satirlar.find(x => x.id === id), disli.has(id));
      if (k.kart) cikti.sinavlar[s].push(k.kart); else cikti.dusen.push({ sinav: s, id, neden: k.neden });
    }
  }
  const ozet = `VİTRİN HESAP: SGS ${cikti.sinavlar.sgs.length}/${(liste.sgs || []).length} · Yeterlilik ${cikti.sinavlar.yeterlilik.length}/${(liste.yeterlilik || []).length}`
    + (cikti.dusen.length ? ' · düşen: ' + cikti.dusen.map(d => d.id + ' (' + d.neden + ')').join(', ') : '');
  console.log(ozet);
  if (process.argv.includes('--kuru')) return;
  const yeni = JSON.stringify(cikti) + '\n';
  let eski = null; try { eski = fs.readFileSync(HEDEF, 'utf8'); } catch (e) {}
  if (eski === yeni) console.log('  değişiklik yok - dosyaya dokunulmadı');
  else { fs.writeFileSync(HEDEF, yeni); console.log('  yazıldı -> veri/vitrin-hesap.json'); }
}

function sinav() {
  let h = 0; const b = (ad, k) => { console.log((k ? '  geçti  ' : '  DÜŞTÜ  ') + ad); if (!k) h++; };
  const iyi = () => ({ id: 'x', ders: 'Finansal Muhasebe|a', ucretsiz: true, veri: { soru: 'S?', dogru: 'B', siklar: { A: '1', B: '2', C: '3', D: '4', E: '5' },
    tuzak: { A: { ad: 'T', metin: 'm' } }, sade: { dogru: 'neden' }, kural: 'kural', dayanak: 'VUK m.1 (teori notu: iç)' } });
  const k = kartKur(iyi(), false);
  b('sağlam soru karta girer, dayanaktan iç not silinir, kural büyük harfle', k.kart && k.kart.dayanak === 'VUK m.1' && k.kart.kural === 'Kural' && k.kart.secim === 'A');
  b('her yanlış şıkkın tuzağı karta girer, doğru şık girmez', k.kart && k.kart.tuzaklar.A && k.kart.tuzaklar.A.metin === 'm' && !k.kart.tuzaklar.B);
  b('ücretsizden çıkan soru düşer (06.10 olayı)', kartKur({ ...iyi(), ucretsiz: false }, false).neden === 'ücretsiz değil');
  b('vitrin dışlama listesindeki soru düşer', kartKur(iyi(), true).neden === 'vitrin dışlama listesinde');
  b('kasada olmayan soru düşer', kartKur(undefined, false).neden === 'kasada yok');
  const uzun = iyi(); uzun.veri.siklar.C = 'x'.repeat(41); b('uzun şıklı soru düşer (karta sığmaz)', kartKur(uzun, false).neden === 'şık uzun');
  const bos = iyi(); bos.veri.sade.dogru = 'undefined'; b('açıklaması "undefined" olan soru düşer', kartKur(bos, false).neden === 'anlatım eksik');
  const tz = iyi(); tz.veri.tuzak = {}; b('tuzağı olmayan soru düşer', kartKur(tz, false).neden === 'anlatım eksik');
  console.log(`VİTRİN HESAP öz-sınav: ${8 - h}/8`); process.exitCode = h ? 1 : 0;
}

if (require.main === module) { if (process.argv.includes('--sinav')) sinav(); else ana().catch(e => { console.log('VİTRİN HESAP HATA: ' + e.message); process.exitCode = 1; }); }
module.exports = { kartKur };
