#!/usr/bin/env node
/* ============================================================================
 *  ERKEN KAYIT KAMPANYA MAİLİ — TEK SEFERLİK (31.10.2026, Cem: "üye olup paket açmayan insanlara mail göndersek"
 *  → "sınavı kazanmaz isen kazanana kadar ... onu yazsan" → metni gördü: "gönder mailleri")
 *
 *  İÇERİK: yönetim kurulu kararı (kampanya-son-20-gun.html #karar, 29.10) — 1 Kasım 23:59'a kadar paket alan, paketinin
 *    sınavını kazanana kadar ek üyelik ücreti ödemez (şartsız; sonuç belgesi yeter) + erken kayıt fiyatları (fiyat-motoru.js
 *    FIYAT + ERKEN_KAYIT / ERKEN_YET: SGS 2.988 → 2.388, 1 Kasım · Yeterlilik tüm 3.468 → 2.868, 7 Kasım).
 *    "Garanti" / "hediye" YAZILMAZ (kampanya sayfasıyla aynı dil: reklam kuralı + 5580). "Az kalan paket" YAZILMAZ (stok yok).
 *  KİME: uye-dizisi.mjs ile AYNI izin kuralı (pazarlama_rizasi ya da karnede kampanya izni) · e-postası doğrulanmış ·
 *    bugün aktif paketi yok · ödeme bekleyen siparişi yok · çıkış (ret) yapmamış · bu kampanyayı daha önce almamış.
 *    Karneden sınavı belli olana yalnız o sınavın fiyat satırı; bilinmeyene ikisi.
 *  SÜRE: yalnız 31.10 ve 1.11 (TR) gönderir; şartsız hak 1 Kasım 23:59'da biter → sonra çalışmaz.
 *  ⛔ GÜNLÜK PUBLIC: e-posta/ad basılmaz, yalnız sayı. Her gönderim form_kayit "Hatırlatma gönderildi" {tur:'erken3110', sinav:'kampanya'}
 *    → yeniden koşunca aynı kişiye ikinci kez gitmez; üye dizisinin "son 3 gün" kuralı da bunu görür.
 *  Kullanım: node motor/erken-kayit-kampanya.mjs --kuru | --ornek <klasör> | --gonder (GitHub: erken-kayit-kampanya.yml)
 * ==========================================================================*/
import { kurumsalMail } from '../radar-app/edge/karne-gonder.ts';
import { SINAVLAR, jeton } from './hatirlatma-dizisi.mjs';
import fs from 'node:fs';
import path from 'node:path';

const SB = 'https://bjrleanjpyujtajmazxn.supabase.co', SITE = 'https://tetikte.com', TUR = 'erken3110';
const SK = (process.env.SUPABASE_SERVICE_KEY || '').trim();
const RESEND_KEY = (process.env.RESEND_KEY || '').trim(), RESEND_FROM = (process.env.RESEND_FROM || 'Tetikte <bildirim@tetikte.com>').trim();
const ALARM = (process.env.ALARM_ALICI || 'cem@dizdardenetim.com').trim();
const arg = a => { const i = process.argv.indexOf(a); return i > 0 ? process.argv[i + 1] : null; };
const GUN = 864e5;
const kac = s => String(s == null ? '' : s).replace(/[&<>"]/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
const DUGME = 'background:#f5a524;color:#1b1206;text-decoration:none;font-weight:800;padding:11px 18px;border-radius:8px;display:inline-block';
const NEDEN = 'Bu e-postayı, Tetikte hesabını açarken sınav hatırlatmalarına ve duyurulara izin verdiğin için aldın.';
const trGun = d => new Date(d.getTime() + 3 * 3600e3).toISOString().slice(0, 10);
const kalanGun = (s, simdi) => Math.max(0, Math.round((new Date(SINAVLAR[s].tarih + 'T00:00:00+03:00') - simdi) / GUN));

/* sinav: 'sgs' | 'yeterlilik' | null · simdi: 31.10 ya da 1.11 (TR) */
export function mailKur(sinav, e, simdi = new Date()) {
  const g = trGun(simdi), ne = g === '2026-10-31' ? 'Yarın 23:59' : 'Bu gece 23:59';
  const konu = `${ne}'a kadar: sınavda kalırsan, geçene kadar Tetikte`;
  const karar = '1 Kasım Pazar 23:59\'a kadar paket alan herkes, aldığı paketin sınavını kazanana kadar ek üyelik ücreti ödemez.';
  const karar2 = 'Deneme barajı ya da görev şartı yok; girdiğin sınavın sonuç belgesini bizimle paylaşman yeterli. 1 Kasım\'dan sonra alanlarda deneme ve görev şartı aranacak.';
  const fiyat = [];
  if (sinav !== 'yeterlilik') fiyat.push(['Staja Giriş soru bankası', '2.988 TL', '2.388 TL', '1 Kasım 23:59\'a kadar']);
  if (sinav !== 'sgs') fiyat.push(['Yeterlilik, tüm dersler', '3.468 TL', '2.868 TL', '7 Kasım 23:59\'a kadar']);
  const kalan = sinav ? `${SINAVLAR[sinav].ad} sınavına ${kalanGun(sinav, simdi)} gün kaldı.`
    : `Staja Giriş sınavına ${kalanGun('sgs', simdi)} gün, Yeterlilik sınavına ${kalanGun('yeterlilik', simdi)} gün kaldı.`;
  const son = kalan + ' Paketle seçtiğin sınavın bütün soruları açılır. Yanlışların, test ve deneme sonuçların hesabında kalır.';
  const href = `${SITE}/kampanya-son-20-gun.html?k=mail-erken3110`, dugme = 'Kararı ve paketleri gör →';
  const ret = `${SITE}/hatirlatma-ret.html?t=${jeton(e || '')}`;
  const metin = ['Merhaba,', '', 'TETİKTE · YÖNETİM KURULU KARARI', 'Kalırsan, geçene kadar Tetikte\'desin', '', karar, karar2, '',
    ...fiyat.map(([a, l, y, t]) => `${a}: ${l} yerine ${y} (${t})`), '', son, '', `${dugme.replace(' →', '')}: ${href}`, '',
    'Sınava tetikte gir.', '', NEDEN, `Bir daha gönderme: ${ret}`].join('\n');
  const html = kurumsalMail(`<p style="font-size:12px;letter-spacing:.12em;color:#8d6c38;font-weight:700;margin:0 0 6px">TETİKTE · YÖNETİM KURULU KARARI</p>
<h1 style="font-size:24px;margin:0 0 10px">Kalırsan, geçene kadar Tetikte'desin</h1>
<p style="margin:0 0 8px"><b>${kac(karar)}</b></p>
<p style="margin:0 0 14px">${kac(karar2)}</p>
${fiyat.map(([a, l, y, t]) => `<p style="margin:0 0 6px"><b>${kac(a)}:</b> <s style="color:#6b7280">${kac(l)}</s> yerine <b>${kac(y)}</b> <span style="color:#6b7280">(${kac(t)})</span></p>`).join('\n')}
<p style="margin:12px 0 12px">${kac(son)}</p>
<p style="margin:4px 0 18px"><a href="${href}" style="${DUGME}">${kac(dugme)}</a></p>
<p style="margin:0;font-size:12px;color:#6b7280"><a href="${ret}" style="color:#6b7280">Bu e-postaları bir daha gönderme</a></p>
`, NEDEN);
  return { konu, metin, html };
}

async function sb(yol, sec = {}) {
  const r = await fetch(SB + yol, { ...sec, headers: { apikey: SK, Authorization: 'Bearer ' + SK, 'Content-Type': 'application/json', ...(sec.headers || {}) } });
  if (!r.ok) throw new Error(yol.split('?')[0] + ' http ' + r.status); return sec.method === 'POST' ? null : r.json();
}
async function hepsi(yol) { const o = []; for (let i = 0; ; i += 1000) { const p = await sb(yol + `&limit=1000&offset=${i}`); o.push(...p); if (p.length < 1000) return o; } }
async function kullanicilar() {
  const o = []; for (let p = 1; p < 200; p++) { const j = await sb(`/auth/v1/admin/users?page=${p}&per_page=200`); const L = j.users || []; o.push(...L); if (L.length < 200) break; } return o;
}
const resend = govde => fetch('https://api.resend.com/emails', { method: 'POST', headers: { Authorization: 'Bearer ' + RESEND_KEY, 'Content-Type': 'application/json' }, body: JSON.stringify(govde) });

async function ana() {
  const simdi = new Date(), g = trGun(simdi);
  const ornek = arg('--ornek');
  if (ornek) {
    fs.mkdirSync(ornek, { recursive: true });
    for (const s of [null, 'sgs', 'yeterlilik']) { const m = mailKur(s, 'ornek@ornek.com', new Date('2026-10-31T15:00:00+03:00')); fs.writeFileSync(path.join(ornek, `erken-${s || 'iki'}.html`), `<!-- Konu: ${m.konu} -->\n` + m.html); console.log(`${s || 'iki'}: ${m.konu}\n${m.metin}\n`); }
    return;
  }
  const gonder = process.argv.includes('--gonder');
  if (gonder && g !== '2026-10-31' && g !== '2026-11-01') { console.log(`ERKEN KAMPANYA: bugün ${g} — süre dışı, gönderilmedi`); return; }
  if (!SK) throw new Error('SUPABASE_SERVICE_KEY yok');
  const bugun = g;
  const karne = await hepsi(`/rest/v1/form_kayit?select=eposta,alanlar,olusturma&konu=eq.${encodeURIComponent('Seviye testi karnesi')}&order=olusturma.asc`);
  const gonderim = await hepsi(`/rest/v1/form_kayit?select=eposta,alanlar&konu=eq.${encodeURIComponent('Hatırlatma gönderildi')}`);
  const aldi = new Set(gonderim.filter(x => (x.alanlar || {}).tur === TUR).map(x => String(x.eposta || '').toLowerCase()));
  const elleRet = new Set((await hepsi(`/rest/v1/form_kayit?select=eposta&konu=eq.${encodeURIComponent('Hatırlatma reddi')}`)).map(x => String(x.eposta || '').toLowerCase()));
  const retJeton = new Set((await hepsi('/rest/v1/hatirlatma_ret?select=jeton')).map(x => x.jeton));
  const aktif = new Set((await hepsi('/rest/v1/paket_uyeler?select=user_id,bitis')).filter(p => p.bitis >= bugun).map(p => p.user_id));
  const bekleyen = new Set((await hepsi('/rest/v1/siparisler?select=email&durum=eq.odeme_bekliyor')).map(x => String(x.email || '').toLowerCase()));
  const kart = new Map();
  for (const k of karne) {
    const a = k.alanlar || {}, e = String(k.eposta || '').toLowerCase(); if (!e) continue;
    const once = kart.get(e);
    kart.set(e, { sinav: a['Sınav'] === 'Yeterlilik' ? 'yeterlilik' : 'sgs', izin: a['Kampanya/hatırlatma izni'] === 'evet' || (once && once.izin) });
  }
  const say = { hesap: 0, paketli: 0, onaysiz: 0, izinsiz: 0, cikti: 0, bekleyen: 0, aldi: 0, sgs: 0, yeterlilik: 0, iki: 0, gitti: 0, dustu: 0 }, liste = [];
  for (const u of await kullanicilar()) {
    const e = String(u.email || '').toLowerCase(); if (!e) continue; say.hesap++;
    if (aktif.has(u.id)) { say.paketli++; continue; }
    if (!u.email_confirmed_at) { say.onaysiz++; continue; }
    const kr = kart.get(e) || {};
    if (!((u.user_metadata || {}).pazarlama_rizasi === true || kr.izin)) { say.izinsiz++; continue; }
    if (elleRet.has(e) || retJeton.has(jeton(e))) { say.cikti++; continue; }
    if (bekleyen.has(e)) { say.bekleyen++; continue; }
    if (aldi.has(e)) { say.aldi++; continue; }
    const s = kr.sinav || null; say[s || 'iki']++; liste.push([e, s]);
  }
  if (gonder) {
    if (!RESEND_KEY) throw new Error('RESEND_KEY yok');
    const d = mailKur(null, ALARM, simdi);   // önce Cem'e bir kopya ("[KOPYA]"), kayıt yazılmaz
    await resend({ from: RESEND_FROM, to: [ALARM], subject: '[KOPYA] ' + d.konu, text: d.metin, html: d.html });
    for (const [e, s] of liste) {
      const m = mailKur(s, e, simdi);
      const r = await resend({ from: RESEND_FROM, to: [e], subject: m.konu, text: m.metin, html: m.html, headers: { 'List-Unsubscribe': `<${SITE}/hatirlatma-ret.html?t=${jeton(e)}>` } });
      if (r.ok) { say.gitti++; await sb('/rest/v1/form_kayit', { method: 'POST', headers: { Prefer: 'return=minimal' }, body: JSON.stringify({ konu: 'Hatırlatma gönderildi', gonderen: 'motor/erken-kayit-kampanya.mjs', eposta: e, alanlar: { tur: TUR, sinav: 'kampanya' } }) }); }
      else say.dustu++;
      await new Promise(r => setTimeout(r, 600));
    }
  }
  console.log(`ERKEN KAMPANYA ${gonder ? 'GÖNDERİM' : 'SAYIM'}: hesap ${say.hesap} · aktif paketli ${say.paketli} · onaysız ${say.onaysiz} · izinsiz ${say.izinsiz} · çıkmış ${say.cikti} · ödeme bekleyen ${say.bekleyen} · daha önce aldı ${say.aldi} · alıcı ${liste.length} (SGS ${say.sgs} · Yeterlilik ${say.yeterlilik} · iki sınav ${say.iki})` + (gonder ? ` · gitti ${say.gitti} · düştü ${say.dustu}` : ''));
  if (gonder && say.dustu) process.exitCode = 1;
}
if (process.argv[1] && process.argv[1].endsWith('erken-kayit-kampanya.mjs')) ana().catch(e => { console.log('ERKEN KAMPANYA HATA: ' + e.message); process.exitCode = 1; });
