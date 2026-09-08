#!/usr/bin/env node
/* ===========================================================================
   MUTABAKAT NÖBETÇİSİ — "kütük mü doğru, tablo mu?"  (30.08.2026 · 08.09 v2)

   Cem: "2 yapalım."

   NEDEN VAR: marka_bulten_durum() sayıları KÜTÜKTEN okuyor, çünkü 100 bin
   satırı saymak zaman aşımına düşüyordu. Hızlı ama bir varsayıma dayanıyor:
   "robot kaç kayıt yazdığını doğru yazdı." O varsayım kırılırsa ekran
   "7.860 kayıt" der, tabloda 7.400 vardır ve KIMSE FARK ETMEZ. Eksik
   markalar için uyarı gitmez, itiraz süresi sessizce akar.

   Bu nöbetçi o boşluğu kapatır: bülten bülten kütükle tabloyu karşılaştırır.

   ── 08.09 v2: NEDEN TEK RPC DEĞİL, BÜLTEN BÜLTEN SAYIM ─────────────────────
   Eski sürüm tek çağrıyla marka_bulten_mutabakat() RPC'sini çağırıyordu.
   O fonksiyon 105 bültenin hepsini TEK sorguda sayıyor; tablo 800 bini
   geçince (07.09 koşusu) "canceling statement due to statement timeout"
   verdi ve nöbetçi KÖR kaldı. 2 milyonda hiç dönmeyecekti — yani nöbetçi
   tam da işe yarayacağı büyüklükte susuyordu.

   ÖLÇÜLDÜ (08.09, 799.146 kayıt): bülten başına tek sayım (PostgREST
   Prefer: count=exact + bulten_no=eq.N) 320–1.190 ms. 105 bülten ≈ 1 dk,
   263 bülten ≈ 3 dk. Her sayım kendi başına zaman aşımı sınırının altında;
   tablo büyüdükçe toplam süre uzar ama tek bir sorgu asla tavana çarpmaz.

   ÜÇ DURUM (kör kalma kuralı - "sessiz" diye bir sonuç yok):
     YEŞİL  : tüm bültenlerde kütük = tablo
     KIRMIZI: en az bir bültende fark var -> hangisi, kaç kayıt
     KÖR    : ölçüm yapılamadı (anahtar yok / kütük okunamadı / bazı
              bültenler sayılamadı) -> "temiz" DEMEZ. Sayılabilen bültenlerde
              fark varsa KIRMIZI önce gelir; körlük raporda ayrıca yazılır.

   ENV: SUPABASE_SERVICE_KEY
   Kullanım: node motor/marka-mutabakat.js
   =========================================================================== */
'use strict';

const SB_URL = process.env.SUPABASE_URL || 'https://bjrleanjpyujtajmazxn.supabase.co';
const SB_KEY = process.env.SUPABASE_SERVICE_KEY || '';
const fs = require('fs');
const path = require('path');

const RAPOR = path.join(__dirname, '..', 'veri', 'marka-mutabakat-raporu.json');
const ES_ZAMANLI = 3;        // aynı anda kaç sayım (kaynağı yormadan)
const DENEME = 2;            // bir bülten sayımı düşerse kaç kez denenir
const log = (...s) => console.log(...s);
const H = { apikey: SB_KEY, Authorization: 'Bearer ' + SB_KEY };

// Rapor: sonuç değişmediyse dosyaya DOKUNMA (yalnız tarih değişen dosya her
// koşuda "değişmiş" görünür, boş commit ve çakışma üretir - CLAUDE.md kuralı).
function yaz(durum, ozet, ayrinti, ek) {
  const yeni = Object.assign({ durum, ozet, ayrinti }, ek || {});
  try {
    if (fs.existsSync(RAPOR)) {
      const eski = JSON.parse(fs.readFileSync(RAPOR, 'utf8'));
      delete eski.tarih;
      const e2 = Object.assign({}, yeni); delete e2.tarih;
      if (JSON.stringify(eski) === JSON.stringify(e2)) return;
    }
  } catch (e) { /* okunamayan eski rapor: üstüne yaz */ }
  try {
    fs.writeFileSync(RAPOR, JSON.stringify(Object.assign({
      tarih: new Date().toISOString().slice(0, 16).replace('T', ' ')
    }, yeni), null, 1));
  } catch (e) { console.error('rapor yazilamadi: ' + e.message); }
}

async function kutukOku() {
  const r = await fetch(`${SB_URL}/rest/v1/marka_bulten_kutuk?durum=eq.bitti&select=bulten_no,yayin_tarihi,kayit&order=bulten_no.desc`, { headers: H });
  const t = await r.text();
  if (!r.ok) throw new Error(`kutuk HTTP ${r.status} ${t.slice(0, 200)}`);
  return JSON.parse(t);
}

// Tek bültenin tablodaki satır sayısı. Gövde istenmez (Range 0-0), yalnız
// Content-Range başlığındaki toplam okunur: "0-0/7860" ya da "*/0".
async function tabloSay(bultenNo) {
  let sonHata = null;
  for (let d = 1; d <= DENEME; d++) {
    try {
      const r = await fetch(`${SB_URL}/rest/v1/marka_bulten?bulten_no=eq.${bultenNo}&select=bulten_no`, {
        headers: Object.assign({ Prefer: 'count=exact', Range: '0-0' }, H)
      });
      if (!r.ok && r.status !== 206) {
        const t = await r.text();
        throw new Error(`HTTP ${r.status} ${t.slice(0, 160)}`);
      }
      const cr = r.headers.get('content-range') || '';
      const m = cr.match(/\/(\d+)\s*$/);
      if (!m) throw new Error('Content-Range okunamadi: "' + cr + '"');
      return Number(m[1]);
    } catch (e) {
      sonHata = e;
      if (d < DENEME) await new Promise(res => setTimeout(res, 1500 * d));
    }
  }
  throw sonHata;
}

(async () => {
  if (!SB_KEY) {
    // KÖR: ölçemedik. "Temiz" demek yerine körlüğü ilan ediyoruz.
    log('KOR: SUPABASE_SERVICE_KEY yok - mutabakat OLCULEMEDI.');
    log('     Bu "kayip yok" demek DEGILDIR; olcum yapilamadi.');
    yaz('KOR', 'anahtar yok, olcum yapilamadi', []);
    process.exit(1);
  }

  let kutuk;
  try { kutuk = await kutukOku(); }
  catch (e) {
    log('KOR: kutuk okunamadi -> ' + e.message);
    log('     Bu "kayip yok" demek DEGILDIR.');
    yaz('KOR', 'kutuk okunamadi: ' + e.message, []);
    process.exit(1);
  }
  if (!Array.isArray(kutuk) || !kutuk.length) {
    log('KOR: yutulmus bulten yok ya da cevap bos - karsilastirilacak sey yok.');
    yaz('KOR', 'karsilastirilacak bulten yok', []);
    process.exit(1);
  }

  const t0 = Date.now();
  const satir = new Array(kutuk.length);
  let sira = 0;
  async function isci() {
    while (sira < kutuk.length) {
      const i = sira++;
      const k = kutuk[i];
      const s = { bulten_no: k.bulten_no, yayin_tarihi: k.yayin_tarihi, kutuk: Number(k.kayit), tablo: null, fark: null };
      try {
        s.tablo = await tabloSay(k.bulten_no);
        s.fark = s.tablo - s.kutuk;
      } catch (e) {
        s.hata = String(e && e.message || e).slice(0, 200);
      }
      satir[i] = s;
    }
  }
  await Promise.all(Array.from({ length: ES_ZAMANLI }, isci));
  const sureSn = Math.round((Date.now() - t0) / 100) / 10;

  const olculen  = satir.filter(x => x.tablo !== null);
  const kor      = satir.filter(x => x.tablo === null);
  const bozuk    = olculen.filter(x => x.fark !== 0);
  const kutukToplam = olculen.reduce((a, x) => a + x.kutuk, 0);
  const tabloToplam = olculen.reduce((a, x) => a + x.tablo, 0);

  log(`Kutukte bitti bulten   : ${satir.length}`);
  log(`Sayilabilen            : ${olculen.length}  (${sureSn} sn)`);
  log(`Kutuk toplami (sayilan): ${kutukToplam}`);
  log(`Tablo toplami (sayilan): ${tabloToplam}`);
  if (kor.length) {
    log(`Sayilamayan            : ${kor.length}`);
    kor.slice(0, 10).forEach(x => log(`   bulten ${x.bulten_no}: ${x.hata}`));
  }

  const ek = { bulten: satir.length, sayilan: olculen.length, sure_sn: sureSn,
               olculemeyen: kor.map(x => ({ bulten_no: x.bulten_no, hata: x.hata })).slice(0, 50) };

  if (bozuk.length) {
    log(`\nKIRMIZI: ${bozuk.length} bultende FARK VAR (toplam ${tabloToplam - kutukToplam} kayit)`);
    bozuk.slice(0, 20).forEach(x => {
      const y = x.fark < 0 ? 'TABLODA EKSIK' : 'tabloda FAZLA';
      log(`   bulten ${x.bulten_no} (${x.yayin_tarihi}): kutuk ${x.kutuk} · tablo ${x.tablo} · ${y} ${Math.abs(x.fark)}`);
    });
    if (bozuk.length > 20) log(`   ... ${bozuk.length - 20} bulten daha`);
    log('\nNE YAPMALI: ilgili bulteni yeniden yut ->');
    log('  Actions > Marka Bulteni > Run workflow > mod: bulten · numara: <bulten no>');
    log('  (kutuk kaydini "bitti"den cikarmak icin --zorla gerekir; bulten modu bunu yapar)');
    yaz('KIRMIZI', `${bozuk.length} bultende fark` + (kor.length ? ` · ${kor.length} bulten sayilamadi` : ''),
        bozuk.slice(0, 50).sort((a, b) => Math.abs(b.fark) - Math.abs(a.fark)), ek);
    process.exit(1);
  }

  if (kor.length) {
    log(`\nKOR: ${kor.length}/${satir.length} bulten SAYILAMADI; sayilan ${olculen.length} bultende fark yok.`);
    log('     Sayilamayanlar icin "kayip yok" DENEMEZ.');
    yaz('KOR', `${kor.length}/${satir.length} bulten sayilamadi; sayilan ${olculen.length} bultende fark yok`, [], ek);
    process.exit(1);
  }

  log(`\nYESIL: ${satir.length} bultenin hepsinde kutuk = tablo. Sessiz kayip yok.`);
  yaz('YESIL', `${satir.length} bulten, ${tabloToplam} kayit, fark yok`, [], ek);
})().catch(e => {
  console.error('!! ISTISNA: ' + (e && e.stack || e));
  yaz('KOR', 'istisna: ' + (e && e.message), []);
  process.exit(1);
});
