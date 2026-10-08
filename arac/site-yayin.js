#!/usr/bin/env node
/* ============================================================================
 *  SİTE YAYINI — BEYAZ LİSTE (08.10.2026, açılış sonrası iş: "yalnız site dosyalarını yayınla")
 *
 *  NEDEN: tetikte.com, GitHub Pages "Deploy from branch" ile deponun KÖKÜNDEN yayınlanıyordu; deponun
 *  tamamı herkese açıktı (08.10 ölçüldü: /CLAUDE.md, /DEVIR-NOTU.md, /motor/*.ps1, /radar-app/sql/UYGULANDI.md,
 *  /radar-app/edge/*.ts, /veri/*.md, motor/cikti/ altında 354 HTML 200 dönüyordu). Bu betik yayına giden
 *  dosyaları BEYAZ LİSTEYLE seçer; liste dışındaki hiçbir dosya yayına çıkmaz.
 *
 *  LİSTE: arac/site-beyaz-liste.txt (satır başına bir kalıp; "!" ile başlayan satır hariç tutar;
 *         "*" bölü işaretini geçmez, "**" her derinliği geçer; "#" yorum).
 *
 *  KULLANIM
 *    node arac/site-yayin.js --kur _site            liste ile yayın klasörünü kurar (git ls-files'tan)
 *    node arac/site-yayin.js --kur _site --denetim  kurar + üç denetim (aşağıda); ihlalde çıkış 1
 *    node arac/site-yayin.js --eslesir <yol>...     yolların listeye girip girmediğini yazar (iş akışı kullanır)
 *    node arac/site-yayin.js --sinav [--mutasyon]   öz-sınav (dogrula.yml); --mutasyon her kilit koşulu
 *                                                   tek tek bozar, her bozmada sınav KIRMIZI düşmeli
 *
 *  DENETİMLER (--denetim)
 *    YASAK    yayına iç dosya girdi (md/ps1/sql/ts/yml, motor/, arac/, radar-app/, .github/ ...)
 *    ZORUNLU  sitenin olmazsa olmazı yayında yok (index, 404, CNAME, robots, sitemap + haritadaki her adres)
 *    KOPUK    yayındaki bir HTML/JS/CSS'in TIRNAK İÇİNDE andığı depo dosyası yayında yok
 *             (yeni sayfa yeni bir veri/ dosyası çekiyorsa liste güncellenmeden yayın düşer)
 *
 *  🚫 GÖRMEZ: dizgeyle birleştirilen yollar ('veri/canli/' + kod + '.json' gibi; bunlar listede kalıpla
 *     tutulur ve ölçümü tarayıcı taramasıdır: arac/site-esdegerlik.js) · tırnaksız yazılmış yol ·
 *     depoda olmayan (robotun ileride yazacağı) dosyanın adı · sayfanın gerçekten ÇALIŞIP çalışmadığı.
 * ==========================================================================*/
'use strict';
const fs = require('fs'), path = require('path'), cp = require('child_process');
const MUT = process.env.SY_MUTASYON || '';

/* ---- kalıp eşleme ---------------------------------------------------------- */
function kaliptanRe(k) {
  let s = '';
  for (let i = 0; i < k.length; i++) {
    const c = k[i];
    if (c === '*' && k[i + 1] === '*') { s += (MUT === 'glob' ? '[^/]*' : '.*'); i++; if (k[i + 1] === '/') { i++; s += (MUT === 'glob' ? '/' : '(?:/|)'); } }
    else if (c === '*') s += (MUT === 'glob' ? '.*' : '[^/]*');
    else if (c === '?') s += '[^/]';
    else s += c.replace(/[.+^${}()|[\]\\]/g, '\\$&');
  }
  return new RegExp('^' + s + '$');
}
function listeOku(metin) {
  const dahil = [], haric = [];
  for (let sat of metin.split(/\r?\n/)) {
    sat = sat.replace(/\s+#.*$/, '').trim();
    if (!sat || sat.startsWith('#')) continue;
    if (sat.startsWith('!')) { if (MUT !== 'haric') haric.push(kaliptanRe(sat.slice(1).trim())); }
    else dahil.push(kaliptanRe(sat));
  }
  return { dahil, haric };
}
const eslesir = (L, y) => L.dahil.some(r => r.test(y)) && !L.haric.some(r => r.test(y));

/* ---- YASAK: yayına ASLA girmeyecek iç dosyalar (listeden bağımsız ikinci kilit) ---- */
const YASAK = [
  /(^|\/)[^/]*\.(md|ps1|psm1|psd1|sql|ts|yml|yaml|bat|cmd|sh|py|cs|csproj|sln|env|pem|key|bak|log)$/i,
  /^(motor|arac|radar-app|rag-motor|mobil|evrak-app|tasarim|pazarlama|kapsam|kaynak-ozetleri|gelen|_[^/]*|\.[^/]*)\//,
  /^\.(git|github)/,
  /^(CLAUDE|DEVIR-NOTU|README)(\.|$)/i,
];
const yasakMi = y => YASAK.some(r => r.test(y));

/* ---- ZORUNLU: sitenin olmazsa olmazı + haritadaki ve canlı taramadaki her sayfa ---- */
function zorunluListe(kok) {
  const z = ['index.html', '404.html', 'CNAME', 'robots.txt', 'sitemap.xml', 'manifest.webmanifest', 'menu.js', 'stil.css', 'stil-acik.css'];
  try {
    const h = fs.readFileSync(path.join(kok, 'sitemap.xml'), 'utf8');
    for (const m of h.matchAll(/<loc>https?:\/\/[^/<]+\/([^<]*)<\/loc>/g)) z.push(m[1] === '' || m[1].endsWith('/') ? m[1] + 'index.html' : m[1]);
  } catch (e) {}
  try {
    const t = fs.readFileSync(path.join(kok, 'motor', 'canli-tarama.js'), 'utf8');
    const b = t.indexOf('const SAYFALAR'), s = t.indexOf('];', b);
    if (b > -1) for (const m of t.slice(b, s).matchAll(/^\s*\['([^'?]+)/gm)) z.push(m[1]);   // yalnız satır başındaki öğe (iç dizi = beklenen öğeler)
  } catch (e) {}
  return [...new Set(z)];
}

/* ---- dosya listesi: git ls-files (izlenen dosya), git yoksa klasör taraması (öz-sınav) ---- */
function dosyalar(kok) {
  if (fs.existsSync(path.join(kok, '.git'))) {
    return cp.execSync('git ls-files -z', { cwd: kok, maxBuffer: 1 << 28 }).toString().split('\0').filter(Boolean)
      .filter(f => fs.existsSync(path.join(kok, f)));   // silinmiş ama sahnelenmemiş dosya yayına giremez
  }
  const o = [];
  (function gez(d, on) { for (const e of fs.readdirSync(d, { withFileTypes: true })) { const y = on ? on + '/' + e.name : e.name; e.isDirectory() ? gez(path.join(d, e.name), y) : o.push(y); } })(kok, '');
  return o;
}

/* ---- KOPUK: yayındaki metin dosyalarında tırnak içindeki yol başvuruları ---- */
const UZ = 'html|js|mjs|css|json|png|jpe?g|svg|pdf|webmanifest|xml|txt|ico|webp|woff2?|gif|csv|mp4|mp3';
const TIRNAK = new RegExp(`["'\`]((?:\\.{0,2}/)?[A-Za-z0-9_\\-./%]+\\.(?:${UZ}))(?:[?#][^"'\`]*)?["'\`]`, 'g');
function baglar(kok, yayin, izli) {
  const kopuk = [], not = [];
  for (const f of yayin) {
    if (!/\.(html|js|mjs|css)$/i.test(f)) continue;
    const t = fs.readFileSync(path.join(kok, f), 'utf8'), dir = path.posix.dirname(f);
    for (const m of t.matchAll(TIRNAK)) {
      let p = m[1]; if (/^\/\//.test(p)) continue;
      try { p = decodeURIComponent(p); } catch (e) {}
      const aday = p.startsWith('/') ? [p.slice(1)] : [path.posix.normalize(path.posix.join(dir, p)), path.posix.normalize(p.replace(/^\.\//, ''))];
      const var_ = aday.find(a => izli.has(a));
      if (!var_ || yayin.has(var_) || aday.some(a => yayin.has(a))) continue;
      (yasakMi(var_) ? not : kopuk).push(f + ' -> ' + var_);
    }
  }
  return { kopuk: [...new Set(kopuk)], not: [...new Set(not)] };
}

function kur(kok, hedef, listeYolu) {
  const L = listeOku(fs.readFileSync(listeYolu, 'utf8'));
  const tum = dosyalar(kok), izli = new Set(tum);
  const yayin = new Set(tum.filter(f => eslesir(L, f)));
  if (hedef) {
    fs.rmSync(hedef, { recursive: true, force: true });
    for (const f of yayin) { const h = path.join(hedef, f); fs.mkdirSync(path.dirname(h), { recursive: true }); fs.copyFileSync(path.join(kok, f), h); }
  }
  return { L, tum, izli, yayin };
}

/* ---- TETİK: ana tele iten her robot akışı site-yayin.yml'nin workflow_run listesinde olmalı ----
   Neden: robotlar GITHUB_TOKEN ile itiyor; bu itmeler "push" tetiğini ÇALIŞTIRMAZ. Listede olmayan robotun
   yazdığı veri, sonraki elle push'a ya da yarım saatlik yedek koşuya kadar siteye çıkmaz. */
const AKIS = '.github/workflows', YAYIN_AKIS = 'site-yayin.yml';
function itenAkislar(kok) {
  const d = path.join(kok, AKIS); if (!fs.existsSync(d)) return [];
  const o = [];
  for (const f of fs.readdirSync(d).filter(x => /\.ya?ml$/.test(x) && x !== YAYIN_AKIS).sort()) {
    const t = fs.readFileSync(path.join(d, f), 'utf8');
    if (!/^[^#\n]*git push/m.test(t)) continue;            // yorumdaki "git push" sayılmaz
    const n = (t.match(/^name:\s*(.+?)\s*$/m) || [])[1];
    o.push({ dosya: f, ad: n ? n.replace(/^(['"])(.*)\1$/, '$2') : null });
  }
  return o;
}
const TETIK_BAS = '# >>> TETIK LISTESI (node arac/site-yayin.js --tetik-yaz uretir; elle duzenlenmez)', TETIK_SON = '# <<< TETIK LISTESI';
function tetikBlok(kok) {
  return itenAkislar(kok).filter(x => x.ad).map(x => '      - "' + x.ad.replace(/\\/g, '\\\\').replace(/"/g, '\\"') + '"   # ' + x.dosya).join('\n');
}
function tetikDenetle(kok) {
  const y = path.join(kok, AKIS, YAYIN_AKIS); if (!fs.existsSync(y)) return ['TETIK ' + YAYIN_AKIS + ' yok'];
  const t = fs.readFileSync(y, 'utf8'), b = t.indexOf(TETIK_BAS), s = t.indexOf(TETIK_SON);
  if (b < 0 || s < 0) return ['TETIK işaretli liste bloğu yok'];
  const var_ = new Set([...t.slice(b, s).matchAll(/^\s*-\s*"((?:[^"\\]|\\.)*)"/gm)].map(m => m[1].replace(/\\(.)/g, '$1')));
  const o = [];
  for (const x of itenAkislar(kok)) {
    if (!x.ad) o.push('TETIK ' + x.dosya + ' adsız (workflow_run adla bağlanır)');
    else if (!var_.has(x.ad)) o.push('TETIK ' + x.dosya + ' ("' + x.ad + '") ana tele itiyor ama ' + YAYIN_AKIS + ' tetik listesinde yok -> node arac/site-yayin.js --tetik-yaz');
  }
  return o;
}

function denetle(kok, r, tetik) {
  const ihlal = [];
  if (MUT !== 'yasak') for (const f of r.yayin) if (yasakMi(f)) ihlal.push('YASAK ' + f);
  if (MUT !== 'zorunlu') for (const z of zorunluListe(kok)) if (!r.yayin.has(z)) ihlal.push('ZORUNLU ' + z + ' yayında yok');
  const b = baglar(kok, r.yayin, r.izli);
  if (MUT !== 'bag') b.kopuk.forEach(k => ihlal.push('KOPUK ' + k));
  if (tetik && MUT !== 'tetik') ihlal.push(...tetikDenetle(kok));
  return { ihlal, not: b.not };
}

/* ---- öz-sınav ---------------------------------------------------------------- */
function sinav() {
  const os = require('os');
  const vakalar = [];
  const yaz = (kok, d) => { for (const [y, t] of Object.entries(d)) { if (t === null) continue; const h = path.join(kok, y); fs.mkdirSync(path.dirname(h), { recursive: true }); fs.writeFileSync(h, t); } };
  const TEMEL = {
    'index.html': '<link href="stil.css"><script src="menu.js"></script><script>fetch("veri/a.json")</script>',
    '404.html': 'yok', 'CNAME': 'x.com', 'robots.txt': '', 'manifest.webmanifest': '{}', 'menu.js': 'fetch(\'veri/b.json?t=1\')',
    'stil.css': 'body{}', 'stil-acik.css': '', 'fiyat.html': '<a href="/kaydir/sgs/turkce.html">x</a>',
    'sitemap.xml': '<urlset><url><loc>https://x.com/</loc></url><url><loc>https://x.com/fiyat.html</loc></url></urlset>',
    'kaydir/sgs/turkce.html': '<img src="../../gorsel/a.png">', 'gorsel/a.png': 'p',
    'veri/a.json': '{}', 'veri/b.json': '{}', 'veri/IC-NOT.md': '#', 'veri/ic.json': '{}',
    'CLAUDE.md': '#', 'motor/x.ps1': '', 'radar-app/sql/UYGULANDI.md': '', 'radar-app/edge/f.ts': '', 'kok-not.md': '',
    'gizli.html': '<!-- motor/x.ps1 üretir --> <script>/* "arac/y.js" yorumu */</script>', 'arac/y.js': '',
    'motor/canli-tarama.js': "const SAYFALAR = [\n  ['index.html', ['#nav', '.uc'], true],\n  ['kaydir/sgs/turkce.html?x=1', ['body'], false],\n];",
    '.github/workflows/a.yml': 'name: Robot A (ite)\non: push\njobs:\n  x:\n    steps:\n      - run: git push origin HEAD:main\n',
    '.github/workflows/b.yml': 'name: Yalniz okur\n# git push yapmaz\njobs: {}\n',
    '.github/workflows/site-yayin.yml': 'on:\n  workflow_run:\n    workflows:\n' + TETIK_BAS + '\n      - "Robot A (ite)"   # a.yml\n' + TETIK_SON + '\n',
  };
  const LISTE = '*.html\n*.js\n*.css\n*.webmanifest\nCNAME\nrobots.txt\nsitemap.xml\nkaydir/**\ngorsel/**\nveri/a.json\nveri/b.json\n';
  function kos(ad, ekDosya, liste, bekleIhlal) {
    const kok = fs.mkdtempSync(path.join(os.tmpdir(), 'sy-'));
    yaz(kok, Object.assign({}, TEMEL, ekDosya)); fs.writeFileSync(path.join(kok, '_liste.txt'), liste);
    for (const [y, t] of Object.entries(ekDosya)) if (t === null) fs.rmSync(path.join(kok, y), { force: true });
    const r = kur(kok, null, path.join(kok, '_liste.txt'));
    r.yayin.delete('_liste.txt');
    const d = denetle(kok, r, true);
    const tur = [...new Set(d.ihlal.map(x => x.split(' ')[0]))].sort().join(',');
    const gecti = tur === bekleIhlal;
    vakalar.push({ ad, gecti, beklenen: bekleIhlal || '(temiz)', bulunan: tur || '(temiz)', yayin: r.yayin });
    fs.rmSync(kok, { recursive: true, force: true });
    return r;
  }
  // 1) temiz: iç dosyalar yayında değil, site dosyaları yayında
  const t = kos('temiz kurulum', {}, LISTE, '');
  const icYok = ['CLAUDE.md', 'motor/x.ps1', 'radar-app/sql/UYGULANDI.md', 'radar-app/edge/f.ts', 'veri/IC-NOT.md', 'veri/ic.json', 'kok-not.md', 'arac/y.js'].every(f => !t.yayin.has(f));
  const siteVar = ['index.html', 'kaydir/sgs/turkce.html', 'gorsel/a.png', 'veri/a.json', 'veri/b.json', 'CNAME', 'gizli.html'].every(f => t.yayin.has(f));
  vakalar.push({ ad: 'temiz: iç dosya yayında YOK', gecti: icYok }, { ad: 'temiz: site dosyası yayında VAR', gecti: siteVar });
  // 2) yeni sayfa listede olmayan veri dosyası çekiyor -> KOPUK
  kos('yeni veri dosyası listede yok', { 'yeni.html': '<script>fetch("veri/ic.json")</script>' }, LISTE, 'KOPUK');
  // 3) kök-göreli ve ../ ile anılan dosya
  kos('kök-göreli yol listede yok', { 'kaydir/sgs/turkce.html': '<img src="/gorsel/a.png"><script src="/veri/ic.json"></script>' }, LISTE, 'KOPUK');
  // 4) liste yanlışlıkla bütün veri/'yı açtı -> veri/IC-NOT.md YASAK
  kos('liste veri/** açtı', {}, LISTE + 'veri/**\n', 'YASAK');
  // 5) liste motor/ açtı
  kos('liste motor/** açtı', {}, LISTE + 'motor/**\n', 'YASAK');
  // 6) haric satırı çalışıyor: veri/** açık ama !veri/*.md ve !veri/ic.json kapalı -> temiz
  kos('hariç satırı', {}, LISTE + 'veri/**\n!veri/*.md\n!veri/ic.json\n', '');
  // 7) zorunlu sayfa (haritadaki fiyat.html) silinmiş
  kos('haritadaki sayfa yok', { 'fiyat.html': null }, LISTE, 'ZORUNLU');
  // 8) CNAME listeden düştü
  kos('CNAME listeden düştü', {}, LISTE.replace('CNAME\n', ''), 'ZORUNLU');
  // 9) yorumdaki tırnaksız iç yol yanlış alarm vermez; tırnaklı iç yol yalnız NOT
  kos('yorumdaki iç yol (yanlış alarm yok)', {}, LISTE, '');
  // 10) "*" bölü geçmez: kökteki *.html alt klasördeki iç sayfayı açmaz
  // 11) yeni robot ana tele itiyor ama yayın akışının tetik listesinde yok
  kos('iten robot tetik listesinde yok', { '.github/workflows/c.yml': 'name: Robot C\njobs:\n  x:\n    steps:\n      - run: |\n          git push origin HEAD:main\n' }, LISTE, 'TETIK');
  // 12) canlı taramadaki sayfa silinmiş (iç dizideki '#nav' sayfa sanılmamalı -> temiz vakada ölçülür)
  kos('canlı taramadaki sayfa yok', { 'kaydir/sgs/turkce.html': null }, LISTE, 'ZORUNLU');
  const r10 = kos('* bölü geçmez', { 'motor/cikti/rapor.html': 'x' }, LISTE, '');
  vakalar.push({ ad: '* bölü geçmez: motor/cikti/rapor.html yayında YOK', gecti: !r10.yayin.has('motor/cikti/rapor.html') });

  let kirmizi = 0;
  for (const v of vakalar) { if (!v.gecti) kirmizi++; console.log((v.gecti ? 'GEÇTİ ' : 'DÜŞTÜ ') + v.ad + (v.beklenen ? '  [beklenen ' + v.beklenen + ' · bulunan ' + v.bulunan + ']' : '')); }
  console.log('ÖZ-SINAV: ' + (vakalar.length - kirmizi) + '/' + vakalar.length + (MUT ? ' (mutasyon ' + MUT + ')' : ''));
  return kirmizi === 0;
}

/* ---- giriş ---------------------------------------------------------------- */
const a = process.argv.slice(2);
const KOK = path.resolve(__dirname, '..'), LISTE = path.join(KOK, 'arac', 'site-beyaz-liste.txt');
if (a.includes('--sinav')) {
  if (a.includes('--mutasyon')) {
    let hepsi = true;
    for (const m of ['yasak', 'zorunlu', 'bag', 'haric', 'glob', 'tetik']) {
      const r = cp.spawnSync(process.execPath, [__filename, '--sinav'], { env: Object.assign({}, process.env, { SY_MUTASYON: m }), encoding: 'utf8' });
      const dustu = r.status !== 0;
      console.log('MUTASYON ' + m + ': ' + (dustu ? 'KIRMIZI (doğru)' : 'YEŞİL KALDI — sınav bu koşulu ölçmüyor'));
      if (!dustu) hepsi = false;
    }
    const temiz = cp.spawnSync(process.execPath, [__filename, '--sinav'], { encoding: 'utf8' });
    console.log('BOZULMAMIŞ: ' + (temiz.status === 0 ? 'YEŞİL (doğru)' : 'KIRMIZI'));
    process.exit(hepsi && temiz.status === 0 ? 0 : 1);
  }
  process.exit(sinav() ? 0 : 1);
}
if (a.includes('--eslesir')) {
  const L = listeOku(fs.readFileSync(LISTE, 'utf8'));
  const yollar = a.slice(a.indexOf('--eslesir') + 1);
  const girdi = yollar.length ? yollar : fs.readFileSync(0, 'utf8').split(/\r?\n/).filter(Boolean);
  const o = girdi.filter(y => eslesir(L, y));
  if (o.length) process.stdout.write(o.join('\n') + '\n');
  return;   // process.exit değil: borudaki çıktı yarıda kesilmesin
}
if (a.includes('--tetik-yaz')) {
  const y = path.join(KOK, AKIS, YAYIN_AKIS), t = fs.readFileSync(y, 'utf8');
  const b = t.indexOf(TETIK_BAS), s = t.indexOf(TETIK_SON);
  if (b < 0 || s < 0) { console.log('işaretli blok yok'); process.exit(1); }
  const yeni = t.slice(0, b) + TETIK_BAS + '\n' + tetikBlok(KOK) + '\n      ' + t.slice(s);
  if (yeni !== t) { fs.writeFileSync(y, yeni); console.log('tetik listesi yazıldı: ' + itenAkislar(KOK).length + ' akış'); }
  else console.log('tetik listesi aynı (' + itenAkislar(KOK).length + ' akış), dokunulmadı');
  process.exit(0);
}
const ki = a.indexOf('--kur');
if (ki > -1) {
  const hedef = path.resolve(a[ki + 1]);
  const r = kur(KOK, hedef, LISTE);
  let boyut = 0; for (const f of r.yayin) boyut += fs.statSync(path.join(KOK, f)).size;
  console.log('YAYIN: ' + r.yayin.size + ' dosya / depoda izlenen ' + r.tum.length + ' · ' + (boyut / 1048576).toFixed(1) + ' MB -> ' + hedef);
  if (a.includes('--denetim')) {
    // --uyari KOPUK,TETIK : bu türler yayını DURDURMAZ, yalnız uyarır (yayın akışı; kapı kuralı 7 — bir kopuk
    // başvuru yüzünden bütün robot verisinin siteye çıkması durmasın). YASAK ve ZORUNLU her zaman durdurur.
    const ui = a.indexOf('--uyari'), uyari = new Set(ui > -1 ? a[ui + 1].split(',') : []);
    const d = denetle(KOK, r, a.includes('--tetik'));
    d.not.slice(0, 20).forEach(n => console.log('NOT (iç dosya anılıyor, yayına alınmadı) ' + n));
    if (d.not.length > 20) console.log('NOT ... +' + (d.not.length - 20));
    const dur = d.ihlal.filter(i => !uyari.has(i.split(' ')[0])), uy = d.ihlal.filter(i => uyari.has(i.split(' ')[0]));
    uy.forEach(i => console.log('UYARI ' + i));
    dur.forEach(i => console.log('İHLAL ' + i));
    const say = t => d.ihlal.filter(i => i.startsWith(t + ' ')).length;
    console.log('DENETİM: ' + (dur.length ? 'KIRMIZI' : uy.length ? 'YEŞİL (uyarılı)' : 'YEŞİL') + ' · YASAK ' + say('YASAK') + ' · ZORUNLU ' + say('ZORUNLU') + '/' + zorunluListe(KOK).length +
      ' · KOPUK ' + say('KOPUK') + ' · TETIK ' + (a.includes('--tetik') ? say('TETIK') + '/' + itenAkislar(KOK).length + ' iten akış' : 'ölçülmedi') + ' · NOT ' + d.not.length);
    process.exit(dur.length ? 1 : 0);
  }
  process.exit(0);
}
console.log('kullanım: --kur <dizin> [--denetim] | --eslesir <yol>... | --sinav [--mutasyon]');
process.exit(2);
