// motor/sabah-kontrol.js — Tetikte SABAH KONTROLÜ (06.10.2026, Cem "2 yap": "sabah 08:00 bulut kontrolü, sonuç bana mail")
// Bulutta (.github/workflows/sabah-kontrol.yml) her sabah 08:00 TR koşar; bilgisayara bağlı değildir. 0 USD.
// Ölçer: (1) site sayfaları 200 mü · (2) uç fonksiyonlar ayakta mı (?surum=1) · (3) son yayın/yükleme akışlarının sonucu ·
//        (4) tuzak ADINDA istem kalıntısı (06.10 TuzakAyir olayı) · (5) vitrin dışlama tablosu dolu mu + Nöbetçi anlatımı
//        canlıda dönüyor mu (rpc/seviye_aciklama) · (6) 24 saatte sipariş/ödeme sayısı (yalnız sayı).
// Sonuç: YEŞİL / SARI / KIRMIZI + madde madde, Resend ile ALARM_ALICI'ya (yoksa cem@dizdardenetim.com — robotların tek kutusu).
// GÜNLÜK PUBLIC: yalnız sayı ve hüküm basılır; soru metni, kişi verisi, anahtar BASILMAZ.
// 🚫 GÖRMEZ: sayfanın tarayıcıda doğru çizildiği (yalnız HTTP durumu) · ödeme sağlayıcısının (iyzico) kendi durumu ·
//   içerik kusurları (elle okuma işi) · Supabase faturası/kotası.
'use strict';
const SB = 'https://bjrleanjpyujtajmazxn.supabase.co', PUB = 'sb_publishable_kTZpYwrL7skw8Ryj5Vs8_Q_-5_Fhkcg';
const SK = (process.env.SUPABASE_SERVICE_KEY || '').trim(), GH = (process.env.GITHUB_TOKEN || '').trim(), REPO = process.env.GITHUB_REPOSITORY || 'cemdizdar85-arch/mevzuat-radar';
const RESEND_KEY = (process.env.RESEND_KEY || '').trim(), RESEND_FROM = (process.env.RESEND_FROM || 'Tetikte <bildirim@tetikte.com>').trim();
const ALICI = (process.env.ALARM_ALICI || 'cem@dizdardenetim.com').trim();
const KURU = process.argv.includes('--kuru');
const satir = []; let durum = 0;            // 0 yeşil, 1 sarı, 2 kırmızı
const not = (seviye, metin) => { durum = Math.max(durum, seviye); satir.push((['✅', '🟡', '🔴'][seviye]) + ' ' + metin); };
const zaman = (ms = 15000) => AbortSignal.timeout(ms);
async function sb(yol, sec = {}) { const r = await fetch(SB + '/rest/v1/' + yol, { ...sec, signal: zaman(), headers: { apikey: SK, Authorization: 'Bearer ' + SK, 'Content-Type': 'application/json', ...(sec.headers || {}) } }); if (!r.ok) throw new Error(yol.split('?')[0] + ' http ' + r.status); return r.json(); }

async function siteSayfalari() {
  const yollar = ['/', '/fiyat.html', '/satin-al.html', '/seviye-testi.html', '/ogrenci.html', '/gorsel/logo-mail.png'];
  const kotu = [];
  for (const y of yollar) { try { const r = await fetch('https://tetikte.com' + y, { signal: zaman() }); if (r.status !== 200) kotu.push(y + ' ' + r.status); } catch (e) { kotu.push(y + ' ' + e.name); } }
  kotu.length ? not(2, `Site: ${kotu.length}/${yollar.length} sayfa açılmıyor (${kotu.join(', ')})`) : not(0, `Site: ${yollar.length}/${yollar.length} sayfa 200`);
}
async function ucFonksiyonlar() {
  const adlar = ['karne-gonder', 'siparis-bildirim', 'iyzico-odeme', 'nobetci-sor', 'quick-task'];
  const kotu = [];
  for (const a of adlar) { try { const r = await fetch(`${SB}/functions/v1/${a}?surum=1`, { signal: zaman(), headers: { apikey: PUB, Authorization: 'Bearer ' + PUB } }); const j = await r.json().catch(() => ({})); if (!r.ok || !j.surum) kotu.push(a + ' ' + r.status); } catch (e) { kotu.push(a + ' ' + e.name); } }
  kotu.length ? not(2, `Uç fonksiyon: ${kotu.length}/${adlar.length} cevap vermiyor (${kotu.join(', ')})`) : not(0, `Uç fonksiyon: ${adlar.length}/${adlar.length} ayakta`);
}
async function akislar() {
  if (!GH) return not(1, 'Akışlar: GITHUB_TOKEN yok, ölçülmedi');
  const dosyalar = { 'yayin-bas.yml': 'SGS yayını', 'smmm-kasa-yayin.yml': 'Yeterlilik yayını', 'edge-yukle.yml': 'Uç fonksiyon yükleme', 'sql-uygula.yml': 'SQL uygulama', 'vitrin-kalite.yml': 'Vitrin kalite' };
  for (const [d, ad] of Object.entries(dosyalar)) {
    try {
      const r = await fetch(`https://api.github.com/repos/${REPO}/actions/workflows/${d}/runs?per_page=1`, { signal: zaman(), headers: { Authorization: 'Bearer ' + GH, Accept: 'application/vnd.github+json' } });
      const k = ((await r.json()).workflow_runs || [])[0];
      if (!k) { not(1, `${ad}: hiç koşu yok`); continue; }
      const saat = Math.round((Date.now() - new Date(k.updated_at)) / 36e5);
      if (k.status !== 'completed') not(0, `${ad}: şu an koşuyor (${saat} sa önce başladı)`);
      else if (k.conclusion === 'success') not(0, `${ad}: son koşu başarılı (${saat} sa önce)`);
      else not(1, `${ad}: son koşu ${k.conclusion} (${saat} sa önce) — ${k.html_url}`);
    } catch (e) { not(1, `${ad}: ölçülemedi (${e.message})`); }
  }
}
async function kasaVeVitrin() {
  if (!SK) return not(2, 'Kasa/vitrin: SUPABASE_SERVICE_KEY yok, ölçülmedi');
  // tuzak adında istem kalıntısı (06.10 TuzakAyir olayı: 241 soru)
  let toplam = 0, kalinti = 0;
  for (let o = 0; ; o += 1000) {
    const a = await sb(`paket_soru?select=tuzak:veri->tuzak&order=id&limit=1000&offset=${o}`);
    for (const x of a) { toplam++; if (Object.values(x.tuzak || {}).some(t => /ne soruluyor|kural\s*:|doğrusu\s*:|placeholder/i.test(String((t && t.ad) || '')))) kalinti++; }
    if (a.length < 1000) break;
  }
  kalinti ? not(1, `Tuzak adında istem kalıntısı: ${kalinti} soru (sitede ${toplam})`) : not(0, `Tuzak adı kalıntısı: 0 (sitede ${toplam} soru)`);
  // vitrin tablosu + canlı Nöbetçi anlatımı
  const dis = await sb('vitrin_aciklama_dislanan?select=id');
  const ucr = await sb('paket_soru?select=id,dogru:veri->>dogru&ucretsiz=eq.true&order=id&limit=2000');
  const disSet = new Set(dis.map(x => x.id)), temiz = ucr.filter(x => !disSet.has(x.id));
  if (!dis.length) not(2, `Vitrin dışlama tablosu BOŞ (ücretsiz ${ucr.length}) — kusurlu kartlar gösteriliyor olabilir`);
  else not(0, `Vitrin: ücretsiz ${ucr.length} · dışlanan ${dis.length} · vitrinde ${temiz.length}`);
  const gonder = temiz.slice(0, 6).map(x => ({ id: x.id, secim: 'ABCDE'.split('').find(h => h !== String(x.dogru || '').toUpperCase()) }));
  try {
    const r = await fetch(`${SB}/rest/v1/rpc/seviye_aciklama`, { method: 'POST', signal: zaman(), headers: { apikey: PUB, Authorization: 'Bearer ' + PUB, 'Content-Type': 'application/json' }, body: JSON.stringify({ p_cevaplar: gonder }) });
    const j = await r.json(); const n = (j.liste || []).length;
    n ? not(0, `Nöbetçi anlatımı canlıda dönüyor (${n}/3 kart)`) : not(2, `Nöbetçi anlatımı DÖNMÜYOR (${j.hata || 'boş liste'})`);
  } catch (e) { not(2, `Nöbetçi anlatımı ölçülemedi (${e.message})`); }
}
// 06.10 (Cem 'ana sayfa sorularına bekçi, ama mail çok - otomatik olsun'): ana sayfa kartının soru listesi robotça
// tazelenir (motor/vitrin-hesap.js); burada yalnız TEK SATIR durum. Düşen soru varsa SARI (yerine yenisi elle okunup listeye eklenir).
async function anaSayfaSorulari() {
  try {
    const r = await fetch('https://tetikte.com/veri/vitrin-hesap.json?k=' + Date.now(), { signal: zaman() }); if (!r.ok) return not(1, 'Ana sayfa soruları: liste okunamadı (http ' + r.status + ')');
    const d = await r.json(), s = (d.sinavlar || {}), dus = d.dusen || [];
    const metin = 'Ana sayfa soruları: SGS ' + (s.sgs || []).length + ' · Yeterlilik ' + (s.yeterlilik || []).length + ' yayında';
    dus.length ? not(1, metin + ' · robot ' + dus.length + ' soruyu düşürdü (' + dus.map(x => x.neden).join(', ') + ') - yerine yenisi okunmalı') : not(0, metin);
  } catch (e) { not(1, 'Ana sayfa soruları: ölçülemedi (' + e.message + ')'); }
}
// 07.10 (Cem "1.2.3" madde 1): Yeterlilik seviye setinde kasadan çıkan soru robotça değişir (smmm-kasa-yayin.yml) ve
// "okunmadi" tarihi taşır. Okunmamış soru varsa SARI; sette kasada olmayan kimlik ölçülmez (robot o gece onarır).
async function seviyeSeti() {
  try {
    const r = await fetch('https://tetikte.com/veri/seviye/smmm-set.json?k=' + Date.now(), { signal: zaman() }); if (!r.ok) return not(1, 'Seviye seti: okunamadı (http ' + r.status + ')');
    const s = (await r.json()).sorular || [], ok = s.filter(x => x.okunmadi);
    ok.length ? not(1, 'Yeterlilik seviye seti: robot ' + ok.length + ' soruyu değiştirdi, elle okunmadı (' + ok.map(x => x.id).join(', ') + ')') : not(0, 'Yeterlilik seviye seti: ' + s.length + ' soru, hepsi okunmuş');
  } catch (e) { not(1, 'Seviye seti: ölçülemedi (' + e.message + ')'); }
}
async function siparisler() {
  if (!SK) return;
  try {
    const once = new Date(Date.now() - 864e5).toISOString();
    const s = await sb(`siparisler?select=durum&olusturma=gte.${encodeURIComponent(once)}`);
    const say = {}; s.forEach(x => { say[x.durum || '?'] = (say[x.durum || '?'] || 0) + 1; });
    not(0, `Son 24 saat sipariş: ${s.length}` + (s.length ? ' (' + Object.entries(say).map(([k, v]) => k + ' ' + v).join(', ') + ')' : ''));
  } catch (e) { not(1, `Sipariş sayısı ölçülemedi (${e.message})`); }
}

(async () => {
  for (const f of [siteSayfalari, ucFonksiyonlar, akislar, kasaVeVitrin, siparisler, anaSayfaSorulari, seviyeSeti]) { try { await f(); } catch (e) { not(1, f.name + ': ' + e.message); } }
  const hukum = ['YEŞİL', 'SARI', 'KIRMIZI'][durum];
  const tarih = new Date().toLocaleString('tr-TR', { timeZone: 'Europe/Istanbul' });
  console.log(`SABAH KONTROLÜ: ${hukum}`); satir.forEach(s => console.log('  ' + s));
  if (KURU) return;
  if (!RESEND_KEY) { console.log('MAIL GITMEDI: RESEND_KEY yok'); process.exitCode = durum === 2 ? 1 : 0; return; }
  const html = `<div style="font-family:Segoe UI,Arial,sans-serif;font-size:15px;line-height:1.6;color:#16191d;max-width:620px">
<h2 style="margin:0 0 6px">Tetikte sabah kontrolü: ${hukum}</h2><p style="margin:0 0 14px;color:#6b7280">${tarih}</p>
<ul style="padding-left:18px;margin:0 0 14px">${satir.map(s => '<li style="margin:0 0 6px">' + s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/(https:\/\/github\.com\/\S+)/g, '<a href="$1">$1</a>') + '</li>').join('')}</ul>
<p style="font-size:12px;color:#9ca3af;margin:0">Bulutta her sabah 08:00 koşar (.github/workflows/sabah-kontrol.yml). Soru metni ve kişi verisi içermez.</p></div>`;
  const r = await fetch('https://api.resend.com/emails', { method: 'POST', signal: zaman(), headers: { Authorization: 'Bearer ' + RESEND_KEY, 'Content-Type': 'application/json' },
    body: JSON.stringify({ from: RESEND_FROM, to: [ALICI], subject: `Tetikte sabah kontrolü: ${hukum}`, html, text: `Tetikte sabah kontrolü: ${hukum}\n${tarih}\n\n` + satir.join('\n') }) });
  console.log(r.ok ? 'MAIL GITTI' : 'MAIL GITMEDI: http ' + r.status);
  process.exitCode = durum === 2 ? 1 : 0;   // KIRMIZI'da akış da kırmızı olsun (ci-kirmizi-nobeti görür)
})().catch(e => { console.log('SABAH KONTROLÜ HATA: ' + e.message); process.exitCode = 1; });
