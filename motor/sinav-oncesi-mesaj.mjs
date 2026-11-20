#!/usr/bin/env node
/* ============================================================================
 *  SINAV ÖNCESİ ÜYE MESAJI — SGS (20.11.2026, Cem: "sgs sınava giren herkese yazalım ve gönderelim")
 *
 *  NEDEN: SGS 21.11.2026. Sınavdan önceki akşam aktif SGS üyesine kurucu imzalı kısa başarı mesajı; çok çözen üyeye
 *    hesabına kayıtlı soru sayısıyla. Satış, bağlantı düğmesi, "garanti" YOK.
 *  KİME: paket_uyeler paket ∈ {sgs, tam, son20-sgs} + bitiş ≥ bugün + e-posta izni (user_metadata.pazarlama_rizasi = true)
 *    + hatırlatmalardan çıkmamış. `--telefonsuz`: siparişinde geçerli cep telefonu OLMAYAN üye (telefonu olana aynı mesaj
 *    WhatsApp'tan elle gidiyor; iki kanaldan aynı metin gitmesin).
 *  SAYI: kasa_cevap'ta üyenin farklı soru sayısı + s20_sonuc doğru+yanlış; ogrenci_sonuc (sgs) toplamı daha büyükse o.
 *    100'den azsa sayı YAZILMAZ (az çözene sayısını hatırlatmak moral bozar). Sayı gerçeğin altında olabilir, üstünde olamaz.
 *  ⛔ ONAYSIZ GÖNDERMEZ: gönderim yalnız `--gonder` + ONAY ortam değişkeni (Cem'in onay cümlesi) ile. Yoksa yalnız SAYIM.
 *  ⛔ METİN "yarın" DER: sınavdan önceki gün (TR saatiyle) değilse gönderim DURUR.
 *  ⛔ KİŞİYE BİR KEZ: form_kayit "Hatırlatma gönderildi" {tur:'sinav-oncesi', sinav:'sgs'} kaydı olan atlanır.
 *  ⛔ GÜNLÜK PUBLIC: e-posta, ad, soru sayısı BASILMAZ; yalnız kişi sayısı.
 *  🚫 GÖRMEZ: hesaba yazılmamış çözüm · 11.10.2026 öncesi cevap (kasa_cevap o gün başlıyor) · adresin geçerliliği ·
 *    siparişsiz (hediye) üyenin telefonu · üyenin sınava gerçekten girip girmeyeceği.
 *
 *  Kullanım: node motor/sinav-oncesi-mesaj.mjs [--telefonsuz]            (sayım)
 *            node motor/sinav-oncesi-mesaj.mjs --deneme                  (iki örnek YALNIZ ALARM_ALICI'ya, "[DENEME]")
 *            ONAY="20.11 Cem: gönder" node motor/sinav-oncesi-mesaj.mjs --gonder [--telefonsuz]
 *            node motor/sinav-oncesi-mesaj.mjs --ornek <klasör> | --sinav
 * ==========================================================================*/
import { kurumsalMail } from '../radar-app/edge/karne-gonder.ts';
import { jeton } from './hatirlatma-dizisi.mjs';
import fs from 'node:fs';
import path from 'node:path';

const SB = 'https://bjrleanjpyujtajmazxn.supabase.co', SITE = 'https://tetikte.com';
const SK = (process.env.SUPABASE_SERVICE_KEY || '').trim();
const RESEND_KEY = (process.env.RESEND_KEY || '').trim(), RESEND_FROM = (process.env.RESEND_FROM || 'Tetikte <bildirim@tetikte.com>').trim();
const ALARM = (process.env.ALARM_ALICI || 'cem@dizdardenetim.com').trim();
const ONAY = (process.env.ONAY || '').trim();
const SINAV_GUNU = '2026-11-21', PAKETLER = ['sgs', 'tam', 'son20-sgs'], SAYI_ESIGI = 100;
const arg = a => { const i = process.argv.indexOf(a); return i > 0 ? process.argv[i + 1] : null; };
const kac = s => String(s == null ? '' : s).replace(/[&<>"]/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
const NEDEN = 'Bu e-postayı, Tetikte hesabını açarken sınav hatırlatmalarına ve duyurulara izin verdiğin için aldın.';

export const trGun = d => new Date(d.getTime() + 3 * 36e5).toISOString().slice(0, 10);
export const oncekiGunMu = (simdi, sinavGunu = SINAV_GUNU) => trGun(new Date(simdi.getTime() + 864e5)) === sinavGunu;
/* "AYŞE NUR YILMAZ" → "Ayşe"; harf dışı içeren ilk kelime → '' (selam adsız yazılır) */
export function ilkAd(s) {
  const w = String(s || '').trim().split(/\s+/)[0] || '';
  if (!/^[A-Za-zÇĞİÖŞÜçğıöşü]{2,}$/.test(w)) return '';
  return w.charAt(0).toLocaleUpperCase('tr-TR') + w.slice(1).toLocaleLowerCase('tr-TR');
}
/* 05xx…, +90 5xx…, 5xx… → 905xxxxxxxxx; cep değilse null */
export function cep(t) {
  let d = String(t || '').replace(/\D/g, '');
  if (d.startsWith('0090')) d = d.slice(2);
  if (d.length === 11 && d.startsWith('0')) d = '9' + d; else if (d.length === 10) d = '90' + d;
  return /^905\d{9}$/.test(d) ? d : null;
}
export function mailKur({ ad, soru }, e) {
  const selam = ilkAd(ad) ? `Merhaba ${ilkAd(ad)},` : 'Merhaba,';
  const orta = soru >= SAYI_ESIGI ? `Tetikte'de ${soru.toLocaleString('tr-TR')} soru çözdün; o emek yarın seninle birlikte salona giriyor.`
    : 'Verdiğin emek yarın seninle birlikte salona giriyor.';
  const govde = [`Yarın sınav günü. ${orta}`, 'Bu gece erken yat. Yarın soruyu iki kez oku, takıldığın soruda oyalanma.', 'Başarılar. Yanındayız.'];
  const ret = `${SITE}/hatirlatma-ret.html?t=${jeton(e || '')}`;
  const konu = 'Yarın salona yalnız girmiyorsun';
  const metin = [selam, '', ...govde.flatMap(p => [p, '']), 'Cem Dizdar · Tetikte', '', NEDEN, `Bir daha gönderme: ${ret}`].join('\n');
  const html = kurumsalMail(`<p style="font-size:12px;letter-spacing:.12em;color:#8d6c38;font-weight:700;margin:0 0 6px">TETİKTE · STAJA GİRİŞ SINAVI</p>
<h1 style="font-size:24px;margin:0 0 14px">Başarılar</h1>
<p style="margin:0 0 12px">${kac(selam)}</p>
${govde.map(p => `<p style="margin:0 0 12px">${kac(p)}</p>`).join('\n')}
<p style="margin:14px 0 18px;font-weight:700">Cem Dizdar · Tetikte</p>
<p style="margin:0;font-size:12px;color:#6b7280"><a href="${ret}" style="color:#6b7280">Bu e-postaları bir daha gönderme</a></p>
`, NEDEN);
  return { konu, metin, html };
}
/* saf seçim: kime gider, kim neden düşer (öz-sınavlı) */
export function sec({ paketler, kullanicilar, siparisler, retJeton, gitmis, bugun, telefonsuz }) {
  const U = new Map(kullanicilar.map(u => [u.id, u])), say = { uye: 0, suresiDolmus: 0, hesapYok: 0, izinsiz: 0, cikti: 0, telefonlu: 0, gitmis: 0 }, liste = [];
  for (const p of paketler) {
    if (!PAKETLER.includes(p.paket)) continue;
    if (String(p.bitis) < bugun) { say.suresiDolmus++; continue; }
    const u = U.get(p.user_id), e = String((u || {}).email || '').toLowerCase();
    if (!e) { say.hesapYok++; continue; }
    say.uye++;
    const md = u.user_metadata || {};
    if (md.pazarlama_rizasi !== true) { say.izinsiz++; continue; }
    if (retJeton.has(jeton(e))) { say.cikti++; continue; }
    const sp = siparisler.filter(x => x.bagli_kullanici === p.user_id || String(x.email || '').toLowerCase() === e);
    if (telefonsuz && sp.some(x => cep(x.telefon))) { say.telefonlu++; continue; }
    if (gitmis.has(e)) { say.gitmis++; continue; }
    const ad = String(md.ad || md.full_name || md.name || (sp.find(x => String(x.ad_soyad || '').trim()) || {}).ad_soyad || '').trim();
    liste.push({ id: p.user_id, e, ad });
  }
  return { say, liste };
}

async function sb(yol, sec_ = {}) {
  const r = await fetch(SB + yol, { ...sec_, headers: { apikey: SK, Authorization: 'Bearer ' + SK, 'Content-Type': 'application/json', ...(sec_.headers || {}) } });
  if (!r.ok) throw new Error(yol.split('?')[0] + ' http ' + r.status); return sec_.method === 'POST' ? null : r.json();
}
async function hepsi(yol) { const o = []; for (let i = 0; ; i += 1000) { const p = await sb(yol + `&limit=1000&offset=${i}`); o.push(...p); if (p.length < 1000) return o; } }
async function tumKullanicilar() { const o = []; for (let p = 1; p < 200; p++) { const j = await sb(`/auth/v1/admin/users?page=${p}&per_page=200`); const L = j.users || []; o.push(...L); if (L.length < 200) break; } return o; }
const resend = govde => fetch('https://api.resend.com/emails', { method: 'POST', headers: { Authorization: 'Bearer ' + RESEND_KEY, 'Content-Type': 'application/json' }, body: JSON.stringify(govde) });

async function ana() {
  const ornek = arg('--ornek');
  if (ornek) {
    fs.mkdirSync(ornek, { recursive: true });
    [['sayili', { ad: 'Ayşe Örnek', soru: 731 }], ['sayisiz', { ad: '', soru: 12 }]].forEach(([n, k]) => { const m = mailKur(k, 'ornek@ornek.com'); fs.writeFileSync(path.join(ornek, n + '.html'), `<!-- Konu: ${m.konu} -->\n` + m.html); });
    console.log('örnekler yazıldı'); return;
  }
  if (process.argv.includes('--deneme')) {   /* YALNIZ ALARM_ALICI'ya; kayıt yazılmaz */
    if (!RESEND_KEY) throw new Error('RESEND_KEY yok');
    let n = 0;
    for (const k of [{ ad: 'Ayşe Örnek', soru: 731 }, { ad: '', soru: 12 }]) { const m = mailKur(k, ALARM); if ((await resend({ from: RESEND_FROM, to: [ALARM], subject: '[DENEME] ' + m.konu, text: m.metin, html: m.html })).ok) n++; await new Promise(r => setTimeout(r, 600)); }
    console.log(`DENEME: ${n}/2 mail Cem'e gitti`); if (n < 2) process.exitCode = 1; return;
  }
  if (!SK) throw new Error('SUPABASE_SERVICE_KEY yok');
  const simdi = new Date(), bugun = trGun(simdi), telefonsuz = process.argv.includes('--telefonsuz');
  const gonder = process.argv.includes('--gonder');
  if (gonder && !ONAY) throw new Error('ONAY yok: gönderim Cem onay cümlesi olmadan açılmaz');
  if (gonder && !oncekiGunMu(simdi)) throw new Error(`metin "yarın" diyor; bugün ${bugun}, sınav ${SINAV_GUNU} → gönderilmez`);
  const paketler = await hepsi('/rest/v1/paket_uyeler?select=user_id,paket,bitis');
  const siparisler = await hepsi('/rest/v1/siparisler?select=ad_soyad,email,telefon,bagli_kullanici&order=olusturma.desc');
  const retJeton = new Set((await hepsi('/rest/v1/hatirlatma_ret?select=jeton')).map(x => x.jeton));
  const gitmis = new Set((await hepsi(`/rest/v1/form_kayit?select=eposta,alanlar&konu=eq.${encodeURIComponent('Hatırlatma gönderildi')}`)).filter(x => (x.alanlar || {}).tur === 'sinav-oncesi').map(x => String(x.eposta || '').toLowerCase()));
  const { say, liste } = sec({ paketler, kullanicilar: await tumKullanicilar(), siparisler, retJeton, gitmis, bugun, telefonsuz });
  const kc = await hepsi('/rest/v1/kasa_cevap?select=user_id,soru_id&order=id.asc');
  const s20 = await hepsi('/rest/v1/s20_sonuc?select=user_id,dogru,yanlis&order=zaman.asc');
  const os = await hepsi('/rest/v1/ogrenci_sonuc?select=user_id,veri&sinav=eq.sgs&order=id.asc');
  let sayili = 0, gitti = 0, dustu = 0;
  for (const u of liste) {
    const a = new Set(kc.filter(x => x.user_id === u.id).map(x => x.soru_id)).size + s20.filter(x => x.user_id === u.id).reduce((t, x) => t + (+x.dogru || 0) + (+x.yanlis || 0), 0);
    const b = os.filter(x => x.user_id === u.id).reduce((t, x) => t + (+(x.veri || {}).dogru || 0) + (+(x.veri || {}).yanlis || 0), 0);
    u.soru = Math.max(a, b); if (u.soru >= SAYI_ESIGI) sayili++;
  }
  if (gonder) {
    if (!RESEND_KEY) throw new Error('RESEND_KEY yok');
    for (const u of liste) {
      const m = mailKur(u, u.e);
      const r = await resend({ from: RESEND_FROM, to: [u.e], subject: m.konu, text: m.metin, html: m.html, headers: { 'List-Unsubscribe': `<${SITE}/hatirlatma-ret.html?t=${jeton(u.e)}>` } });
      if (r.ok) { gitti++; await sb('/rest/v1/form_kayit', { method: 'POST', headers: { Prefer: 'return=minimal' }, body: JSON.stringify({ konu: 'Hatırlatma gönderildi', gonderen: 'motor/sinav-oncesi-mesaj.mjs', eposta: u.e, alanlar: { tur: 'sinav-oncesi', sinav: 'sgs', onay: ONAY.slice(0, 120) } }) }); }
      else dustu++;
      await new Promise(r => setTimeout(r, 600));
    }
  }
  console.log(`SINAV ÖNCESİ MESAJ ${gonder ? 'GÖNDERİM' : 'SAYIM (gönderilmedi)'}${telefonsuz ? ' · yalnız telefonsuz' : ''}: aktif SGS üyesi ${say.uye} · süresi dolmuş ${say.suresiDolmus} · hesapsız ${say.hesapYok} · izinsiz ${say.izinsiz} · çıkmış ${say.cikti} · telefonlu (atlandı) ${say.telefonlu} · daha önce gitmiş ${say.gitmis} · gidecek ${liste.length} (sayılı ${sayili})` + (gonder ? ` · gitti ${gitti} · düştü ${dustu}` : ''));
  if (gonder && dustu) process.exitCode = 1;
}

function sinav() {
  let h = 0, n = 0; const b = (ad, k) => { n++; console.log((k ? '  geçti  ' : '  DÜŞTÜ  ') + ad); if (!k) h++; };
  const K = (id, e, riza = true) => ({ id, email: e, user_metadata: { pazarlama_rizasi: riza, ad: 'ali veli' } });
  const taban = { kullanicilar: [K('1', 'a@b.com'), K('2', 'c@d.com', false), K('3', 'e@f.com'), K('4', 'g@h.com'), K('5', 'i@j.com')],
    paketler: [{ user_id: '1', paket: 'sgs', bitis: '2027-01-01' }, { user_id: '2', paket: 'sgs', bitis: '2027-01-01' }, { user_id: '3', paket: 'yeterlilik-tum', bitis: '2027-01-01' },
      { user_id: '4', paket: 'tam', bitis: '2026-10-31' }, { user_id: '5', paket: 'son20-sgs', bitis: '2027-01-01' }, { user_id: '9', paket: 'sgs', bitis: '2027-01-01' }],
    siparisler: [{ email: 'i@j.com', telefon: '0532 111 22 33', ad_soyad: 'X' }], retJeton: new Set(), gitmis: new Set(), bugun: '2026-11-20', telefonsuz: false };
  const e = o => sec({ ...taban, ...o }).liste.map(x => x.e).join(',');
  b('izinli SGS + Son 20 Gün üyesi seçilir', e({}) === 'a@b.com,i@j.com');
  b('izinsiz üye seçilmez', !e({}).includes('c@d.com') && sec(taban).say.izinsiz === 1);
  b('Yeterlilik paketi seçilmez', !e({}).includes('e@f.com'));
  b('süresi dolmuş paket seçilmez', !e({}).includes('g@h.com') && sec(taban).say.suresiDolmus === 1);
  b('hesabı olmayan paket satırı sayılır, seçilmez', sec(taban).say.hesapYok === 1);
  b('--telefonsuz: telefonu olan atlanır', e({ telefonsuz: true }) === 'a@b.com');
  b('çıkış yapmış üye seçilmez', e({ retJeton: new Set([jeton('a@b.com')]) }) === 'i@j.com');
  b('daha önce gitmiş üye seçilmez', e({ gitmis: new Set(['a@b.com']) }) === 'i@j.com');
  const m1 = mailKur({ ad: 'AYŞE NUR', soru: 731 }, 'a@b.com'), m2 = mailKur({ ad: 'x1', soru: 99 }, 'a@b.com');
  b('100+ soruda sayı yazılır, ad düzgün', m1.metin.includes('Merhaba Ayşe,') && m1.metin.includes('731 soru çözdün'));
  b('99 soruda sayı yazılmaz, bozuk ad adsız selam', !/\d+ soru/.test(m2.metin) && m2.metin.startsWith('Merhaba,\n'));
  b('çıkış bağlantısı var, e-posta gövdede yok', m1.html.includes('hatirlatma-ret.html?t=' + jeton('a@b.com')) && !m1.html.includes('a@b.com'));
  b('metinde garanti / satış / yapay zekâ yok', ![m1, m2].some(m => /garanti|kesin|geçeceksin|indirim|paket|fiyat|yapay zek|claude/i.test(m.metin)));
  b('yalnız sınavdan önceki gün "yarın" doğru', oncekiGunMu(new Date('2026-11-20T19:00:00Z')) && !oncekiGunMu(new Date('2026-11-20T21:30:00Z')) && !oncekiGunMu(new Date('2026-11-19T12:00:00Z')));
  b('cep: biçimler tek biçime iner, sabit hat değil', cep('0532 111 22 33') === '905321112233' && cep('+90 532 111 22 33') === '905321112233' && cep('5321112233') === '905321112233' && cep('0212 111 22 33') === null && cep('') === null);
  console.log(`SINAV ÖNCESİ MESAJ öz-sınav: ${n - h}/${n}`); process.exitCode = h ? 1 : 0;
}
if (process.argv[1] && process.argv[1].endsWith('sinav-oncesi-mesaj.mjs')) {
  if (process.argv.includes('--sinav')) sinav(); else ana().catch(e => { console.log('SINAV ÖNCESİ MESAJ HATA: ' + e.message); process.exitCode = 1; });
}
