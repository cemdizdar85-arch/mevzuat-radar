#!/usr/bin/env node
/* Nöbetçi çizerek çözüyor — seslendirme (21.10.2026). Metin pazarlama/reklam/instagram-nobetci-cizerek-cozuyor.md "## Seslendirme"
   (s0…s8). Ses kimliği KİLİTLİ: Nöbetçi 06. Bedel: ElevenLabs aboneliği (ek para yok). Her klip klip-denetim.js'ten geçer;
   KIRMIZI → exit 2. Süreler <cikti>/sureler.json'a yazılır (kayit.js zamanlaması buradan kurulur).
   Kullanım: node arac/video/cizerek/ses.js [--alis 1]
   🚫 GÖRMEZ: tonlama (kulakla) · whisper'ın kaçırdığı telaffuz. */
'use strict';
const fs = require('fs'), path = require('path'), { execFileSync } = require('child_process');
const KOK = path.resolve(__dirname, '..', '..', '..');
const arg = n => { const i = process.argv.indexOf(n); return i > -1 ? process.argv[i + 1] : null; };
const ALIS = arg('--alis') || '1';
const KASA = 'C:/Users/cemdi/OneDrive/Masaüstü/mevzuat işi/_yerel-veri-kasasi';
const CIKTI = path.join(KASA, 'nobetci-cizerek');
const FF = 'C:/Users/cemdi/AppData/Local/Microsoft/WinGet/Packages/Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe/ffmpeg-9.0-full_build/bin/ffmpeg.exe';
const ANAHTAR = fs.readFileSync(path.join(KASA, 'elevenlabs.key'), 'utf8').trim();
const NOBETCI = 'z2ObNnp0E5ZGeTlSXkX0';
const md = fs.readFileSync(path.join(KOK, 'pazarlama', 'reklam', 'instagram-nobetci-cizerek-cozuyor.md'), 'utf8').replace(/<!--[\s\S]*?-->\r?\n?/g, '');
const m = /## Seslendirme\r?\n([\s\S]*?)(?=\r?\n## )/.exec(md);
const klipler = m ? [...m[1].matchAll(/^(s\d): (.+)$/gm)].map(x => ({ ad: x[1], metin: x[2].trim() })) : [];
if (klipler.length !== 9) { console.error('9 klip bekleniyordu: ' + klipler.length); process.exit(3); }
function sure(dosya) {
  const o = (() => { try { return execFileSync(FF, ['-hide_banner', '-i', dosya], { stdio: ['ignore', 'pipe', 'pipe'] }).toString(); } catch (e) { return String(e.stderr); } })();
  const d = /Duration: (\d+):(\d+):([\d.]+)/.exec(o); return d ? (+d[1]) * 3600 + (+d[2]) * 60 + (+d[3]) : 0;
}
(async () => {
  fs.mkdirSync(CIKTI, { recursive: true });
  let kirmizi = 0; const sureler = {};
  for (const k of klipler) {
    const mp3 = path.join(CIKTI, `ses-${k.ad}-alis${ALIS}.mp3`);
    if (!fs.existsSync(mp3)) {
      const r = await fetch(`https://api.elevenlabs.io/v1/text-to-speech/${NOBETCI}?output_format=mp3_44100_128`, {
        method: 'POST', headers: { 'xi-api-key': ANAHTAR, 'Content-Type': 'application/json', 'Accept': 'audio/mpeg' },
        body: JSON.stringify({ text: k.metin, model_id: 'eleven_v3', language_code: 'tr', settings: { stability: 0.5, use_speaker_boost: true } }) });
      if (!r.ok) { console.error(`${k.ad}: ElevenLabs ${r.status} ${(await r.text()).slice(0, 200)}`); process.exit(1); }
      fs.writeFileSync(mp3, Buffer.from(await r.arrayBuffer()));
    }
    const sahne = path.join(CIKTI, `ses-${k.ad}.json`);
    fs.writeFileSync(sahne, JSON.stringify({ not: 'nobetci cizerek', beklenen_replikler: [k.metin] }));
    let kod = 0; let cikti = '';
    try { cikti = execFileSync('node', [path.join(KOK, 'arac', 'video', 'klip-denetim.js'), mp3, sahne], { stdio: ['ignore', 'pipe', 'pipe'] }).toString(); }
    catch (e) { kod = e.status; cikti = String(e.stdout || ''); }
    const durum = { 0: 'YEŞİL', 1: 'SARI', 2: 'KIRMIZI' }[kod] || 'ÇALIŞMADI';
    sureler[k.ad] = sure(mp3);
    const dokum = (/ada dokumu: (.*)/.exec(cikti) || [])[1] || '';
    console.log(`${k.ad} ${durum} ${sureler[k.ad].toFixed(2)} sn | ${dokum}`);
    if (durum === 'KIRMIZI' || durum === 'ÇALIŞMADI') kirmizi++;
  }
  fs.writeFileSync(path.join(CIKTI, `sureler-alis${ALIS}.json`), JSON.stringify(sureler, null, 1));
  if (kirmizi) { console.error(`${kirmizi} klip kullanılamaz → --alis ${+ALIS + 1}`); process.exit(2); }
})().catch(e => { console.error(e); process.exit(1); });
