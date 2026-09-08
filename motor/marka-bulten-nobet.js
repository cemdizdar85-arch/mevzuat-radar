#!/usr/bin/env node
/* ===========================================================================
   BÜLTEN NÖBETİ — rakip nöbeti + yayım yakalama, BÜLTEN AMBARINDAN  (08.09.2026)

   Cem: "Rakip nöbeti ve oto-durum robotunu bültene taşı."

   NEDEN: İki robot da TMview'e gidiyordu (motor/marka-portfoy-hasat.ps1 -Rakip
   ve motor/marka-portfoy-durum.ps1). TMview 30.08'den beri ağ düzeyinde kapalı
   (08.09: GitHub'dan da, bizden de bağlantı açılmıyor; gerçek talep "hata").
   İkisi de sessizce ölüydü. Resmî Marka Bülteni ambarı (marka_bulten) ise her
   gece doluyor ve TAM OLARAK bu iki sorunun yemi orada:

   A) RAKİP NÖBETİ — "rakibin yeni marka başvurusu bültende yayımlandı mı?"
      marka_rakip (kullanıcının rakip unvan listesi) × son bültenler. Sahip
      alanı adres de içerdiği için ('8010422-AD (TR) adres') eşleşme yalnız
      AD kısmında aranır; unvanın çekirdeği (hukuki biçim/sektör sözcüğüne
      kadar) kullanılır — tam unvan kısaltmalarla tutmaz.
      İLK KOŞU TEMELDİR: guncelleme boş olan rakipte uyarı YAZILMAZ, yalnız
      görülen numaralar kaydedilir (21.08 dersi: ilk koşuda Arçelik'in 1.120
      markası "yeni" sayılmıştı).

   B) YAYIM YAKALAMA — "senin başvurun yayımlandı, itiraz süresi BAŞLADI."
      firmalar.markalar (üyenin markaları) × son bültenler, ad birebir.
      Sahip üyenin firma adıyla tutuyorsa tip='yayim' (senin başvurun);
      tutmuyorsa tip='ayni-ad' (aynı adla BAŞKASI başvurmuş — itiraz süren
      işliyor). Tescil/ret/düşme BÜLTENDE YOKTUR; o kısım TMview açılana
      kadar bilinemez, bu betik onu iddia etmez.

   SINIR: bülten yalnız YENİ başvuruların ilanıdır. "Rakip tescil aldı",
   "senin markan tescillendi" cümleleri bu betikten ÇIKMAZ.

   KAPILAR: (1) uyarı tekrarı imkânsız — marka_uyari unique(user_id,marka,
   basvuru_no), ignore-duplicates + return=representation → yalnız GERÇEKTEN
   yeni satır için mail. (2) Norm öz-sınavı: SQL marka_norm ile aynı sonucu
   vermeyen sürüm çalışmaz. (3) Mail atılamazsa uyarı panelde kalır, koşu
   kırmızı biter (yutulmaz).

   ENV: SUPABASE_SERVICE_KEY (zorunlu) · RESEND_KEY · RESEND_FROM · RESEND_YANIT
   Kullanım: node motor/marka-bulten-nobet.js [--kuru]
   =========================================================================== */
'use strict';

const fs = require('fs');
const path = require('path');
const SB_URL = process.env.SUPABASE_URL || 'https://bjrleanjpyujtajmazxn.supabase.co';
function sir(ad) { return String(process.env[ad] || '').replace(/^﻿/, '').replace(/[​-‍⁠]/g, '').trim(); }
const SB_KEY = sir('SUPABASE_SERVICE_KEY');
const RESEND = sir('RESEND_KEY');
const FROM = sir('RESEND_FROM') || 'Tetikte <bildirim@tetikte.com>';
const SITE = 'https://tetikte.com';
const KURU = process.argv.includes('--kuru');
const RAPOR = path.join(__dirname, '..', 'veri', 'marka-bulten-nobet-raporu.json');
const RAKIP_TEMEL_GUN = 60;     // ilk koşuda geriye bakılan pencere (temel)
const YAYIM_GUN = 75;           // yayım yakalama penceresi (itiraz 2 ay + pay)
const log = (...s) => console.log(...s);
const esc = s => String(s == null ? '' : s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
const H = { apikey: SB_KEY, Authorization: 'Bearer ' + SB_KEY, 'Content-Type': 'application/json' };

/* --- Normalizasyon: SQL marka_norm ile BİREBİR ---------------------------
   'İ'.toLowerCase() JS'te "i"+U+0307 verir (PS Norm dersinin aynısı). Önce
   İ/I/ı elle i'ye, sonra NFD ile birleşen işaretler atılır (ç→c, ğ→g …).   */
function norm(s) {
  return String(s || '').replace(/[İIı]/g, 'i').toLowerCase().normalize('NFD')
    .replace(/[̀-ͯ]/g, '').replace(/[^a-z0-9]/g, '');
}
const DURAK = new Set(['sanayi','san','ticaret','tic','anonim','as','limited','ltd','sirketi','sti','ve','ithalat','ihracat','pazarlama','dis','ic','insaat','turizm','gida','tekstil','holding','sirket','kollektif','komandit','kooperatif','vakfi','dernegi','hizmetleri','hizmet','urunleri','mamulleri','sanayii','ticareti','muhendislik','danismanlik','yatirim','yatirimlari','enerji','lojistik','nakliyat','otomotiv','bilisim','teknoloji','teknolojileri','yazilim','ilac','kimya','makina','makine','metal','plastik','ambalaj','mobilya','elektrik','elektronik','medikal','saglik','egitim','organizasyon','reklam','matbaacilik','yayincilik','yapi','emlak','gayrimenkul','tarim','hayvancilik','madencilik','petrol','mensucat','konfeksiyon','deri','ayakkabi','kozmetik','temizlik','sigorta','finans','faktoring','leasing','bankasi']);
function cekirdek(unvan) {
  const kel = String(unvan || '').split(/\s+/).map(k => k.replace(/[()"'.,;:]/g, '')).filter(Boolean);
  const al = [];
  for (const k of kel) { const n = norm(k); if (!n) continue; if (DURAK.has(n)) break; al.push(k); }
  if (!al.length && kel.length) al.push(kel[0]);
  return al.join(' ');
}
// "8010422-MEF SERAMİK … LİMİTED ŞİRKETİ (TR) adres" -> "MEF SERAMİK … LİMİTED ŞİRKETİ"
function sahipAd(s) { return String(s || '').split(' (')[0].replace(/^\s*\d+\s*-\s*/, '').trim(); }
/* SÖZCÜK BAŞI EŞLEŞME (08.09 SQL v3 ile aynı kural): boşluksuz alt dize
   "hezarCELIKkapi" içinde "arcelik"i, "deGEr" içinde "ege"yi buluyordu.
   Boşluklu normalizasyon + " sözcük" başlangıcı: "hezar celik" ✗, "arcelik
   anonim" ✓, "ege vitrifiye" ✗, "ege seramik san" ✓. */
function normSozcuk(s) {
  return String(s || '').replace(/[İIı]/g, 'i').toLowerCase().normalize('NFD')
    .replace(/[̀-ͯ]/g, '').replace(/[^a-z0-9]+/g, ' ').trim();
}
function adEslesir(sahipAdi, cekirdekMetni) {
  const s = normSozcuk(cekirdekMetni); if (!s) return false;
  return (' ' + normSozcuk(sahipAdi) + ' ').includes(' ' + s);
}
const rakam = s => String(s || '').replace(/\D/g, '');
const trT = s => { const p = String(s || '').slice(0, 10).split('-'); return p.length === 3 ? (p[2] + '.' + p[1] + '.' + p[0]) : String(s || ''); };
const gunFark = (a, b) => Math.round((a - b) / 86400000);
const isoGun = d => d.toISOString().slice(0, 10);

function ozSinav() {
  const v = [
    ['EGE SERAMİK SANAYİ VE TİCARET ANONİM ŞİRKETİ', 'egeseramik'],
    ['ARÇELİK A.Ş.', 'arcelik'],
    ['DİZDAR DENETİM ANONİM ŞİRKETİ', 'dizdardenetim'],
    ['Koç Holding A.Ş.', 'koc'],
  ];
  for (const [u, b] of v) { const c = norm(cekirdek(u)); if (c !== b) throw new Error(`oz-sinav: cekirdek(${u}) = ${c}, beklenen ${b}`); }
  if (norm('ÇĞİÖŞÜçğıöşü') !== 'cgiosucgiosu') throw new Error('oz-sinav: norm Turkce harf');
  if (sahipAd('8010422-MEF SERAMİK İNŞAAT (TR) AKDENİZ MAH.') !== 'MEF SERAMİK İNŞAAT') throw new Error('oz-sinav: sahipAd');
  if (adEslesir('HEZAR ÇELİK KAPI MOBİLYA SANAYİ', 'ARÇELİK')) throw new Error('oz-sinav: hezar celik ARCELIK sayildi');
  if (!adEslesir('ARÇELİK ANONİM ŞİRKETİ', 'ARÇELİK')) throw new Error('oz-sinav: arcelik eslesmedi');
  if (adEslesir('EGE VİTRİFİYE SAĞLIK GEREÇLERİ', 'EGE SERAMİK')) throw new Error('oz-sinav: ege vitrifiye EGE SERAMIK sayildi');
  if (!adEslesir('EGE SERAMİK SAN. VE TİC. A.Ş.', 'EGE SERAMİK')) throw new Error('oz-sinav: ege seramik eslesmedi');
  if (adEslesir('DEĞER GIDA', 'EGE')) throw new Error('oz-sinav: deger EGE sayildi');
}

async function get(p) {
  const r = await fetch(`${SB_URL}/rest/v1/${p}`, { headers: H });
  const t = await r.text();
  if (!r.ok) throw new Error(`GET ${p.split('?')[0]}: HTTP ${r.status} ${t.slice(0, 160)}`);
  return t ? JSON.parse(t) : [];
}
async function post(p, body, prefer) {
  const r = await fetch(`${SB_URL}/rest/v1/${p}`, { method: 'POST', headers: Object.assign({ Prefer: prefer }, H), body: JSON.stringify(body) });
  const t = await r.text();
  if (!r.ok) throw new Error(`POST ${p.split('?')[0]}: HTTP ${r.status} ${t.slice(0, 160)}`);
  return t ? JSON.parse(t) : [];
}
async function patch(p, body) {
  const r = await fetch(`${SB_URL}/rest/v1/${p}`, { method: 'PATCH', headers: Object.assign({ Prefer: 'return=minimal' }, H), body: JSON.stringify(body) });
  if (!r.ok) throw new Error(`PATCH ${p.split('?')[0]}: HTTP ${r.status} ${(await r.text()).slice(0, 160)}`);
}
async function mail(kime, konu, html) {
  if (!RESEND) throw new Error('RESEND_KEY yok');
  const r = await fetch('https://api.resend.com/emails', {
    method: 'POST', headers: { Authorization: 'Bearer ' + RESEND, 'Content-Type': 'application/json' },
    body: JSON.stringify({ from: FROM, to: [kime], subject: konu, html, reply_to: sir('RESEND_YANIT') || FROM })
  });
  if (!r.ok) throw new Error(`Resend HTTP ${r.status}: ${(await r.text()).slice(0, 160)}`);
}
/* Ambardan PENCERE: son N günün bülten kayıtları TEK SEFERDE, sayfalı.
   08.09 ÖLÇÜM: `sahip_norm=like.*arcelik*` + 60 günlük tarih süzgeci 4,3 sn
   sürdü (sahip_norm'da trigram indeksi yok, planlayıcı tam tarama seçiyor);
   ambar 2 milyona giderken bu sorgu zaman aşımına düşer. Tarih süzgeci tek
   başına indeksli ve hızlı; 75 gün ≈ 40 bin satır ≈ 6 MB. Bir kez çekilir,
   bütün rakipler ve bütün markalar bellekte süzülür — indekse bağımlı değil.
   `order` ŞART: order'sız sayfalama kararsız (ambar-olcum-tuzaklari).
   SAYFA = 1000: PostgREST max-rows tavanı 1.000 — 5.000 istenince 1.000
   döner ve "son sayfa" sanılır (08.09 ölçüldü: 75 gün 1 sayfa 1.000 kayıt).
   ~1.000 satır ≈ 3 sn → 40 bin satır ≈ 2 dk; gece işi için kabul. */
async function pencereYukle(basIso) {
  const hepsi = []; const SAYFA = 1000;
  for (let off = 0; off < 400000; off += SAYFA) {
    const p = await get(`marka_bulten?select=basvuru_no,bulten_no,ad,ad_norm,sinif,yayin_tarihi,itiraz_son,sahip,sahip_norm&yayin_tarihi=gte.${basIso}&order=yayin_tarihi.desc,basvuru_no.desc&offset=${off}&limit=${SAYFA}`);
    hepsi.push(...p);
    if (p.length < SAYFA) break;
  }
  return hepsi;
}
async function uyariYaz(satirlar) {
  if (!satirlar.length) return [];
  if (KURU) return satirlar;   // kuru: hepsi "yeni" sayılır, yazılmaz
  return post('marka_uyari?on_conflict=user_id,marka,basvuru_no', satirlar, 'resolution=ignore-duplicates,return=representation');
}
function altBilgi() {
  return `<p style="font-size:12.5px;color:#5d6b7c;line-height:1.6;margin:16px 0 0">Kaynak: Resmî Marka Bülteni (TÜRKPATENT) — bülten yalnız <b>yeni başvuruların ilanıdır</b>; tescil, ret ya da düşme bilgisini vermez. Yayımlanan başvuruya itiraz süresi yayımdan <b>iki aydır (SMK m.18)</b> ve uzatılamaz. İtirazı marka vekiliniz yapar; bu bir bildirimdir, hukuki mütalaa değildir.</p>
  <p style="font-size:14px;margin:18px 0 0">Kolay gelsin,<br><b>Tetikte — Marka Nöbeti</b></p>
  <p style="font-size:11px;color:#8a93a0;margin:14px 0 0">Bu bildirimi panelinizdeki nöbet ayarları için alıyorsunuz. Kapatmak için bu maile "iptal" yanıtı verin.</p>`;
}
function satirHtml(k, kalan) {
  return `<tr><td style="padding:10px 12px;border-bottom:1px solid #e6e8eb">
    <div style="font-weight:700;font-size:15px">${esc(k.ad)}</div>
    <div style="font-size:12px;color:#5d6b7c;margin-top:3px">başvuru ${esc(k.basvuru_no)}${k.sinif && k.sinif.length ? ' · sınıf ' + esc(k.sinif.join(', ')) : ''} · ${esc(k.bulten_no)} sayılı bültende ${trT(k.yayin_tarihi)}</div>
    ${k.sahip ? `<div style="font-size:12px;color:#5d6b7c;margin-top:3px"><b>Başvuru sahibi:</b> ${esc(sahipAd(k.sahip))}</div>` : ''}
    <div style="font-size:13px;margin-top:6px">İtiraz için son gün <b>${trT(k.itiraz_son)}</b> — <b>${kalan} gün</b>${kalan < 0 ? ' (dolmuş)' : ''}</div></td></tr>`;
}

(async () => {
  if (!SB_KEY) { console.error('!! SUPABASE_SERVICE_KEY yok'); process.exit(1); }
  ozSinav(); log('Oz-sinav gecti (norm + cekirdek + sahipAd).');
  const bugun = new Date(); bugun.setUTCHours(0, 0, 0, 0);
  const rapor = { rakip_unvan: 0, rakip_temel: 0, rakip_yeni: 0, yayim_marka: 0, yayim_uyari: 0, ayni_ad_uyari: 0, mail: 0, hata: 0, ornek: [] };

  // e-posta eşlemesi (ayrı abone listesi yok - firmalar tablosundan)
  const firmalar = await get('firmalar?select=user_id,email,firma_adi,kanal,markalar');
  const posta = new Map();
  for (const f of firmalar) if (f.email && !posta.has(f.user_id)) posta.set(f.user_id, { email: f.email, kanal: f.kanal, firma: f.firma_adi || '' });
  const postaUygun = u => { const p = posta.get(u); return p && p.kanal === 'mail' && /^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(p.email) ? p.email : null; };

  /* ---------------- A) RAKİP NÖBETİ ---------------- */
  let rakipler = [];
  try { rakipler = await get('marka_rakip?select=id,user_id,unvan,son_nolar,guncelleme&aktif=is.true'); }
  catch (e) { log('marka_rakip okunamadi: ' + e.message); }
  const markali = firmalar.filter(f => Array.isArray(f.markalar) && f.markalar.length);
  if (!rakipler.length && !markali.length) { log('Rakip listesi ve markali uye yok - pencere cekilmedi.'); }
  // Pencere: en eski ihtiyaç (temel 60 gün · yayım 75 gün · rakip son bakış-3 gün)
  let pencereBas = bugun.getTime() - Math.max(RAKIP_TEMEL_GUN, YAYIM_GUN) * 86400000;
  for (const r of rakipler) if (r.guncelleme) pencereBas = Math.min(pencereBas, new Date(r.guncelleme).getTime() - 3 * 86400000);
  let pencere = [];
  if (rakipler.length || markali.length) {
    const t0 = Date.now();
    pencere = await pencereYukle(isoGun(new Date(pencereBas)));
    log(`Pencere: ${isoGun(new Date(pencereBas))}'den bu yana ${pencere.length} bulten kaydi (${Math.round((Date.now() - t0) / 100) / 10} sn)`);
  }
  log(`Rakip nobeti: ${rakipler.length} unvan`);
  for (const r of rakipler) {
    rapor.rakip_unvan++;
    const cek = cekirdek(r.unvan), n = norm(cek);
    if (n.length < 3) { log(`  ${r.unvan}: cekirdek cok kisa (${cek}), atlandi`); continue; }
    const temel = !r.guncelleme;
    const bas = isoGun(new Date(temel ? bugun.getTime() - RAKIP_TEMEL_GUN * 86400000 : new Date(r.guncelleme).getTime() - 3 * 86400000));
    const tarihIci = pencere.filter(x => x.yayin_tarihi >= bas);
    const rows = tarihIci.filter(x => adEslesir(sahipAd(x.sahip), cek));
    log(`  ${r.unvan}: pencere ${bas}'den itibaren ${tarihIci.length} kayit`);
    const eski = new Set((r.son_nolar || []).map(rakam));
    const yeni = rows.filter(x => !eski.has(rakam(x.basvuru_no)));
    const birlesik = Array.from(new Set([...(r.son_nolar || []), ...rows.map(x => x.basvuru_no)]));
    log(`  ${r.unvan} [${cek}]: pencerede ${rows.length} · yeni ${yeni.length}${temel ? ' · TEMEL (uyari yok)' : ''}`);
    if (temel) { rapor.rakip_temel++; }
    else if (yeni.length) {
      const yazilan = await uyariYaz(yeni.map(x => ({ user_id: r.user_id, marka: r.unvan, basvuru_no: x.basvuru_no, benzer_ad: x.ad, basvuru_tarih: x.yayin_tarihi, durum: 'Bültende yayımlandı · itiraz son ' + trT(x.itiraz_son), tip: 'rakip-yeni', ofis: 'TR' })));
      const yeniSet = new Set(yazilan.map(x => x.basvuru_no));
      const gercekYeni = yeni.filter(x => yeniSet.has(x.basvuru_no));
      rapor.rakip_yeni += gercekYeni.length;
      gercekYeni.slice(0, 3).forEach(x => rapor.ornek.push({ tip: 'rakip-yeni', unvan: r.unvan, ad: x.ad, no: x.basvuru_no }));
      const kime = postaUygun(r.user_id);
      if (gercekYeni.length && kime && !KURU) {
        try {
          await mail(kime, `Rakip nöbeti: “${r.unvan}” adına ${gercekYeni.length} yeni başvuru bültende`,
            `<div style="font-family:-apple-system,Segoe UI,Roboto,Arial,sans-serif;max-width:640px;margin:0 auto;color:#101418">
             <p style="font-size:16px;margin:0 0 10px">Merhaba,</p>
             <p style="font-size:15px;line-height:1.6;margin:0 0 14px">İzlediğiniz <b>${esc(r.unvan)}</b> adına Resmî Marka Bülteni'nde <b>${gercekYeni.length} yeni başvuru</b> yayımlandı. İtiraz süresi yayımdan itibaren işliyor; sizi ilgilendiren varsa vekilinizle şimdi konuşun.</p>
             <table style="width:100%;border-collapse:collapse;border:1px solid #e6e8eb;border-radius:10px">${gercekYeni.slice(0, 25).map(x => satirHtml(x, gunFark(new Date(x.itiraz_son), bugun))).join('')}</table>
             <p style="font-size:14px;margin:14px 0 0">Benzerlik karşılaştırması: <a href="${SITE}/marka-itiraz.html">${SITE}/marka-itiraz.html</a></p>${altBilgi()}</div>`);
          rapor.mail++;
        } catch (e) { rapor.hata++; console.error(`   !! mail ${kime}: ${e.message}`); }
      }
    }
    if (!KURU) {
      try { await patch(`marka_rakip?id=eq.${r.id}`, { son_nolar: birlesik, son_sayi: birlesik.length, guncelleme: new Date().toISOString() }); }
      catch (e) { rapor.hata++; log(`  ${r.unvan}: kayit guncellenemedi ${e.message}`); }
    }
  }

  /* ---------------- B) YAYIM YAKALAMA ---------------- */
  const yayimBas = isoGun(new Date(bugun.getTime() - YAYIM_GUN * 86400000));
  log(`Yayim yakalama: ${markali.length} firma`);
  for (const f of markali) {
    const firmaCek = cekirdek(f.firma_adi || ''), firmaN = norm(firmaCek);
    const uyarilar = [];
    for (const ad of f.markalar) {
      const n = norm(ad); if (n.length < 2) continue;
      rapor.yayim_marka++;
      const rows = pencere.filter(x => x.yayin_tarihi >= yayimBas && x.ad_norm === n);
      for (const x of rows) {
        const kendi = firmaN.length >= 3 && adEslesir(sahipAd(x.sahip), firmaCek);
        uyarilar.push({ satir: { user_id: f.user_id, marka: ad, basvuru_no: x.basvuru_no, benzer_ad: x.ad, basvuru_tarih: x.yayin_tarihi, durum: (kendi ? 'Başvurun yayımlandı' : 'Aynı adla başkası başvurdu') + ' · itiraz son ' + trT(x.itiraz_son), tip: kendi ? 'yayim' : 'ayni-ad', ofis: 'TR' }, k: x, kendi });
      }
    }
    if (!uyarilar.length) continue;
    const yazilan = await uyariYaz(uyarilar.map(u => u.satir));
    const yeniSet = new Set(yazilan.map(x => x.marka + '|' + x.basvuru_no));
    const yeni = uyarilar.filter(u => yeniSet.has(u.satir.marka + '|' + u.satir.basvuru_no));
    if (!yeni.length) continue;
    yeni.forEach(u => { if (u.kendi) rapor.yayim_uyari++; else rapor.ayni_ad_uyari++; });
    yeni.slice(0, 3).forEach(u => rapor.ornek.push({ tip: u.satir.tip, marka: u.satir.marka, ad: u.k.ad, no: u.k.basvuru_no }));
    log(`  ${f.firma_adi || f.user_id}: ${yeni.length} yeni (${yeni.filter(u => u.kendi).length} kendi yayimi, ${yeni.filter(u => !u.kendi).length} ayni ad)`);
    const kime = postaUygun(f.user_id);
    if (kime && !KURU) {
      const kendi = yeni.filter(u => u.kendi), baska = yeni.filter(u => !u.kendi);
      try {
        await mail(kime, kendi.length ? `Başvurun bültende yayımlandı — itiraz süresi başladı (${kendi.length})` : `Markanla aynı adlı ${baska.length} başvuru bültende yayımlandı`,
          `<div style="font-family:-apple-system,Segoe UI,Roboto,Arial,sans-serif;max-width:640px;margin:0 auto;color:#101418">
           <p style="font-size:16px;margin:0 0 10px">Merhaba,</p>
           ${kendi.length ? `<p style="font-size:15px;line-height:1.6;margin:0 0 10px"><b>Başvurunuz Resmî Marka Bülteni'nde yayımlandı.</b> Bu tarihten itibaren üçüncü kişilerin <b>iki aylık itiraz süresi</b> işliyor (SMK m.18); süre dolup itiraz gelmezse başvuru tescile ilerler.</p>
           <table style="width:100%;border-collapse:collapse;border:1px solid #e6e8eb;border-radius:10px">${kendi.map(u => satirHtml(u.k, gunFark(new Date(u.k.itiraz_son), bugun))).join('')}</table>` : ''}
           ${baska.length ? `<p style="font-size:15px;line-height:1.6;margin:14px 0 10px"><b>Markanızla aynı adı taşıyan başvuru yayımlandı</b> — başvuru sahibi siz değilsiniz. İtiraz etmek istiyorsanız süre yayımdan iki aydır.</p>
           <table style="width:100%;border-collapse:collapse;border:1px solid #e6e8eb;border-radius:10px">${baska.map(u => satirHtml(u.k, gunFark(new Date(u.k.itiraz_son), bugun))).join('')}</table>` : ''}
           <p style="font-size:14px;margin:14px 0 0">Panel: <a href="${SITE}/radar-app.html">${SITE}/radar-app.html</a></p>${altBilgi()}</div>`);
        rapor.mail++;
      } catch (e) { rapor.hata++; console.error(`   !! mail ${kime}: ${e.message}`); }
    }
  }

  log(`\nBITTI: rakip ${rapor.rakip_unvan} unvan (${rapor.rakip_temel} temel, ${rapor.rakip_yeni} yeni) · yayim ${rapor.yayim_marka} marka (${rapor.yayim_uyari} kendi, ${rapor.ayni_ad_uyari} ayni ad) · ${rapor.mail} mail · ${rapor.hata} hata${KURU ? ' · KURU' : ''}`);
  // Rapor: sonuç değişmediyse dosyaya dokunma (yalnız tarih değişen dosya boş commit üretir)
  try {
    const yeni = Object.assign({ mod: KURU ? 'KURU' : 'CANLI', kaynak: 'marka_bulten (Resmi Marka Bulteni ambari)' }, rapor);
    let ayni = false;
    try { const e = JSON.parse(fs.readFileSync(RAPOR, 'utf8')); delete e.tarih; ayni = JSON.stringify(e) === JSON.stringify(yeni); } catch (e) {}
    if (!ayni) fs.writeFileSync(RAPOR, JSON.stringify(Object.assign({ tarih: new Date().toISOString().slice(0, 16).replace('T', ' ') }, yeni), null, 1));
  } catch (e) { console.error('rapor yazilamadi: ' + e.message); }
  if (rapor.hata) process.exit(1);
})().catch(e => { console.error('!! ISTISNA: ' + (e && e.stack || e)); process.exit(1); });
