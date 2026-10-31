/* mobil/prova-oturum.js — YALNIZ iOS PROVASI: paketli bir hesap için tek seferlik oturum üretir (30.10.2026, Cem
 * "benim iPhone yok, sen şimdiden ölç": siteden alınan paket iPhone'da açılıyor mu, simülatörde girişli ölçülsün).
 *
 * Nasıl: servis anahtarıyla admin generate_link (magiclink; E-POSTA GİTMEZ) → /auth/v1/verify (token_hash) → oturum.
 * Şifre kullanılmaz, hesap AÇILMAZ (hesap yoksa durur). Oturum dosyaya yazılır (RUNNER_TEMP), ekrana BASILMAZ;
 * access/refresh jetonları GitHub'a "::add-mask::" ile bildirilir (depo public, günlük herkese açık).
 * Prova bitince cihaz-akis-ios.js oturumu YEREL kapsamda kapatır (hesabın başka cihazlarındaki oturumlara dokunmaz).
 *
 * ⚠ CİHAZ KAPISI (cihaz-kapisi.js: tek aktif ekran + en fazla 3 cihaz): simülatör hesaba YENİ CİHAZ olarak yazılır ve
 *   aktif ekranı devralır. 30.10 ilk koşuda iki simülatör aynı anda girdi → Cem'in hesabında 3. yer doldu, iOS 26
 *   "cihaz sınırı" perdesine düştü, aktif ekran simülatöre geçti (elle geri alındı). Bu yüzden: oturum açılırken önceki
 *   aktif ekran + başlangıç zamanı <cikti>.iz.json'a yazılır; prova bitince `--temizle <iz>` simülatörün cihaz/olay
 *   kayıtlarını siler ve aktif ekranı geri verir. İş akışı girişli aşamayı TEK simülatörde (iOS 26) koşar.
 *
 * Kullanım: SUPABASE_SERVICE_KEY=… node mobil/prova-oturum.js <eposta> <cikti.json>
 *           SUPABASE_SERVICE_KEY=… node mobil/prova-oturum.js --temizle <cikti.json.iz.json>
 * GÖRMEZ: Google/Apple ile giriş yolu (oturum doğrudan kurulur); giriş formunun kendisi.
 */
const fs = require('fs'), path = require('path');
const [, , eposta, cikti] = process.argv;
const SERVIS = String(process.env.SUPABASE_SERVICE_KEY || '').trim();
if (!eposta || !cikti) { console.log('kullanım: prova-oturum.js <eposta> <cikti.json> | --temizle <iz.json>'); process.exit(2); }
if (!SERVIS) { console.log('SUPABASE_SERVICE_KEY yok'); process.exit(2); }
const ortak = fs.readFileSync(path.join(__dirname, 'uygulama', 'ortak.js'), 'utf8');
const SB_URL = (ortak.match(/SB_URL\s*=\s*'([^']+)'/) || [])[1], ANON = (ortak.match(/SB_KEY\s*=\s*'([^']+)'/) || [])[1];
if (!SB_URL || !ANON) { console.log('ortak.js SB_URL/SB_KEY okunamadı'); process.exit(2); }
const UA = { 'User-Agent': 'tetikte-bakim/1.0', 'Content-Type': 'application/json' };
const SV = { ...UA, apikey: SERVIS, Authorization: 'Bearer ' + SERVIS };
const rest = async (yol, s = {}) => { const r = await fetch(SB_URL + '/rest/v1/' + yol, { ...s, headers: { ...SV, Prefer: 'return=representation', ...(s.headers || {}) } }); return { ok: r.ok, durum: r.status, j: await r.json().catch(() => null) }; };

if (eposta === '--temizle') {
  (async () => {
    const iz = JSON.parse(fs.readFileSync(cikti, 'utf8'));
    const u = encodeURIComponent(iz.user_id), t = encodeURIComponent(iz.baslangic);
    const yeni = (await rest(`uye_cihazlar?user_id=eq.${u}&ilk_gorulme=gte.${t}&select=cihaz_id`)).j || [];
    const ids = yeni.map((x) => x.cihaz_id);
    if (iz.ekran) await rest(`uye_ekran?user_id=eq.${u}`, { method: 'PATCH', body: JSON.stringify({ cihaz_id: iz.ekran.cihaz_id, devralma: iz.ekran.devralma }) });
    else if (ids.length) await rest(`uye_ekran?user_id=eq.${u}&cihaz_id=in.(${ids.join(',')})`, { method: 'DELETE' });
    const c = ids.length ? (await rest(`uye_cihazlar?user_id=eq.${u}&cihaz_id=in.(${ids.join(',')})`, { method: 'DELETE' })).j || [] : [];
    const o = (await rest(`uye_cihaz_olay?user_id=eq.${u}&zaman=gte.${t}`, { method: 'DELETE' })).j || [];
    console.log('temizlik: simülatör cihazı ' + c.length + ' · olay ' + o.length + ' · aktif ekran ' + (iz.ekran ? 'önceki cihaza geri verildi' : 'yoktu, kaldırıldı'));
    try { fs.unlinkSync(cikti); } catch (e) { }
  })().catch((e) => { console.log('TEMIZLIK HATASI ' + String(e && e.message || e).slice(0, 200)); process.exit(1); });
} else (async () => {
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
  const ekran = ((await rest(`uye_ekran?user_id=eq.${encodeURIComponent(o.user.id)}&select=cihaz_id,devralma`)).j || [])[0] || null;
  fs.writeFileSync(cikti + '.iz.json', JSON.stringify({ user_id: o.user.id, baslangic: new Date(Date.now() - 5000).toISOString(), ekran }));
  fs.writeFileSync(cikti, JSON.stringify(o), { mode: 0o600 });
  console.log('oturum hazır · kullanıcı ' + String(o.user && o.user.id || '').slice(0, 8) + '… · bitiş ' + new Date((o.expires_at || 0) * 1000).toISOString());
})().catch((e) => { console.log('HATA ' + String(e && e.message || e).slice(0, 200)); process.exit(1); });
