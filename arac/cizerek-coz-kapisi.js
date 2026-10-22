#!/usr/bin/env node
/* KAPI-CZ — "Nöbetçi çizerek çözsün" rakam/aritmetik kapısının öz-sınavı ve pilot listesi raporu (14.10.2026).
 *
 * Kapının kendisi cizerek-coz.js içinde (cizerekKapi): sitede düğme yalnız kapı geçerse çıkar.
 *   node arac/cizerek-coz-kapisi.js --sinav              öz-sınav (uydurma, bankada olmayan soru nesneleriyle; depo public)
 *   node arac/cizerek-coz-kapisi.js --sinav --mutasyon   her kilit koşulu tek tek bozulur (CIZ_MUTASYON), her bozmada sınav KIRMIZI olmalı
 *   node arac/cizerek-coz-kapisi.js --liste <paket.json> PILOT listesindeki her soruyu kapıdan geçirir. paket.json = { "<id>": { veri: {...} } }
 *                                                        (ambardan servis anahtarıyla yerelde çekilir; DEPOYA KONMAZ). Çıktıda soru metni yok.
 *
 * 🚫 GÖRMEZ: sözel kusur (adım metni yanlış kural anlatıyor ama sayılar tutuyor) · adım sırasının mantığı · birimli
 *   ifade ("5 kilogram × 18 ₺/kilogram") hesaplanmaz · kelimeli işlem ("3 Mart + 10 gün") hesaplanmaz · yalnız 3 haneli
 *   tam sayılardan oluşan toplam ("151 + 152 + 620") hesap kodu sayılır, denetlenmez · alt yazının anlamı.
 */
'use strict';
const path = require('path');
const { spawnSync } = require('child_process');
const C = require(path.join(__dirname, '..', 'cizerek-coz.js'));
const a = process.argv.slice(2);

/* Uydurma soru: bankadaki hiçbir soruyla aynı değildir (kural: depoya soru içeriği girmez). */
function soru(d) {
  return Object.assign({
    id: 'sinav/kp-01', soru: 'Bir işletme 1.03.2026 tarihinde 12 aylık 48.000 ₺ sigorta primini peşin ödemiş ve tamamını gider yazmıştır. 2026 yılı kârı kaç ₺ düşük gösterilmiştir?',
    siklar: { A: '8.000', B: '12.000', C: '40.000', D: '48.000', E: '36.000' }, dogru: 'A',
    adimlar: [
      { verilenAdim: true, formul: 'Verilen: prim 48.000 (soruda verilen); süre 12 ay (soruda verilen)', anlatim: 'Soru bize 48.000 ₺ primi ve 12 ayı vermiş.' },
      { formul: 'Aylık pay = 48.000 / 12 = 4.000', anlatim: 'Önce aylık payı buluyoruz.' },
      { formul: 'Cari dönem payı = 4.000 × 10 = 40.000', anlatim: 'Mart-aralık 10 ay.' },
      { formul: 'Fazla gider = 48.000 − 40.000 = 8.000 (3. adımda bulduk)', anlatim: 'Kâr bu kadar düşük gösterilmiştir.' },
      { formul: 'Yanlış yol: 48.000 − 36.000 = 12.000 (HATALI)', anlatim: 'Ay sayısını karıştırma.' }
    ],
    celdiriciYol: { B: '48.000 / 4 = 12.000 (çeyrek dönem sandın)', C: '4.000 × 10 = 40.000 (cari payı fark sandın)', D: '48.000 − 0 = 48.000 (hiç bölmedin)', E: '4.000 × 9 = 36.000 (ay sayısını eksik saydın)' },
    teshis: {}
  }, d || {});
}
function kopya(o) { return JSON.parse(JSON.stringify(o)); }

function sinav() {
  const hata = [], v = [];
  const kos = (ad, s, bekle, kod) => { const r = C.cizerekKapi(s); const ok = bekle ? r.gecer : (!r.gecer && r.neden.some(n => n.indexOf(kod) === 0)); v.push(ad); if (!ok) hata.push(ad + ' -> ' + (r.gecer ? 'GEÇTİ' : r.neden.join(' | '))); return r; };
  // 1) temiz soru geçer (yanlış alarm yok)
  const r1 = kos('temiz hesap sorusu geçer', soru(), true);
  if (r1.gecer) {
    const yz = r1.senaryo.sahne.filter(x => x.tur === 'yaz').map(x => x.satirlar.join(' | '));
    if (yz.join(' ').indexOf('adımda bulduk') >= 0) hata.push('sadeleştirme: "(N. adımda bulduk)" karalamaya sızdı');
    if (yz.some(x => /Yanlış yol/.test(x))) hata.push('"Yanlış yol" adımı karalamaya yazıldı');
    if (!r1.senaryo.sahne.some(x => x.tur === 'yaz' && x.son && /8\.000$/.test(x.satirlar[x.satirlar.length - 1]))) hata.push('doğru sonuç satırı yeşil (son) işaretlenmedi');
    v.push('sadeleştirme + son satır');
  }
  // 2) karalamada kaynakta olmayan sayı (dizici hatası benzetimi) -> RAKAM
  { const s = soru(); const sen = C.senaryo(s); sen.sahne.find(x => x.tur === 'yaz').satirlar[0] = 'Aylık pay = 48.000 / 12 = 4.100'; const r = C.cizerekKapi(s, sen); v.push('kaynakta olmayan sayı'); if (r.gecer || !r.neden.some(n => /^RAKAM/.test(n))) hata.push('kaynakta olmayan sayı -> ' + (r.gecer ? 'GEÇTİ' : r.neden.join(' | '))); }
  // 3) şık notunda kaynakta olmayan sayı -> RAKAM
  { const s = soru(); const sen = C.senaryo(s); sen.sahne.find(x => x.tur === 'karala' && x.not).not = '48.000 / 5 = 9.600'; const r = C.cizerekKapi(s, sen); v.push('notta kaynakta olmayan sayı'); if (r.gecer || !r.neden.some(n => /^RAKAM/.test(n))) hata.push('notta kaynakta olmayan sayı -> ' + (r.gecer ? 'GEÇTİ' : r.neden.join(' | '))); }
  // 4) adım hesabı tutmuyor -> ARITMETIK
  { const s = soru(); s.adimlar[2].formul = 'Cari dönem payı = 4.000 × 10 = 44.000'; s.siklar.C = '44.000'; kos('adım hesabı tutmuyor', s, false, 'ARITMETIK'); }
  // 5) çeldirici yolu hesabı tutmuyor -> ARITMETIK
  { const s = soru(); s.celdiriciYol.E = '4.000 × 9 = 38.000 (ay sayısını eksik saydın)'; kos('çeldirici hesabı tutmuyor', s, false, 'ARITMETIK'); }
  // 6) iç eşitlik yanlış: "(500 x 25 = 12.000)" -> ARITMETIK
  { const s = soru(); s.celdiriciYol.D = '30.000 + (500 x 25 = 12.000) = 42.000 (yanlış saat)'; s.siklar.D = '42.000'; kos('iç eşitlik yanlış', s, false, 'ARITMETIK'); }
  // 7) doğru şıkkın sayısı karalamada yok -> DOGRU
  { const s = soru(); s.dogru = 'E'; kos('çözüm doğru şıkka varmıyor', s, false, 'DOGRU'); }
  // 8) sözel soru (sayılı çözüm adımı 1) -> SOZEL
  { const s = soru(); s.adimlar = [s.adimlar[0], { formul: 'Kural: peşin giderin gelecek döneme ait kısmı 180 hesabına alınır', anlatim: '' }, s.adimlar[3]]; kos('sözel soru', s, false, 'SOZEL'); }
  // 9) veri eksik -> VERI
  { const s = soru(); delete s.dogru; kos('doğru harf yok', s, false, 'VERI'); }
  // 10) hesap kodu dizisi yanlış alarm vermez
  { const s = soru(); s.adimlar.splice(1, 0, { formul: 'Toplam = 151 + 152 = 40.000 + 8.000 = 48.000', anlatim: '' }); kos('hesap kodu dizisi (151 + 152) yanlış alarm yok', s, true); }
  // 11) yuvarlanmış yüzde yanlış alarm vermez
  { const s = soru(); s.adimlar.splice(1, 0, { formul: 'Oran: 40.000 / 48.000 = %83,33; Pay: 9.600 × %83,33 = 8.000', anlatim: '' }); kos('yuvarlanmış yüzde (%83,33) yanlış alarm yok', s, true); }
  // 12) doğrulanamayan sayılı alt yazı yazılmaz ama soru düşmez
  { const s = soru(); s.adimlar[1].anlatim = 'Aylık pay 4.000; 2025 yılında 3.500 idi.'; const r = kos('doğrulanamayan alt yazı düşer, soru geçer', s, true); if (r.gecer && r.senaryo.sahne.some(x => /3\.500/.test(x.alt || ''))) hata.push('doğrulanamayan alt yazı ekrana çıkıyor'); }
  // 13) "X nedir?" ile başlayan anlatım alt yazı olmaz
  { const s = soru(); s.adimlar[1].anlatim = '180 Gelecek Aylara Ait Giderler nedir? Peşin ödenen gideri taşır.'; const r = C.cizerekKapi(s); v.push('"nedir?" alt yazısı düşer'); if (!r.gecer || r.senaryo.sahne.some(x => /nedir|Peşin ödenen/.test(x.alt || ''))) hata.push('"nedir?" anlatımı alt yazıya çıktı'); }
  // 14) tanım adımı (yalnız hesap kodu) karalamaya yazılmaz
  { const s = soru(); s.adimlar.splice(1, 0, { formul: '180 Gelecek Aylara Ait Giderler nedir?', anlatim: '' }); const r = C.cizerekKapi(s); v.push('tanım adımı yazılmaz'); if (!r.gecer || r.senaryo.sahne.some(x => x.satirlar && x.satirlar.some(y => /nedir/.test(y)))) hata.push('tanım adımı karalamaya yazıldı'); }
  // 15) çeldirici: not + neden ayrımı
  { const b = C.celdiriciBol('(280.000 + 20.000) x %20 = 60.000 (sigortayı maliyete kattın)'); v.push('çeldirici not/neden ayrımı'); if (b.not !== '(280.000 + 20.000) x %20 = 60.000' || b.neden !== 'sigortayı maliyete kattın') hata.push('çeldirici ayrımı: ' + JSON.stringify(b)); }
  // 16) prova listesi: cizerek-coz.js PROVA = radar-app/sql/2026-10-15-prova-cizim.sql izin listesi (biri değişip öteki kalırsa
  //     sitede düğme çıkar ama sunucu boş döner, ya da tersi)
  {
    const fs = require('fs'); const sql = fs.readFileSync(path.join(__dirname, '..', 'radar-app', 'sql', '2026-10-15-prova-cizim.sql'), 'utf8');
    const s = new Set((sql.match(/'smmm-[^']+'|'sgs-[^']+'/g) || []).map(x => x.slice(1, -1)));
    let j = (C.PROVA && C.PROVA['YET-2410']) || []; if (process.env.CIZ_MUTASYON === 'provaliste') j = j.concat(['sgs-uydurma/kp-01']);
    v.push('prova listesi JS = SQL'); if (!j.length || j.length !== s.size || !j.every(x => s.has(x))) hata.push('prova listesi JS (' + j.length + ') ile SQL (' + s.size + ') farklı');
    if (C.PROVA && C.PROVA['SGS-1710']) hata.push('SGS-1710 prova listesinde: 17.10 akışına dokunulmaz');
  }
  // ---- SÖZEL ŞABLON (20.10.2026) — uydurma sorular, bankada yok ----
  const oncul = (d) => Object.assign({
    id: 'sgs-uydurma/kp-02', soru: 'Bir sözleşmeyle ilgili aşağıdaki durumlar veriliyor:\nI. Taraflardan biri ehliyetsizdir.\nII. Sözleşme yazılı yapılmıştır.\nIII. Konusu imkânsızdır.\nBu durumlardan hangilerinde sözleşme geçersizdir?',
    siklar: { A: 'Yalnız I', B: 'Yalnız III', C: 'I ve II', D: 'I ve III', E: 'II ve III' }, dogru: 'D',
    adimlar: [{ formul: 'I: ehliyetsiz taraf → kurulamaz', anlatim: 'Ehliyet yoksa sözleşme geçersizdir.' }, { formul: 'II: yazılı şekil → şart yerine gelmiş', anlatim: 'Şekil tamam; sözleşme ayakta.' },
      { formul: 'III: imkânsız konu → batıl', anlatim: 'Konu imkânsızsa geçersizdir.' }, { formul: 'Sonuç = I ve III', anlatim: 'Geçersizlik yalnız I ve III.' }],
    taktik: 'Her öncülde kuruluş şartını sor.', hap: 'Ehliyetsizlik ve imkânsız konu sözleşmeyi geçersiz kılar.',
    tuzak: { A: { ad: 'Eksik Tuzak', metin: 'Yalnız ehliyeti gördün.' }, B: { ad: 'Konu Tuzağı', metin: 'Yalnız konuyu gördün.' }, C: { ad: 'Şekil Tuzağı', metin: 'Yazılı şekli geçersizlik sandın.' }, E: { ad: 'Ters Tuzak', metin: 'Ehliyeti atladın.' } }
  }, d || {});
  const duz = (d) => Object.assign({
    id: 'smmm-uydurma/kp-03', soru: 'Bir şirketin yöneticilerine karşı açılacak ceza davasında 6362 sayılı Kanun uyarınca görevli mahkeme hangisidir?',
    siklar: { A: 'İdare mahkemeleri', B: 'Ticaret mahkemeleri', C: 'Ağır ceza mahkemeleri', D: 'Asliye ceza mahkemeleri', E: 'Sulh hukuk mahkemeleri' }, dogru: 'D',
    adimlar: [{ formul: 'Ne yapacağız: kuralı bul', anlatim: '' }], taktik: 'Görev kuralını ara.',
    hap: '6362 sayılı Kanun uyarınca ceza davasında görevli mahkeme asliye ceza mahkemeleridir.',
    tuzak: { A: { ad: 'İdari Yol Tuzağı', metin: 'İdari yolu ceza yargılaması sandın.' }, B: { ad: 'Ticaret Tuzağı', metin: 'Ticari uyuşmazlıkla karıştırdın.' }, C: { ad: 'Ağırlık Tuzağı', metin: 'Suçun ağırlığına baktın.' }, E: { ad: 'Hukuk Tuzağı', metin: 'Hukuk davası sandın.' } }
  }, d || {});
  const sz = (ad, s, bekle, kod) => { const r = C.cizimKapi(s); const ok = bekle ? r.gecer : (!r.gecer && r.neden.some(n => n.indexOf(kod) === 0)); v.push(ad); if (!ok) hata.push(ad + ' -> ' + (r.gecer ? 'GEÇTİ' : r.neden.join(' | '))); return r; };
  // 17) öncüllü sözel soru geçer, ✓ kümesi doğru
  { const r = sz('sözel öncüllü geçer', oncul(), true); if (r.gecer && r.senaryo.bicim !== 'ONCUL') hata.push('öncüllü soru ONCUL biçimine girmedi'); }
  // 18) sonuç satırı doğru şıkla tutmuyor -> SZ-SONUC
  { const s = oncul(); s.adimlar[3].formul = 'Sonuç = I ve II'; sz('sonuç satırı ≠ doğru şık', s, false, 'SZ-SONUC'); }
  // 19) öncül anlatımı ✓ kümesini bozuyor -> SZ-ONCUL
  { const s = oncul(); s.adimlar[1].anlatim = 'Şekil tamam ama yine de geçersiz sayılır.'; sz('✓ kümesi ≠ doğru şık', s, false, 'SZ-ONCUL'); }
  // 20) kökteki bir öncülün satırı yok -> SZ-ONCUL
  { const s = oncul(); s.adimlar.splice(1, 1); sz('öncül satırı eksik', s, false, 'SZ-ONCUL'); }
  // 21) düz sözel soru geçer
  { const r = sz('sözel düz (hap) geçer', duz(), true); if (r.gecer && r.senaryo.bicim !== 'DUZ') hata.push('düz soru DUZ biçimine girmedi'); }
  // 22) hap doğru şıkkı anmıyor -> SZ-DOGRU
  { const s = duz(); s.hap = '6362 sayılı Kanun uyarınca ceza davasına özel görevli mahkeme bakar.'; sz('hap doğru şıkkı anmıyor', s, false, 'SZ-DOGRU'); }
  // 23) hap iki şıkkı birden anıyor -> SZ-CIFT
  { const s = duz(); s.hap = '6362 sayılı Kanun uyarınca ceza davasına ağır ceza mahkemeleri değil asliye ceza mahkemeleri bakar.'; sz('hap iki şıkkı anıyor', s, false, 'SZ-CIFT'); }
  // 24) hapta soruda olmayan sayı -> SZ-RAKAM
  { const s = duz(); s.hap = '6362 sayılı Kanunun 116. maddesi uyarınca görevli mahkeme asliye ceza mahkemeleridir.'; sz('hapta kaynakta olmayan sayı', s, false, 'SZ-RAKAM'); }
  // 25) yanlış şıkkın nedeni yok -> SZ-NEDEN
  { const s = duz(); delete s.tuzak.B; sz('yanlış şıkta neden yok', s, false, 'SZ-NEDEN'); }
  // 26) sayısal kapıdan RAKAM ile dönen soru sözel şablonla KURTARILMAZ
  { /* sözel şablonun TÜM şartlarını sağlayan ama sayısal kapıdan RAKAM+SOZEL ile dönen soru: kurtarma kapalıysa düşer (mutasyon szkurtar) */
    const s = soru({ tuzak: { B: { ad: 'x', metin: 'Çeyrek sandın.' }, C: { ad: 'x', metin: 'Cari payı fark sandın.' }, D: { ad: 'x', metin: 'Hiç bölmedin.' }, E: { ad: 'x', metin: 'Ay eksik.' } } });
    s.adimlar[1].formul = 'Aylık pay = 48.000 / 12 = 4.100'; s.adimlar = s.adimlar.slice(0, 2); s.siklar.A = 'Fazla gider'; s.hap = 'Fazla gider olur; tamamını gider yazmıştır.';
    const r = C.cizimKapi(s); v.push('sayılı soru sözelle kurtarılmaz'); if (r.gecer) hata.push('RAKAM ile dönen soru sözel şablonla GEÇTİ'); }
  // 27) sayısal soru sayısal kalır (sözel şablona düşmez)
  { const r = C.cizimKapi(soru()); v.push('sayısal soru sayısal şablonda'); if (!r.gecer || r.senaryo.bicim) hata.push('temiz sayısal soru sözel şablona düştü'); }

  // ---- KGK EKİ (22.10.2026) — uydurma KGK biçimli sorular, bankada yok ----
  // öncül hükmü "I:" satırında değil: "Bu olayda: …" + tuzak metni; kök öncüllerin ÜSTÜNDE
  const kgkO = (d) => Object.assign({
    id: 'kgk-uydurma/kp-01',
    soru: '(K) A.Ş. genel kurul toplantısı yapmaktadır; gündemde özellik arz eden bir konu yoktur. Uydurma Tebliğe göre aşağıdaki ifadelerden hangileri doğrudur?\nI. Toplantı tutanağı imzalanır.\nII. Pay sahipleri soru sorabilir.\nIII. Hazır bulunanlar listesi düzenlenir.\nIV. Toplantı gizli yapılır ve sonuç açıklanmaz.',
    siklar: { A: 'I ve II', B: 'I ve III', C: 'I, II ve III', D: 'II ve III', E: 'I, II, III ve IV' }, dogru: 'C',
    dayanak: 'İlke 7.7.1: Toplantı tutanağı imzalanır ve hazır bulunanlar listesi düzenlenir.',
    adimlar: [{ verilenAdim: true, formul: 'Soruda ne var: dört öncül · istenen: doğru olanlar', anlatim: 'Her öncülü ayrı sına.' },
      { formul: 'Kural: tutanak imzalanır, liste düzenlenir, soru sorulabilir; toplantı açıktır', anlatim: 'Gizlilik kuralı yoktur.' },
      { formul: 'Bu olayda: I doğru · II doğru · III doğru · IV yanlış', anlatim: 'Doğru küme I, II ve III.' },
      { formul: 'Doğru şık: I, II ve III', anlatim: 'Doğru cevap: I, II ve III.' }],
    hap: 'Genel kurul açık yapılır; tutanak ve liste şarttır.', taktik: 'Gizlilik diyen öncülü önce sına.',
    tuzak: { A: { ad: 'Eksik Öncül Tuzağı', metin: 'III de doğrudur; İlke 7.7.1 gereği hazır bulunanlar listesi düzenlenir. Doğrusu: I, II ve III.' },
      B: { ad: 'Soru Hakkı Tuzağı', metin: 'II de doğrudur. Pay sahibi toplantıda soru sorabilir.' },
      D: { ad: 'Tutanak Tuzağı', metin: 'I de doğrudur; tutanak imzalanır.' },
      E: { ad: 'Gizlilik Tuzağı', metin: 'IV yanlıştır; toplantı açıktır ve sonuç duyurulur.' } },
    teshis: { C: { gercek: 'I, II ve III doğru; IV yanlış.', yanilgi: 'IV doğru sanılır.' } }
  }, d || {});
  // 28) KGK öncüllü soru HUKUM biçiminde geçer; ✓ kümesi öncül kararlarından; altı çizilen kökteki soru öbeği (öncül satırı değil)
  { const r = sz('KGK öncüllü (HUKUM) geçer', kgkO(), true);
    if (r.gecer) {
      if (r.senaryo.bicim !== 'HUKUM') hata.push('KGK öncüllü soru HUKUM biçimine girmedi: ' + r.senaryo.bicim);
      const al = r.senaryo.sahne[0].hedef.join('|'); if (al !== 'hangileri doğrudur') hata.push('HUKUM altı çizilen öbek: "' + al + '" (beklenen "hangileri doğrudur")');
      const iv = r.senaryo.sahne.find(x => x.oncul === 'IV'); if (!iv || !/IV → yanlış ✗/.test(iv.satirlar[0])) hata.push('IV satırı yanlış ✗ değil');
      const iii = r.senaryo.sahne.find(x => x.oncul === 'III'); if (!iii || !/7\.7\.1/.test(iii.alt)) hata.push('III gerekçesi dayanaktaki ilke numarasıyla gelmedi: ' + (iii && iii.alt));
      const ii = r.senaryo.sahne.find(x => x.oncul === 'II'); if (!ii || !/soru sorabilir/.test(ii.alt)) hata.push('"II de doğrudur." çıplak hükmüne nedeni taşıyan sonraki cümle eklenmedi: ' + (ii && ii.alt));
      if (r.senaryo.sahne.some(x => x.oncul && /Bu olayda/.test(x.alt))) hata.push('"Bu olayda: I doğru · II doğru…" satırı öncül gerekçesi olarak tekrarlandı');
    } }
  // 29) aynı öncüle hem doğru hem yanlış -> SZ-HUKUM
  { const s = kgkO(); s.adimlar[2].formul = 'Bu olayda: I doğru · II doğru · III doğru · IV doğru'; sz('öncüle çelişkili hüküm', s, false, 'SZ-HUKUM'); }
  // 30) kökteki öncülün hükmü hiçbir alanda yok -> SZ-HUKUM
  { const s = kgkO(); s.adimlar[2].formul = 'Bu olayda: I doğru · III doğru · IV yanlış'; s.tuzak.B.metin = 'Pay sahibi toplantıda soru sorabilir.'; s.teshis.C.gercek = 'Küme üç öncüllüdür.'; sz('öncül hükmü yok', s, false, 'SZ-HUKUM'); }
  // 31) öncül kararları tutarlı ama doğru şık başka küme -> SZ-SONUC (32: aynı soruda SZ-ONCUL)
  { const s = kgkO({ dogru: 'B' }); sz('kurulan küme ≠ doğru şık (SONUC)', s, false, 'SZ-SONUC'); sz('kurulan küme ≠ doğru şık (ONCUL)', kgkO({ dogru: 'B' }), false, 'SZ-ONCUL'); }
  // 33) olumsuz kök: ✓ = yanlış öncüller
  { const s = kgkO({ soru: kgkO().soru.replace('hangileri doğrudur?', 'hangileri yanlıştır?'), siklar: { A: 'Yalnız IV', B: 'I ve IV', C: 'II ve IV', D: 'III ve IV', E: 'I, II ve III' }, dogru: 'A' });
    s.tuzak = { B: { ad: 'x', metin: 'I doğrudur; tutanak imzalanır ve saklanır.' }, C: { ad: 'x', metin: 'II doğrudur; pay sahibi soru sorabilir.' }, D: { ad: 'x', metin: 'III doğrudur; liste düzenlenir.' }, E: { ad: 'x', metin: 'IV yanlıştır; toplantı açıktır ve sonuç duyurulur.' } };
    const r = sz('olumsuz kökte ✓ = yanlış öncül', s, true); if (r.gecer && !/Yalnız IV/.test(r.senaryo.sahne.find(x => x.etiket === 'Sonuç').satirlar[0])) hata.push('olumsuz kök sonucu Yalnız IV değil'); }
  // 34) "doğru değildir" = yanlış
  { const s = kgkO(); s.adimlar[2].formul = 'Bu olayda: I doğru · II doğru · III doğru · IV doğru değildir'; sz('"doğru değildir" yanlış sayılır', s, true); }
  // 35) "yanlış sanılır" / "yanlış saydın" hüküm değildir (yanlış alarm yok)
  { const s = kgkO(); s.tuzak.B.metin = 'II yanlış sanılır; oysa II de doğrudur ve pay sahibi soru sorabilir.'; sz('"yanlış sanılır" hüküm sayılmaz', s, true); }
  // 36) "Yanlış yol: … IV de doğru sayılır (HATALI)" hüküm değildir
  { const s = kgkO(); s.adimlar.splice(3, 0, { formul: 'Yanlış yol: gizliliği kural sanmak → IV de doğru → I, II, III ve IV (HATALI)', anlatim: '' }); sz('"Yanlış yol" satırı hüküm sayılmaz', s, true); }
  // 37) KGK öncülsüz ifade sorusu SIK biçiminde geçer; altı çizilen öbek SORU cümlesinden (senaryodaki "değildir" değil)
  const kgkS = (d) => Object.assign({
    id: 'kgk-uydurma/kp-02',
    soru: 'Uydurma Ltd. halka açık değildir ve denetçisi ilk kez atanmıştır. Uydurma Standarda göre aşağıdakilerden hangisi doğrudur?',
    siklar: { A: 'Denetçi önceki yılın tablolarını hiç incelemeden görüş verebilir.', B: 'Denetçi açılış bakiyeleri için yeterli ve uygun kanıt elde eder.', C: 'Açılış bakiyeleri denetimin konusu dışında kalır.', D: 'Önceki denetçiyle iletişim kurmak yasaktır.', E: 'İlk denetimde önemlilik belirlenmez.' }, dogru: 'B',
    hap: 'İlk denetimde açılış bakiyeleri için yeterli ve uygun kanıt aranır.', taktik: 'İlk denetimde açılış bakiyesini ara.',
    adimlar: [{ verilenAdim: true, formul: 'Soruda ne var: ilk denetim', anlatim: '' }, { formul: 'Kural: açılış bakiyeleri için kanıt elde edilir', anlatim: '' }],
    tuzak: { A: { ad: 'İnceleme Tuzağı', metin: 'Önceki dönem tabloları okunur.' }, C: { ad: 'Kapsam Tuzağı', metin: 'Açılış bakiyeleri kapsamdadır.' }, D: { ad: 'İletişim Tuzağı', metin: 'Önceki denetçinin çalışma kâğıtları okunabilir.' }, E: { ad: 'Önemlilik Tuzağı', metin: 'Önemlilik her denetimde belirlenir.' } },
    teshis: { B: { gercek: 'Açılış bakiyeleri için yeterli ve uygun denetim kanıtı elde edilir.' } }
  }, d || {});
  { const r = sz('KGK öncülsüz ifade sorusu (SIK) geçer', kgkS(), true);
    if (r.gecer) { if (r.senaryo.bicim !== 'SIK') hata.push('ifade sorusu SIK biçimine girmedi: ' + r.senaryo.bicim);
      const al = r.senaryo.sahne[0].hedef.join('|'); if (al !== 'hangisi doğrudur') hata.push('SIK altı çizilen öbek: "' + al + '" (beklenen "hangisi doğrudur")'); } }
  // 38) şıkkın açıklaması s.dogru ile çelişiyor -> SZ-CELISKI
  { const s = kgkS(); s.tuzak.A.ad = 'Doğru ifade'; sz('tuzak adı "Doğru ifade" ama şık yanlış', s, false, 'SZ-CELISKI'); }
  { const s = kgkS({ soru: kgkS().soru.replace('hangisi doğrudur?', 'hangisi yanlıştır?'), dogru: 'C' }); s.tuzak = { A: { ad: 'x', metin: 'Bu ifade yanlıştır; inceleme şarttır.' }, B: { ad: 'Doğru ifade', metin: 'Kanıt aranır.' }, D: { ad: 'x', metin: 'İletişim serbesttir.' }, E: { ad: 'x', metin: 'Önemlilik belirlenir.' } }; s.teshis = { C: { gercek: 'Açılış bakiyeleri denetim kapsamındadır.' } };
    sz('olumsuz kökte "bu ifade yanlıştır" diyen yanlış şık', s, false, 'SZ-CELISKI'); }
  // 38b) "yanlışlık / aykırılık" kökü olumsuz yapmaz: olumlu kökte "Yanlış ifade" adlı yanlış şık çelişki DEĞİL
  { const s = kgkS({ soru: 'Uydurma Standarda göre yanlışlık riskiyle ilgili aşağıdakilerden hangisi doğrudur?' }); s.tuzak.A.ad = 'Yanlış ifade'; sz('"yanlışlık" kökü olumsuz yapmaz', s, true); }
  // 39) DUZ: hap doğru şıkkı anmıyorsa doğru şıkkı AYNEN anan cümle (teshis[doğru].gercek) kural olur
  { const s = duz(); s.hap = '6362 sayılı Kanun ceza davasına özel bir görev kuralı koyar.'; s.teshis = { D: { gercek: 'Görevli mahkeme asliye ceza mahkemeleridir.' } };
    const r = sz('DUZ: kural cümlesi teşhisten', s, true); if (r.gecer && !/asliye ceza/.test(r.senaryo.sahne.find(x => x.tur === 'yaz').satirlar[0])) hata.push('DUZ kural cümlesi teşhisten gelmedi'); }
  // 40) "Doğru cevap: X" kural sayılmaz -> SZ-DOGRU
  { const s = duz(); s.hap = '6362 sayılı Kanun ceza davasına özel bir görev kuralı koyar.'; s.adimlar.push({ formul: 'Doğru cevap: Asliye ceza mahkemeleri', anlatim: '' }); sz('"Doğru cevap:" satırı kural sayılmaz', s, false, 'SZ-DOGRU'); }
  // 41) sayı şıkkı: kural "%20"yi de anıyorsa iki şık birden -> SZ-CIFT; "%200" "%20" sayılmaz
  const yuz = (hap) => ({ id: 'kgk-uydurma/kp-03', soru: 'Uydurma Tebliğe göre, toplam %200 kaldıraç sınırından ayrı olarak, tek ihraççı sınırı yüzde kaçtır?', siklar: { A: '%5', B: '%10', C: '%20', D: '%25', E: '%35' }, dogru: 'B', hap: hap, adimlar: [],
    tuzak: { A: { ad: 'x', metin: 'Başka bendin oranı.' }, C: { ad: 'x', metin: 'Grup sınırı.' }, D: { ad: 'x', metin: 'İstisna oranı.' }, E: { ad: 'x', metin: 'Kamu istisnası.' } } });
  sz('sayı şıkkı: kural iki oranı anıyor', yuz('Tek ihraççı sınırı %10, grup sınırı %20 olarak uygulanır.'), false, 'SZ-CIFT');
  sz('sayı şıkkı: %200 ≠ %20 (yanlış alarm yok)', yuz('Tek ihraççı sınırı %10 olup toplam %200 kaldıraç ayrı hesaplanır.'), true);
  // 42) SZ-ALT: altı çizilecek ifade kökte yoksa
  { const s = kgkS(); const sen = C.sozelSenaryo(s, 'SIK'); sen.sahne[0].hedef = ['kökte olmayan öbek']; const r = C.sozelKapi(s, sen); v.push('altı çizilen öbek kökte yok'); if (r.gecer || !r.neden.some(n => /^SZ-ALT/.test(n))) hata.push('kökte olmayan öbek -> ' + (r.gecer ? 'GEÇTİ' : r.neden.join(' | '))); }
  // 43) düğme adayı: PILOT kimliği ya da kgk- öneki (KGK_DIS hariç); öteki sınavlarda liste dışı soru düğme almaz
  { v.push('düğme adayı kuralı'); const p = {}; p['sgs-pilot/kp-01'] = 1;
    if (!C.dugmeAday('kgk-uydurma/kp-01', p)) hata.push('kgk- önekli soru düğme adayı değil');
    if (C.dugmeAday('sgs-uydurma/kp-09', p) || C.dugmeAday('smmm-uydurma/kp-09', p)) hata.push('PILOT dışı SGS/Yeterlilik sorusu düğme adayı oldu');
    if (!C.dugmeAday('sgs-pilot/kp-01', p)) hata.push('PILOT kimliği düğme adayı değil');
    C.KGK_DIS.push('kgk-dislanan/kp-01'); if (C.dugmeAday('kgk-dislanan/kp-01', p)) hata.push('KGK_DIS kimliği düğme adayı oldu'); C.KGK_DIS.pop(); }
  // 44) SESLİ ÇİZİM tablosu (22.10): yapı + herkese açık örnek sayfalardaki (kaydir/vitrin/ornek-*.html, depoda zaten açık) gerçek
  //     senaryoyla sahne sayısı. Tablo kayarsa sitede ses KAPANIR (çizim sessiz) — bu vaka kaymayı yayından önce yakalar.
  { v.push('ses tablosu = örnek sayfa senaryosu'); const fs = require('fs'); const S = C.SES || {}; const kim = Object.keys(S);
    if (kim.length < 10) hata.push('ses tablosunda ' + kim.length + ' soru (10 beklenir)');
    const bul = {}; for (const f of ['ornek-sgs', 'ornek-smmm']) { const t = (fs.readFileSync(path.join(__dirname, '..', 'kaydir', 'vitrin', f + '.html'), 'utf8').split('\n').find(x => x.includes('const SORULAR=')) || ''); const i0 = t.indexOf('['); if (i0 < 0) continue; let d = 0, i = i0; for (; i < t.length; i++) { if (t[i] === '[') d++; else if (t[i] === ']') { d--; if (!d) break; } } JSON.parse(t.slice(i0, i + 1)).forEach(q => { bul[q.id] = q; }); }
    for (const id of kim) { const e = S[id];
      if (e.d !== id.replace(/[^a-z0-9]+/gi, '-').replace(/-+$/, '')) hata.push('ses klasör adı kimlikten türemiyor: ' + id);
      if (e.b.length !== e.s.length || e.b.some((x, i) => i && x <= e.b[i - 1]) || e.b[e.b.length - 1] !== e.n - 1) hata.push('ses eşlemesi bozuk: ' + id);
      if (!fs.existsSync(path.join(__dirname, '..', 'ses', 'cizim', e.d, 'r' + e.b.length + '.mp3'))) hata.push('ses dosyası yok: ' + e.d);
      const q = bul[id]; if (!q) { hata.push('ses tablosundaki soru örnek sayfada yok: ' + id); continue; }
      const r = C.cizimKapi(q); if (!r.gecer || r.senaryo.sahne.length !== e.n) hata.push('ses tablosu senaryodan kaydı: ' + id + ' (tablo ' + e.n + ', senaryo ' + (r.senaryo ? r.senaryo.sahne.length : 'yok') + ')'); } }
  // 45) KGK SES KASASI (22.10): KGK sesi paketli — sitede DOSYASI OLMAZ, adres yalnız imzalı (sesKaynak kasa kaydında herkese açık
  //     yola asla düşmez), tablo yapısı tutarlı, kesik cümle yok (≥0,9 sn; 22.10'da "Doğru cevap D" 0,67 sn'de kesik çıktı),
  //     göç kovayı KAPALI kurar ve politikayı paket kuralına bağlar. Senaryo kıyası kasa verisiyle: --kgk <paket.json>.
  { v.push('KGK ses kasası'); const fs = require('fs'); const K = C.SES_KASA || {}, kim = Object.keys(K);
    if (kim.length < 10) hata.push('ses kasası tablosunda ' + kim.length + ' soru (10 beklenir)');
    for (const id of kim) {
      const e = K[id];
      if (!/^kgk-/.test(id)) hata.push('ses kasasında KGK dışı soru: ' + id);
      if (C.SES && C.SES[id]) hata.push('soru hem açık hem kasa ses tablosunda: ' + id);
      if (e.d !== id.replace('/', '__') || /[~\s]/.test(e.d)) hata.push('kasa klasör adı kimlikten türemiyor: ' + id);
      if (e.b.length !== e.n || e.b.some((x, i) => x !== i) || e.s.length !== e.n) hata.push('kasa ses eşlemesi bozuk (her sahne bir cümle): ' + id);
      if (e.s.some(x => !(x >= 0.9))) hata.push('kesik cümle (<0,9 sn): ' + id + ' r' + (e.s.findIndex(x => !(x >= 0.9)) + 1));
      if (fs.existsSync(path.join(__dirname, '..', 'ses', 'cizim', id.replace(/[^a-z0-9]+/gi, '-').replace(/-+$/, '')))) hata.push('PAKETLİ SES SİTEDE AÇIK: ses/cizim/… ' + id);
      if (C.sesKaynak(e, 0, '../../') !== null) hata.push('imzasız kasa kaydı ses adresi verdi: ' + id);
      if (C.sesKaynak(Object.assign({}, e, { u: ['https://imzali/x'] }), 0, '../../') !== 'https://imzali/x') hata.push('imzalı adres kullanılmıyor: ' + id);
      if (C.kasaYollari(e).length !== e.n || C.kasaYollari(e)[0] !== e.d + '/r1.mp3') hata.push('kasa yolu biçimi bozuk: ' + id);
    }
    const sql = path.join(__dirname, '..', 'radar-app', 'sql', '2026-10-22-cizim-ses-paket-kasasi.sql');
    if (!fs.existsSync(sql)) hata.push('ses kasası göçü yok');
    else { const t = fs.readFileSync(sql, 'utf8'), kod = t.replace(/--.*$/gm, '');
      if (!/values \('cizim-ses-paket', 'cizim-ses-paket', false/.test(kod) || !/set public = false/.test(kod)) hata.push('göç kovayı kapalı kurmuyor');
      if (!/for select to authenticated/.test(kod) || /\bto (anon|public)\b/.test(kod)) hata.push('göç politikası anon/public okutuyor ya da authenticated değil');
      if (!/paket_erisim_var\(s\.sinav, s\.ders\)/.test(kod) || kod.indexOf("replace((storage.foldername(name))[1], '__', '/')") < 0) hata.push('göç politikası paket kuralına / klasör biçimine bağlı değil');
      if (C.KOVA !== 'cizim-ses-paket') hata.push('JS kova adı göçle aynı değil'); } }
  const mut = process.env.CIZ_MUTASYON ?' (MUTASYON: ' + process.env.CIZ_MUTASYON + ')' : '';
  if (hata.length) { console.log('KAPI-CZ ÖZ-SINAV DÜŞTÜ' + mut + ': ' + hata.length + '/' + v.length); hata.forEach(h => console.log('  - ' + h)); return 1; }
  console.log('KAPI-CZ ÖZ-SINAV TEMİZ' + mut + ': ' + v.length + ' vaka'); return 0;
}

if (a.includes('--sinav')) {
  let kod = sinav();
  if (kod === 0 && a.includes('--mutasyon') && !process.env.CIZ_MUTASYON) {
    const M = ['rakam', 'aritmetik', 'dogru', 'sozel', 'hesapkodu', 'altyazi', 'provaliste', 'szsonuc', 'szoncul', 'szdogru', 'szcift', 'szrakam', 'szneden', 'szkurtar',
      'szhukum', 'szdegil', 'szsan', 'szyol', 'szkok', 'szceliski', 'szkural', 'szalt', 'kgkonek', 'sestablo', 'seskasaacik'];   // 22.10 KGK eki + ses tablosu
    let kac = 0;
    for (const m of M) {
      const r = spawnSync(process.execPath, [__filename, '--sinav'], { env: Object.assign({}, process.env, { CIZ_MUTASYON: m }), encoding: 'utf8' });
      const kirmizi = r.status !== 0; if (!kirmizi) kac++;
      console.log('  mutasyon ' + m.padEnd(10) + (kirmizi ? 'KIRMIZI ✓ ' : 'YEŞİL ✗ (sınav bu bozmayı görmüyor) ') + ((r.stdout || '').split('\n')[0] || ''));
    }
    if (kac) { console.log('MUTASYON: ' + kac + '/' + M.length + ' bozma yakalanmadı'); kod = 1; } else console.log('MUTASYON: ' + M.length + '/' + M.length + ' bozma KIRMIZI');
  }
  process.exit(kod);
}

if (a.includes('--liste')) {
  const dosya = a[a.indexOf('--liste') + 1];
  if (!dosya) { console.error('kullanım: --liste <paket.json>'); process.exit(2); }
  const P = require(path.resolve(dosya));
  let g = 0, d = 0, yok = 0;
  for (const id of C.PILOT) {
    const x = P[id]; if (!x) { yok++; console.log('KÖR   ' + id + ' (dosyada yok)'); continue; }
    const r = C.cizerekKapi(x.veri || x);
    if (r.gecer) { g++; const s = r.senaryo; console.log('GEÇER ' + id.padEnd(40) + ' adım ' + s.sahne.length + ' · karalama satırı ' + s.sahne.filter(y => y.tur === 'yaz').reduce((t, y) => t + y.satirlar.length, 0) + ' · şık notu ' + s.sahne.filter(y => y.not).length); }
    else { d++; console.log('DÖNDÜ ' + id.padEnd(40) + ' ' + r.neden.join(' | ')); }
  }
  console.log('PILOT ' + C.PILOT.length + ' · geçer ' + g + ' · döndü ' + d + ' · KÖR ' + yok);
  process.exit(d || yok ? 1 : 0);
}
/* --kgk <kgk-paket.json>: yayındaki KGK sorularında sitedeki düğme kuralı (dugmeAday + cizimKapi). Dosya = [{id, sayfa, veri}]
   (paket_soru?sinav=eq.kgk, servis anahtarıyla yerelde çekilir; DEPOYA KONMAZ). Çıktıda soru metni yok: sayfa sayıları + neden kodları. */
if (a.includes('--kgk')) {
  const dosya = a[a.indexOf('--kgk') + 1];
  if (!dosya) { console.error('kullanım: --kgk <kgk-paket.json>'); process.exit(2); }
  const P = require(path.resolve(dosya)); const sf = {}, kod = {}, bic = {}; let say = 0, sayili = 0, sozel = 0;
  for (const x of P) {
    const s = Object.assign({ id: x.id }, x.veri || {}); if (!C.dugmeAday(s.id)) continue; say++;
    const ad = String(x.sayfa || '?').replace(/^.*\//, '').replace(/\.html$/, ''); const t = sf[ad] = sf[ad] || { toplam: 0, sayili: 0, sozel: 0 }; t.toplam++;
    let r; try { r = C.cizimKapi(s); } catch (e) { r = { gecer: false, neden: ['HATA ' + e.message] }; }
    if (r.gecer) { const b = r.senaryo.bicim || 'SAYI'; bic[b] = (bic[b] || 0) + 1; if (r.senaryo.bicim) { sozel++; t.sozel++; } else { sayili++; t.sayili++; } }
    else { const k = [...new Set(r.neden.map(n => n.split(':')[0]))].join('+'); kod[k] = (kod[k] || 0) + 1; }
  }
  console.log('KGK ' + say + ' soru · düğme: sayılı ' + sayili + ' · sözel ' + sozel + ' · toplam ' + (sayili + sozel) + ' · dönen ' + (say - sayili - sozel));
  console.log('biçim: ' + JSON.stringify(bic));
  { const K = C.SES_KASA || {}; let tut = 0, yok = 0; const kay = [];   // ses kasası tablosu bu kasa verisindeki senaryoyla tutuyor mu
    for (const id of Object.keys(K)) { const x = P.find(z => z.id === id); if (!x) { yok++; continue; }
      const r = C.cizimKapi(Object.assign({ id }, x.veri || {})); if (r.gecer && r.senaryo.sahne.length === K[id].n) tut++; else kay.push(id + ' (tablo ' + K[id].n + ', senaryo ' + (r.senaryo ? r.senaryo.sahne.length : 'yok') + ')'); }
    console.log('ses kasası: ' + Object.keys(K).length + ' soru · senaryoyla tutan ' + tut + ' · kayan ' + kay.length + ' · dosyada yok ' + yok + (kay.length ? ' → ' + kay.join(', ') : '')); }
  Object.keys(sf).sort().forEach(k => console.log('  ' + k.padEnd(32) + ' ' + String(sf[k].toplam).padStart(4) + ' soru · sayılı ' + sf[k].sayili + ' · sözel ' + sf[k].sozel));
  console.log('dönme nedenleri (ilk 12):'); Object.entries(kod).sort((x, y) => y[1] - x[1]).slice(0, 12).forEach(([k, n]) => console.log('  ' + String(n).padStart(4) + '  ' + k));
  process.exit(0);
}
console.log('kullanım: --sinav [--mutasyon] | --liste <paket.json> | --kgk <kgk-paket.json>');
