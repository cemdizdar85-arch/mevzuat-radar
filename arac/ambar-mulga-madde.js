#!/usr/bin/env node
// ============================================================================
//  AMBAR MÜLGA MADDE LİSTESİ (29.09.2026, Cem "1.2.3 üçünü de yap")
//  Ambarda BÜTÜNÜYLE yürürlükten kalkmış (mülga) ya da yargı kararıyla İPTAL edilmiş
//  maddeleri bulur → veri/sinav/ambar-mulga-maddeler.json. Motor (KAPI-MM) bu satırları
//  kaynak paketine ALMAZ; ön denetim (hazir-soru-denetle) kaynak_adlar'da görürse KUSUR der.
//
//  ÖLÇÜLDÜ (29.09): 50.120 parçadan "Mülga"/"iptal" geçen 2.919 ad tarandı → 24 madde.
//   Bankada (14.340 soru) bunlardan yalnız VUK m.270 kaynak gösterilmiş: 17 soru.
//   m.270'in ambar satırı yalnız başlık + "(Mülga:14/10/2021-7338/29 md.)" — hüküm yok;
//   ad araması başlığı eşleştirip pakete sokuyordu.
//
//  ÖLÇÜT: madde başlığından hemen sonra (Değişik/Ek parantezleri atlanarak) "(Mülga…)"
//   ya da "(…iptal madde/edil…)" parantezi gelir VE ardından 40 harften kısa hüküm kalır.
//   "(Mülga ibare/fıkra/bent/cümle…)" maddenin KENDİSİ değildir → sayılmaz.
//   Arkadan gelen bölüm başlığı ("DÖRDÜNCÜ BÖLÜM …") ve sonraki madde başlığı hüküm sayılmaz
//   (ilk sürüm bu yüzden Ücret Yön. m.22'yi kaçırıyordu).
//  🚫 GÖRMEZ: iptali metinde yazmayan madde (ambar metni konsolide değilse); fıkra düzeyi iptal.
//
//  Kullanım: node arac/ambar-mulga-madde.js          (ambardan okur, listeyi yazar; SUPABASE_SERVICE_KEY)
//            node arac/ambar-mulga-madde.js --sinav  (öz-sınav, ağ yok)
// ============================================================================
const fs = require('fs'), path = require('path');
const KOK = path.resolve(__dirname, '..');
const CIKTI = path.join(KOK, 'veri', 'sinav', 'ambar-mulga-maddeler.json');

function butunuyleMulga(metin) {
  const m = String(metin || '').replace(/\s+/g, ' ').trim();
  const bas = m.search(/(?:Ek |Geçici |Mükerrer )?(Madde|MADDE)\s*\d+(?:\/[A-Z])?\s*[-–—]/);
  if (bas < 0) return null;
  let r = m.slice(bas).replace(/^(?:Ek |Geçici |Mükerrer )?(Madde|MADDE)\s*\d+(?:\/[A-Z])?\s*[-–—]\s*/, '');
  let iptal = null;
  for (let i = 0; i < 4; i++) {
    const p = r.match(/^\(([^()]*(?:\([^()]*\)[^()]*)*)\)\s*/); if (!p) break;
    const ic = p[1];
    if (/^(Mülga|İptal)\b/i.test(ic) && !/^(Mülga|İptal)\s+(ibare|fıkra|bent|cümle|bir|ikinci|üçüncü|dördüncü|beşinci|altıncı|yedinci|sekizinci|dokuzuncu|onuncu|son)/i.test(ic)) iptal = ic;
    else if (/iptal (madde|edil)/i.test(ic) && !/(ibare|fıkra|bent|cümle)/i.test(ic)) iptal = ic;
    r = r.slice(p[0].length);
  }
  if (!iptal) return null;
  const hukum = r.replace(/^[\s.;:]*/, '')
    .replace(/(?:Ek |Geçici |Mükerrer )?(Madde|MADDE)\s*\d.*$/, '')
    .replace(/(BİRİNCİ|İKİNCİ|ÜÇÜNCÜ|DÖRDÜNCÜ|BEŞİNCİ|ALTINCI|YEDİNCİ|SEKİZİNCİ|DOKUZUNCU|ONUNCU)\s+(BÖLÜM|KISIM|KİTAP).*$/u, '')
    .replace(/[^\p{L}\p{N}]+/gu, ' ').trim();
  return hukum.length < 40 ? { iptal: iptal.slice(0, 160), kalan: hukum.slice(0, 60) } : null;
}

function sinav() {
  const V = [
    ['bütünüyle mülga', 'Madde 270 – (Mülga:14/10/2021-7338/29 md.)', true],
    ['yargı iptali + arkasında bölüm başlığı', "Madde 22- (Danıştay Sekizinci Dairesinin 2/4/2004 tarihli ve E.:2003/367; K.:2004/1539 sayılı kararı ile iptal madde; Danıştay İDDK'nın onama kararı ile mezkûr karar kesinleşmiştir.) DÖRDÜNCÜ BÖLÜM Çeşitli Hükümler İş Sahiplerine Tebligat", true],
    ['Değişik parantezinden sonra mülga', 'İhalenin feshi: Madde 133 – (Değişik: 6/6/1985-3222/16 md.) (Mülga:24/11/2021-7343/32 md.)', true],
    ['yalnız ibaresi mülga → yürürlükte', 'Madde 24 – (Mülga bir ila dördüncü cümleler: 2/7/2018-KHK-703/167 md.) Başkanlık ve üyelikler, yenilenme hariç olmak üzere boşalma halinde Kurul tarafından seçim yapılır ve görev süresi dolan üyenin yerine gelen üye göreve başlar.', false],
    ['mülga + yeniden düzenlenmiş → yürürlükte', 'Madde 370 – (Mülga: 30/12/1980-2365/89 md.; Yeniden düzenleme: 15/7/2016-6728/22 md.) Vergi incelemesi ve takdir işlemleri başlamadan önce mükellefler tarafından verilen izahat talebi üzerine ilgili mükellef lehine hüküm kurulur.', false],
    ['kısa madde, yalnız ibaresi mülga → yürürlükte', 'Madde 5 – (Mülga ibare: 1/1/2020-7000/1 md.) Ceza tebliğ edilir.', false],
    ['iptal geçmeyen olağan madde', 'Madde 14- Ücret sözleşmeleri münferit ya da süreli olarak yapılabilir. Süreli sözleşmelerin en az bir yıllık olması şarttır.', false],
  ];
  let ok = 0;
  for (const [ad, metin, bek] of V) { const s = !!butunuyleMulga(metin); const g = s === bek; if (g) ok++; console.log((g ? '  ✓ ' : '  ✗ ') + ad + ' → ' + (s ? 'MÜLGA' : 'yürürlükte')); }
  console.log(`MÜLGA MADDE ÖZ-SINAVI ${ok === V.length ? 'YEŞİL' : 'KIRMIZI'} (${ok}/${V.length})`);
  process.exit(ok === V.length ? 0 : 1);
}

async function olc() {
  const K = process.env.SUPABASE_SERVICE_KEY; if (!K) { console.error('SUPABASE_SERVICE_KEY yok'); process.exit(2); }
  const B = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar';
  const H = { apikey: K, Authorization: 'Bearer ' + K, 'User-Agent': 'mevzuat-radar-robot/1.0' };
  const cek = async q => { const out = []; for (let o = 0; ; o += 1000) { const r = await fetch(B + '?select=kaynak_ad,metin&order=id.asc&metin=ilike.' + encodeURIComponent(q) + '&limit=1000&offset=' + o, { headers: H }); if (!r.ok) throw new Error('ambar ' + r.status); const j = await r.json(); out.push(...j); if (j.length < 1000) break; } return out; };
  const rows = [...await cek('*Mülga*'), ...await cek('*iptal*')];
  const seen = new Set(), liste = [];
  for (const d of rows) { if (seen.has(d.kaynak_ad)) continue; seen.add(d.kaynak_ad); const k = butunuyleMulga(d.metin); if (k) liste.push({ kaynak_ad: d.kaynak_ad, ...k }); }
  liste.sort((a, b) => a.kaynak_ad.localeCompare(b.kaynak_ad, 'tr'));
  if (!liste.length) { console.error('0 madde bulundu - ambar okunamamış olabilir, liste YAZILMADI'); process.exit(3); }
  fs.writeFileSync(CIKTI, JSON.stringify({ aciklama: 'Ambarda BÜTÜNÜYLE mülga/iptal madde parçaları (arac/ambar-mulga-madde.js). Motor KAPI-MM bunları kaynak paketine almaz; ön denetim kaynak_adlar\'da görürse KUSUR der.', olcum: new Date().toISOString().slice(0, 10), taranan_ad: seen.size, sayi: liste.length, maddeler: liste }, null, 1) + '\n');
  console.log(`MÜLGA MADDE: taranan ${seen.size} ad → bütünüyle mülga/iptal ${liste.length} → ${path.relative(KOK, CIKTI)}`);
}

module.exports = { butunuyleMulga };
if (require.main === module) { if (process.argv.includes('--sinav')) sinav(); else olc().catch(e => { console.error(e.message); process.exit(1); }); }
