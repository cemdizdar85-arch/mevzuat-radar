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
 *  Modül (09.10, Sınav Nöbeti robotu için): require(...) → { anahtarVar, metinGonder, fotoGonder, KANAL }
 *    metinGonder(metin) / fotoGonder(dosya, metin) → { message_id } ; anahtar yoksa Error fırlatır (robot "KÖR" yazar, düşmez).
 *  Kural: her gönderi Cem onayıyla (herkese açık yayın). Reklam metni kapısı: pazarlama/reklam/*.md'den kopyalanan metin.
 *    Tek istisna: motor/sinav-nobeti.js'in resmî duyuru haberi (kalıp sabit, öz-sınavlı; Cem 09.10 robotla gönderimi istedi).
 *  🚫 GÖRMEZ: gönderinin kanalda nasıl göründüğü (önizleme yok) · Telegram'ın 50 MB video sınırı (hata döner).
 * ==========================================================================*/
'use strict';
const fs = require('fs'), path = require('path');
const KOK = path.join(__dirname, '..');
const KANAL = process.env.TELEGRAM_KANAL || '-1003870418044';
function anahtarYolu() { return path.join(KOK, '..', '_yerel-veri-kasasi', 'telegram-bot.key'); }
function anahtarVar() { return !!(process.env.TELEGRAM_BOT_TOKEN || fs.existsSync(anahtarYolu())); }
function anahtar() {
  if (process.env.TELEGRAM_BOT_TOKEN) return process.env.TELEGRAM_BOT_TOKEN.trim();
  if (fs.existsSync(anahtarYolu())) return fs.readFileSync(anahtarYolu(), 'utf8').trim();
  throw new Error('bot anahtarı yok (TELEGRAM_BOT_TOKEN ya da kasa telegram-bot.key)');
}
async function gonder(yol, govde) {
  const r = await fetch(`https://api.telegram.org/bot${anahtar()}/${yol}`, { method: 'POST', body: govde });
  const j = await r.json();
  if (!j.ok) throw new Error('Telegram: ' + j.description);
  return j.result;
}
async function metinGonder(metin) {
  const f = new FormData(); f.set('chat_id', KANAL); f.set('text', metin); f.set('parse_mode', 'HTML'); f.set('disable_web_page_preview', 'false');
  return gonder('sendMessage', f);
}
async function dosyaGonder(mod, dosya, metin) {
  if (metin.length > 1024) throw new Error('açıklama 1024 karakteri aşıyor (' + metin.length + ')');
  const f = new FormData(); f.set('chat_id', KANAL); f.set('caption', metin); f.set('parse_mode', 'HTML');
  f.set(mod === 'foto' ? 'photo' : 'video', new Blob([fs.readFileSync(dosya)]), path.basename(dosya));
  if (mod === 'video') f.set('supports_streaming', 'true');
  return gonder(mod === 'foto' ? 'sendPhoto' : 'sendVideo', f);
}
const fotoGonder = (dosya, metin) => dosyaGonder('foto', dosya, metin);
module.exports = { KANAL, anahtarVar, metinGonder, fotoGonder };

if (require.main === module) (async () => {
  const KURU = process.argv.includes('--kuru');
  const argv = process.argv.slice(2).filter(a => a !== '--kuru');
  const [mod, a1, a2] = argv;
  if (!['metin', 'foto', 'video'].includes(mod)) { console.error('kullanım: metin "..." | foto <dosya> "..." | video <dosya> "..."'); process.exit(2); }
  const metin = mod === 'metin' ? a1 : a2;
  if (!metin) { console.error('KIRMIZI: metin boş'); process.exit(2); }
  if (mod !== 'metin' && !fs.existsSync(a1)) { console.error('KIRMIZI: dosya yok ' + a1); process.exit(2); }
  if (mod !== 'metin' && metin.length > 1024) { console.error('KIRMIZI: açıklama 1024 karakteri aşıyor (' + metin.length + ')'); process.exit(2); }
  if (KURU) { console.log(`KURU: ${mod} -> ${KANAL}${mod !== 'metin' ? ' dosya=' + path.basename(a1) + ' (' + Math.round(fs.statSync(a1).size / 1024) + ' KB)' : ''}\n---\n${metin}`); return; }
  if (!anahtarVar()) { console.error('KIRMIZI: bot anahtarı yok (TELEGRAM_BOT_TOKEN ya da kasa telegram-bot.key)'); process.exit(2); }
  try {
    const sonuc = mod === 'metin' ? await metinGonder(metin) : await dosyaGonder(mod, a1, metin);
    console.log(`GÖNDERİLDİ: mesaj ${sonuc.message_id} · t.me/tetiktecom/${sonuc.message_id}`);
  } catch (e) { console.error('KIRMIZI: ' + e.message); process.exit(3); }
})();
