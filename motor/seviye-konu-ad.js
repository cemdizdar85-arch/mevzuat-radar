// motor/seviye-konu-ad.js — seviye testi raporu için "takıldığın konular" adları (07.10.2026, Cem "konu adlarını düzeltip takıldığın konuları ekleyelim").
//
// NE YAPAR: seviye testinde çıkabilecek her sorunun kimliği -> öğrenciye gösterilecek düzgün Türkçe konu adı.
//   · Yeterlilik (veri/seviye/smmm-set.json): sınav oturumunun soruyu OKUYARAK bağladığı ad (veri/sinav/smmm-banka-esleme.json,
//     ilk konu). Eşlemede olmayan soru dosyaya YAZILMAZ (sayfa o soruda konu göstermez).
//   · Staja Giriş (veri/seviye/sgs-havuz.json): kasadaki konu adı (paket_soru.konu) çoğunlukla Türkçe harfsiz ya da yarım
//     ("anlatım bozuklugu"). Kelime kelime onarılır: aynı kelimenin kasadaki tüm SGS konu adlarında + okunmuş SGS konu
//     listesinde (veri/sinav/sgs-konu-okuma.json) Türkçe harfli yazımı varsa en sık görülen o yazım alınır. Türkçe harfli
//     yazımı hiç görülmeyen kelime olduğu gibi kalır (ör. "denklem" zaten doğru).
// ÇIKTI: veri/seviye/konu-ad.json { uretici, sinavlar:{ smmm:{id:ad}, sgs:{id:ad} }, onarilamayan:[...] } — soru metni YOK,
//   yalnız kimlik + konu adı (depo public). Zaman damgası yok: sonuç değişmezse dosyaya dokunulmaz.
// 🚫 GÖRMEZ: Türkçe harfli yazımı kasada hiç geçmeyen ama aslında Türkçe harf isteyen kelime (ör. tek başına "uslup") —
//   "onarilamayan" listesine yazılır, sabah gözle okunur; konu adının soruya uygunluğu (etiket hatası) ölçülmez.
// Kullanım: node motor/seviye-konu-ad.js [--kuru] · öz-sınav: --sinav   (kasa okuması için SUPABASE_SERVICE_KEY)
'use strict';
const fs = require('fs'), path = require('path');
const KOK = path.join(__dirname, '..');
const HEDEF = path.join(KOK, 'veri', 'seviye', 'konu-ad.json');
const TR = /[çğıöşüÇĞİÖŞÜ]/;
const katla = s => String(s || '').toLocaleLowerCase('tr').replace(/ı/g, 'i').replace(/ş/g, 's').replace(/ğ/g, 'g').replace(/ü/g, 'u').replace(/ö/g, 'o').replace(/ç/g, 'c').replace(/[âà]/g, 'a').replace(/[îì]/g, 'i').replace(/û/g, 'u');
const buyukBas = s => { s = String(s || '').trim(); return s ? s.charAt(0).toLocaleUpperCase('tr') + s.slice(1) : s; };
const jsonOku = f => JSON.parse(fs.readFileSync(f, 'utf8').replace(/^﻿/, ''));

/* sözlük: katlanmış kelime -> en sık Türkçe harfli yazım (yalnız Türkçe harf taşıyan yazımlar sayılır) */
function sozlukKur(metinler) {
  const say = {};
  for (const m of metinler) for (const k of String(m || '').toLocaleLowerCase('tr').split(/[^0-9a-zçğıöşüâîû]+/i)) {
    if (!k || !TR.test(k)) continue; const a = katla(k); (say[a] = say[a] || {})[k] = (say[a][k] || 0) + 1;
  }
  const s = {}; for (const a in say) s[a] = Object.entries(say[a]).sort((x, y) => y[1] - x[1] || x[0].localeCompare(y[0], 'tr'))[0][0];
  return s;
}
/* ELLE OKUNMUŞ EK (07.10, ilk koşunun 342 adı tek tek okundu): kasada Türkçe harfli yazımı HİÇ geçmeyen kelimeler + kısaltmalar.
   Anahtar katlanmış yazım. Kelime eklerken yalnız bugün listede görülen kelime eklenir (tahmin yok). */
const EK = { ozellikleri: 'özellikleri', unsurlari: 'unsurları', organlari: 'organları', ogeleri: 'ögeleri', kagitlari: 'kâğıtları',
  cozme: 'çözme', oz: 'öz', farklilastirmasi: 'farklılaştırması', yapilari: 'yapıları', koklu: 'köklü', antlasmalari: 'antlaşmaları',
  anlasmalari: 'anlaşmaları', kuramlari: 'kuramları', istisnalari: 'istisnaları', iradi: 'iradı', ustunlukler: 'üstünlükler', ayrac: 'ayraç',
  padisahlari: 'padişahları', guvenceleri: 'güvenceleri', sozcukte: 'sözcükte', esasi: 'esası', duzlestirmesi: 'düzleştirmesi', uslu: 'üslü',
  faktorleri: 'faktörleri', turkiye: 'Türkiye', abdulhamit: 'Abdülhamit', ataturk: 'Atatürk', osmanli: 'Osmanlı', lozan: 'Lozan',
  erzurum: 'Erzurum', sakarya: 'Sakarya', keynesyen: 'Keynesyen', laffer: 'Laffer', taylor: 'Taylor',
  kdv: 'KDV', otv: 'ÖTV', tms: 'TMS', tfrs: 'TFRS', vuk: 'VUK', smmm: 'SMMM', gsyh: 'GSYH', gsyih: 'GSYİH', ifac: 'IFAC', lm: 'LM', ii: 'II' };
/* konu adını kelime kelime onar; dönüş: { ad, eksik:[Türkçe harfsiz kalan ama sözlükte olmayan kelime] } */
function onar(konu, soz) {
  const eksik = [];
  const ad = String(konu || '').toLocaleLowerCase('tr').replace(/[0-9a-zçğıöşüâîû]+/gi, k => {
    const a = katla(k); if (EK[a]) return EK[a]; if (soz[a]) return soz[a];
    if (!TR.test(k) && /[iousgc]/.test(k) && k.length > 3) eksik.push(k);
    return k;
  });
  return { ad: buyukBas(ad.replace(/Atatürk'un\b/g, "Atatürk'ün").replace(/\s+/g, ' ').trim()), eksik };
}

async function ana() {
  const kuru = process.argv.includes('--kuru');
  const cikti = { uretici: 'motor/seviye-konu-ad.js', sinavlar: { smmm: {}, sgs: {} }, onarilamayan: [] };
  // Yeterlilik
  const set = jsonOku(path.join(KOK, 'veri', 'seviye', 'smmm-set.json')).sorular || [];
  const es = jsonOku(path.join(KOK, 'veri', 'sinav', 'smmm-banka-esleme.json')).sorular || {};
  let smmmYok = 0;
  for (const s of set) { const x = es[s.id]; const ad = x && (x.konular || [])[0]; if (ad) cikti.sinavlar.smmm[s.id] = String(ad).trim(); else smmmYok++; }
  // Staja Giriş
  const K = (process.env.SUPABASE_SERVICE_KEY || '').trim(); if (!K) throw new Error('SUPABASE_SERVICE_KEY yok - kasa okunamaz');
  const hd = { apikey: K, Authorization: 'Bearer ' + K };
  const hv = jsonOku(path.join(KOK, 'veri', 'seviye', 'sgs-havuz.json')).havuz || {};
  const ids = []; for (const d in hv) for (const z in hv[d]) for (const q of hv[d][z]) ids.push(q.id);
  const tum = [];   // bütün SGS kasa konu adları (sözlük için)
  for (let i = 0; ; i += 1000) {
    const r = await fetch('https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/paket_soru?select=id,konu&sinav=eq.sgs&order=id.asc&limit=1000&offset=' + i, { headers: hd });
    if (!r.ok) throw new Error('kasa okunamadı: HTTP ' + r.status); const p = await r.json(); tum.push(...p); if (p.length < 1000) break;
  }
  let okunmus = []; try { okunmus = (jsonOku(path.join(KOK, 'veri', 'sinav', 'sgs-konu-okuma.json')).konular || []).map(k => k.konu); } catch (e) {}
  const soz = sozlukKur(tum.map(x => x.konu).concat(okunmus));
  const kasa = new Map(tum.map(x => [x.id, x.konu]));
  const eksikler = new Set(); let sgsYok = 0;
  for (const id of ids) { const k = kasa.get(id); if (!k) { sgsYok++; continue; } const o = onar(k, soz); cikti.sinavlar.sgs[id] = o.ad; o.eksik.forEach(e => eksikler.add(e)); }
  cikti.onarilamayan = [...eksikler].sort((a, b) => a.localeCompare(b, 'tr'));
  console.log(`KONU ADI: Yeterlilik ${Object.keys(cikti.sinavlar.smmm).length}/${set.length} (eşlemesiz ${smmmYok}) · Staja Giriş ${Object.keys(cikti.sinavlar.sgs).length}/${ids.length} (kasada yok ${sgsYok}) · farklı SGS adı ${new Set(Object.values(cikti.sinavlar.sgs)).size} · onarılamayan kelime ${cikti.onarilamayan.length}`);
  if (kuru) { console.log('  kuru - yazılmadı'); return; }
  const yeni = JSON.stringify(cikti, null, 1) + '\n';
  const eski = fs.existsSync(HEDEF) ? fs.readFileSync(HEDEF, 'utf8') : '';
  if (eski === yeni) console.log('  değişiklik yok - dosyaya dokunulmadı'); else { fs.writeFileSync(HEDEF, yeni); console.log('  yazıldı -> veri/seviye/konu-ad.json'); }
}

function sinav() {
  let h = 0, n = 0; const b = (ad, k) => { n++; console.log((k ? '  geçti  ' : '  DÜŞTÜ  ') + ad); if (!k) h++; };
  const soz = sozlukKur(['anlatım bozukluğu', 'yazım kuralları', 'Yazım kuralları', 'noktalama işaretleri', 'öge dizilişi']);
  b('Türkçe harfsiz kelime sözlükten onarılır', onar('anlatim bozuklugu', soz).ad === 'Anlatım bozukluğu');
  b('yarım Türkçe ad tamamlanır', onar('yazım kurallari', soz).ad === 'Yazım kuralları');
  b('sözlükte olmayan doğru kelime olduğu gibi kalır', onar('belirli integral', soz).ad === 'Belirli integral');
  b('onarılamayan şüpheli kelime listelenir', onar('uslup ozgunlugu', soz).eksik.join(',') === 'uslup,ozgunlugu');
  b('en sık yazım seçilir', sozlukKur(['kuralları', 'kuralları', 'kuralları'])['kurallari'] === 'kuralları');
  b('elle okunmuş ek + kısaltma', onar('kdv istisnalari', soz).ad === 'KDV istisnaları' && onar('uslu sayılar', soz).ad === 'Üslü sayılar');
  b("Atatürk'ün eki düzelir", onar("ataturk'un eserleri", soz).ad === "Atatürk'ün eserleri");
  b('ilk harf Türkçe büyütülür', onar('işaretler', soz).ad === 'İşaretler');
  console.log(`SEVİYE KONU ADI öz-sınav: ${n - h}/${n}`); process.exitCode = h ? 1 : 0;
}

if (require.main === module) { if (process.argv.includes('--sinav')) sinav(); else ana().catch(e => { console.error('KONU ADI DÜŞTÜ: ' + e.message); process.exitCode = 1; }); }
module.exports = { sozlukKur, onar, katla };
