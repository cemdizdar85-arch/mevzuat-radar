#!/usr/bin/env node
/* s20-deneme-yukle.js — SON 20 GÜN denemesini veritabanına yükler (28.10.2026, Cem: "D1–D4 kalite onayımla").
 *
 * Neden depo dışı dosyadan: site deponun TAMAMINI yayınlıyor (28.10 ölçüldü) → deneme soru listesi depoya YAZILMAZ.
 * Liste SGS oturumunun çalışma klasöründe durur (C:\TETIKTE-CALISMA\sgs-s20-arac\deneme\denemeN.json) ve yalnız buradan
 * s20_deneme_yukle RPC'sine (servis anahtarı) gider. Soru verisi paket_soru'dan SUNUCUDA kopyalanır.
 *
 * Girdi: dizi [{soru_id|id, ders, konu?, veri?}] ya da {sorular:[...]}.
 * Denetim (bedel 0): 130 soru · ders başına TESMER m.6.2 sayısı · kimlik tekrarı yok · bilinmeyen ders yok.
 * AÇILIŞ: --kalite "<Cem'in onay cümlesi + tarih>" verilmezse deneme KAPALI yüklenir (acilis yazılsa da açılmaz).
 *
 * Kullanım:
 *   node arac/s20-deneme-yukle.js <dosya> --no 5 [--ad "Deneme 5"] [--acilis 2026-11-01T00:00:00+03:00]
 *        [--kalite "Cem 31.10.2026: D5 kalite raporu onaylı"] [--uygula] [--zorla]
 *   --uygula yoksa KURU: yalnız denetler ve özet basar. Anahtar: SUPABASE_SERVICE_KEY (ortam ya da kullanıcı değişkeni).
 *   node arac/s20-deneme-yukle.js --sinav   (öz-sınav; ağ yok)
 * 🚫 GÖRMEZ: kalite raporunun kendisi · benzerlik kapısı (KAPI-BENZERLIK, SGS oturumu) · s20 sorusunun ambar verisi
 *    (paket_soru'da yoksa öğe "veri" alanıyla gelmeli; yoksa RPC S20_EKSIK der).
 */
'use strict';
const fs = require('fs');

const SB_URL = 'https://bjrleanjpyujtajmazxn.supabase.co';
// TESMER Uygulama Yönergesi 2026 m.6.2 (veri/sgs-sinav-yapisi.json, ders adları ekrandaki adlarla). Sıra = denemede ders sırası.
const PROFIL = [
  ['Finansal Muhasebe', 26], ['Maliyet Muhasebesi', 8], ['Mali Tablolar Analizi', 8], ['Denetim', 16],
  ['Ekonomi', 6], ['Maliye', 6], ['Ticaret Hukuku', 6], ['Borçlar Hukuku', 6], ['Vergi Hukuku', 6],
  ['İş ve Sosyal Güvenlik Hukuku', 6], ['Meslek Hukuku', 6],
  ['Türkçe', 7], ['Matematik', 8], ['Atatürk İlkeleri ve İnkılap Tarihi', 5], ['Yabancı Dil', 10],
];
const TOPLAM = PROFIL.reduce((t, p) => t + p[1], 0);

function hazirla(girdi, no) {
  const liste = Array.isArray(girdi) ? girdi : (girdi && girdi.sorular) || [];
  const kusur = [], sira = new Map(PROFIL.map((p, i) => [p[0], i])), sayi = {};
  const goruldu = new Set();
  const sorular = liste.map((q, i) => ({ id: String(q.id || q.soru_id || '').trim(), ders: String(q.ders || '').trim(), konu: q.konu || null, veri: q.veri, i }));
  for (const q of sorular) {
    if (!q.id) kusur.push(`kimliksiz öğe #${q.i + 1}`);
    else if (goruldu.has(q.id)) kusur.push(`tekrar: ${q.id}`);
    goruldu.add(q.id);
    if (!sira.has(q.ders)) kusur.push(`bilinmeyen ders "${q.ders}" (${q.id})`);
    sayi[q.ders] = (sayi[q.ders] || 0) + 1;
  }
  for (const [d, n] of PROFIL) if ((sayi[d] || 0) !== n) kusur.push(`${d}: ${sayi[d] || 0} / ${n}`);
  if (sorular.length !== TOPLAM) kusur.push(`toplam ${sorular.length} / ${TOPLAM}`);
  sorular.sort((a, b) => (sira.get(a.ders) ?? 99) - (sira.get(b.ders) ?? 99) || a.i - b.i);
  const cikti = sorular.map((q, k) => { const o = { id: q.id, ders: q.ders, sira: k + 1 }; if (q.konu) o.konu = q.konu; if (q.veri && typeof q.veri === 'object') o.veri = q.veri; return o; });
  return { kusur, sayi, sorular: cikti, no };
}

function arg(ad, vars) { const i = process.argv.indexOf(ad); return i > -1 ? process.argv[i + 1] : vars; }

async function ana() {
  const dosya = process.argv[2];
  const no = parseInt(arg('--no'), 10);
  if (!dosya || !no) { console.error('kullanım: node arac/s20-deneme-yukle.js <dosya> --no N [--uygula]'); process.exit(2); }
  const h = hazirla(JSON.parse(fs.readFileSync(dosya, 'utf8')), no);
  const kalite = (arg('--kalite', '') || '').trim(), acilis = arg('--acilis', '2026-11-01T00:00:00+03:00');
  console.log(`S20 DENEME ${no}: ${h.sorular.length} soru · ` + PROFIL.map(p => `${p[0]} ${h.sayi[p[0]] || 0}/${p[1]}`).join(' · '));
  console.log(`  açılış ${acilis} · kalite onayı: ${kalite || 'YOK → KAPALI yüklenir'}`);
  if (h.kusur.length) { console.error('  KUSUR:\n   - ' + h.kusur.join('\n   - ')); process.exit(1); }
  if (!process.argv.includes('--uygula')) { console.log('  KURU: yazılmadı (--uygula ile yazar).'); return; }
  const anahtar = (process.env.SUPABASE_SERVICE_KEY || '').trim();
  if (!anahtar) { console.error('SUPABASE_SERVICE_KEY yok'); process.exit(1); }
  const govde = { p: { no, ad: arg('--ad', `Deneme ${no}`), sure_dk: 165, acilis, kalite_onay: kalite, zorla: process.argv.includes('--zorla') ? 'evet' : '', sorular: h.sorular } };
  const r = await fetch(SB_URL + '/rest/v1/rpc/s20_deneme_yukle', { method: 'POST', headers: { apikey: anahtar, Authorization: 'Bearer ' + anahtar, 'Content-Type': 'application/json' }, body: JSON.stringify(govde) });
  const t = await r.text();
  if (!r.ok) { console.error(`  YAZILAMADI (${r.status}): ${t.slice(0, 400)}`); process.exit(1); }
  console.log('  YAZILDI: ' + t);
}

function ozSinav() {
  const tam = []; for (const [d, n] of PROFIL) for (let i = 0; i < n; i++) tam.push({ soru_id: `x-${d}-${i}`, ders: d });
  const V = [
    ['tam 130 temiz', tam, 0],
    ['bir ders eksik', tam.slice(1), 2],
    ['tekrar kimlik', tam.map((q, i) => i === 5 ? { ...q, soru_id: tam[4].soru_id } : q), 1],
    ['bilinmeyen ders', tam.map((q, i) => i === 0 ? { ...q, ders: 'Muhasebe' } : q), 2],
    ['{sorular} biçimi', { sorular: tam }, 0],
  ];
  let k = 0;
  for (const [ad, g, beklenen] of V) { const n = hazirla(g, 5).kusur.length; const ok = beklenen === 0 ? n === 0 : n >= 1; console.log((ok ? 'GEÇTİ ' : 'DÜŞTÜ ') + ad + ` (kusur ${n})`); if (!ok) k++; }
  const s = hazirla(tam.slice().reverse(), 5).sorular;
  const sirali = s[0].ders === 'Finansal Muhasebe' && s[129].ders === 'Yabancı Dil' && s.every((q, i) => q.sira === i + 1);
  console.log((sirali ? 'GEÇTİ ' : 'DÜŞTÜ ') + 'ders sırası TESMER düzeninde'); if (!sirali) k++;
  console.log(`S20 YÜKLEYİCİ ÖZ-SINAV: ${k ? 'KIRMIZI' : 'YEŞİL'} (${V.length + 1 - k}/${V.length + 1})`);
  process.exit(k ? 1 : 0);
}

if (process.argv.includes('--sinav')) ozSinav(); else ana().catch(e => { console.error(e); process.exit(1); });
