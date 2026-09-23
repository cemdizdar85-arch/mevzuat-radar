// ============================================================================
//  SATIR İÇİ :root JETON TARAMASI (23.09.2026, Cem "2 yap") — SALT OKUMA, hiçbir dosyaya yazmaz.
//  NEDEN: 23.09'da kartlar/radar/karsilastirma/alacak-radari koyu temada okunmuyordu; kök, sayfanın ya da
//  üreticinin kendi :root kopyasındaki eski --dim idi (09.09 stil.css düzeltmesi kopyalara ulaşmamıştı).
//  NE YAPAR: stil.css (koyu) + stil-acik.css (açık) :root jetonlarını referans alır; üretici betiklerde
//  (motor/, arac/) ve kök HTML'de :root{...} bloklarında AYNI ADLI jetona FARKLI değer verenleri listeler.
//  GÖRMEZ: :root dışındaki yerel tanımları (body.x{--dim:...}), çok satırlı olmayan kurgu dışı bloklar, arsiv/.
//  Farklı değer her zaman kusur değildir (sayfaya özgü palet); kusur olup olmadığını kontrast kapısı söyler.
//  Kullanım: node arac/root-jeton-tarama.js
// ============================================================================
const fs = require('fs'), path = require('path'), { execSync } = require('child_process');
const kok = process.cwd();
function jetonlar(css) {
  const o = {}; const re = /:root\s*\{([^}]*)\}/g; let m;
  while ((m = re.exec(css))) for (const p of m[1].split(';')) { const q = p.match(/^\s*(--[\w-]+)\s*:\s*(.+?)\s*$/); if (q) o[q[1]] = (o[q[1]] ?? q[2].replace(/\/\*.*?\*\//g, '').trim()); }
  return o;
}
const norm = v => String(v).toLowerCase().replace(/\s+/g, '');
const koyu = jetonlar(fs.readFileSync(path.join(kok, 'stil.css'), 'utf8'));
const acik = jetonlar(fs.readFileSync(path.join(kok, 'stil-acik.css'), 'utf8'));
const dosyalar = execSync('git ls-files "motor/*.ps1" "motor/*.js" "arac/*.ps1" "arac/*.js" "*.html"', { encoding: 'utf8' })
  .split('\n').filter(f => f && !f.includes('/') || /^(motor|arac)\//.test(f)).filter(f => f && !/^arsiv\//.test(f));
const bulgu = [];
for (const f of dosyalar) {
  const t = fs.readFileSync(path.join(kok, f), 'utf8');
  if (!/:root\s*\{/.test(t)) continue;
  const j = jetonlar(t);
  const stilBagli = /\.html$/.test(f) ? /stil\.css/.test(t) : /stil\.css/.test(t);
  const acikBagli = /stil-acik\.css/.test(t);
  const ayri = [];
  for (const [k, v] of Object.entries(j)) {
    if (!(k in koyu)) continue;                       // yerel jeton: ortakta yok, ayrışma değil
    if (norm(v) !== norm(koyu[k])) ayri.push(`${k}: ${v} (stil.css ${koyu[k]}${k in acik ? ' · açık ' + acik[k] : ''})`);
  }
  if (ayri.length) bulgu.push({ f, stilBagli, acikBagli, ayri });
}
const tur = f => /^(motor|arac)\//.test(f) ? 'ÜRETİCİ' : 'SAYFA';
bulgu.sort((a, b) => tur(a.f).localeCompare(tur(b.f)) || b.ayri.length - a.ayri.length);
for (const b of bulgu) {
  console.log(`${tur(b.f)} ${b.f}  [stil.css ${b.stilBagli ? 'bağlı' : 'YOK'} · stil-acik ${b.acikBagli ? 'bağlı' : 'YOK'}]  ${b.ayri.length} ayrışan jeton`);
  for (const a of b.ayri) console.log('    ' + a);
}
console.log(`\nTOPLAM: ${bulgu.length} dosya (${bulgu.filter(b => tur(b.f) === 'ÜRETİCİ').length} üretici, ${bulgu.filter(b => tur(b.f) === 'SAYFA').length} sayfa) ortak jetona farklı değer veriyor.`);
