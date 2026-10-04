#!/usr/bin/env node
/* ============================================================================
 *  PAKET HEDİYE (04.10.2026, Cem: "elçilere siteye giriş bedava vereceğiz ... kimlere ful paket bedava verdik
 *  kontrol edebileceğimiz")
 *
 *  Panel yok: Cem "X'e paket ver" der, oturum bu aracı koşar. Kişinin ÖNCE sitede ücretsiz hesap açmış olması gerekir
 *  (e-postayla ya da Google ile) - hesap yoksa araç durur, hesap AÇMAZ.
 *
 *    node arac/paket-hediye.js ver   --eposta kisi@x.com [--paket tam|sgs|yeterlilik-tum] [--bitis 2026-11-28]
 *                                    --neden "elçi ücretsiz erişim" [--elci KOD] [--zorla]
 *    node arac/paket-hediye.js liste                 -> kütükteki bütün hediyeler (aktif / bitmiş / iptal)
 *    node arac/paket-hediye.js geri  --eposta kisi@x.com --neden "..."
 *                                    -> paket SİLİNMEZ: bitiş dün yapılır, kütüğe iptal tarihi düşer
 *
 *  Paket: tam = tüm sınavlar (uye-durumu.js paketSinavlari 'tam' -> SGS + Yeterlilik + KGK). Varsayılan bitiş: son
 *  sınav günü (Yeterlilik 28.11.2026). Kişinin PARAYLA aldığı paketi varsa araç ÜSTÜNE YAZMAZ (--zorla ile bilerek).
 *
 *  ⛔ Kişi verisi: e-posta yalnız kasadaki (Supabase, RLS açık, politika yok) paket_hediye tablosunda durur. Bu araç
 *     YEREL koşar; Actions'a/depoya kişi verisi yazmaz. Servis anahtarı ortam değişkeninden (SUPABASE_SERVICE_KEY).
 *  🚫 GÖRMEZ: kişi hediyeyi aldıktan sonra kendi parasıyla paket alırsa sipariş onayı bu satırı ezer (tek satır/üye).
 * ==========================================================================*/
'use strict';
const SB = 'https://bjrleanjpyujtajmazxn.supabase.co';
const K = process.env.SUPABASE_SERVICE_KEY;
const argv = process.argv.slice(2), komut = argv[0];
const al = (ad, vars) => { const i = argv.indexOf('--' + ad); return i >= 0 ? argv[i + 1] : vars; };
const var_ = ad => argv.includes('--' + ad);
const PAKETLER = ['tam', 'sgs', 'yeterlilik-tum'];
const VARS_BITIS = '2026-11-28';

/* Windows'ta açık fetch bağlantısıyla process.exit Node'u çökertiyor (UV_HANDLE_CLOSING, çıkış 127) -> fırlat, çıkış kodu sonda */
function dur(m) { const e = new Error(m); e.dur = true; throw e; }
if (!K) { console.error('DUR: SUPABASE_SERVICE_KEY yok'); process.exitCode = 2; }
const bas = (ek) => Object.assign({ apikey: K, Authorization: 'Bearer ' + K, 'Content-Type': 'application/json' }, ek || {});
async function istek(yol, sec) {
  const r = await fetch(SB + yol, Object.assign({ headers: bas(sec && sec.ek) }, sec || {}));
  const g = await r.text(); let j = null; try { j = g ? JSON.parse(g) : null; } catch (e) {}
  if (!r.ok) throw new Error(yol.split('?')[0] + ' -> HTTP ' + r.status + ' ' + g.slice(0, 160));
  return j;
}
async function kullaniciBul(eposta) {
  const e = eposta.trim().toLowerCase();
  for (let s = 1; s < 50; s++) {
    const j = await istek('/auth/v1/admin/users?page=' + s + '&per_page=1000');
    const u = (j.users || []).find(x => String(x.email || '').toLowerCase() === e);
    if (u) return u;
    if (!j.users || j.users.length < 1000) return null;
  }
  return null;
}
const bugun = () => new Date().toISOString().slice(0, 10);
const dun = () => new Date(Date.now() - 86400000).toISOString().slice(0, 10);

(async () => {
  if (!K) return;
  if (komut === 'liste') {
    const h = await istek('/rest/v1/paket_hediye?select=eposta,paket,bitis,neden,elci_kodu,tarih,iptal&order=tarih.desc');
    if (!h.length) { console.log('Hediye kütüğü boş.'); return; }
    console.log('Durum    Bitiş       Paket            E-posta                          Neden');
    for (const x of h) {
      const d = x.iptal ? 'İPTAL  ' : (x.bitis < bugun() ? 'BİTTİ  ' : 'AKTİF  ');
      console.log(`${d}  ${x.bitis}  ${x.paket.padEnd(15)}  ${x.eposta.padEnd(32)} ${x.neden || ''}${x.elci_kodu ? ' · elçi ' + x.elci_kodu : ''}`);
    }
    console.log(`\nToplam ${h.length} · aktif ${h.filter(x => !x.iptal && x.bitis >= bugun()).length}`);
    return;
  }
  const eposta = al('eposta'); if (!eposta || !/^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(eposta)) dur('--eposta gerekli');
  const neden = al('neden'); if (!neden) dur('--neden gerekli (kütükte durur: "elçi ücretsiz erişim" gibi)');
  const u = await kullaniciBul(eposta);
  if (!u) dur(eposta + ' ile açılmış hesap yok. Kişi önce tetikte.com/ogrenci.html adresinden ücretsiz hesap açmalı (Google ya da e-posta).');
  const mevcut = (await istek('/rest/v1/paket_uyeler?select=paket,bitis&user_id=eq.' + u.id))[0];

  if (komut === 'ver') {
    const paket = al('paket', 'tam'); if (!PAKETLER.includes(paket)) dur('--paket ' + PAKETLER.join(' | '));
    const bitis = al('bitis', VARS_BITIS); if (!/^\d{4}-\d{2}-\d{2}$/.test(bitis) || bitis <= bugun()) dur('--bitis YYYY-AA-GG, bugünden sonra');
    const elci = al('elci') ? String(al('elci')).toUpperCase() : null;
    if (mevcut && mevcut.bitis >= bugun() && !var_('zorla')) dur(`bu hesabın zaten aktif paketi var (${mevcut.paket}, ${mevcut.bitis} bitiş). Parayla alınmış olabilir; üstüne yazmak için --zorla.`);
    const satir = { user_id: u.id, paket, bitis };
    if (mevcut) await istek('/rest/v1/paket_uyeler?user_id=eq.' + u.id, { method: 'PATCH', body: JSON.stringify({ paket, bitis, dersler: null }), ek: { Prefer: 'return=minimal' } });
    else await istek('/rest/v1/paket_uyeler', { method: 'POST', body: JSON.stringify(satir), ek: { Prefer: 'return=minimal' } });
    await istek('/rest/v1/paket_hediye', { method: 'POST', body: JSON.stringify({ user_id: u.id, eposta: eposta.toLowerCase(), paket, bitis, neden, elci_kodu: elci }), ek: { Prefer: 'return=minimal' } });
    const kontrol = (await istek('/rest/v1/paket_uyeler?select=paket,bitis&user_id=eq.' + u.id))[0];
    console.log(`✓ ${eposta}: ${kontrol.paket} paketi ${kontrol.bitis} tarihine kadar açık (kütüğe yazıldı).`);
    return;
  }
  if (komut === 'geri') {
    if (!mevcut) dur('bu hesapta paket yok');
    const h = await istek('/rest/v1/paket_hediye?select=id&iptal=is.null&user_id=eq.' + u.id);
    if (!h.length && !var_('zorla')) dur('bu hesabın paketi hediye kütüğünde yok - parayla alınmış olabilir. Bilerek kapatmak için --zorla.');
    await istek('/rest/v1/paket_uyeler?user_id=eq.' + u.id, { method: 'PATCH', body: JSON.stringify({ bitis: dun() }), ek: { Prefer: 'return=minimal' } });
    for (const x of h) await istek('/rest/v1/paket_hediye?id=eq.' + x.id, { method: 'PATCH', body: JSON.stringify({ iptal: new Date().toISOString(), neden: ('İPTAL: ' + neden).slice(0, 200) }), ek: { Prefer: 'return=minimal' } });
    console.log(`✓ ${eposta}: paket kapatıldı (bitiş ${dun()}), kütükte iptal işaretlendi.`);
    return;
  }
  dur('komut: ver | liste | geri');
})().catch(e => { console.error((e.dur ? 'DUR: ' : 'HATA: ') + e.message); process.exitCode = e.dur ? 2 : 1; });
