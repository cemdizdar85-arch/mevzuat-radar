/* mobil/prova-oturum.js — YALNIZ iOS PROVASI: paketli bir hesap için tek seferlik oturum üretir (30.10.2026, Cem
 * "benim iPhone yok, sen şimdiden ölç": siteden alınan paket iPhone'da açılıyor mu, simülatörde girişli ölçülsün).
 *
 * Nasıl: servis anahtarıyla admin generate_link (magiclink; E-POSTA GİTMEZ) → /auth/v1/verify (token_hash) → oturum.
 * Şifre kullanılmaz, hesap AÇILMAZ (hesap yoksa durur). Oturum dosyaya yazılır (RUNNER_TEMP), ekrana BASILMAZ;
 * access/refresh jetonları GitHub'a "::add-mask::" ile bildirilir (depo public, günlük herkese açık).
 * Prova bitince cihaz-akis-ios.js oturumu YEREL kapsamda kapatır (hesabın başka cihazlarındaki oturumlara dokunmaz).
 *
 * Kullanım: SUPABASE_SERVICE_KEY=… node mobil/prova-oturum.js <eposta> <cikti.json>
 * GÖRMEZ: Google/Apple ile giriş yolu (oturum doğrudan kurulur); giriş formunun kendisi.
 */
const fs = require('fs'), path = require('path');
const [, , eposta, cikti] = process.argv;
const SERVIS = String(process.env.SUPABASE_SERVICE_KEY || '').trim();
if (!eposta || !cikti) { console.log('kullanım: prova-oturum.js <eposta> <cikti.json>'); process.exit(2); }
if (!SERVIS) { console.log('SUPABASE_SERVICE_KEY yok'); process.exit(2); }
const ortak = fs.readFileSync(path.join(__dirname, 'uygulama', 'ortak.js'), 'utf8');
const SB_URL = (ortak.match(/SB_URL\s*=\s*'([^']+)'/) || [])[1], ANON = (ortak.match(/SB_KEY\s*=\s*'([^']+)'/) || [])[1];
if (!SB_URL || !ANON) { console.log('ortak.js SB_URL/SB_KEY okunamadı'); process.exit(2); }
const UA = { 'User-Agent': 'tetikte-bakim/1.0', 'Content-Type': 'application/json' };
(async () => {
  const g = await fetch(SB_URL + '/auth/v1/admin/generate_link', { method: 'POST', headers: { ...UA, apikey: SERVIS, Authorization: 'Bearer ' + SERVIS },
    body: JSON.stringify({ type: 'magiclink', email: eposta }) });
  const gj = await g.json().catch(() => ({}));
  const hash = gj.hashed_token || (gj.properties && gj.properties.hashed_token);
  if (!g.ok || !hash) { console.log('bağlantı üretilemedi: ' + g.status); process.exit(1); }
  const v = await fetch(SB_URL + '/auth/v1/verify', { method: 'POST', headers: { ...UA, apikey: ANON }, body: JSON.stringify({ type: 'magiclink', token_hash: hash }) });
  const o = await v.json().catch(() => ({}));
  if (!v.ok || !o.access_token || !o.refresh_token) { console.log('oturum kurulamadı: ' + v.status); process.exit(1); }
  console.log('::add-mask::' + o.access_token);
  console.log('::add-mask::' + o.refresh_token);
  fs.writeFileSync(cikti, JSON.stringify(o), { mode: 0o600 });
  console.log('oturum hazır · kullanıcı ' + String(o.user && o.user.id || '').slice(0, 8) + '… · bitiş ' + new Date((o.expires_at || 0) * 1000).toISOString());
})().catch((e) => { console.log('HATA ' + String(e && e.message || e).slice(0, 200)); process.exit(1); });
