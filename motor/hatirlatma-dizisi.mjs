#!/usr/bin/env node
/* ============================================================================
 *  SEVİYE TESTİ HATIRLATMA DİZİSİ (06.10.2026, Cem: "bu mail otomatik atılması gerekiyor" + "1 yap")
 *
 *  TAKVİM (Cem onayı 06.10; 3. gün "çalış" maili yalnız paketi olana — ücretsiz kişinin çalışacağı yer yok):
 *    gun7      testten 7-9 gün sonra   "Bir hafta oldu: seviyeni yeniden ölç"
 *    ilerleme  son testten 21+ gün ve son hatırlatmadan 14+ gün sonra   "Sınava N gün kaldı: ilerlemeni gör"
 *    son-hafta sınava 1-7 gün kala, son test o haftadan önceyse   "Sınava 1 hafta kaldı"   (Cem: 2 değil 1 hafta)
 *    paket3    paketi olan, testten 3-4 gün sonra   "Bugün şunu yap: <zayıf grup>"
 *  Öncelik son-hafta > gun7 > paket3 > ilerleme; kişi başına koşuda en çok 1 mail; son 3 günde mail gittiyse hiç.
 *  Sınav günü ve sonrası gönderilmez. Tarihler veri/sinav-takvimi.json (SGS 21.11, Yeterlilik 28.11).
 *
 *  KİME: yalnız İZİN VERENLER (hukuk çizgisi Cem'in; 06.10 varsayılan güvenli taraf): seviye karnesinde
 *    "Kampanya/hatırlatma izni" = "evet" YA DA hesap açarken rıza kutusu (user_metadata.pazarlama_rizasi = true).
 *  ÇIKIŞ: her mailde tek tık bağlantı (hatirlatma-ret.html?t=<jeton>); jeton = HMAC-SHA256(SUPABASE_SERVICE_KEY,
 *    'ret:' + e-posta) - adreste e-posta YOK. Ayrıca form_kayit "Hatırlatma reddi" (elle "ret" yanıtı) de atlanır.
 *    ⚠ Servis anahtarı değişirse eski jetonlar tutmaz (eski çıkanlar yeniden mail alır) - anahtar değişince tablo taşınmalı.
 *  ⛔ ONAYSIZ GÖNDERMEZ: arac/hatirlatma-ayar.json gonderim_acik = true VE onayli_imza = bugünkü metinlerin imzası.
 *    Metin değişirse imza değişir, gönderim kendiliğinden SAYIMA döner (Cem metni yeniden onaylar). Sayım modunda
 *    gönderilecek kişi varsa ALARM_ALICI'ya yalnız SAYI maili gider.
 *  ⛔ GÜNLÜK PUBLIC: e-posta, ad, yüzde BASILMAZ; yalnız sayı. Çift gönderim yok: her gönderim form_kayit'a
 *    "Hatırlatma gönderildi" {tür, sınav, test_tarihi} yazılır.
 *  🚫 GÖRMEZ: üye olmayanın ikinci testi (yalnız karne kaydı olan test sayılır) · adresin geçerliliği · izin geri alma
 *    (hesap ayarından değil yalnız çıkış bağlantısı/elle ret ile).
 *
 *  Kullanım: node motor/hatirlatma-dizisi.mjs            (ayar dosyasına göre: sayım ya da gönderim)
 *            node motor/hatirlatma-dizisi.mjs --kuru     (her durumda yalnız sayım, mail yok)
 *            node motor/hatirlatma-dizisi.mjs --ornek <klasör>   (4 örnek mail + imza; ağ yok)
 *            node motor/hatirlatma-dizisi.mjs --imza     (bugünkü metin imzası)
 * ==========================================================================*/
import { kurumsalMail } from '../radar-app/edge/karne-gonder.ts';
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { fileURLToPath } from 'node:url';

const KOK = path.join(path.dirname(fileURLToPath(import.meta.url)), '..');   // Türkçe/boşluklu yol: URL çözülür
const SB = 'https://bjrleanjpyujtajmazxn.supabase.co', SITE = 'https://tetikte.com';
const SK = (process.env.SUPABASE_SERVICE_KEY || '').trim();
const RESEND_KEY = (process.env.RESEND_KEY || '').trim(), RESEND_FROM = (process.env.RESEND_FROM || 'Tetikte <bildirim@tetikte.com>').trim();
const ALARM = (process.env.ALARM_ALICI || 'cem@dizdardenetim.com').trim();
const arg = a => { const i = process.argv.indexOf(a); return i > 0 ? process.argv[i + 1] : null; };
const GUN = 864e5;
export const SINAVLAR = {
  sgs: { ad: 'Staja Giriş', tarih: '2026-11-21', tarihYazi: '21 Kasım', test: 'seviye-testi.html', paket: /^sgs/ },
  yeterlilik: { ad: 'SMMM Yeterlilik', tarih: '2026-11-28', tarihYazi: '28 Kasım', test: 'seviye-testi.html?sinav=yeterlilik', paket: /^yeterlilik/ },
};
/* 06.10: CSS text-transform:uppercase e-posta istemcisinde Türkçe İ'yi düşürüyordu ('STAJA GIRIŞ'); büyük harf metinde, elle (makineden bağımsız) */
const buyuk = s => String(s).replace(/i/g, 'İ').toUpperCase();
const kac = s => String(s == null ? '' : s).replace(/[&<>"]/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
export const jeton = e => crypto.createHmac('sha256', SK || 'imza-yok').update('ret:' + String(e).toLowerCase()).digest('hex');
/* ay adı elle: toLocaleDateString Windows ile Linux'ta farklı çıktı verdi, metin imzası makineye göre değişiyordu (06.10 ölçüldü) */
const AYLAR = ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];
const trTarih = t => { const d = new Date(new Date(t).getTime() + 3 * 36e5); return d.getUTCDate() + ' ' + AYLAR[d.getUTCMonth()]; };   // TR saati (UTC+3)
const DUGME = 'background:#f5a524;color:#1b1206;text-decoration:none;font-weight:800;padding:11px 18px;border-radius:8px;display:inline-block';
const NEDEN = 'Bu e-postayı, Tetikte seviye testi ve sınav hatırlatmalarına izin verdiğin için aldın.';

/* 130 soruluk SGS'de grup soru sayısı (seviye-testi.html oncelikGrup ile aynı kural) */
const SGS_GRUP = { 'Muhasebe': 58, 'Hukuk': 30, 'Ekonomi ve Maliye': 12, 'Genel Kültür ve Yabancı Dil': 30 };
export function zayifGrup(gruplarMetni, sinav) {
  const L = String(gruplarMetni || '').split('·').map(s => /^\s*(.+?)\s+(\d+)\/(\d+)/.exec(s)).filter(Boolean).map(m => ({ ad: m[1].trim(), dogru: +m[2], soru: +m[3] }));
  if (!L.length) return null;
  const w = x => sinav === 'sgs' ? (SGS_GRUP[x.ad] || x.soru * 130 / 30) : 1;
  return L.sort((a, b) => (1 - b.dogru / b.soru) * w(b) - (1 - a.dogru / a.soru) * w(a))[0].ad;
}

/* tur: gun7 | ilerleme | son-hafta | paket3 ; k: { gecme, tarih, zayif } */
export function mailKur(tur, sinav, k, e) {
  const S = SINAVLAR[sinav], kalan = Math.max(0, Math.round((new Date(S.tarih + 'T00:00:00+03:00') - Date.now()) / GUN));
  const once = k.gecme ? `${trTarih(k.tarih)} günü çözdüğün seviye testinde geçme ihtimalin ${k.gecme} çıkmıştı.` : '';
  const yeniden = `${SITE}/${S.test}`, ret = `${SITE}/hatirlatma-ret.html?t=${jeton(e || '')}`;
  const uye = 'Testi yeniden çözmek için ücretsiz hesabınla gir; hesabın yoksa 1 dakikada açılır.';
  let konu, bas, govde, dugme, href;
  if (tur === 'gun7') {
    konu = 'Bir hafta oldu: seviyeni yeniden ölç'; bas = 'Bir hafta oldu';
    govde = [once + ' Bu hafta çalıştıysan farkı şimdi gör: 30 soru, yaklaşık 20 dakika.', '30 soruluk ölçümde birkaç puanlık oynama olağandır; tek testten değil, gidişattan karar ver.', uye];
    dugme = 'Seviyemi yeniden ölç →'; href = yeniden;
  } else if (tur === 'ilerleme') {
    konu = `${S.ad} sınavına ${kalan} gün kaldı: ilerlemeni gör`; bas = `Sınava ${kalan} gün kaldı`;
    govde = [once + ' İki haftada bir ölçmek gidişatını gösterir: yükseliyor musun, yerinde mi sayıyorsun?', uye];
    dugme = 'İlerlememi gör →'; href = yeniden;
  } else if (tur === 'son-hafta') {
    konu = `${S.ad} sınavına 1 hafta kaldı: seviyeni yeniden ölç`; bas = 'Sınava 1 hafta kaldı';
    govde = [`${S.tarihYazi}'daki ${S.ad} sınavına 1 hafta kaldı. ` + (once ? once + ' O günden beri çalıştın; şimdi nerede olduğunu gör.' : 'Şimdi nerede olduğunu gör.'),
      'Son haftada testi bir kez daha ücretsiz çözebilirsin. Bu test bize de yardım eder: sınavdan sonra gerçek sonucunu yazarsan, tahmini senin gibi adayların gerçek sonuçlarıyla ayarlarız.'];
    dugme = 'Seviyemi yeniden ölç →'; href = yeniden;
  } else if (tur === 'paket3') {
    konu = k.zayif ? `Bugün şunu yap: ${k.zayif} grubundan 10 soru` : 'Bugün şunu yap: 10 soru, 15 dakika';
    bas = 'Bugün şunu yap';
    govde = [(k.zayif ? `Seviye testinde en çok soruyu ${k.zayif} grubunda kaybettin. ` : '') + 'Bugün oradan 10 soru çöz; yaklaşık 15 dakika. Her yanlışını Nöbetçi, tuzağı ve dayandığı maddeyle anlatır; yanlışların kutuna düşer, 2 gün sonra yeniden karşına çıkar.'];
    dugme = 'Paketime git →'; href = `${SITE}/ogrenci.html`;
  } else throw new Error('tür yok: ' + tur);
  const metin = ['Merhaba,', '', ...govde.flatMap(p => [p, '']), `${dugme.replace(' →', '')}: ${href}`, '', 'Sınava tetikte gir.', '', NEDEN, `Bir daha gönderme: ${ret}`].join('\n');
  const html = kurumsalMail(`<p style="font-size:12px;letter-spacing:.12em;color:#8d6c38;font-weight:700;margin:0 0 6px">${kac(buyuk('Tetikte · ' + S.ad))}</p>
<h1 style="font-size:24px;margin:0 0 10px">${kac(bas)}</h1>
${govde.map(p => `<p style="margin:0 0 12px">${kac(p)}</p>`).join('\n')}
<p style="margin:4px 0 18px"><a href="${href}" style="${DUGME}">${kac(dugme)}</a></p>
<p style="margin:0;font-size:12px;color:#6b7280"><a href="${ret}" style="color:#6b7280">Bu hatırlatmaları bir daha gönderme</a></p>
`, NEDEN);
  return { konu, metin, html };
}
/* metin imzası: sabit örnek veriyle 4 türün çıktısı (tarih/gün sayısı hariç) - metin değişince değişir */
export function imza() {
  const k = { gecme: '%37', tarih: '2026-10-06T10:00:00Z', zayif: 'Muhasebe' };
  const t = ['gun7', 'ilerleme', 'son-hafta', 'paket3'].map(x => { const m = mailKur(x, 'sgs', k, 'ornek@ornek.com'); return m.konu + m.metin; }).join('|').replace(/\d+ gün/g, 'N gün').replace(/t=[0-9a-f]{64}/g, 't=X');   // jeton anahtara bağlı, imzaya girmez
  return crypto.createHash('sha256').update(t).digest('hex').slice(0, 16);
}

/* karar: bugün bu kişiye hangi mail? (saf işlev, öz-sınavlı) */
export function karar({ bugun, sinav, sonTest, sonMail, paketli, gitti }) {
  const S = SINAVLAR[sinav], sg = new Date(S.tarih + 'T00:00:00+03:00');
  const d = Math.floor((bugun - sonTest) / GUN), kalan = (sg - bugun) / GUN;
  if (kalan <= 0) return null;
  if (sonMail && (bugun - sonMail) / GUN < 3) return null;
  const testIcin = tur => !gitti.some(g => g.tur === tur && g.test === sonTest.toISOString().slice(0, 10));
  if (kalan <= 7 && sonTest < new Date(sg - 7 * GUN) && !gitti.some(g => g.tur === 'son-hafta')) return 'son-hafta';
  if (d >= 7 && d <= 9 && testIcin('gun7')) return 'gun7';
  if (paketli && d >= 3 && d <= 4 && testIcin('paket3')) return 'paket3';
  if (d >= 21 && (!sonMail || (bugun - sonMail) / GUN >= 14) && kalan > 7) return 'ilerleme';
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

async function ana() {
  if (process.argv.includes('--imza')) { console.log(imza()); return; }
  const ornek = arg('--ornek');
  if (ornek) {
    fs.mkdirSync(ornek, { recursive: true });
    for (const t of ['gun7', 'ilerleme', 'son-hafta', 'paket3']) { const m = mailKur(t, 'sgs', { gecme: '%37', tarih: '2026-10-06T10:00:00Z', zayif: 'Muhasebe' }, 'ornek@ornek.com'); fs.writeFileSync(path.join(ornek, t + '.html'), `<!-- Konu: ${m.konu} -->\n` + m.html); console.log(`${t}: ${m.konu}`); }
    console.log('imza: ' + imza()); return;
  }
  if (!SK) throw new Error('SUPABASE_SERVICE_KEY yok');
  const ayar = JSON.parse(fs.readFileSync(path.join(KOK, 'arac', 'hatirlatma-ayar.json'), 'utf8'));
  const im = imza(), acik = !process.argv.includes('--kuru') && ayar.gonderim_acik === true && ayar.onayli_imza === im;
  const bugun = new Date();
  const karne = await hepsi(`/rest/v1/form_kayit?select=eposta,alanlar,olusturma&konu=eq.${encodeURIComponent('Seviye testi karnesi')}&order=olusturma.asc`);
  const gonderim = await hepsi(`/rest/v1/form_kayit?select=eposta,alanlar,olusturma&konu=eq.${encodeURIComponent('Hatırlatma gönderildi')}`);
  const elleRet = new Set((await hepsi(`/rest/v1/form_kayit?select=eposta&konu=eq.${encodeURIComponent('Hatırlatma reddi')}`)).map(x => String(x.eposta || '').toLowerCase()));
  const retJeton = new Set((await hepsi('/rest/v1/hatirlatma_ret?select=jeton')).map(x => x.jeton));
  const uyeler = await kullanicilar(), uyeRiza = new Set(), uyeId = new Map();
  uyeler.forEach(u => { const e = String(u.email || '').toLowerCase(); uyeId.set(u.id, e); if ((u.user_metadata || {}).pazarlama_rizasi === true) uyeRiza.add(e); });
  const paket = await hepsi(`/rest/v1/paket_uyeler?select=user_id,paket,bitis`);
  const paketli = (e, s) => paket.some(p => uyeId.get(p.user_id) === e && SINAVLAR[s].paket.test(String(p.paket)) && (!p.bitis || new Date(p.bitis) >= bugun));
  const kisi = new Map();   // "<sınav>|<eposta>" -> son test
  for (const k of karne) {
    const a = k.alanlar || {}, s = a['Sınav'] === 'Yeterlilik' ? 'yeterlilik' : 'sgs', e = String(k.eposta || '').toLowerCase(); if (!e) continue;
    const onceki = kisi.get(s + '|' + e);
    kisi.set(s + '|' + e, { s, e, izin: a['Kampanya/hatırlatma izni'] === 'evet' || (onceki && onceki.izin), gecme: a['Geçme ihtimali'], tarih: k.olusturma, zayif: zayifGrup(a['Gruplar'], s) });
  }
  const say = { kisi: kisi.size, izinsiz: 0, cikti: 0, bugunYok: 0, gun7: 0, ilerleme: 0, 'son-hafta': 0, paket3: 0, gitti: 0, dustu: 0 }, liste = [];
  for (const k of kisi.values()) {
    if (!(k.izin || uyeRiza.has(k.e))) { say.izinsiz++; continue; }
    if (elleRet.has(k.e) || retJeton.has(jeton(k.e))) { say.cikti++; continue; }
    const g = gonderim.filter(x => String(x.eposta || '').toLowerCase() === k.e && (x.alanlar || {}).sinav === k.s).map(x => ({ tur: x.alanlar.tur, test: x.alanlar.test_tarihi, zaman: new Date(x.olusturma) }));
    const sonMail = g.length ? new Date(Math.max(...g.map(x => x.zaman))) : null;
    const tur = karar({ bugun, sinav: k.s, sonTest: new Date(k.tarih), sonMail, paketli: paketli(k.e, k.s), gitti: g });
    if (!tur) { say.bugunYok++; continue; }
    say[tur]++; liste.push([tur, k]);
  }
  if (acik) {
    if (!RESEND_KEY) throw new Error('RESEND_KEY yok');
    for (const [tur, k] of liste) {
      const m = mailKur(tur, k.s, k, k.e);
      const r = await fetch('https://api.resend.com/emails', { method: 'POST', headers: { Authorization: 'Bearer ' + RESEND_KEY, 'Content-Type': 'application/json' },
        body: JSON.stringify({ from: RESEND_FROM, to: [k.e], subject: m.konu, text: m.metin, html: m.html, headers: { 'List-Unsubscribe': `<${SITE}/hatirlatma-ret.html?t=${jeton(k.e)}>` } }) });
      if (r.ok) { say.gitti++; await sb('/rest/v1/form_kayit', { method: 'POST', headers: { Prefer: 'return=minimal' }, body: JSON.stringify({ konu: 'Hatırlatma gönderildi', gonderen: 'motor/hatirlatma-dizisi.mjs', eposta: k.e, alanlar: { tur, sinav: k.s, test_tarihi: String(k.tarih).slice(0, 10) } }) }); }
      else say.dustu++;
      await new Promise(r => setTimeout(r, 600));
    }
  }
  const ozet = `HATIRLATMA ${acik ? 'GÖNDERİM' : 'SAYIM (gönderim kapalı)'}: kişi ${say.kisi} · izinsiz ${say.izinsiz} · çıkmış ${say.cikti} · bugün mail yok ${say.bugunYok} · 7. gün ${say.gun7} · ilerleme ${say.ilerleme} · son hafta ${say['son-hafta']} · paket 3. gün ${say.paket3}` + (acik ? ` · gitti ${say.gitti} · düştü ${say.dustu}` : '') + ` · metin imzası ${im}${ayar.onayli_imza === im ? ' (onaylı)' : ' (ONAYSIZ)'}`;
  console.log(ozet);
  if (!acik && liste.length && RESEND_KEY && !process.argv.includes('--kuru')) {
    await fetch('https://api.resend.com/emails', { method: 'POST', headers: { Authorization: 'Bearer ' + RESEND_KEY, 'Content-Type': 'application/json' },
      body: JSON.stringify({ from: RESEND_FROM, to: [ALARM], subject: `Tetikte hatırlatma: bugün ${liste.length} mail gidecekti (gönderim kapalı)`, text: ozet + '\n\nGönderimi açmak için mail metinlerini onayla: arac/hatirlatma-ayar.json (gonderim_acik + onayli_imza).' }) });
  }
  if (acik && say.dustu) process.exitCode = 1;
}

/* öz-sınav: node motor/hatirlatma-dizisi.mjs --sinav */
function sinav() {
  let h = 0; const b = (ad, k) => { console.log((k ? '  geçti  ' : '  DÜŞTÜ  ') + ad); if (!k) h++; };
  const T = s => new Date(s + 'T09:00:00+03:00');
  const K = (bugun, test, ek = {}) => karar({ bugun: T(bugun), sinav: 'sgs', sonTest: T(test), sonMail: null, paketli: false, gitti: [], ...ek });
  b('7. gün -> gun7', K('2026-10-13', '2026-10-06') === 'gun7');
  b('6. gün -> yok', K('2026-10-12', '2026-10-06') === null);
  b('7. gün maili gittiyse tekrar yok', K('2026-10-14', '2026-10-06', { gitti: [{ tur: 'gun7', test: T('2026-10-06').toISOString().slice(0, 10) }] }) === null);
  b('paketli 3. gün -> paket3, paketsiz -> yok', K('2026-10-09', '2026-10-06', { paketli: true }) === 'paket3' && K('2026-10-09', '2026-10-06') === null);
  b('21+ gün, mail yok -> ilerleme', K('2026-10-28', '2026-10-06') === 'ilerleme');
  b('ilerleme: son mail 10 gün önce -> yok', K('2026-10-28', '2026-10-06', { sonMail: T('2026-10-18') }) === null);
  b('son hafta: 15.11, test 06.10 -> son-hafta', K('2026-11-15', '2026-10-06') === 'son-hafta');
  b('son hafta: test 16.11 (pencerede) -> yok', K('2026-11-18', '2026-11-16') === null);
  b('son 3 günde mail -> hiç', K('2026-10-13', '2026-10-06', { sonMail: T('2026-10-12') }) === null);
  b('sınav günü ve sonrası -> yok', K('2026-11-21', '2026-10-06') === null && K('2026-11-25', '2026-10-06') === null);
  b('zayıf grup: 3/14 Muhasebe, 0/4 Ekonomiden önce', zayifGrup('Muhasebe 3/14 · Hukuk 1/5 · Ekonomi ve Maliye 0/4 · Genel Kültür ve Yabancı Dil 6/7', 'sgs') === 'Muhasebe');
  const m = mailKur('gun7', 'sgs', { gecme: '%5', tarih: '2026-10-06T10:00:00Z' }, 'a@b.com');
  b('mailde çıkış bağlantısı var, e-posta adreste yok', m.html.includes('hatirlatma-ret.html?t=' + jeton('a@b.com')) && !m.html.includes('a@b.com') && m.metin.includes('Bir daha gönderme:'));
  b('imza metinle değişir', (() => { const i1 = imza(); const eski = SINAVLAR.sgs.ad; SINAVLAR.sgs.ad = 'X'; const i2 = imza(); SINAVLAR.sgs.ad = eski; return i1 !== i2; })());
  console.log(`HATIRLATMA DİZİSİ öz-sınav: ${13 - h}/13`); process.exitCode = h ? 1 : 0;
}
if (process.argv[1] && process.argv[1].endsWith('hatirlatma-dizisi.mjs')) {
  if (process.argv.includes('--sinav')) sinav(); else ana().catch(e => { console.log('HATIRLATMA HATA: ' + e.message); process.exitCode = 1; });
}
