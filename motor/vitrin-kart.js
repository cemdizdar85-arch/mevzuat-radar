// GÜNÜN VİTRİN SORUSU (09.09.2026, Cem "2 yap") — ana sayfadaki gösterimlik kartın verisi.
// Kaynak: kaydir/vitrin/<sinav>.html (motor/vitrin-bas.ps1 ile basılan, ölçütle seçilmiş havuz; 13.09'dan beri 70 soru).
// Her sınav için o günün sorusu = yılın günü mod soru sayısı (TR günü); sayfa sırasıyla aynı
// (kart bağlantısı #s=<sıra> ile Nöbetçi'de o soruyu açar). Sınav sekmesi yalnız vitrin dosyası
// olan sınav için üretilir → smmm/kgk basılınca sekme kendiliğinden gelir.
// Çıktı: veri/vitrin-kart-ozet.json (robot dosyası, elle düzenlenmez; *-ozet.json merge sürücüsü).
// Zaman damgası dışında içerik aynıysa dosyaya DOKUNULMAZ (boş commit ve çakışma üretmesin).
// Kullanım: node motor/vitrin-kart.js   (Actions: vitrin-kart.yml her sabah; Cem yerelde de koşabilir)
const fs = require('fs'); const path = require('path'); const crypto = require('crypto');

// ---------------------------------------------------------------------------
// HAVUZ ÖMRÜ NÖBETİ (13.09.2026, Cem: "sınavdan sonrası için hatırlatıcı kur")
// Günün sorusu "yılın günü mod adet" ile seçilir: adet kadar gün boyunca her soru
// TAM BİR KEZ gelir, sonra aynı sorular geri döner. Havuzu yenileyen basım
// (motor/vitrin-bas.ps1) bulutta koşamaz (soru gövdeleri git dışı) - biri
// hatırlamazsa vitrin sessizce tekrara girer.
// Havuzun İMZASI (soru kimlikleri) veri/vitrin-havuz.json'da tutulur; havuz yeniden
// basılınca imza değişir ve sayaç KENDİLİĞİNDEN sıfırlanır (takvime tarih çakılmaz).
// Durum: YESIL (>7 gün) · SARI (1-7) · KIRMIZI (<=0, tekrar başladı).
// Mail günleri: kalan 7, 3, 1, 0 ve sonrasında haftada bir - her gün değil.
// ---------------------------------------------------------------------------
function gunSayisi(etiket) { const [y, m, d] = String(etiket).split('-').map(Number); return Math.floor(Date.UTC(y, m - 1, d) / 86400000); }
function gunEkle(etiket, n) { return new Date((gunSayisi(etiket) + n) * 86400000).toISOString().slice(0, 10); }
function havuzDurumu(adet, ilkGun, bugun) {
  const kalan = adet - (gunSayisi(bugun) - gunSayisi(ilkGun));
  const durum = kalan <= 0 ? 'KIRMIZI' : (kalan <= 7 ? 'SARI' : 'YESIL');
  const mailGunu = [7, 3, 1, 0].includes(kalan) || (kalan < 0 && (-kalan) % 7 === 0);
  return { adet, ilk_gun: ilkGun, bitis: gunEkle(ilkGun, adet), kalan_gun: kalan, durum, mail_gunu: mailGunu };
}
function jsonOku(yol) { return JSON.parse(fs.readFileSync(yol, 'utf8').replace(/^﻿/, '')); }

// ÖZ-SINAV (karar veren betiğe öz-sınav): node motor/vitrin-kart.js --sinav   (dosyaya YAZMAZ)
if (process.argv.includes('--sinav')) {
  const vakalar = [
    ['basım günü',          70, '2026-09-13', '2026-09-13', 70,  'YESIL',   false, '2026-11-22'],
    ['sınav günü',          70, '2026-09-13', '2026-11-21', 1,   'SARI',    true,  '2026-11-22'],
    ['7 gün kala',          70, '2026-09-13', '2026-11-15', 7,   'SARI',    true,  '2026-11-22'],
    ['6 gün kala (sessiz)', 70, '2026-09-13', '2026-11-16', 6,   'SARI',    false, '2026-11-22'],
    ['tekrar başladı',      70, '2026-09-13', '2026-11-22', 0,   'KIRMIZI', true,  '2026-11-22'],
    ['3 gün geçti (sessiz)',70, '2026-09-13', '2026-11-25', -3,  'KIRMIZI', false, '2026-11-22'],
    ['1 hafta geçti',       70, '2026-09-13', '2026-11-29', -7,  'KIRMIZI', true,  '2026-11-22'],
    ['yıl dönümü',          10, '2026-12-28', '2027-01-02', 5,   'SARI',    false, '2027-01-07']
  ];
  let kotu = 0;
  for (const [ad, adet, ilk, bugun, kalan, durum, mail, bitis] of vakalar) {
    const s = havuzDurumu(adet, ilk, bugun);
    if (s.kalan_gun !== kalan || s.durum !== durum || s.mail_gunu !== mail || s.bitis !== bitis) {
      console.log('  HATA ' + ad + ': ' + JSON.stringify(s)); kotu++;
    }
  }
  console.log(kotu ? '  HAVUZ ÖMRÜ ÖZ-SINAVI DÜŞTÜ' : '  HAVUZ ÖMRÜ ÖZ-SINAVI: ' + vakalar.length + '/' + vakalar.length + ' GEÇTİ');
  process.exit(kotu ? 2 : 0);
}
const kok = path.resolve(__dirname, '..');
const SINAVLAR = [['sgs', 'SMMM Staja Giriş (SGS)'], ['smmm', 'SMMM Yeterlilik'], ['kgk', 'KGK Bağımsız Denetçi'], ['spk', 'SPK Lisanslama']];
const hedef = path.join(kok, 'veri', 'vitrin-kart-ozet.json');
const havuzYol = path.join(kok, 'veri', 'vitrin-havuz.json');
let havuzKayit = {}; try { havuzKayit = jsonOku(havuzYol); } catch (e) { havuzKayit = {}; }
const havuzYeni = {};

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
  // havuz imzası: soru kimlikleri - havuz yeniden basılınca değişir, sayaç sıfırlanır
  const imza = crypto.createHash('sha1').update(liste.map(x => String(x.id)).join('|')).digest('hex').slice(0, 16);
  const onceki = havuzKayit[kod];
  const ilkGun = (onceki && onceki.imza === imza && onceki.adet === liste.length) ? onceki.ilk_gun : gunEtiket;
  havuzYeni[kod] = { imza, ilk_gun: ilkGun, adet: liste.length };
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
    baglanti: 'kaydir/vitrin/' + kod + '.html?vitrin=1&tema=acik#s=' + i,
    havuz: havuzDurumu(liste.length, ilkGun, gunEtiket)
  };
}

const yeni = { olcum: simdi.toISOString(), gun: gunEtiket, sinavlar };
let eski = null; try { eski = JSON.parse(fs.readFileSync(hedef, 'utf8')); } catch (e) {}
const ayni = eski && JSON.stringify({ ...eski, olcum: 0 }) === JSON.stringify({ ...yeni, olcum: 0 });
if (ayni) { console.log('vitrin-kart: değişiklik yok (' + gunEtiket + ', ' + Object.keys(sinavlar).join('+') + '), dosyaya dokunulmadı'); }
else { fs.writeFileSync(hedef, JSON.stringify(yeni, null, 2) + '\n', 'utf8'); console.log('vitrin-kart: yazıldı ' + gunEtiket + ' → ' + Object.entries(sinavlar).map(([k, v]) => k + ':' + v.sira + '/' + v.toplam + ' ' + v.ders).join(' · ')); }
// havuz kaydı yalnız değiştiyse yazılır (imza/ilk gün/adet) - her gün commit üretmesin
let havuzEski = null; try { havuzEski = jsonOku(havuzYol); } catch (e) {}
if (JSON.stringify(havuzEski) !== JSON.stringify(havuzYeni)) { fs.writeFileSync(havuzYol, JSON.stringify(havuzYeni, null, 2) + '\n', 'utf8'); console.log('vitrin-havuz: kayıt yazıldı (yeni havuz ya da ilk koşu)'); }
for (const [k, v] of Object.entries(sinavlar)) {
  const h = v.havuz;
  console.log('HAVUZ ' + k + ': ' + h.durum + ' · ' + h.adet + ' soru · ilk gün ' + h.ilk_gun + ' · tekrar başlangıcı ' + h.bitis + ' · kalan ' + h.kalan_gun + ' gün' + (h.mail_gunu ? ' · MAİL GÜNÜ' : ''));
}
if (!Object.keys(sinavlar).length) { console.error('hiçbir sınavın vitrin dosyası yok'); process.exit(2); }
