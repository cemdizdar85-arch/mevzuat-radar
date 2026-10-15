#!/usr/bin/env node
/* ============================================================================
 * PLAY TERFİ — Play'e ZATEN yüklenmiş bir derlemeyi (versionCode) başka kanala koyar (15.10.2026, Cem "sen gönder,
 * üretim incelemesine yolla; yönetilen yayınlama açık, Yayınla'ya ben basarım").
 *
 * Neden yeniden derleme değil: emülatör akış provası (cihaz-akis.js) belirli bir derlemeyi sınadı (44 = 1.8.5,
 * 38787580347). Yeniden derleme ana tele sonradan gelen, SINANMAMIŞ site dosyalarını da içine alır.
 *
 * Akış (Play Developer API v3, servis hesabı MOBIL_PLAY_SERVIS_JSON): edit aç → bütün kanalları oku (yalnız sürüm
 * kodu/durum/ad yazılır) → derleme dahili/kapalı kanalda VAR mı → hedef kanala {versionCodes:[kod], status:completed}
 * → YAZ=1 değilse yalnız :validate (kuru koşu, edit silinir) · YAZ=1 ise :commit.
 * Yönetilen yayınlama açıkken commit = incelemeye gönderim; yayına Cem Play Console'da "Yayınla" ile alır.
 *
 * GÖRMEZ: yönetilen yayınlamanın açık olduğunu (API vermiyor; Cem 15.10 "açık" dedi) · ülke listesini (değiştirmez,
 * kanalın mevcut ülkeleri kalır) · inceleme sonucunu.
 * ========================================================================== */
'use strict';
const crypto = require('crypto');

const PAKET = 'com.tetikte.app';
const KOD = String(process.env.SURUM_KODU || '').trim();
const AD = String(process.env.SURUM_ADI || '').trim();
const KANAL = String(process.env.KANAL || 'production').trim();
const NOT = String(process.env.SURUM_NOTU || '').trim();
const YAZ = process.env.YAZ === '1';
if (!/^\d+$/.test(KOD)) { console.log('SURUM_KODU sayi olmali'); process.exit(1); }

const b64 = (x) => Buffer.from(x).toString('base64url');
async function belirtec() {
  const sa = JSON.parse(process.env.SERVIS_JSON);
  const simdi = Math.floor(Date.now() / 1000);
  const govde = b64(JSON.stringify({ alg: 'RS256', typ: 'JWT' })) + '.' + b64(JSON.stringify({
    iss: sa.client_email, scope: 'https://www.googleapis.com/auth/androidpublisher',
    aud: 'https://oauth2.googleapis.com/token', iat: simdi, exp: simdi + 3000 }));
  const imza = crypto.createSign('RSA-SHA256').update(govde).sign(sa.private_key).toString('base64url');
  const r = await fetch('https://oauth2.googleapis.com/token', { method: 'POST',
    headers: { 'content-type': 'application/x-www-form-urlencoded' },
    body: 'grant_type=' + encodeURIComponent('urn:ietf:params:oauth:grant-type:jwt-bearer') + '&assertion=' + govde + '.' + imza });
  const j = await r.json(); if (!j.access_token) throw new Error('belirtec alinamadi: ' + (j.error || r.status));
  return j.access_token;
}
let TOK;
async function api(yontem, yol, govde) {
  const r = await fetch('https://androidpublisher.googleapis.com/androidpublisher/v3/applications/' + PAKET + yol, {
    method: yontem, headers: { authorization: 'Bearer ' + TOK, 'content-type': 'application/json' },
    body: govde ? JSON.stringify(govde) : undefined });
  const t = await r.text(); let j = {}; try { j = t ? JSON.parse(t) : {}; } catch (e) { }
  if (!r.ok) throw new Error(yontem + ' ' + yol + ' → ' + r.status + ' ' + ((j.error && j.error.message) || t).slice(0, 300));
  return j;
}
const ozet = (k) => (k.releases || []).map((s) => (s.name || '?') + ' [' + (s.versionCodes || []).join(',') + '] ' + s.status).join(' · ') || 'boş';

(async () => {
  TOK = await belirtec();
  const edit = (await api('POST', '/edits')).id;
  let tamam = false;
  try {
    const kanallar = (await api('GET', '/edits/' + edit + '/tracks')).tracks || [];
    for (const k of kanallar) console.log('KANAL ' + k.track + ': ' + ozet(k));
    const var_ = kanallar.some((k) => k.track !== KANAL && (k.releases || []).some((s) => (s.versionCodes || []).includes(KOD)));
    if (!var_) throw new Error('derleme ' + KOD + ' hicbir kanalda yok (once Play\'e yuklenmeli)');
    const surum = { versionCodes: [KOD], status: 'completed' };
    if (AD) surum.name = AD;
    if (NOT) surum.releaseNotes = [{ language: 'tr-TR', text: NOT }];
    const yeni = await api('PUT', '/edits/' + edit + '/tracks/' + KANAL, { track: KANAL, releases: [surum] });
    console.log('HEDEF ' + KANAL + ' (taslak): ' + ozet(yeni));
    if (YAZ) {
      const c = await api('POST', '/edits/' + edit + ':commit');
      console.log('COMMIT TAMAM edit ' + c.id + ' → ' + KANAL + ' derleme ' + KOD + ' incelemeye gonderildi');
      tamam = true;
    } else {
      await api('POST', '/edits/' + edit + ':validate');
      console.log('KURU KOSU: validate GECTI (hicbir sey gonderilmedi)');
    }
  } finally {
    if (!tamam) { try { await api('DELETE', '/edits/' + edit); } catch (e) { } }
  }
})().catch((e) => { console.log('HATA ' + String(e.message || e)); process.exit(1); });
