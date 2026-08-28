// ============================================================================
//  ALACAK METİN AYRIŞTIR (20.08.2026)
//  Cem: "ilan açıklaması bu kadar mı, neden battı vs bulamıyor muyuz"
//
//  ÖLÇÜLEN KUSUR: ilan.gov.tr detay metni alacak-borclu-cek.ps1 içinde çekiliyor
//  ama SAKLANMIYOR — regexten geçip atılıyordu. Ambarda 9 künye alanı vardı
//  (il/tur/url/vkn/kurum/tarih/baslik/borclu/ilanNo), metin yoktu; canlıda son
//  60 kaydın 31'inde borçlu adı boştu (Cem'in gönderdiği EFEŞAH ilanı dahil:
//  unvan metinde apaçık yazılıyken kayıtta borclu=null).
//
//  Bu betik metni saklar ve İLANIN KENDİSİNDE YAZAN yapılandırılmış alanları
//  çıkarır. "Neden battı" hiçbir resmî ilanda yazmaz (İİK m.288 ilanı hukuki
//  bildirimdir, gerekçe değil) — çıkarılabilecek olan, borçlunun süreçteki
//  YERİdir: hangi mahkeme/dosya, mühlet ne zaman başladı, ne zaman doluyor,
//  komiser kim, itiraz süresi kaç gün.
//
//  ÇOK BORÇLULU İLAN: grup konkordatosunda tek ilanda birden çok borçlu olur
//  (ölçüldü: İstanbul 2. ATM ilanı 3 borçlu, Kastamonu ilanı 6 borçlu).
//  Eski kural "tek geçerli VKN varsa yaz" bunların hepsini eliyordu; artık
//  borclular[] dizisi yazılır, arama tümünde yapılabilsin diye vknler[] de.
//
//  YAZMA KAPISI korunur: bir alan ancak metinde AÇIKÇA varsa yazılır. Emin
//  olunmayan alan boş bırakılır — boş güvenli, yanlış firma göstermek değil.
//
//  Kullanım:  node motor/alacak-metin-ayristir.js [--hedef veri/x.json] [--zorla]
//             node motor/alacak-metin-ayristir.js --test   (7 örnek ilanda ölç)
// ============================================================================
const https = require('https');
const fs = require('fs');
const path = require('path');

const KOK = path.join(__dirname, '..');
// PowerShell'in Out-File -Encoding utf8'i BOM yazar; JSON.parse BOM'u kabul
// etmez (20.08: arsiv kosusu bu yuzden coktu). Okurken kirpilir.
const jsonOku = (y) => JSON.parse(fs.readFileSync(y, 'utf8').replace(/^﻿/, ''));
const ARG = process.argv.slice(2);
const bayrak = (ad) => ARG.includes('--' + ad);
const deger = (ad) => { const i = ARG.indexOf('--' + ad); return i >= 0 ? ARG[i + 1] : null; };

const UA = { 'User-Agent': 'Mozilla/5.0 (MevzuatRadar-Alacak)', 'Accept': 'application/json' };

function detayCek(id) {
  return new Promise((cb) => {
    const u = 'https://www.ilan.gov.tr/api/api/services/app/AdDetail/GetAdDetail?id=' + id;
    https.get(u, { headers: UA, timeout: 30000 }, (res) => {
      let b = ''; res.on('data', (d) => b += d); res.on('end', () => cb(b));
    }).on('error', () => cb('')).on('timeout', function () { this.destroy(); cb(''); });
  });
}

function metinTemizle(html) {
  return String(html || '')
    .replace(/<style[^>]*>[\s\S]*?<\/style>/gi, ' ')
    .replace(/<script[^>]*>[\s\S]*?<\/script>/gi, ' ')
    .replace(/<[^>]+>/g, ' ')
    .replace(/&nbsp;/g, ' ').replace(/&amp;/g, '&').replace(/&quot;/g, '"')
    .replace(/\s+/g, ' ')
    .trim();
}

// --- kimlik doğrulama: uydurma numara ambara girmesin -----------------------
function vknGecerli(s) {
  if (!/^\d{10}$/.test(s)) return false;
  const v = s.split('').map(Number); let top = 0;
  for (let i = 0; i < 9; i++) { const t = (v[i] + (9 - i)) % 10; top += (t === 9) ? 9 : (t * Math.pow(2, 9 - i)) % 9; }
  return v[9] === ((10 - (top % 10)) % 10);
}
function tcknGecerli(s) {
  if (!/^[1-9]\d{10}$/.test(s)) return false;
  const d = s.split('').map(Number);
  const tek = d[0] + d[2] + d[4] + d[6] + d[8], cift = d[1] + d[3] + d[5] + d[7];
  let h10 = ((tek * 7) - cift) % 10; if (h10 < 0) h10 += 10;
  if (d[9] !== h10) return false;
  let t = 0; for (let i = 0; i < 10; i++) t += d[i];
  return d[10] === t % 10;
}

// --- unvan yakalama ---------------------------------------------------------
const SONEK = 'L[İIi]M[İIi]TED\\s+Ş[İIi]RKET[İIi]|ANON[İIi]M\\s+Ş[İIi]RKET[İIi]|Limited\\s+Şirketi|Anonim\\s+Şirketi|LTD\\.?\\s*ŞT[İIi]\\.?|LTD\\.?\\s*ST[İIi]\\.?|Ltd\\.?\\s*Şti\\.?|Kollektif\\s+Şirketi|KOLLEKT[İIi]F\\s+Ş[İIi]RKET[İIi]|Komandit\\s+Şirketi|KOMAND[İIi]T\\s+Ş[İIi]RKET[İIi]';
const KELIME = '(?:[A-ZÇĞİÖŞÜ][A-Za-zÇĞİÖŞÜçğıöşüİı0-9\\.\'’]*|ve|Ve|VE|ile|İle|İLE|için)';
const UNVAN_RX = new RegExp('(' + KELIME + '(?:\\s+' + KELIME + '){0,18}\\s+(?:' + SONEK + '))');
// unvanın önüne yapışan kalıp çöpü (ölçülmüş liste — ps1'deki junk'ın devamı)
const COP = /^(Yukarıda|Sicil|Sayılı|Adresindeki|adresindeki|Olan|olan|Müflis|müflis|Yazılı|yazılı|Numaraları|Numarası|Numaralı|numaralı|Vergi|vergi|Kimlik|kimlik|Kayıtlı|kayıtlı|Tarihli|tarihli|Adres|adres|Nezdinde|Hakkında|hakkında|Davacılar|Davacı|davacı|Davalı|davalı|Ve|ve|İle|ile|Sayın|Borçlu|borçlu|Borçlusu|borçlusu|Ait|ait|Esas|Karar|İLAN|İLANI|İlan|İlanı|Alacaklılar|alacaklılar|Toplantısına|toplantısına|Toplantı|Davet|davet|Tebligat|tebligat|Konusu|konusu|Talebinde|talebinde|Bulunan|bulunan|Talep|talep|Nolu|nolu|No|Mersis|MERSİS|TC|T\.C\.|Numaralı)\s+/;

function unvanTemizle(s) {
  // 20.08 ölçüm: etiketli kalıpta unvandan sonra şehir adı yapışıyordu
  // ("…LİMİTED ŞİRKETİ Bursa"). Şirket son eki unvanın SONUDUR, sonrası kesilir.
  const sk = new RegExp('^([\\s\\S]*?(?:' + SONEK + '))').exec(String(s || ''));
  if (sk) s = sk[1];
  let u = String(s || '').trim().replace(/^["'“”\s.,-]+/, '').replace(/["'“”\s.,-]+$/, '');
  let onceki = null;
  while (u !== onceki && COP.test(u)) { onceki = u; u = u.replace(COP, '').trim(); }
  return u;
}

// Bir kimlik numarasının ÇEVRESİNDEKİ unvanı bul: numara unvandan önce de
// sonra da gelebilir ("2091426181 Vergi Numaralı Cihan ... A.Ş." / "EFEŞAH ...
// LİMİTED ŞİRKETİ (Yüreğir V.D.-3251136127)"). İki yön de denenir, en yakını
// kazanır; hiçbiri tutmazsa unvan BOŞ bırakılır.
function numaraCevresiUnvan(metin, poz, uzunluk) {
  const sonra = metin.slice(poz + uzunluk, poz + uzunluk + 220);
  const once = metin.slice(Math.max(0, poz - 220), poz);
  const ms = UNVAN_RX.exec(sonra);
  if (ms && ms.index < 60) { const u = unvanTemizle(ms[1]); if (u.length >= 6) return u; }
  const tumOnce = [...once.matchAll(new RegExp(UNVAN_RX.source, 'g'))];
  if (tumOnce.length) {
    const son = tumOnce[tumOnce.length - 1];
    const bosluk = once.length - (son.index + son[1].length);
    if (bosluk < 60) { const u = unvanTemizle(son[1]); if (u.length >= 6) return u; }
  }
  return '';
}

function kisiAdiCevresi(metin, poz, uzunluk) {
  // 20.08 ölçüm: ad numaradan SONRA gelir ama araya "T.C. Kimlik numaralı",
  // "gerçek kişi" ve tırnak girebiliyor ([10705168356] TC Kimlik numaralı
  // gerçek kişi "EREN ÇAĞLAR NİRON"). Ad numaradan ÖNCE de gelebilir
  // (Miras Bırakan : ALİ VURAL ÖZCAN - 48775806038).
  const sonra = metin.slice(poz + uzunluk, poz + uzunluk + 140);
  const AD = '([A-ZÇĞİÖŞÜ][A-Za-zÇĞİÖŞÜçğıöşüİı]+(?:\\s+[A-ZÇĞİÖŞÜ][A-Za-zÇĞİÖŞÜçğıöşüİı]+){1,3})';
  const onek = '^[\\s\\]\\),.-]*(?:T\\.?C\\.?\\s*)?(?:Kimlik\\s*)?(?:Numaral[ıi]|numaral[ıi]|No(?:\'?lu)?)?\\s*(?:gerçek\\s*kişi\\s*)?["“”\'\\s]*';
  let m = new RegExp(onek + AD).exec(sonra);
  if (!m) {
    const once = metin.slice(Math.max(0, poz - 90), poz);
    const m2 = new RegExp(AD + '\\s*[-–:\\s]*$').exec(once);
    if (m2) m = m2;
  }
  if (!m) return '';
  const ad = m[1].trim();
  if (/Şirket|ŞİRKET|Mahkeme|MAHKEME|Müdürl|Ticaret|Sicil|Vergi|Kimlik|Numaral|Kanun|Madde|Esas|Karar/i.test(ad)) return '';
  return ad;
}

// Kimlik numarası olmayan borçlu: yalnız AÇIK etiketten (müflis / miras bırakan /
// davacı) — etiket yoksa yazılmaz. 20.08 ölçümünde üç ilan bu yolla kurtarıldı:
// MERSİS numaralı davacı (VKN yok), MÜFLİS: başlıklı sıra cetveli, tereke ilanı.
function etiketliBorclular(metin) {
  const bulunan = [];
  const kaliplar = [
    /M[ÜU]FL[İIi]S\s*:?\s*([^\n]{6,140}?)(?=\s{2,}|\s*Ticaret\s*Sicil|\s*Adres|\s*Vergi|$)/i,
    /(?:Mersis|MERSİS)\s*numaral[ıi]\s*(?:davac[ıi])?\s*["“”']?\s*([^"“”']{6,140}?)["“”']/i,
    /olan\s+m[üu]flis\s+([^,;.]{6,140})/i,
    // NOT: /i bayrağı Türkçe I↔ı eşlemez ("BIRAKAN" ile "Bırakan" tutmaz) —
    // harf sınıfı elle yazılır. 20.08'de tereke ilanı bu yüzden kaçmıştı.
    /M[İIi]RAS\s*B[Iıİi]RAKAN\s*:?\s*([^\n-]{5,90})/i
  ];
  for (const rx of kaliplar) {
    const m = rx.exec(metin);
    if (!m) continue;
    const u = unvanTemizle(m[1]);
    if (u.length >= 6 && u.length <= 140) bulunan.push(u);
  }
  return bulunan;
}

// --- tarih/süre -------------------------------------------------------------
const AY_ADI = { ocak: 1, şubat: 2, subat: 2, mart: 3, nisan: 4, mayıs: 5, mayis: 5, haziran: 6, temmuz: 7, ağustos: 8, agustos: 8, eylül: 9, eylul: 9, ekim: 10, kasım: 11, kasim: 11, aralık: 12, aralik: 12 };
function tariheCevir(s) {
  const m = /^(\d{1,2})[\/.\-](\d{1,2})[\/.\-](\d{4})$/.exec(String(s || '').trim());
  if (!m) return null;
  const g = +m[1], a = +m[2], y = +m[3];
  if (a < 1 || a > 12 || g < 1 || g > 31) return null;
  return { g, a, y, iso: `${y}-${String(a).padStart(2, '0')}-${String(g).padStart(2, '0')}` };
}
function tarihEkle(t, ay) {
  if (!t) return null;
  const d = new Date(Date.UTC(t.y, t.a - 1 + ay, t.g));
  return d.toISOString().slice(0, 10);
}

function muhletCikar(metin) {
  const out = {};
  const kesin = /kes[İIi]n\s*m[üu]hlet/i.test(metin);
  const uzat = /uzat[ıi]lmas/i.test(metin);
  const gecici = /ge[çc][İIi]c[İIi]\s*m[üu]hlet/i.test(metin);
  if (uzat) out.muhlet_tip = 'uzatma';
  else if (kesin) out.muhlet_tip = 'kesin';
  else if (gecici) out.muhlet_tip = 'gecici';

  // süre: "3 AY SÜRE İLE", "3 AYLIK", "1 yıllık", "üç aylık"
  const YAZI = { bir: 1, iki: 2, üç: 3, uc: 3, dört: 4, dort: 4, beş: 5, bes: 5, altı: 6, alti: 6, oniki: 12, on: 10 };
  let ay = null;
  let m = /(\d{1,2})\s*(?:AY|ay)(?:LIK|lık|lik)?\b/.exec(metin);
  if (m) ay = +m[1];
  if (ay === null) { m = /(\d{1,2})\s*(?:YIL|yıl)(?:LIK|lık|lik)?\b/.exec(metin); if (m) ay = +m[1] * 12; }
  if (ay === null) { m = /(bir|iki|üç|uc|dört|dort|beş|bes|altı|alti|on|oniki)\s*(?:ay|AY)(?:lık|LIK|lik)?\b/i.exec(metin); if (m) ay = YAZI[m[1].toLowerCase()] || null; }
  if (ay === null) { m = /(bir|iki|üç|uc)\s*(?:yıl|YIL)(?:lık|LIK)?\b/i.exec(metin); if (m) ay = (YAZI[m[1].toLowerCase()] || 0) * 12 || null; }
  if (ay) out.muhlet_ay = ay;

  // başlangıç: "13/08/2026 tarih saat 17.20'den itibaren", "20/08/2026 tarihinden
  // itibaren başlamak üzere", "14/08/2026 günü saat 15:30 itibariyle"
  const bas = /(\d{1,2}[\/.\-]\d{1,2}[\/.\-]\d{4})\s*(?:tarih(?:li|inden)?|günü|gün)?\s*(?:saat\s*[\d:.]+)?\s*(?:'?den|'?dan|)?\s*itibar/i.exec(metin);
  const t = bas ? tariheCevir(bas[1]) : null;
  if (t) {
    out.muhlet_baslangic = t.iso;
    if (out.muhlet_ay) out.muhlet_bitis = tarihEkle(t, out.muhlet_ay);
  }
  return out;
}

// --- KARAR DURUMU (20.08, Cem: "karar durumu filtresi YAP") -----------------
// Rakip konkordatoilanlari.com karar durumuna göre filtreliyor; bizde yoktu.
// muhlet_tip yetmez: "alacaklılara çağrı" (~331 ilan) ve "ret" onda hiç yok,
// oysa alacaklı için EN KRİTİK olan çağrı ilanıdır — 15 günlük kayıt süresi
// oradan işler (İİK m.299). Sıra: en belirleyici kalıp önce.
// Kaynak: 5.775 ilanın başlık dağılımı ölçülerek çıkarıldı, uydurulmadı.
const DURUMLAR = [
  ['alacak_cagrisi', /alacaklar[ıi]n[ıi]\s*bildirme|alacakl[ıi]lara\s*[çc]a[ğg]r[ıi]|alacakl[ıi]lar[ıi]\s*davet|bildirmeye\s*davet|kay[ıi]t\s*ilan/i],
  // 28.08: "İflasın kaldırılması" (İİK m.182) ret_kaldirma'ya düşüyordu ve
  // alacaklıya İYİ HABERİ KÖTÜ HABER gibi gösteriyordu — borçlu iflastan
  // ÇIKIYOR (borçlar ödendi / alacaklılar talebini geri aldı / konkordato
  // tasdik edildi). ret_kaldirma'dan ÖNCE gelmeli, yoksa "kaldırılmas" kalıbı
  // onu yutar. Konkordatolu olanlar zaten yukarıda ret_iflas'a ayrılıyor.
  ['iflas_kaldirma', /[iİIı]flas[ıi]n\s*kald[ıi]r[ıi]lma/i],
  ['ret_kaldirma',   /reddine|reddi|kald[ıi]r[ıi]lmas|feshine|feshi\b|iptaline/i],
  ['tasdik',         /tasdik(?:ine|i\b|\s*karar)/i],
  ['iflas_tasfiye',  /iflas[ıi]n[ıi]n\s*a[çc][ıi]lmas|iflas\s*karar|s[ıi]ra\s*cetvel|basit\s*tasfiye|tasfiyesinin\s*a[çc][ıi]lmas|masa\b/i],
  ['uzatma',         /uzat[ıi]lmas|uzatma/i],
  ['kesin_muhlet',   /kes[İIi]n\s*m[üu]hlet/i],
  ['gecici_muhlet',  /ge[çc][İIi]c[İIi]\s*m[üu]hlet/i],
  ['durusma',        /duru[şs]ma\s*g[üu]n/i],
  ['muhlet',         /m[üu]hlet/i]
];
// 28.08 ÜRÜN KUSURU (ölçümle bulundu): "Konkordato talebinin REDDİ VE İFLASA
// ilişkin mahkeme kararı" ve "Konkordato mühletinin kaldırılması VE İFLAS
// kararına ilişkin…" ilanları 'ret_kaldirma' damgası yiyordu — çünkü ret kalıbı
// listede iflastan önce geliyor. Oysa bunlar alacaklı için arşivdeki EN KRİTİK
// haberdir: konkordato tutmadı, firma BATTI. Nötr "Ret / kaldırma" etiketinin
// altında görünmez oluyor, üstelik 'tur' konkordato olduğu için İflas süzgecine
// basan kullanıcı bunları HİÇ görmüyordu.
// Ayrı damga: ret kalıbı VE iflas kelimesi birlikte geçiyorsa 'ret_iflas'.
// NOT: /i bayrağı Türkçe İ↔i eşlemez (bkz. bu dosyadaki diğer harf sınıfları),
// o yüzden ilk harf elle yazıldı: [iİIı].
// 28.08 AYNI GÜN DÜZELTİLDİ — ilk kural "ret kalıbı + iflas kelimesi"ydi ve
// KİRLİ çıktı. Canlı ölçüm (60 ilan): 53 doğru, ama 6 tanesi "İflasın
// kaldırılması kararının ilanen tebliği" (m.182 — borçlu iflastan ÇIKIYOR,
// anlamı TAM TERS) ve 1 tanesi "Terekenin iflas hükümlerine göre tasfiyesi
// kararının kaldırılması" (m.180 — konkordatoyla ilgisi yok).
// DERS: kelime eşleşmesi anlam taşımaz. "kaldırılması + iflas" iki zıt olayı
// birden eşliyor; ayıran şey KONKORDATO kelimesinin varlığı.
const KONK_RX  = /konkordato/i;
const RET_RX   = /reddine|reddi|kald[ıi]r[ıi]lmas|feshine|feshi\b|iptaline/i;
const IFLAS_RX = /[iİIı]flas/i;
function kararDurumu(baslik, metin) {
  const b = String(baslik || '');
  const m = String(metin || '').slice(0, 1500);
  let bulunan = null;
  if (KONK_RX.test(b) && RET_RX.test(b) && IFLAS_RX.test(b)) return 'ret_iflas';
  for (const [ad, rx] of DURUMLAR) if (rx.test(b)) { bulunan = ad; break; }
  // 20.08 ÖLÇÜM: "Konkordato mühlet kararının ilanen tebliği" 520 ilanda geçiyor
  // ve geçici mi kesin mi SÖYLEMİYOR. Başlık belirsiz kaldıysa metne bakılır —
  // karar metninde hangisi olduğu yazar. Belirsizi belirsiz bırakmak, filtreyi
  // en kalabalık kümede işe yaramaz hale getirirdi.
  // 20.08 ÖLÇÜLEN KUSUR: metin yedeği "ret"i 1.405 ilana basmıştı — çünkü
  // geçici mühlet ilanının STANDART cümlesi "…konkordato talebinin REDDİNİ
  // isteyebilecekleri" (İİK m.288). Yani mühlet verilmiş, ret sanılmış.
  // Ret / kaldırma / tasdik / iflas YALNIZ BAŞLIKTAN belirlenir: bunlar ilanın
  // türüdür, kurum başlığa yazar. Metin yedeği yalnız mühletin HANGİSİ olduğunu
  // (geçici mi kesin mi uzatma mı) çözmek için çalışır.
  if (!bulunan || bulunan === 'muhlet') {
    for (const ad of ['uzatma', 'kesin_muhlet', 'gecici_muhlet']) {
      const rx = DURUMLAR.find(d => d[0] === ad)[1];
      if (rx.test(m)) return ad;
    }
  }
  return bulunan || 'diger';
}

function komiserCikar(metin) {
  const m = /komiser(?:i|leri|liğine)?\s*(?:olarak|:)?\s*([^.;]{5,240}?)(?:'?[üu]n\s*atan|atanmas|atand|görevlendir|karar\s*veril)/i.exec(metin);
  if (!m) return '';
  let s = m[1].replace(/\s+/g, ' ').trim().replace(/[,;\s]+$/, '');
  if (s.length < 5 || s.length > 220) return '';
  if (/^(olarak|atan|görev)/i.test(s)) return '';
  return s;
}

// --- ana ayrıştırıcı --------------------------------------------------------
function ayristir(metin, baslik) {
  const r = { metin: metin, borclular: [], vknler: [], tcknler: [] };
  r.karar_durumu = kararDurumu(baslik, metin);

  let m = /ESAS\s*NO\s*:?\s*(\d{4}\s*\/\s*\d+)/i.exec(metin) || /Say[ıi]\s*:?\s*(\d{4}\s*\/\s*\d+)\s*Esas/i.exec(metin) || /(\d{4}\s*\/\s*\d+)\s*Esas/i.exec(metin);
  if (m) r.esas_no = m[1].replace(/\s+/g, '') + ' Esas';

  m = /(?:Ticaret\s*Sicil\s*(?:Müdürlüğü|Memurluğu)[^0-9]{0,40})(["'\s]*)([0-9][0-9\-]{2,14})\1?\s*(?:sicil\s*)?(?:no|nosunda|numaras[ıi]|numaras[ıi]nda|nolu)/i.exec(metin);
  if (m) r.sicil_no = m[2].trim();

  // BORÇLULAR: kimlik numarası çapa, unvan/ad çevresinden. Numara yoksa yazma.
  const gorulen = new Set();
  for (const mm of metin.matchAll(/\b\d{10}\b/g)) {
    const no = mm[0];
    if (!vknGecerli(no) || gorulen.has(no)) continue;
    // yalnız vergi bağlamındaki 10 hane (sicil/mersis/dosya numarası değil)
    const cevre = metin.slice(Math.max(0, mm.index - 60), mm.index + 60);
    if (!/vergi|V\.?D\.?|VD|mükellef/i.test(cevre)) continue;
    gorulen.add(no);
    r.vknler.push(no);
    const unvan = numaraCevresiUnvan(metin, mm.index, no.length);
    r.borclular.push(unvan ? { ad: unvan, vkn: no } : { vkn: no });
  }
  for (const mm of metin.matchAll(/\b\d{11}\b/g)) {
    const no = mm[0];
    if (!tcknGecerli(no) || gorulen.has(no)) continue;
    const cevre = metin.slice(Math.max(0, mm.index - 60), mm.index + 90);
    if (!/kimlik|T\.?C\.?|TC\b/i.test(cevre)) continue;
    gorulen.add(no);
    r.tcknler.push(no);
    const ad = kisiAdiCevresi(metin, mm.index, no.length);
    r.borclular.push(ad ? { ad, tckn: no } : { tckn: no });
  }
  // Etiketli unvanlar: numarasız borçluyu kurtarır, ayrıca numarayla bulunmuş
  // ama unvanı boş kalan kayda adı yapıştırır (ölçüm: sıra cetvelinde VKN
  // parantez içindeydi, unvan 100 karakter öteden "MÜFLİS :" satırındaydı).
  for (const ad of etiketliBorclular(metin)) {
    const ayni = r.borclular.find(b => b.ad && b.ad.toLocaleUpperCase('tr') === ad.toLocaleUpperCase('tr'));
    if (ayni) continue;
    const bos = r.borclular.find(b => !b.ad);
    if (bos) bos.ad = ad; else r.borclular.push({ ad });
  }

  Object.assign(r, muhletCikar(metin));
  const k = komiserCikar(metin); if (k) r.komiser = k;

  m = /(\d{1,2})\s*g[üu]nl[üu]k\s*kes[İIi]n\s*s[üu]re/i.exec(metin) || /(\d{1,2})\s*g[üu]n\s*i[çc]inde\s*(?:itiraz|şikayet)/i.exec(metin);
  if (m) r.itiraz_gun = +m[1];

  // MAHKEME — 20.08 kusur: gevşek desen cümle ortasından çöp yakalıyordu
  // ("ndan 12.12.2025 tarihinde konkordato talebinde… Mahkemesi"). Artık il
  // adıyla başlar, tarih/rakam dizisi içeremez, "T.C." ve "İ L A N" öneki atılır.
  m = /([A-ZÇĞİÖŞÜ][A-ZÇĞİÖŞÜa-zçğıöşü]+(?:\s+[A-ZÇĞİÖŞÜ0-9][A-ZÇĞİÖŞÜa-zçğıöşü\.]*){0,5}\s*(?:ASL[İI]YE\s*T[İI]CARET\s*MAHKEMES[İI]|Asliye\s*Ticaret\s*Mahkemesi|ASL[İI]YE\s*HUKUK\s*MAHKEMES[İI]|Asliye\s*Hukuk\s*Mahkemesi|[İI]FLAS\s*DA[İI]RES[İI]|İflas\s*Dairesi|T[İI]CARET\s*MAHKEMES[İI]))/.exec(metin);
  if (m) {
    let mh = m[1].replace(/\s+/g, ' ').trim()
      .replace(/^(?:İ\s*L\s*A\s*N\s*)?(?:T\s*\.?\s*C\s*\.?\s*)?/i, '').trim();
    if (!/\d{2}[.\/]\d{2}/.test(mh) && mh.length >= 10) r.mahkeme = mh;
  }

  return r;
}

// --- test kipi: ölçülmüş örneklerde doğruluk --------------------------------
async function test() {
  const dosya = path.join(process.env.SP || __dirname, 'ornek-ilanlar.json');
  let ornek;
  try { ornek = jsonOku(dosya); }
  catch (e) { console.log('örnek dosyası yok: ' + dosya); process.exit(1); }
  for (const o of ornek) {
    const r = ayristir(o.metin, o.baslik);
    console.log('\n===== [' + o.id + '] ' + o.baslik.slice(0, 55) + ' =====');
    console.log('  karar      :', r.karar_durumu || '—');
    console.log('  esas_no    :', r.esas_no || '—');
    console.log('  sicil_no   :', r.sicil_no || '—');
    console.log('  mahkeme    :', r.mahkeme || '—');
    console.log('  borçlular  :', r.borclular.length ? r.borclular.map(b => (b.ad || '?') + (b.vkn ? ' [' + b.vkn + ']' : b.tckn ? ' [TCKN]' : '')).join(' | ') : '—');
    console.log('  mühlet     :', (r.muhlet_tip || '—') + ' · ' + (r.muhlet_ay ? r.muhlet_ay + ' ay' : '—') + ' · ' + (r.muhlet_baslangic || '—') + ' → ' + (r.muhlet_bitis || '—'));
    console.log('  komiser    :', r.komiser || '—');
    console.log('  itiraz gün :', r.itiraz_gun || '—');
  }
}

// --- ana koşu: hedef json'daki ilanları zenginleştir ------------------------
async function kos() {
  const hedef = path.join(KOK, deger('hedef') || 'veri/alacak-ilan-canli.json');
  if (!fs.existsSync(hedef)) { console.log('hedef yok: ' + hedef); process.exit(0); }
  const obj = jsonOku(hedef);
  const ilanlar = obj.ilanlar || [];
  const zorla = bayrak('zorla');
  const tavan = parseInt(deger('adet') || '0', 10) || Infinity;
  let say = 0, yok = 0, sayac = { metin: 0, borclu: 0, vkn: 0, esas: 0, muhlet: 0, komiser: 0 };

  for (const x of ilanlar) {
    if (x.tur !== 'iflas' && x.tur !== 'konkordato') continue;
    if (say >= tavan) break;
    if (x.metin && !zorla) continue;
    // 20.08 OLCULDU: 25 ilanin metni kaynakta YOK — API 200 doner ama
    // result.id null gelir (ilan ilan.gov.tr'den kaldirilmis). Damgalanir,
    // yoksa her kosuda bosuna 25 istek gider. --zorla yine dener.
    if (x.metin_yok && !zorla) continue;
    const id = (String(x.url || '').match(/\/ilan\/(\d+)\//) || [])[1];
    if (!id) continue;
    let j = {};
    try { j = JSON.parse(await detayCek(id)); } catch (e) { continue; }
    const metin = metinTemizle(j && j.result && j.result.content);
    if (!metin || metin.length < 40) {
      if (j && j.result && j.result.id === null) { x.metin_yok = 'kaynakta-yok'; yok++; }
      continue;
    }
    say++;
    const r = ayristir(metin, x.baslik);
    x.metin = r.metin; sayac.metin++;
    if (r.karar_durumu) x.karar_durumu = r.karar_durumu;
    if (r.esas_no) { x.esas_no = r.esas_no; sayac.esas++; }
    if (r.sicil_no) x.sicil_no = r.sicil_no;
    if (r.mahkeme) x.mahkeme = r.mahkeme;
    if (r.borclular.length) {
      x.borclular = r.borclular;
      const adli = r.borclular.find(b => b.ad);
      if (adli && !x.borclu) { x.borclu = adli.ad; }
      if (r.borclular.some(b => b.ad)) sayac.borclu++;
    }
    if (r.vknler.length) { x.vknler = r.vknler; if (!x.vkn) x.vkn = r.vknler[0]; sayac.vkn++; }
    if (r.tcknler.length) { x.tcknler = r.tcknler; if (!x.tckn) x.tckn = r.tcknler[0]; }
    if (r.muhlet_tip) x.muhlet_tip = r.muhlet_tip;
    if (r.muhlet_ay) x.muhlet_ay = r.muhlet_ay;
    if (r.muhlet_baslangic) { x.muhlet_baslangic = r.muhlet_baslangic; sayac.muhlet++; }
    if (r.muhlet_bitis) x.muhlet_bitis = r.muhlet_bitis;
    if (r.komiser) { x.komiser = r.komiser; sayac.komiser++; }
    if (r.itiraz_gun) x.itiraz_gun = r.itiraz_gun;
    await new Promise(r2 => setTimeout(r2, 120));
  }
  // 20.08: karar_durumu BASLIKTAN da cikarilabilir — metni olmayan (kaynakta
  // silinmis) ilanlar da filtreye girsin diye tum kayitlar damgalanir.
  let dmg = 0;
  for (const x of ilanlar) {
    if (x.tur !== 'iflas' && x.tur !== 'konkordato') continue;
    if (x.karar_durumu) continue;
    x.karar_durumu = kararDurumu(x.baslik, x.metin); dmg++;
  }
  if (dmg) console.log('Yalniz basliktan damgalanan: ' + dmg);
  fs.writeFileSync(hedef, JSON.stringify(obj, null, 1), 'utf8');
  console.log('Kaynakta metni olmayan (damgalandi): ' + yok);
  console.log('Taranan: ' + say + ' · metin: ' + sayac.metin + ' · borçlu adı: ' + sayac.borclu + ' · VKN: ' + sayac.vkn + ' · esas no: ' + sayac.esas + ' · mühlet: ' + sayac.muhlet + ' · komiser: ' + sayac.komiser);

  // yaz -> geri oku -> karşılaştır (pazarlıksız kural)
  const geri = jsonOku(hedef).ilanlar || [];
  const say2 = (f) => geri.filter(f).length;
  console.log('-> geri okuma: metinli ' + say2(k => k.metin) + ' · borçlu adlı ' + say2(k => k.borclu) + ' · VKN\'li ' + say2(k => k.vkn) + ' · mühlet bitişli ' + say2(k => k.muhlet_bitis) + ' / toplam ' + geri.length);
}

// require ile yuklendiginde ANA KOSU calismasin (20.08: test sirasinda kazara
// 400 kayit islendi); yalniz dogrudan cagrildiginda kos.
if (require.main === module) { if (bayrak('test')) test(); else kos(); }
module.exports = { ayristir, vknGecerli, tcknGecerli };
