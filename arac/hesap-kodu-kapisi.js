#!/usr/bin/env node
// ============================================================================
//  KAPI-HK — HESAP KODU KAPISI (30.09.2026, Cem "1.2.3 üçünü de yap, bu kural olsun her sınavda")
//  Öğrenciye görünen soru alanlarında geçen Tekdüzen Hesap Planı kodlarını ambardaki THP ile karşılaştırır:
//    HK-YOK : "hesap/hs." bağlamında ya da yevmiye satırında geçen 3 haneli kod THP'de YOK (ör. 528, 552, 714, 739)
//    HK-AD  : kodun hemen yanında yazan hesap adı THP'deki adla UYUŞMUYOR (ör. "481 Ertelenmiş Vergi Borcu" → THP 481 Gider
//             Tahakkukları; "522 İhraç İskontoları" → THP 522 MDV Yeniden Değerleme Artışları; "644 Menkul Kıymetler Değer Artışı")
//  ÖLÇÜLDÜ (30.09 SGS risk okuması): bu iki desen hakemden ve kör çözümden geçmiş soruların açıklama/adım/ikiz alanlarında
//    onlarca kez çıktı (ertelenmiş vergi 481/391/292/950, 7xx 714/715/739/741, 5xx 522/528/552, 644, 649, 660, 630).
//  THP listesi: veri/sinav/thp-hesap-kodlari.json (ambardan: node arac/hesap-kodu-kapisi.js --tazele; SUPABASE_SERVICE_KEY).
//  🚫 GÖRMEZ: kod doğru ama BAĞLAMDA yanlış hesap (ör. vadesi belirsiz satışta 220 yerine 120; "nakden" ama 102) ·
//     adsız ve "hesap" kelimesi geçmeyen tek başına sayı · 7/B'ye özgü kodlar ambarda yoksa HK-YOK yanlış alarmı verebilir
//     (öz-sınavda 7/B kodu 796 vakası var) · kodun adı kısaltılmış/serbest yazılmışsa HK-AD eşik altında kalabilir.
//  Kullanım: node arac/hesap-kodu-kapisi.js --sinav | --tazele | --banka <sgs|smmm|kgk> (yayındaki soruları ölçer)
//            require('./hesap-kodu-kapisi.js').kusurlar(soru) → [{tur, kod, ad, alan}]
// ============================================================================
const fs = require('fs'), path = require('path');
const KOK = path.resolve(__dirname, '..');
const LISTE = path.join(KOK, 'veri', 'sinav', 'thp-hesap-kodlari.json');
const MODEL = new Set(['hakem', 'hakem2', 'kor_cozum', 'simulasyon_sonnet', 'kaynak_metin_ozet', 'kaynak_adlar', 'capa_metin', 'capa_kaynak', 'atif_genisletme', 'mukerrer']);

const katla = s => String(s || '').toLocaleLowerCase('tr').replace(/ı/g, 'i').normalize('NFD').replace(/[̀-ͯ]/g, '').replace(/[^a-z0-9 ]/g, ' ').replace(/\s+/g, ' ').trim();
const DOLGU = new Set(['hesabi', 'hesap', 've', 'ile', 'veya', 'diger', 'ler', 'lar', 'mdv', 'm', 'd', 'v']);
const koklar = s => katla(s).split(' ').filter(w => w.length >= 3 && !DOLGU.has(w)).map(w => w.slice(0, 5));

let THP = null;
function thp() { if (THP) return THP; THP = fs.existsSync(LISTE) ? JSON.parse(fs.readFileSync(LISTE, 'utf8')).kodlar : {}; return THP; }

// ad uyumu: yazılan adın kökleri ile THP adının kökleri arasında ortak kök var mı (en az 1 anlamlı ortak kök ya da THP kökünün yarısı)
function adUyar(yazilan, resmi) {
  const a = koklar(yazilan), b = koklar(resmi); if (!a.length || !b.length) return true;
  const ortak = b.filter(x => a.includes(x)).length;
  if (a.every(x => b.includes(x))) return true;   // yazilan ad resmi adin kisaltmasi/alt kumesi ("253 TESİS", "371 DÖNEM K")
  return ortak >= Math.min(2, Math.ceil(b.length / 2)) || (b.length === 1 && ortak === 1);
}
function metinleri(o, p, out) {
  if (o == null) return out;
  if (typeof o === 'string') { out.push([p, o]); return out; }
  if (typeof o === 'object') for (const [k, v] of Object.entries(o)) { if (!p && MODEL.has(k)) continue; metinleri(v, p ? p + '.' + k : k, out); }
  return out;
}
// 3 haneli kod + ardından BÜYÜK HARFLE ya da Başharfle başlayan ad (en çok 6 kelime)
const KOD_AD = /(?<![\d.,])\b([1-9]\d{2})\b\s*(?:no\.?(?:lu|lı)?\s*|numaral[ıi]\s*)?(?:[-–—:]\s*)?((?:[A-ZÇĞİÖŞÜ][A-Za-zÇĞİÖŞÜçğıöşü.'’()/]*\s*){1,6})/g;
const KOD_HESAP = /(?<![\d.,])\b([1-9]\d{2})\b\s*(?:no\.?(?:lu|lı)?\s*|numaral[ıi]\s*)?(?:[-–—]\s*)?(?:nolu\s+)?(?:hesab|hesap|hs\.)/gi;
const HESAP_KOD = /(?:hesab[ıi]?|hesap|hs\.)\s*(?:no\.?\s*)?:?\s*([1-9]\d{2})\b(?![\d.,])/gi;

function kusurlar(soru) {
  const K = thp(); if (!Object.keys(K).length) return [{ tur: 'HK-KOR', kod: '', ad: 'THP listesi yok', alan: '' }];
  const out = []; const gor = new Set();
  const ekle = (tur, kod, ad, alan) => { const k = tur + kod + katla(ad).slice(0, 20); if (!gor.has(k)) { gor.add(k); out.push({ tur, kod, ad: String(ad || '').trim().slice(0, 60), alan }); } };
  for (const [alan, t] of metinleri(soru, '', [])) {
    let m;
    KOD_AD.lastIndex = 0;
    while ((m = KOD_AD.exec(t))) {
      const [, kod, adHam] = m; const ad = adHam.replace(/\s+(TL|₺|Tl)\b.*$/, '').trim();
      if (katla(ad).split(' ').filter(w => w.length >= 3).length < 1) continue;
      if (/(TUZA|SINAV|KVYK|UVYK|BDS|TMS|TFRS|UDS)/i.test(ad)) continue;   // etiket/standart adi, hesap adi degil
      if (/^(BORÇ|BORC|ALACAK|B|A|KVYK|UVYK|DVYK)(?=[\s).,;]|$)[\s).,;]*$/i.test(ad)) continue;   // yevmiye yonu / oran kisaltmasi, hesap adi degil
      if (/(BDS|TMS|TFRS|UDS|ISA|IFRS|SDS|BOBİ|KAYDS|madde|m\.|p\.|md\.|say[ıi]l[ıi])\s*$/i.test(t.slice(Math.max(0, m.index - 12), m.index))) continue;   // standart/madde numarasi
      if (/^(TL|Tl|₺|YTL|USD|EUR|Adet|Birim|Gün|Ay|Yıl|Saat|Kg|Ton|Metre|Kişi|İşçi|Adet)\b/i.test(ad)) continue;
      if (!K[kod] && /^[89]/.test(kod)) continue;   // 8 (serbest) ve 9 (nazim) gruplari isletmeye gore acilir, THP listesinde yok
      if (!K[kod]) { if (/[A-ZÇĞİÖŞÜ]{3,}/.test(ad) || /hesab|hesap/i.test(t.slice(m.index, m.index + 80))) ekle('HK-YOK', kod, ad, alan); continue; }
      if (/^[A-ZÇĞİÖŞÜ .'’()/-]{6,}$/.test(ad.split(/\s{2,}/)[0]) || /[A-ZÇĞİÖŞÜ]{4,}/.test(ad)) { if (!adUyar(ad, K[kod])) ekle('HK-AD', kod, ad + ' ≠ ' + K[kod], alan); }
    }
    for (const re of [KOD_HESAP, HESAP_KOD]) { re.lastIndex = 0; while ((m = re.exec(t))) { const kod = m[1]; if (/hesapla/i.test(t.slice(m.index, m.index + 40))) continue; if (/^[89]/.test(kod)) continue; if (/g[üu]n/i.test(t.slice(m.index, m.index + 12))) continue; if (/(BDS|TMS|TFRS|UDS|ISA|madde|m\.|p\.)\s*$/i.test(t.slice(Math.max(0, m.index - 12), m.index))) continue; if (!K[kod]) ekle('HK-YOK', kod, '(hesap bağlamı)', alan); } }
  }
  return out;
}

async function tazele() {
  const Kk = process.env.SUPABASE_SERVICE_KEY; if (!Kk) { console.error('SUPABASE_SERVICE_KEY yok'); process.exit(2); }
  const ad = []; for (let o = 0; ; o += 1000) { const r = await fetch('https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar?select=kaynak_ad&order=kaynak_ad.asc&kaynak_ad=ilike.' + encodeURIComponent('THP %') + '&limit=1000&offset=' + o, { headers: { apikey: Kk, Authorization: 'Bearer ' + Kk, 'User-Agent': 'mevzuat-radar-robot/1.0' } }); if (!r.ok) throw new Error('ambar ' + r.status); const j = await r.json(); ad.push(...j.map(x => x.kaynak_ad)); if (j.length < 1000) break; }
  const kodlar = {}; for (const a of ad) { const m = a.match(/^THP (\d{3})\b\s*[-–]?\s*(.*)$/); if (m) { const n = m[2].replace(/\s*\[\d+\/\d+\]\s*$/, '').trim(); if (!kodlar[m[1]] || kodlar[m[1]].length < n.length) kodlar[m[1]] = n; } }
  if (Object.keys(kodlar).length < 200) { console.error('THP listesi şüpheli küçük (' + Object.keys(kodlar).length + '), YAZILMADI'); process.exit(3); }
  fs.writeFileSync(LISTE, JSON.stringify({ aciklama: 'Ambardaki Tekdüzen Hesap Planı kodları ve adları (arac/hesap-kodu-kapisi.js --tazele). KAPI-HK bunu kullanır.', olcum: new Date().toISOString().slice(0, 10), sayi: Object.keys(kodlar).length, kodlar }, null, 1) + '\n');
  console.log('THP: ' + Object.keys(kodlar).length + ' kod → ' + path.relative(KOK, LISTE));
}

function banka(sinav) {
  const d = path.join(KOK, 'veri', 'sinav', 'kaydir-secim'); const ids = new Set();
  for (const f of fs.readdirSync(d).filter(f => new RegExp('^(yayin|vitrin)-' + sinav + '-').test(f))) for (const r of JSON.parse(fs.readFileSync(path.join(d, f), 'utf8').replace(/^﻿/, ''))) if (r.etiket && r.id) ids.add(r.etiket + '/' + r.id);
  const onb = {}; const sonuc = []; let okunan = 0;
  for (const k of ids) { const [e, kp] = k.split('/'); if (!(e in onb)) { const p = path.join(KOK, 'veri', 'fabrika', 'kalip-parti-' + e + '.json'); onb[e] = fs.existsSync(p) ? JSON.parse(fs.readFileSync(p, 'utf8').replace(/^﻿/, '')) : null; } const q = onb[e] && onb[e][kp]; if (!q) continue; okunan++; const ks = kusurlar(q); if (ks.length) sonuc.push({ anahtar: k, kusurlar: ks }); }
  const tur = {}; for (const s of sonuc) for (const k of s.kusurlar) tur[k.tur] = (tur[k.tur] || 0) + 1;
  console.log(`KAPI-HK banka (${sinav}): yayında ${ids.size} · okunan ${okunan} · kusurlu soru ${sonuc.length} · ${JSON.stringify(tur)}`);
  return sonuc;
}

function sinav() {
  THP = { '200': 'x', '252': 'BİNALAR', '253': 'TESİS, MAKİNE VE CİHAZLAR', '100': 'Kasa', '102': 'Bankalar', '120': 'Alıcılar', '153': 'Ticari Mallar', '220': 'ALICILAR', '481': 'GİDER TAHAKKUKLARI', '522': 'M.D.V. YENİDEN DEĞERLEME ARTIŞLARI', '644': 'KONUSU KALMAYAN KARŞILIKLAR', '770': 'Genel Yönetim Giderleri', '730': 'Genel Üretim Giderleri', '796': 'DİĞER ÇEŞİTLİ GİDERLER' };
  const V = [
    ['olmayan kod + ad (528 İptal Zararları)', { adimlar: [{ anlatim: '528 İPTAL ZARARLARI hesabına borç' }] }, 'HK-YOK'],
    ['var olan kod yanlış ad (481 Ertelenmiş Vergi)', { aciklama: { A: '481 ERTELENMİŞ VERGİ BORCU hesabına alacak' } }, 'HK-AD'],
    ['var olan kod yanlış ad (522 İhraç İskontoları)', { sade: { dogru: 'Fark 522 İHRAÇ İSKONTOLARI hesabına yazılır.' } }, 'HK-AD'],
    ['"hesap" bağlamında olmayan kod (714 nolu hesap)', { soru: 'Fark 714 nolu hesapta izlenir.' }, 'HK-YOK'],
    ['doğru kod doğru ad → temiz', { soru: 'Tutar 153 TİCARİ MALLAR hesabına, KDV 102 Bankalar üzerinden ödenir.' }, null],
    ['kısaltılmış doğru ad → temiz (644 Konusu Kalmayan Karş.)', { aciklama: { B: '644 KONUSU KALMAYAN KARŞ. hesabına alacak' } }, null],
    ['tutar/adet yanlış alarm yok (150 İşçi, 360 Gün)', { soru: 'İşletmede 150 İşçi çalışıyor; yıl 360 Gün kabul edilir.' }, null],
    ['7/B kodu listede → temiz (796)', { aciklama: { C: '796 DİĞER ÇEŞİTLİ GİDERLER hesabına' } }, null],
    ['kısaltma → temiz (253 TESİS)', { aciklama: { A: '253 TESİS hesabına borç' } }, null],
    ['yön kelimesi → temiz (102 BORÇ)', { cozum_tablo: { satirlar: [['102 BORÇ', '10.000']] } }, null],
    ['standart numarası → temiz (BDS 505 Dış Teyitler)', { dayanak: 'BDS 505 DIŞ TEYİTLER p.7' }, null],
    ['"hesaplama" bağlamı → temiz', { soru: '200 hesaplamasında hata yapılmıştır.' }, null],
    ['gerçek hata (252 TAŞITLAR)', { adimlar: [{ anlatim: '252 TAŞITLAR hesabına borç' }] }, 'HK-AD'],
    ['etiket → temiz (500 SINAV TUZAĞI)', { teshis: { A: '500 SINAV TUZAĞI: yanlış yol' } }, null],
    ['nazım/serbest grup → temiz (900 hesabı)', { soru: 'Teminat 900 hesabında izlenir.' }, null],
    ['nazım grup adıyla → temiz (910 NAZIM TEMİNAT)', { aciklama: { D: 'Teminat 910 NAZIM TEMİNAT MEKTUPLARI ile izlenir' } }, null],
    ['model alanı taranmaz (hakem)', { hakem: { gerekce: '528 İPTAL ZARARLARI' } }, null],
  ];
  let ok = 0; for (const [ad, q, bek] of V) { const ks = kusurlar(q); const g = bek ? ks.some(k => k.tur === bek) : ks.length === 0; if (g) ok++; console.log((g ? '  ✓ ' : '  ✗ ') + ad + (g ? '' : ' → ' + JSON.stringify(ks))); }
  console.log(`KAPI-HK ÖZ-SINAVI ${ok === V.length ? 'YEŞİL' : 'KIRMIZI'} (${ok}/${V.length})`); process.exit(ok === V.length ? 0 : 1);
}

module.exports = { kusurlar, adUyar };
if (require.main === module) {
  const a = process.argv[2];
  if (a === '--sinav') sinav();
  else if (a === '--tazele') tazele().catch(e => { console.error(e.message); process.exit(1); });
  else if (a === '--banka') { const s = banka(process.argv[3] || 'sgs'); if (process.argv[4]) fs.writeFileSync(process.argv[4], JSON.stringify(s, null, 1)); }
  else { console.log('--sinav | --tazele | --banka <sgs|smmm|kgk> [cikti.json]'); process.exit(2); }
}
