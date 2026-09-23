// ============================================================================
//  SATIR İÇİ :root JETON TARAMASI (23.09.2026, Cem "2 yap") — kaynak dosyaya YAZMAZ.
//  NEDEN: 23.09'da kartlar/radar/karsilastirma/alacak-radari/arsiv-degisim koyu zeminde okunmuyordu; kök, sayfanın
//  ya da üreticinin kendi :root kopyasındaki eski --dim idi (09.09 stil.css düzeltmesi kopyalara ulaşmamıştı).
//  NE YAPAR: stil.css (koyu) + stil-acik.css (açık) :root jetonlarını referans alır; üretici betiklerde
//  (motor/, arac/) ve kök HTML'de :root{...} bloklarında AYNI ADLI jetona FARKLI değer verenleri listeler.
//  SINIF: OKUNURLUK jetonu (yazı/zemin/çizgi) -> ayrışma okunmayan metin üretebilir; diğerleri (amber vb.) BİLGİ.
//  UYARI (haftalık robot, .github/workflows/root-jeton-tarama.yml): yalnız GEÇEN RAPORDA OLMAYAN yeni okunurluk
//  ayrışması SARI yakar. Var olan borç (23.09 ilk rapor: 22 dosya, 32 okunurluk + 26 bilgi) her hafta sarı yakmaz (sürekli sarı uyarı kimseye bir şey söylemez).
//  Robot HİÇ KIRMIZI DÜŞMEZ - kapı değil uyarı; okunmayan metni kontrast kapısı ölçer.
//  GÖRMEZ: :root dışındaki yerel tanımları (body.x{--dim:...}), arsiv/ altını, JS ile çalışma anında basılan renkleri.
//  Farklı değer her zaman kusur değildir (sayfaya özgü palet); kusur olup olmadığını kontrast kapısı söyler.
//  Kullanım: node arac/root-jeton-tarama.js            (ekrana liste)
//            node arac/root-jeton-tarama.js --rapor    (veri/root-jeton-raporu.json; yalnız değiştiyse yazar)
//            node arac/root-jeton-tarama.js --sinav    (öz-sınav)
// ============================================================================
const fs = require('fs'), path = require('path');
const OKUNURLUK = ['--ink', '--muted', '--dim', '--bg', '--bg2', '--panel', '--panel2', '--line', '--line2', '--taban', '--yuzey', '--kagit'];

function jetonlar(css) {
  const o = {}; const re = /:root\s*\{([^}]*)\}/g; let m;
  while ((m = re.exec(css))) for (const p of m[1].split(';')) { const q = p.match(/^\s*(--[\w-]+)\s*:\s*(.+?)\s*$/); if (q && !(q[1] in o)) o[q[1]] = q[2].replace(/\/\*.*?\*\//g, '').trim(); }
  return o;
}
const norm = v => String(v).toLowerCase().replace(/\s+/g, '');
const turu = f => /^(motor|arac)\//.test(f) ? 'uretici' : 'sayfa';

// dosyalar: [{ad, metin}] ; ortak: {koyu, acik}
function tara(dosyalar, ortak) {
  const kayit = [];
  for (const d of dosyalar) {
    if (!/:root\s*\{/.test(d.metin)) continue;
    for (const [k, v] of Object.entries(jetonlar(d.metin))) {
      if (!(k in ortak.koyu) || norm(v) === norm(ortak.koyu[k])) continue;
      kayit.push({ dosya: d.ad, tur: turu(d.ad), jeton: k, deger: v, ortak: ortak.koyu[k], sinif: OKUNURLUK.includes(k) ? 'okunurluk' : 'bilgi' });
    }
  }
  return kayit.sort((a, b) => a.dosya.localeCompare(b.dosya) || a.jeton.localeCompare(b.jeton));
}
// geçen rapora göre YENİ okunurluk ayrışmaları (aynı dosya+jeton+değer önceden varsa yeni değil)
function yeniler(onceki, simdi) {
  const eski = new Set((onceki || []).map(r => r.dosya + '|' + r.jeton + '|' + norm(r.deger)));
  return simdi.filter(r => r.sinif === 'okunurluk' && !eski.has(r.dosya + '|' + r.jeton + '|' + norm(r.deger)));
}

if (process.argv.includes('--sinav')) {
  let h = 0; const t = (ad, k) => { console.log((k ? '  geçti: ' : '  DÜŞTÜ: ') + ad); if (!k) h++; };
  const ortak = { koyu: jetonlar(':root{--dim:#8f9dae;--amber:#ffc24b;--ink:#eef2f7}'), acik: {} };
  const d = [
    { ad: 'a.html', metin: '<style>:root{--dim:#5d6b7c;--amber:#f5a524;--yerel:#123}</style>' },
    { ad: 'motor/u.ps1', metin: "AppendLine(':root{--ink:#eef2f7;--dim:#8F9DAE}')" },
    { ad: 'b.html', metin: '<p>root yok</p>' }];
  const k = tara(d, ortak);
  t('eski --dim okunurluk ayrışması bulunur', k.some(r => r.dosya === 'a.html' && r.jeton === '--dim' && r.sinif === 'okunurluk'));
  t('--amber farkı BİLGİ sınıfında', k.some(r => r.jeton === '--amber' && r.sinif === 'bilgi'));
  t('ortakta olmayan yerel jeton sayılmaz', !k.some(r => r.jeton === '--yerel'));
  t('büyük/küçük harf farkı ayrışma değil (üretici aynı değer)', !k.some(r => r.dosya === 'motor/u.ps1'));
  t('yalnız :root taşıyan dosyalar taranır', !k.some(r => r.dosya === 'b.html'));
  t('geçen raporda olan ayrışma YENİ sayılmaz (borç her hafta sarı yakmaz)', yeniler(k, k).length === 0);
  t('yeni okunurluk ayrışması yakalanır, yeni bilgi ayrışması SARI yapmaz',
    (() => { const y = yeniler([], k); return y.length === 1 && y[0].jeton === '--dim'; })());
  t('aynı dosyada değer değişirse yeni sayılır', yeniler([{ dosya: 'a.html', jeton: '--dim', deger: '#7d848c' }], k).length === 1);
  console.log(h ? 'ROOT JETON TARAMASI ÖZ-SINAVI DÜŞTÜ' : 'ROOT JETON TARAMASI ÖZ-SINAVI: 8/8 GEÇTİ'); process.exit(h ? 1 : 0);
}

const kok = path.resolve(__dirname, '..');
const { execSync } = require('child_process');
const ortak = { koyu: jetonlar(fs.readFileSync(path.join(kok, 'stil.css'), 'utf8')), acik: jetonlar(fs.readFileSync(path.join(kok, 'stil-acik.css'), 'utf8')) };
const adlar = execSync('git ls-files "motor/*.ps1" "motor/*.js" "arac/*.ps1" "arac/*.js" "*.html"', { cwd: kok, encoding: 'utf8' })
  .split('\n').filter(f => f && (/^(motor|arac)\/[^/]+$/.test(f) || !f.includes('/')));
const kayit = tara(adlar.map(ad => ({ ad, metin: fs.readFileSync(path.join(kok, ad), 'utf8') })), ortak);
const dosyaSay = new Set(kayit.map(r => r.dosya)).size;

if (!process.argv.includes('--rapor')) {
  let son = '';
  for (const r of kayit) { if (r.dosya !== son) { console.log(`${r.tur === 'uretici' ? 'ÜRETİCİ' : 'SAYFA'} ${r.dosya}`); son = r.dosya; } console.log(`    ${r.sinif === 'okunurluk' ? '!' : ' '} ${r.jeton}: ${r.deger} (stil.css ${r.ortak})`); }
  console.log(`\nTOPLAM: ${dosyaSay} dosya · okunurluk ${kayit.filter(r => r.sinif === 'okunurluk').length} · bilgi ${kayit.filter(r => r.sinif === 'bilgi').length}`);
  process.exit(0);
}
const hedef = path.join(kok, 'veri', 'root-jeton-raporu.json');
let onceki = null; try { onceki = JSON.parse(fs.readFileSync(hedef, 'utf8').replace(/^﻿/, '')); } catch (e) {}
// ilk koşu (geçmiş rapor yok) TEMEL ÇİZGİDİR: mevcut borç "yeni" sayılmaz, uyarı basılmaz
const yeni = onceki ? yeniler(onceki.kayitlar, kayit) : [];
const rapor = {
  uretici: 'arac/root-jeton-tarama.js', olcum: new Date().toISOString(),
  durum: yeni.length ? 'SARI' : 'YESIL',
  taranan_dosya: adlar.length, ayrisan_dosya: dosyaSay,
  okunurluk: kayit.filter(r => r.sinif === 'okunurluk').length, bilgi: kayit.filter(r => r.sinif === 'bilgi').length,
  yeni_okunurluk: yeni, gormez: ':root disindaki yerel tanimlar · arsiv/ · calisma aninda basilan renkler',
  kayitlar: kayit
};
// içerik aynıysa dosyaya dokunulmaz (boş commit yok) - AMA son ölçüm 6 günden eskiyse damga tazelenir:
// veri/_sozlesme.json azami_yas_saat 192; haftalık robot çalışırken tazelik kapısı yanlış alarm vermesin.
const eskiGun = onceki && onceki.olcum ? (Date.now() - Date.parse(onceki.olcum)) / 86400000 : 99;
const ayni = onceki && eskiGun < 6 && JSON.stringify({ ...onceki, olcum: 0 }) === JSON.stringify({ ...rapor, olcum: 0 });
if (ayni) console.log('root-jeton: degisiklik yok, dosyaya dokunulmadi');
else { fs.writeFileSync(hedef, JSON.stringify(rapor, null, 2) + '\n', 'utf8'); console.log('root-jeton: yazildi -> veri/root-jeton-raporu.json'); }
console.log(`ROOT JETON: ${rapor.durum} · ${dosyaSay}/${adlar.length} dosya ayrisiyor · okunurluk ${rapor.okunurluk} · bilgi ${rapor.bilgi} · YENI okunurluk ${yeni.length}`);
for (const r of yeni) console.log(`::warning file=${r.dosya}::YENI okunurluk ayrismasi ${r.jeton}: ${r.deger} (stil.css ${r.ortak}) - ortak stildeki duzeltme bu dosyaya ulasmaz`);
