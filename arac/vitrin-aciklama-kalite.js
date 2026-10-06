// arac/vitrin-aciklama-kalite.js — ücretsiz soruların anlatımını kalite kapılarından geçirir, kusurluları vitrin dışı tutar (0 USD).
// 05.10.2026 Cem ("30 soruyu çözen bizim anlatımımızı görmeyecek" → "1.2.3 üçünü de yapalım"): seviye testi sonucu öğrencinin ilk 3
// yanlışının anlatımını gösteriyor (rpc/seviye_aciklama, radar-app/sql/2026-10-05-seviye-aciklama.sql). Vitrine kusurlu anlatım çıkmasın:
//   - soru-kalite-kapisi.js satirlar() — HER SORU YENİ2 sayılır (en sıkı ölçü; KALITE_BASLANGIC_YENI2=2000-01-01) → KAPI-* bulgusu
//   - kartta görünen alanlar: sade.dogru · kural · dayanak · tuzak.<harf>.ad/metin → Türkçe harfsiz (KART-TR), boş (KART-BOS)
// Bulgulu soru public.vitrin_aciklama_dislanan'a yazılır (tablo her koşuda baştan kurulur); RPC o soruyu döndürmez.
//   SUPABASE_SERVICE_KEY=... node arac/vitrin-aciklama-kalite.js            → ölç + tabloyu yaz
//   SUPABASE_SERVICE_KEY=... node arac/vitrin-aciklama-kalite.js --kuru     → yalnız ölç
// Çıktıda soru metni YOK: yalnız sayılar ve kural kodları.
// 🚫 GÖRMEZ: kapıların GÖRMEDİĞİ her şey (soru-kalite-kapisi.js başındaki liste: yanlış madde atfı, uydurma bilgi, kök muğlaklığı) ·
//   60 harften kısa alanda yalnız aşağıdaki bilinen ASCII kelimeler · tuzak metninin içeriğinin doğruluğu (elle okuma işi).
//   Soru değişirse tablo bayatlar → ücretsiz soru güncellendiğinde yeniden koşulur.
'use strict';
process.env.KALITE_BASLANGIC_YENI2 = '2000-01-01';
const path = require('path');
const { satirlar } = require(path.join(__dirname, 'soru-kalite-kapisi.js'));
const TR = require(path.join(__dirname, 'turkce-karakter-kapisi.js'));
const KEY = (process.env.SUPABASE_SERVICE_KEY || '').trim();
const API = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/';
const KURU = process.argv.includes('--kuru');
// 05.10 genişletildi: Yeterlilik uçtan uca denemesinde "MSUGT Sira No:1 Tekduzen Hesap Plani" dayanağı eski listeden kaçtı
const KISA_ASCII = /\b(sayili|isletme|odeme|isci|isveren|sirket|yonetmelik|yonetmeligi|teblig|tebligi|ozel|gorev|ucret|degisik|gecici|kurulus|sozlesme|hukum|sira|tekduzen|plani|duzenleme|islem|islemleri|mukellef|degerleme|yukumlu)\b/i;

function kartBulgu(k) {
  const b = [], sade = (k.sade && typeof k.sade === 'object') ? k.sade : { dogru: k.sade };
  const bak = (ad, v) => { if (v == null || v === '') return; const t = String(v);
    if (TR.asciiTurkce(t)) b.push('KART-TR ' + ad); else if (KISA_ASCII.test(t)) b.push('KART-TR ' + ad); };   // listedeki kelimeler YALNIZ harfsiz yazımda geçer → karışık dizede de kusur (05.10: "Sira No:1 Tekduzen Hesap Plani - Tekdüzen ...")
  bak('sade.dogru', sade.dogru); bak('kural', k.kural); bak('dayanak', k.dayanak);
  for (const [h, tz] of Object.entries(k.tuzak || {})) { bak('tuzak.' + h + '.ad', tz && tz.ad); bak('tuzak.' + h + '.metin', tz && tz.metin); }
  if (!sade.dogru) b.push('KART-BOS sade.dogru');
  const eksik = Object.keys(k.siklar || {}).filter(h => h !== k.dogru && !(k.tuzak && k.tuzak[h] && k.tuzak[h].metin));
  if (eksik.length) b.push('KART-BOS tuzak ' + eksik.join(''));
  return b;
}

async function istek(yol, secenek) {
  const r = await fetch(API + yol, { ...secenek, headers: { apikey: KEY, Authorization: 'Bearer ' + KEY, 'Content-Type': 'application/json', ...(secenek && secenek.headers) } });
  if (!r.ok) throw new Error(yol.split('?')[0] + ' http ' + r.status);
  return r.status === 204 ? null : r.json().catch(() => null);
}

(async () => {
  if (!KEY) { console.log('VITRIN-KALITE KÖR: SUPABASE_SERVICE_KEY yok'); process.exitCode = 2; return; }
  const hepsi = [];
  for (let o = 0; ; o += 500) { const a = await istek(`paket_soru?select=id,veri&ucretsiz=eq.true&order=id&limit=500&offset=${o}`); hepsi.push(...a); if (a.length < 500) break; }
  const dis = [], say = {};
  for (const { id, veri } of hepsi) {
    const t = [...satirlar(veri).filter(x => /^KAPI-/.test(x)).map(x => x.split(':')[0]), ...kartBulgu(veri).map(x => x.split(' ').slice(0, 2).join(' '))];
    if (!t.length) continue;
    const kod = [...new Set(t)]; kod.forEach(x => { say[x] = (say[x] || 0) + 1; });
    dis.push({ id, neden: kod.join(' · ').slice(0, 300) });
  }
  // 05.10 elle okuma retleri (arac/vitrin-elle-ret.json) kapı bulgularına EKLENİR - tablo baştan yazılınca silinmesinler
  try { const er = JSON.parse(require('fs').readFileSync(path.join(__dirname, 'vitrin-elle-ret.json'), 'utf8')).ret || [];
    const var_ = new Set(dis.map(x => x.id)), ids = new Set(hepsi.map(x => x.id));
    for (const r of er) { if (!ids.has(r.id)) continue; if (var_.has(r.id)) { const d = dis.find(x => x.id === r.id); d.neden = (d.neden + ' · ' + r.neden).slice(0, 300); } else dis.push({ id: r.id, neden: String(r.neden).slice(0, 300) }); say['ELLE'] = (say['ELLE'] || 0) + 1; }
  } catch (e) { console.log('VITRIN-KALITE: elle ret listesi okunamadı (' + e.message + ')'); }
  console.log(`VITRIN-KALITE: ücretsiz ${hepsi.length} · dışlanan ${dis.length} · vitrinde ${hepsi.length - dis.length}`);
  console.log(Object.entries(say).sort((a, b) => b[1] - a[1]).map(([k, v]) => '  ' + k + ' ' + v).join('\n'));
  if (KURU) return;
  await istek('vitrin_aciklama_dislanan?id=neq.__hic__', { method: 'DELETE' });
  for (let i = 0; i < dis.length; i += 200) await istek('vitrin_aciklama_dislanan', { method: 'POST', headers: { Prefer: 'return=minimal' }, body: JSON.stringify(dis.slice(i, i + 200)) });
  const kontrol = await istek('vitrin_aciklama_dislanan?select=id');
  console.log(`VITRIN-KALITE: tabloya yazıldı ${kontrol.length}/${dis.length}`);
})().catch(e => { console.log('VITRIN-KALITE HATA: ' + e.message); process.exitCode = 1; });
