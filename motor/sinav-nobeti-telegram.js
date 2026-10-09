#!/usr/bin/env node
/* ============================================================================
 *  SINAV NÖBETİ → TELEGRAM AYAĞI (09.10.2026, Cem "Telegram'ı haber hattına bağlayalım")
 *  motor/sinav-nobeti.js yeni bir SINAV duyurusu yakaladığında aynı koşuda t.me/tetiktecom kanalına haber düşer:
 *  başlık + 2 cümle (yalnız başlıktan ve tarihten türetilir; duyurunun gövdesi OKUNMADIĞI için içerik özeti YAZILMAZ —
 *  "önce resmî kaynak, sonra yaz") + "resmî sınav duyurusu: <link>" + varsa yerel görsel (foto) + "Kaynak: …" satırı.
 *
 *  KÜTÜK / DAMGA: gönderilen duyurunun veri/sinav-nobeti.json kaydına `telegram: {mesaj, tarih}` damgası yazılır.
 *    Aday = damgasız VE gorulme ≥ TELEGRAM_BASLANGIC (09.10.2026; eski 50 tohum duyuru GİTMEZ). Koşu başına en çok 5.
 *    Damgalı duyuru ikinci koşuda GİTMEZ (öz-sınavla ölçüldü, aşağıda). Gönderim düşerse damga yazılmaz → sonraki koşuda yeniden denenir.
 *  ANAHTAR: ortam TELEGRAM_BOT_TOKEN (Actions secret) ya da kasa _yerel-veri-kasasi/telegram-bot.key. Anahtar yoksa "TELEGRAM KÖR"
 *    yazar, robot DÜŞMEZ, damga yazılmaz (anahtar gelince gider; başlangıç tarihi + 5 tavanı seli önler).
 *  METİN KURALI (reklam değil haber): kurs/eğitim/hoca/MEB onaylı/Türkiye geneli YOK; kurum adı yalnız kaynak olarak.
 *    Resmî başlık aynen alıntılanır (başlıkta "eğitim" geçebilir — kurumun kendi sözü, bizim sözümüz değil).
 *  GÖRSEL: motor/sinav-nobeti-gorsel.js'in YEREL çıktısı (Masaüstü\Tetikte-Instagram\sinav-nobeti\<tarih>-<kurum>-<kısa>-gonderi.png)
 *    varsa foto+açıklama, yoksa metin. Bulutta görsel basılmaz → bulut koşusu her zaman METİN gönderir.
 *  Kullanım (robot içinden çağrılır): require → { metinKur, telegramGonder }
 *    node motor/sinav-nobeti-telegram.js --kuru [--url <duyuru>]   → ne gideceğini yazar, göndermez
 *    node motor/sinav-nobeti-telegram.js --sinav [--mutasyon]       → öz-sınav (dogrula.yml)
 *  🚫 GÖRMEZ: duyurunun içeriği (gövde okunmaz) · Telegram'da nasıl göründüğü · başlıkta sınav kelimesi olmayan duyuru (süzgeç üstte) ·
 *     aynı duyurunun iki kurumda iki ayrı linkle yayımlanması (iki haber gider).
 * ==========================================================================*/
'use strict';
const fs = require('fs'), path = require('path'), os = require('os');
const KOK = path.join(__dirname, '..');
const TELEGRAM_BASLANGIC = process.env.SN_TELEGRAM_BASLANGIC || '2026-10-09';
const KOSU_TAVANI = 5;
const YASAK = /(kurs|e[ğg]itim|hoca|MEB onayl|T[üu]rkiye geneli)/i;   // bizim metnimizde geçemez (başlık hariç)
const MUT = process.env.SN_MUTASYON || '';                             // öz-sınav mutasyonları: kutuk | kaynak | yasak | baslangic
const esc = s => String(s == null ? '' : s).replace(/[&<>]/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;' }[c]));
const trTarih = iso => { const [y, a, g] = String(iso).split('-'); return `${g}.${a}.${y}`; };
const kisa = s => String(s).toLocaleLowerCase('tr').replace(/ç/g, 'c').replace(/ğ/g, 'g').replace(/ı/g, 'i').replace(/ö/g, 'o').replace(/ş/g, 's').replace(/ü/g, 'u').replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '').slice(0, 40);
const alanAdi = url => { try { return new URL(url).hostname.replace(/^www\./, ''); } catch { return ''; } };

/** Gönderilecek metin (Telegram HTML). Yalnız resmî başlık + tarih + link; içerik özeti yok. */
function metinKur(d) {
  const kurum = esc(d.kurum), tarih = trTarih(d.tarih), alan = alanAdi(d.url);
  const satirlar = [
    `📌 <b>Sınav Nöbeti</b>`,
    ``,
    `<b>${esc(d.baslik)}</b>`,
    ``,
    `${kurum} ${tarih} tarihinde bu başlıkla bir duyuru yayımladı. Ayrıntı ve bağlayıcı metin duyurunun kendisinde; paylaşmadan ve plan yapmadan önce aslını okuyun.`,
    ``,
    `Resmî sınav duyurusu: ${esc(d.url)}`,
    ``,
    `Tüm sınav duyuruları tek listede: https://tetikte.com/sinav-nobeti.html`,
  ];
  if (MUT !== 'kaynak') satirlar.push(`Kaynak: ${esc(alan)}`);
  if (MUT === 'yasak') satirlar.push(`Kurs kaydı için bize yazın.`);
  return satirlar.join('\n');
}

/** Yerel görsel (varsa): sinav-nobeti-gorsel.js'in adlandırmasıyla AYNI. */
function gorselYolu(d) {
  const ad = path.join(os.homedir(), 'OneDrive', 'Masaüstü', 'Tetikte-Instagram', 'sinav-nobeti', `${d.tarih}-${kisa(d.kurum)}-${kisa(d.baslik)}-gonderi.png`);
  return fs.existsSync(ad) ? ad : null;
}

/** Aday süzgeci: damgasız + başlangıç tarihinden sonra görülmüş (ya da --url ile zorlanmış). */
function adaylar(duyurular, zorUrl) {
  return duyurular.filter(d => {
    if (MUT !== 'kutuk' && d.telegram) return false;
    if (zorUrl) return d.url === zorUrl;
    return MUT === 'baslangic' ? true : String(d.gorulme || '') >= TELEGRAM_BASLANGIC;
  }).slice(0, KOSU_TAVANI);
}

/**
 * Yeni duyuruları kanala gönderir, kayda damga yazar (kaydı DÖNDÜRÜR; dosyaya yazmak çağıranın işi).
 * secenek: { kuru, zorUrl, gonderici: {metinGonder, fotoGonder, anahtarVar}, bugun }
 * Dönüş: { gonderilen: [...], kor: bool }
 */
async function telegramGonder(duyurular, secenek = {}) {
  const tg = secenek.gonderici || require(path.join(KOK, 'arac', 'telegram-kanal.js'));
  const bugun = secenek.bugun || new Date().toISOString().slice(0, 10);
  const log = secenek.sessiz ? () => {} : console.log;
  const liste = adaylar(duyurular, secenek.zorUrl);
  const gonderilen = [];
  if (!liste.length) { log('telegram: yeni duyuru yok, gönderim yok'); return { gonderilen, kor: false }; }
  if (!secenek.kuru && !tg.anahtarVar()) { log(`telegram KÖR: bot anahtarı yok (TELEGRAM_BOT_TOKEN) — ${liste.length} duyuru bekliyor, damga yazılmadı`); return { gonderilen, kor: true }; }
  for (const d of liste) {
    const metin = metinKur(d), gorsel = gorselYolu(d);
    if (secenek.kuru) { log(`KURU telegram ${gorsel ? 'foto ' + path.basename(gorsel) : 'metin'} ->\n---\n${metin}\n---`); gonderilen.push({ url: d.url, kuru: true }); continue; }
    try {
      const r = gorsel ? await tg.fotoGonder(gorsel, metin) : await tg.metinGonder(metin);
      d.telegram = { mesaj: r.message_id, tarih: bugun };
      gonderilen.push({ url: d.url, mesaj: r.message_id });
      log(`telegram GÖNDERİLDİ: mesaj ${r.message_id} · ${d.kurum} · ${d.baslik.slice(0, 60)}`);
    } catch (e) { log(`telegram HATA (damga yazılmadı, sonraki koşuda yeniden denenir): ${e.message}`); }
  }
  return { gonderilen, kor: false };
}

module.exports = { metinKur, telegramGonder, adaylar, TELEGRAM_BASLANGIC };

// ---------------------------------------------------------------- öz-sınav
async function sinav() {
  const vaka = { kurum: 'TESMER', url: 'https://www.tesmer.org.tr/2026-3-donem-staja-giris-sinavi-basvurulari/', baslik: '2026/3 Dönem Staja Giriş Sınavı Başvuruları & Takvim <test>', tarih: '2026-10-09', gorulme: '2026-10-09' };
  const hatalar = [];
  const ok = (k, m) => { if (!k) hatalar.push(m); };
  // 1) metin kuralları
  const m = metinKur(vaka);
  const bizimMetin = m.replace(esc(vaka.baslik), '');
  ok(m.includes('<b>' + esc(vaka.baslik) + '</b>'), 'başlık kalın ve HTML kaçışlı değil');
  ok(m.includes('Resmî sınav duyurusu: ' + esc(vaka.url)), '"Resmî sınav duyurusu: <link>" satırı yok');
  ok(/\nKaynak: tesmer\.org\.tr$/.test(m), 'son satır "Kaynak: tesmer.org.tr" değil');
  ok(!YASAK.test(bizimMetin), 'yasak kelime (kurs/eğitim/hoca/MEB onaylı/Türkiye geneli) bizim metinde geçiyor');
  ok(!/<test>/.test(m) && m.includes('&lt;test&gt;'), 'başlıktaki < > kaçışlanmadı');
  ok(m.includes('09.10.2026'), 'tarih TR biçiminde değil');
  ok(m.length <= 1024, 'metin 1024 karakteri aşıyor (foto açıklaması sığmaz)');
  // 2) kütük: iki koşu — ilkinde 1 gider, ikincisinde 0; tohum (eski) duyuru hiç gitmez; düşen gönderim damgalanmaz
  let sayac = 0;
  const sahte = { anahtarVar: () => true, metinGonder: async () => ({ message_id: 100 + (++sayac) }), fotoGonder: async () => ({ message_id: 100 + (++sayac) }) };
  const kayit = [{ ...vaka }, { kurum: 'TÜRMOB', url: 'https://www.turmob.org.tr/haberler/x/eski', baslik: 'Eski tohum duyuru', tarih: '2026-10-01', gorulme: '2026-10-05' }];
  const k1 = await telegramGonder(kayit, { gonderici: sahte, bugun: '2026-10-09', sessiz: true });
  ok(k1.gonderilen.length === 1 && k1.gonderilen[0].url === vaka.url, `1. koşu 1 gönderim beklendi, ${k1.gonderilen.length}`);
  ok(kayit[0].telegram && kayit[0].telegram.mesaj === 101 && kayit[0].telegram.tarih === '2026-10-09', 'damga yazılmadı');
  ok(!kayit[1].telegram, 'tohum (başlangıçtan önce görülen) duyuru gönderildi');
  const k2 = await telegramGonder(kayit, { gonderici: sahte, bugun: '2026-10-09', sessiz: true });
  ok(k2.gonderilen.length === 0, `2. koşu 0 gönderim beklendi, ${k2.gonderilen.length} (AYNI DUYURU İKİ KEZ GİTTİ)`);
  ok(sayac === 1, `sahte gönderici ${sayac} kez çağrıldı, 1 beklendi`);
  // 3) kuru koşu göndermez, damga yazmaz
  const k3 = await telegramGonder([{ ...vaka }], { gonderici: sahte, kuru: true, sessiz: true });
  ok(k3.gonderilen.length === 1 && k3.gonderilen[0].kuru && sayac === 1, 'kuru koşu gönderdi ya da saymadı');
  // 4) anahtar yoksa KÖR: gönderim yok, damga yok, hata yok
  const kayit4 = [{ ...vaka }];
  const k4 = await telegramGonder(kayit4, { gonderici: { anahtarVar: () => false, metinGonder: async () => { throw new Error('çağrılmamalı'); } }, sessiz: true });
  ok(k4.kor && !kayit4[0].telegram && k4.gonderilen.length === 0, 'anahtarsız koşu KÖR dönmedi ya da damga yazdı');
  // 5) gönderim düşerse damga yazılmaz (sonraki koşuda yeniden)
  const kayit5 = [{ ...vaka }];
  const k5 = await telegramGonder(kayit5, { gonderici: { anahtarVar: () => true, metinGonder: async () => { throw new Error('Telegram: 429'); } }, sessiz: true });
  ok(!kayit5[0].telegram && k5.gonderilen.length === 0, 'düşen gönderim damgalandı');
  // 6) koşu tavanı
  const cok = Array.from({ length: 9 }, (_, i) => ({ ...vaka, url: vaka.url + i }));
  const k6 = await telegramGonder(cok, { gonderici: sahte, sessiz: true });
  ok(k6.gonderilen.length === KOSU_TAVANI, `tavan ${KOSU_TAVANI} beklendi, ${k6.gonderilen.length}`);
  // 7) --url zorlaması başlangıçtan eski duyuruyu da gönderir, ama damgalıysa göndermez
  const kayit7 = [{ ...kayit[1] }];
  const k7 = await telegramGonder(kayit7, { gonderici: sahte, zorUrl: kayit7[0].url, sessiz: true });
  const k7b = await telegramGonder(kayit7, { gonderici: sahte, zorUrl: kayit7[0].url, sessiz: true });
  ok(k7.gonderilen.length === 1 && k7b.gonderilen.length === 0, '--url zorlaması: ilk 1, ikinci 0 beklendi');
  return hatalar;
}
async function mutasyon() {
  // her mutasyonda öz-sınav KIRMIZI düşmeli; düşmüyorsa sınav kör
  const { spawnSync } = require('child_process');
  const sonuc = [];
  for (const mut of ['kutuk', 'kaynak', 'yasak', 'baslangic']) {
    const r = spawnSync(process.execPath, [__filename, '--sinav'], { env: { ...process.env, SN_MUTASYON: mut }, encoding: 'utf8' });
    sonuc.push({ mut, dustu: r.status !== 0 });
    console.log(`mutasyon ${mut.padEnd(10)} → ${r.status !== 0 ? 'KIRMIZI (beklenen)' : 'YEŞİL — SINAV KÖR'}`);
  }
  return sonuc.filter(s => !s.dustu).map(s => s.mut);
}
if (require.main === module) (async () => {
  const arg = (ad) => { const i = process.argv.indexOf(ad); return i > 0 ? process.argv[i + 1] : null; };
  if (process.argv.includes('--sinav')) {
    const h = await sinav();
    h.forEach(x => console.error('  KIRMIZI: ' + x));
    console.log(`sinav-nobeti-telegram öz-sınav: ${h.length ? 'KIRMIZI ' + h.length + ' hata' : 'YEŞİL (7 vaka)'}`);
    if (h.length) process.exit(1);
    if (process.argv.includes('--mutasyon')) { const kor = await mutasyon(); if (kor.length) { console.error('KIRMIZI: mutasyon yakalanmadı: ' + kor.join(', ')); process.exit(1); } console.log('mutasyon: 4/4 KIRMIZI'); }
    return;
  }
  if (process.argv.includes('--kuru')) {
    const kayit = JSON.parse(fs.readFileSync(path.join(KOK, 'veri', 'sinav-nobeti.json'), 'utf8')).duyurular;
    const r = await telegramGonder(kayit, { kuru: true, zorUrl: arg('--url') });
    console.log(`kuru: ${r.gonderilen.length} aday`);
    return;
  }
  console.error('kullanım: --kuru [--url <duyuru>] | --sinav [--mutasyon]'); process.exit(2);
})().catch(e => { console.error('HATA ' + e.message); process.exit(1); });
