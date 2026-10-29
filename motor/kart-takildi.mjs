#!/usr/bin/env node
/* ============================================================================
 *  KART TAKILDI MAİLİ (29.10.2026, Cem: "iyzico sayfasında kalıp hiç dönmeyenlere 30 dk sonra mail" → "Evet, kur")
 *
 *  NEDEN (29.10 ölçüldü, kart_odemeleri + siparisler, yalnız sayım): 15 siparişte kart hiç geçmedi; 11'i iyzico
 *  sayfasında kaldı (siteye dönmedi, durum 'baslatildi'), 4'ü hata ile döndü. 8'i sonra ödedi, 7'si ödemedi.
 *  28.10'dan beri kart düğmesine basana 'alindi' (IBAN) maili gitmiyor; SMS hattı yok → bu kişiye 3 saatlik havale
 *  hatırlatmasına kadar hiçbir şey ulaşmıyordu (o da yalnız 3'üne gitmişti).
 *
 *  KİME: siparisler durum = odeme_bekliyor · kart_odemeleri'nde (deneme değil) bu siparişe en az bir deneme var, hiçbiri
 *    'basarili' değil · SON deneme en az 30 dk, en çok 24 saat önce · paketin sınavı geçmemiş · aynı e-postayla sonra
 *    ödenmiş sipariş yok · kişi hata ile siteye dönüp IBAN mailini o anda almadı (alindi_mail damgası ilk denemeden
 *    SONRA ise satin-al.html ?odeme=hata kutusu maili zaten yolladı → atlanır) · bu sipariş için daha önce gitmedi.
 *    Bir e-postanın birden çok adayı varsa yalnız en yenisine. Her sipariş ömründe BİR kez.
 *  ÇİFT MAİL YOK: motor/havale-hatirlatma.mjs bu kaydı (KAYIT) da okur; kart takıldı maili giden siparişe 3 saatlik
 *    havale hatırlatması GİTMEZ.
 *  KAYIT: form_kayit "Kart takıldı maili gönderildi" {siparis_no, kapsar}.
 *  ⛔ ONAYSIZ GÖNDERMEZ: arac/hatirlatma-ayar.json kart_takildi_acik = true VE kart_takildi_onayli_imza = metin imzası
 *    (node motor/kart-takildi.mjs --imza). Metin değişince gönderim kendiliğinden SAYIMA döner.
 *  ⛔ GÜNLÜK PUBLIC: e-posta/ad/sipariş no basılmaz, yalnız sayı.
 *  🚫 GÖRMEZ: bankanın gerçek ret sebebi (iyzico panelinde) · kişinin başka e-postayla ödemiş olması · Resend'in kutuya
 *    teslimi · robotun gecikmesi (GitHub zamanlayıcısı 15 dakikalık; gerçek gecikme 30 dk + birkaç dakika ile saat arası).
 *
 *  Kullanım: node motor/kart-takildi.mjs [--kuru] · --ornek <klasör> · --imza · --sinav · --deneme (yalnız Cem'e)
 * ==========================================================================*/
import { kurumsalMail } from '../radar-app/edge/karne-gonder.ts';
import { SINAVLAR } from './hatirlatma-dizisi.mjs';
import { BANKA } from './havale-hatirlatma.mjs';
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
const DK = 6e4;
export const KAYIT = 'Kart takıldı maili gönderildi';
const kac = s => String(s == null ? '' : s).replace(/[&<>"]/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
const tl = n => Number(n || 0).toLocaleString('tr-TR') + ' TL';
const DUGME = 'background:#f5a524;color:#1b1206;text-decoration:none;font-weight:800;padding:12px 20px;border-radius:8px;display:inline-block';
const NEDEN = "Bu e-posta, tetikte.com'da başlattığın kart ödemesi üzerine gönderilmiştir.";
/* son20-sgs / son20-yet de sayılır (havale-hatirlatma.mjs sinavOf yalnız baştan bakar) */
export const sinavOf = paket => /sgs/.test(paket) ? 'sgs' : /yet/.test(paket) ? 'yeterlilik' : null;

/* s: { siparis_no, ad_soyad, paket, paket_ad, tutar } */
export function mailKur(s) {
  const ad = String(s.ad_soyad || '').trim().split(/\s+/)[0] || '';
  const S = SINAVLAR[sinavOf(s.paket)] || null;
  const kart = `${SITE}/satin-al.html?kartla=${encodeURIComponent(s.siparis_no)}&k=mail-kart-takildi`;
  const konu = `Kart ödemen tamamlanmadı: ${s.siparis_no} · ${tl(s.tutar)}`;
  const p1 = `${s.paket_ad || s.paket} için başlattığın kart ödemesi tamamlanmadı. Kartından para çekilmedi; siparişin seni bekliyor, yeniden sipariş vermene gerek yok.`;
  const sebep = ['Kartın internetten alışverişe kapalı olabilir: banka uygulamasından "internet alışverişi"ni açman yeterli.',
    'Bankanın gönderdiği SMS şifresi gelmemiş, yanlış girilmiş ya da süresi dolmuş olabilir.',
    'Kartın limiti ya da bakiyesi yetmemiş olabilir; başka bir kartla da ödeyebilirsin.'];
  const p3 = 'Ödemeyi yaptıysan bu e-postayı dikkate alma. Siparişi artık istemiyorsan bir şey yapmana gerek yok.';
  const p4 = (S ? `${S.ad} sınavı ${S.tarihYazi}'da. ` : '') + "Takıldığın bir yer varsa bu e-postayı yanıtla ya da WhatsApp'tan yaz: 0532 344 80 58.";
  const metin = [`Merhaba${ad ? ' ' + ad : ''},`, '', p1, '', 'En sık sebepler:', ...sebep.map(x => '- ' + x), '',
    `Kartla yeniden dene (${tl(s.tutar)}): ${kart}`, '',
    'Havale/EFT ile ödemek istersen:', `Banka: ${BANKA.ad}`, `Alıcı: ${BANKA.alici}`, `IBAN: ${BANKA.iban}`, `Tutar (KDV dahil): ${tl(s.tutar)}`,
    `Açıklama: ${s.siparis_no}  (havale açıklamasına yalnız sipariş numaranı yaz)`, '', p3, '', p4, '', 'Sınava tetikte gir.'].join('\n');
  const satir = (k, v) => `<tr><td style="padding:4px 14px 4px 0;color:#3d4b63">${k}</td><td>${v}</td></tr>`;
  const html = kurumsalMail(`<p>Merhaba${ad ? ' ' + kac(ad) : ''},</p>
<p>${kac(p1)}</p>
<p style="margin:0 0 4px"><b>En sık sebepler:</b></p>
<ul style="margin:0 0 14px;padding-left:20px">${sebep.map(x => `<li>${kac(x)}</li>`).join('')}</ul>
<p style="margin:4px 0 18px"><a href="${kac(kart)}" style="${DUGME}">Kartla yeniden dene · ${kac(tl(s.tutar))} →</a></p>
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
  { siparis_no: 'TT-20261029-ABCD', ad_soyad: 'Ayşe Örnek', paket: 'sgs', paket_ad: 'Staja Giriş — Tam Paket', tutar: 2388 },
  { siparis_no: 'TT-20261029-EFHJ', ad_soyad: '', paket: 'yeterlilik-tum', paket_ad: 'Yeterlilik — tüm dersler', tutar: 2868 },
];
export function imza() {
  const t = ORNEKLER.map(s => { const m = mailKur(s); return m.konu + m.metin; }).join('|');
  return crypto.createHash('sha256').update(t).digest('hex').slice(0, 16);
}

/* seçim: saf işlev, öz-sınavlı. L = siparisler, K = kart_odemeleri (deneme değil), gitti = Set(siparis_no) */
export function sec(L, K, gitti, simdi) {
  const say = { takilan: 0, yeni: 0, eski: 0, sinavGecti: 0, sonraOdedi: 0, sayfadaAldi: 0, zatenGitti: 0, ayniKisi: 0, gidecek: 0 };
  const dene = new Map();   // siparis_no -> [deneme]
  for (const k of K) if (k.siparis_no) (dene.get(k.siparis_no) || dene.set(k.siparis_no, []).get(k.siparis_no)).push(k);
  const odenen = L.filter(x => x.durum === 'odendi');
  const aday = new Map();   // eposta -> [{ s, son }]
  for (const s of L) {
    if (s.durum !== 'odeme_bekliyor') continue;
    const D = dene.get(s.siparis_no); if (!D || D.some(k => k.durum === 'basarili')) continue;
    say.takilan++;
    const zaman = D.map(k => new Date(k.olusturma).getTime()).sort((a, b) => a - b), ilk = zaman[0], son = zaman[zaman.length - 1];
    if (simdi - son < 30 * DK) { say.yeni++; continue; }
    if (simdi - son > 24 * 60 * DK) { say.eski++; continue; }
    const S = SINAVLAR[sinavOf(s.paket)];
    if (!S || simdi >= new Date(S.tarih + 'T00:00:00+03:00')) { say.sinavGecti++; continue; }
    const e = String(s.email || '').toLowerCase(); if (!e) continue;
    if (odenen.some(o => String(o.email || '').toLowerCase() === e && new Date(o.olusturma) >= new Date(s.olusturma))) { say.sonraOdedi++; continue; }
    if (s.alindi_mail && new Date(s.alindi_mail).getTime() >= ilk) { say.sayfadaAldi++; continue; }
    if (gitti.has(s.siparis_no)) { say.zatenGitti++; continue; }
    (aday.get(e) || aday.set(e, []).get(e)).push({ s, son });
  }
  const out = [];
  for (const L2 of aday.values()) {
    L2.sort((a, b) => b.son - a.son);
    say.ayniKisi += L2.length - 1;
    out.push({ s: L2[0].s, kapsar: L2.map(x => x.s.siparis_no) });
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
    ORNEKLER.forEach((s, i) => { const m = mailKur(s); fs.writeFileSync(path.join(ornek, `${i + 1}-kart-takildi.html`), `<!-- Konu: ${m.konu} -->\n` + m.html); fs.writeFileSync(path.join(ornek, `${i + 1}-kart-takildi.txt`), 'Konu: ' + m.konu + '\n\n' + m.metin); console.log(m.konu); });
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
  const im = imza(), acik = !process.argv.includes('--kuru') && ayar.kart_takildi_acik === true && ayar.kart_takildi_onayli_imza === im;
  const L = await hepsi('/rest/v1/siparisler?select=siparis_no,ad_soyad,email,paket,paket_ad,tutar,durum,olusturma,alindi_mail&order=olusturma.asc');
  const K = await hepsi('/rest/v1/kart_odemeleri?select=siparis_no,durum,olusturma&deneme=eq.false&order=id.asc');
  const gitti = new Set((await hepsi(`/rest/v1/form_kayit?select=alanlar&konu=eq.${encodeURIComponent(KAYIT)}`)).flatMap(x => (x.alanlar || {}).kapsar || [(x.alanlar || {}).siparis_no]).filter(Boolean));
  const { out, say } = sec(L, K, gitti, Date.now());
  let git = 0, dus = 0;
  if (acik) {
    if (!RESEND_KEY) throw new Error('RESEND_KEY yok');
    for (const { s, kapsar } of out) {
      const m = mailKur(s);
      const r = await resend({ from: RESEND_FROM, to: [s.email], subject: m.konu, text: m.metin, html: m.html, reply_to: 'destek@tetikte.com' });
      if (r.ok) { git++; await sb('/rest/v1/form_kayit', { method: 'POST', headers: { Prefer: 'return=minimal' }, body: JSON.stringify({ konu: KAYIT, gonderen: 'motor/kart-takildi.mjs', eposta: s.email, alanlar: { siparis_no: s.siparis_no, kapsar } }) }); }
      else dus++;
      await new Promise(r => setTimeout(r, 600));
    }
  }
  console.log(`KART TAKILDI ${acik ? 'GÖNDERİM' : 'SAYIM (gönderim kapalı)'}: takılan ${say.takilan} · 30 dk'dan yeni ${say.yeni} · 24 saatten eski ${say.eski} · sınavı geçmiş ${say.sinavGecti} · sonra ödemiş ${say.sonraOdedi} · sayfada IBAN mailini almış ${say.sayfadaAldi} · zaten gitti ${say.zatenGitti} · aynı kişinin eski siparişi ${say.ayniKisi} · gidecek ${say.gidecek}`
    + (acik ? ` · gitti ${git} · düştü ${dus}` : '') + ` · metin imzası ${im}${ayar.kart_takildi_onayli_imza === im ? ' (onaylı)' : ' (ONAYSIZ)'}`);
  if (acik && dus) process.exitCode = 1;
}

function sinav() {
  let h = 0, n = 0; const b = (ad, k) => { n++; console.log((k ? '  geçti  ' : '  DÜŞTÜ  ') + ad); if (!k) h++; };
  const T = new Date('2026-10-29T12:00:00Z').getTime();
  const S = (no, ek) => Object.assign({ siparis_no: no, email: 'a@b.com', paket: 'sgs', paket_ad: 'SGS', tutar: 2388, durum: 'odeme_bekliyor', olusturma: '2026-10-29T10:00:00Z', alindi_mail: null }, ek);
  const D = (no, ek) => Object.assign({ siparis_no: no, durum: 'baslatildi', olusturma: '2026-10-29T11:00:00Z' }, ek);
  const ids = r => r.out.map(x => x.s.siparis_no).join(',');
  b('iyzico sayfasında kaldı, 1 saat önce -> gider', ids(sec([S('A')], [D('A')], new Set(), T)) === 'A');
  b('hata ile döndü (basarisiz) -> gider', ids(sec([S('A')], [D('A', { durum: 'basarisiz' })], new Set(), T)) === 'A');
  b('son deneme 30 dk\'dan yeni -> gitmez', ids(sec([S('A')], [D('A'), D('A', { olusturma: '2026-10-29T11:45:00Z' })], new Set(), T)) === '');
  b('son deneme 24 saatten eski -> gitmez', ids(sec([S('A')], [D('A', { olusturma: '2026-10-28T10:00:00Z' })], new Set(), T)) === '');
  b('kart denemesi yok (havale) -> gitmez', ids(sec([S('A')], [], new Set(), T)) === '');
  b('bir denemesi başarılı -> gitmez', ids(sec([S('A')], [D('A'), D('A', { durum: 'basarili' })], new Set(), T)) === '');
  b('ödenmiş / iptal -> gitmez', ids(sec([S('A', { durum: 'odendi' }), S('B', { durum: 'iptal', email: 'c@d.com' })], [D('A'), D('B')], new Set(), T)) === '');
  b('zaten gitti -> gitmez', ids(sec([S('A')], [D('A')], new Set(['A']), T)) === '');
  b('hata dönüşünde IBAN maili sayfada gitti -> gitmez', ids(sec([S('A', { alindi_mail: '2026-10-29T11:02:00Z' })], [D('A')], new Set(), T)) === '');
  b('IBAN maili karttan ÖNCE gitmiş -> yine gider', ids(sec([S('A', { alindi_mail: '2026-10-29T10:01:00Z' })], [D('A')], new Set(), T)) === 'A');
  b('aynı kişi sonra yeni siparişle ödemiş -> gitmez', ids(sec([S('A'), S('B', { durum: 'odendi', olusturma: '2026-10-29T11:10:00Z' })], [D('A')], new Set(), T)) === '');
  b('aynı kişinin iki takılanı -> yalnız en yenisi, ikisi kapsanır', (() => { const r = sec([S('A'), S('B', { olusturma: '2026-10-29T10:30:00Z' })], [D('A', { olusturma: '2026-10-29T10:40:00Z' }), D('B')], new Set(), T); return ids(r) === 'B' && r.out[0].kapsar.join() === 'B,A'; })());
  b('son20-sgs / son20-yet sınava bağlanır', sinavOf('son20-sgs') === 'sgs' && sinavOf('son20-yet') === 'yeterlilik' && sinavOf('yeterlilik-3') === 'yeterlilik');
  b('sınav günü geçmiş -> gitmez', ids(sec([S('A', { olusturma: '2026-11-21T08:00:00Z' })], [D('A', { olusturma: '2026-11-21T09:00:00Z' })], new Set(), new Date('2026-11-21T12:00:00Z').getTime())) === '');
  b('KGK / tanımsız paket -> gitmez', ids(sec([S('A', { paket: 'kgk-1' })], [D('A')], new Set(), T)) === '');
  const m = mailKur(ORNEKLER[0]);
  b('yeniden dene bağlantısı sipariş no ile', m.html.includes('satin-al.html?kartla=TT-20261029-ABCD') && m.metin.includes('satin-al.html?kartla=TT-20261029-ABCD'));
  b('IBAN siparis-bildirim.ts ile aynı', (() => { const t = fs.readFileSync(path.join(KOK, 'radar-app', 'edge', 'siparis-bildirim.ts'), 'utf8'); return t.includes(BANKA.iban) && t.includes(BANKA.alici); })());
  b('tutar ve sınav tarihi metinde', m.metin.includes('2.388 TL') && m.metin.includes('21 Kasım') && mailKur(ORNEKLER[1]).metin.includes('28 Kasım'));
  b('adsız siparişte "Merhaba," düz', mailKur(ORNEKLER[1]).metin.startsWith('Merhaba,'));
  b('metinde "yapay zek" / "Claude" yok', ORNEKLER.every(s => !/yapay zek|claude/i.test(mailKur(s).metin)));
  b('imza metinle değişir', (() => { const i1 = imza(); const e = BANKA.ad; BANKA.ad = 'X'; const i2 = imza(); BANKA.ad = e; return i1 !== i2; })());
  console.log(`KART TAKILDI öz-sınav: ${n - h}/${n}`); process.exitCode = h ? 1 : 0;
}
if (process.argv[1] && process.argv[1].endsWith('kart-takildi.mjs')) {
  if (process.argv.includes('--sinav')) sinav(); else ana().catch(e => { console.log('KART TAKILDI HATA: ' + e.message); process.exitCode = 1; });
}
