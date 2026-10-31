#!/usr/bin/env node
/* MEYDAN OKUMA seslendirmesi — 21.10.2026. Metin pazarlama/reklam/meta-meydan-okuma-sayac.md "## Seslendirme · Yeterlilik"
   bölümünden (v1, v2, v3, marka). Ses kimliği KİLİTLİ: anlatıcı Nöbetçi 06, marka 01 (yalnız "Tetikte.").
   Bedel: ElevenLabs aboneliği (ek para yok). Her klip arac/video/klip-denetim.js'ten geçer; KIRMIZI → exit 2, film basılmaz.
   Kullanım: node arac/video/meydan/ses.js [--alis 1] [--cikti <klasör>]   → <cikti>/ses-<ad>-alis<n>.mp3
   🚫 GÖRMEZ: tonlama/vurgu (kulakla dinlenir) · whisper'ın kaçırdığı yanlış telaffuz. */
'use strict';
const fs = require('fs'), path = require('path'), { execFileSync } = require('child_process');
const KOK = path.resolve(__dirname, '..', '..', '..');
const arg = n => { const i = process.argv.indexOf(n); return i > -1 ? process.argv[i + 1] : null; };
const ALIS = arg('--alis') || '1';
const KASA = path.resolve(KOK, '..', '_yerel-veri-kasasi');
const KASA_ANA = 'C:/Users/cemdi/OneDrive/Masaüstü/mevzuat işi/_yerel-veri-kasasi';
const CIKTI = arg('--cikti') || path.join(KASA_ANA, 'meydan-okuma');
const anahtarYol = [path.join(KASA, 'elevenlabs.key'), path.join(KASA_ANA, 'elevenlabs.key')].find(p => fs.existsSync(p));
if (!anahtarYol) { console.error('elevenlabs.key bulunamadı'); process.exit(1); }
const ANAHTAR = fs.readFileSync(anahtarYol, 'utf8').trim();
const SES = { anlatici: 'z2ObNnp0E5ZGeTlSXkX0', marka: 'ZsYcqahfiS2dy4J6XYC5' };

const md = fs.readFileSync(path.join(KOK, 'pazarlama', 'reklam', 'meta-meydan-okuma-sayac.md'), 'utf8').replace(/<!--[\s\S]*?-->\r?\n?/g, '');
const m = /## Seslendirme · Yeterlilik\r?\n([\s\S]*?)(?=\r?\n## |$)/.exec(md);
if (!m) { console.error('"Seslendirme · Yeterlilik" bölümü yok'); process.exit(3); }
const klipler = [...m[1].matchAll(/^(v\d|marka): (.+)$/gm)].map(x => ({ ad: x[1], metin: x[2].trim(), ses: x[1] === 'marka' ? SES.marka : SES.anlatici }));
if (klipler.length !== 3) { console.error('3 klip bekleniyordu: ' + klipler.length); process.exit(3); }

(async () => {
  fs.mkdirSync(CIKTI, { recursive: true });
  let kirmizi = 0;
  for (const k of klipler) {
    const mp3 = path.join(CIKTI, `ses-${k.ad}-alis${ALIS}.mp3`);
    if (!fs.existsSync(mp3)) {
      const r = await fetch(`https://api.elevenlabs.io/v1/text-to-speech/${k.ses}?output_format=mp3_44100_128`, {
        method: 'POST', headers: { 'xi-api-key': ANAHTAR, 'Content-Type': 'application/json', 'Accept': 'audio/mpeg' },
        body: JSON.stringify({ text: k.metin, model_id: 'eleven_v3', language_code: 'tr', settings: { stability: 0.5, use_speaker_boost: true } }) });
      if (!r.ok) { console.error(`${k.ad}: ElevenLabs ${r.status} ${(await r.text()).slice(0, 200)}`); process.exit(1); }
      fs.writeFileSync(mp3, Buffer.from(await r.arrayBuffer()));
      console.log(`indi: ${mp3}`);
    }
    const sahne = path.join(CIKTI, `ses-${k.ad}.json`);
    fs.writeFileSync(sahne, JSON.stringify({ not: 'meydan okuma seslendirmesi', beklenen_replikler: [k.metin] }, null, 1));
    let kod = 0;
    try { execFileSync('node', [path.join(KOK, 'arac', 'video', 'klip-denetim.js'), mp3, sahne], { stdio: 'inherit' }); }
    catch (e) { kod = e.status; }
    const durum = { 0: 'YEŞİL', 1: 'SARI', 2: 'KIRMIZI' }[kod] || 'ÇALIŞMADI';
    console.log(`SES DENETİMİ ${k.ad} = ${durum}`);
    if (durum === 'KIRMIZI' || durum === 'ÇALIŞMADI') kirmizi++;
  }
  if (kirmizi) { console.error(`${kirmizi} klip kullanılamaz → --alis ${+ALIS + 1}`); process.exit(2); }
})().catch(e => { console.error(e); process.exit(1); });
