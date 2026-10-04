#!/usr/bin/env node
/* ============================================================================
 *  HUNİ RAPORU (03.10.2026, Cem "2 yap" — V2 madde 55-56)
 *
 *  NE YAPAR: GoatCounter'dan (salt okuma anahtarı) dün ve son 7 günün sayfa + olay sayılarını çeker,
 *  satış hunisini adım adım dizer, bir adımdan ötekine geçiş yüzdesini yazar. Ödenmiş sipariş sayısını
 *  Supabase'in herkese açık sayım fonksiyonundan (paket_secim_sayac; yalnız paket + adet döner) ekler.
 *  Çıktı bir METİN dosyasıdır (--cikti); iş akışı onu Cem'e e-postayla gönderir.
 *
 *  ⛔ GİZLİLİK: Actions günlükleri HERKESE AÇIK (CLAUDE.md bulut güvenliği). Bu betik tabloyu ekrana
 *     BASMAZ (yalnız "rapor hazır, N satır"); dönüşüm rakamları depoya da YAZILMAZ (rakipler okumasın).
 *     Kişi verisi yok: sayaç zaten yalnız sayfa/adım adı tutuyor.
 *  ANAHTAR: GOATCOUNTER_TOKEN (GitHub secret; "Read statistics" izni). Yoksa rapor "anahtar yok" der, 0 ile çıkar.
 *     Kurulum adımları motor/goatcounter-cek.js başında.
 *
 *  🚫 GÖRMEZ: reklam engelleyicisi sayacı kesen ziyaretçi (sayılmaz) · havale ödemesinin günü (sipariş tablosu
 *     dışarı kapalı; yalnız toplam ödenen adet) · ders sayfalarında "ilk soru" (kalıp henüz sayılmıyor).
 *  ⚠ ÖLÇÜLMEDİ: GoatCounter API cevabının alan adları canlıda denenmedi (anahtar yok); --sinav yalnız toplama
 *     mantığını sınar. İlk gerçek koşuda "eşleşmeyen yol" listesi rapora yazılır, yanlış eşleme oradan görülür.
 *
 *  Kullanım:  GOATCOUNTER_TOKEN=... node motor/huni-raporu.js --cikti huni.txt
 *             node motor/huni-raporu.js --sinav
 * ==========================================================================*/
'use strict';
const fs = require('fs');

const SITE = 'https://mevzuatradar.goatcounter.com';
const SB = 'https://bjrleanjpyujtajmazxn.supabase.co';
const SB_ANON = 'sb_publishable_kTZpYwrL7skw8Ryj5Vs8_Q_-5_Fhkcg';   // yayın anahtarı (sitede zaten açık)

/* Huni adımları: ad + yolu tanıyan düzenli ifade. Sıra = huni sırası. */
const ADIMLAR = [
  ['Ana sayfa',                 /^\/(index\.html)?$/],
  ['Seviye testi sayfası',      /^\/seviye-testi\.html$/],
  ['Teste başladı',             /^seviye\/(sgs|yet)\/basla$/],
  ['30 soruyu bitirdi',         /^seviye\/(sgs|yet)\/bitti$/],
  ['Form çıktı (üye değil)',    /^seviye\/(sgs|yet)\/form-cikti$/],
  ['Formu doldurdu',            /^seviye\/(sgs|yet)\/form-dolduruldu$/],
  ['Sonucu gördü',              /^seviye\/(sgs|yet)\/sonuc$/],
  /* 04.10 Cem "sınav sonunda üye olsun": form kapısı kalktı (form adımları eski veri için duruyor); özet açık, rapor hesapla */
  ['Rapor kilidini gördü',      /^seviye\/(sgs|yet)\/kilit-gordu$/],
  ['Hesap aç dedi',             /^seviye\/(sgs|yet)\/kilit-hesap-ac$/],
  ['Raporu hesapla açtı',       /^seviye\/(sgs|yet)\/rapor-acildi$/],
  ['Fiyat sayfası',             /^\/fiyat\.html$/],
  ['Satın alma sayfası',        /^\/satin-al\.html$/],
  ['Paket seçti',               /^satin-al\/sec\//],
  ['Sipariş verdi',             /^satin-al\/siparis\//],
];
const EK = [
  ['Üye oldu',                  /^hesap\/kayit$/],
  ['Hesabım açıldı',            /^hesap\/panel$/],
  ['Ödeme bekleyen gördü',      /^hesap\/odeme-bekliyor$/],
  ['Sınav gibi başladı',        /^deneme\/basla\//],
  ['Sınav gibi bitti',          /^deneme\/bitti/],
  ['Sorular: sınav seçti',      /^sorular\/sinav\//],
];

function topla(hits) {
  const say = {}, eslesmeyen = [];
  const tum = ADIMLAR.concat(EK);
  for (const h of hits) {
    const yol = String(h.yol || '');
    const t = tum.find(a => a[1].test(yol));
    if (t) say[t[0]] = (say[t[0]] || 0) + (h.adet || 0);
    else if (h.olay) eslesmeyen.push(yol);
  }
  return { say, eslesmeyen };
}
function yuzde(a, b) { return b ? '%' + Math.round(100 * a / b) : '—'; }
function tablo(dun, hafta) {
  const satir = [];
  const pad = (s, n) => (s + ' '.repeat(n)).slice(0, n);
  satir.push(pad('Adım', 28) + pad('Dün', 8) + pad('7 gün', 8) + 'Önceki adıma göre (7 gün)');
  let onceki = null;
  for (const [ad] of ADIMLAR) {
    const d = dun.say[ad] || 0, h = hafta.say[ad] || 0;
    satir.push(pad(ad, 28) + pad(String(d), 8) + pad(String(h), 8) + (onceki === null ? '' : yuzde(h, onceki)));
    onceki = h;
  }
  satir.push('');
  for (const [ad] of EK) satir.push(pad(ad, 28) + pad(String(dun.say[ad] || 0), 8) + String(hafta.say[ad] || 0));
  return satir.join('\n');
}

async function gc(yol, token) {
  const r = await fetch(SITE + yol, { headers: { Authorization: 'Bearer ' + token, 'Content-Type': 'application/json' } });
  if (r.status === 401 || r.status === 403) throw new Error('GoatCounter anahtarı reddedildi (401/403) - izin "Read statistics" mi?');
  if (!r.ok) throw new Error(yol.split('?')[0] + ' -> HTTP ' + r.status);
  return r.json();
}
async function aralik(token, bas, bit) {
  const j = await gc(`/api/v0/stats/hits?start=${bas}&end=${bit}&limit=500`, token);
  return (j.hits || []).map(h => ({ yol: h.path_name || h.path || '', adet: h.count || 0, olay: !!h.event }));
}
async function odenen() {
  try {
    const r = await fetch(SB + '/rest/v1/rpc/paket_secim_sayac', { method: 'POST', headers: { apikey: SB_ANON, Authorization: 'Bearer ' + SB_ANON, 'Content-Type': 'application/json' }, body: '{}' });
    if (!r.ok) return null;
    const d = await r.json();
    return Array.isArray(d) ? d.reduce((a, x) => a + (x.satilan || 0), 0) : null;
  } catch (e) { return null; }
}

function sinav() {
  const ornek = [
    { yol: '/', adet: 100 }, { yol: '/index.html', adet: 20 }, { yol: '/seviye-testi.html', adet: 50 },
    { yol: 'seviye/sgs/basla', adet: 40, olay: true }, { yol: 'seviye/yet/basla', adet: 5, olay: true },
    { yol: 'seviye/sgs/bitti', adet: 30, olay: true }, { yol: 'seviye/sgs/form-dolduruldu', adet: 12, olay: true },
    { yol: 'satin-al/sec/sgs', adet: 6, olay: true }, { yol: 'satin-al/siparis/sgs', adet: 2, olay: true },
    { yol: 'bilinmeyen/olay', adet: 3, olay: true }, { yol: '/gtip.html', adet: 9 },
  ];
  const t = topla(ornek);
  const vakalar = [
    ['ana sayfa / ve /index.html toplanır', t.say['Ana sayfa'] === 120],
    ['sgs + yet basla toplanır', t.say['Teste başladı'] === 45],
    ['satın alma olayları ayrı adım', t.say['Paket seçti'] === 6 && t.say['Sipariş verdi'] === 2],
    ['eşleşmeyen OLAY listelenir', t.eslesmeyen.length === 1 && t.eslesmeyen[0] === 'bilinmeyen/olay'],
    ['eşleşmeyen SAYFA olay listesine girmez', t.eslesmeyen.indexOf('/gtip.html') < 0],
    ['yüzde: 12/30 -> %40', yuzde(12, 30) === '%40'],
    ['yüzde: payda 0 -> —', yuzde(3, 0) === '—'],
  ];
  let k = 0; for (const [ad, ok] of vakalar) { if (!ok) { k++; console.log('  YANLIS: ' + ad); } }
  console.log('HUNI RAPORU OZ-SINAVI: ' + (vakalar.length - k) + '/' + vakalar.length);
  process.exit(k ? 1 : 0);
}

(async () => {
  const args = process.argv.slice(2);
  if (args.includes('--sinav')) return sinav();
  const ci = args.indexOf('--cikti'), cikti = ci > -1 ? args[ci + 1] : null;
  const token = process.env.GOATCOUNTER_TOKEN;
  const gun = n => new Date(Date.now() + n * 86400000).toISOString().slice(0, 10);
  let metin;
  if (!token) {
    metin = 'Huni raporu çıkarılamadı: GOATCOUNTER_TOKEN tanımlı değil.\n'
      + 'Kurulum (bir kez, 2 dk): mevzuatradar.goatcounter.com > Settings > API tokens > yalnız "Read statistics" izniyle anahtar üret;\n'
      + 'GitHub > Settings > Secrets and variables > Actions > New secret: GOATCOUNTER_TOKEN.';
    console.log('GOATCOUNTER_TOKEN yok - rapor yalnız kurulum notu.');
  } else {
    const [dunH, haftaH, od] = await Promise.all([aralik(token, gun(-1), gun(-1)), aralik(token, gun(-7), gun(-1)), odenen()]);
    const dun = topla(dunH), hafta = topla(haftaH);
    metin = 'TETİKTE HUNİ RAPORU · dün ' + gun(-1) + ' · son 7 gün ' + gun(-7) + '..' + gun(-1) + '\n\n'
      + tablo(dun, hafta) + '\n\n'
      + 'Ödenmiş sipariş (tüm zamanlar, sipariş tablosundan): ' + (od === null ? 'okunamadı' : od) + '\n'
      + (hafta.eslesmeyen.length ? '\nEşleşmeyen olaylar (huniye girmedi): ' + Array.from(new Set(hafta.eslesmeyen)).join(', ') + '\n' : '')
      + '\nNot: reklam engelleyici kullananlar sayılmaz; oranlar yön gösterir, kesin sayı değildir.';
    console.log('Huni raporu hazır (' + metin.split('\n').length + ' satır). Tablo günlüğe basılmaz (günlük herkese açık).');
  }
  if (cikti) fs.writeFileSync(cikti, metin, 'utf8');
})().catch(e => { console.error('KIRMIZI:', e.message); process.exit(1); });
