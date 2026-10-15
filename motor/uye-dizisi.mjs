#!/usr/bin/env node
/* ============================================================================
 *  YENİ ÜYE DİZİSİ (16.10.2026, Cem: "üye çekemiyoruz" → "2 ve 3 yap")
 *
 *  NEDEN (16.10 ölçüldü, auth admin + paket_uyeler + siparisler, yalnız sayım): 08.10'dan beri 59 hesap açıldı;
 *  17'sinde paket var ama 13'ü elçi hediyesi, ödenen sipariş 4. Paketsiz üyeye hesap açtıktan sonra HİÇBİR mail
 *  gitmiyordu (hatirlatma-dizisi.mjs yalnız seviye testi karnesi olana gider; 59 hesabın 6'sında karne var).
 *
 *  TAKVİM (paketsiz, e-postası doğrulanmış, izinli üye; hesap açılış gününe göre):
 *    uye1  1-2. gün   "Hesabın hazır: bugün 5 soru"             → ana sayfa (tek düğme)
 *    uye3  3-5. gün   karnesi varsa en zayıf grubu (→ fiyat.html), yoksa seviye testi (→ seviye-testi.html)
 *    uye7  7-10. gün  "Sınava N gün kaldı: bütün sorular paketle açılır" → fiyat.html
 *  Her tür kişiye bir kez; koşuda kişi başına en çok 1 mail; son 3 günde (bu dizi YA DA hatırlatma dizisi) mail
 *  gittiyse hiç. Paket alan diziden çıkar. Sınav günü (SGS 21.11) ve sonrası gönderilmez.
 *
 *  KİME: yalnız İZİN VERENLER — hesap açarken rıza kutusu (user_metadata.pazarlama_rizasi = true: "Sınav hatırlatmaları
 *    ve Tetikte duyuruları için e-posta…") YA DA seviye karnesinde "Kampanya/hatırlatma izni" = "evet".
 *  ÇIKIŞ: hatırlatma dizisiyle AYNI tek tık bağlantı + aynı ret tablosu (bir yerden çıkan ikisinden de çıkar).
 *  ⛔ ONAYSIZ GÖNDERMEZ: arac/hatirlatma-ayar.json uye_acik = true VE uye_onayli_imza = bugünkü metin imzası
 *    (node motor/uye-dizisi.mjs --imza). Metin değişince imza değişir, gönderim kendiliğinden SAYIMA döner.
 *  ⛔ GÜNLÜK PUBLIC: e-posta/ad basılmaz, yalnız sayı. Her gönderim form_kayit "Hatırlatma gönderildi" {tur, sinav:'uye'}.
 *  🚫 GÖRMEZ: üyenin hangi sınava hazırlandığı (hesapta alan yok; karnesi yoksa iki sınav birlikte anılır) · sitede kaç
 *    soru çözdüğü (çözüm kaydı hesaba bağlı okunmuyor) · İYS kaydının kapsamı (hukuk tarafı Cem'de).
 *
 *  Kullanım: node motor/uye-dizisi.mjs [--kuru] · --ornek <klasör> · --imza · --sinav · --deneme (yalnız Cem'e)
 * ==========================================================================*/
import { kurumsalMail } from '../radar-app/edge/karne-gonder.ts';
import { SINAVLAR, jeton, zayifGrup } from './hatirlatma-dizisi.mjs';
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
const GUN = 864e5, TURLER = ['uye1', 'uye3', 'uye7'];
const buyuk = s => String(s).replace(/i/g, 'İ').toUpperCase();
const kac = s => String(s == null ? '' : s).replace(/[&<>"]/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
const DUGME = 'background:#f5a524;color:#1b1206;text-decoration:none;font-weight:800;padding:11px 18px;border-radius:8px;display:inline-block';
const NEDEN = 'Bu e-postayı, Tetikte hesabını açarken sınav hatırlatmalarına ve duyurulara izin verdiğin için aldın.';
const kalanGun = (sinav, simdi) => Math.max(0, Math.round((new Date(SINAVLAR[sinav].tarih + 'T00:00:00+03:00') - simdi) / GUN));

/* k: { sinav: 'sgs'|'yeterlilik'|null, zayif } · simdi: Date (imza için sabitlenebilir) */
export function mailKur(tur, k, e, simdi = new Date()) {
  const S = k.sinav ? SINAVLAR[k.sinav] : null;
  const sinavCumle = S ? `${S.tarihYazi}'daki ${S.ad} sınavına ${kalanGun(k.sinav, simdi)} gün kaldı.`
    : `Staja Giriş sınavına ${kalanGun('sgs', simdi)} gün, Yeterlilik sınavına ${kalanGun('yeterlilik', simdi)} gün kaldı.`;
  const ret = `${SITE}/hatirlatma-ret.html?t=${jeton(e || '')}`;
  let konu, bas, govde, dugme, href;
  /* metindeki her ürün cümlesi sitedeki metne dayanır (ogrenci.html "Ücretsiz hesap aç: yanlış yaptığın sorular, test ve
     deneme sonuçların kaydedilir…"); ölçülmemiş özellik yazılmaz. Bağlantılar ?k=mail-<tür> taşır (kaynak tablosu). */
  if (tur === 'uye1') {
    konu = 'Hesabın hazır: bugün 5 soruyla başla'; bas = 'Hesabın hazır';
    govde = [sinavCumle + ' En iyi başlangıç bugün birkaç soru çözmek; 5 soru yaklaşık 10 dakika.',
      'Yanlış yaptığın sorular, test ve deneme sonuçların hesabına kaydedilir; telefondan da bilgisayardan da kaldığın yerden devam edersin.'];
    dugme = '5 soru çöz →'; href = `${SITE}/?k=mail-uye1`;
  } else if (tur === 'uye3') {
    if (k.zayif) {
      konu = `En çok soruyu ${k.zayif} grubunda kaybettin`; bas = 'Zayıf yerin belli';
      govde = [`Seviye testinde en çok soruyu ${k.zayif} grubunda kaybettin. Sınavda da puan en çok orada gider.`,
        'Bu grubun bütün soruları paketle açılır. Hangi paketin sana uyduğunu, fiyatları ve ödeme yollarını tek sayfada gör.'];
      dugme = 'Paketleri gör →'; href = `${SITE}/fiyat.html?k=mail-uye3`;
    } else {
      konu = 'Nerede durduğunu biliyor musun? 30 soruda ölç'; bas = 'Nerede duruyorsun?';
      govde = [sinavCumle + ' Çalışmaya nereden başlayacağını bilmek, en çok zamanı kazandırır.',
        'Seviye testi 30 soru, yaklaşık 20 dakika. Sonunda geçme ihtimalini ve en çok puan kaybettiğin grubu görürsün. Ücretsiz.'];
      dugme = 'Seviyemi ölç →'; href = `${SITE}/seviye-testi.html?k=mail-uye3` + (k.sinav === 'yeterlilik' ? '&sinav=yeterlilik' : '');
    }
  } else if (tur === 'uye7') {
    const n = kalanGun(k.sinav || 'sgs', simdi);
    konu = `Sınava ${n} gün kaldı: bütün sorular paketle açılır`; bas = `Sınava ${n} gün kaldı`;
    govde = [sinavCumle + ' Ücretsiz hesabınla örnek soruları çözebiliyorsun.',
      'Paketle seçtiğin sınavın ya da derslerin bütün soruları açılır. Yanlışların, test ve deneme sonuçların hesabında kalır.',
      'Hangi paketin sana uyduğunu, fiyatları ve ödeme yollarını tek sayfada gör.'];
    dugme = 'Paketleri gör →'; href = `${SITE}/fiyat.html?k=mail-uye7`;
  } else throw new Error('tür yok: ' + tur);
  const ust = S ? 'Tetikte · ' + S.ad : 'Tetikte';
  const metin = ['Merhaba,', '', ...govde.flatMap(p => [p, '']), `${dugme.replace(' →', '')}: ${href}`, '', 'Sınava tetikte gir.', '', NEDEN, `Bir daha gönderme: ${ret}`].join('\n');
  const html = kurumsalMail(`<p style="font-size:12px;letter-spacing:.12em;color:#8d6c38;font-weight:700;margin:0 0 6px">${kac(buyuk(ust))}</p>
<h1 style="font-size:24px;margin:0 0 10px">${kac(bas)}</h1>
${govde.map(p => `<p style="margin:0 0 12px">${kac(p)}</p>`).join('\n')}
<p style="margin:4px 0 18px"><a href="${href}" style="${DUGME}">${kac(dugme)}</a></p>
<p style="margin:0;font-size:12px;color:#6b7280"><a href="${ret}" style="color:#6b7280">Bu e-postaları bir daha gönderme</a></p>
`, NEDEN);
  return { konu, metin, html };
}

const ORNEKLER = [['uye1', {}], ['uye3', { zayif: 'Muhasebe', sinav: 'sgs' }], ['uye3', {}], ['uye7', {}], ['uye7', { sinav: 'yeterlilik' }]];
export function imza() {
  const sabit = new Date('2026-10-16T09:00:00+03:00');
  const t = ORNEKLER.map(([x, k]) => { const m = mailKur(x, k, 'ornek@ornek.com', sabit); return m.konu + m.metin; }).join('|').replace(/t=[0-9a-f]{64}/g, 't=X');
  return crypto.createHash('sha256').update(t).digest('hex').slice(0, 16);
}

/* karar: bugün bu üyeye hangi mail? (saf işlev, öz-sınavlı) */
export function karar({ bugun, acilis, paketli, sonMail, gitti }) {
  if (paketli) return null;
  if (bugun >= new Date(SINAVLAR.sgs.tarih + 'T00:00:00+03:00')) return null;
  if (sonMail && (bugun - sonMail) / GUN < 3) return null;
  const d = Math.floor((bugun - acilis) / GUN), yok = t => !gitti.includes(t);
  if (d >= 7 && d <= 10 && yok('uye7')) return 'uye7';
  if (d >= 3 && d <= 5 && yok('uye3')) return 'uye3';
  if (d >= 1 && d <= 2 && yok('uye1')) return 'uye1';
  return null;
}

async function sb(yol, sec = {}) {
  const r = await fetch(SB + yol, { ...sec, headers: { apikey: SK, Authorization: 'Bearer ' + SK, 'Content-Type': 'application/json', ...(sec.headers || {}) } });
  if (!r.ok) throw new Error(yol.split('?')[0] + ' http ' + r.status); return sec.method === 'POST' ? null : r.json();
}
async function hepsi(yol) { const o = []; for (let i = 0; ; i += 1000) { const p = await sb(yol + `&limit=1000&offset=${i}`); o.push(...p); if (p.length < 1000) return o; } }
async function kullanicilar() {
  const o = []; for (let p = 1; p < 200; p++) { const j = await sb(`/auth/v1/admin/users?page=${p}&per_page=200`); const L = j.users || []; o.push(...L); if (L.length < 200) break; } return o;
}
async function resend(govde) {
  return fetch('https://api.resend.com/emails', { method: 'POST', headers: { Authorization: 'Bearer ' + RESEND_KEY, 'Content-Type': 'application/json' }, body: JSON.stringify(govde) });
}

async function ana() {
  if (process.argv.includes('--imza')) { console.log(imza()); return; }
  const ornek = arg('--ornek');
  if (ornek) {
    fs.mkdirSync(ornek, { recursive: true });
    ORNEKLER.forEach(([t, k], i) => { const m = mailKur(t, k, 'ornek@ornek.com'); fs.writeFileSync(path.join(ornek, `${i + 1}-${t}.html`), `<!-- Konu: ${m.konu} -->\n` + m.html); console.log(`${t}: ${m.konu}`); });
    console.log('imza: ' + imza()); return;
  }
  if (process.argv.includes('--deneme')) {   /* örnekler YALNIZ ALARM_ALICI'ya, "[DENEME]" konulu; kayıt yazılmaz */
    if (!RESEND_KEY) throw new Error('RESEND_KEY yok');
    let n = 0;
    for (const [t, k] of ORNEKLER) { const m = mailKur(t, k, ALARM); if ((await resend({ from: RESEND_FROM, to: [ALARM], subject: '[DENEME] ' + m.konu, text: m.metin, html: m.html })).ok) n++; await new Promise(r => setTimeout(r, 600)); }
    console.log(`DENEME: ${n}/${ORNEKLER.length} mail Cem'e gitti`); if (n < ORNEKLER.length) process.exitCode = 1; return;
  }
  if (!SK) throw new Error('SUPABASE_SERVICE_KEY yok');
  const ayar = JSON.parse(fs.readFileSync(path.join(KOK, 'arac', 'hatirlatma-ayar.json'), 'utf8'));
  const im = imza(), acik = !process.argv.includes('--kuru') && ayar.uye_acik === true && ayar.uye_onayli_imza === im;
  const bugun = new Date();
  const karne = await hepsi(`/rest/v1/form_kayit?select=eposta,alanlar,olusturma&konu=eq.${encodeURIComponent('Seviye testi karnesi')}&order=olusturma.asc`);
  const gonderim = await hepsi(`/rest/v1/form_kayit?select=eposta,alanlar,olusturma&konu=eq.${encodeURIComponent('Hatırlatma gönderildi')}`);
  const elleRet = new Set((await hepsi(`/rest/v1/form_kayit?select=eposta&konu=eq.${encodeURIComponent('Hatırlatma reddi')}`)).map(x => String(x.eposta || '').toLowerCase()));
  const retJeton = new Set((await hepsi('/rest/v1/hatirlatma_ret?select=jeton')).map(x => x.jeton));
  const paketli = new Set((await hepsi('/rest/v1/paket_uyeler?select=user_id')).map(p => p.user_id));
  const kart = new Map();   // eposta -> { sinav, zayif, izin } (son karne)
  for (const k of karne) {
    const a = k.alanlar || {}, s = a['Sınav'] === 'Yeterlilik' ? 'yeterlilik' : 'sgs', e = String(k.eposta || '').toLowerCase(); if (!e) continue;
    const once = kart.get(e);
    kart.set(e, { sinav: s, zayif: zayifGrup(a['Gruplar'] || a['Dersler'], s), izin: a['Kampanya/hatırlatma izni'] === 'evet' || (once && once.izin) });
  }
  const say = { uye: 0, eski: 0, paketli: 0, onaysiz: 0, izinsiz: 0, cikti: 0, bugunYok: 0, uye1: 0, uye3: 0, uye7: 0, gitti: 0, dustu: 0 }, liste = [];
  for (const u of await kullanicilar()) {
    const e = String(u.email || '').toLowerCase(), acilis = new Date(u.created_at); if (!e) continue;
    if ((bugun - acilis) / GUN > 11) { say.eski++; continue; }
    say.uye++;
    if (paketli.has(u.id)) { say.paketli++; continue; }
    if (!u.email_confirmed_at) { say.onaysiz++; continue; }
    const kr = kart.get(e) || {};
    if (!((u.user_metadata || {}).pazarlama_rizasi === true || kr.izin)) { say.izinsiz++; continue; }
    if (elleRet.has(e) || retJeton.has(jeton(e))) { say.cikti++; continue; }
    const g = gonderim.filter(x => String(x.eposta || '').toLowerCase() === e);
    const sonMail = g.length ? new Date(Math.max(...g.map(x => new Date(x.olusturma)))) : null;
    const tur = karar({ bugun, acilis, paketli: false, sonMail, gitti: g.filter(x => (x.alanlar || {}).sinav === 'uye').map(x => x.alanlar.tur) });
    if (!tur) { say.bugunYok++; continue; }
    say[tur]++; liste.push([tur, e, { sinav: kr.sinav || null, zayif: kr.zayif || null }]);
  }
  if (acik) {
    if (!RESEND_KEY) throw new Error('RESEND_KEY yok');
    for (const [tur, e, k] of liste) {
      const m = mailKur(tur, k, e, bugun);
      const r = await resend({ from: RESEND_FROM, to: [e], subject: m.konu, text: m.metin, html: m.html, headers: { 'List-Unsubscribe': `<${SITE}/hatirlatma-ret.html?t=${jeton(e)}>` } });
      if (r.ok) { say.gitti++; await sb('/rest/v1/form_kayit', { method: 'POST', headers: { Prefer: 'return=minimal' }, body: JSON.stringify({ konu: 'Hatırlatma gönderildi', gonderen: 'motor/uye-dizisi.mjs', eposta: e, alanlar: { tur, sinav: 'uye' } }) }); }
      else say.dustu++;
      await new Promise(r => setTimeout(r, 600));
    }
  }
  const ozet = `ÜYE DİZİSİ ${acik ? 'GÖNDERİM' : 'SAYIM (gönderim kapalı)'}: son 11 gün üye ${say.uye} · paketli ${say.paketli} · onaysız ${say.onaysiz} · izinsiz ${say.izinsiz} · çıkmış ${say.cikti} · bugün mail yok ${say.bugunYok} · 1. gün ${say.uye1} · 3. gün ${say.uye3} · 7. gün ${say.uye7}` + (acik ? ` · gitti ${say.gitti} · düştü ${say.dustu}` : '') + ` · metin imzası ${im}${ayar.uye_onayli_imza === im ? ' (onaylı)' : ' (ONAYSIZ)'}`;
  console.log(ozet);
  if (!acik && liste.length && RESEND_KEY && !process.argv.includes('--kuru')) {
    await resend({ from: RESEND_FROM, to: [ALARM], subject: `Tetikte üye dizisi: bugün ${liste.length} mail gidecekti (gönderim kapalı)`, text: ozet + '\n\nGönderimi açmak için metinleri onayla: arac/hatirlatma-ayar.json (uye_acik + uye_onayli_imza).' });
  }
  if (acik && say.dustu) process.exitCode = 1;
}

function sinav() {
  let h = 0, n = 0; const b = (ad, k) => { n++; console.log((k ? '  geçti  ' : '  DÜŞTÜ  ') + ad); if (!k) h++; };
  const T = s => new Date(s + 'T09:00:00+03:00');
  const K = (bugun, acilis, ek = {}) => karar({ bugun: T(bugun), acilis: T(acilis), paketli: false, sonMail: null, gitti: [], ...ek });
  b('aynı gün -> yok', K('2026-10-16', '2026-10-16') === null);
  b('1. gün -> uye1', K('2026-10-17', '2026-10-16') === 'uye1');
  b('uye1 gittiyse 2. gün -> yok', K('2026-10-18', '2026-10-16', { gitti: ['uye1'] }) === null);
  b('3. gün -> uye3', K('2026-10-19', '2026-10-16', { gitti: ['uye1'] }) === 'uye3');
  b('6. gün -> yok', K('2026-10-22', '2026-10-16', { gitti: ['uye1'] }) === null);
  b('7. gün -> uye7', K('2026-10-23', '2026-10-16', { gitti: ['uye1', 'uye3'] }) === 'uye7');
  b('11. gün -> yok', K('2026-10-27', '2026-10-16') === null);
  b('paketli -> hiç', K('2026-10-17', '2026-10-16', { paketli: true }) === null && K('2026-10-23', '2026-10-16', { paketli: true }) === null);
  b('son 3 günde mail (hatırlatma dahil) -> yok', K('2026-10-19', '2026-10-16', { sonMail: T('2026-10-17') }) === null);
  b('SGS günü ve sonrası -> yok', K('2026-11-21', '2026-11-20') === null && K('2026-11-22', '2026-11-21') === null);
  const m = mailKur('uye7', {}, 'a@b.com', T('2026-10-23'));
  b('çıkış bağlantısı var, e-posta adreste yok', m.html.includes('hatirlatma-ret.html?t=' + jeton('a@b.com')) && !m.html.includes('a@b.com') && m.metin.includes('Bir daha gönderme:'));
  b('sınavı bilinmeyen üyeye iki sınav birlikte', /Staja Giriş sınavına \d+ gün, Yeterlilik sınavına \d+ gün/.test(m.metin));
  b('karneli zayıf grup uye3 konusunda', mailKur('uye3', { zayif: 'Hukuk', sinav: 'sgs' }, 'a@b.com').konu.includes('Hukuk'));
  b('metinde "yapay zek" / "Claude" yok', ORNEKLER.every(([t, k]) => !/yapay zek|claude/i.test(mailKur(t, k, 'a@b.com').metin)));
  b('imza metinle değişir', (() => { const i1 = imza(); const eski = SINAVLAR.yeterlilik.ad; SINAVLAR.yeterlilik.ad = 'X'; const i2 = imza(); SINAVLAR.yeterlilik.ad = eski; return i1 !== i2; })());
  b('imza saate göre değişmez', imza() === imza());
  console.log(`ÜYE DİZİSİ öz-sınav: ${n - h}/${n}`); process.exitCode = h ? 1 : 0;
}
if (process.argv[1] && process.argv[1].endsWith('uye-dizisi.mjs')) {
  if (process.argv.includes('--sinav')) sinav(); else ana().catch(e => { console.log('ÜYE DİZİSİ HATA: ' + e.message); process.exitCode = 1; });
}
