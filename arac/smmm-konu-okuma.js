#!/usr/bin/env node
/* ============================================================================
 *  YETERLİLİK (SMMM bitirme) KONU OKUMA — çıkmış soruları OKUYARAK konu sayımı (04.10.2026, Cem "2 yapalım": SGS'deki
 *  kanıtlı sayımın Yeterlilik karşılığı). Kural: CLAUDE.md "DIŞARI ÇIKAN SINAV RAKAMI ÖNCE SORU METNİYLE DOĞRULANIR".
 *  YÖNTEM (SGS'den farklı): klasik sınavda dönem başına ders başına 4–6 çok parçalı soru var; anahtar kelime adayı işe yaramaz.
 *    Her DERS tek bir okuyucuya verilir, okuyucu 31 dönemin tamamını okur ve konu sözlüğünü kendisi kurup sabit tutar →
 *    aynı konu her dönemde aynı adı alır (SGS etiketlerindeki parçalanma burada oluşmaz).
 *    (1) --parti <klasör>: ambardan 2016/1–2025/3 klasik soru metni (tur=cikmis-komisyon-cevabi, cevap işaretinden önceki kısım)
 *        + 2026 test kitapçıkları (tur=cikmis-soru) → ders başına d1..d8.txt (YEREL; soru metni depoya GİRMEZ).
 *    (2) okuyucu her ders için sonuc-dN.json yazar: {ders, konular:{ad:tanım}, sorular:[{donem, soru, konular:[]}]}.
 *    (3) --topla <klasör>: → veri/sinav/smmm-konu-okuma.json (dönem, soru no, konu — METİN YOK).
 *  🚫 GÖRMEZ: ambarda olmayan dönem (2020/3 ambarda YOK → payda 31) · okuyucunun konu genişliği seçimi (dersler arası eşit değil) ·
 *     2016–2018 Finansal Muhasebe belgelerinde cevap işareti yok, soru ile cevap aynı metinde (okuyucu ayırır) · OCR'lı dönemlerde
 *     (2019–2025) bozuk sayılar (konu ayrımını etkilemez).
 *  Kullanım: node arac/smmm-konu-okuma.js --parti <klasör>  |  node arac/smmm-konu-okuma.js --topla <klasör>
 * ==========================================================================*/
'use strict';
const fs = require('fs'), path = require('path');
const KOK = path.join(__dirname, '..');
const mod = process.argv[2], DIR = process.argv[3];
if (!['--parti', '--topla'].includes(mod) || !DIR) { console.error('kullanım: --parti <klasör> | --topla <klasör>'); process.exit(2); }
// 2026 test kitapçığı sıra no → ders (smmm_2026_N_0X)
const TEST = ['Finansal Muhasebe', 'Finansal Tablolar ve Analizi', 'Maliyet Muhasebesi', 'Muhasebe Denetimi', 'Vergi Mevzuatı ve Uygulaması', 'Hukuk', 'Muh. ve Mali Müş. Meslek Hukuku', 'Sermaye Piyasası Mevzuatı'];
// ambar ders adı → sitedeki ders adı (veri/soru-dizini.json smmm)
const SITE = { 'Muh. ve Mali Müş. Meslek Hukuku': 'Meslek Hukuku' };
const srt = d => { const [y, n] = d.split('/'); return +y * 10 + +n; };

async function cek(tur, filtre) {
  const K = process.env.SUPABASE_SERVICE_KEY; if (!K) { console.error('SUPABASE_SERVICE_KEY yok'); process.exit(2); }
  let hepsi = [];
  for (let o = 0; ; o += 100) {
    const r = await fetch(`https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar?tur=eq.${tur}&select=kaynak_ad,baslik,metin${filtre}&order=baslik.asc&limit=100&offset=${o}`, { headers: { apikey: K, Authorization: 'Bearer ' + K } });
    const j = await r.json(); hepsi = hepsi.concat(j); if (j.length < 100) break;
  }
  return hepsi;
}
(async () => {
  if (mod === '--parti') {
    const klasik = (await cek('cikmis-komisyon-cevabi', '')).filter(d => /SMMM Yeterlilik 20(1[6-9]|2\d)\//.test(d.baslik));
    const test = (await cek('cikmis-soru', '&kaynak_ad=ilike.*SMMM*')).filter(d => /SMMM 2026\//.test(d.kaynak_ad));
    const dosya = {};
    klasik.sort((p, q) => srt(p.baslik.match(/20\d\d\/\d/)[0]) - srt(q.baslik.match(/20\d\d\/\d/)[0]));
    for (const d of klasik) {
      const m = d.baslik.match(/(20\d\d\/\d) - (.+)$/); let x = d.metin;
      const i = x.search(/\n[ \t]*(CEVAPLAR|CEVAP ANAHTARI|CEVAP|ÇÖZÜMLER|KAYNAK NOTU)/); if (i > 0) x = x.slice(0, i);
      x = x.replace(/\r/g, '').replace(/Gençlik Caddesi[^\n]*\n?/g, '').replace(/http:\/\/www\.turmob[^\n]*\n?/g, '').replace(/\n{3,}/g, '\n\n').slice(0, 30000);
      (dosya[m[2]] = dosya[m[2]] || []).push('######## DÖNEM ' + m[1] + ' (klasik yazılı sınav' + (i > 0 ? '' : '; metinde komisyon cevabı da olabilir') + ')\n' + x);
    }
    for (const d of test) {
      const m = d.kaynak_ad.match(/SMMM (2026\/\d) \(smmm_2026_\d_0(\d)\)/); const ders = TEST[+m[2] - 1];
      (dosya[ders] = dosya[ders] || []).push('######## DÖNEM ' + m[1] + ' (çoktan seçmeli test, 20 soru)\n' + d.metin.replace(/\r/g, '').slice(0, 22000));
    }
    fs.mkdirSync(DIR, { recursive: true });
    Object.keys(dosya).forEach((k, i) => fs.writeFileSync(path.join(DIR, 'd' + (i + 1) + '.txt'), 'DERS: ' + k + '\n\n' + dosya[k].join('\n\n')));
    console.log('klasik belge ' + klasik.length + ' · test kitapçığı ' + test.length + ' · ders ' + Object.keys(dosya).length + ' → ' + DIR);
    return;
  }
  const sonuc = fs.readdirSync(DIR).filter(f => /^sonuc-d\d+\.json$/.test(f)).map(f => JSON.parse(fs.readFileSync(path.join(DIR, f), 'utf8')));
  if (sonuc.length !== 8) { console.error('KIRMIZI: 8 ders bekleniyordu, ' + sonuc.length + ' sonuç var'); process.exit(3); }
  const donemler = new Set(); const kararlar = []; const konular = {};
  for (const s of sonuc) {
    const ders = SITE[s.ders] || s.ders; konular[ders] = s.konular;
    for (const q of s.sorular) {
      donemler.add(q.donem);
      for (const k of q.konular || []) {
        if (!(k in s.konular)) { console.error('KIRMIZI: ' + ders + ' sözlükte olmayan konu: ' + k); process.exit(3); }
        kararlar.push({ ders, donem: q.donem, soru: String(q.soru), konu: k });
      }
    }
    const dd = new Set(s.sorular.map(q => q.donem)).size;
    if (dd !== 31) { console.error('KIRMIZI: ' + ders + ' ' + dd + ' dönem (31 bekleniyordu)'); process.exit(3); }
  }
  const cikti = { olcum: new Date().toISOString().slice(0, 10), pencere: '2016/1-2026/2', donem: donemler.size,
    yontem: 'her ders tek okuyucu: 31 dönemin soru metni okundu, konu sözlüğü ders içinde sabit; konu = sorunun/alt sorunun ölçtüğü başlık',
    kaynak_notu: '2016/1-2025/3 TÜRMOB-TESMER klasik sınav soru ve komisyon cevapları (2019-2025 görüntü sayfaları OCR ile metne çevrildi); 2026/1-2026/2 test kitapçıkları. 2020/3 ambarda yok.',
    gormez: 'okuyucunun konu genişliği seçimi dersler arasında eşit değil · ambarda olmayan dönem',
    konular, kararlar };
  fs.writeFileSync(path.join(KOK, 'veri', 'sinav', 'smmm-konu-okuma.json'), JSON.stringify(cikti).replace(/\},\{/g, '},\n{'));
  console.log('veri/sinav/smmm-konu-okuma.json: ' + kararlar.length + ' soru-konu bağı, ' + donemler.size + ' dönem');
})().catch(e => { console.error('HATA ' + e.message); process.exitCode = 1; });
