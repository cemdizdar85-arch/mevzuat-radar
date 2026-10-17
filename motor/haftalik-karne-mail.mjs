#!/usr/bin/env node
/* ============================================================================
 *  HAFTALIK DENEME KARNESİ MAİLİ — Yeterlilik (11.10.2026, Cem "1.2.3 üçünü de yap", GM2:
 *  "Bu hafta Vergi'de 3 deneme çözdün, 47 → 60; en zayıf konun: …")
 *
 *  KİME: AKTİF Yeterlilik paketi olan (paket_uyeler yeterlilik*) VE son 7 günde en az 1 ders denemesi bitirmiş üye
 *    (ogrenci_sonuc tur=deneme sinav=smmm; sinav-gibi.html bitince / Hesabım açılınca hesaba yazılır).
 *    Paketli müşterinin satın aldığı hizmetin kullanım özeti; yine de her mailde tek tık çıkış (hatırlatma ile AYNI
 *    jeton + hatirlatma_ret tablosu → hatırlatmalardan çıkan bundan da çıkar).
 *  NE ZAMAN: haftada en çok 1 (son 6 günde "Haftalık karne gönderildi" kaydı varsa yok). Sınav günü ve sonrası yok.
 *  İÇERİK: ders ders bu haftaki deneme sayısı + puan gidişatı (son 5) + baraj · en çok tekrarlanan zayıf konu ·
 *    "sana özel deneme" düğmesi. Puan (doğru − yanlış/4) × 100 / soru.
 *  ⛔ ONAYSIZ GÖNDERMEZ: arac/hatirlatma-ayar.json haftalik_acik = true VE haftalik_onayli_imza = bugünkü metin imzası
 *    (node motor/haftalik-karne-mail.mjs --imza). Hatırlatma dizisinin imzasından AYRI: bunu açmak/kapamak onları durdurmaz.
 *  ⛔ GÜNLÜK PUBLIC: e-posta, ad, puan BASILMAZ; yalnız sayı.
 *  🚫 GÖRMEZ: yalnız bu cihazda kalmış (hesaba hiç yazılmamış) deneme · paketsiz deneme (paketsiz deneme yok) ·
 *    adresin geçerliliği.
 *
 *  Kullanım: node motor/haftalik-karne-mail.mjs            (ayara göre sayım ya da gönderim)
 *            node motor/haftalik-karne-mail.mjs --kuru     (yalnız sayım)
 *            node motor/haftalik-karne-mail.mjs --ornek <klasör>   (örnek mail + imza; ağ yok)
 *            node motor/haftalik-karne-mail.mjs --imza | --sinav
 * ==========================================================================*/
import { kurumsalMail } from '../radar-app/edge/karne-gonder.ts';
import { jeton } from './hatirlatma-dizisi.mjs';
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { fileURLToPath } from 'node:url';

const KOK = path.join(path.dirname(fileURLToPath(import.meta.url)), '..');
const SB = 'https://bjrleanjpyujtajmazxn.supabase.co', SITE = 'https://tetikte.com';
const SK = (process.env.SUPABASE_SERVICE_KEY || '').trim();
const RESEND_KEY = (process.env.RESEND_KEY || '').trim(), RESEND_FROM = (process.env.RESEND_FROM || 'Tetikte <bildirim@tetikte.com>').trim();
const ALARM = (process.env.ALARM_ALICI || 'cem@dizdardenetim.com').trim();
const GUN = 864e5, SINAV_TARIH = '2026-11-28';
const arg = a => { const i = process.argv.indexOf(a); return i > 0 ? process.argv[i + 1] : null; };
const kac = s => String(s == null ? '' : s).replace(/[&<>"]/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
const sayi = n => (Math.round(n * 10) / 10).toLocaleString('tr-TR');   // 47,5
const DUGME = 'background:#f5a524;color:#1b1206;text-decoration:none;font-weight:800;padding:11px 18px;border-radius:8px;display:inline-block';
const NEDEN = 'Bu e-postayı, Tetikte Yeterlilik paketindeki çalışmanın haftalık özeti olarak aldın.';
export const puan = v => Math.max(0, ((+v.dogru || 0) - (+v.yanlis || 0) / 4) * 100 / (+v.toplam || 20));

/* denemeler: [{ders, dogru, yanlis, toplam, tarih, zayif?}] (tümü; hafta = son 7 gün) → özet */
export function ozetKur(denemeler, bugun) {
  const hafta = denemeler.filter(d => bugun - new Date(d.tarih) <= 7 * GUN);
  if (!hafta.length) return null;
  const dersler = [...new Set(hafta.map(d => d.ders))];
  const satir = dersler.map(ders => {
    const tum = denemeler.filter(d => d.ders === ders).sort((a, b) => String(a.tarih).localeCompare(String(b.tarih)));
    const p = tum.map(puan), son = p[p.length - 1];
    return { ders, hafta: hafta.filter(d => d.ders === ders).length, gidis: p.slice(-5), son };
  }).sort((a, b) => b.hafta - a.hafta || a.ders.localeCompare(b.ders, 'tr'));
  const z = {}; hafta.forEach(d => { if (d.zayif) z[d.zayif] = (z[d.zayif] || 0) + 1; });
  const zayif = Object.keys(z).sort((a, b) => z[b] - z[a] || a.localeCompare(b, 'tr'))[0] || null;
  return { toplam: hafta.length, satir, zayif };
}

/* 18.10 (Cem "1.2.3" madde 1): SET GELİŞİMİ - ders sayfasındaki 20 soruluk set raporları (ogrenci_sonuc tur=set, kaydir-coz şablonu
   setOzet yazar). setler: [{ders, dogru, yanlis, tarih}] → bu haftaki (son 7 gün) setler ders ders: "Vergi: 3 set · %61 → %79".
   Oran = doğru ÷ (doğru + yanlış) (rapordaki halka ile aynı; boş sayılmaz). En çok setli 3 ders. */
export function setSatir(setler, bugun) {
  const h = (setler || []).filter(s => s && s.ders && s.tarih && bugun - new Date(s.tarih) <= 7 * GUN);
  const orn = s => { const c = (+s.dogru || 0) + (+s.yanlis || 0); return c ? Math.round(100 * (+s.dogru || 0) / c) : 0; };
  return [...new Set(h.map(s => s.ders))].map(ders => { const L = h.filter(s => s.ders === ders).sort((a, b) => String(a.tarih).localeCompare(String(b.tarih)));
    return { ders, n: L.length, ilk: orn(L[0]), son: orn(L[L.length - 1]) }; }).sort((a, b) => b.n - a.n || a.ders.localeCompare(b.ders, 'tr')).slice(0, 3);
}
const setYazi = s => `${kisaAd(s.ders)}: ${s.n} set · ` + (s.n > 1 ? `%${s.ilk} → %${s.son}` : `%${s.son}`);
const SET_BAS = 'Ders sayfalarındaki 20 soruluk setlerde gidişatın:';
const setMetin = L => L && L.length ? [SET_BAS, ...L.map(setYazi), ''] : [];
const setHtml = L => L && L.length ? `<p style="margin:0 0 6px;font-weight:700">${kac(SET_BAS)}</p><ul style="margin:0 0 14px;padding-left:18px">${L.map(s => `<li>${kac(setYazi(s))}</li>`).join('')}</ul>` : '';

export function mailKur(o, e) {
  /* gün sayısı TR takvim gününe göre (sorular.html sonrakiSinav ile aynı; saat yuvarlaması 47/48 farkı veriyordu) */
  const t = new Date(Date.now() + 3 * 36e5), bugunTR = Date.UTC(t.getUTCFullYear(), t.getUTCMonth(), t.getUTCDate()) - 3 * 36e5;
  const kalan = Math.max(0, Math.round((new Date(SINAV_TARIH + 'T00:00:00+03:00') - bugunTR) / GUN));
  const ret = `${SITE}/hatirlatma-ret.html?t=${jeton(e || '')}`, href = `${SITE}/sinav-gibi.html?tur=ders&sinav=smmm`;
  const ilk = o.satir[0];
  const konu = `Bu hafta ${ilk.ders}: ${ilk.hafta} deneme · ${ilk.gidis.map(sayi).join(' → ')}`;
  const govde = [`Bu hafta ${o.toplam} ders denemesi çözdün. Sınava ${kalan} gün kaldı; işte gidişatın:`];
  const liste = o.satir.map(s => `${s.ders}: ${s.hafta} deneme · ${s.gidis.map(sayi).join(' → ')} · son puan ${sayi(s.son)} (baraj 50 ${s.son >= 50 ? '✓' : '✗'})`);
  const sonra = o.zayif ? `Bu hafta en çok zorlandığın konu: ${o.zayif}. Sana özel denemede bitince Nöbetçi seni bu konuya götürür; önce hiç görmediğin sorular gelir.`
    : 'Sana özel denemede önce hiç görmediğin sorular gelir; bitince Nöbetçi seni zayıf konuna götürür.';
  const kural = 'Gerçek sınavda her ders 50 ve ortalama 60 gerekir.';
  const metin = ['Merhaba,', '', govde[0], '', ...liste, '', ...setMetin(o.setler), sonra, '', kural, '', `Sana özel denemeye git: ${href}`, '', 'Sınava tetikte gir.', '', NEDEN, `Bir daha gönderme: ${ret}`].join('\n');
  const html = kurumsalMail(`<p style="font-size:12px;letter-spacing:.12em;color:#8d6c38;font-weight:700;margin:0 0 6px">TETİKTE · SMMM YETERLİLİK</p>
<h1 style="font-size:24px;margin:0 0 10px">Haftalık deneme karnen</h1>
<p style="margin:0 0 12px">${kac(govde[0])}</p>
<table role="presentation" style="border-collapse:collapse;width:100%;margin:0 0 14px;font-size:14px">${o.satir.map(s => `<tr><td style="padding:8px 0;border-bottom:1px solid #e5e7eb"><b>${kac(s.ders)}</b><br><span style="color:#6b7280">${s.hafta} deneme · ${kac(s.gidis.map(sayi).join(' → '))}</span></td><td style="padding:8px 0;border-bottom:1px solid #e5e7eb;text-align:right;white-space:nowrap;font-weight:700;color:${s.son >= 50 ? '#15803d' : '#b91c1c'}">${kac(sayi(s.son))} puan</td></tr>`).join('')}</table>
${setHtml(o.setler)}<p style="margin:0 0 12px">${kac(sonra)}</p>
<p style="margin:0 0 12px;font-size:13px;color:#6b7280">${kac(kural)}</p>
<p style="margin:4px 0 18px"><a href="${href}" style="${DUGME}">Sana özel denemeye git →</a></p>
<p style="margin:0;font-size:12px;color:#6b7280"><a href="${ret}" style="color:#6b7280">Bu e-postaları bir daha gönderme</a></p>
`, NEDEN);
  return { konu, metin, html };
}

/* 12.10 (Cem "1 ekle 2 yap"): üyeler deneme bitirmiyor, ders sayfasında birkaç soru çözüp bırakıyor → deneme karnesi
   kimseye gitmiyordu (12.10 sayım: gidecek 0). İki durum daha: A) bu hafta ders sayfasında soru çözmüş, deneme yok ·
   B) bu hafta hiç çözmemiş. Kaynak ogrenci_ilerleme.veri.cevap (ilerleme-web.js: d=ders, k=konu, s=ok|yan, gun, yol). */
const SAYFA = { 'Finansal Muhasebe': 'finansal-muhasebe', 'Finansal Tablolar ve Analizi': 'finansal-tablolar', 'Maliyet Muhasebesi': 'maliyet-muhasebesi',
  'Muhasebe Denetimi': 'muhasebe-denetimi', 'Vergi Mevzuatı ve Uygulaması': 'vergi', 'Hukuk': 'hukuk', 'Meslek Hukuku': 'meslek-hukuku',
  'Sermaye Piyasası Mevzuatı': 'sermaye-piyasasi' };
const KISA = { 'Vergi Mevzuatı ve Uygulaması': 'Vergi', 'Finansal Tablolar ve Analizi': 'Finansal Tablolar', 'Sermaye Piyasası Mevzuatı': 'Sermaye Piyasası' };
const kisaAd = d => KISA[d] || d;

/* cevaplar: veri.cevap değerleri · dersler: paketin dersleri (null = tümü) → { tur:'soru'|'bos', ders, n, ok, zayif } */
export function soruOzet(cevaplar, dersler, bugun) {
  const smmm = (cevaplar || []).filter(x => x && /^kaydir\/smmm\//.test(String(x.yol || '')) && x.d);
  const hafta = smmm.filter(x => (x.t ? bugun - x.t : bugun - new Date(x.gun + 'T12:00:00+03:00')) <= 7 * GUN);
  const enCok = L => { const c = {}; L.forEach(x => { c[x.d] = (c[x.d] || 0) + 1; }); return Object.keys(c).sort((a, b) => c[b] - c[a] || a.localeCompare(b, 'tr'))[0] || null; };
  if (hafta.length) {
    const ders = enCok(hafta), L = hafta.filter(x => x.d === ders), yan = {};
    L.forEach(x => { if (x.s !== 'ok' && x.k) yan[x.k] = (yan[x.k] || 0) + 1; });
    const zayif = Object.keys(yan).sort((a, b) => yan[b] - yan[a] || a.localeCompare(b, 'tr'))[0] || null;
    return { tur: 'soru', ders, n: L.length, ok: L.filter(x => x.s === 'ok').length, toplam: hafta.length, zayif };
  }
  const ders = (Array.isArray(dersler) && dersler.length === 1 && dersler[0]) || enCok(smmm) || (Array.isArray(dersler) && dersler[0]) || null;
  return { tur: 'bos', ders };
}

export function soruMailKur(o, e) {
  const t = new Date(Date.now() + 3 * 36e5), bugunTR = Date.UTC(t.getUTCFullYear(), t.getUTCMonth(), t.getUTCDate()) - 3 * 36e5;
  const kalan = Math.max(0, Math.round((new Date(SINAV_TARIH + 'T00:00:00+03:00') - bugunTR) / GUN));
  const ret = `${SITE}/hatirlatma-ret.html?t=${jeton(e || '')}`;
  let konu, satir, dugme, href;
  if (o.tur === 'soru') {
    const d = kisaAd(o.ders);
    href = `${SITE}/sinav-gibi.html?tur=ders&sinav=smmm&ders=${encodeURIComponent(o.ders)}`;
    konu = `Bu hafta ${d}: ${o.n} soru, ${o.ok} doğru`;
    satir = [`Bu hafta ${d} dersinde ${o.n} soru çözdün, ${o.ok} tanesi doğru.` + (o.zayif ? ` En çok zorlandığın konu: ${o.zayif.charAt(0).toLocaleUpperCase('tr') + o.zayif.slice(1)}.` : ''),
      `Kendini sınamaya hazırsan dersinin 20 soruluk denemesi seni bekliyor; bitince Nöbetçi seni zayıf konuna götürür.`,
      `Sınava ${kalan} gün kaldı.`];
    dugme = 'Ders denememi çöz';
  } else {
    const d = o.ders ? kisaAd(o.ders) : null;
    href = o.ders && SAYFA[o.ders] ? `${SITE}/kaydir/smmm/${SAYFA[o.ders]}.html#s=0` : `${SITE}/sorular.html`;
    konu = `Sınava ${kalan} gün: 15 dakikalık 10 soru`;
    satir = [`Bu hafta seni göremedik. Sınava ${kalan} gün kaldı.`,
      d ? `${d} sayfasının ilk 10 sorusu sınavda en sık sorulan konulardan; 15 dakika yeter.`
        : `Her ders sayfasının ilk 10 sorusu sınavda en sık sorulan konulardan; 15 dakika yeter.`];
    dugme = '10 soruyu çöz';
  }
  const setL = o.tur === 'soru' ? o.setler : null;
  const metin = ['Merhaba,', '', ...satir.flatMap(s => [s, '']), ...setMetin(setL), `${dugme}: ${href}`, '', 'Sınava tetikte gir.', '', NEDEN, `Bir daha gönderme: ${ret}`].join('\n');
  const html = kurumsalMail(`<p style="font-size:12px;letter-spacing:.12em;color:#8d6c38;font-weight:700;margin:0 0 6px">TETİKTE · SMMM YETERLİLİK</p>
<h1 style="font-size:24px;margin:0 0 10px">${o.tur === 'soru' ? 'Bu haftaki çalışman' : 'Kısa bir set seni bekliyor'}</h1>
${satir.map(s => `<p style="margin:0 0 12px">${kac(s)}</p>`).join('\n')}${setHtml(setL)}
<p style="margin:4px 0 18px"><a href="${href}" style="${DUGME}">${kac(dugme)} →</a></p>
<p style="margin:0;font-size:12px;color:#6b7280"><a href="${ret}" style="color:#6b7280">Bu e-postaları bir daha gönderme</a></p>
`, NEDEN);
  return { konu, metin, html };
}
const ORNEK_A = [
  { d: 'Vergi Mevzuatı ve Uygulaması', k: 'ücret ve kira geliri beyani', s: 'yan', t: Date.parse('2026-10-10T07:00:00Z'), yol: 'kaydir/smmm/vergi.html' },
  { d: 'Vergi Mevzuatı ve Uygulaması', k: 'ücret ve kira geliri beyani', s: 'yan', t: Date.parse('2026-10-10T07:02:00Z'), yol: 'kaydir/smmm/vergi.html' },
  { d: 'Vergi Mevzuatı ve Uygulaması', k: 'ötv ihracat istisnası', s: 'ok', t: Date.parse('2026-10-10T07:03:00Z'), yol: 'kaydir/smmm/vergi.html' },
  { d: 'Vergi Mevzuatı ve Uygulaması', k: 'binek otomobil gideri kkeg', s: 'yan', t: Date.parse('2026-10-10T07:05:00Z'), yol: 'kaydir/smmm/vergi.html' },
  { d: 'Vergi Mevzuatı ve Uygulaması', k: 'ithalatta kdv hesabı', s: 'yan', t: Date.parse('2026-10-10T07:06:00Z'), yol: 'kaydir/smmm/vergi.html' }];
const ORNEK = [
  { ders: 'Vergi Mevzuatı ve Uygulaması', dogru: 8, yanlis: 8, toplam: 20, tarih: '2026-10-05T10:00:00Z' },
  { ders: 'Vergi Mevzuatı ve Uygulaması', dogru: 11, yanlis: 6, toplam: 20, tarih: '2026-10-08T10:00:00Z', zayif: 'GVK › Menkul sermaye iradı' },
  { ders: 'Vergi Mevzuatı ve Uygulaması', dogru: 13, yanlis: 4, toplam: 20, tarih: '2026-10-10T10:00:00Z', zayif: 'GVK › Menkul sermaye iradı' },
  { ders: 'Muhasebe Denetimi', dogru: 9, yanlis: 8, toplam: 20, tarih: '2026-10-09T10:00:00Z', zayif: 'Denetim riski' }];
const ORNEK_B = 'Vergi Mevzuatı ve Uygulaması';
/* 18.10: set gelişimi örneği (imzaya girer → set satırı metni değişirse gönderim durur) */
const ORNEK_SET = [
  { ders: 'Vergi Mevzuatı ve Uygulaması', dogru: 11, yanlis: 7, tarih: '2026-10-08T10:00:00Z' },
  { ders: 'Vergi Mevzuatı ve Uygulaması', dogru: 13, yanlis: 6, tarih: '2026-10-09T10:00:00Z' },
  { ders: 'Vergi Mevzuatı ve Uygulaması', dogru: 15, yanlis: 4, tarih: '2026-10-10T10:00:00Z' }];
/* üç mailin örneği (deneme · A soru · B boş); imza üçünü birden kapsar → herhangi biri değişirse gönderim durur */
export function ornekler() {
  const B = new Date('2026-10-11T09:00:00Z');
  const ss = setSatir(ORNEK_SET, +B), dn = ozetKur(ORNEK, B), sa = soruOzet(ORNEK_A, [ORNEK_B], +B); dn.setler = ss; sa.setler = ss;
  return { deneme: mailKur(dn, 'ornek@ornek.com'),
    soru: soruMailKur(sa, 'ornek@ornek.com'),
    bos: soruMailKur(soruOzet([], [ORNEK_B], +B), 'ornek@ornek.com') };
}
export function imza() {
  const o = ornekler();
  return crypto.createHash('sha256').update(['deneme', 'soru', 'bos'].map(k => o[k].konu + o[k].metin).join('\n#\n')
    .replace(/\d+ gün/g, 'N gün').replace(/t=[0-9a-f]{64}/g, 't=X')).digest('hex').slice(0, 16);
}

async function sb(yol, sec = {}) {
  const r = await fetch(SB + yol, { ...sec, headers: { apikey: SK, Authorization: 'Bearer ' + SK, 'Content-Type': 'application/json', ...(sec.headers || {}) } });
  if (!r.ok) throw new Error(yol.split('?')[0] + ' http ' + r.status); return sec.method === 'POST' ? null : r.json();
}
async function hepsi(yol) { const o = []; for (let i = 0; ; i += 1000) { const p = await sb(yol + `&limit=1000&offset=${i}`); o.push(...p); if (p.length < 1000) return o; } }
async function kullanicilar() { const o = []; for (let p = 1; p < 200; p++) { const j = await sb(`/auth/v1/admin/users?page=${p}&per_page=200`); const L = j.users || []; o.push(...L); if (L.length < 200) break; } return o; }

async function ana() {
  if (process.argv.includes('--imza')) { console.log(imza()); return; }
  const ornek = arg('--ornek');
  if (ornek) { fs.mkdirSync(ornek, { recursive: true }); const O = ornekler();
    for (const [k, m] of Object.entries(O)) { const ad = k === 'deneme' ? 'haftalik-karne' : 'haftalik-karne-' + k;
      fs.writeFileSync(path.join(ornek, ad + '.html'), `<!-- Konu: ${m.konu} -->\n` + m.html); fs.writeFileSync(path.join(ornek, ad + '.txt'), m.konu + '\n\n' + m.metin);
      console.log(k + ' konu: ' + m.konu); }
    console.log('imza: ' + imza()); return; }
  if (!SK) throw new Error('SUPABASE_SERVICE_KEY yok');
  const ayar = JSON.parse(fs.readFileSync(path.join(KOK, 'arac', 'hatirlatma-ayar.json'), 'utf8'));
  const im = imza(), acik = !process.argv.includes('--kuru') && ayar.haftalik_acik === true && ayar.haftalik_onayli_imza === im;
  const bugun = new Date();
  if (bugun >= new Date(SINAV_TARIH + 'T00:00:00+03:00')) { console.log('HAFTALIK KARNE: sınav geçti, gönderim yok'); return; }
  const kayit = await hepsi(`/rest/v1/ogrenci_sonuc?select=user_id,veri&tur=eq.deneme&sinav=eq.smmm&order=olusturma.asc`);
  const paket = await hepsi(`/rest/v1/paket_uyeler?select=user_id,paket,bitis,dersler`);
  const aktifL = paket.filter(p => /^yeterlilik/.test(String(p.paket)) && (!p.bitis || new Date(p.bitis) >= bugun));
  const aktif = new Set(aktifL.map(p => p.user_id)), paketDers = new Map(aktifL.map(p => [p.user_id, p.dersler]));
  const cevap = new Map((await hepsi(`/rest/v1/ogrenci_ilerleme?select=user_id,cevap:veri->cevap&order=user_id.asc`)).map(r => [r.user_id, Object.values(r.cevap || {})]));
  const gonderim = await hepsi(`/rest/v1/form_kayit?select=eposta,olusturma&konu=eq.${encodeURIComponent('Haftalık karne gönderildi')}`);
  const elleRet = new Set((await hepsi(`/rest/v1/form_kayit?select=eposta&konu=eq.${encodeURIComponent('Hatırlatma reddi')}`)).map(x => String(x.eposta || '').toLowerCase()));
  const retJeton = new Set((await hepsi('/rest/v1/hatirlatma_ret?select=jeton')).map(x => x.jeton));
  const eposta = new Map(); (await kullanicilar()).forEach(u => eposta.set(u.id, String(u.email || '').toLowerCase()));
  /* 18.10: set raporları (tablo/tür yoksa boş - mail eskisi gibi) */
  let setK = []; try { setK = await hepsi(`/rest/v1/ogrenci_sonuc?select=user_id,veri&tur=eq.set&sinav=eq.smmm&order=olusturma.asc`); } catch (e) { setK = []; }
  const setKisi = new Map(); setK.forEach(k => { const v = k.veri || {}; if (!v.ders || !v.tarih) return; (setKisi.get(k.user_id) || setKisi.set(k.user_id, []).get(k.user_id)).push(v); });
  const kisi = new Map(); kayit.forEach(k => { const v = k.veri || {}; if (!v.ders || !v.tarih) return; (kisi.get(k.user_id) || kisi.set(k.user_id, []).get(k.user_id)).push(v); });
  /* 12.10: evren = AKTİF Yeterlilik paketlisi (eskiden yalnız denemesi olan). Sıra: deneme karnesi → A (soru) → B (boş). */
  const say = { kisi: kisi.size, uye: aktif.size, paketsiz: 0, haftaYok: 0, cikti: 0, yakin: 0, gidecek: 0, deneme: 0, soru: 0, bos: 0, gitti: 0, dustu: 0 }, liste = [];
  for (const uid of kisi.keys()) if (!aktif.has(uid)) say.paketsiz++;
  for (const uid of aktif) {
    const e = eposta.get(uid); if (!e) continue;
    const L = kisi.get(uid) || [];
    let o = L.length ? ozetKur(L, bugun) : null, tur = 'deneme';
    if (!o) { if (L.length) say.haftaYok++; o = soruOzet(cevap.get(uid), paketDers.get(uid), +bugun); tur = o.tur; }
    if (elleRet.has(e) || retJeton.has(jeton(e))) { say.cikti++; continue; }
    if (gonderim.some(g => String(g.eposta || '').toLowerCase() === e && (bugun - new Date(g.olusturma)) / GUN < 6)) { say.yakin++; continue; }
    if (o && tur !== 'bos') o.setler = setSatir(setKisi.get(uid), +bugun);
    say.gidecek++; say[tur]++; liste.push([e, o, tur]);
  }
  if (acik) {
    if (!RESEND_KEY) throw new Error('RESEND_KEY yok');
    for (const [e, o, tur] of liste) {
      const m = tur === 'deneme' ? mailKur(o, e) : soruMailKur(o, e);
      const r = await fetch('https://api.resend.com/emails', { method: 'POST', headers: { Authorization: 'Bearer ' + RESEND_KEY, 'Content-Type': 'application/json' },
        body: JSON.stringify({ from: RESEND_FROM, to: [e], subject: m.konu, text: m.metin, html: m.html, headers: { 'List-Unsubscribe': `<${SITE}/hatirlatma-ret.html?t=${jeton(e)}>` } }) });
      if (r.ok) { say.gitti++; await sb('/rest/v1/form_kayit', { method: 'POST', headers: { Prefer: 'return=minimal' }, body: JSON.stringify({ konu: 'Haftalık karne gönderildi', gonderen: 'motor/haftalik-karne-mail.mjs', eposta: e, alanlar: { tur, deneme: tur === 'deneme' ? o.toplam : 0, soru: tur === 'soru' ? o.n : 0 } }) }); }
      else say.dustu++;
      await new Promise(r => setTimeout(r, 600));
    }
  }
  const ozet = `HAFTALIK KARNE ${acik ? 'GÖNDERİM' : 'SAYIM (gönderim kapalı)'}: aktif Yeterlilik üyesi ${say.uye} · denemesi olan ${say.kisi} · paketsiz ${say.paketsiz} · bu hafta denemesiz ${say.haftaYok} · çıkmış ${say.cikti} · son 6 günde gitti ${say.yakin} · gidecek ${say.gidecek} (deneme ${say.deneme} · soru ${say.soru} · boş ${say.bos})` + (acik ? ` · gitti ${say.gitti} · düştü ${say.dustu}` : '') + ` · metin imzası ${im}${ayar.haftalik_onayli_imza === im ? ' (onaylı)' : ' (ONAYSIZ)'}`;
  console.log(ozet);
  if (!acik && liste.length && RESEND_KEY && !process.argv.includes('--kuru')) {
    await fetch('https://api.resend.com/emails', { method: 'POST', headers: { Authorization: 'Bearer ' + RESEND_KEY, 'Content-Type': 'application/json' },
      body: JSON.stringify({ from: RESEND_FROM, to: [ALARM], subject: `Tetikte haftalık karne: bugün ${liste.length} mail gidecekti (gönderim kapalı)`, text: ozet + '\n\nAçmak için: arac/hatirlatma-ayar.json haftalik_acik + haftalik_onayli_imza.' }) });
  }
  if (acik && say.dustu) process.exitCode = 1;
}

function sinav() {
  let h = 0, n = 0; const b = (ad, k) => { n++; console.log((k ? '  geçti  ' : '  DÜŞTÜ  ') + ad); if (!k) h++; };
  const B = new Date('2026-10-11T09:00:00Z');
  b('puan: 8D 8Y = 30, 13D 4Y = 60, eksiye düşmez', puan({ dogru: 8, yanlis: 8, toplam: 20 }) === 30 && puan({ dogru: 13, yanlis: 4, toplam: 20 }) === 60 && puan({ dogru: 0, yanlis: 20, toplam: 20 }) === 0);
  const o = ozetKur(ORNEK, B);
  b('hafta: 4 deneme, Vergi önce (3 deneme), gidiş 30→47,5→60', o.toplam === 4 && o.satir[0].ders.startsWith('Vergi') && o.satir[0].gidis.join(',') === '30,47.5,60');
  b('zayıf konu: en çok tekrarlanan', o.zayif === 'GVK › Menkul sermaye iradı');
  b('7 günden eski deneme haftaya girmez ama gidişe girer', (() => { const x = ozetKur([{ ders: 'Hukuk', dogru: 10, yanlis: 0, toplam: 20, tarih: '2026-09-01T00:00:00Z' }, { ders: 'Hukuk', dogru: 12, yanlis: 0, toplam: 20, tarih: '2026-10-10T00:00:00Z' }], B); return x.toplam === 1 && x.satir[0].gidis.length === 2; })());
  b('bu hafta deneme yoksa mail yok', ozetKur([{ ders: 'Hukuk', dogru: 10, yanlis: 0, toplam: 20, tarih: '2026-09-01T00:00:00Z' }], B) === null);
  const m = mailKur(o, 'a@b.com');
  b('çıkış bağlantısı var ve GÖRÜNÜR yazılı, e-posta adreste yok', /hatirlatma-ret\.html\?t=[0-9a-f]{64}"[^>]*>[^<]*bir daha gönderme<\/a>/i.test(m.html) && m.html.includes(jeton('a@b.com')) && !m.html.includes('a@b.com') && m.metin.includes('Bir daha gönderme:'));
  b('imza metinle değişir', (() => { const i1 = imza(); ORNEK[0].ders = 'X'; const i2 = imza(); ORNEK[0].ders = 'Vergi Mevzuatı ve Uygulaması'; return i1 !== i2; })());
  /* 12.10 A/B */
  const a = soruOzet(ORNEK_A, ['Vergi Mevzuatı ve Uygulaması'], +B);
  b('A: bu hafta 5 Vergi sorusu, 1 doğru, zayıf = en çok yanlış konu', a.tur === 'soru' && a.n === 5 && a.ok === 1 && a.zayif === 'ücret ve kira geliri beyani');
  b('A: zayıf konu yalnız YANLIŞLARDAN (çok doğru çözülen konu zayıf sayılmaz)', soruOzet([1, 2, 3].map(i => ({ d: 'Hukuk', k: 'iyi', s: 'ok', t: +B - i, yol: 'kaydir/smmm/hukuk.html' })).concat([{ d: 'Hukuk', k: 'kötü', s: 'yan', t: +B, yol: 'kaydir/smmm/hukuk.html' }]), null, +B).zayif === 'kötü');
  b('A: 7 günden eski cevap haftaya girmez → B', soruOzet(ORNEK_A, null, +B + 9 * GUN).tur === 'bos');
  b('A: sgs/vitrin sayfası cevabı sayılmaz', soruOzet([{ d: 'Hukuk', s: 'ok', t: +B, yol: 'kaydir/sgs/turkce.html' }, { d: 'Hukuk', s: 'ok', t: +B, yol: 'kaydir/vitrin/ornek-smmm.html' }], null, +B).tur === 'bos');
  b('A: t yoksa gun alanından tarih', soruOzet([{ d: 'Hukuk', k: 'x', s: 'yan', gun: '2026-10-10', yol: 'kaydir/smmm/hukuk.html' }], null, +B).tur === 'soru');
  b('B: tek dersli paket → o dersin sayfası #s=0 (kaldığın yer atlanır)', (() => { const m = soruMailKur(soruOzet([], ['Hukuk'], +B), 'a@b.com'); return m.metin.includes('/kaydir/smmm/hukuk.html#s=0'); })());
  b('B: tüm dersli, hiç cevabı yok → sorular.html', soruMailKur(soruOzet([], null, +B), 'a@b.com').metin.includes('/sorular.html'));
  b('B: tüm dersli, geçmişte en çok çözdüğü ders', soruOzet([{ d: 'Hukuk', s: 'ok', t: +B - 30 * GUN, yol: 'kaydir/smmm/hukuk.html' }], null, +B).ders === 'Hukuk');
  b('A/B maillerinde çıkış bağlantısı var, e-posta adreste yok', ['soru', 'bos'].every(k => { const m = ornekler()[k]; return m.html.includes('hatirlatma-ret.html?t=') && !m.html.includes('ornek@ornek.com') && m.metin.includes('Bir daha gönderme:'); }));
  b('imza A metniyle değişir', (() => { const i1 = imza(); ORNEK_A[0].k = 'X'; ORNEK_A[1].k = 'X'; const i2 = imza(); ORNEK_A[0].k = ORNEK_A[1].k = 'ücret ve kira geliri beyani'; return i1 !== i2; })());
  /* 18.10 set gelişimi */
  const st = setSatir(ORNEK_SET.concat([{ ders: 'Hukuk', dogru: 5, yanlis: 5, tarih: '2026-09-01T00:00:00Z' }]), +B);
  b('SET: haftalık 3 Vergi seti %61 → %79; 7 günden eski set girmez', st.length === 1 && st[0].n === 3 && st[0].ilk === 61 && st[0].son === 79);
  b('SET: deneme ve soru mailinde set satırı var, boş mailde yok', (() => { const O = ornekler(); return O.deneme.metin.includes('Vergi: 3 set · %61 → %79') && O.soru.metin.includes('Vergi: 3 set · %61 → %79') && !O.bos.metin.includes(' set · '); })());
  b('SET: seti olmayan üyede satır yok (eski metin aynen)', !mailKur(ozetKur(ORNEK, B), 'a@b.com').metin.includes('setlerde gidişatın'));
  console.log(`HAFTALIK KARNE öz-sınav: ${n - h}/${n}`); process.exitCode = h ? 1 : 0;
}
if (process.argv[1] && process.argv[1].endsWith('haftalik-karne-mail.mjs')) {
  if (process.argv.includes('--sinav')) sinav(); else ana().catch(e => { console.log('HAFTALIK KARNE HATA: ' + e.message); process.exitCode = 1; });
}
