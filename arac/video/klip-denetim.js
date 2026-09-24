// klip-denetim.js — VIDEO BASIM SONRASI ZORUNLU DENETIM
// 24.09.2026 Cem: "basimdan sonra her cumleyi tek tek kontrol et ... bu cok onemli ve kural olsun video basiminda"
//
// OLAY (20.09 YKL klibi, 3,71 USD): Seedance referans sesi "tuttu" sanildi (yalniz sessizlik duzenine bakildi);
// gercekte (a) SON CUMLE DUSMUSTU, (b) bir cumle KEKELIYORDU (ayni kelime iki kez). Ikisini de sonradan
// Cem'in kulagi / tek tek dokum yakaladi.
//
// Ne yapar:
//   1) Klibin sesini 16 kHz'e indirir, konusma adalarini (silencedetect) bulur.
//   2) Whisper'i IKI kez kosar: tum ses + ada ada (>=2,5 sn pencereler). Ada dokumu tekrar/kekelemeyi, tam dokum
//      baglami yakalar.
//   3) Beklenen replikleri (sahne json "beklenen_replikler") kelime kelime hizalar (sayi kelimeleri <-> rakam esitlenir).
//   4) Karar:  KIRMIZI = dusen/eksik cumle · kelime tekrari (ada dokumunde) · 2+ fazladan kelime
//              SARI    = yakin esleme (kulakla bak) · tekrar yalniz tam dokumde · tek fazladan kelime
//              YESIL   = hepsi temiz
//   5) Dudak icin kare tabakasi basar: her konusma adasinin ORTASI (agiz acik olmali) + her sessizligin ORTASI
//      (agiz kapali olmali). Dudak senkronunu OTOMATIK OLCMEZ — tabaka gozle okunur. Rapor bunu soyler.
//
// Kullanim:  node klip-denetim.js <klip.mp4|ses> <sahne.json>          -> rapor + <klip>.denetim.json + .denetim.png
//            node klip-denetim.js --sinav                               -> oz-sinav (bilinen iki vaka)
// Cikis kodu: 0 YESIL · 1 SARI · 2 KIRMIZI · 3 calisma hatasi
const fs = require('fs'), path = require('path'), os = require('os'), { execFileSync } = require('child_process');
// Bu kapi sunlari GORMEZ: dudak senkronu (yalniz kare tabakasi, goz) · telaffuz inceligi (yalniz YAKIN ESLEME) ·
// yerel arac (whisper bu makinede) oldugu icin CI'da (dogrula.yml) KOSMAZ — oz-sinav elle: --sinav.
// MUTASYON (CLAUDE.md kapi kurali 8): KD_MUTASYON=dusen|tekrar|yapisik ilgili kontrolu kapatir; oz-sinav o zaman DUSMELI.
const MUT = process.env.KD_MUTASYON || '';
const WH = 'C:/Users/cemdi/.claude/araclar/whisper';
const WCLI = WH + '/Release/whisper-cli.exe', WMOD = WH + '/ggml-small.bin';

// ---------------- metin normallestirme ----------------
const katla = s => s.replace(/İ/g, 'i').replace(/I/g, 'ı').toLowerCase()
  .replace(/ı/g, 'i').replace(/ş/g, 's').replace(/ğ/g, 'g').replace(/ü/g, 'u').replace(/ö/g, 'o').replace(/ç/g, 'c').replace(/[âà]/g, 'a').replace(/[îì]/g, 'i').replace(/[ûù]/g, 'u');
const BIRLER = { sifir: 0, bir: 1, iki: 2, uc: 3, dort: 4, bes: 5, alti: 6, yedi: 7, sekiz: 8, dokuz: 9 };
const ONLAR = { on: 10, yirmi: 20, otuz: 30, kirk: 40, elli: 50, altmis: 60, yetmis: 70, seksen: 80, doksan: 90 };
const CARPAN = { yuz: 100, bin: 1000, milyon: 1e6 };
const sayiSozcugu = w => (w in BIRLER) || (w in ONLAR) || (w in CARPAN);
function sozcuklere(metin) {
  let t = katla(metin).replace(/%\s*(\d)/g, 'yuzde $1').replace(/(\d)\.(\d{3})/g, '$1$2').replace(/(\d)\.(\d{3})/g, '$1$2');
  t = t.replace(/['’][a-z]+/g, '');                        // eylul'de -> eylul, 11'inde -> 11
  return t.split(/[^a-z0-9]+/).filter(Boolean);
}
// sayi kelime dizilerini tek sayi belirtecine cevirir; rakam + "bin" -> carpim
function sayilastir(ts) {
  const cikti = []; let i = 0;
  while (i < ts.length) {
    const w = ts[i];
    if (/^\d+$/.test(w)) {
      let v = parseInt(w, 10); i++;
      while (i < ts.length && (ts[i] in CARPAN) && ts[i] !== 'yuz') { v *= CARPAN[ts[i]]; i++; }
      cikti.push('#' + v); continue;
    }
    if (sayiSozcugu(w)) {
      let top = 0, cur = 0, j = i;
      while (j < ts.length) {
        let s = ts[j];
        if (!sayiSozcugu(s)) {                       // son sayi kelimesine ek gelmis olabilir: "besi", "yirmide"
          const kok = Object.keys({ ...BIRLER, ...ONLAR, ...CARPAN }).find(k => s.startsWith(k) && s.length - k.length <= 4 && s.length - k.length > 0);
          if (kok && j > i) { s = kok; } else break;
          const v = BIRLER[s] ?? ONLAR[s]; if (v !== undefined) cur += v; else if (s === 'yuz') cur = (cur || 1) * 100; else { top += (cur || 1) * CARPAN[s]; cur = 0; }
          j++; break;
        }
        const v = BIRLER[s] ?? ONLAR[s];
        if (v !== undefined) cur += v; else if (s === 'yuz') cur = (cur || 1) * 100; else { top += (cur || 1) * CARPAN[s]; cur = 0; }
        j++;
      }
      cikti.push('#' + (top + cur)); i = j; continue;
    }
    cikti.push(w); i++;
  }
  return cikti;
}
const belirtec = metin => sayilastir(sozcuklere(metin));
// Whisper bazen iki kelimeyi YAPISTIRIR (ornek: "ab cd" -> "abcd").
// 24.09 bitmis filmde bu, iki cumleyi "duyulmadi" gosterip YANLIS KIRMIZI uretti. Beklenen metinde art arda gelen
// iki belirtecin birlesimine (>=0.8 benzer) uyan dokum belirteci ikiye ayrilir. Yalniz BEKLENEN ciftlerle ayrilir,
// yani bilinmeyen bir kelimeyi "duyulmus" sayamaz.
function yapisigiAyir(dok, bek) {
  const ciftler = []; for (let k = 0; k + 1 < bek.length; k++) if (bek[k].t[0] !== '#' && bek[k + 1].t[0] !== '#') ciftler.push([bek[k].t, bek[k + 1].t]);
  const kelimeler = new Set(bek.map(b => b.t)); const cikti = [];
  for (let k = 0; k < dok.length; k++) {
    const w = dok[k];
    if (w[0] === '#' || kelimeler.has(w)) { cikti.push(w); continue; }
    let en = null, enB = 0;
    for (const [a, b] of ciftler) { const s = benzer(w, a + b); if (s > enB) { enB = s; en = [a, b]; } }
    // 24.09 YANLIS KIRMIZI (Bolum 1 filmi): beklenen "Maliyet'in ilk" -> ek atilir "maliyet ilk"; whisper "maliyetin ilk" yazar.
    // "maliyetin" ~ "maliyet"+"ilk" (0,80) diye bolunuyor, hemen arkadaki gercek "ilk" ile IKI "ilk" olusup TEKRAR sayiliyordu.
    // Arkadaki dokum kelimesi zaten ciftin ikinci kelimesiyse bolunmez (ikinci kelime yapisik degil, kendi basina duyulmus).
    const arkadaVar = MUT !== 'cift' && en && k + 1 < dok.length && benzer(dok[k + 1], en[1]) >= 0.8;
    if (en && enB >= 0.8 && !arkadaVar) cikti.push(en[0], en[1]); else cikti.push(w);
  }
  return cikti;
}
function lev(a, b) { const m = a.length, n = b.length; if (!m) return n; if (!n) return m; let p = Array.from({ length: n + 1 }, (_, j) => j);
  for (let i = 1; i <= m; i++) { const c = [i]; for (let j = 1; j <= n; j++) c[j] = Math.min(p[j] + 1, c[j - 1] + 1, p[j - 1] + (a[i - 1] === b[j - 1] ? 0 : 1)); p = c; } return p[n]; }
const benzer = (a, b) => { if (a === b) return 1; if (a[0] === '#' || b[0] === '#') return 0; return 1 - lev(a, b) / Math.max(a.length, b.length); };

// ---------------- hizalama (Needleman-Wunsch) ----------------
function hizala(bek, dok) {
  const m = bek.length, n = dok.length, S = [], Y = [];
  for (let i = 0; i <= m; i++) { S.push(new Array(n + 1).fill(0)); Y.push(new Array(n + 1).fill(0)); }
  for (let i = 1; i <= m; i++) { S[i][0] = -i; Y[i][0] = 1; }
  for (let j = 1; j <= n; j++) { S[0][j] = -j; Y[0][j] = 2; }
  for (let i = 1; i <= m; i++) for (let j = 1; j <= n; j++) {
    const b = benzer(bek[i - 1].t, dok[j - 1]); const es = b === 1 ? 3 : b >= 0.75 ? 2 : -1;
    const d = S[i - 1][j - 1] + es, u = S[i - 1][j] - 1, l = S[i][j - 1] - 1;
    if (d >= u && d >= l) { S[i][j] = d; Y[i][j] = 0; } else if (u >= l) { S[i][j] = u; Y[i][j] = 1; } else { S[i][j] = l; Y[i][j] = 2; }
  }
  const eslesme = []; let i = m, j = n;
  while (i > 0 || j > 0) {
    if (i > 0 && j > 0 && Y[i][j] === 0) { const b = benzer(bek[i - 1].t, dok[j - 1]); eslesme.unshift({ bi: i - 1, dj: j - 1, b: b >= 0.75 ? b : 0 }); i--; j--; }
    else if (i > 0 && (j === 0 || Y[i][j] === 1)) { eslesme.unshift({ bi: i - 1, dj: -1, b: 0 }); i--; }
    else { eslesme.unshift({ bi: -1, dj: j - 1, b: 0 }); j--; }
  }
  return eslesme;
}

// ---------------- ses / whisper ----------------
const ff = a => execFileSync('ffmpeg', ['-nostdin', '-y', '-v', 'error', ...a], { stdio: ['ignore', 'pipe', 'pipe'] });
function sure(f) { return parseFloat(execFileSync('ffprobe', ['-v', 'error', '-show_entries', 'format=duration', '-of', 'csv=p=0', f]).toString()); }
function sessizlikler(wav) {
  const r = require('child_process').spawnSync('ffmpeg', ['-nostdin', '-i', wav, '-af', 'silencedetect=noise=-38dB:d=0.22', '-f', 'null', '-'], { encoding: 'utf8' });
  const t = r.stderr || ''; const s = [...t.matchAll(/silence_start: ([0-9.]+)/g)].map(m => +m[1]); const e = [...t.matchAll(/silence_end: ([0-9.]+)/g)].map(m => +m[1]);
  return s.map((a, k) => [a, e[k] ?? a]);
}
function whisper(wav) {
  const r = require('child_process').spawnSync(WCLI, ['-m', WMOD, '-f', wav, '-l', 'tr', '-nt'], { encoding: 'utf8', input: '' });
  return (r.stdout || '').replace(/\s+/g, ' ').trim();
}

// ---------------- ana denetim ----------------
function denetle(girdi, beklenen, secenek = {}) {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'kd-'));
  const w16 = path.join(tmp, 's.wav');
  ff(['-i', girdi, '-vn', '-ar', '16000', '-ac', '1', '-c:a', 'pcm_s16le', w16]);
  const T = sure(w16), sess = sessizlikler(w16);
  // konusma adalari
  const ada = []; let bas = 0;
  for (const [a, b] of sess) { if (a - bas > 0.12) ada.push([bas, a]); bas = b; }
  if (T - bas > 0.12) ada.push([bas, T]);
  // >=2,5 sn pencereler
  const pen = []; let cur = null;
  for (const [a, b] of ada) { if (!cur) cur = [a, b]; else if (cur[1] - cur[0] < 2.5) cur[1] = b; else { pen.push(cur); cur = [a, b]; } }
  if (cur) { if (pen.length && cur[1] - cur[0] < 1.2) pen[pen.length - 1][1] = cur[1]; else pen.push(cur); }
  const dokumTam = whisper(w16);
  const parcalar = pen.map(([a, b], k) => { const f = path.join(tmp, 'p' + k + '.wav');
    ff(['-ss', Math.max(0, a - 0.15).toFixed(2), '-t', (b - a + 0.3).toFixed(2), '-i', w16, '-af', 'adelay=300:all=1,apad=pad_dur=0.8', f]); return whisper(f); });
  const dokumAda = parcalar.join(' ');

  const bek = []; beklenen.forEach((c, ci) => belirtec(c).forEach(t => bek.push({ t, ci })));
  const sonuc = { girdi: path.basename(girdi), sure_sn: +T.toFixed(2), ada_sayisi: ada.length, dokum_tam: dokumTam, dokum_ada: dokumAda, bulgular: [], cumleler: [] };
  const incele = (dokMetin, etiket) => {
    const dok = MUT === 'yapisik' ? belirtec(dokMetin) : yapisigiAyir(belirtec(dokMetin), bek), es = hizala(bek, dok);
    const kapsam = beklenen.map(() => ({ top: 0, tam: 0, yakin: [] }));
    for (const e of es) if (e.bi >= 0) { const k = kapsam[bek[e.bi].ci]; k.top++; if (e.dj >= 0 && e.b > 0) { k.tam++; if (e.b < 1) k.yakin.push(bek[e.bi].t + '~' + dok[e.dj]); } }
    // fazladan / tekrar
    const fazla = [];
    es.forEach((e, k) => { if (e.bi === -1) { const w = dok[e.dj];
      const onc = es.slice(0, k).reverse().find(x => x.dj >= 0), son = es.slice(k + 1).find(x => x.dj >= 0);
      const tekrar = (onc && benzer(dok[onc.dj], w) >= 0.8) || (son && benzer(dok[son.dj], w) >= 0.8);
      fazla.push({ w, tekrar, konum: e.dj }); } });
    return { kapsam, fazla };
  };
  const A = incele(dokumAda, 'ada'), F = incele(dokumTam, 'tam');
  beklenen.forEach((c, ci) => {
    const ka = A.kapsam[ci], kf = F.kapsam[ci];
    const oran = Math.max(ka.tam / ka.top, kf.tam / kf.top);
    const yakin = [...new Set([...ka.yakin, ...kf.yakin])];
    sonuc.cumleler.push({ n: ci + 1, beklenen: c, duyulma: +oran.toFixed(2), yakin });
    if (oran < 0.5 && MUT !== 'dusen') sonuc.bulgular.push({ sinif: 'KIRMIZI', tur: 'DUSEN/EKSIK CUMLE', ayrinti: (ci + 1) + '. cumle duyulmadi (' + Math.round(oran * 100) + '%): "' + c + '"' });
    else if (oran < 0.85) sonuc.bulgular.push({ sinif: 'SARI', tur: 'KISMEN DUYULDU', ayrinti: (ci + 1) + '. cumle %' + Math.round(oran * 100) + ': "' + c + '"' });
    if (yakin.length) sonuc.bulgular.push({ sinif: 'SARI', tur: 'YAKIN ESLEME (kulakla bak)', ayrinti: (ci + 1) + '. cumle: ' + yakin.join(', ') });
  });
  const tekrarAda = A.fazla.filter(f => f.tekrar), tekrarTam = F.fazla.filter(f => f.tekrar);
  if (tekrarAda.length && MUT !== 'tekrar') sonuc.bulgular.push({ sinif: 'KIRMIZI', tur: 'KELIME TEKRARI / KEKELEME', ayrinti: 'ada dokumunde: ' + tekrarAda.map(f => f.w).join(', ') });
  else if (tekrarTam.length) sonuc.bulgular.push({ sinif: 'SARI', tur: 'OLASI TEKRAR (yalniz tam dokumde)', ayrinti: tekrarTam.map(f => f.w).join(', ') });
  const fazlaAda = A.fazla.filter(f => !f.tekrar);
  let ard = 0, azami = 0, onceki = -9; for (const f of fazlaAda) { ard = (f.konum === onceki + 1) ? ard + 1 : 1; azami = Math.max(azami, ard); onceki = f.konum; }
  if (azami >= 2) sonuc.bulgular.push({ sinif: 'KIRMIZI', tur: 'FAZLADAN KONUSMA', ayrinti: 'ada dokumunde art arda ' + azami + ' beklenmeyen kelime: ' + fazlaAda.map(f => f.w).join(', ') });
  else if (fazlaAda.length) sonuc.bulgular.push({ sinif: 'SARI', tur: 'FAZLADAN KELIME', ayrinti: fazlaAda.map(f => f.w).join(', ') });

  // dudak tabakasi (video varsa)
  let video = false; try { video = execFileSync('ffprobe', ['-v', 'error', '-select_streams', 'v:0', '-show_entries', 'stream=codec_type', '-of', 'csv=p=0', girdi]).toString().includes('video'); } catch (e) {}
  if (video && !secenek.tabakasiz) {
    const anlar = [...ada.map(([a, b]) => ({ t: (a + b) / 2, beklenen: 'ACIK' })), ...sess.filter(([a, b]) => b - a >= 0.3 && b < T).map(([a, b]) => ({ t: (a + b) / 2, beklenen: 'KAPALI' }))].sort((x, y) => x.t - y.t).slice(0, 18);
    const kareler = anlar.map((a, k) => { const f = path.join(tmp, 'k' + String(k).padStart(2, '0') + '.png'); ff(['-ss', a.t.toFixed(2), '-i', girdi, '-frames:v', '1', '-vf', 'scale=240:-2,pad=iw:ih+6:0:0:' + (a.beklenen === 'ACIK' ? 'lime' : 'red'), f]); return f; });
    const cikti = girdi + '.denetim.png';
    const sutun = Math.min(6, kareler.length), satir = Math.ceil(kareler.length / sutun);
    ff(['-framerate', '1', '-i', path.join(tmp, 'k%02d.png'), '-vf', 'tile=' + sutun + 'x' + satir + ':padding=6:color=white', '-frames:v', '1', cikti]);
    sonuc.dudak_tabakasi = cikti; sonuc.dudak_anlari = anlar.map(a => ({ t: +a.t.toFixed(2), agiz: a.beklenen }));
  }
  sonuc.olcmedigi = ['Dudak senkronu OTOMATIK olculmez: tabakada YESIL cerceve = agiz ACIK olmali (konusuyor), KIRMIZI cerceve = agiz KAPALI olmali (sessizlik). Goz kontrolu sart.',
    'Telaffuz inceligi (tek harf farki) yalniz YAKIN ESLEME olarak isaretlenir; son soz kulakta.',
    'Whisper kisa (<1 sn) parcada ve kaydin sonunda kelime dusurebilir; DUSEN CUMLE bulgusu iki dokumde de eksikse verilir.'];
  sonuc.durum = sonuc.bulgular.some(b => b.sinif === 'KIRMIZI') ? 'KIRMIZI' : sonuc.bulgular.length ? 'SARI' : 'YESIL';
  fs.rmSync(tmp, { recursive: true, force: true });
  return sonuc;
}
function yaz(s) {
  console.log('\n=== KLIP DENETIMI: ' + s.durum + ' === ' + s.girdi + ' (' + s.sure_sn + ' sn, ' + s.ada_sayisi + ' konusma adasi)');
  for (const c of s.cumleler) console.log('  ' + String(c.n).padStart(2) + '. %' + String(Math.round(c.duyulma * 100)).padStart(3) + '  ' + c.beklenen);
  if (!s.bulgular.length) console.log('  bulgu yok');
  for (const b of s.bulgular) console.log('  [' + b.sinif + '] ' + b.tur + ' — ' + b.ayrinti);
  console.log('  ada dokumu: ' + s.dokum_ada);
  if (s.dudak_tabakasi) console.log('  dudak tabakasi: ' + s.dudak_tabakasi + '  (yesil cerceve=agiz acik olmali, kirmizi=kapali olmali)');
  console.log('  OLCMEDIGI: dudak senkronu otomatik degil (tabaka gozle) · telaffuz inceligi kulakla');
}

// ---------------- oz-sinav ----------------
if (process.argv[2] === '--sinav') {
  // Vakalar DEPODA DEGIL, kasada: depo PUBLIC, video metinleri (soru icerigi) commit'lenmez (CLAUDE.md bulut guvenligi 5).
  // Dosya: <mevzuat isi>/_yerel-veri-kasasi/instagram-ilk-gonderi/denetim-sinav/vakalar.json
  //   vaka 1: 20.09 klibi — son cumle dusmus + kekeleme -> KIRMIZI + iki KIRMIZI bulgu sart
  //   vaka 2: onayli temiz ses -> KIRMIZI OLMAMALI (yanlis alarm)
  //   vaka 3: 24.09 bitmis film, whisper yapisik kelime -> KIRMIZI OLMAMALI (yanlis alarm; 'yapisik' mutasyonunda duser)
  //   vaka 4: Bolum 1 filmi, ekli kelime ("Maliyet'in") yapisik sanilip bolununce sahte TEKRAR -> KIRMIZI OLMAMALI ('cift' mutasyonunda duser)
  // Sartlar KIRMIZI bulgunun KENDISINI arar: 24.09'da 'tekrar' kontrolu kapatilinca yedek SARI "OLASI TEKRAR" satiri
  // eski sinavi (tur.includes('TEKRAR')) yaniltmis, sinav yine TEMIZ demisti.
  const kok = path.resolve(__dirname, '..', '..', '..');
  const vYol = path.join(kok, '_yerel-veri-kasasi', 'instagram-ilk-gonderi', 'denetim-sinav', 'vakalar.json');
  if (!fs.existsSync(vYol)) { console.log('OZ-SINAV KOR: vaka dosyasi yok -> ' + vYol); process.exit(3); }
  const vakalar = JSON.parse(fs.readFileSync(vYol, 'utf8')).vakalar;
  let dus = 0, top = 0;
  for (const v of vakalar) {
    const dosya = path.join(kok, v.dosya);
    if (!fs.existsSync(dosya)) { console.log('DUSTU  ' + v.ad + ' — dosya YOK (KOR): ' + dosya); dus++; top++; continue; }
    const s = denetle(dosya, v.beklenen, { tabakasiz: !!v.tabakasiz }); yaz(s);
    const durumOk = v.durum === 'KIRMIZI' ? s.durum === 'KIRMIZI' : s.durum !== 'KIRMIZI';
    top++; console.log((durumOk ? 'GECTI' : 'DUSTU') + '  ' + v.ad + ' -> durum ' + (v.durum === 'KIRMIZI' ? 'KIRMIZI' : 'KIRMIZI degil')); if (!durumOk) dus++;
    for (const sr of (v.sartlar || [])) {
      const var_ = s.bulgular.some(b => b.sinif === sr.sinif && b.tur.startsWith(sr.tur_bas) && (!sr.ayrinti_bas || b.ayrinti.startsWith(sr.ayrinti_bas)));
      top++; console.log((var_ ? 'GECTI' : 'DUSTU') + '  ' + v.ad.split(' - ')[0] + ' ' + sr.ad); if (!var_) dus++;
    }
  }
  console.log(dus ? '\nOZ-SINAV DUSTU (' + dus + '/' + top + ')' : '\nOZ-SINAV TEMIZ (' + top + '/' + top + ')'); process.exit(dus ? 2 : 0);
}

// ---------------- normal calisma ----------------
const [girdi, sahneYol] = process.argv.slice(2);
if (!girdi || !sahneYol) { console.error('kullanim: node klip-denetim.js <klip> <sahne.json>  |  --sinav'); process.exit(3); }
const sahne = JSON.parse(fs.readFileSync(sahneYol, 'utf8'));
// iki bicim: sahne json ("beklenen_replikler": [...]) ya da ses metin json ("replikler": [{tts:...}]) — ses asamasi denetimi
const beklenenler = Array.isArray(sahne.beklenen_replikler) && sahne.beklenen_replikler.length ? sahne.beklenen_replikler
  : Array.isArray(sahne.replikler) ? sahne.replikler.map(r => r.tts).filter(Boolean) : [];
if (!beklenenler.length) { console.error('json icinde "beklenen_replikler" ya da "replikler[].tts" yok — denetim yapilamaz'); process.exit(3); }
const s = denetle(girdi, beklenenler);
fs.writeFileSync(girdi + '.denetim.json', JSON.stringify(s, null, 1));
yaz(s);
process.exit(s.durum === 'YESIL' ? 0 : s.durum === 'SARI' ? 1 : 2);
