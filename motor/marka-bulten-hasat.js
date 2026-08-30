#!/usr/bin/env node
/* ===========================================================================
   RESMİ MARKA BÜLTENİ HASADI  (30.08.2026)

   Cem: "yeni marka başvurularını görmek istiyorum... müşterimizin markası ile
   başka yerden yeni başvuru geldiğinde nasıl görürüz."

   NE YAPAR: TÜRKPATENT'in yayımladığı Resmî Marka Bülteni PDF'ini indirir,
   metne çevirir, kayıtlara ayırır, Supabase'e yazar.

   ── 30.08 ÖLÇÜLEN GERÇEKLER (tasarımın tamamı bunlara dayanıyor) ──────────
   · 499 sayılı bülten: 477 MB · 3.520 sayfa · 5 dk 17 sn · 1,5 MB/sn
   · HTTP 200, application/pdf. CAPTCHA yok, üyelik yok, engel yok.
   · Range/206 DESTEKLENMİYOR -> kesinti olursa baştan iner, devam yok.
   · pdftotext -raw ŞART. -layout iki sütunu aynı satırda birleştiriyor ve
     alanlar karışıyor: (511) 6.012 çıkıyor, oysa gerçek 7.860.
   · -enc UTF-8 ŞART. Onsuz Türkçe harfler düşüyor: "ONBAŞI" -> "ONBAI".
   · SAYFA BAŞLIĞI SİLİNMELİ. Yoksa sayfa sonuna denk gelen kayıtların marka
     adına başlık karışıyor - ÖLÇÜLDÜ: 882 kayıt (%11) bozuluyordu.
   · Sonuç: 7.860 kayıt, dört alanın dördü de %100 dolu.

   HUKUKİ ÇAPA: İtiraz süresi bültenin YAYIM tarihinden işler (SMK m.18,
   iki ay). itiraz_son bu yüzden yayın tarihinden hesaplanır; PDF içindeki
   başka hiçbir tarihten değil.

   SINIR: Bülten yalnız YENİ BAŞVURULARI verir. "Düşmüş mü/yenilenmiş mi"
   sorusuna cevap VERMEZ - o geçmiş sicil işidir.

   ENV : SUPABASE_SERVICE_KEY (yazma için zorunlu)
   Kullanım:
     node motor/marka-bulten-hasat.js --liste          (hangi bültenler var)
     node motor/marka-bulten-hasat.js --son 1          (en yeni 1 bülteni yut)
     node motor/marka-bulten-hasat.js --bulten 499     (belirli bülten)
     node motor/marka-bulten-hasat.js --kuru --bulten 499   (yazma, yalnız ölç)
   =========================================================================== */
'use strict';
const fs = require('fs');
const os = require('os');
const path = require('path');
const { execFileSync, spawnSync } = require('child_process');

const LISTE_URL = 'https://www.turkpatent.gov.tr/bultenler';
const DOSYA_URL = 'https://webim.turkpatent.gov.tr/file/';
const SB_URL = process.env.SUPABASE_URL || 'https://bjrleanjpyujtajmazxn.supabase.co';
const SB_KEY = process.env.SUPABASE_SERVICE_KEY || '';
const PARTI = 500;

const arg = process.argv.slice(2);
const bayrak = (a) => arg.includes(a);
const deger = (a, d) => { const i = arg.indexOf(a); return i >= 0 && arg[i + 1] ? arg[i + 1] : d; };
const KURU = bayrak('--kuru');

const log = (...s) => console.log(...s);
function patla(m) { console.error('!! ' + m); process.exit(1); }

/* --- Türkçe katlama: SQL'deki marka_norm() ile AYNI sonucu vermek ZORUNDA.
   Kültüre güvenilmez (29.08 dersi: Linux'ta 'İ'.toLowerCase() 'i'+U+0307
   veriyor ve bütün i'ler kayboluyordu). Harf harf eşlenir. */
const HK = 'ÇçĞğİIıiÖöŞşÜüÂâÎîÛû';
const HH = 'ccggiiiioossuuaaiiuu';
function norm(s) {
  if (!s) return '';
  let o = '';
  for (const ch of String(s)) {
    const i = HK.indexOf(ch);
    if (i >= 0) { o += HH[i]; continue; }
    const c = ch.toLowerCase();
    if ((c >= 'a' && c <= 'z') || (c >= '0' && c <= '9')) o += c;
  }
  return o;
}

/* ===================== ÖZ-SINAV =========================================
   Karar veren her betiğe öz-sınav. Gerçek veriye dokunmadan, bilinen bir
   numune üstünde ayrıştırıcı doğru mu diye bakılır. Düşerse HİÇ başlamaz -
   yanlış ayrıştırıcıyla 7.860 kaydı bozuk yazmaktansa hiç yazmamak iyidir. */
const NUMUNE = [
  '____________________________________________',
  '2026/499 Resmi Marka Bülteni Türk Patent ve Marka Kurumu Yayın Tarihi : 27.08.2026 1500',
  '(210) 2026/094758 (220) 22.07.2026',
  '(731) 7680072-SERKAN ONBAŞI (TR)',
  'Vekil: OKTAY BİLGİN(BİLGİ PATENT OFİSİ VE DAN. HİZM.',
  'LTD. ŞTİ.)',
  '(540) ec emek conta fabrika & gemi malzemeleri',
  '(511) 06 , 07 , 17 , 35',
  '(510)',
  'Değerli olmayan maden cevherleri.',
  '1817 Yayın Tarihi : 27.08.2026 Türk Patent ve Marka Kurumu 2026/499 Resmi Marka Bülteni',
  '(210) 2026/097275 (220) 28.07.2026',
  '(731) 8074141-SANBA GIDA SANAYİ TİCARET LİMİTED',
  'ŞİRKETİ (TR)',
  '(540) antres kaizen',
  '(511) 35 , 43',
  '(510)',
  'Yiyecek ve içecek sağlanması hizmetleri.'
].join('\n');

function ozSinav() {
  const k = ayristir(NUMUNE);
  const hata = [];
  if (k.length !== 2) hata.push(`kayit sayisi ${k.length}, beklenen 2`);
  const a = k[0] || {};
  if (a.basvuru_no !== '2026/094758') hata.push(`basvuru_no "${a.basvuru_no}"`);
  if (a.basvuru_tarihi !== '2026-07-22') hata.push(`basvuru_tarihi "${a.basvuru_tarihi}"`);
  if (a.ad !== 'ec emek conta fabrika & gemi malzemeleri') hata.push(`ad "${a.ad}"`);
  if (a.sahip !== '7680072-SERKAN ONBAŞI (TR)') hata.push(`sahip "${a.sahip}"`);
  if (!/OKTAY BİLGİN/.test(a.vekil || '')) hata.push(`vekil "${a.vekil}"`);
  if (String(a.sinif) !== '6,7,17,35') hata.push(`sinif [${a.sinif}]`);
  // Sayfa başlığı sızıntısı - 882 kayıtlık kusurun nöbetçisi:
  const b = k[1] || {};
  if (b.ad !== 'antres kaizen') hata.push(`BASLIK SIZINTISI: ad "${b.ad}"`);
  // Türkçe katlama - Linux/Windows farkının nöbetçisi:
  if (norm('İstanbul Şişli') !== 'istanbulsisli') hata.push(`norm "${norm('İstanbul Şişli')}"`);
  if (norm('i̇stanbul') !== 'istanbul') hata.push(`norm(birlesik nokta) "${norm('i̇stanbul')}"`);
  if (hata.length) { hata.forEach(h => console.error('   OZ-SINAV: ' + h)); patla('Oz-sinav DUSTU - gercek veriye dokunulmadi.'); }
  log('Oz-sinav gecti (ayristirma + baslik temizligi + Turkce katlama).');
}

/* ===================== AYRIŞTIRMA ======================================= */
function baslikTemizle(m) {
  return m.split(/\r?\n/).filter(s => {
    const t = s.trim();
    if (/^_{20,}$/.test(t)) return false;
    if (t.includes('Resmi Marka Bülteni') && t.includes('Yayın Tarihi')) return false;
    return true;
  }).join('\n');
}

function alan(govde, kod) {
  const r = new RegExp('\\(' + kod + '\\)([\\s\\S]*?)(?=\\(\\d{3}\\)|$)');
  const t = r.exec(govde);
  return t ? t[1].replace(/\s+/g, ' ').trim() : '';
}

function ayristir(ham) {
  const m = baslikTemizle(ham);
  // ÇAPA: "(210) 2026/094758 (220) 22.07.2026".
  // Tarih NOKTALI olmak zorunda - SLAŞLI olanlar (gg/aa/yyyy) başvuru değil,
  // mahkeme kararları bölümüdür. 499'da 419 tane vardı; onlar ayrı iştir.
  const bas = /\(210\)\s*(\d{4}\/\d+)\s*\(220\)\s*(\d{2})\.(\d{2})\.(\d{4})/g;
  const yer = []; let x;
  while ((x = bas.exec(m)) !== null) {
    yer.push({ i: x.index, no: x[1], tarih: `${x[4]}-${x[3]}-${x[2]}` });
  }
  const out = [];
  for (let k = 0; k < yer.length; k++) {
    const govde = m.slice(yer[k].i, k + 1 < yer.length ? yer[k + 1].i : m.length);
    let sahip = alan(govde, 731), vekil = '';
    const vi = sahip.indexOf('Vekil:');
    if (vi >= 0) { vekil = sahip.slice(vi + 6).trim(); sahip = sahip.slice(0, vi).trim(); }
    const ad = alan(govde, 540);
    const sinif = [...new Set((alan(govde, 511).match(/\d{1,2}/g) || [])
      .map(Number).filter(n => n >= 1 && n <= 45))].sort((a, b) => a - b);
    out.push({
      basvuru_no: yer[k].no, basvuru_tarihi: yer[k].tarih,
      ad, ad_norm: norm(ad), sahip, sahip_norm: norm(sahip), vekil, sinif,
      mal_hizmet: alan(govde, 510).slice(0, 20000) || null
    });
  }
  return out;
}

/* ===================== KAYNAK ============================================ */
async function bultenListesi() {
  const r = await fetch(LISTE_URL, { headers: { 'User-Agent': 'mevzuat-radar-robot/1.0' } });
  if (!r.ok) patla('Bulten listesi alinamadi: HTTP ' + r.status);
  const html = await r.text();
  const t = /<script id="__NEXT_DATA__"[^>]*>([\s\S]*?)<\/script>/.exec(html);
  if (!t) patla('__NEXT_DATA__ bulunamadi - site yapisi degismis olabilir.');
  const nd = JSON.parse(t[1]);

  const bulundu = [];
  (function gez(o) {
    if (!o || typeof o !== 'object') return;
    if (Array.isArray(o)) return o.forEach(gez);
    const aciklama = o.meta && o.meta.description;
    if (aciklama && /Resmi Marka B[üu]lteni/i.test(aciklama) && Array.isArray(o.media)) {
      const pdf = o.media.find(x => x && x.mime === 'application/pdf' && x.slug);
      const g = /(\d{2})\.(\d{2})\.(\d{4})\s*Tarih\s*ve\s*(\d+)\s*Say/i.exec(aciklama);
      if (pdf && g) {
        bulundu.push({
          bulten_no: Number(g[4]),
          yayin_tarihi: `${g[3]}-${g[2]}-${g[1]}`,
          slug: pdf.slug, boyut: pdf.size || null, aciklama
        });
      }
    }
    Object.values(o).forEach(gez);
  })(nd);

  const tek = new Map();
  bulundu.forEach(b => { if (!tek.has(b.bulten_no)) tek.set(b.bulten_no, b); });
  return [...tek.values()].sort((a, b) => b.bulten_no - a.bulten_no);
}

async function indir(slug, hedef) {
  // AKITARAK yazilir, bellege toplanmaz. Ilk surum 477 MB'i once RAM'e
  // aliyordu: hem savurgan, hem de dosya ancak SONUNDA olustugu icin
  // "takildi mi, iniyor mu?" sorusunun cevabi yoktu. Simdi disk anlik buyuyor.
  const t0 = Date.now();
  const r = await fetch(DOSYA_URL + slug, { headers: { 'User-Agent': 'mevzuat-radar-robot/1.0' } });
  if (!r.ok) throw new Error('PDF inmedi: HTTP ' + r.status);
  const tip = r.headers.get('content-type') || '';
  if (!/pdf/i.test(tip)) throw new Error('Beklenen PDF degil, gelen: ' + tip + ' (engel sayfasi olabilir)');
  const beklenen = Number(r.headers.get('content-length') || 0);

  const cikis = fs.createWriteStream(hedef);
  let inen = 0, sonBas = 0, ilk = null;
  for await (const parca of r.body) {
    if (ilk === null) ilk = Buffer.from(parca.slice(0, 5)).toString();
    inen += parca.length;
    if (!cikis.write(parca)) await new Promise(z => cikis.once('drain', z));
    if (Date.now() - sonBas > 15000) {                       // 15 sn'de bir nabiz
      sonBas = Date.now();
      const y = beklenen ? ` / ${(beklenen / 1048576).toFixed(0)} MB` : '';
      process.stdout.write(`\r   iniyor: ${(inen / 1048576).toFixed(0)} MB${y}`);
    }
  }
  await new Promise((z, h) => { cikis.on('error', h); cikis.end(z); });
  process.stdout.write('\r');

  // BUTUNLUK KAPISI: kesik PDF sessizce AZ kayit uretir - yakalayan sey bu.
  if (inen < 1_000_000) throw new Error('PDF cok kucuk: ' + inen + ' bayt');
  if (ilk !== '%PDF-') throw new Error('PDF imzasi yok - dosya bozuk/engel sayfasi');
  if (beklenen && inen !== beklenen) {
    throw new Error(`KESIK INDI: ${inen} bayt geldi, ${beklenen} bekleniyordu. Kaynak Range/devam DESTEKLEMIYOR, bastan inmeli.`);
  }
  log(`   indi: ${(inen / 1048576).toFixed(0)} MB, ${((Date.now() - t0) / 1000).toFixed(0)} sn`);
  return inen;
}

function metneCevir(pdf, txt) {
  const p = spawnSync('pdftotext', ['-raw', '-enc', 'UTF-8', pdf, txt], { encoding: 'utf8' });
  if (p.error) throw new Error('pdftotext calistirilamadi (poppler-utils kurulu mu?): ' + p.error.message);
  if (!fs.existsSync(txt)) throw new Error('pdftotext cikti uretmedi: ' + (p.stderr || '').slice(0, 200));
  return fs.statSync(txt).size;
}

/* ===================== SUPABASE ========================================== */
async function sbYaz(yol, govde, prefer) {
  const r = await fetch(`${SB_URL}/rest/v1/${yol}`, {
    method: 'POST',
    headers: {
      apikey: SB_KEY, Authorization: 'Bearer ' + SB_KEY,
      'Content-Type': 'application/json', Prefer: prefer
    },
    body: JSON.stringify(govde)
  });
  if (!r.ok) throw new Error(`Supabase ${yol}: HTTP ${r.status} ${(await r.text()).slice(0, 300)}`);
}

function ikiAySonra(iso) {
  const d = new Date(iso + 'T00:00:00Z');
  const g = d.getUTCDate();
  d.setUTCMonth(d.getUTCMonth() + 2);
  if (d.getUTCDate() !== g) d.setUTCDate(0);   // 31 Aralık + 2 ay taşmasın
  return d.toISOString().slice(0, 10);
}

/* ===================== ANA AKIŞ ========================================== */
(async () => {
  ozSinav();
  if (!KURU && !SB_KEY) patla('SUPABASE_SERVICE_KEY yok - yazamam. (Olcmek icin --kuru)');

  const liste = await bultenListesi();
  log(`Kaynakta ${liste.length} marka bulteni goruldu. En yenisi: ${liste[0] ? liste[0].bulten_no + ' (' + liste[0].yayin_tarihi + ')' : 'YOK'}`);
  if (bayrak('--liste')) {
    liste.slice(0, 30).forEach(b => log(`   ${b.bulten_no}  ${b.yayin_tarihi}  ${b.boyut ? (b.boyut / 1048576).toFixed(0) + ' MB' : ''}`));
    return;
  }

  let hedefler;
  if (deger('--bulten')) {
    const n = Number(deger('--bulten'));
    hedefler = liste.filter(b => b.bulten_no === n);
    if (!hedefler.length) patla(`${n} sayili bulten kaynakta yok.`);
  } else {
    hedefler = liste.slice(0, Number(deger('--son', '1')));
  }

  const gecici = fs.mkdtempSync(path.join(os.tmpdir(), 'bulten-'));
  const rapor = { tarih: new Date().toISOString().slice(0, 16).replace('T', ' '), islenen: [], hata: [] };

  for (const b of hedefler) {
    log(`\n=== ${b.bulten_no} sayili bulten (${b.yayin_tarihi}) ===`);
    const pdf = path.join(gecici, `b${b.bulten_no}.pdf`);
    const txt = path.join(gecici, `b${b.bulten_no}.txt`);
    try {
      if (!KURU) await sbYaz('marka_bulten_kutuk?on_conflict=bulten_no',
        [{ bulten_no: b.bulten_no, yayin_tarihi: b.yayin_tarihi, durum: 'bekliyor', guncelleme: new Date().toISOString() }],
        'resolution=merge-duplicates,return=minimal');

      const boyut = await indir(b.slug, pdf);
      const tb = metneCevir(pdf, txt);
      log(`   metin: ${(tb / 1048576).toFixed(0)} MB`);

      const kayit = ayristir(fs.readFileSync(txt, 'utf8'));
      const itiraz = ikiAySonra(b.yayin_tarihi);
      const tam = kayit.filter(r => r.ad && r.sahip && r.sinif.length);
      log(`   kayit: ${kayit.length} · tam (4 alan): ${tam.length} (%${(100 * tam.length / (kayit.length || 1)).toFixed(1)})`);

      // KAPI: ölçülen bültende oran %100'dü. Ciddi düşüş ayrıştırıcının
      // bozulduğunu gösterir - bozuk veri yazmaktansa DURULUR.
      if (!kayit.length) throw new Error('Hic kayit cikmadi - ayristirici ya da kaynak bicimi degismis.');
      if (tam.length / kayit.length < 0.95) throw new Error(`Tam kayit orani %${(100 * tam.length / kayit.length).toFixed(1)} - kapi %95. Bicim degismis olabilir, yazilmadi.`);

      if (!KURU) {
        const satir = kayit.map(r => ({ ...r, bulten_no: b.bulten_no, yayin_tarihi: b.yayin_tarihi, itiraz_son: itiraz }));
        for (let i = 0; i < satir.length; i += PARTI) {
          await sbYaz('marka_bulten?on_conflict=basvuru_no,bulten_no', satir.slice(i, i + PARTI),
            'resolution=merge-duplicates,return=minimal');
          process.stdout.write(`\r   yaziliyor: ${Math.min(i + PARTI, satir.length)}/${satir.length}`);
        }
        log('');
        await sbYaz('marka_bulten_kutuk?on_conflict=bulten_no',
          [{ bulten_no: b.bulten_no, yayin_tarihi: b.yayin_tarihi, kayit: kayit.length, boyut_bayt: boyut, durum: 'bitti', not_: null, guncelleme: new Date().toISOString() }],
          'resolution=merge-duplicates,return=minimal');
      }
      log(`   itiraz son gunu: ${itiraz}  (SMK m.18 - yayimdan 2 ay)`);
      rapor.islenen.push({ bulten_no: b.bulten_no, yayin_tarihi: b.yayin_tarihi, kayit: kayit.length, tam: tam.length, itiraz_son: itiraz });
    } catch (e) {
      console.error(`   !! HATA: ${e.message}`);
      rapor.hata.push({ bulten_no: b.bulten_no, mesaj: e.message });
      if (!KURU) {
        try {
          await sbYaz('marka_bulten_kutuk?on_conflict=bulten_no',
            [{ bulten_no: b.bulten_no, yayin_tarihi: b.yayin_tarihi, durum: 'hata', not_: e.message.slice(0, 400), guncelleme: new Date().toISOString() }],
            'resolution=merge-duplicates,return=minimal');
        } catch (_) { }
      }
    } finally {
      [pdf, txt].forEach(f => { try { fs.unlinkSync(f); } catch (_) { } });
    }
  }
  try { fs.rmSync(gecici, { recursive: true, force: true }); } catch (_) { }

  // Kör kalma kuralı: kırmızı olsa da ne gördüğümüz depoda dursun.
  try {
    fs.writeFileSync(path.join(__dirname, '..', 'veri', 'marka-bulten-raporu.json'), JSON.stringify(rapor, null, 1));
  } catch (_) { }
  log(`\nBITTI: ${rapor.islenen.length} bulten islendi, ${rapor.hata.length} hata.`);
  if (rapor.hata.length) process.exit(1);
})().catch(e => { console.error('!! ISTISNA: ' + (e && e.stack || e)); process.exit(1); });
