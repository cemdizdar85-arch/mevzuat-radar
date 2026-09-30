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
    ['EK5 meşru: "2024 öncesi %10 idi"', T({ aciklama: { A: '2024 yılı sonuna kadar kâr payı stopajı %10 idi.' } }), 0],
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
      const { spawnSync } = require('child_process'); const ler = ['haric-yok', 'model-dahil']; let t = 0;
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
