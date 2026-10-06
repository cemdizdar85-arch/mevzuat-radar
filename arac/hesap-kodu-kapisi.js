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
// 07.10 (Cem "1.2.3", SGS vitrin onarımı): 'hesaplar' = yayın dönüştürücüsünün (motor/kaydir-coz.ps1 ThpTanim) ambardaki THP RESMÎ
//   tanımından kopyaladığı sözlük; yazılmış açıklama değil. Resmî metni THP ad listesiyle sınamak yanlış alarm üretiyordu:
//   "690 Dönem Kar veya Zararı" ↔ "Karı" (sgs-k5-fmuh-cokzor/kp-04), THP 122 metnindeki 652 atfı (sgs-c5-ekonomi-cokzor-r2/kp-08).
//   Parti kayıtlarında bu alan yok → üretim/yayın şartı etkilenmez; yalnız basılmış (paket_soru) kayıtta taranmaz.
const MODEL = new Set(['hakem', 'hakem2', 'kor_cozum', 'simulasyon_sonnet', 'kaynak_metin_ozet', 'kaynak_adlar', 'capa_metin', 'capa_kaynak', 'atif_genisletme', 'mukerrer', 'aciklama_hakem', ...(process.env.HK_MUTASYON === 'hesaplar-tara' ? [] : ['hesaplar'])]);

const katla = s => String(s || '').toLocaleLowerCase('tr').replace(/ı/g, 'i').normalize('NFD').replace(/[̀-ͯ]/g, '').replace(/[^a-z0-9 ]/g, ' ').replace(/\s+/g, ' ').trim();
const DOLGU = new Set(['hesabi', 'hesap', 've', 'ile', 'veya', 'diger', 'ler', 'lar', 'mdv', 'm', 'd', 'v']);
const koklar = s => katla(s).split(' ').filter(w => w.length >= 3 && !DOLGU.has(w)).map(w => w.slice(0, 5));

let THP = null;
// 30.09 (resmî RG doğrulaması: MSUGT Sıra No:2, RG 16.12.1993/21790, C/12): 652 REESKONT FAİZ GİDERLERİ 657'ye taşındı, 652 BOŞ.
//   Ambarda 1992 metniyle hâlâ canlı (id 8f00770e…) → --tazele listeye geri getirir; mülga kodlar burada ayrıca düşülür.
const MULGA_KOD = { '652': '657 REESKONT FAİZ GİDERLERİ (-) — MSUGT Sıra No:2 C/12' };
function thp() { if (THP) return THP; THP = fs.existsSync(LISTE) ? JSON.parse(fs.readFileSync(LISTE, 'utf8')).kodlar : {}; for (const k of Object.keys(MULGA_KOD)) delete THP[k]; return THP; }

// ad uyumu: yazılan adın kökleri ile THP adının kökleri arasında ortak kök var mı (en az 1 anlamlı ortak kök ya da THP kökünün yarısı)
const kdvAd = s => String(s).replace(/katma\s+de[ğgĞG]er\s+verg[iİıI]s[iİıI]/gi, 'KDV')   // 30.09: "Diğer Katma Değer Vergisi" = THP "DİĞER KDV"
  .replace(/[iİ]lk\s*madde/gi, 'İLK MADDE');                                                   // 30.09 SMMM: "İLKMADDE" bitişik yazım
// kök eşitliği: tekil/çoğul ekleri ("FARKI" / "FARKLARI") ilk 4 harfte buluşur (30.09 SMMM: "733 Verimlilik Farkı")
const esK = (x, y) => x === y || (x.length >= 4 && y.length >= 4 && x.slice(0, 4) === y.slice(0, 4));
const icinde = (x, dizi) => dizi.some(y => esK(x, y));
function adUyar(yazilan, resmi) {
  const a = koklar(kdvAd(yazilan)), b = koklar(kdvAd(resmi)); if (!a.length || !b.length) return true;
  const ortak = b.filter(x => icinde(x, a)).length;
  if (a.every(x => icinde(x, b))) return true;   // yazilan ad resmi adin kisaltmasi/alt kumesi ("253 TESİS", "371 DÖNEM K")
  return ortak >= Math.min(2, Math.ceil(b.length / 2)) || (b.length === 1 && ortak === 1);
}
function metinleri(o, p, out) {
  if (o == null) return out;
  if (typeof o === 'string') { out.push([p, o]); return out; }
  if (typeof o === 'object') for (const [k, v] of Object.entries(o)) { if (!p && MODEL.has(k)) continue; metinleri(v, p ? p + '.' + k : k, out); }
  return out;
}
// 30.09 hk-65 onarımında elle yargılanan yanlış alarmlar: grup adıyla ya da yerleşik kısaltmayla yazılan doğru kod
const GRUP_KISA = { '15': /^STOK(LAR)?\b/i, '62': /^S(T)?MM\b/i };
// 3 haneli kod + ardından BÜYÜK HARFLE ya da Başharfle başlayan ad (en çok 6 kelime)
const KOD_AD = /(?<![\d.,])\b([1-9]\d{2})\b\s*(?:no\.?(?:lu|lı)?\s*|numaral[ıi]\s*)?(?:[-–—:)]\s*)?((?:[A-ZÇĞİÖŞÜ][A-Za-zÇĞİÖŞÜçğıöşü.'’()/]*\s*){1,6})/g;
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
      if (/(TUZA|SINAV|KVYK|UVYK|BDS|TMS|TFRS|\bUDS\b)/i.test(ad)) continue;   // etiket/standart adi, hesap adi degil
      if (/^(BORÇ|BORC|ALACAK|B|A|KVYK|UVYK|DVYK)(?=[\s).,;]|$)[\s).,;]*$/i.test(ad)) continue;   // yevmiye yonu / oran kisaltmasi, hesap adi degil
      if (/(BDS|TMS|TFRS|UDS|ISA|IFRS|SDS|BOBİ|KAYDS|Standard[ıi]|Standartlar[ıi]|madde|m\.|p\.|md\.|say[ıi]l[ıi])\s*$/i.test(t.slice(Math.max(0, m.index - 12), m.index))) continue;   // standart/madde numarasi (30.09: "Bağımsız Denetim Standardı 505" yanlış alarmı)
      if (/\d{3}\s*[\/–-]\s*$/.test(t.slice(Math.max(0, m.index - 6), m.index))) continue;   // birleşik kod "180/280 GELECEK AYLARA-YILLARA" (30.09 yanlış alarm)
      if (GRUP_KISA[kod.slice(0, 2)] && GRUP_KISA[kod.slice(0, 2)].test(ad)) continue;   // grup kısaltması "153 STOK", "621 STMM" (30.09 yanlış alarm)
      if (/^(BOR[ÇC]|ALACAK)LAN/i.test(ad)) continue;   // 30.09 SMMM: "760 ALACAKLANIR" / "BORÇLANDIRILIR" yön fiili, hesap adı değil
      if (/^(TL|Tl|₺|YTL|USD|EUR|Adet|Birim|Gün|Ay|Yıl|Saat|Kg|Ton|Metre|Kişi|İşçi|Adet)\b/i.test(ad)) continue;
      if (!K[kod] && /^[89]/.test(kod)) continue;   // 8 (serbest) ve 9 (nazim) gruplari isletmeye gore acilir, THP listesinde yok
      // 30.09 (SMMM oturumu bildirdi): ambarda THP 17 grubu (170/178/179) HİÇ yok → listede grubu olmayan kod için hüküm verilmez (liste eksiği ≠ soru kusuru)
      if (!K[kod] && !Object.keys(K).some(c => c.slice(0, 2) === kod.slice(0, 2))) continue;
      // 30.09: "THP 151 - FIFO basamak 4" paragraf künyesi — kodun ardındaki metin hesap adı değil
      if (/THP\s*$/.test(t.slice(Math.max(0, m.index - 5), m.index)) && /^\s*[-–—]/.test(t.slice(m.index + 3, m.index + 6))) continue;
      // 30.09: tek büyük harfli sözcük ("324 EBOB", matematik) hesap adı sayılmaz; hesap bağlamı yoksa en az iki sözcük ister
      if (!K[kod]) { if ((/[A-ZÇĞİÖŞÜ]{3,}/.test(ad) && ad.trim().split(/\s+/).length >= 2) || /hesab|hesap/i.test(t.slice(m.index, m.index + 80))) ekle('HK-YOK', kod, ad, alan); continue; }
      // 30.09 (SMMM oturumu ölçtü): olağan cümle yazımı "252 Taşıtlar hesabı" / "Borç: 252 Taşıtlar" kaçıyordu → Başharfli ad da,
      //   yalnız hesap bağlamında (40 karakter içinde "hesap") ya da yevmiye satırında ("Borç:"/"Alacak:") denetlenir.
      //   Ölçülen yanlış alarmlar (SGS bankası, 30.09): "Hesabının Kalanı"/"Hesap Açıklaması" (ad değil, ifade), paragraf künyesi
      //   "… Hesaplarının İşleyişi", "Yansıtma Hesabına" (sondaki "hesap" sözcüğü ad değil) → ayıklanır.
      if (/^Hesa[bp]/i.test(ad) || /İşleyiş|Açıklama/i.test(ad)) continue;
      const adK = ad.replace(/\s+Hesa[bp]\S*(\s.*)?$/i, '').trim();
      const basharf = /^[A-ZÇĞİÖŞÜ][a-zçğıöşü]/.test(adK) && adK.split(/\s+/).some(w => w.length >= 4) && (/^[^.;!?]{0,40}hesa[bp]/i.test(t.slice(m.index, m.index + 60)) || /(Borç|Alacak)\s*[:.]?\s*$/i.test(t.slice(Math.max(0, m.index - 10), m.index)));
      if (basharf || /^[A-ZÇĞİÖŞÜ .'’()/-]{6,}$/.test(ad.split(/\s{2,}/)[0]) || /[A-ZÇĞİÖŞÜ]{4,}/.test(ad)) {
        if (!adUyar(adK || ad, K[kod])) ekle('HK-AD', kod, ad + ' ≠ ' + K[kod], alan);
        else {
          // 30.09 (SMMM oturumu 312 soruluk okumayla ölçtü): yazılan ad BAŞKA bir kodun adına tam uyuyor, kendi kodununkine uymuyor
          //   ("620 Satılan Ticari Mallar Maliyeti" → 621, "656 Diğer Olağan Gider ve Zararlar" → 659) — ortak kök eşiği bunu geçiriyordu.
          const a = koklar(kdvAd(adK || ad)), oz = koklar(kdvAd(K[kod]));
          if (a.length >= 2 && !a.every(x => icinde(x, oz))) {
            const diger = Object.keys(K).find(c => c !== kod && a.every(x => icinde(x, koklar(kdvAd(K[c])))));
            if (diger) ekle('HK-AD', kod, ad + ' ≈ ' + diger + ' ' + K[diger], alan);
          }
        }
      }
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
  THP = { '200': 'x', '652': 'REESKONT FAİZ GİDERLERİ (-)', '657': 'REESKONT FAİZ GİDERLERİ (-)', '760': 'PAZARLAMA SATIŞ VE DAĞITIM GİDERLERİ', '280': 'GELECEK YILLARA AİT GİDERLER', '320': 'SATICILAR', '500': 'SERMAYE', '151': 'YARI MAMULLER-ÜRETİM', '150': 'İLK MADDE VE MALZEME', '733': 'GENEL ÜRETİM GİDERLERİ VERİMLİLİK FARKLARI', '679': 'DİĞER OLAĞANDIŞI GELİR VE KARLAR', '689': 'Diğer Olağandışı Gider ve Zararlar', '521': 'HİSSE SENEDİ İPTAL KARLARI', '620': 'SATILAN MAMULLER MALİYETİ (-)', '621': 'Satılan Ticari Mallar Maliyeti (-)', '254': 'TAŞITLAR', '690': 'DÖNEM KARI VEYA ZARARI', '110': 'HİSSE SENETLERİ', '731': 'Genel Üretim Giderleri Yansıtma Hesabı', '190': 'DEVREDEN KATMA DEĞER VERGİSİ', '191': 'İNDİRİLECEK KDV', '252': 'BİNALAR', '253': 'TESİS, MAKİNE VE CİHAZLAR', '100': 'Kasa', '102': 'Bankalar', '120': 'Alıcılar', '153': 'Ticari Mallar', '220': 'ALICILAR', '481': 'GİDER TAHAKKUKLARI', '522': 'M.D.V. YENİDEN DEĞERLEME ARTIŞLARI', '644': 'KONUSU KALMAYAN KARŞILIKLAR', '770': 'Genel Yönetim Giderleri', '730': 'Genel Üretim Giderleri', '796': 'DİĞER ÇEŞİTLİ GİDERLER' };
  for (const k of Object.keys(MULGA_KOD)) delete THP[k];   // gerçek yüklemeyle aynı mülga düşümü
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
    ['uzun standart adı → temiz (Bağımsız Denetim Standardı 505)', { sade: { sinav: 'Bağımsız Denetim Standardı 505 Dış Teyitler kapsamında banka hesapları karşılaştırılır.' } }, null],
    ['MSUGT künyesi (Sıra No yok) → temiz', { dayanak: 'THP 380 - MSUGT hesap açıklamaları' }, null],
    ['grup kısaltması → temiz (153 STOK, 621 STMM)', { teshis: { A: '153 STOKLAR artar; 621 STMM hesabına borç' } }, null],
    ['birleşik kod → temiz (180/280 GELECEK AYLARA-YILLARA)', { hap: '180/280 GELECEK AYLARA-YILLARA AİT GİDERLER' }, null],
    ['MSUGT künyesi → temiz (THP 380 - MSUGT Sıra No:1)', { teshis: { D: { paragraf: 'THP 380 - MSUGT Sıra No:1' } } }, null],
    ['grup kısaltması gerçek hatayı örtmez (153 TAŞITLAR)', { aciklama: { A: '153 TAŞITLAR hesabına borç' } }, 'HK-AD'],
    ['UDS etiketi → temiz (400 UDS NOTU)', { teshis: { B: '400 UDS NOTU: kavram' } }, null],
    ['cümle yazımı yakalanır (252 Taşıtlar hesabı)', { aciklama: { A: '252 Taşıtlar hesabı borçlandırılır.' } }, 'HK-AD'],
    ['parantezli kod yakalanır ((252) TAŞITLAR)', { aciklama: { A: '(252) TAŞITLAR hesabına borç yazılır.' } }, 'HK-AD'],
    ['yevmiye satırı yakalanır (Borç: 252 Taşıtlar)', { adimlar: [{ anlatim: 'Borç: 252 Taşıtlar 100.000' }] }, 'HK-AD'],
    ['cümle yazımı doğru ad → temiz (254 Taşıtlar hesabı)', { aciklama: { A: '254 Taşıtlar hesabı borçlandırılır.' } }, null],
    ['"hesabının kalanı" ifadesi → temiz', { ikiz: { tablo: { satirlar: [['690 Hesabının Kalanı', '5.000']] } } }, null],
    ['künye → temiz (Menkul Kıymetler Hesaplarının İşleyişi)', { teshis: { A: { paragraf: 'THP 110 Menkul Kıymetler Hesaplarının İşleyişi' } } }, null],
    ['sondaki hesap sözcüğü → temiz (731 Yansıtma Hesabına)', { celdirici_yol: { E: '731 Yansıtma Hesabına alacak yazılır' } }, null],
    ['KDV = Katma Değer Vergisi → temiz (190 Devreden KDV hesabı)', { konu_giris: { yontemler: '190 Devreden KDV hesabı ile 191 İndirilecek Katma Değer Vergisi hesabı' } }, null],
    ['kısa başharfli sözcük ad sayılmaz (253 Ara toplam hesaplanır)', { sade: { siklar: { B: '253 Ara toplam hesaplanır.' } } }, null],
    ['tek büyük harfli sözcük → temiz ((D) 324 EBOB)', { sade: { siklar: { D: '324) EBOB ile bulunur' } } }, null],
    ['yakın ad başka koda uyuyor (620 Satılan Ticari Mallar Maliyeti → 621)', { adimlar: [{ anlatim: '620 Satılan Ticari Mallar Maliyeti hesabına borç' }] }, 'HK-AD'],
    ['kendi adı → temiz (621 Satılan Ticari Mallar Maliyeti)', { adimlar: [{ anlatim: '621 Satılan Ticari Mallar Maliyeti hesabına borç' }] }, null],
    ['listede grubu olmayan kod → hüküm yok (170 YILLARA YAYGIN İNŞAAT)', { sema: { hesap: '170 YILLARA YAYGIN İNŞAAT VE ONARIM MALİYETLERİ hesabı' } }, null],
    ['listede grubu olan olmayan kod → HK-YOK (528 grubu 52 var)', { adimlar: [{ anlatim: '528 İPTAL ZARARLARI hesabına' }] }, 'HK-YOK'],
    ['THP künyesi → temiz (THP 151 - FIFO basamak 4)', { teshis: { A: { paragraf: 'THP 151 - FIFO basamak 4' } } }, null],
    ['tekil/çoğul → temiz (733 Verimlilik Farkı hesabı)', { aciklama: { A: '733 Verimlilik Farkı hesabına' } }, null],
    ['bitişik yazım → temiz (150 İLKMADDE VE MALZEME)', { sema: { hesap: '150 İLKMADDE VE MALZEME' } }, null],
    ['olağandışı gider 679\'a yazılmış → HK-AD (doğrusu 689)', { sema: { hesap: '679 DİĞER OLAĞANDIŞI GİDER VE ZARARLAR' } }, 'HK-AD'],
    ['yön fiili → temiz (760 ALACAKLANIR, 252 BORÇLANDIRILIR)', { aciklama: { E: 'Gider fazla yazıldığı için 760 ALACAKLANIR; 252 BORÇLANDIRILIR.' } }, null],
    ['mülga kod → HK-YOK (652 REESKONT, 1993 de 657 ye taşındı)', { sema: { hesap: '652 REESKONT FAİZ GİDERLERİ hesabına borç' } }, 'HK-YOK'],
    ['güncel kod temiz (657 REESKONT FAİZ GİDERLERİ)', { sema: { hesap: '657 REESKONT FAİZ GİDERLERİ hesabına borç' } }, null],
    ['model alanı taranmaz (hakem)', { hakem: { gerekce: '528 İPTAL ZARARLARI' } }, null],
    ['07.10: THP resmî sözlüğü (hesaplar) taranmaz', { hesaplar: { '122': { ad: 'ALACAK SENETLERİ REESKONTU (-)', tanim: '652 REESKONT FAİZ GİDERLERİ hesabına gider yazılır' } } }, null],
    ['07.10: aynı metin açıklamada YİNE yakalanır', { aciklama: { A: '652 REESKONT FAİZ GİDERLERİ hesabına borç' } }, 'HK-YOK'],
  ];
  let ok = 0; for (const [ad, q, bek] of V) { const ks = kusurlar(q); const g = bek ? ks.some(k => k.tur === bek) : ks.length === 0; if (g) ok++; console.log((g ? '  ✓ ' : '  ✗ ') + ad + (g ? '' : ' → ' + JSON.stringify(ks))); }
  console.log(`KAPI-HK ÖZ-SINAVI ${ok === V.length ? 'YEŞİL' : 'KIRMIZI'} (${ok}/${V.length})`); process.exit(ok === V.length ? 0 : 1);
}

module.exports = { kusurlar, adUyar };
if (require.main === module) {
  const a = process.argv[2];
  if (a === '--sinav' && process.argv.includes('--mutasyon')) {   // 07.10: 'hesaplar' yeniden taranırsa öz-sınav KIRMIZI olmalı
    const cp = require('child_process'); const r = cp.spawnSync(process.execPath, [__filename, '--sinav'], { env: { ...process.env, HK_MUTASYON: 'hesaplar-tara' }, encoding: 'utf8' });
    const kr = r.status !== 0; console.log('  mutasyon hesaplar-tara ' + (kr ? 'KIRMIZI (doğru)' : 'YEŞİL (SINAV KÖR!)'));
    const n = cp.spawnSync(process.execPath, [__filename, '--sinav'], { encoding: 'utf8' }); console.log(n.stdout.trim().split(/\r?\n/).pop()); process.exit(kr && n.status === 0 ? 0 : 1);
  }
  else if (a === '--sinav') sinav();
  else if (a === '--tazele') tazele().catch(e => { console.error(e.message); process.exit(1); });
  else if (a === '--banka') { const s = banka(process.argv[3] || 'sgs'); if (process.argv[4]) fs.writeFileSync(process.argv[4], JSON.stringify(s, null, 1)); }
  else { console.log('--sinav | --tazele | --banka <sgs|smmm|kgk> [cikti.json]'); process.exit(2); }
}
