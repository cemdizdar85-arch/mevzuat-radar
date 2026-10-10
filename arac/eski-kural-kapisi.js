// arac/eski-kural-kapisi.js — KAPI-EK: BİLİNEN ESKİ / YANLIŞ KURAL SORU METNİNDE Mİ (30.09.2026, Cem "1.2.3 yap ve kural koy")
//
// Olay (ölçüldü 30.09): SGS risk taramasında yanlış cevapların ve güncellik kusurlarının kökü hakemde değil KAYNAKTA idi:
// hakem cevabı önündeki kaynak paketiyle kıyaslıyor, paket eskiyse o da eskiye "doğru" diyor (özel maliyet THP 264 1992 metni,
// VUK m.270 mülga maddesi, eski %18 KDV). Bu kapı, RESMÎ KAYNAKTAN doğrulanmış eski/yanlış kuralları bir listede tutar
// (arac/eski-kurallar.json) ve sorunun ÖĞRENCİYE GÖRÜNEN metninde (kök, şıklar, açıklama, sade, teşhis, adımlar, ikiz, hap)
// arar. Liste her yeni bulguyla büyür; listeye yalnız kaynağı yazılı kural girer ("dayanak" alanı zorunlu).
// 🚫 GÖRMEZ: listede olmayan eski kural · kaynak paketinin kendisi (KAPI-MM ayrı) · sayıyı değil ifadeyi yazan eski kural ·
//   kelimesi farklı yazılmış aynı kural. "Güncel" DEMEZ; yalnız listedekilerin YOKLUĞUNU söyler.
// Model alanları (hakem, hakem2, kor_cozum, simulasyon_sonnet, kaynak_metin_ozet) taranmaz: öğrenci görmez.
//
// Kullanım: --sinav [--mutasyon] | --dosya <parti.json...> | --banka <önek> [--yaz <çıktı>]
//   Modül: require('./eski-kural-kapisi.js').denetle(kayit) → [{kod, kural, alan, parca}]
'use strict';
const fs = require('fs'), path = require('path');
const MUT = process.env.EK_MUTASYON || '';
const LISTE = JSON.parse(fs.readFileSync(path.join(__dirname, 'eski-kurallar.json'), 'utf8')).kurallar
  .map(k => Object.assign({}, k, { re: new RegExp(k.desen, 'i'), haric: k.haric ? new RegExp(k.haric, 'i') : null }));
// 30.09: atif_genisletme (üretimde hakeme çekilen ambar belgelerinin iz kaydı, öğrenci görmez), mukerrer ve aciklama_hakem de model alanı —
//   kardeş kapılarla (hesap-kodu, bds-atif) aynı liste. Kapanış onarımında 3 yanlış alarm bu alandan geliyordu.
const MODEL_ALAN = new Set(['hakem', 'hakem2', 'kor_cozum', 'simulasyon_sonnet', 'kaynak_metin_ozet', 'kaynak_adlar', 'notlandirici', 'capa_metin', 'capa_kaynak', 'atif_genisletme', 'mukerrer', 'aciklama_hakem']);

/* öğrenciye görünen metin parçaları: [yol, metin] */
function parcalar(k) {
  const c = [];
  (function gez(o, yol) {
    if (o == null) return;
    if (typeof o === 'string') { c.push([yol, o]); return; }
    if (typeof o !== 'object') return;
    for (const a of Object.keys(o)) {
      if (!yol && MODEL_ALAN.has(a) && MUT !== 'model-dahil') continue;
      gez(o[a], yol ? yol + '.' + a : a);
    }
  })(k, '');
  return c;
}
function denetle(k) {
  const b = [];
  if (!k || typeof k !== 'object') return b;
  for (const [yol, t] of parcalar(k)) {
    for (const r of LISTE) {
      const m = t.match(r.re);
      if (!m) continue;
      /* 07.10 (EK20–22): kural "sikHaric" taşıyorsa YANLIŞ şıkkın kendi metni sayılmaz — çeldirici o yanılgıyı bilerek taşır
         (ölçüldü: smmm-4k-a-fmuh-kolay-r2-2/kp-25 siklar.E "KDV'nin tamamı 291 hesabında bekletilir"; rehakem sonrası YENİ soru
         olunca kapı bu meşru şık yüzünden soruyu durdururdu). Doğru şıkta ve öteki alanlarda aynen yakalar. */
      const sm = /^siklar\.([A-E])$/.exec(yol);
      if (r.sikHaric && sm && sm[1] !== String(k.dogru || '') && MUT !== 'sik-haric-yok') continue;
      /* istisna aynı cümlede aranır (ör. "2023 öncesi %18") */
      const cumle = t.slice(Math.max(0, m.index - 120), m.index + m[0].length + 120);
      if (r.haric && r.haric.test(cumle) && MUT !== 'haric-yok') continue;
      b.push({ kod: r.kod, kural: r.ad, alan: yol, parca: cumle.replace(/\s+/g, ' ').slice(0, 160) });
    }
  }
  return b;
}

function sinav() {
  const T = (ek) => Object.assign({ soru: 'İşletme 100.000 TL + KDV mal satmıştır (KDV oranı %20).', siklar: { A: '20.000', B: '18.000' }, dogru: 'A',
    aciklama: { A: 'KDV %20 uygulanır.', B: 'Eski oranla hesapladın.' }, sade: { dogru: 'KDV genel oranı %20.' } }, ek || {});
  const vakalar = [
    ['temiz soru → bulgu yok', T(), 0],
    ['açıklamada KDV %18 genel oran → EK1', T({ aciklama: { A: 'KDV oranı %18 uygulanır.' } }), 1],
    ['"yüzde 18 KDV" yazımı da yakalanır', T({ sade: { dogru: 'Satışa yüzde 18 KDV eklenir.' } }), 1],
    ['tarihli anlatım istisnası: "2023 Temmuz öncesi KDV %18 idi"', T({ aciklama: { A: '2023 Temmuz ayından önce KDV genel oranı %18 idi, bugün %20.' } }), 0],
    ['teşhis "eski %18 oranını kullandın" meşru', T({ teshis: { B: { yanilgi: 'KDV oranını sorudan almak yerine ezberindeki eski yüzde 18 oranını kullandın.' } } }), 0],
    ['%18 ama KDV değil (kâr marjı) → alarm yok', T({ aciklama: { A: 'Brüt kâr marjı %18 olarak bulunur.' } }), 0],
    ['GÜG farkı 630 hesabına → EK2', T({ adimlar: [{ anlatim: 'Fark 630 genel üretim gideri farkı hesabına yazılır.' }] }), 1],
    ['630 Ar-Ge Giderleri doğru anılırsa alarm yok', T({ adimlar: [{ anlatim: 'Aktifleştirilmeyen Ar-Ge 630 Araştırma ve Geliştirme Giderleri hesabına yazılır.' }] }), 0],
    ['VUK m.270 atfı → EK3', T({ aciklama: { A: 'VUK m.270 uyarınca noter harcı maliyete eklenebilir.' } }), 1],
    ['"270 inci madde" yazımı da yakalanır', T({ sade: { dogru: 'Vergi Usul Kanunu 270 inci maddesine göre.' } }), 1],
    ['"VUK\'ta yıl 360 gün" iddiası → EK4', T({ aciklama: { A: 'VUK\'ta yıl 360 gün kabul edilir.' } }), 1],
    ['"360 gün kabul edilecektir" varsayımı alarm vermez', T({ soru: 'Faiz hesabında yıl 360 gün kabul edilecektir.' }), 0],
    ['EK5 kâr payı stopajı %10 → alarm', T({ aciklama: { A: 'Kâr payı dağıtımında %10 stopaj yapılır.' } }), 1],
    ['EK5 "kesinti oranı %10" → alarm (w10-2-yvergi-kolay/kp-01, sitedeydi 06.10)', T({ soru: 'Kâr payı üzerinden vergi sorumlusu sıfatıyla yapılacak kesinti oranı %10\'dur.' }), 1],
    ['EK5 meşru: kâr payı yok, "%10 kesinti" (indirim)', T({ aciklama: { A: 'Satış bedelinden %10 kesinti yapılarak ödeme alınmıştır.' } }), 0],
    ['EK5 meşru: "2024 öncesi %10 idi"', T({ aciklama: { A: '2024 yılı sonuna kadar kâr payı stopajı %10 idi.' } }), 0],
    ['EK5 "kârın … dağıtmaya … kesinti oranı %10" → alarm (w14-8-fmuh-kolay/kp-01 kökü, sitedeydi 06.10)', T({ soru: 'Kalan kârın 310.000 ₺\'sini gerçek kişi ortağa, 175.000 ₺\'sini ise tam mükellef kurumlar vergisi mükellefi ortağa dağıtmaya karar vermiştir. Gelir Vergisi Kanunu m.94 uyarınca kesinti oranı %10\'dur.' }), 1],
    ['EK5 kâr payı ile kesinti arası 80+ karakter → alarm (w4-yvergi-zor/kp-04 kökü 06.10)', T({ soru: 'Kâr payı üzerinden Gelir Vergisi Kanunu m.94 uyarınca şirketçe sorumlu sıfatıyla yapılacak vergi kesintisi oranı %10\'dur.' }), 1],
    ['EK5 meşru: kâr dağıtımında %10 ikinci tertip yedek akçe (kesinti yok)', T({ soru: 'Kârın ortaklara dağıtılmasına karar verilmiştir; dağıtılacak tutarın %10\'u ikinci tertip yedek akçe olarak ayrılır.' }), 0],
    ['EK5 meşru: "%10,5" ondalık oran', T({ soru: 'Kâr payı üzerinden yapılan stopaj %10,5 olarak varsayılmıştır.' }), 0],
    ['EK6 eski dilimler 18.000/40.000/98.000 → alarm', T({ aciklama: { A: 'Gelir vergisi tarifesi: 18.000 TL\'ye kadar %15, 40.000 TL\'nin 18.000\'i için, 98.000 TL\'nin 40.000\'i için.' } }), 1],
    ['EK6 meşru: tek başına 18.000 tutarı', T({ aciklama: { A: 'Alış bedeli 18.000 TL, iskonto 40 TL.' } }), 0],
    ['EK7 KV oranı %20 → alarm', T({ aciklama: { A: 'Kurumlar vergisi oranı %20 uygulanır.' } }), 1],
    ['EK7 meşru: ihracat indirimli oran', T({ aciklama: { A: 'İhracat kazancına kurumlar vergisi oranı %20 (5 puan indirimli) uygulanır.' } }), 0],
    ['EK7 meşru: "%20 olarak yanlış okunup"', T({ sade: { siklar: { C: 'Kurumlar vergisi oranı %20 olarak yanlış okunup hesaplanması; %25 kullanılmalı.' } } }), 0],
    ['EK6 meşru: "dilimler şöyle varsayılmıştır"', T({ soru: 'Tarifenin dilimleri şöyle varsayılmıştır: 0-18.000 TL %15, 18.000-40.000 TL %20, 40.000-98.000 TL %27.' }), 0],
    ['EK8 teminatsız tecil 1.000.000 → alarm', T({ aciklama: { A: 'Tecil talebinde 1.000.000 TL\'ye kadar teminat aranmaz.' } }), 1],
    ['EK8 meşru: 10.000.000', T({ aciklama: { A: 'Tecil talebinde 10.000.000 TL\'ye kadar teminat aranmaz.' } }), 0],
    ['EK9 TMS 1 atfı → alarm', T({ aciklama: { A: 'TMS 1 p.82 uyarınca kâr veya zarar tablosunda gösterilir.' } }), 1],
    ['EK9 meşru: TMS 10–19 (TMS 12) alarm yok', T({ aciklama: { A: 'TMS 12 uyarınca ertelenmiş vergi hesaplanır.' } }), 0],
    ['EK9 meşru: "TFRS 18 TMS 1\'in yerini aldı"', T({ aciklama: { A: 'TFRS 18, TMS 1\'in yerini aldı.' } }), 0],
    ['EK10 TMS 8 eski adı → alarm', T({ dayanak: 'TMS 8 Muhasebe Politikaları, Muhasebe Tahminlerinde Değişiklikler ve Hatalar' }), 1],
    ['EK11 faiz ödemesi işletme faaliyetinde seçimlik → alarm', T({ aciklama: { A: 'Ödenen faiz işletme faaliyetlerinde de sınıflandırılabilir; bu bir politika seçimidir.' } }), 1],
    ['EK11 meşru: ana faaliyeti finansman olan işletme (p.34B)', T({ aciklama: { A: 'Ana faaliyeti müşteriye finansman olan işletmede ödenen faiz işletme faaliyetinde sınıflandırılabilir (p.34B).' } }), 0],
    ['EK11 "seçtiği politika gereği finansman" → alarm (SMMM w14-11 vakası)', T({ hap: 'Ödenen temettü işletmenin seçtiği politika gereği genellikle finansman faaliyeti sayılır.' }), 1],
    ['EK11 "temettü sınıflandırma politikası" → alarm', T({ konu_giris: { terimler: [{ ad: 'Temettü sınıflandırma politikası' }] } }), 1],
    ['EK11 meşru: kâr dağıtım politikası (TTK/SPK kavramı)', T({ aciklama: { A: 'Şirket temettü ödemesini kâr dağıtım politikası çerçevesinde belirler.' } }), 0],
    ['EK12 649\'a menkul kıymet satış kârı → alarm', T({ adimlar: [{ anlatim: 'Tahvil satışından doğan kâr 649 Diğer Olağan Gelir ve Kârlar hesabına, menkul kıymet satış kârı olarak yazılır.' }] }), 1],
    ['EK12 meşru: 649 diğer olağan gelir (kira geliri)', T({ adimlar: [{ anlatim: 'Arızi kira geliri 649 Diğer Olağan Gelir ve Kârlar hesabına alacak yazılır.' }] }), 0],
    ['EK12 meşru: "645\'e yazılır, 649\'a değil"', T({ aciklama: { B: 'Menkul kıymet satış kârı 645\'e yazılır, 649\'a değil.' } }), 0],
    ['EK13 659\'a kambiyo zararı → alarm', T({ aciklama: { A: 'Kur farkından doğan kambiyo zararı 659 hesabına borç yazılır.' } }), 1],
    ['EK13 meşru: 656 Kambiyo Zararları', T({ aciklama: { A: 'Kambiyo zararı 656 Kambiyo Zararları hesabına borç yazılır.' } }), 0],
    ['EK14 zayi ATİK KDV\'si bu dönem indirilir → alarm (0610d vakası)', T({ aciklama: { B: 'Faydalı ömrünü tamamlayıp zayi olan forkliftin 4.750 TL KDV\'si bu dönem indirilecek KDV\'ye eklenir.' } }), 1],
    ['EK14 gerçek ifade (0610d öncesi hap) → alarm', T({ hap: 'KDVK m.30\'a göre zayi olan emtiaya ait KDV indirilemez; ancak faydalı ömrünü tamamlamış amortismana tabi kıymetin zayi olmasında yüklenilen KDV istisna olarak indirilebilir.' }), 1],
    ['EK14 meşru: kanunun kendi parantez hükmü', T({ dayanak: 'KDVK m.30/c: faydalı ömrünü tamamlayan amortismana tabi iktisadi kıymetlerin zayi olması halinde, bu kıymetlerin alımında yüklenilen vergiler indirilebilir.' }), 0],
    ['EK15 yarışma ikramiyesinden %10 kesinti → alarm (gm5-12-fmuh-zor/kp-04 konu girişi, sitedeydi 06.10)', T({ aciklama: { A: 'Ali\'nin arkadaşı 20.000 ₺ kazandığı yarışma ikramiyesinden %10 kesinti yapılınca eline 18.000 ₺ geçmişti.' } }), 1],
    ['EK15 meşru: doğru oran %20', T({ aciklama: { A: 'Yarışmada kazanılan 20.000 ₺ ikramiyeden istisnayı aşan kısım üzerinden %20 veraset ve intikal vergisi kesilir.' } }), 0],
    ['EK15 meşru: personel ikramiyesi %10 artış (yarışma yok)', T({ aciklama: { A: 'Personele ödenen ikramiye bu yıl %10 artırılmıştır.' } }), 0],
    ['EK16 izaha davette "dörtte biri" → alarm (olc2-a-vergi/kp-18 konu girişi 06.10)', T({ aciklama: { A: 'İzaha davete uyup yeterli izah veren mükellefin vergi ziyaı cezası dörtte bir oranında kesilir.' } }), 1],
    ['EK16 meşru: izaha davette %20 (beşte bir)', T({ aciklama: { A: 'İzaha davette vergi ziyaı cezası %20 oranında, yani beşte bir kesilir.' } }), 0],
    ['EK17 m.376 "üçte bir" indirim → alarm (w3-yvergi-cokzor/kp-18 konu girişi 06.10)', T({ aciklama: { A: 'Otuz gün içinde başvuru ve vadesinde ödeme halinde cezanın üçte biri indirilir (VUK m.376).' } }), 1],
    ['EK17 meşru: mülga bent anlatımı', T({ aciklama: { A: 'VUK m.376\'daki müteakip cezalarda üçte bir indirim bendi 7524 sayılı Kanunla mülga edilmiştir.' } }), 0],
    ['EK18 kira kesintisi %10 → alarm (gm5-2-fmuh-zor/kp-05 konu girişi 06.10)', T({ aciklama: { A: 'Esnaf depo kirasını ödüyor ve kiraya kesinti uyguluyor; kesinti %10 ise brüt 100 ₺ olur.' } }), 1],
    ['EK18 meşru: çeldiricide "%10 uyguladı" yanılgısı', T({ aciklama: { B: 'Serbest meslek stopaj oranını %10 uyguladın; doğrusu %20.' } }), 0],
    ['EK18 meşru: kira artışı %10', T({ aciklama: { A: 'Kira bedeli bu yıl %10 artırılmış, stopaj ayrıca hesaplanır.' } }), 0],
    ['EK19 "GMSİ\'deki %10" → alarm (w3-yvergi-zor/kp-06 celdirici_yol 07.10)', T({ aciklama: { B: '94500*0.10 = 9450 (tevkifat oranını GMSİ\'deki %10 ile karıştırdın)' } }), 1],
    ['EK19 meşru: GMSİ stopajı %20', T({ aciklama: { A: 'Gayrimenkul sermaye iradı niteliğindeki kira ödemelerinde stopaj %20\'dir.' } }), 0],
    ['EK19 meşru: GMSİ kira artışı %10', T({ aciklama: { A: 'Gayrimenkul sermaye iradı olarak alınan kira bu yıl %10 artırılmıştır.' } }), 0],
    ['EK21 makine KDV\'si 291\'de bekletilip gelecek yıl indirilir → alarm (07.10, 29 soru)', T({ aciklama: { A: 'Makinenin KDV\'si 291 hesabında bekletilir ve gelecek yıl indirilir.' } }), 1],
    ['EK21 meşru: YANLIŞ şıkkın kendi metni (sikHaric; fmuh-kolay-r2-2/kp-25 E)', T({ siklar: { A: '20.000', B: '18.000', E: 'Kayıt yapılmaz; KDV\'nin tamamı 291 hesabında bekletilir' } }), 0],
    ['EK21 doğru şıkta aynı yanılgı → alarm (sikHaric yalnız yanlış şık)', T({ dogru: 'E', siklar: { A: '20.000', B: '18.000', E: 'Kayıt yapılmaz; KDV\'nin tamamı 291 hesabında bekletilir' } }), 1],
    ['EK21 meşru: alım ayında indirilir', T({ aciklama: { A: 'Makinenin KDV\'si alım ayında indirilir; 291\'de bekletilmez sanılır yanılgısı Tuzağı.' } }), 0],
    ['EK20 "bankalar m.35 listesinde yer almaz" → alarm (07.10, 11 soru)', T({ aciklama: { A: 'Bankalar sermaye piyasası kurumları arasında yer almaz.' } }), 1],
    ['EK20 meşru: bankalar yatırım kuruluşu olarak sayılır', T({ aciklama: { A: 'Bankalar yatırım kuruluşu olarak sermaye piyasası kurumudur (m.3/1-v, m.35/1-a).' } }), 0],
    ['EK22 "m.35 listesinde kitle fonlama platformları" → alarm (07.10, 14 soru)', T({ aciklama: { A: 'Kanunun 35. maddesinde sayılan kurumlar arasında kitle fonlama platformları da vardır.' } }), 1],
    ['EK22 meşru: m.35/A başlığı', T({ aciklama: { A: 'Kitle fonlama platformları m.35/A başlığı altında ayrıca düzenlenir.' } }), 0],
    // 10.10 EK23 (GVK m.22/4, 7491 s.K.): yurt dışı A.Ş./Ltd. kâr payında yarı istisna %50 sermaye + transfer şartıyla VAR
    ['EK23 "yalnız tam mükellef kurumdan … yabancı tam tutarıyla" → alarm (4k-a-yvergi-zor-r8/kp-01 hap 10.10)', T({ hap: 'GVK m.22\'deki kâr payı istisnası yalnız tam mükellef kurumdan gelen kâr payının yarısına uygulanır; yabancı kurumdan gelen kâr payı tam tutarıyla matraha girer.' }), 1],
    ['EK23 "yabancı kurum kâr payına istisna uygulanmaz" → alarm', T({ aciklama: { A: 'Yabancı şirketten elde edilen kâr payına istisna uygulanmaz, tamamı beyan edilir.' } }), 1],
    ['EK23 "istisna … yalnız tam mükellef kurumlara" → alarm', T({ sade: { dogru: 'Kâr payı istisnası yalnız tam mükellef kurumlardan alınanlar için geçerlidir.' } }), 1],
    ['EK23 meşru: m.22/4 şartı anılıyor (%50 sermaye)', T({ aciklama: { A: 'Yurt dışı A.Ş.\'deki payı %5 olduğundan GVK m.22/4\'ün %50 sermaye şartı sağlanmaz; yabancı kurum kâr payı tam tutarıyla matraha girer.' } }), 0],
    ['EK23 meşru: m.22/3 tek başına ("yalnız" yok)', T({ aciklama: { A: 'GVK m.22/3\'e göre tam mükellef kurumdan elde edilen kâr payının yarısı istisnadır.' } }), 0],
    ['EK23 meşru: KVK bağlamı (gm5-16-yvergi-zor/kp-03, kurum ortak; m.5/1-a ve %10)', T({ teshis: { B: { gercek: 'KVK m.5/1-a yalnız tam mükellef kurumlardan alınan kâr paylarını kapsar, KVK m.5/1-b en az %10 pay ister.' } } }), 0],
    ['EK23 meşru: 640 muhasebe tuzağı (gm5-30-fmuh-zor/kp-02)', T({ aciklama: { A: 'Vergi İstisnası Tuzağı: Yalnız tam mükellef kurumdan gelen kâr payını 640\'a yazdın.' } }), 0],
    ['EK23 meşru: YANLIŞ şıkkın kendi metni (sikHaric)', T({ siklar: { A: '20.000', B: 'Yabancı kurumdan alınan kâr payına istisna uygulanmaz' } }), 0],
    // 10.10 EK24–EK43 (kanun değişikliği taraması 2021–2026; veri/sinav/KANUN-DEGISIKLIGI-TARAMA-20261010.md) — her kurala 1 yakalama + 1 meşru
    ['EK24 "kıst yalnız binekte, makinede tam yıl" → alarm', T({ aciklama: { A: 'VUK\'ta kıst amortisman yalnız binek otomobilde uygulanır, makinede tam yıl ayrılır.' } }), 1],
    ['EK24 meşru: "kıst zorunluluğu yalnız binekte; gün esası seçimlik"', T({ aciklama: { A: 'Kıst zorunluluğu yalnız binek otomobildedir; öteki kıymetlerde gün esası seçimliktir (m.320/3).' } }), 0],
    ['EK25 "m.261\'de sekiz değerleme ölçüsü" → alarm', T({ sade: { dogru: 'VUK 261\'de sekiz değerleme ölçüsü sayılmıştır.' } }), 1],
    ['EK25 meşru: dokuz ölçü', T({ sade: { dogru: 'VUK 261\'de dokuz değerleme ölçüsü sayılır; dokuzuncusu 7338 ile eklendi.' } }), 0],
    ['EK26 "süre sonunda fonda kalan bakiye kâra" → alarm', T({ aciklama: { A: 'Yeni makine alındı; üçüncü takvim yılı sonunda fonda kalan bakiye kâra eklenir.' } }), 1],
    ['EK26 meşru: amortisman ayrılabilecek tutarı aşan fazlalık', T({ aciklama: { A: 'Fon yeni kıymetin amortisman ayrılabilecek tutarından fazla ise fazlalık üçüncü takvim yılında kâra eklenir.' } }), 0],
    ['EK27 "envantere alındığı dönem sonuna kadarki faiz tercihe bağlı" → alarm', T({ aciklama: { A: 'Envantere alındığı dönem sonuna kadarki faizi maliyete eklemek mükellefin tercihindedir.' } }), 1],
    ['EK27 meşru: o kısım zorunlu, sonrası seçimlik', T({ aciklama: { A: 'Envantere alındığı dönem sonuna kadarki faiz zorunlu olarak maliyete eklenir; sonraki kısmı tercihe bağlıdır.' } }), 0],
    ['EK28 "2026 yılı sonu enflasyon düzeltmesinde" → alarm', T({ soru: 'İşletme 2026 yılı sonu enflasyon düzeltmesinde stoklarını düzeltmektedir.' }), 1],
    ['EK28 meşru: geçici 37 ile yapılmaz', T({ aciklama: { A: '2026 hesap döneminde VUK enflasyon düzeltmesi yapılmaz (geçici madde 37).' } }), 0],
    ['EK29 "uzlaşmada vergi aslı ve ceza" → alarm', T({ aciklama: { A: 'Mükellef uzlaşmada vergi aslı ve cezada indirim sağladı.' } }), 1],
    ['EK29 meşru: vergi aslı uzlaşmaya konu edilemez', T({ aciklama: { A: 'Vergi aslı uzlaşmaya konu edilemez, uzlaşma yalnız ceza miktarı içindir.' } }), 0],
    ['EK30 asgari geçim indirimi güncel gibi → alarm', T({ siklar: { A: 'Ücretlilere tanınan asgari geçim indirimi şahsi verginin örneğidir.', B: '18.000' } }), 1],
    ['EK30 meşru: 7349 ile kaldırıldı', T({ aciklama: { A: 'Asgari geçim indirimi 7349 sayılı Kanunla 2022 başından itibaren kaldırılmıştır.' } }), 0],
    ['EK31 "2026 tarifesi … 330.000" → alarm', T({ soru: '2026 tarifesinin ikinci gelir dilimi tutarı 330.000 TL\'dir.' }), 1],
    ['EK31 meşru: varsayım', T({ soru: '2026 tarifesinin ikinci dilim tutarının 330.000 TL olduğu varsayılmıştır.' }), 0],
    ['EK32 "2026 mesken istisnası 33.000" → alarm', T({ soru: '2026 yılı için konut kira geliri istisnası 33.000 TL\'dir.' }), 1],
    ['EK32 meşru: 2025 yılı tutarı', T({ aciklama: { A: '2025 yılı mesken kira istisnası 47.000 TL idi.' } }), 0],
    ['EK33 "2026 aylık kira sınırı 26.000" → alarm', T({ soru: '2026 yılı için binek otomobil aylık kira sınırı 26.000 TL\'dir.' }), 1],
    ['EK33 meşru: varsayım', T({ soru: '2026 yılı için aylık kira sınırının 26.000 TL olduğu varsayılmıştır.' }), 0],
    // 10.10 (onarım oturumu ölçtü): gerçek 2026 tutarı 46.000 içindeki "6.000" alarm veriyordu (smmm-4k-a-yvergi-zor-r5/kp-16 onarımı)
    ['EK33 meşru: gerçek 2026 tutarı 46.000 (içinde 6.000 geçer)', T({ soru: '2026 yılı için binek otomobil aylık kira bedeli sınırı 46.000 TL\'dir.' }), 0],
    ['EK34 "basit usul kazancı beyan edilir" → alarm', T({ aciklama: { A: 'Basit usulde kazanç ticari kazanç olarak beyan edilir.' } }), 1],
    ['EK34 meşru: mük. 20/A istisna', T({ aciklama: { A: 'Basit usul kazancı mük. m.20/A gereği istisnadır, beyanname verilmez.' } }), 0],
    ['EK35 "2026 … teşvik belgeli … inşaat KDV iadesi" → alarm', T({ soru: 'İşletme 2026 yılında teşvik belgeli büyük yatırımının inşaat işleri KDV\'sini izleyen yıl iade alır.' }), 1],
    ['EK35 "teşvik belgesi … inşaat … 2026 yılında … KDV" (yıl sonra) → alarm (dog1-vergi/kp-51 10.10)', T({ soru: 'Yatırım teşvik belgesi kapsamındaki yatırımın inşaat işleri nedeniyle 2026 yılında 4.000.000 TL katma değer vergisi yüklenmiş, izleyen yıl iade edilmiştir.' }), 1],
    ['EK35 meşru: 2022 yılı', T({ soru: 'İşletme 2022 yılında teşvik belgeli büyük yatırımının inşaat işleri KDV\'sini izleyen yıl iade almıştır.' }), 0],
    ['EK36 "6183 m.51 … %2,5" → alarm', T({ soru: 'Vergi, 6183 sayılı Kanunun 51. maddesindeki aylık %2,5 gecikme zammıyla ödenmiştir.' }), 1],
    ['EK36 meşru: varsayım', T({ soru: 'Gecikme zammı oranının aylık %2,5 olduğu varsayılmıştır (6183 m.51).' }), 0],
    ['EK37 eski azami damga tutarı yılsız → alarm', T({ aciklama: { A: 'Firma azami tutar olan 10.732.371,80 TL üzerinden damga vergisi ödemiştir.' } }), 1],
    ['EK37 meşru: yılı yazılı', T({ aciklama: { A: '2023 yılı azami tutarı olan 10.732.371,80 TL üzerinden vergi ödenmiştir.' } }), 0],
    ['EK38 ücret damgası istisnasız → alarm', T({ adimlar: [{ anlatim: 'Brüt ücret 90.000 TL; damga vergisi binde 7,59 ile 683,10 TL.' }] }), 1],
    ['EK38 meşru: asgari ücret istisnası düşülerek', T({ adimlar: [{ anlatim: 'Asgari ücreti aşan kısım üzerinden damga vergisi binde 7,59 ile hesaplanır.' }] }), 0],
    ['EK39 "2026 m.177 alım haddi 5.900.000" → alarm', T({ soru: '2026 yılında VUK m.177 uyarınca alım haddi 5.900.000 TL\'dir.' }), 1],
    ['EK39 meşru: varsayılırsa', T({ soru: 'VUK m.177/3\'teki haddin 3.400.000 TL olduğu varsayılırsa işletme hangi sınıftadır?' }), 0],
    ['EK40 "bir milyon TL … basit yargılama" → alarm', T({ aciklama: { A: 'Değeri bir milyon TL\'yi geçmeyen ticari davalarda basit yargılama usulü uygulanır.' } }), 1],
    ['EK40 meşru: yeniden değerleme ile artırılır', T({ aciklama: { A: 'Basit yargılama sınırı 1.000.000 TL olarak konmuş, her yıl yeniden değerleme oranıyla artırılır.' } }), 0],
    ['EK41 "İleri tarihli çek … ibraz günü ödenir" (büyük İ) → alarm', T({ aciklama: { A: 'İleri tarihli çek, tarihinden önce bankaya getirilirse ibraz günü ödenir.' } }), 1],
    ['EK41 meşru: geçici m.3/5 anılıyor', T({ aciklama: { A: 'Genel kurala göre erken ibrazda ibraz günü ödenir; ancak Çek Kanunu geçici m.3/5 uyarınca 31/12/2028\'e kadar bu ibraz geçersizdir.' } }), 0],
    ['EK42 "askerlik borçlanmasında %39" → alarm', T({ hap: 'Askerlik borçlanmasında oran %39 uygulanır.' }), 1],
    ['EK42 meşru: "%39,00 duran varlık payı" (oran değil, askerlik yok)', T({ adimlar: [{ formul: 'Duran Varlık Payı = 487.500 / 1.250.000 = %39,00' }] }), 0],
    ['EK43 "nispi aidat %1" → alarm', T({ aciklama: { A: 'Nispi aidat, bir önceki yıl mesleki kazancın %1\'i olarak odaya ödenir.' } }), 1],
    ['EK43 meşru: Danıştay iptali anılıyor', T({ aciklama: { A: 'Nispi aidatı %1 olarak belirleyen alt bent Danıştay kararıyla iptal edilmiştir.' } }), 0],
    ['EK14 meşru: "düzeltme yapılmaz"', T({ aciklama: { A: 'Faydalı ömrünü tamamlayıp zayi olan ATİK\'in alımda indirilen KDV\'si için düzeltme yapılmaz.' } }), 0],
    ['EK14 meşru: yanlış şıkta "Mükerrer İndirim Tuzağı"', T({ aciklama: { B: 'Mükerrer İndirim Tuzağı: faydalı ömrünü tamamlayıp zayi olan forkliftin KDV\'sini bu dönem yeniden indirdin.' } }), 0],
    ['atif_genisletme iz kaydı taranmaz (öğrenci görmez)', T({ atif_genisletme: ['TMS 1 p.82 - Kâr veya zarar'] }), 0],
    ['model alanı taranmaz (öğrenci görmez)', T({ hakem: { gerekce: 'KDV oranı %18 uygulanır.' } }), 0]
  ];
  let g = 0;
  for (const [ad, k, bek] of vakalar) {
    const n = denetle(k).length, ok = n === bek; if (ok) g++;
    console.log((ok ? '  ✓ ' : '  ✗ ') + ad + (ok ? '' : ' (beklenen ' + bek + ', çıkan ' + n + ')'));
  }
  console.log('ESKI-KURAL-SINAVI: ' + (g === vakalar.length ? 'YESIL' : 'KIRMIZI') + ' — ' + g + '/' + vakalar.length + (MUT ? ' · EK_MUTASYON=' + MUT : ''));
  return g === vakalar.length;
}

if (require.main === module) {
  const a = process.argv.slice(2);
  if (a.includes('--sinav')) {
    if (a.includes('--mutasyon')) {
      const { spawnSync } = require('child_process'); const ler = ['haric-yok', 'model-dahil', 'sik-haric-yok']; let t = 0;
      for (const m of ler) { const r = spawnSync(process.execPath, [__filename, '--sinav'], { env: Object.assign({}, process.env, { EK_MUTASYON: m }), encoding: 'utf8' });
        if (r.status !== 0) t++; console.log('  mutasyon ' + m.padEnd(12) + (r.status !== 0 ? 'KIRMIZI (doğru)' : 'YESIL (YANLIŞ)')); }
      console.log('MUTASYON: ' + t + '/' + ler.length + ' → KIRMIZI'); process.exit(t === ler.length ? 0 : 1);
    }
    process.exit(sinav() ? 0 : 1);
  }
  const i = a.indexOf('--dosya');
  if (i >= 0) {
    let n = 0; const ds = a.slice(i + 1).filter(x => !x.startsWith('--'));
    for (const d of ds) { const p = JSON.parse(fs.readFileSync(d, 'utf8')); const et = path.basename(d).replace(/^kalip-parti-|\.json$/g, '');
      for (const kp of Object.keys(p)) if (/^kp-/.test(kp)) denetle(p[kp]).forEach(b => { n++; console.log('KAPI-EK ' + et + '/' + kp + ' ' + b.kod + ' ' + b.alan + ': ' + b.parca); }); }
    console.log('KAPI-EK: ' + ds.length + ' parti, ' + n + ' bulgu'); process.exit(n ? 1 : 0);
  }
  const j = a.indexOf('--banka');
  if (j >= 0) {
    const onek = a[j + 1] || 'sgs-', kok = path.join(__dirname, '..', 'veri', 'fabrika');
    const fs2 = fs.readdirSync(kok).filter(f => f.startsWith('kalip-parti-' + onek) && f.endsWith('.json'));
    const bul = []; let soru = 0; const say = {};
    for (const f of fs2) { let p; try { p = JSON.parse(fs.readFileSync(path.join(kok, f), 'utf8')); } catch (e) { continue; }
      const et = f.replace(/^kalip-parti-|\.json$/g, '');
      for (const kp of Object.keys(p)) { if (!/^kp-/.test(kp)) continue; soru++;
        denetle(p[kp]).forEach(b => { bul.push(Object.assign({ anahtar: et + '/' + kp }, b)); say[b.kod] = (say[b.kod] || 0) + 1; }); } }
    const sorular = new Set(bul.map(b => b.anahtar));
    console.log('KAPI-EK BANKA (' + onek + '*): ' + fs2.length + ' parti · ' + soru + ' soru · işaretli soru ' + sorular.size + ' · bulgu ' + bul.length + ' · ' + JSON.stringify(say));
    const o = a.indexOf('--yaz'); if (o >= 0) fs.writeFileSync(a[o + 1], JSON.stringify({ olcum: new Date().toISOString(), onek, soru, bulgular: bul }, null, 1));
    process.exit(0);
  }
  console.log('kullanım: --sinav [--mutasyon] | --dosya <parti.json...> | --banka <önek> [--yaz <çıktı>]'); process.exit(2);
}
module.exports = { denetle, LISTE };
