#!/usr/bin/env node
// ============================================================================
//  KAPI-UCRETSIZ-YOL — ücretsiz deneme yolu 10 soruluk sabit örnek sayfasına çıkmasın (07.10.2026)
//  Cem 07.10: "pakete dahil dediğimde ücretsiz soru çöz yine 10 soru çıkıyor" → "her yerde dene, bir daha böyle karşılaşmayalım".
//  Ücretsiz yol = 30 soruluk seviye testi (seviye-testi.html[?sinav=yeterlilik]) + günün sorusu (index.html?sinav=..#ekran).
//  Bu kapı depodaki yayın sayfalarını (.html + sayfa betikleri) okur ve şunları BULGU sayar:
//    UY-VITRIN : kaydir/vitrin/sgs.html ya da kaydir/vitrin/smmm.html'e bağlantı / yönlendirme
//    UY-DENE   : "ücretsiz dene" yazan bağlantı seviye testine ya da günün sorusuna gitmiyor
//  Muaf: kaydir/vitrin/ klasörünün kendisi (sayfalar birbirine bağlanabilir), yorum satırları, _arsiv/_kapali/tasarim/sql-yerel/mobil
//  (mobil kopyası derlemede güncellenir), arac/ ve motor/ içindeki ölçüm/sınav betikleri (bağlantı değil, dosya yolu).
//  🚫 GÖRMEZ: tarayıcıda çalışırken birleştirilen adresler (ör. 'kaydir/' + 'vitrin/...' parçalı yazım) · menü dışı elle
//     yazılmış adres (kişi adresi kendisi yazarsa sayfa açılır - bilerek) · uygulama içi (mobil/www) kopyası.
//  Kullanım: node arac/ucretsiz-yol-kapisi.js           (depo taraması; bulgu varsa çıkış 1)
//            node arac/ucretsiz-yol-kapisi.js --sinav   (öz-sınav)  ·  --sinav --mutasyon (öz-sınav kendini bozarak sınanır)
// ============================================================================
'use strict';
const fs = require('fs'), path = require('path'), cp = require('child_process');
const KOK = path.resolve(__dirname, '..');
const VITRIN = /kaydir\/vitrin\/(sgs|smmm)\.html/;
const MUAF = /^(_|sql-yerel\/|tasarim\/|arsiv\/|mobil\/|kaydir\/vitrin\/|arac\/|motor\/|radar-app\/|node_modules\/|_kapali)/;

/* yorumları at (HTML <!-- -->, JS /* * / ve // satır sonu) — bağlantı değil açıklama */
function yorumsuz(t) {
  if (process.env.UY_MUTASYON === 'yorum-tara') return t;
  return t.replace(/<!--[\s\S]*?-->/g, '').replace(/\/\*[\s\S]*?\*\//g, '').replace(/(^|[^:'"\\])\/\/[^\n]*/g, '$1');
}
function bulgular(metin) {
  const t = yorumsuz(metin), out = [];
  const satirlar = t.split('\n');
  satirlar.forEach((s, i) => {
    if (process.env.UY_MUTASYON !== 'vitrin-kapat' && VITRIN.test(s)) out.push({ tur: 'UY-VITRIN', satir: i + 1, metin: s.trim().slice(0, 120) });
    // "ücretsiz dene" bağlantısı: aynı <a> içinde metin + href
    const re = /<a\b[^>]*href=["']?([^"'\s>]*)[^>]*>([^<]{0,80}?(?:ücretsiz|Ücretsiz)[^<]{0,40}?dene[^<]{0,20})<\/a>/g; let m;
    while ((m = re.exec(s))) { const href = m[1]; if (!/seviye-testi\.html|index\.html[^"']*#ekran|ucretsiz-dene\.html/.test(href)) out.push({ tur: 'UY-DENE', satir: i + 1, metin: (m[2] + ' -> ' + href).slice(0, 120) }); }
  });
  return out;
}
function tara() {
  const dosyalar = cp.execSync('git ls-files "*.html" "*.js"', { cwd: KOK, encoding: 'utf8', maxBuffer: 1 << 26 }).split('\n').filter(Boolean)
    .filter(f => !MUAF.test(f) && !/(^|\/)(sw|service-worker)\.js$/.test(f));
  const sonuc = [];
  for (const f of dosyalar) { let t; try { t = fs.readFileSync(path.join(KOK, f), 'utf8'); } catch (e) { continue; } for (const b of bulgular(t)) sonuc.push({ dosya: f, ...b }); }
  console.log(`KAPI-UCRETSIZ-YOL: taranan ${dosyalar.length} dosya · bulgu ${sonuc.length}`);
  sonuc.forEach(b => console.log(`  ${b.tur} ${b.dosya}:${b.satir}  ${b.metin}`));
  process.exitCode = sonuc.length ? 1 : 0;
}
function sinav() {
  const V = [
    ['10 soruluk SGS sayfasına bağlantı yakalanır', '<a href="kaydir/vitrin/sgs.html">Örnek sorular</a>', 'UY-VITRIN'],
    ['10 soruluk Yeterlilik sayfasına yönlendirme yakalanır', "location.replace('kaydir/vitrin/smmm.html?vitrin=1');", 'UY-VITRIN'],
    ['ücretsiz dene → yanlış hedef yakalanır', '<a href="fiyat.html">Önce ücretsiz dene</a>', 'UY-DENE'],
    ['seviye testine giden ücretsiz dene → temiz', '<a href="seviye-testi.html?sinav=yeterlilik">Önce ücretsiz dene</a>', null],
    ['günün sorusuna giden ücretsiz dene → temiz', '<a href="index.html?sinav=sgs#ekran">Ücretsiz dene</a>', null],
    ['yorumdaki eski adres → temiz', '<!-- eskiden kaydir/vitrin/sgs.html idi -->\n/* kaydir/vitrin/smmm.html */ var a=1; // kaydir/vitrin/sgs.html', null],
    ['vitrin klasöründeki başka sayfa (deneme.html) → temiz', '<a href="kaydir/vitrin/deneme.html">Tanıtım</a>', null],
  ];
  let ok = 0; for (const [ad, girdi, bek] of V) { const b = bulgular(girdi); const g = bek ? b.some(x => x.tur === bek) : b.length === 0; if (g) ok++; console.log((g ? '  ✓ ' : '  ✗ ') + ad + (g ? '' : ' → ' + JSON.stringify(b))); }
  console.log(`KAPI-UCRETSIZ-YOL ÖZ-SINAVI ${ok === V.length ? 'YEŞİL' : 'KIRMIZI'} (${ok}/${V.length})`); return ok === V.length;
}
if (require.main === module) {
  if (process.argv.includes('--sinav') && process.argv.includes('--mutasyon')) {
    let tamam = true;
    for (const mu of ['vitrin-kapat', 'yorum-tara']) { const r = cp.spawnSync(process.execPath, [__filename, '--sinav'], { env: { ...process.env, UY_MUTASYON: mu }, encoding: 'utf8' }); const kr = r.status !== 0; console.log(`  mutasyon ${mu} ${kr ? 'KIRMIZI (doğru)' : 'YEŞİL (SINAV KÖR!)'}`); tamam = tamam && kr; }
    const ok = sinav(); process.exit(tamam && ok ? 0 : 1);
  } else if (process.argv.includes('--sinav')) process.exit(sinav() ? 0 : 1);
  else tara();
}
module.exports = { bulgular };
