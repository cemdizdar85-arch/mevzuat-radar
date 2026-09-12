#!/usr/bin/env node
/* ============================================================================
   TAZELİK KAPISI — "tazelik iddiası kuran sayfa, kanıtını tazeliyor mu?"
   12.09.2026, Cem "1.2.3 üçünü de yap"

   NİYE VAR: 12.09'da ana sayfanın Nöbetçi kutusu "son robot koşusu 07.09 —
   5 gün önce" yazıp kırmızı yandı. Robot hiç gün atlamamıştı (damga izi
   ölçüldü, boşluk yok); sayfa veriyi açılışta BİR KEZ çekip bayatlık hükmünü
   O ANKI SAATLE kuruyordu. Aynı desen pano.html ve durum.html'de de vardı.

   Üçü de düzeltildi. Bu kapı DÖRDÜNCÜSÜNÜ önlüyor: kural yorumda kalırsa
   unutulur - bugün tam bu yüzden unutulmuştu. (Aynı ders: CLAUDE.md'deki
   "bilinen tuzağı tekrar yazmak" satırı; yorum kimseyi durdurmadı, kapı
   durdurdu.)

   HÜKÜM KURALI — bir HTML sayfası
     (a) bir JSON/veri ucundan fetch ediyorsa VE
     (b) ekrana tazelik iddiası yazıyorsa ("gün önce", "ölçüm:", "son koşu",
         "Okundu:", "bugün/dün" gibi) VE
     (c) tazelik.js'i bağlayıp Tazelik.kur çağırmıyorsa
   → KIRMIZI.

   TABAN (borç) DEFTERI: veri/tazelik-borcu.json → { "dosya.html": "gerekçe" }.
   Kapı kurulduğu gün kırmızı olan sayfalar buraya yazıldı ve SARI sayılıyor -
   hepsini aynı gün düzeltmek kapıyı ilk gün kapatırdı (tuzak-nöbetçisinin
   210 eski bulgusunda alınan dersin aynısı). Ama bu defter BORÇTUR, muafiyet
   değil: her satırı kapanacak bir iş emridir. Deftere YENİ satır eklemek
   ancak yazılı gerekçeyle olur. Defterde OLMAYAN yeni bir ihlal KIRMIZIDIR.

   Kullanım:  node arac/tazelik-kapisi.js
   Çıkış:     0 temiz · 1 kırmızı
   Bedel:     0 (yalnız dosya okur, ağ yok, model yok)
   ============================================================================ */
'use strict';
const fs = require('fs');
const path = require('path');

const KOK = path.resolve(__dirname, '..');

/* Üretilmiş/türev/git-dışı sayfalar taranmaz — ölçüldü (12.09): ilk koşuda
   31 kırmızının 17'si sql-yerel/'di, yani .gitignore'daki YEREL çıktılar.
   Yayına çıkmayan dosyaya kapı kurmak yalan alarmdır.
     kaydir/    : Kaydır-Çöz basımı (motor üretir, elle yazılmaz)
     sql-yerel/ : .gitignore - paralı soru içeren yerel SQL/HTML çıktıları
     arsiv/     : donmuş eski sayfalar, tazeleme iddiası taşımazlar
     tasarim/   : deneme taslakları */
const ATLA_KLASOR = ['kaydir', 'sql-yerel', 'arsiv', 'tasarim', '_temizlik',
                     'node_modules', '_kaynak', '.git'];

/* ============================ İMZALAR ======================================
   Üç tur ölçümle daraltıldı (12.09). Yanlış alarm kapının kendisini öldürür:
   bugün 16 kapının kırmızı olmasına rağmen kimsenin bakmamasının sebebi tam
   bu. O yüzden her daraltma ÖLÇÜLDÜ.

   1. TUR — ham metinde tazelik sözcükleri: 31 kırmızı. 17'si sql-yerel/
      (git dışı), 3'ü yalnız YORUMDA geçiyordu. → klasör + yorum filtresi.
   2. TUR — Date.now()/getTime() aranması: 33 aday. `Date.now()` önbellek
      kırıcıda, zamanlayıcıda, kimlik üretiminde de kullanılıyor; arızayla
      ilgisi yok. → ELENDİ, sinyal değil.
   3. TUR — iddia YALNIZ <script> gövdesinde aranır: 12 aday. Kalan 4 yalan
      alarmın ortak yanı: hepsi DÜZ METİN SABİTİ ("30 gün önceden yazılı
      bildir" = hukuki tavsiye, "3 gün önce hatırlatırız" = ürün vaadi).
      Burası bir MEVZUAT sitesi; "30 gün önce" içeriğin kendisidir.
   4. TUR (bu hâli) — iddia, VERİDEN gelen bir değerle kurulmuş olmalı:
        SINIF-A  metin bir değişkenle birleştiriliyor ('... '+gunEski+' gündür')
        SINIF-B  bayatlık bir DEĞİŞKEN/İŞLEV adı taşıyor (AI_BAYAT, aiBayatlik)
      Düz metin sabiti ikisine de girmez. Ölçüm: 12 aday → 8 gerçek.
   ========================================================================== */

/* (b) TAZELİK İDDİASI SÖZCÜKLERİ */
const IDDIA = [
  /gün önce/i, /gündür/i, /son ölçüm/i, /son koşu/i, /son çekim/i,
  /Okundu[ \t]*:/i, /nöbet tutuldu/i, /tazelenm/i, /güncellenm/i
];

/* SINIF-A: satırda hem iddia sözcüğü hem de birleştirme (+) var →
   metin VERİDEN gelen bir değerle kuruluyor. */
const BIRLESTIRME = /\+/;

/* SINIF-B: bayatlık hükmü bir değişken/işlev adında yaşıyor.
   Tırnak içindeki "bayat" sözcüğü (düz metin) buraya girmez. */
const BAYAT_KOD = /[A-Za-z_$][A-Za-z0-9_$]*bayat[A-Za-z0-9_$]*\s*[=(),;.]|(?:var|let|const|function)\s+bayat/i;

/* (a) VERİ ÇEKME İMZASI */
const CEKIM = /fetch\s*\(/;

/* YALNIZ satır içi <script> gövdeleri okunur (src'li etiketler hariç):
   statik HTML gövdesindeki hukuki metin iddia değil İÇERİKTİR. */
function betikGovdesi(m){
  const c = [];
  const r = /<script\b(?![^>]*\bsrc\s*=)[^>]*>([\s\S]*?)<\/script>/gi;
  let k;
  while((k = r.exec(m)) !== null) c.push(k[1]);
  return c.join('\n');
}

/* (c) MOTORA BAĞLANMA İMZALARI — ikisi birlikte aranır: betik etiketi olmadan
   Tazelik tanımsızdır, çağrı olmadan etiket işe yaramaz. */
const BAGLI_ETIKET = /<script[^>]+src\s*=\s*["'][^"']*tazelik\.js["']/i;
const BAGLI_CAGRI  = /Tazelik\s*\.\s*kur\s*\(/;

function htmlBul(dizin, biriktir){
  for(const ad of fs.readdirSync(dizin, {withFileTypes:true})){
    if(ad.name.startsWith('.') && ad.name !== '.github') continue;
    const tam = path.join(dizin, ad.name);
    if(ad.isDirectory()){
      if(ATLA_KLASOR.includes(ad.name)) continue;
      htmlBul(tam, biriktir);
    } else if(ad.name.endsWith('.html')){
      biriktir.push(tam);
    }
  }
  return biriktir;
}

/* YORUMLAR SÖKÜLÜR. Ölçüldü (12.09): ilk koşuda bilgi.html, songun.html ve
   senaryo-raporu.html yalnız YORUM metnindeki "tazelenir"/"bayat" sözcükleri
   yüzünden kırmızı düştü - ekrana hiçbir tazelik iddiası yazmıyorlardı.
   Yanlış alarm, kapının kendisini öldürür (bugün 16 kapının kırmızı olduğu
   hâlde kimsenin bakmamasının sebebi tam bu). */
function yorumSok(m){
  return m.replace(/<!--[\s\S]*?-->/g, ' ')      /* HTML yorumu */
          .replace(/\/\*[\s\S]*?\*\//g, ' ');    /* JS blok yorumu */
}

/* Borç defteri: { sayfalar: [ {dosya, iddia, oncelik, not} ] }
   Gerekçesiz satır KABUL EDİLMEZ - `iddia` alanı boşsa satır yok sayılır ve
   sayfa yine KIRMIZI düşer. Defterin işi borcu kaydetmek, gizlemek değil. */
function borcOku(){
  const y = path.join(KOK, 'veri', 'tazelik-borcu.json');
  if(!fs.existsSync(y)) return {};
  try {
    const j = JSON.parse(fs.readFileSync(y, 'utf8'));
    const t = {};
    for(const s of (j.sayfalar || [])){
      if(!s || !s.dosya || !s.iddia) continue;   /* gerekçesiz satır geçersiz */
      t[s.dosya] = 'öncelik ' + (s.oncelik || '?') + ' · ' + s.iddia;
    }
    return t;
  }
  catch(h){ console.log('  ⚠ borç defteri okunamadı: ' + h.message); return {}; }
}

const borc = borcOku();
const sayfalar = htmlBul(KOK, []).sort();

const kirmizi = [];
const sari    = [];
const gecen   = [];
const ilgisiz = [];

for(const tam of sayfalar){
  const gorece = path.relative(KOK, tam).replace(/\\/g, '/');
  const ham = fs.readFileSync(tam, 'utf8');
  const js  = yorumSok(betikGovdesi(ham));

  if(!CEKIM.test(js)){ ilgisiz.push(gorece); continue; }

  /* SINIF-A · SINIF-B: iddia VERİDEN gelen bir değerle kurulmuş olmalı */
  const bulgu = [];
  for(const satir of js.split('\n')){
    const d = IDDIA.find(function(r){ return r.test(satir); });
    if(d && BIRLESTIRME.test(satir)) bulgu.push('A:' + String(d).replace(/^\/|\/i?$/g, ''));
    if(BAYAT_KOD.test(satir))        bulgu.push('B:bayatlık değişkeni');
  }
  if(bulgu.length === 0){ ilgisiz.push(gorece); continue; }

  /* buraya gelen sayfa: veri çekiyor VE veriden tazelik hükmü kuruyor.
     Betik etiketi HAM metinde aranır - o bir yorum değildir. */
  const etiket = BAGLI_ETIKET.test(ham);
  const cagri  = BAGLI_CAGRI.test(js);

  if(etiket && cagri){ gecen.push(gorece); continue; }

  const imza = Array.from(new Set(bulgu)).join(' · ');
  const eksik = (!etiket ? 'tazelik.js bağlı değil' : '') +
                (!etiket && !cagri ? ' + ' : '') +
                (!cagri ? 'Tazelik.kur çağrılmıyor' : '');

  if(borc[gorece]){ sari.push({ dosya: gorece, iddia: imza, gerekce: borc[gorece] }); continue; }

  kirmizi.push({ dosya: gorece, iddia: imza, eksik: eksik });
}

console.log('TAZELİK KAPISI: ' + sayfalar.length + ' sayfa tarandı · iddia kuran ' +
            (gecen.length + sari.length + kirmizi.length) + ' · ilgisiz ' + ilgisiz.length);

if(gecen.length){
  console.log('');
  console.log('  YEŞİL — motora bağlı (' + gecen.length + '):');
  gecen.forEach(function(g){ console.log('    ✓ ' + g); });
}

if(sari.length){
  console.log('');
  console.log('  SARI — TAZELEME BEKLİYOR, borç defterinde (' + sari.length + '):');
  sari.forEach(function(s){ console.log('    · ' + s.dosya + '  —  ' + s.gerekce); });
  console.log('    (defter: veri/tazelik-borcu.json · her satır kapanacak iş emri)');
}

if(kirmizi.length === 0){
  console.log('');
  console.log(sari.length
    ? '  TEMİZ — yeni ihlal yok. Borç defterindeki ' + sari.length + ' sayfa hâlâ açık.'
    : '  TEMİZ — tazelik iddiası kuran her sayfa kanıtını tazeliyor.');
  process.exit(0);
}

console.log('');
console.log('  KIRMIZI — tazelik iddiası kuruyor ama kanıtını TAZELEMİYOR:');
kirmizi.forEach(function(k){
  console.log('    ' + k.dosya);
  console.log('        iddia imzası : ' + k.iddia);
  console.log('        eksik        : ' + k.eksik);
});
console.log('');
console.log('  NİYE ÖNEMLİ: veriyi bir kez çekip bayatlık hükmünü o anki saatle');
console.log('  kuran sayfa, tarayıcıda kalmış eski bir kopyayla ROBOTU SUÇLAR.');
console.log('  12.09.2026: ana sayfa "son koşu 07.09 — 5 gün önce" dedi, robot');
console.log('  hiç gün atlamamıştı. Üç tur bu yanlış teşhise gitti.');
console.log('');
console.log('  ÇÖZÜM: <head> içine  <script src="tazelik.js"></script>  (defer YOK)');
console.log('         çekimi        Tazelik.kur({ ad:"...", cek:function(){ ... } })');
console.log('         URL\'yi        Tazelik.url("veri/x.json")  ile sar');
console.log('  Bilinçli istisnaysa veri/tazelik-borcu.json\'a GEREKÇESİYLE ekle.');
process.exit(1);
