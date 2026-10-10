#!/usr/bin/env node
// arac/degisiklik-nobetcisi.js — KANUN DEĞİŞİKLİĞİ NÖBETÇİSİ (10.10.2026, Cem "1 yap" — kanun değişikliği taraması GM önerisi 1)
//
// Olay (ölçüldü 10.10): bankada 123 soru eskimiş kuralla yazılmıştı (veri/sinav/KANUN-DEGISIKLIGI-TARAMA-20261010.md). arac/eski-kurallar.json
// yalnız BİLİNEN kuralları yakalıyor; listede olmayan değişiklik (KDVK m.29/1-ç 7491, GVK m.22/4 7491, VUK m.320/3 7338, 5510 m.41 7566 …)
// aylarca görülmedi. Oysa mevzuat.gov.tr konsolide metni her değişikliği metnin içinde yazar: satır içi "(Değişik: 14/10/2021-7338/30 md.)"
// ve dipnot "… tarihli ve 7887 sayılı Cumhurbaşkanı Kararı ile … yükseltilmiştir". Bu nöbetçi ambardaki resmî metinlerden (veri/mevzuat/*.json)
// bu notları çıkarır, kütükle (veri/sinav/degisiklik-kutugu.json) kıyaslar; YENİ not "bekleyen" listesine girer ve okunup onaylanana kadar
// --kati KIRMIZI döner. Rapor: veri/sinav/DEGISIKLIK-NOBETI.md (bekleyen notlar + bankada yaklaşık atıf; soru metni YOK).
//
// Kimlik: satır içi not = dosya + madde + not metni; dipnot = dosya + not metni (madde YOK: PDF dipnotu çoğu zaman bir SONRAKİ maddenin
// kaydına düşer — TTK m.332'nin 7887 dipnotu m.334 kaydında — ve sayfa düzeni değişince kayabilir). Boşluklar teke indirilir.
// Aynı kimlik birden çok yerde geçebilir (aynı ek fıkra notu); sayı artarsa yeni sayılır.
//
// 🚫 GÖRMEZ: ambara hiç yutulmamış kanun/tebliğ (önce yutulur) · metne not düşmeyen değişiklik (yıllık tutar tebliği, oranı CBK ile değişip
//   dipnotu kesik/eksik kalan madde — 10.10'da 5510 m.41 ve TTK m.580 dipnotları ambarda eksikti) · notun SORUYU etkileyip etkilemediği
//   (bunu ancak okuma söyler; banka atıf sayısı yalnız ipucu, madde numarası anmayan soruyu görmez) · iki biçim dışındaki not yazımları.
//
// Kullanım (cwd = depo kökü):
//   node arac/degisiklik-nobetcisi.js --tara            mevzuatı tara; yeni not → bekleyen; kütük + rapor yalnız içerik değişirse yazılır
//   node arac/degisiklik-nobetcisi.js --kati            bekleyen varsa çıkış 1 (mevzuat.yml kapı adımı)
//   node arac/degisiklik-nobetcisi.js --onayla <kimlik…|hepsi> --not "<okundu: ne yapıldı>"   bekleyeni bilinenlere taşır
//   node arac/degisiklik-nobetcisi.js --taban --not "<gerekçe>"   kütük yoksa: bugünkü bütün notlar bilinen (bir kez)
//   node arac/degisiklik-nobetcisi.js --sinav [--mutasyon]
//   Seçenek: --kok <dizin> (vars. depo kökü; sınav geçici dizinde koşar)
'use strict';
const fs = require('fs'), path = require('path'), crypto = require('crypto');
const MUT = process.env.DN_MUTASYON || '';

// ---------- çıkarım ----------
const RE_SATIR = /\(((?:De[ğg]i[şs]ik|Ek|M[üu]lga|[İI]ptal|Yeniden d[üu]zenleme)[^():]{0,80}):\s*(\d{1,2})\s*\/\s*(\d{1,2})\s*\/\s*(\d{4})\s*[-–]\s*(\d{3,5})[^)]{0,40}\)/g;
const FIIL = 'de[ğg]i[şs]tirilmi[şs]tir|eklenmi[şs]tir|y[üu]r[üu]rl[üu]kten kald[ıi]r[ıi]lm[ıi][şs]t[ıi]r|ilga edilmi[şs]tir|iptal edilmi[şs]tir|[İI]PTAL|h[üu]kme ba[ğg]lanm[ıi][şs]t[ıi]r|belirlenmi[şs]tir|y[üu]kseltilmi[şs]tir|art[ıi]r[ıi]lm[ıi][şs]t[ıi]r|[çc][ıi]kar[ıi]lm[ıi][şs]t[ıi]r|indirilmi[şs]tir|d[üu][şs][üu]r[üu]lm[üu][şs]t[üu]r|uzat[ıi]lm[ıi][şs]t[ıi]r';
const RE_DIPNOT = new RegExp('(\\d{1,2})\\/(\\d{1,2})\\/(\\d{4}) tarihli ve (\\d{3,5}) say[ıi]l[ıi] (Kanun|Cumhurba[şs]kan[ıi] Karar|Cumhurba[şs]kanl[ıi][ğg][ıi] Kararnamesi|Kanun H[üu]km[üu]nde Kararname)[\\s\\S]{0,700}?(' + FIIL + ')', 'g');
// 10.10 gerçek vaka ölçümü: KDVK 14.08 → 10.09 aynasındaki tek gerçek değişiklik AYM iptaliydi (m.36'dan "iade" → "(…)91"; karar
//   "Anayasa Mahkemesinin 22/7/2025 tarihli ve E.: 2024/54, K.: 2025/163 sayılı Kararı" biçiminde) — iki biçim onu görmüyordu. Danıştay
//   iptali de bu biçimde (SMMM Odalar Yön. m.16/b-2: "Danıştay Sekizinci Dairesinin 11/2/2022 tarihli ve E.:2018/4865; K.:2022/792").
const RE_KARAR = /(Anayasa Mahkemesi|Dan[ıi][şs]tay)[^.()]{0,60}?(\d{1,2})\/(\d{1,2})\/(\d{4}) tarihli ve E\.?\s?:?\s?(\d{4}\/\d+)\s*[;,]?\s*K\.?\s?:?\s?(\d{4}\/\d+)/g;
const bosluk = s => MUT === 'bosluk' ? s : s.replace(/\s+/g, ' ').trim();
const maddeAd = ad => String(ad || '').replace(/\s*\[\d+\/\d+\].*$/, '').replace(/\s+-\s+.*$/, '').trim();
const ozet = s => crypto.createHash('sha1').update(s).digest('hex').slice(0, 16);

function cikar(kok) {
  const dz = path.join(kok, 'veri', 'mevzuat'); const notlar = new Map(); let dosya = 0, belge = 0;
  for (const f of fs.readdirSync(dz).filter(f => f.endsWith('.json') && !f.startsWith('_')).sort()) {
    let j; try { j = JSON.parse(fs.readFileSync(path.join(dz, f), 'utf8').replace(/^﻿/, '')); } catch (e) { continue; }
    const bl = Array.isArray(j.belgeler) ? j.belgeler : []; if (!bl.length) continue; dosya++;
    const d = f.replace(/\.json$/, '');
    for (const b of bl) {
      const t = String(b.metin || ''); if (!t) continue; belge++; const m = maddeAd(b.kaynak_ad);
      const ekle = (kimlikMetni, o) => { const k = ozet(kimlikMetni); const v = notlar.get(k); if (v) v.sayi++; else notlar.set(k, Object.assign({ kimlik: k, sayi: 1 }, o)); };
      let x; RE_SATIR.lastIndex = 0;
      while ((x = RE_SATIR.exec(t))) {
        const not = bosluk(x[0]);
        ekle(d + '|' + m + '|' + not, { dosya: d, madde: m, bicim: 'satir', tur: bosluk(x[1]), tarih: `${x[2]}/${x[3]}/${x[4]}`, yil: +x[4], sayi_no: x[5],
          url: b.kaynak_url || '', belge_tarihi: b.belge_tarihi || '', parca: bosluk(t.slice(x.index, x.index + 260)) });
      }
      if (MUT === 'dipnot-yok') continue;
      RE_DIPNOT.lastIndex = 0;
      while ((x = RE_DIPNOT.exec(t))) {
        const not = bosluk(x[0]);
        /* 10.10 ölçümü (dipnot süzgeci yeniden yutması 71afa9a1, 891 dosya): parça sınırı kayınca aynı dipnot farklı uzunlukta kesildi,
           metin kimliği 6 yanlış "yeni" verdi. Kimlik = değiştiren kanunun tarih + sayı + madde numarası (kesilmeden etkilenmez). */
        const dm = /say[ıi]l[ıi] [^.]{0,40}?(\d{1,3})\s*['’]?\s*(?:inci|nci|üncü|uncu|ıncı|\.)?\s*madde/i.exec(not);
        const kim = (dm && MUT !== 'dipnot-metin') ? `${x[1]}/${x[2]}/${x[3]}-${x[4]}/m${dm[1]}` : not.slice(0, 160);
        ekle(d + '|' + (MUT === 'madde-anahtar' ? m + '|' : '') + kim, { dosya: d, madde: m + ' (dipnot; madde kayabilir)', bicim: 'dipnot',
          tur: x[6], tarih: `${x[1]}/${x[2]}/${x[3]}`, yil: +x[3], sayi_no: x[4] + (/Karar/.test(x[5]) ? ' ' + x[5] : ''),
          url: b.kaynak_url || '', belge_tarihi: b.belge_tarihi || '', parca: not.slice(0, 260) });
      }
      if (MUT === 'karar-yok') continue;
      RE_KARAR.lastIndex = 0;
      while ((x = RE_KARAR.exec(t))) {
        const not = bosluk(x[0]);
        ekle(d + '|' + not, { dosya: d, madde: m + ' (yargı kararı; madde kayabilir)', bicim: 'karar', tur: x[1] + ' kararı', tarih: `${x[2]}/${x[3]}/${x[4]}`,
          yil: +x[4], sayi_no: 'E.' + x[5] + ' K.' + x[6], url: b.kaynak_url || '', belge_tarihi: b.belge_tarihi || '', parca: bosluk(t.slice(x.index, x.index + 260)) });
      }
    }
  }
  return { notlar, dosya, belge };
}

// ---------- kütük ----------
const yollar = kok => ({ kutuk: path.join(kok, 'veri', 'sinav', 'degisiklik-kutugu.json'), rapor: path.join(kok, 'veri', 'sinav', 'DEGISIKLIK-NOBETI.md') });
function kutukOku(kok) { const p = yollar(kok).kutuk; if (!fs.existsSync(p)) return null; return JSON.parse(fs.readFileSync(p, 'utf8').replace(/^﻿/, '')); }
/* zaman alanı dışında değişmediyse dosyaya hiç dokunma (CLAUDE.md: rapor her koşuda "değişmiş" görünmesin) */
function yazDegistiyse(p, metin, zamanRe) {
  if (fs.existsSync(p)) { const eski = fs.readFileSync(p, 'utf8'); if (eski.replace(zamanRe, '') === metin.replace(zamanRe, '')) return false; }
  fs.mkdirSync(path.dirname(p), { recursive: true }); fs.writeFileSync(p, metin); return true;
}
const KUTUK_ZAMAN = /"son_tarama": "[^"]*"/;
const RAPOR_ZAMAN = /^Son tarama: .*$/m;
function kutukYaz(kok, K) { return yazDegistiyse(yollar(kok).kutuk, JSON.stringify(K, null, 1) + '\n', KUTUK_ZAMAN); }

// ---------- banka ipucu (yerelde varsa) ----------
function bankaAtif(kok, bekleyen) {
  const fz = path.join(kok, 'veri', 'fabrika'); if (!fs.existsSync(fz)) return null;
  const fs2 = fs.readdirSync(fz).filter(f => /^kalip-parti-(sgs|smmm|kgk)-.*\.json$/.test(f)); if (!fs2.length) return null;
  const MODEL = new Set(['hakem', 'hakem2', 'kor_cozum', 'simulasyon_sonnet', 'kaynak_metin_ozet', 'kaynak_adlar', 'notlandirici', 'capa_metin', 'capa_kaynak', 'atif_genisletme', 'mukerrer', 'aciklama_hakem']);
  const metinler = [];
  for (const f of fs2) { let p; try { p = JSON.parse(fs.readFileSync(path.join(fz, f), 'utf8').replace(/^﻿/, '')); } catch (e) { continue; }
    for (const kp of Object.keys(p)) { if (!/^kp-/.test(kp) || !p[kp] || typeof p[kp] !== 'object') continue; const c = [];
      (function gez(o, ust) { if (o == null) return; if (typeof o === 'string') { c.push(o); return; } if (typeof o !== 'object') return; for (const a of Object.keys(o)) { if (ust && MODEL.has(a)) continue; gez(o[a], false); } })(p[kp], true);
      metinler.push(c.join(' \n ')); } }
  const kac = n => { const mm = /^(\S+)\s+\((\d+)\s*s\.K\.\)\s+(?:(ek|ge[çc]\.|muk\.)\s*)?m\.(\d+(?:\/[A-Z])?)/i.exec(n.madde); if (!mm) return null;
    const kis = mm[1].replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), no = mm[4].replace('/', '\\s?\\/\\s?');
    const re = new RegExp(`(${kis}|${mm[2]} say[ıi]l[ıi])[^.;\\n]{0,40}?(m\\.?|md\\.?|madde)\\s?${no}(?![\\d])|\\b${no}\\.?\\s?(inci|nci|üncü|uncu|ıncı)?\\s?madde[^.;\\n]{0,30}?(${kis}|${mm[2]} say[ıi]l[ıi])`, 'i');
    return metinler.reduce((a, t) => a + (re.test(t) ? 1 : 0), 0); };
  const r = {}; for (const n of bekleyen) r[n.kimlik] = kac(n); return { soru: metinler.length, r };
}

function rapor(kok, K, ozetSatir, banka) {
  const L = Object.values(K.bekleyen).sort((a, b) => (b.yil - a.yil) || a.dosya.localeCompare(b.dosya));
  let o = '# Kanun değişikliği nöbeti\n\n';
  o += 'Üretici: `node arac/degisiklik-nobetcisi.js --tara` (mevzuat.yml her yutmadan sonra). Elle düzenlenmez.\n';
  o += 'Bekleyen not = ambardaki resmî metinde YENİ görülen değişiklik notu; okunup `--onayla <kimlik> --not "…"` ile kapanana kadar `--kati` KIRMIZI.\n';
  o += 'Okuma sırası: madde metnini oku → eski kural / yeni kural → bankada etkilenen soru var mı (`veri/sinav/KANUN-DEGISIKLIGI-TARAMA-20261010.md` yöntemi) → gerekirse `arac/eski-kurallar.json` + onarım kuyruğu.\n\n';
  o += 'Son tarama: ' + K.son_tarama + '\n\n' + ozetSatir + '\n\n';
  o += banka ? `Bankada yaklaşık atıf: yerel ambar kopyası ${banka.soru} soru (madde numarasıyla atıf; konu kelimesiyle anılan soruyu GÖRMEZ).\n\n` : 'Bankada atıf: **KÖR** (veri/fabrika bu makinede/koşucuda yok — yerelde `--tara` koşunca dolar).\n\n';
  if (!L.length) o += '**Bekleyen not yok.**\n';
  else {
    o += `## Bekleyen (${L.length})\n\n| Kimlik | Dosya | Madde | Biçim | Tür | Tarih – sayı | Banka atıf | Not (ilk 160) |\n|---|---|---|---|---|---|---|---|\n`;
    for (const n of L) { const a = banka ? (banka.r[n.kimlik] == null ? 'madde çözülemedi' : banka.r[n.kimlik]) : 'KÖR';
      o += `| \`${n.kimlik}\` | ${n.dosya} | ${n.madde.replace(/\|/g, '/')} | ${n.bicim} | ${String(n.tur).replace(/\|/g, '/')} | ${n.tarih} – ${n.sayi_no} | ${a} | ${String(n.parca).slice(0, 160).replace(/\|/g, '/')} |\n`; }
  }
  return o;
}

function tara(kok, opt) {
  opt = opt || {};
  const { notlar, dosya, belge } = cikar(kok);
  let K = kutukOku(kok); const zaman = new Date().toISOString();
  if (!K) throw new Error('kütük yok — önce bir kez: --taban --not "<gerekçe>"');
  K.son_tarama = zaman; let yeni = 0, eskiTarihli = 0;
  const esik = (opt.yil || new Date().getFullYear()) - 2;   // konsolide metne YENİ giren değişikliğin tarihi yenidir
  for (const [k, n] of notlar) {
    const bil = K.bilinen[k];
    if (bil && bil.sayi >= n.sayi) continue;
    if (K.bekleyen[k] && MUT !== 'bekleyen-tasir') continue;   // okunmamış not hiçbir kuralla sessizce kapanmaz (yıl dönse de)
    /* eski tarihli not yeniden göründü (yeniden yutma / parça kayması) → bekleyen değil, bilinen'e otomatik + sayaç (10.10 ölçümü: 5/6 yanlış alarm) */
    if (n.yil < esik && MUT !== 'eski-yil-yok') { K.bilinen[k] = { sayi: n.sayi, dosya: n.dosya, madde: n.madde, tarih: n.tarih, sayi_no: n.sayi_no, onay: zaman.slice(0, 10) + ': otomatik — eski tarihli not yeniden göründü (< ' + esik + ')' }; eskiTarihli++; continue; }
    if (bil && bil.sayi < n.sayi && MUT !== 'sayi-yok') { if (!K.bekleyen[k]) { K.bekleyen[k] = Object.assign({}, n, { ilk_gorulme: zaman.slice(0, 10), neden: 'aynı not ' + bil.sayi + ' → ' + n.sayi + ' yerde' }); yeni++; } continue; }
    if (bil) continue;
    if (!K.bekleyen[k]) { K.bekleyen[k] = Object.assign({}, n, { ilk_gorulme: zaman.slice(0, 10), neden: 'yeni not' }); yeni++; }
  }
  const kaybolan = Object.keys(K.bilinen).filter(k => !notlar.has(k)).length;
  K.olcum = { dosya, belge, not: notlar.size, bilinen: Object.keys(K.bilinen).length, bekleyen: Object.keys(K.bekleyen).length, kaybolan };
  const ozetSatir = `DEĞİŞİKLİK NÖBETİ: ${dosya} dosya · ${belge} belge · ${notlar.size} not · yeni ${yeni} · bekleyen ${K.olcum.bekleyen} · eski tarihli yeniden görünen (otomatik bilinen) ${eskiTarihli} · kütükte olup metinde artık görülmeyen ${kaybolan}`;
  const banka = opt.bankaYok ? null : (K.olcum.bekleyen ? bankaAtif(kok, Object.values(K.bekleyen)) : null);
  const k1 = kutukYaz(kok, K), r1 = yazDegistiyse(yollar(kok).rapor, rapor(kok, K, ozetSatir, banka), RAPOR_ZAMAN);
  return { yeni, bekleyen: K.olcum.bekleyen, kaybolan, eskiTarihli, ozetSatir, yazildi: k1 || r1 };
}

function taban(kok, not) {
  if (kutukOku(kok)) throw new Error('kütük zaten var — taban yalnız bir kez');
  if (!not) throw new Error('--not zorunlu');
  const { notlar, dosya, belge } = cikar(kok); const z = new Date().toISOString(); const bilinen = {};
  for (const [k, n] of notlar) bilinen[k] = { sayi: n.sayi, dosya: n.dosya, madde: n.madde, tarih: n.tarih, sayi_no: n.sayi_no, onay: 'taban' };
  const K = { aciklama: 'Kanun değişikliği nöbetçisinin kütüğü (arac/degisiklik-nobetcisi.js). bilinen = okunmuş/taban notlar (kimlik → sayı); bekleyen = yeni görülen, okunmamış. Elle düzenlenmez: --onayla ile kapanır.',
    taban: { tarih: z.slice(0, 10), not }, son_tarama: z, olcum: { dosya, belge, not: notlar.size, bilinen: notlar.size, bekleyen: 0, kaybolan: 0 }, bilinen, bekleyen: {} };
  kutukYaz(kok, K); yazDegistiyse(yollar(kok).rapor, rapor(kok, K, `DEĞİŞİKLİK NÖBETİ: taban kuruldu — ${dosya} dosya · ${belge} belge · ${notlar.size} not bilinen`, null), RAPOR_ZAMAN);
  return notlar.size;
}

function onayla(kok, kimlikler, not) {
  if (!not) throw new Error('--not zorunlu (ne okundu, ne yapıldı)');
  const K = kutukOku(kok); if (!K) throw new Error('kütük yok');
  const hedef = kimlikler.includes('hepsi') ? Object.keys(K.bekleyen) : kimlikler; let n = 0; const yok = [];
  for (const k of hedef) { const b = K.bekleyen[k]; if (!b) { yok.push(k); continue; }
    K.bilinen[k] = { sayi: b.sayi, dosya: b.dosya, madde: b.madde, tarih: b.tarih, sayi_no: b.sayi_no, onay: new Date().toISOString().slice(0, 10) + ': ' + not };
    delete K.bekleyen[k]; n++; }
  K.olcum.bilinen = Object.keys(K.bilinen).length; K.olcum.bekleyen = Object.keys(K.bekleyen).length;
  kutukYaz(kok, K); yazDegistiyse(yollar(kok).rapor, rapor(kok, K, `DEĞİŞİKLİK NÖBETİ: ${n} not onaylandı · bekleyen ${K.olcum.bekleyen}`, null), RAPOR_ZAMAN);
  return { n, yok, bekleyen: K.olcum.bekleyen };
}

// ---------- öz-sınav ----------
function sinav() {
  const os = require('os'); const kok = fs.mkdtempSync(path.join(os.tmpdir(), 'dn-sinav-'));
  const mz = path.join(kok, 'veri', 'mevzuat'); fs.mkdirSync(mz, { recursive: true });
  const yaz = (ad, belgeler) => fs.writeFileSync(path.join(mz, ad + '.json'), JSON.stringify({ belgeler }));
  const B = (ad, metin) => ({ kaynak_ad: ad, metin, kaynak_url: 'https://www.mevzuat.gov.tr/x.pdf', belge_tarihi: '2026-10-08' });
  const M320 = 'Madde 320 – (Ek fıkra: 14/10/2021-7338/30 md.) Dileyen mükellef gün esasına göre amortisman ayırabilir.';
  const M332 = 'MADDE 332- (1) Esas sermaye ellibin Türk Lirasından aşağı olamaz.4142';
  const M334 = 'MADDE 334- ... 42 24/11/2023 tarihli ve 7887 sayılı Cumhurbaşkanı Kararı ile bu fıkrada yer alan ellibin Türk Lirası ikiyüzellibin Türk Lirasına yükseltilmiştir.';
  yaz('vuk', [B('VUK (213 s.K.) m.320 - Amortisman', M320)]);
  yaz('ttk', [B('TTK (6102 s.K.) m.332', M332), B('TTK (6102 s.K.) m.334', M334)]);
  yaz('_durum', [B('x', '(Değişik: 1/1/2025-7000/1 md.)')]);   // _ ile başlayan dosya taranmaz
  const v = []; const ok = (ad, kosul) => v.push([ad, !!kosul]);
  const T0 = { bankaYok: true, yil: 2022 };   // sınav notları 2021+ tarihli; eşik (yıl-2) hepsini 'yeni' saysın
  const t0 = taban(kok, 'sınav tabanı');
  ok('taban: satır içi + dipnot (CBK) notu çıkar → 2 not', t0 === 2);
  let r = tara(kok, T0); ok('değişmeyen metin → yeni 0', r.yeni === 0 && r.bekleyen === 0);
  r = tara(kok, T0);   // ilk tarama tabanın özet satırını değiştirir (gerçek içerik); ikinci tarama dokunmamalı
  ok('değişmeyen metin, ikinci tarama → kütük/rapor YENİDEN YAZILMAZ (zaman damgası farkı sayılmaz)', r.yazildi === false);
  // aynı metin farklı boşluk + parça bölünmesi ([1/2]) → yeni değil
  yaz('vuk', [B('VUK (213 s.K.) m.320 [1/2] - Amortisman', M320.replace(/ /g, '  ')), B('VUK (213 s.K.) m.320 [2/2]', 'devam metni')]);
  r = tara(kok, T0); ok('boşluk farkı + parça bölünmesi → yeni 0', r.yeni === 0);
  // dipnot bir sonraki maddeye kaydı (PDF düzeni) → yeni değil
  yaz('ttk', [B('TTK (6102 s.K.) m.332', M332 + ' ' + M334.slice(13)), B('TTK (6102 s.K.) m.334', 'MADDE 334- başka metin')]);
  r = tara(kok, T0); ok('dipnot başka madde kaydına kaydı → yeni 0', r.yeni === 0);
  // yeni satır içi not
  yaz('vuk', [B('VUK (213 s.K.) m.320 [1/2] - Amortisman', M320), B('VUK (213 s.K.) m.376', 'Madde 376 – 2. (Mülga:28/7/2024-7524/14 md.) indirilir.')]);
  r = tara(kok, T0); ok('yeni satır içi not (Mülga 7524) → yeni 1, bekleyen 1', r.yeni === 1 && r.bekleyen === 1);
  ok('yeni not → rapor yazıldı', r.yazildi === true);
  const rp = fs.readFileSync(yollar(kok).rapor, 'utf8'); ok('rapor bekleyeni gösterir (7524) + banka KÖR', /7524/.test(rp) && /KÖR/.test(rp));
  r = tara(kok, T0); ok('ikinci taramada aynı bekleyen tekrar sayılmaz', r.yeni === 0 && r.bekleyen === 1);
  // aynı not ikinci yerde (sayı artışı)
  yaz('vuk', [B('VUK (213 s.K.) m.320 [1/2] - Amortisman', M320 + ' ' + M320.slice(12)), B('VUK (213 s.K.) m.376', 'Madde 376 – 2. (Mülga:28/7/2024-7524/14 md.) indirilir.')]);
  r = tara(kok, T0); ok('aynı not aynı maddede ikinci kez (sayı 1→2) → yeni 1', r.yeni === 1 && r.bekleyen === 2);
  // yeni CBK dipnotu
  yaz('ttk', [B('TTK (6102 s.K.) m.332', M332 + ' ' + M334.slice(13)), B('TTK (6102 s.K.) m.580', 'MADDE 580- (1) en az onbin. 83 24/11/2023 tarihli ve 7887 sayılı Cumhurbaşkanı Kararı ile limited şirket tutarı ellibin Türk Lirasına yükseltilmiştir.')]);
  r = tara(kok, T0); ok('yeni CBK dipnotu (m.580) → yeni 1', r.yeni === 1 && r.bekleyen === 3);
  // yeni AYM iptali (KDVK m.36 gerçek vakası, 10.09 aynası) ve Danıştay iptali (Odalar Yön. m.16/b-2)
  yaz('kdv', [B('KDVK (3065 s.K.) m.36 - Yetki', 'Madde 36 – Cumhurbaşkanı indirim (…)91 hakkını kaldırmaya yetkilidir. 91 Anayasa Mahkemesinin 22/7/2025 tarihli ve E.: 2024/54, K.: 2025/163 sayılı Kararı ile bu fıkradaki "veya iade" ibaresi iptal edilmiştir.')]);
  r = tara(kok, T0); ok('yeni AYM iptal kararı (KDVK m.36 biçimi) → yeni ≥1', r.yeni >= 1);
  yaz('smmm-odalar-yon', [B('Odalar Yön. m.16', '2) (Değişik:RG-4/8/2015-29435) (Danıştay Sekizinci Dairesinin 11/2/2022 tarihli ve E.:2018/4865; K.:2022/792 sayılı kararı ile iptal alt bent; Nispi Aidat ...')]);
  const bk = Object.keys(kutukOku(kok).bekleyen).length;
  r = tara(kok, T0); ok('yeni Danıştay iptal kararı (E.:…; K.:… biçimi) → yeni 1', r.yeni === 1 && r.bekleyen === bk + 1);
  // dipnot parça sınırında farklı uzunlukta kesildi (aynı değiştiren madde) → yeni değil (71afa9a1 ölçümü)
  const bk2 = Object.keys(kutukOku(kok).bekleyen).length;
  yaz('ttk', [B('TTK (6102 s.K.) m.332', M332 + ' ' + M334.slice(13)), B('TTK (6102 s.K.) m.580', 'MADDE 580- (1) en az onbin. 83 24/11/2023 tarihli ve 7887 sayılı Cumhurbaşkanı Kararı ile limited şirket tutarı ellibin Türk Lirasına yükseltilmiştir.'),
    B('TTK (6102 s.K.) m.555', '... 2/6/2022 tarihli ve 7408 sayılı Kanunun 29 uncu maddesiyle metne işlendiği şekilde değiştirilmiştir.')]);
  r = tara(kok, T0); const bk3 = Object.keys(kutukOku(kok).bekleyen).length;   // 2022 notu T0 (yıl 2022 → eşik 2020) ile yeni sayılır
  yaz('ttk', [B('TTK (6102 s.K.) m.332', M332 + ' ' + M334.slice(13)), B('TTK (6102 s.K.) m.580', 'MADDE 580- (1) en az onbin. 83 24/11/2023 tarihli ve 7887 sayılı Cumhurbaşkanı Kararı ile limited şirket tutarı ellibin Türk Lirasına yükseltilmiştir.'),
    B('TTK (6102 s.K.) m.555 [1/2]', '... 2/6/2022 tarihli ve 7408 sayılı Kanunun 29 uncu maddesiyle bu maddenin başlığı ile birlikte metne işlendiği şekilde değiştirilmiştir.')]);
  r = tara(kok, T0); ok('aynı dipnot farklı kesildi (değiştiren madde aynı) → yeni 0', r.yeni === 0 && bk3 === bk2 + 1);
  // eski tarihli not yeniden göründü (gerçek yıl eşiği) → bekleyen değil, sayaç
  yaz('sgk5510', [B('5510 s. SGK Kanunu m.53', '... 13/2/2011 tarihli ve 6111 sayılı Kanunun 33 üncü maddesiyle, bu fıkrada yer alan ibare değiştirilmiştir.')]);
  const bk4 = Object.keys(kutukOku(kok).bekleyen).length;
  r = tara(kok, { bankaYok: true, yil: 2026 }); ok('eski tarihli (2011) not yeniden göründü, yıl 2026 → yeni 0, otomatik bilinen 1', r.yeni === 0 && r.eskiTarihli === 1);
  ok('yıl dönünce bekleyendeki eski tarihli notlar (2021/2023) KAPANMAZ', r.bekleyen === bk4);
  // kati
  const K = kutukOku(kok); ok('kati: bekleyen > 0', Object.keys(K.bekleyen).length > 0);
  // onay
  const o1 = onayla(kok, ['hepsi'], 'sınav: okundu'); ok('onayla hepsi → bekleyen 0', o1.bekleyen === 0 && o1.n >= 5);
  r = tara(kok, T0); ok('onaydan sonra tarama → yeni 0', r.yeni === 0 && r.bekleyen === 0);
  let hata = ''; try { onayla(kok, ['hepsi'], ''); } catch (e) { hata = e.message; } ok('onay notsuz reddedilir', /zorunlu/.test(hata));
  hata = ''; try { taban(kok, 'x'); } catch (e) { hata = e.message; } ok('taban ikinci kez reddedilir', /zaten/.test(hata));
  // kaybolan
  yaz('vuk', [B('VUK (213 s.K.) m.320 - Amortisman', 'Madde 320 – metin notsuz.')]);
  r = tara(kok, T0); ok('nottan kaybolan (yeniden yutma eksiği olabilir) sayılır', r.kaybolan >= 1 && r.yeni === 0);
  let g = 0; for (const [ad, s] of v) { if (s) g++; console.log((s ? '  ✓ ' : '  ✗ ') + ad); }
  fs.rmSync(kok, { recursive: true, force: true });
  console.log('DEGISIKLIK-NOBETI-SINAVI: ' + (g === v.length ? 'YESIL' : 'KIRMIZI') + ' — ' + g + '/' + v.length + (MUT ? ' · DN_MUTASYON=' + MUT : ''));
  return g === v.length;
}

if (require.main === module) {
  const a = process.argv.slice(2); const gi = k => { const i = a.indexOf(k); return i >= 0 ? a[i + 1] : null; };
  const kok = gi('--kok') ? path.resolve(gi('--kok')) : path.resolve(__dirname, '..');
  try {
    if (a.includes('--sinav')) {
      if (a.includes('--mutasyon')) {
        const { spawnSync } = require('child_process'); const ler = ['bosluk', 'dipnot-yok', 'madde-anahtar', 'sayi-yok', 'karar-yok', 'dipnot-metin', 'eski-yil-yok', 'bekleyen-tasir']; let t = 0;
        for (const m of ler) { const r = spawnSync(process.execPath, [__filename, '--sinav'], { env: Object.assign({}, process.env, { DN_MUTASYON: m }), encoding: 'utf8' });
          if (r.status !== 0) t++; console.log('  mutasyon ' + m.padEnd(14) + (r.status !== 0 ? 'KIRMIZI (doğru)' : 'YESIL (YANLIŞ)')); }
        console.log('MUTASYON: ' + t + '/' + ler.length + ' → KIRMIZI'); process.exit(t === ler.length ? 0 : 1);
      }
      process.exit(sinav() ? 0 : 1);
    }
    if (a.includes('--taban')) { const n = taban(kok, gi('--not')); console.log('DEĞİŞİKLİK NÖBETİ: taban kuruldu — ' + n + ' not bilinen'); process.exit(0); }
    if (a.includes('--onayla')) { const i = a.indexOf('--onayla'); const ks = []; for (let j = i + 1; j < a.length && !a[j].startsWith('--'); j++) ks.push(a[j]);
      const r = onayla(kok, ks, gi('--not')); console.log('DEĞİŞİKLİK NÖBETİ: onaylanan ' + r.n + ' · bulunamayan ' + r.yok.length + (r.yok.length ? ' (' + r.yok.join(' ') + ')' : '') + ' · bekleyen ' + r.bekleyen); process.exit(r.yok.length ? 1 : 0); }
    if (a.includes('--tara')) { const r = tara(kok); console.log(r.ozetSatir); if (r.bekleyen) console.log('UYARI: yeni kanun değişikliği notu var — veri/sinav/DEGISIKLIK-NOBETI.md okunmalı'); process.exit(0); }
    if (a.includes('--kati')) { const K = kutukOku(kok); if (!K) { console.log('DEĞİŞİKLİK NÖBETİ KÖR: kütük yok'); process.exit(1); }
      const n = Object.keys(K.bekleyen).length; if (!n) { console.log('DEĞİŞİKLİK NÖBETİ TEMİZ: bekleyen not yok'); process.exit(0); }
      console.log('KIRMIZI: ' + n + ' kanun değişikliği notu okunmayı bekliyor (veri/sinav/DEGISIKLIK-NOBETI.md).');
      for (const b of Object.values(K.bekleyen).slice(0, 30)) console.log('  ' + b.kimlik + '  ' + b.dosya + ' ' + b.madde + '  ' + b.tarih + '-' + b.sayi_no);
      console.log('Okunduktan sonra: node arac/degisiklik-nobetcisi.js --onayla <kimlik…> --not "<ne yapıldı>"'); process.exit(1); }
  } catch (e) { console.error('DEĞİŞİKLİK NÖBETİ HATA: ' + e.message); process.exit(2); }
  console.log('kullanım: --tara | --kati | --onayla <kimlik…|hepsi> --not "…" | --taban --not "…" | --sinav [--mutasyon]  [--kok <dizin>]'); process.exit(2);
}
module.exports = { cikar, tara, onayla, taban };
