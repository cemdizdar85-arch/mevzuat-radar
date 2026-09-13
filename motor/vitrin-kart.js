// GÜNÜN VİTRİN SORUSU (09.09.2026, Cem "2 yap") — ana sayfadaki gösterimlik kartın verisi.
// Kaynak: kaydir/vitrin/<sinav>.html (motor/vitrin-bas.ps1 ile basılan, ölçütle seçilmiş havuz; 13.09'dan beri 70 soru).
// Her sınav için o günün sorusu = yılın günü mod soru sayısı (TR günü); sayfa sırasıyla aynı
// (kart bağlantısı #s=<sıra> ile Nöbetçi'de o soruyu açar). Sınav sekmesi yalnız vitrin dosyası
// olan sınav için üretilir → smmm/kgk basılınca sekme kendiliğinden gelir.
// Çıktı: veri/vitrin-kart-ozet.json (robot dosyası, elle düzenlenmez; *-ozet.json merge sürücüsü).
// Zaman damgası dışında içerik aynıysa dosyaya DOKUNULMAZ (boş commit ve çakışma üretmesin).
// Kullanım: node motor/vitrin-kart.js   (Actions: vitrin-kart.yml her sabah; Cem yerelde de koşabilir)
const fs = require('fs'); const path = require('path');
const kok = path.resolve(__dirname, '..');
const SINAVLAR = [['sgs', 'SMMM Staja Giriş (SGS)'], ['smmm', 'SMMM Yeterlilik'], ['kgk', 'KGK Bağımsız Denetçi'], ['spk', 'SPK Lisanslama']];
const hedef = path.join(kok, 'veri', 'vitrin-kart-ozet.json');

const simdi = new Date();
const tr = new Date(simdi.toLocaleString('en-US', { timeZone: 'Europe/Istanbul' }));
const yilBasi = new Date(tr.getFullYear(), 0, 1);
const gunNo = Math.floor((tr - yilBasi) / 86400000);
const gunEtiket = tr.getFullYear() + '-' + String(tr.getMonth() + 1).padStart(2, '0') + '-' + String(tr.getDate()).padStart(2, '0');

function kisalt(s, n) { s = String(s || '').replace(/\s+/g, ' ').trim(); return s.length > n ? s.slice(0, n - 1) + '…' : s; }

const sinavlar = {};
for (const [kod, ad] of SINAVLAR) {
  const dosya = path.join(kok, 'kaydir', 'vitrin', kod + '.html');
  if (!fs.existsSync(dosya)) continue;
  const h = fs.readFileSync(dosya, 'utf8');
  const m = h.match(/const SORULAR=(\[\{[\s\S]*?\}\]);\r?\n/);
  if (!m) { console.warn(kod + ': SORULAR bulunamadı'); continue; }
  let liste; try { liste = JSON.parse(m[1]); } catch (e) { console.warn(kod + ': JSON okunamadı'); continue; }
  if (!liste.length) continue;
  const i = gunNo % liste.length; const s = liste[i];
  const siklar = {}; for (const k of ['A', 'B', 'C', 'D', 'E']) if (s.siklar && s.siklar[k] != null) siklar[k] = String(s.siklar[k]);
  const tuzak = {}; for (const k of Object.keys(s.tuzak || {})) tuzak[k] = { ad: String(s.tuzak[k].ad || '').replace(/\s*\[.*?\]\s*/g, '').trim(), metin: kisalt(s.tuzak[k].metin, 220) };
  // çözüm tablosu: HESAP + SONUÇ satırları (VERİLENLER bloğu soruda zaten var), en çok 5 satır
  let satirlar = [];
  if (s.tablo && Array.isArray(s.tablo.satirlar)) {
    let blok = ''; for (const r of s.tablo.satirlar) { const ad = String(r[0] || ''); if (/^(VERİLENLER|HESAP|SONUÇ)$/i.test(ad)) { blok = ad.toUpperCase(); continue; } if (blok === 'VERİLENLER') continue; satirlar.push([ad, String(r[1] || '')]); }
    if (satirlar.length > 5) satirlar = satirlar.slice(-5);
  }
  const rakamSik = Object.values(siklar).every(v => /^[\d.,%\s€$TL-]+$/.test(v));
  sinavlar[kod] = {
    ad, sira: i, toplam: liste.length, id: s.id, ders: s.ders, konu: s.konu,
    kunye: (s.capa && s.capa.kaynak) ? s.capa.kaynak + ' kalıbı' : (s.ders + ' · yeni soru'),
    // ⛔ 13.09: yorum "rozetle aynı" diyordu ama DEĞİLDİ. Karttaki rozet kaydir-coz.ps1'de
    // max(s.donem, cikmis.donemler.length); gece yayınlanan havuzda cikmis.donemler boş, s.donem dolu.
    // Eski hâl yeni sorularda afişe "0 dönem" yazdırıyordu. Artık rozetle birebir aynı ölçü.
    // (pencereDonemler PENCERE genişliğidir, her soruda 7 - kullanılmaz.)
    donem: Math.max(parseInt(s.donem, 10) || 0, (s.cikmis && Array.isArray(s.cikmis.donemler)) ? s.cikmis.donemler.length : 0),
    teori: !!s.teori, rakamSik,
    soru: String(s.soru || ''), siklar, dogru: String(s.dogru || ''), tuzak,
    hap: kisalt(s.hap || s.kural || '', 240), satirlar,
    baglanti: 'kaydir/vitrin/' + kod + '.html?vitrin=1&tema=acik#s=' + i
  };
}

const yeni = { olcum: simdi.toISOString(), gun: gunEtiket, sinavlar };
let eski = null; try { eski = JSON.parse(fs.readFileSync(hedef, 'utf8')); } catch (e) {}
const ayni = eski && JSON.stringify({ ...eski, olcum: 0 }) === JSON.stringify({ ...yeni, olcum: 0 });
if (ayni) { console.log('vitrin-kart: değişiklik yok (' + gunEtiket + ', ' + Object.keys(sinavlar).join('+') + '), dosyaya dokunulmadı'); }
else { fs.writeFileSync(hedef, JSON.stringify(yeni, null, 2) + '\n', 'utf8'); console.log('vitrin-kart: yazıldı ' + gunEtiket + ' → ' + Object.entries(sinavlar).map(([k, v]) => k + ':' + v.sira + '/' + v.toplam + ' ' + v.ders).join(' · ')); }
if (!Object.keys(sinavlar).length) { console.error('hiçbir sınavın vitrin dosyası yok'); process.exit(2); }
