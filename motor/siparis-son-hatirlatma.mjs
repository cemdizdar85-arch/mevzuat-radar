#!/usr/bin/env node
/* ============================================================================
 *  SON HATIRLATMA + OTOMATİK İPTAL (29.10.2026, Cem: "büyük firmalar ne yapıyorsa onu yap, ödeme sorunu / bekleyen
 *  istemiyorum, mail filan benden gitmesin" → seçim "Robot mail + otomatik iptal")
 *
 *  NEDEN (29.10 ölçüldü, siparisler, yalnız sayım): ödeme bekleyen 25 havale siparişi vardı, en eskisi 07.10. Kişiye
 *  3 saatte bir hatırlatma (motor/havale-hatirlatma.mjs) ve kart takıldıysa bir mail (motor/kart-takildi.mjs) gidiyordu,
 *  sonra hiçbir şey; sipariş süresiz "ödeme bekliyor"da kalıyordu. Cem bekleyenlere elle WhatsApp atmak istemedi.
 *
 *  1) SON HATIRLATMA: durum = odeme_bekliyor · odeme = havale · en az 24 saat önce açılmış · paketin sınavı geçmemiş ·
 *     aynı e-postayla SONRA ödenmiş sipariş yok · paketi zaten açık değil · son 12 saatte bu siparişe başka hatırlatma
 *     (havale / kart takıldı) gitmemiş. Bir e-postanın birden çok bekleyeni varsa yalnız en yenisine mail, hepsi kapsanır.
 *     Her sipariş ömründe BİR kez. İçerik: tek bağlantı satin-al.html?ode=<no>&t=<tutar> ("Siparişini tamamla" sayfası:
 *     kart düğmesi + açık havale bilgisi) + iptal günü. KAYIT: form_kayit "Son hatırlatma gönderildi" {siparis_no, kapsar, iptal}.
 *  2) OTOMATİK İPTAL: durum = odeme_bekliyor · en az 72 saat önce açılmış · ve şunlardan biri:
 *       a) son hatırlatması (kapsar) en az 24 saat önce gitmiş,
 *       b) aynı e-postayla sonra ödenmiş sipariş var ya da paketi zaten açık (mail gerekmez, kişi ödemiş).
 *     Sınavı geçmiş ama son hatırlatma almamış sipariş İPTAL EDİLMEZ (habersiz iptal yok). İptal rpc
 *     siparis_otomatik_iptal (radar-app/sql/2026-10-29-otomatik-iptal.sql): durum 'iptal', iptal_neden 'otomatik'.
 *     Geç gelen havale: yönetim paneli "Ödendi, paketi aç" otomatik iptal edilmiş siparişte de çalışır (aynı SQL).
 *  ⛔ ONAYSIZ GÖNDERMEZ / İPTAL ETMEZ: arac/hatirlatma-ayar.json son_hatirlatma_acik = true VE son_hatirlatma_onayli_imza
 *     = bugünkü metin imzası (--imza); iptal ayrıca otomatik_iptal_acik = true. Kapalıyken yalnız SAYI.
 *  ⛔ GÜNLÜK PUBLIC: e-posta/ad/sipariş no basılmaz, yalnız sayı.
 *  🚫 GÖRMEZ: havalenin bankaya gelip panelde henüz "ödendi" yapılmamış olması (metin "ödemeyi yaptıysan dikkate alma"
 *     der; iptal edilse de panelden açılır) · kişinin başka e-postayla ödemiş olması · Resend'in kutuya teslimi.
 *
 *  Kullanım: node motor/siparis-son-hatirlatma.mjs [--kuru] · --ornek <klasör> · --imza · --sinav · --deneme (yalnız Cem'e)
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
const SAAT = 36e5;
export const KAYIT = 'Son hatırlatma gönderildi';
const DIGER = ['Havale hatırlatması gönderildi', 'Kart takıldı maili gönderildi'];
export const ESIK = { mail: 24 * SAAT, sessiz: 12 * SAAT, iptalYas: 72 * SAAT, iptalSonra: 24 * SAAT };
const kac = s => String(s == null ? '' : s).replace(/[&<>"]/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
const tl = n => Number(n || 0).toLocaleString('tr-TR') + ' TL';
const tarih = d => new Date(d).toLocaleDateString('tr-TR', { timeZone: 'Europe/Istanbul', day: 'numeric', month: 'long' });
const DUGME = 'background:#f5a524;color:#1b1206;text-decoration:none;font-weight:800;padding:12px 20px;border-radius:8px;display:inline-block';
const NEDEN = "Bu e-posta, tetikte.com'da verdiğin sipariş üzerine gönderilmiştir.";
export const sinavOf = paket => /^sgs/.test(paket) ? 'sgs' : /^yeterlilik/.test(paket) ? 'yeterlilik' : null;
/* iptal günü: mailden en az 24 saat ve siparişten en az 72 saat sonra; robot 15 dakikada bir koştuğu için o günün sonu */
export const iptalAni = (s, simdi) => new Date(Math.max(+simdi + ESIK.iptalSonra, +new Date(s.olusturma) + ESIK.iptalYas));

/* s: { siparis_no, ad_soyad, paket, paket_ad, tutar, olusturma }, iptal: Date, guncel: false = sipariş tutarı bugünkü
   fiyatla aynı değil (eski fiyatla açılmış: kartla ödeme iyzico'da "tutar guncel fiyatla uyusmuyor" der, havalede de
   eski tutar ödenirdi) → "yeniden sipariş ver" metni, tutar yazılmaz */
export function mailKur(s, iptal, guncel = true) {
  const ad = String(s.ad_soyad || '').trim().split(/\s+/)[0] || '';
  const S = SINAVLAR[sinavOf(s.paket)] || null;
  const link = guncel ? `${SITE}/satin-al.html?ode=${encodeURIComponent(s.siparis_no)}&t=${Math.round(Number(s.tutar) || 0)}&k=mail-son`
                      : `${SITE}/satin-al.html?k=mail-son-fiyat`;
  const gun = tarih(iptal);
  const konu = `Siparişin ${gun} günü iptal olacak: ${s.siparis_no}`;
  const p1 = guncel ? `${tarih(s.olusturma)} tarihinde verdiğin ${s.paket_ad || s.paket} siparişinin (${s.siparis_no}, ${tl(s.tutar)}) ödemesi henüz bize ulaşmadı.`
                    : `${tarih(s.olusturma)} tarihinde verdiğin ${s.paket_ad || s.paket} siparişinin (${s.siparis_no}) ödemesi henüz bize ulaşmadı.`;
  const p2 = guncel ? "Siparişini aşağıdaki bağlantıdan tamamlayabilirsin. Kartla ödersen paketin hemen açılır; havale bilgisi de aynı sayfada."
                    : "Bu siparişten sonra paket fiyatları güncellendi; bu yüzden eski siparişin için ödeme yapma. Güncel fiyatı görmek ve paketini almak için aşağıdaki bağlantıdan yeniden sipariş ver; kartla ödersen paketin hemen açılır.";
  const dugme = guncel ? 'Siparişini tamamla' : 'Güncel fiyattan sipariş ver';
  const p3 = guncel ? `${gun} gününe kadar ödeme gelmezse sipariş kendiliğinden iptal olur; dilediğin zaman yeniden sipariş verebilirsin. Ödemeyi yaptıysan bu e-postayı dikkate alma, havaleyi gördüğümüz gün paketin açılır.`
                    : `Eski sipariş ${gun} günü kendiliğinden iptal olur. Ödemeyi zaten yaptıysan bu e-postayı dikkate alma, havaleyi gördüğümüz gün paketin açılır.`;
  const p4 = (S ? `${S.ad} sınavı ${S.tarihYazi}'da. ` : '') + "Takıldığın bir yer varsa bu e-postayı yanıtla ya da WhatsApp'tan yaz: 0532 344 80 58.";
  const metin = [`Merhaba${ad ? ' ' + ad : ''},`, '', p1, '', p2, `${dugme}: ${link}`, '', p3, '', p4, '', 'Sınava tetikte gir.'].join('\n');
  const html = kurumsalMail(`<p>Merhaba${ad ? ' ' + kac(ad) : ''},</p>
<p>${kac(p1)}</p>
<p>${kac(p2)}</p>
<p style="margin:4px 0 18px"><a href="${kac(link)}" style="${DUGME}">${kac(dugme)} →</a></p>
<p style="color:#3d4b63">${kac(p3)}</p>
<p style="color:#3d4b63">${kac(p4)}</p>`, NEDEN);
  return { konu, metin, html };
}

const ORNEKLER = [
  { siparis_no: 'TT-20261019-ABCD', ad_soyad: 'Ayşe Örnek', paket: 'yeterlilik-1', paket_ad: 'Yeterlilik — 1 ders', tutar: 1188, olusturma: '2026-10-19T13:57:00Z' },
  { siparis_no: 'TT-20261008-EFHJ', ad_soyad: '', paket: 'sgs', paket_ad: 'Staja Giriş — soru bankası', tutar: 2388, olusturma: '2026-10-08T21:51:00Z' },
];
const ORNEK_IPTAL = new Date('2026-10-31T09:00:00Z');
export function imza() {
  const t = ORNEKLER.flatMap(s => [true, false].map(g => { const m = mailKur(s, ORNEK_IPTAL, g); return m.konu + m.metin; })).join('|');
  return crypto.createHash('sha256').update(t).digest('hex').slice(0, 16);
}

/* seçim: saf işlev, öz-sınavlı.
   L = siparisler · son = Map(siparis_no -> son hatırlatma zamanı) · diger = Map(siparis_no -> en yeni öteki hatırlatma zamanı)
   acik = Set(siparis_no) paketi başka yoldan açık. Dönen: { mail: [{ s, kapsar }], iptal: [no], say } */
export function sec(L, son, diger, acik, simdi) {
  const say = { bekleyen: 0, yeni: 0, sinavGecti: 0, odemis: 0, zatenGitti: 0, sessiz: 0, ayniKisi: 0, mail: 0, iptal: 0, iptalBekler: 0 };
  const odenen = L.filter(x => x.durum === 'odendi');
  const aday = new Map(), iptal = [];
  for (const s of L) {
    if (s.durum !== 'odeme_bekliyor' || s.odeme !== 'havale') continue;
    say.bekleyen++;
    const yas = simdi - new Date(s.olusturma);
    const e = String(s.email || '').toLowerCase();
    const odemis = acik.has(s.siparis_no) || (!!e && odenen.some(o => String(o.email || '').toLowerCase() === e && new Date(o.olusturma) >= new Date(s.olusturma)));
    const sonZ = son.get(s.siparis_no);
    if (yas >= ESIK.iptalYas && (odemis || (sonZ && simdi - sonZ >= ESIK.iptalSonra))) { iptal.push(s.siparis_no); continue; }
    if (sonZ) { say.zatenGitti++; if (yas >= ESIK.iptalYas) say.iptalBekler++; continue; }
    if (odemis) { say.odemis++; continue; }
    if (yas < ESIK.mail) { say.yeni++; continue; }
    const S = SINAVLAR[sinavOf(s.paket)];
    if (!S || simdi >= new Date(S.tarih + 'T00:00:00+03:00')) { say.sinavGecti++; continue; }
    if (!e) continue;
    const dz = diger.get(s.siparis_no);
    if (dz && simdi - dz < ESIK.sessiz) { say.sessiz++; continue; }
    (aday.get(e) || aday.set(e, []).get(e)).push(s);
  }
  const mail = [];
  for (const L2 of aday.values()) {
    L2.sort((a, b) => new Date(b.olusturma) - new Date(a.olusturma));
    say.ayniKisi += L2.length - 1;
    mail.push({ s: L2[0], kapsar: L2.map(x => x.siparis_no) });
  }
  say.mail = mail.length; say.iptal = iptal.length;
  return { mail, iptal, say };
}

/* bugünkü tutar — radar-app/edge/iyzico-odeme.ts ?islem=baslat ile AYNI hesap (fiyatlar + paketFiyat + kurucu_sayac taban +
   indirim kolonları). F = { FIYAT, KOTA }, satilan = { sinav: adet }. Paket kartla satılmıyorsa null. */
export function paketFiyat(F, paket) {
  if (paket === 'sgs') return { f: F.sgs, sinav: 'sgs' };
  const m = String(paket).match(/^yeterlilik-([1-4])$/); if (m) return { f: F.yeterlilik[+m[1]], sinav: 'yeterlilik' };
  if (paket === 'yeterlilik-tum') return { f: F.yeterlilikTum, sinav: 'yeterlilik' };
  if (paket === 'son20-sgs') return { f: F.son20Sgs, sinav: 'son20' };
  if (paket === 'son20-yet') return { f: F.son20Yet, sinav: 'son20' };
  return null;
}
export function guncelTutar(s, F, satilan) {
  const pf = F && paketFiyat(F.FIYAT, s.paket); if (!pf || !pf.f) return null;
  const taban = (satilan[pf.sinav] ?? 0) >= (F.KOTA[pf.sinav] ?? 0) ? pf.f.liste : pf.f.kurulus;
  return taban - (Number(s.indirim_tl) || 0) - (Number(s.anlik_teklif_tl) || 0) - (Number(s.ozel_kod_tl) || 0);
}
/* bugün YENİ sipariş verse ödeyeceği tutar: taban, erken kayıt süresindeyse sitenin erkenNet'i (fiyat-motoru.js; satin-al
   kodu kendiliğinden uygular). Eski siparişi bundan pahalıysa "tamamla" değil "yeniden sipariş ver" denir (29.10: 07–21.10
   SGS siparişleri 2.988 TL, bugün yeni sipariş 2.388 TL). */
export function yeniTutar(s, F, satilan) {
  const pf = F && paketFiyat(F.FIYAT, s.paket); if (!pf || !pf.f) return null;
  const taban = (satilan[pf.sinav] ?? 0) >= (F.KOTA[pf.sinav] ?? 0) ? pf.f.liste : pf.f.kurulus;
  const en = typeof F.erkenNet === 'function' ? Number(F.erkenNet({ id: s.paket, fiyat: taban })) || 0 : 0;
  return en > 0 ? en : taban;
}
/* "Siparişini tamamla" yalnız: kartla ödeme kabul edilir (iyzico ile aynı tutar) VE yeni siparişten pahalı değil */
export const tamamlanir = (s, F, satilan) => guncelTutar(s, F, satilan) === Number(s.tutar) && Number(s.tutar) <= (yeniTutar(s, F, satilan) ?? -1);
/* sitenin kendi fiyat dosyası yalıtılmış bağlamda koşturulur: FIYAT, KOTA, erkenNet sayfanın gördüğüyle aynı */
async function fiyatlar() {
  const js = await (await fetch(`${SITE}/fiyat-motoru.js?_=${Date.now()}`)).text();
  const { default: vm } = await import('node:vm');
  const bos = () => null, ctx = { console: { log() {}, warn() {}, error() {} }, Date, Math, JSON, location: { search: '', href: '' }, navigator: {},
    localStorage: { getItem: bos, setItem() {} }, document: { addEventListener() {}, querySelector: bos, querySelectorAll: () => [], getElementById: bos, readyState: 'complete' } };
  ctx.window = ctx; ctx.self = ctx;
  vm.runInNewContext(js, ctx, { timeout: 3000 });
  if (!ctx.FIYAT || !ctx.KOTA || typeof ctx.erkenNet !== 'function') throw new Error('FIYAT_OKUNAMADI');
  return { FIYAT: ctx.FIYAT, KOTA: ctx.KOTA, erkenNet: ctx.erkenNet };
}

async function sb(yol, sec2 = {}) {
  const r = await fetch(SB + yol, { ...sec2, headers: { apikey: SK, Authorization: 'Bearer ' + SK, 'Content-Type': 'application/json', ...(sec2.headers || {}) } });
  if (!r.ok) throw new Error(yol.split('?')[0] + ' http ' + r.status); return sec2.method === 'POST' && !sec2.cevap ? null : r.json();
}
async function hepsi(yol) { const o = []; for (let i = 0; ; i += 1000) { const p = await sb(yol + `&limit=1000&offset=${i}`); o.push(...p); if (p.length < 1000) return o; } }
async function resend(govde) {
  return fetch('https://api.resend.com/emails', { method: 'POST', headers: { Authorization: 'Bearer ' + RESEND_KEY, 'Content-Type': 'application/json' }, body: JSON.stringify(govde) });
}
/* form_kayit -> Map(no -> en yeni zaman); kapsar varsa hepsi */
function zamanlar(K) {
  const m = new Map();
  for (const x of K) for (const no of ((x.alanlar || {}).kapsar || [(x.alanlar || {}).siparis_no]).filter(Boolean)) {
    const z = new Date(x.olusturma); if (!m.has(no) || m.get(no) < z) m.set(no, z);
  }
  return m;
}

async function ana() {
  if (process.argv.includes('--imza')) { console.log(imza()); return; }
  const ornek = arg('--ornek');
  if (ornek) {
    fs.mkdirSync(ornek, { recursive: true });
    ORNEKLER.forEach((s, i) => [true, false].forEach(g => { const m = mailKur(s, ORNEK_IPTAL, g), ad = `${i + 1}-son${g ? '' : '-eski-fiyat'}`; fs.writeFileSync(path.join(ornek, ad + '.html'), `<!-- Konu: ${m.konu} -->\n` + m.html); fs.writeFileSync(path.join(ornek, ad + '.txt'), 'Konu: ' + m.konu + '\n\n' + m.metin); console.log(ad + ': ' + m.konu); }));
    console.log('imza: ' + imza()); return;
  }
  if (process.argv.includes('--deneme')) {   /* örnekler YALNIZ ALARM_ALICI'ya, "[DENEME]" konulu; kayıt yazılmaz */
    if (!RESEND_KEY) throw new Error('RESEND_KEY yok');
    let n = 0;
    for (const g of [true, false]) { const m = mailKur(ORNEKLER[0], ORNEK_IPTAL, g); if ((await resend({ from: RESEND_FROM, to: [ALARM], subject: '[DENEME] ' + m.konu, text: m.metin, html: m.html, reply_to: 'destek@tetikte.com' })).ok) n++; await new Promise(r => setTimeout(r, 600)); }
    console.log(`DENEME: ${n}/2 mail Cem'e gitti`); if (n < 2) process.exitCode = 1; return;
  }
  if (!SK) throw new Error('SUPABASE_SERVICE_KEY yok');
  const ayar = JSON.parse(fs.readFileSync(path.join(KOK, 'arac', 'hatirlatma-ayar.json'), 'utf8'));
  const kuru = process.argv.includes('--kuru'), im = imza();
  const mailAcik = !kuru && ayar.son_hatirlatma_acik === true && ayar.son_hatirlatma_onayli_imza === im;
  const iptalAcik = !kuru && mailAcik && ayar.otomatik_iptal_acik === true;
  const simdi = new Date();
  const L = await hepsi('/rest/v1/siparisler?select=siparis_no,ad_soyad,email,paket,paket_ad,tutar,indirim_tl,anlik_teklif_tl,ozel_kod_tl,durum,odeme,olusturma&order=olusturma.asc');
  /* fiyat okunamazsa bu koşuda mail GİTMEZ (yanlış tutarla "tamamla" demektense bekle); iptal yine sayılır */
  let F = null, satilan = {};
  try { F = await fiyatlar(); const k = await (await fetch(SB + '/rest/v1/rpc/kurucu_sayac', { method: 'POST', headers: { apikey: SK, Authorization: 'Bearer ' + SK, 'Content-Type': 'application/json' }, body: '{}' })).json(); for (const x of (Array.isArray(k) ? k : [])) satilan[x.sinav] = x.satilan; }
  catch (e) { F = null; }
  const son = zamanlar(await hepsi(`/rest/v1/form_kayit?select=alanlar,olusturma&konu=eq.${encodeURIComponent(KAYIT)}&order=olusturma.asc`));
  const diger = zamanlar(await hepsi(`/rest/v1/form_kayit?select=alanlar,olusturma&konu=in.(${encodeURIComponent(DIGER.map(k => '"' + k + '"').join(','))})&order=olusturma.asc`));
  /* 21.10 çift ödeme kapısı: paketi başka yoldan açık kişi (siparis_odeme_kontrol). Okunamazsa "açık değil" sayılır. */
  const acik = new Set();
  for (const s of L) {
    if (s.durum !== 'odeme_bekliyor' || s.odeme !== 'havale' || simdi - new Date(s.olusturma) < ESIK.mail) continue;
    try { const r = await fetch(SB + '/rest/v1/rpc/siparis_odeme_kontrol', { method: 'POST', headers: { apikey: SK, Authorization: 'Bearer ' + SK, 'Content-Type': 'application/json' }, body: JSON.stringify({ p_no: s.siparis_no }) }); if (r.ok && (await r.json()) === 'PAKET_ZATEN_ACIK') acik.add(s.siparis_no); } catch (e) { /* açık değil say */ }
  }
  const { mail, iptal, say } = sec(L, son, diger, acik, simdi);
  let git = 0, dus = 0, ipt = 0;
  say.eskiFiyat = mail.filter(x => F && !tamamlanir(x.s, F, satilan)).length;
  if (mailAcik && !F) console.log('SON HATIRLATMA: fiyat okunamadı, bu koşuda mail yok');
  if (mailAcik && F) {
    if (!RESEND_KEY) throw new Error('RESEND_KEY yok');
    for (const { s, kapsar } of mail) {
      const ia = iptalAni(s, simdi), m = mailKur(s, ia, tamamlanir(s, F, satilan));
      const r = await resend({ from: RESEND_FROM, to: [s.email], subject: m.konu, text: m.metin, html: m.html, reply_to: 'destek@tetikte.com' });
      if (r.ok) { git++; await sb('/rest/v1/form_kayit', { method: 'POST', headers: { Prefer: 'return=minimal' }, body: JSON.stringify({ konu: KAYIT, gonderen: 'motor/siparis-son-hatirlatma.mjs', eposta: s.email, alanlar: { siparis_no: s.siparis_no, kapsar, iptal: ia.toISOString() } }) }); }
      else dus++;
      await new Promise(r => setTimeout(r, 600));
    }
  }
  if (iptalAcik && iptal.length) {
    const r = await sb('/rest/v1/rpc/siparis_otomatik_iptal', { method: 'POST', cevap: true, body: JSON.stringify({ p_nolar: iptal }) });
    ipt = Number(r) || 0;
  }
  const ozet = `SON HATIRLATMA ${mailAcik ? 'GÖNDERİM' : 'SAYIM (gönderim kapalı)'} · İPTAL ${iptalAcik ? 'AÇIK' : 'KAPALI'}: bekleyen havale ${say.bekleyen} · 24 saatten yeni ${say.yeni} · sınavı geçmiş ${say.sinavGecti} · ödemiş/paketi açık ${say.odemis} · son hatırlatma gitmiş ${say.zatenGitti} (iptal sırası bekleyen ${say.iptalBekler}) · 12 saatte başka mail almış ${say.sessiz} · aynı kişinin eski siparişi ${say.ayniKisi} · mail gidecek ${say.mail} (eski fiyatlı, "yeniden sipariş ver" ${F ? say.eskiFiyat : 'FİYAT OKUNAMADI'}) · iptal edilecek ${say.iptal}` + (mailAcik ? ` · gitti ${git} · düştü ${dus}` : '') + (iptalAcik ? ` · iptal edildi ${ipt}` : '') + ` · metin imzası ${im}${ayar.son_hatirlatma_onayli_imza === im ? ' (onaylı)' : ' (ONAYSIZ)'}`;
  console.log(ozet);
  if ((mailAcik && dus) || (iptalAcik && ipt !== iptal.length)) process.exitCode = 1;
}

function sinav() {
  let h = 0, n = 0; const b = (ad, k) => { n++; console.log((k ? '  geçti  ' : '  DÜŞTÜ  ') + ad); if (!k) h++; };
  const T = new Date('2026-10-29T12:00:00Z'), once = saat => new Date(+T - saat * SAAT).toISOString();
  const S = (no, ek) => Object.assign({ siparis_no: no, email: 'a@b.com', paket: 'sgs', paket_ad: 'SGS', tutar: 2388, durum: 'odeme_bekliyor', odeme: 'havale', olusturma: once(30) }, ek);
  const M = o => new Map(Object.entries(o || {}).map(([k, v]) => [k, new Date(+T - v * SAAT)]));
  const r = (L, son, diger, acik, t) => sec(L, M(son), M(diger), new Set(acik || []), t || T);
  const mi = x => x.mail.map(y => y.s.siparis_no).join(','), ii = x => x.iptal.join(',');
  b('24 saatten eski bekleyen -> son hatırlatma', mi(r([S('A')])) === 'A');
  b('24 saatten yeni -> gitmez', mi(r([S('A', { olusturma: once(20) })])) === '');
  b('kart / ödenmiş / iptal -> gitmez', mi(r([S('A', { odeme: 'kart' }), S('B', { durum: 'odendi', email: 'x@y.com' }), S('C', { durum: 'iptal', email: 'z@y.com' })])) === '');
  b('son hatırlatma zaten gitmiş -> ikinci gitmez', mi(r([S('A')], { A: 2 })) === '');
  b('12 saatte başka hatırlatma almış -> bekler', mi(r([S('A')], {}, { A: 3 })) === '' && mi(r([S('A')], {}, { A: 13 })) === 'A');
  b('aynı kişi sonra ödemiş -> mail yok', mi(r([S('A'), S('B', { durum: 'odendi', odeme: 'kart', olusturma: once(29) })])) === '');
  b('paketi başka yoldan açık -> mail yok', mi(r([S('A')], {}, {}, ['A'])) === '');
  b('aynı kişinin iki bekleyeni -> yalnız en yenisi, ikisi kapsanır', (() => { const x = r([S('A', { olusturma: once(100) }), S('B')]); return mi(x) === 'B' && x.mail[0].kapsar.join() === 'B,A'; })());
  b('sınav günü geçmiş -> mail yok, iptal de yok', (() => { const x = r([S('A', { olusturma: once(80) })], {}, {}, [], new Date('2026-11-21T12:00:00Z')); return mi(x) === '' && ii(x) === ''; })());
  b('KGK / tanımsız paket -> mail yok', mi(r([S('A', { paket: 'kgk-1' })])) === '');
  b('72 saat + son hatırlatma 24 saat önce -> iptal', ii(r([S('A', { olusturma: once(80) })], { A: 25 })) === 'A');
  b('72 saat ama son hatırlatma 24 saatten yeni -> iptal YOK', ii(r([S('A', { olusturma: once(80) })], { A: 10 })) === '');
  b('son hatırlatma 24 saat önce ama sipariş 72 saatten yeni -> iptal YOK', ii(r([S('A', { olusturma: once(50) })], { A: 30 })) === '');
  b('72 saatlik, son hatırlatma HİÇ gitmemiş -> iptal yok, önce mail', (() => { const x = r([S('A', { olusturma: once(200) })]); return ii(x) === '' && mi(x) === 'A'; })());
  b('72 saatlik, kişi sonra ödemiş -> mailsiz iptal', (() => { const x = r([S('A', { olusturma: once(80) }), S('B', { durum: 'odendi', odeme: 'kart', olusturma: once(79) })]); return ii(x) === 'A' && mi(x) === ''; })());
  b('72 saatlik, paketi açık -> mailsiz iptal', ii(r([S('A', { olusturma: once(80) })], {}, {}, ['A'])) === 'A');
  b('kapsanan eski sipariş de iptal olur', ii(r([S('A', { olusturma: once(100) })], { A: 30 })) === 'A');
  b('iptal günü: mailden 24 sa, siparişten 72 sa sonra', +iptalAni({ olusturma: once(30) }, T) === +T + 42 * SAAT && +iptalAni({ olusturma: once(200) }, T) === +T + 24 * SAAT);
  const m = mailKur(ORNEKLER[0], ORNEK_IPTAL);
  b('bağlantı ?ode=<no>&t=<tutar>', m.html.includes('satin-al.html?ode=TT-20261019-ABCD&amp;t=1188') && m.metin.includes('satin-al.html?ode=TT-20261019-ABCD&t=1188'));
  b('iptal günü konuda ve metinde', m.konu.includes('31 Ekim') && m.metin.includes('31 Ekim gününe kadar'));
  b('tutar ve sınav tarihi metinde', m.metin.includes('1.188 TL') && m.metin.includes('28 Kasım'));
  b('adsız siparişte "Merhaba," düz', mailKur(ORNEKLER[1], ORNEK_IPTAL).metin.startsWith('Merhaba,'));
  const e = mailKur(ORNEKLER[0], ORNEK_IPTAL, false);
  b('eski fiyatlı: tutar yok, ?ode yok, "yeniden sipariş ver"', !e.metin.includes('1.188') && !e.metin.includes('?ode=') && e.metin.includes('yeniden sipariş ver') && e.metin.includes('satin-al.html?k=mail-son-fiyat'));
  const F = { FIYAT: { sgs: { kurulus: 2388, liste: 2988 }, yeterlilik: { 1: { kurulus: 1068, liste: 1188 } }, yeterlilikTum: { kurulus: 2868, liste: 3468 } }, KOTA: { sgs: 1000, yeterlilik: 1000 } };
  b('güncel tutar: taban - indirimler', guncelTutar({ paket: 'sgs' }, F, {}) === 2388 && guncelTutar({ paket: 'yeterlilik-1', indirim_tl: 100 }, F, {}) === 968 && guncelTutar({ paket: 'yeterlilik-tum', ozel_kod_tl: 68 }, F, {}) === 2800);
  b('kota dolunca liste fiyatı', guncelTutar({ paket: 'sgs' }, F, { sgs: 1000 }) === 2988 && guncelTutar({ paket: 'sgs' }, F, { sgs: 999 }) === 2388);
  b('kartla satılmayan paket -> null', guncelTutar({ paket: 'kgk-1' }, F, {}) === null);
  const FE = Object.assign({}, F, { FIYAT: Object.assign({}, F.FIYAT, { sgs: { kurulus: 2988, liste: 5988 } }), erkenNet: p => p.id === 'sgs' ? p.fiyat - 600 : 0 });
  b('erken kayıtta eski 2.988 sipariş -> "yeniden sipariş ver"', !tamamlanir({ paket: 'sgs', tutar: 2988 }, FE, {}) && yeniTutar({ paket: 'sgs' }, FE, {}) === 2388);
  b('erken kayıtla açılmış 2.388 (indirim 600) -> "tamamla"', tamamlanir({ paket: 'sgs', tutar: 2388, indirim_tl: 600 }, FE, {}));
  b('erken indirimsiz pakette taban -> "tamamla"', tamamlanir({ paket: 'yeterlilik-tum', tutar: 2868 }, F, {}) && yeniTutar({ paket: 'yeterlilik-tum' }, F, {}) === 2868);
  b('iyzico kabul etmeyen tutar -> "tamamla" değil', !tamamlanir({ paket: 'sgs', tutar: 2000 }, F, {}));
  b('hesap iyzico-odeme.ts ile aynı formül', (() => { const t = fs.readFileSync(path.join(KOK, 'radar-app', 'edge', 'iyzico-odeme.ts'), 'utf8'); return t.includes('const beklenen = taban - (Number(s.indirim_tl) || 0) - (Number(s.anlik_teklif_tl) || 0) - (Number(s.ozel_kod_tl) || 0);') && t.includes('satilan >= (F.KOTA[pf.sinav] ?? 0) ? pf.f.liste : pf.f.kurulus'); })());
  b('metinde "yapay zek" / "Claude" yok', ORNEKLER.every(s => [true, false].every(g => !/yapay zek|claude/i.test(mailKur(s, ORNEK_IPTAL, g).metin))));
  b('imza metinle değişir', (() => { const i1 = imza(); const e = ORNEKLER[0].tutar; ORNEKLER[0].tutar = 9; const i2 = imza(); ORNEKLER[0].tutar = e; return i1 !== i2; })());
  console.log(`SON HATIRLATMA öz-sınav: ${n - h}/${n}`); process.exitCode = h ? 1 : 0;
}
if (process.argv[1] && process.argv[1].endsWith('siparis-son-hatirlatma.mjs')) {
  if (process.argv.includes('--sinav')) sinav(); else ana().catch(e => { console.log('SON HATIRLATMA HATA: ' + e.message); process.exitCode = 1; });
}
