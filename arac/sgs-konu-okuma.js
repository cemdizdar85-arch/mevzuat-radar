#!/usr/bin/env node
/* ============================================================================
 *  SGS KONU OKUMA — çıkmış soruları OKUYARAK konu sayımı (04.10.2026, Cem: "sınav konuları önemli, doğru bilgi verelim,
 *  yanlış olmasın" → "1.2.3 üçünü de yap")
 *  NEDEN: etiket sayımı (veri/sgs-analiz.json konuSayim) aynı konuyu birden çok etikete bölüyor; dışarı verilen rakam düşük
 *  çıkıyordu (muhasebe bilgi sistemi 16→28 dönem). Kural CLAUDE.md: dışarı çıkan sınav rakamı soru metniyle doğrulanır.
 *  YÖNTEM: (1) --aday: ambardaki SGS çıkmış kitapçıklarından (tur=cikmis-soru, 2016/1+, yabancı dil varyantı hariç) her soruyu
 *          aşağıdaki aday konu ifadeleriyle tarar, eşleşen soruları okuma partilerine yazar (YEREL klasör; soru metni depoya GİRMEZ).
 *          (2) partiler tek tek okunur (ajan/insan): soru gerçekten o konuyu mu soruyor → E/H, sonuc-pN.json.
 *          (3) --topla: kararlar → veri/sinav/sgs-konu-okuma.json (yalnız dönem, soru no, konu, karar — METİN YOK).
 *  🚫 GÖRMEZ: aday ifadesi hiç geçmeyen soruyu (konu farklı sözcükle sorulduysa sayıya girmez → sayı ALT SINIRDIR) ·
 *     listede olmayan konuyu · matematik formülleri (kitapçıkta kalın matematik harfleri OCR'da bozuk: "lim" → "lll";
 *     Limit/Türev sayısı eksik → sayfa Matematik'i göstermez) · okuyucunun sınırda kararı (ajan notları commit mesajında).
 *  Kullanım: node arac/sgs-konu-okuma.js --aday <klasör>   |   node arac/sgs-konu-okuma.js --topla <klasör>
 * ==========================================================================*/
'use strict';
const fs = require('fs'), path = require('path');
const KOK = path.join(__dirname, '..');
const mod = process.argv[2], DIR = process.argv[3];
if (!['--aday', '--topla'].includes(mod) || !DIR) { console.error('kullanım: --aday <klasör> | --topla <klasör>'); process.exit(2); }
const lo = s => s.replace(/İ/g, 'i').replace(/I/g, 'ı').toLowerCase();
const T=[
['Türkçe','Anlatım bozukluğu',/anlatım bozuk/],
['Türkçe','Yazım kuralları',/yazım|yazılış|yanlış yazıl/],
['Türkçe','Noktalama işaretleri',/noktalama|virgül|noktalı|iki nokta/],
['Türkçe','Paragrafta ana düşünce / anlam',/ana düşünce|asıl anlatılmak|paragraf/],
['Matematik','Limit',/\blim\b|limit/],
['Matematik','Türev',/türev|f['′]\s*\(|f ['′] \(/],
['Matematik','İntegral',/integral|∫/],
['Matematik','Olasılık',/olasılık/],
['Matematik','Permütasyon / kombinasyon',/permütasyon|kombinasyon/],
['Matematik','Matris / determinant',/matris|determinant/],
['Matematik','Logaritma',/logaritma|\blog\b|\bln\b/],
['Atatürk İlkeleri','Lozan Antlaşması',/lozan/],
['Atatürk İlkeleri','Kongreler ve genelgeler',/kongre|genelge/],
['Atatürk İlkeleri','Misak-ı Millî',/misak/],
['Atatürk İlkeleri','Atatürk ilkeleri',/laiklik|halkçılık|devletçilik|inkılapçılık|inkılâpçılık|milliyetçilik|cumhuriyetçilik/],
['İktisat','Esneklik',/esneklik/],
['İktisat','Enflasyon',/enflasyon/],
['İktisat','Millî gelir / GSYH',/gayri safi|gayrisafi|gsyh|milli gelir|millî gelir/],
['İktisat','Tekel (monopol)',/tekel|monopol/],
['İktisat','Para politikası / Merkez Bankası',/para arzı|merkez bankası|para politika/],
['İktisat','Fayda ve kayıtsızlık eğrisi',/marjinal fayda|kayıtsızlık/],
['Maliye','Kamu malları',/kamu mal/],
['Maliye','Bütçe',/bütçe/],
['Maliye','Kamu borçları',/kamu borç|iç borç|dış borç/],
['Maliye','Verginin yansıması',/yansıma|yansıtma/],
['Vergi Hukuku','Vergi cezaları',/vergi ziyaı|usulsüzlük|kaçakçılık/],
['Vergi Hukuku','Uzlaşma',/uzlaşma/],
['Vergi Hukuku','Zamanaşımı',/zamanaşımı/],
['Vergi Hukuku','Tebliğ',/tebliğ/],
['Vergi Hukuku','Katma değer vergisi',/katma değer/],
['Vergi Hukuku','Kurumlar vergisi',/kurumlar vergisi/],
['Vergi Hukuku','Değerleme ölçüleri (VUK)',/değerleme ölçü|borsa rayici|emsal bedel|mukayyet değer|itibari değer/],
['Muhasebe','Amortisman',/amortisman/],
['Finansal Muhasebe','Muhasebe bilgi sistemi',/muhasebe bilgi sistem/],
['Finansal Muhasebe','Temel muhasebe kavramları',/temel kavram|dönemsellik|ihtiyatlılık|süreklilik kavram|tutarlılık kavram|tam açıklama|özün önceliği/],
['Finansal Muhasebe','Nakit akış tablosu',/nakit akış/],
['Finansal Muhasebe','Yatırım amaçlı gayrimenkul (TMS 40)',/yatırım amaçlı gayrimenkul/],
['Finansal Muhasebe','Hisse senedi alım-satımı',/hisse senedi/],
['Finansal Muhasebe','Stok değerleme yöntemleri',/fifo|ilk giren|ortalama maliyet|stok değerleme|lifo/],
['Finansal Muhasebe','Şüpheli alacaklar',/şüpheli/],
['Finansal Muhasebe','Reeskont',/reeskont/],
['Maliyet Muhasebesi','Ortak (birleşik) maliyet dağıtımı',/ortak maliyet|birleşik maliyet|ortak üretim|yan ürün|birlikte üretilen/],
['Maliyet Muhasebesi','Gider yeri / gider dağıtımı',/yardımcı gider|gider yeri|dağıtım anahtar|birinci dağıtım|ikinci dağıtım|hizmet gider yer/],
['Maliyet Muhasebesi','Safha maliyet / eşdeğer birim',/safha|eşdeğer/],
['Maliyet Muhasebesi','Standart maliyet ve farklar',/standart maliyet|fiyat farkı|miktar farkı|verimlilik farkı/],
['Maliyet Muhasebesi','Başabaş noktası',/başabaş|başa baş|katkı pay/],
['Mali Tablolar Analizi','Dikey yüzde analizi',/dikey/],
['Mali Tablolar Analizi','Yatay analiz',/yatay/],
['Mali Tablolar Analizi','Trend analizi',/trend/],
['Mali Tablolar Analizi','Oran analizi',/cari oran|likidite oran|asit|devir hızı|karlılık oran|kârlılık oran|nakit oran/],
['Denetim','Denetim kanıtı',/denetim kanıt/],
['Denetim','Analitik prosedürler',/analitik/],
['Denetim','Önemlilik',/önemlilik/],
['Denetim','İç kontrol',/iç kontrol/],
['Denetim','Denetim riski',/denetim riski|kontrol riski|keşif riski|doğal risk|tespit riski/],
['Denetim','Denetim görüşü türleri',/olumlu görüş|şartlı görüş|olumsuz görüş|görüş bildirmekten|sınırlı olumlu/],
['Denetim','Örnekleme',/örnekleme/],
['Ticaret Hukuku','Kıymetli evrak (çek, bono, poliçe)',/(^|[^a-zçğıöşü])çek([^a-zçğıöşü]|$)|bono|poliçe|ciro/],
['Ticaret Hukuku','Anonim şirket genel kurulu',/genel kurul/],
['Ticaret Hukuku','Limited şirket',/limited/],
['Ticaret Hukuku','Tacir ve ticari işletme',/tacir|ticari işletme/],
['Ticaret Hukuku','Ticaret unvanı',/ticaret unvan/],
['Borçlar Hukuku','Sebepsiz zenginleşme',/sebepsiz zenginleş/],
['Borçlar Hukuku','Genel işlem koşulları',/genel işlem koşul/],
['Borçlar Hukuku','Haksız fiil',/haksız fiil/],
['Borçlar Hukuku','Kefalet',/kefalet|kefil/],
['Borçlar Hukuku','Vekâlet sözleşmesi',/vekalet|vekâlet/],
['Borçlar Hukuku','Kira sözleşmesi',/kira sözleşme|kiracı|kiraya veren/],
['Borçlar Hukuku','Sözleşmenin kurulması (öneri-kabul)',/icap|öneri.{0,40}kabul|kabul.{0,40}öneri/],
['İş ve Sosyal Güvenlik Hukuku','Toplu iş sözleşmesi',/toplu iş sözleşme/],
['İş ve Sosyal Güvenlik Hukuku','Kıdem tazminatı',/kıdem tazminat/],
['İş ve Sosyal Güvenlik Hukuku','İhbar (bildirim) süreleri',/ihbar|bildirim süre/],
['İş ve Sosyal Güvenlik Hukuku','Fazla çalışma',/fazla çalışma|fazla sürelerle/],
['İş ve Sosyal Güvenlik Hukuku','Yıllık ücretli izin',/yıllık izin|yıllık ücretli izin/],
['İş ve Sosyal Güvenlik Hukuku','Grev ve lokavt',/grev|lokavt/],
['İş ve Sosyal Güvenlik Hukuku','İş kazası ve meslek hastalığı',/iş kaza|meslek hastalı/],
['İş ve Sosyal Güvenlik Hukuku','Deneme süresi',/deneme süre/],
['Meslek Hukuku','Meslek mensubu ücreti (asgari ücret tarifesi)',/ücret tarife|ücret.{0,80}(yönetmeli|tarife|meslek mensub)|meslek mensub.{0,80}ücret/],
['Meslek Hukuku','Disiplin cezaları',/disiplin/],
['Meslek Hukuku','Staj',/staj/],
['Meslek Hukuku','Meslek odaları ve TÜRMOB',/türmob|tesmer|meslek oda|odalar birliği|oda yönetim|odanın/],
['Meslek Hukuku','Meslekle bağdaşmayan işler ve yasaklar',/bağdaşmayan|yapamayacağı|reklam yasa|yasaklan/],
];

// Aday soruları kur (id sırası: ambar sorgusu baslik sırasıyla, deterministik)
function adaylar(docs) {
  const ana = docs.filter(d => !/yabanci dil/.test(d.baslik)).map(d => ({ don: d.baslik.match(/SGS (\d{4}\/\d)/)[1], m: d.metin }))
    .filter(d => +d.don.slice(0, 4) >= 2016);
  const kayit = []; let id = 0;
  for (const d of ana) for (const p of d.m.split(/(?=SORU \d+\s*:)/)) {
    const n = (p.match(/^SORU (\d+)/) || [])[1]; if (!n) continue;
    // kitapçık sayfa başlığı ("TÜRMOB - TESMER …", "STAJA GİRİŞ SINAVI") soru parçasına yapışıyor → sahte "staj/TÜRMOB" eşleşmesi (ölçüldü: 635 sahte)
    const temiz = p.normalize('NFKC').replace(/TÜRMOB\s*-\s*TESMER[^\n]*/g, ' ').slice(0, 1600);
    const t = lo(temiz).replace(/staja gir\S* sınav\S*/g, ' ');
    for (const [ders, konu, re] of T) if (re.test(t)) kayit.push({ id: ++id, ders, konu, donem: d.don, soru: +n, metin: temiz.trim() });
  }
  return { kayit, donemSay: ana.length };
}
(async () => {
  if (mod === '--aday') {
    const K = process.env.SUPABASE_SERVICE_KEY; if (!K) { console.error('SUPABASE_SERVICE_KEY yok'); process.exit(2); }
    const r = await fetch('https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar?tur=eq.cikmis-soru&select=baslik,metin&kaynak_ad=ilike.*SGS*&order=baslik.asc', { headers: { apikey: K, Authorization: 'Bearer ' + K } });
    const docs = await r.json(); const { kayit, donemSay } = adaylar(docs);
    fs.mkdirSync(DIR, { recursive: true });
    fs.writeFileSync(path.join(DIR, 'adaylar.json'), JSON.stringify(kayit.map(({ metin, ...x }) => x)));
    const byK = {}; kayit.forEach(x => (byK[x.konu] = byK[x.konu] || []).push(x));
    const partiler = []; let cur = [], n = 0;
    for (const k of Object.keys(byK)) { const L = byK[k]; if (n + L.length > 320 && cur.length) { partiler.push(cur); cur = []; n = 0; } cur.push(...L); n += L.length; }
    if (cur.length) partiler.push(cur);
    partiler.forEach((p, i) => fs.writeFileSync(path.join(DIR, 'p' + (i + 1) + '.txt'),
      p.map(x => '### id=' + x.id + ' | ADAY KONU: ' + x.ders + ' › ' + x.konu + ' | ' + x.donem + ' soru ' + x.soru + '\n' + x.metin.slice(0, 1100).replace(/\r/g, '') + '\n').join('\n')));
    console.log('dönem ' + donemSay + ' · aday konu ' + T.length + ' · aday soru ' + kayit.length + ' · parti ' + partiler.length + ' → ' + DIR);
    return;
  }
  const a = JSON.parse(fs.readFileSync(path.join(DIR, 'adaylar.json'), 'utf8'));
  const k = {}; fs.readdirSync(DIR).filter(f => /^sonuc-p\d+\.json$/.test(f)).forEach(f => Object.assign(k, JSON.parse(fs.readFileSync(path.join(DIR, f), 'utf8'))));
  const eksik = a.filter(x => !(String(x.id) in k));
  if (eksik.length) { console.error('KIRMIZI: kararı olmayan ' + eksik.length + ' aday soru'); process.exit(3); }
  const cikti = { olcum: new Date().toISOString().slice(0, 10), pencere: '2016/1-2026/2', donem: 32, aday_konu: T.length, aday_soru: a.length,
    yontem: 'aday ifadeyle eşleşen her çıkmış soru tek tek okundu; e=1 soru o konuyu ölçüyor, e=0 sözcük yalnız geçiyor',
    kaynak_notu: '27 dönem TESMER resmî kitapçığı; 2024/2, 2024/3, 2025/1, 2025/2, 2025/3 ikincil yayımlanmış kitapçık (aktifonline.net)',
    gormez: 'aday ifadesi geçmeyen soru sayılmaz (sayı alt sınır) · Matematik formül OCR kusuru',
    konular: T.map(([d, ko, re]) => ({ ders: d, konu: ko, ifade: String(re) })),
    kararlar: a.map(x => ({ ders: x.ders, konu: x.konu, donem: x.donem, soru: x.soru, e: k[x.id] === 'E' ? 1 : 0 })) };
  const yaz = JSON.stringify(cikti).replace(/\},\{/g, '},\n{');
  fs.writeFileSync(path.join(KOK, 'veri', 'sinav', 'sgs-konu-okuma.json'), yaz);
  console.log('veri/sinav/sgs-konu-okuma.json: ' + a.length + ' karar, E ' + cikti.kararlar.filter(x => x.e).length);
})().catch(e => { console.error('HATA ' + e.message); process.exitCode = 1; });
