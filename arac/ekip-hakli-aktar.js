#!/usr/bin/env node
// ============================================================================
//  EKİP HAKLI İTİRAZ → ELLE RET (10.10.2026, Cem "1.2.3": haklı itiraz doğrudan onarım listesine düşsün)
//  Yönetici panelde (yonetim.html) "Ekibe sor" kaydını "Hatalı (öğrenci haklı)" işaretleyince (ekibe_soru.itiraz_hakli = true)
//  bu betik soruyu veri/sinav/<sinav>-elle-ret.json'a yazar → kasa yayını (arac/smmm-kasa-yayin.ps1, havuz-kur, yayin-bas)
//  soruyu sonraki yayında DIŞARIDA bırakır; onarım hattı (arac/onarim-hatti.js) onarınca kayıt kalkar. Sonra ret_aktarim damgası.
//  Robot: .github/workflows/ekibe-sor-nobeti.yml (önce sayım, aktarılacak yoksa depo çekilmez).
//
//    node arac/ekip-hakli-aktar.js            ambardan oku, listeye yaz (SUPABASE_SERVICE_KEY), damgayı commit SONRASI vurmaz:
//                                             --damga ile ayrı çağrılır (push başarılıysa) → push düşerse sonraki koşu yeniden dener
//    node arac/ekip-hakli-aktar.js --damga    yazılmış kimliklere ret_aktarim (dosya: veri/sinav/.ekip-hakli-bekleyen.json)
//    node arac/ekip-hakli-aktar.js --sinav    öz-sınav (ağ yok) · ONARIM-MUTASYON: EKIP_MUTASYON=onek|ezme|yabanci
//  KURALLAR: listede zaten olan kimliğin gerekçesi EZİLMEZ (elle okumanın gerekçesi daha değerli) · tanınmayan önek (sgs-/smmm-/kgk-
//  dışı) yazılmaz, damgalanmaz, günlüğe sayısı basılır · AÇIK DEPO: öğrenci mesajı/e-postası YAZILMAZ, yalnız kimlik + yöneticinin notu.
//  🚫 GÖRMEZ: yöneticinin yanlış işaretini (o karar insanda) · soru kimliği kasada yoksa (yayında zaten yoksa liste zararsız kalır) ·
//     işaret sonradan "Soru doğru"ya çevrilirse listeden SİLMEZ (elle silinir; onarım hattı da kaldırır).
// ============================================================================
'use strict';
const fs = require('fs'), path = require('path');
const KOK = path.resolve(__dirname, '..');
const MUT = process.env.EKIP_MUTASYON || '';
const BEKLEYEN = path.join(KOK, 'veri', 'sinav', '.ekip-hakli-bekleyen.json');

function sinavBul(soruId) {
  const m = /^(smmm|sgs|kgk)-/.exec(String(soruId || ''));
  if (MUT === 'onek') return 'smmm';
  return m ? m[1] : null;
}
// saf: kayıtlar (elle ret.kayitlar) + itiraz satırı → {yazildi, neden}
function ekle(kayitlar, x, bugun) {
  if (!x || !x.soru_id) return { yazildi: false, neden: 'kimlik yok' };
  if (kayitlar[x.soru_id] && MUT !== 'ezme') return { yazildi: false, neden: 'zaten listede' };
  kayitlar[x.soru_id] = {
    gerekce: `Ekibe sor #${x.id}: öğrenci itirazı yönetici tarafından HAKLI bulundu (soru hatalı).` + (x.itiraz_not ? ' Not: ' + String(x.itiraz_not).slice(0, 300) : '') + (MUT === 'yabanci' ? ' ' + x.mesaj : ''),
    kaynak: `Ekibe sor #${x.id} · yonetim.html işareti`,
    tarih: bugun,
  };
  return { yazildi: true };
}

async function servis(yol, sec) {
  const SK = (process.env.SUPABASE_SERVICE_KEY || '').trim(); if (!SK) throw new Error('SUPABASE_SERVICE_KEY yok');
  const r = await fetch('https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/' + yol, Object.assign({
    headers: { apikey: SK, Authorization: 'Bearer ' + SK, 'Content-Type': 'application/json', 'User-Agent': 'tetikte-arac/1.0' } }, sec || {}));
  if (!r.ok) throw new Error('ambar ' + r.status);
  return r.status === 204 ? null : r.json();
}

async function aktar() {
  const satirlar = await servis('ekibe_soru?select=id,soru_id,itiraz_not&itiraz_hakli=is.true&ret_aktarim=is.null&order=id.asc&limit=50');
  const bugun = new Date().toISOString().slice(0, 10), say = { yazildi: 0, zaten: 0, taninmayan: 0 }, damga = [];
  const dosyalar = {};
  for (const x of satirlar) {
    const s = sinavBul(x.soru_id);
    if (!s) { say.taninmayan++; continue; }
    const p = path.join(KOK, 'veri', 'sinav', s + '-elle-ret.json');
    if (!dosyalar[p]) dosyalar[p] = JSON.parse(fs.readFileSync(p, 'utf8').replace(/^﻿/, ''));
    const k = ekle(dosyalar[p].kayitlar, x, bugun);
    k.yazildi ? say.yazildi++ : say.zaten++;
    damga.push(x.id);
  }
  for (const [p, j] of Object.entries(dosyalar)) fs.writeFileSync(p, JSON.stringify(j, null, 4) + '\n');
  fs.writeFileSync(BEKLEYEN, JSON.stringify(damga) + '\n');
  console.log(`EKIP-HAKLI: aday ${satirlar.length} · listeye yazılan ${say.yazildi} · zaten listede ${say.zaten} · tanınmayan önek ${say.taninmayan}`);
}

async function damgala() {
  if (!fs.existsSync(BEKLEYEN)) { console.log('EKIP-HAKLI: damgalanacak yok'); return; }
  const ids = JSON.parse(fs.readFileSync(BEKLEYEN, 'utf8')).filter(Number.isFinite);
  if (ids.length) await servis(`ekibe_soru?id=in.(${ids.join(',')})&ret_aktarim=is.null`, { method: 'PATCH', body: JSON.stringify({ ret_aktarim: new Date().toISOString() }) });
  fs.unlinkSync(BEKLEYEN);
  console.log('EKIP-HAKLI: damgalanan ' + ids.length);
}

function sinav() {
  let ok = 0, top = 0; const t = (ad, kosul) => { top++; if (kosul) ok++; else console.log('  ✗ ' + ad); };
  t('smmm öneki', sinavBul('smmm-4k-a-yspk-cokzor-r5/kp-03') === 'smmm');
  t('sgs öneki', sinavBul('sgs-c5-fmuh-zor-r1-2/kp-07') === 'sgs');
  t('kgk öneki', sinavBul('kgk-d1-bds-zor/kp-01') === 'kgk');
  t('tanınmayan önek yazılmaz (yanlış alarm değil)', sinavBul('test/uctan-uca') === null);
  const k = { 'smmm-a/kp-01': { gerekce: 'elle okuma', kaynak: 'GM', tarih: '2026-09-23' } };
  t('listedeki gerekçe ezilmez', ekle(k, { id: 3, soru_id: 'smmm-a/kp-01' }, '2026-10-10').yazildi === false && k['smmm-a/kp-01'].gerekce === 'elle okuma');
  const y = ekle(k, { id: 4, soru_id: 'smmm-b/kp-02', itiraz_not: 'II. ifade 1-3 yıl', mesaj: 'öğrenci@ornek.com gizli mesaj' }, '2026-10-10');
  t('yeni kimlik yazılır', y.yazildi && /HAKLI/.test(k['smmm-b/kp-02'].gerekce) && /1-3 yıl/.test(k['smmm-b/kp-02'].gerekce));
  t('öğrenci mesajı açık depoya yazılmaz', !/ornek\.com|gizli mesaj/.test(JSON.stringify(k)));
  t('kimliksiz satır yazılmaz', ekle(k, { id: 5 }, '2026-10-10').yazildi === false);
  console.log(`EKIP-HAKLI SINAVI: ${ok === top ? 'YESIL' : 'KIRMIZI'} — ${ok}/${top}`);
  process.exit(ok === top ? 0 : 1);
}

const arg = process.argv[2];
(arg === '--sinav' ? Promise.resolve(sinav()) : arg === '--damga' ? damgala() : aktar()).catch(e => { console.error('EKIP-HAKLI HATA: ' + e.message); process.exit(1); });
