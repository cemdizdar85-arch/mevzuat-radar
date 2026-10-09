#!/usr/bin/env node
/* ============================================================================
 *  TELEGRAM KANALI — Tetikte Sınav Nöbeti (t.me/tetiktecom) gönderim aracı (09.10.2026, Cem "telegram nasıl bağlarım")
 *  Bot: @Tetikte_sinav_bot (kanalda yönetici, ölçüldü 09.10). Kanal kimliği -1003870418044.
 *  Anahtar DEPOYA GİRMEZ: ortam TELEGRAM_BOT_TOKEN ya da _yerel-veri-kasasi/telegram-bot.key (depo public).
 *  Kullanım:
 *    node arac/telegram-kanal.js metin "Mesaj"                       -> düz metin (HTML: <b>, <a href>)
 *    node arac/telegram-kanal.js foto <dosya.png|jpg> "Açıklama"     -> fotoğraf + açıklama (≤1024 kr)
 *    node arac/telegram-kanal.js video <dosya.mp4> "Açıklama"        -> video + açıklama
 *    node arac/telegram-kanal.js --kuru ...                           -> göndermez, ne gideceğini yazar
 *  Kural: her gönderi Cem onayıyla (herkese açık yayın). Reklam metni kapısı: pazarlama/reklam/*.md'den kopyalanan metin.
 *  🚫 GÖRMEZ: gönderinin kanalda nasıl göründüğü (önizleme yok) · Telegram'ın 50 MB video sınırı (hata döner).
 * ==========================================================================*/
'use strict';
const fs = require('fs'), path = require('path');
const KOK = path.join(__dirname, '..');
const KANAL = process.env.TELEGRAM_KANAL || '-1003870418044';
const KURU = process.argv.includes('--kuru');
const argv = process.argv.slice(2).filter(a => a !== '--kuru');
const [mod, a1, a2] = argv;
function anahtar() {
  if (process.env.TELEGRAM_BOT_TOKEN) return process.env.TELEGRAM_BOT_TOKEN.trim();
  const k = path.join(KOK, '..', '_yerel-veri-kasasi', 'telegram-bot.key');
  if (fs.existsSync(k)) return fs.readFileSync(k, 'utf8').trim();
  console.error('KIRMIZI: bot anahtarı yok (TELEGRAM_BOT_TOKEN ya da kasa telegram-bot.key)'); process.exit(2);
}
async function gonder(yol, govde) {
  const r = await fetch(`https://api.telegram.org/bot${anahtar()}/${yol}`, { method: 'POST', body: govde });
  const j = await r.json();
  if (!j.ok) { console.error('KIRMIZI:', j.description); process.exit(3); }
  return j.result;
}
(async () => {
  if (!['metin', 'foto', 'video'].includes(mod)) { console.error('kullanım: metin "..." | foto <dosya> "..." | video <dosya> "..."'); process.exit(2); }
  const metin = mod === 'metin' ? a1 : a2;
  if (!metin) { console.error('KIRMIZI: metin boş'); process.exit(2); }
  if (mod !== 'metin' && !fs.existsSync(a1)) { console.error('KIRMIZI: dosya yok ' + a1); process.exit(2); }
  if (mod !== 'metin' && metin.length > 1024) { console.error('KIRMIZI: açıklama 1024 karakteri aşıyor (' + metin.length + ')'); process.exit(2); }
  if (KURU) { console.log(`KURU: ${mod} -> ${KANAL}${mod !== 'metin' ? ' dosya=' + path.basename(a1) + ' (' + Math.round(fs.statSync(a1).size / 1024) + ' KB)' : ''}\n---\n${metin}`); return; }
  let sonuc;
  if (mod === 'metin') { const f = new FormData(); f.set('chat_id', KANAL); f.set('text', metin); f.set('parse_mode', 'HTML'); f.set('disable_web_page_preview', 'false'); sonuc = await gonder('sendMessage', f); }
  else { const f = new FormData(); f.set('chat_id', KANAL); f.set('caption', metin); f.set('parse_mode', 'HTML');
    f.set(mod === 'foto' ? 'photo' : 'video', new Blob([fs.readFileSync(a1)]), path.basename(a1));
    if (mod === 'video') f.set('supports_streaming', 'true');
    sonuc = await gonder(mod === 'foto' ? 'sendPhoto' : 'sendVideo', f); }
  console.log(`GÖNDERİLDİ: mesaj ${sonuc.message_id} · t.me/tetiktecom/${sonuc.message_id}`);
})();
