#!/usr/bin/env node
/* ============================================================================
 *  HAVALE HATIRLATMASI (19.10.2026, Cem: "Google'dan gelenin satın alma oranını artıralım" → "hatırlatmayı kur,
 *  eski bekleyen siparişlere de bir kez gönder")
 *
 *  NEDEN (19.10 ölçüldü, siparisler, yalnız sayım): kartla açılan 10 siparişin 10'u ödendi; havaleyle açılan 10
 *  siparişin (iptal hariç) 2'si ödendi, 8'i "ödeme bekliyor"da kaldı. Sipariş sonrası tek mail 'alindi' (IBAN) idi,
 *  ödemeyen kişiye bir daha hiçbir şey gitmiyordu.
 *
 *  KİME: siparisler durum = odeme_bekliyor · odeme = havale · en az 3 saat önce açılmış · paketin sınavı geçmemiş.
 *    Aynı e-postayla bu siparişten SONRA ödenmiş sipariş varsa (kişi karta geçmiş) atlanır. Bir e-postanın birden çok
 *    bekleyen siparişi varsa yalnız en yenisi için mail gider, hepsi "hatırlatıldı" sayılır. Her sipariş ömründe BİR kez.
 *  İÇERİK: sipariş no + paket + tutar + "Kartla öde" bağlantısı (satin-al.html?kartla=<no>: tutarı iyzico-odeme
 *    ?islem=baslat SUNUCUDA hesaplar) + havale bilgisi (siparis-bildirim.ts BANKA ile AYNI). Sipariş üzerine giden
 *    işlem maili; kampanya dili yok.
 *  KAYIT: her gönderim form_kayit "Havale hatırlatması gönderildi" {siparis_no} (çift gönderim yok).
 *  ⛔ ONAYSIZ GÖNDERMEZ: arac/hatirlatma-ayar.json havale_acik = true VE havale_onayli_imza = bugünkü metin imzası
 *    (node motor/havale-hatirlatma.mjs --imza). Metin değişince imza değişir, gönderim kendiliğinden SAYIMA döner.
 *  ⛔ GÜNLÜK PUBLIC: e-posta/ad/sipariş no basılmaz, yalnız sayı.
 *  🚫 GÖRMEZ: havalenin bankaya gelip panelde henüz "ödendi" yapılmamış olması (o kişiye yine mail gider; metin
 *    "ödemeyi yaptıysan dikkate alma" der) · kişinin başka e-postayla ödemiş olması · Resend'in kutuya teslimi.
 *
 *  Kullanım: node motor/havale-hatirlatma.mjs [--kuru] · --ornek <klasör> · --imza · --sinav · --deneme (yalnız Cem'e)
 * ==========================================================================*/
import { kurumsalMail } from '../radar-app/edge/karne-gonder.ts';
import { SINAVLAR } from './hatirlatma-dizisi.mjs';
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { fileURLToPath } from 'node:url';

const KOK = path.join(path.dirname(fileURLToPath(import.meta.url)), '..');
const SB = 'https://bjrleanjpyujtajmazxn.supabase.co', SITE = 'https://tetikte.com';
const SK = (process.env.SUPABASE_SERVICE_KEY || '').trim();
const RESEND_KEY = (process.env.RESEND_KEY || '').trim(), RESEND_FROM = (process.env.RESEND_FROM || 'Tetikte <bildirim@tetikte.com>').trim();
const ALARM = (process.env.ALARM_ALICI || 'cem@dizdardenetim.com').trim();
const arg = a => { const i = process.argv.indexOf(a); return i > 0 ? process.argv[i + 1] : null; };
const SAAT = 36e5, KAYIT = 'Havale hatırlatması gönderildi';
/* radar-app/edge/siparis-bildirim.ts BANKA ile AYNI (orada değişirse burada da) */
export const BANKA = { ad: 'VakıfBank', iban: 'TR74 0001 5001 5800 7376 2710 72', alici: 'Dizdar Denetim Danışmanlık ve Yazılım A.Ş.' };
const kac = s => String(s == null ? '' : s).replace(/[&<>"]/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
const tl = n => Number(n || 0).toLocaleString('tr-TR') + ' TL';
const tarih = d => new Date(d).toLocaleDateString('tr-TR', { timeZone: 'Europe/Istanbul', day: '2-digit', month: '2-digit', year: 'numeric' });   /* UTC 21:51 = TR ertesi gün */
const DUGME = 'background:#f5a524;color:#1b1206;text-decoration:none;font-weight:800;padding:12px 20px;border-radius:8px;display:inline-block';
const NEDEN = "Bu e-posta, tetikte.com'da verdiğin sipariş üzerine gönderilmiştir.";
export const sinavOf = paket => /^sgs/.test(paket) ? 'sgs' : /^yeterlilik/.test(paket) ? 'yeterlilik' : null;

/* s: { siparis_no, ad_soyad, paket, paket_ad, tutar, olusturma } */
export function mailKur(s) {
  const ad = String(s.ad_soyad || '').trim().split(/\s+/)[0] || '';
  const S = SINAVLAR[sinavOf(s.paket)] || null;
  const kart = `${SITE}/satin-al.html?kartla=${encodeURIComponent(s.siparis_no)}&k=mail-havale`;
  const konu = `Siparişin ödeme bekliyor: ${s.siparis_no} · ${tl(s.tutar)}`;
  const p1 = `${tarih(s.olusturma)} tarihinde verdiğin ${s.paket_ad || s.paket} siparişinin ödemesi henüz bize ulaşmadı; bu yüzden paketin açılmadı.`;
  const p2 = "Kartla ödersen paketin hemen açılır. Kart bilgin bize gelmez; ödeme iyzico'nun güvenli sayfasında yapılır.";
  const p3 = 'Ödemeyi yaptıysan bu e-postayı dikkate alma; havaleyi gördüğümüz gün paketin açılır ve sana haber veririz. Siparişi artık istemiyorsan bir şey yapmana gerek yok.';
  const p4 = (S ? `${S.ad} sınavı ${S.tarihYazi}'da. ` : '') + "Takıldığın bir yer varsa bu e-postayı yanıtla ya da WhatsApp'tan yaz: 0532 344 80 58.";
  const metin = [`Merhaba${ad ? ' ' + ad : ''},`, '', p1, '', p2, `Kartla öde (${tl(s.tutar)}): ${kart}`, '',
    'Havale/EFT ile ödemek istersen:', `Banka: ${BANKA.ad}`, `Alıcı: ${BANKA.alici}`, `IBAN: ${BANKA.iban}`, `Tutar (KDV dahil): ${tl(s.tutar)}`,
    `Açıklama: ${s.siparis_no}  (havale açıklamasına yalnız sipariş numaranı yaz)`, '', p3, '', p4, '', 'Sınava tetikte gir.'].join('\n');
  const satir = (k, v) => `<tr><td style="padding:4px 14px 4px 0;color:#3d4b63">${k}</td><td>${v}</td></tr>`;
  const html = kurumsalMail(`<p>Merhaba${ad ? ' ' + kac(ad) : ''},</p>
<p>${kac(p1)}</p>
<p>${kac(p2)}</p>
<p style="margin:4px 0 18px"><a href="${kac(kart)}" style="${DUGME}">Kartla öde · ${kac(tl(s.tutar))} →</a></p>
<p style="margin:0 0 4px"><b>Havale/EFT ile ödemek istersen:</b></p>
<table style="border-collapse:collapse;margin:0 0 12px">
${satir('Banka', kac(BANKA.ad))}
${satir('Alıcı', kac(BANKA.alici))}
${satir('IBAN', '<b>' + kac(BANKA.iban) + '</b>')}
${satir('Tutar (KDV dahil)', '<b>' + kac(tl(s.tutar)) + '</b>')}
${satir('Açıklama', '<b>' + kac(s.siparis_no) + '</b> <span style="color:#3d4b63">(yalnız sipariş numaran)</span>')}
</table>
<p style="color:#3d4b63">${kac(p3)}</p>
<p style="color:#3d4b63">${kac(p4)}</p>`, NEDEN);
  return { konu, metin, html };
}

const ORNEKLER = [
  { siparis_no: 'TT-20261019-ABCD', ad_soyad: 'Ayşe Örnek', paket: 'yeterlilik-1', paket_ad: 'Yeterlilik — 1 ders', tutar: 1188, olusturma: '2026-10-19T13:57:00Z' },
  { siparis_no: 'TT-20261008-EFHJ', ad_soyad: '', paket: 'sgs', paket_ad: 'Staja Giriş — soru bankası', tutar: 2988, olusturma: '2026-10-08T21:51:00Z' },
];
export function imza() {
  const t = ORNEKLER.map(s => { const m = mailKur(s); return m.konu + m.metin; }).join('|');
  return crypto.createHash('sha256').update(t).digest('hex').slice(0, 16);
}

/* seçim: saf işlev, öz-sınavlı. L = siparisler, gitti = Set(siparis_no). Dönen: [{ s, kapsar: [no...] }] */
export function sec(L, gitti, simdi) {
  const say = { bekleyen: 0, yeni: 0, kartaGecti: 0, sinavGecti: 0, zatenGitti: 0, ayniKisi: 0, gidecek: 0 };
  const odenen = L.filter(x => x.durum === 'odendi');
  const aday = new Map();   // eposta -> [sipariş]
  for (const s of L) {
    if (s.durum !== 'odeme_bekliyor' || s.odeme !== 'havale') continue;
    say.bekleyen++;
    if (simdi - new Date(s.olusturma) < 3 * SAAT) { say.yeni++; continue; }
    const S = SINAVLAR[sinavOf(s.paket)];
    if (!S || simdi >= new Date(S.tarih + 'T00:00:00+03:00')) { say.sinavGecti++; continue; }
    const e = String(s.email || '').toLowerCase(); if (!e) continue;
    if (odenen.some(o => String(o.email || '').toLowerCase() === e && new Date(o.olusturma) >= new Date(s.olusturma))) { say.kartaGecti++; continue; }
    if (gitti.has(s.siparis_no)) { say.zatenGitti++; continue; }
    (aday.get(e) || aday.set(e, []).get(e)).push(s);
  }
  const out = [];
  for (const L2 of aday.values()) {
    L2.sort((a, b) => new Date(b.olusturma) - new Date(a.olusturma));
    say.ayniKisi += L2.length - 1;
    out.push({ s: L2[0], kapsar: L2.map(x => x.siparis_no) });
  }
  say.gidecek = out.length;
  return { out, say };
}

async function sb(yol, sec2 = {}) {
  const r = await fetch(SB + yol, { ...sec2, headers: { apikey: SK, Authorization: 'Bearer ' + SK, 'Content-Type': 'application/json', ...(sec2.headers || {}) } });
  if (!r.ok) throw new Error(yol.split('?')[0] + ' http ' + r.status); return sec2.method === 'POST' ? null : r.json();
}
async function hepsi(yol) { const o = []; for (let i = 0; ; i += 1000) { const p = await sb(yol + `&limit=1000&offset=${i}`); o.push(...p); if (p.length < 1000) return o; } }
async function resend(govde) {
  return fetch('https://api.resend.com/emails', { method: 'POST', headers: { Authorization: 'Bearer ' + RESEND_KEY, 'Content-Type': 'application/json' }, body: JSON.stringify(govde) });
}

async function ana() {
  if (process.argv.includes('--imza')) { console.log(imza()); return; }
  const ornek = arg('--ornek');
  if (ornek) {
    fs.mkdirSync(ornek, { recursive: true });
    ORNEKLER.forEach((s, i) => { const m = mailKur(s); fs.writeFileSync(path.join(ornek, `${i + 1}-havale.html`), `<!-- Konu: ${m.konu} -->\n` + m.html); fs.writeFileSync(path.join(ornek, `${i + 1}-havale.txt`), 'Konu: ' + m.konu + '\n\n' + m.metin); console.log(m.konu); });
    console.log('imza: ' + imza()); return;
  }
  if (process.argv.includes('--deneme')) {   /* örnekler YALNIZ ALARM_ALICI'ya, "[DENEME]" konulu; kayıt yazılmaz */
    if (!RESEND_KEY) throw new Error('RESEND_KEY yok');
    let n = 0;
    for (const s of ORNEKLER) { const m = mailKur(s); if ((await resend({ from: RESEND_FROM, to: [ALARM], subject: '[DENEME] ' + m.konu, text: m.metin, html: m.html, reply_to: 'destek@tetikte.com' })).ok) n++; await new Promise(r => setTimeout(r, 600)); }
    console.log(`DENEME: ${n}/${ORNEKLER.length} mail Cem'e gitti`); if (n < ORNEKLER.length) process.exitCode = 1; return;
  }
  if (!SK) throw new Error('SUPABASE_SERVICE_KEY yok');
  const ayar = JSON.parse(fs.readFileSync(path.join(KOK, 'arac', 'hatirlatma-ayar.json'), 'utf8'));
  const im = imza(), acik = !process.argv.includes('--kuru') && ayar.havale_acik === true && ayar.havale_onayli_imza === im;
  const L = await hepsi('/rest/v1/siparisler?select=siparis_no,ad_soyad,email,paket,paket_ad,tutar,durum,odeme,olusturma&order=olusturma.asc');
  const gitti = new Set((await hepsi(`/rest/v1/form_kayit?select=alanlar&konu=eq.${encodeURIComponent(KAYIT)}`)).flatMap(x => (x.alanlar || {}).kapsar || [(x.alanlar || {}).siparis_no]).filter(Boolean));
  const { out, say } = sec(L, gitti, new Date());
  let git = 0, dus = 0;
  if (acik) {
    if (!RESEND_KEY) throw new Error('RESEND_KEY yok');
    for (const { s, kapsar } of out) {
      const m = mailKur(s);
      const r = await resend({ from: RESEND_FROM, to: [s.email], subject: m.konu, text: m.metin, html: m.html, reply_to: 'destek@tetikte.com' });
      if (r.ok) { git++; await sb('/rest/v1/form_kayit', { method: 'POST', headers: { Prefer: 'return=minimal' }, body: JSON.stringify({ konu: KAYIT, gonderen: 'motor/havale-hatirlatma.mjs', eposta: s.email, alanlar: { siparis_no: s.siparis_no, kapsar } }) }); }
      else dus++;
      await new Promise(r => setTimeout(r, 600));
    }
  }
  const ozet = `HAVALE HATIRLATMASI ${acik ? 'GÖNDERİM' : 'SAYIM (gönderim kapalı)'}: bekleyen havale ${say.bekleyen} · 3 saatten yeni ${say.yeni} · sınavı geçmiş ${say.sinavGecti} · sonra ödemiş ${say.kartaGecti} · zaten hatırlatıldı ${say.zatenGitti} · aynı kişinin eski siparişi ${say.ayniKisi} · gidecek ${say.gidecek}` + (acik ? ` · gitti ${git} · düştü ${dus}` : '') + ` · metin imzası ${im}${ayar.havale_onayli_imza === im ? ' (onaylı)' : ' (ONAYSIZ)'}`;
  console.log(ozet);
  if (acik && dus) process.exitCode = 1;
}

function sinav() {
  let h = 0, n = 0; const b = (ad, k) => { n++; console.log((k ? '  geçti  ' : '  DÜŞTÜ  ') + ad); if (!k) h++; };
  const S = (no, ek) => Object.assign({ siparis_no: no, email: 'a@b.com', paket: 'sgs', paket_ad: 'SGS', tutar: 2988, durum: 'odeme_bekliyor', odeme: 'havale', olusturma: '2026-10-18T08:00:00Z' }, ek);
  const T = new Date('2026-10-19T12:00:00Z');
  const ids = r => r.out.map(x => x.s.siparis_no).join(',');
  b('3 saatten eski havale -> gider', ids(sec([S('A')], new Set(), T)) === 'A');
  b('3 saatten yeni -> gitmez', ids(sec([S('A', { olusturma: '2026-10-19T10:30:00Z' })], new Set(), T)) === '');
  b('kart siparişi -> gitmez', ids(sec([S('A', { odeme: 'kart' })], new Set(), T)) === '');
  b('ödenmiş / iptal -> gitmez', ids(sec([S('A', { durum: 'odendi' }), S('B', { durum: 'iptal', email: 'c@d.com' })], new Set(), T)) === '');
  b('zaten hatırlatıldı -> gitmez', ids(sec([S('A')], new Set(['A']), T)) === '');
  b('aynı kişi sonra ödemiş -> gitmez', ids(sec([S('A'), S('B', { durum: 'odendi', odeme: 'kart', olusturma: '2026-10-18T08:05:00Z' })], new Set(), T)) === '');
  b('aynı kişi ÖNCE ödemiş (ikinci paket) -> gider', ids(sec([S('B', { durum: 'odendi', odeme: 'kart', olusturma: '2026-10-10T08:00:00Z' }), S('A')], new Set(), T)) === 'A');
  b('aynı kişinin iki bekleyeni -> yalnız en yenisi, ikisi kapsanır', (() => { const r = sec([S('A', { olusturma: '2026-10-08T08:00:00Z' }), S('B')], new Set(), T); return ids(r) === 'B' && r.out[0].kapsar.join() === 'B,A'; })());
  b('büyük/küçük harf e-posta aynı kişi', ids(sec([S('A', { email: 'A@B.com' }), S('B', { durum: 'odendi', odeme: 'kart', olusturma: '2026-10-18T09:00:00Z' })], new Set(), T)) === '');
  b('sınav günü geçmiş -> gitmez', ids(sec([S('A')], new Set(), new Date('2026-11-21T12:00:00Z'))) === '' && ids(sec([S('A', { paket: 'yeterlilik-1' })], new Set(), new Date('2026-11-21T12:00:00Z'))) === 'A');
  b('KGK / tanımsız paket -> gitmez', ids(sec([S('A', { paket: 'kgk-1' })], new Set(), T)) === '');
  const m = mailKur(ORNEKLER[0]);
  b('kartla öde bağlantısı sipariş no ile', m.html.includes('satin-al.html?kartla=TT-20261019-ABCD') && m.metin.includes('satin-al.html?kartla=TT-20261019-ABCD'));
  b('IBAN siparis-bildirim.ts ile aynı', (() => { const t = fs.readFileSync(path.join(KOK, 'radar-app', 'edge', 'siparis-bildirim.ts'), 'utf8'); return t.includes(BANKA.iban) && t.includes(BANKA.alici); })());
  b('tutar ve sınav tarihi metinde', m.metin.includes('1.188 TL') && m.metin.includes('28 Kasım'));
  b('adsız siparişte "Merhaba," düz', mailKur(ORNEKLER[1]).metin.startsWith('Merhaba,'));
  b('metinde "yapay zek" / "Claude" yok', ORNEKLER.every(s => !/yapay zek|claude/i.test(mailKur(s).metin)));
  b('imza metinle değişir', (() => { const i1 = imza(); const e = BANKA.ad; BANKA.ad = 'X'; const i2 = imza(); BANKA.ad = e; return i1 !== i2; })());
  console.log(`HAVALE HATIRLATMASI öz-sınav: ${n - h}/${n}`); process.exitCode = h ? 1 : 0;
}
if (process.argv[1] && process.argv[1].endsWith('havale-hatirlatma.mjs')) {
  if (process.argv.includes('--sinav')) sinav(); else ana().catch(e => { console.log('HAVALE HATIRLATMASI HATA: ' + e.message); process.exitCode = 1; });
}
