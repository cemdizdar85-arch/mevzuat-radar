#!/usr/bin/env node
/* ============================================================================
 *  SINAV ÖNCESİ HATIRLATMA (06.10.2026, Cem "1.2.3 üçünü de yap" — GM önerisi 2)
 *
 *  NE YAPAR: seviye testini çözüp karne alan ve "kampanya/hatırlatma" kutusunu İŞARETLEYEN kişilere, sınava 1 hafta
 *  kala (Cem 06.10: 2 değil 1 HAFTA) "seviyeni yeniden ölç" maili atar. İki amaç: (1) aday ilerlemesini görür, (2) sınava 14 günden yakın çözülen
 *  test kalibrasyona girer (seviye-model.js KALİBRASYON KURALI). Sayfa o dönemde bir ücretsiz hak daha verir
 *  (seviye-testi.html hakKullanildi, son 7 gün).
 *
 *  ⛔ ONAYSIZ GÖNDERMEZ: varsayılan KURU (yalnız alıcı SAYISI). Göndermek için --gonder VE ortamda
 *     HATIRLATMA_ONAY="<sinav> <YYYY-MM-DD> Cem onayı" (sinav ve tarih bu koşuyla aynı olmalı). Cem metni ve gönderimi
 *     onaylamadan kimse bu değişkeni yazmaz (CLAUDE.md: mesaj göndermek Cem onayıyla).
 *  ⛔ GÜNLÜK PUBLIC: e-posta adresi, ad, yüzde BASILMAZ; yalnız sayı.
 *  Çift gönderim yok: her gönderim form_kayit'a "Sınav öncesi hatırlatma" + sınav + dönem olarak yazılır, sonraki koşu atlar.
 *  Alıcı: form_kayit konu "Seviye testi karnesi", alanlar."Kampanya/hatırlatma izni" = "evet", sınav eşleşir
 *     (Yeterlilik kaydında alanlar."Sınav" = "Yeterlilik"; yoksa SGS). Aynı adres bir kez; son testi 7 günden yakınsa atlanır.
 *  🚫 GÖRMEZ: izni sonradan geri alan kişi (ret yanıtı elle işlenir: form_kayit'a "Hatırlatma reddi" yazılır, betik atlar) ·
 *     üye olup karne almamış kişi · adresin hâlâ geçerli olduğu.
 *
 *  Kullanım: node motor/sinav-oncesi-hatirlatma.mjs --sinav sgs            (kuru: sayı)
 *            HATIRLATMA_ONAY="sgs 2026-11-07 Cem onayı" node motor/sinav-oncesi-hatirlatma.mjs --sinav sgs --gonder
 *            node motor/sinav-oncesi-hatirlatma.mjs --ornek sgs  (örnek maili scratch'e yazar; gönderim yok)
 * ==========================================================================*/
import { kurumsalMail } from '../radar-app/edge/karne-gonder.ts';
import fs from 'node:fs';

const SB = 'https://bjrleanjpyujtajmazxn.supabase.co';
const SK = (process.env.SUPABASE_SERVICE_KEY || '').trim();
const RESEND_KEY = (process.env.RESEND_KEY || '').trim(), RESEND_FROM = (process.env.RESEND_FROM || 'Tetikte <bildirim@tetikte.com>').trim();
const arg = (a, v) => { const i = process.argv.indexOf(a); return i > 0 ? process.argv[i + 1] : v; };
const SINAVLAR = {   // veri/sinav-takvimi.json (SGS 2026/3, SMMM 2026/3)
  sgs: { ad: 'Staja Giriş', tarih: '2026-11-21', tarihYazi: '21 Kasım', donem: '2026/3', test: 'seviye-testi.html' },
  yeterlilik: { ad: 'SMMM Yeterlilik', tarih: '2026-11-28', tarihYazi: '28 Kasım', donem: '2026/3', test: 'seviye-testi.html?sinav=yeterlilik' },
};
const KAYIT_KONU = 'Sınav öncesi hatırlatma', RET_KONU = 'Hatırlatma reddi';
const kac = s => String(s == null ? '' : s).replace(/[&<>"]/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));

export function mailKur(sinav, onceki) {
  const S = SINAVLAR[sinav], site = 'https://tetikte.com';
  const ilk = onceki && onceki.tarih ? new Date(onceki.tarih).toLocaleDateString('tr-TR', { day: 'numeric', month: 'long', timeZone: 'Europe/Istanbul' }) : '';
  const gecmis = onceki && onceki.gecme ? `${ilk} günü çözdüğün seviye testinde geçme ihtimalin ${onceki.gecme} çıkmıştı. O günden beri çalıştın; şimdi nerede olduğunu gör.` : 'Şimdi nerede olduğunu gör.';
  const konu = `${S.ad} sınavına 1 hafta kaldı: seviyeni yeniden ölç`;
  const metin = [`Merhaba,`, ``, `${S.tarihYazi}'daki ${S.ad} sınavına 1 hafta kaldı. ${gecmis}`, ``, `30 soru, yaklaşık 20 dakika, ücretsiz: ${site}/${S.test}`, ``,
    `Bu son testin bize de yardım eder: sınavdan sonra gerçek sonucunu yazarsan, tahmini senin gibi adayların gerçek sonuçlarıyla ayarlarız.`, ``, `Sınava tetikte gir.`, ``,
    `Bu e-postayı, seviye testinde hatırlatma almak istediğin için aldın. Bir daha almak istemezsen bu e-postayı "ret" diye yanıtlaman yeter.`].join('\n');
  const html = kurumsalMail(`<p style="font-size:12px;letter-spacing:.12em;text-transform:uppercase;color:#8d6c38;font-weight:700;margin:0 0 6px">Tetikte · ${kac(S.ad)}</p>
<h1 style="font-size:24px;margin:0 0 10px">Sınava 1 hafta kaldı</h1>
<p style="margin:0 0 12px">${kac(S.tarihYazi)}'daki ${kac(S.ad)} sınavına 1 hafta kaldı. ${kac(gecmis)}</p>
<p style="margin:0 0 18px"><a href="${site}/${S.test}" style="background:#f5a524;color:#1b1206;text-decoration:none;font-weight:800;padding:11px 18px;border-radius:8px;display:inline-block">Seviyemi yeniden ölç →</a>
&nbsp; <span style="color:#6b7280">30 soru · ~20 dakika · ücretsiz</span></p>
<p style="margin:0 0 10px;color:#4b5563">Bu son testin bize de yardım eder: sınavdan sonra gerçek sonucunu yazarsan, tahmini senin gibi adayların gerçek sonuçlarıyla ayarlarız.</p>
`, 'Bu e-postayı, seviye testinde hatırlatma almak istediğin için aldın. Bir daha almak istemezsen bu e-postayı "ret" diye yanıtlaman yeter.');
  return { konu, metin, html };
}

async function sb(yol, sec = {}) {
  const r = await fetch(SB + '/rest/v1/' + yol, { ...sec, headers: { apikey: SK, Authorization: 'Bearer ' + SK, 'Content-Type': 'application/json', ...(sec.headers || {}) } });
  if (!r.ok) throw new Error(yol.split('?')[0] + ' http ' + r.status); return sec.method === 'POST' ? null : r.json();
}
async function hepsi(yol) { const o = []; for (let i = 0; ; i += 1000) { const p = await sb(yol + `&limit=1000&offset=${i}`); o.push(...p); if (p.length < 1000) return o; } }

async function ana() {
  const ornek = arg('--ornek');
  if (ornek) { const m = mailKur(ornek, { gecme: '%37', tarih: '2026-10-06' }); const y = arg('--cikti', 'hatirlatma-ornek.html'); fs.writeFileSync(y, m.html); console.log('örnek yazıldı: ' + y + ' · konu: ' + m.konu); return; }
  const sinav = arg('--sinav'); const S = SINAVLAR[sinav]; if (!S) throw new Error('--sinav sgs|yeterlilik');
  if (!SK) throw new Error('SUPABASE_SERVICE_KEY yok');
  const gonder = process.argv.includes('--gonder');
  const bugun = new Date().toISOString().slice(0, 10);
  if (gonder) {
    const onay = (process.env.HATIRLATMA_ONAY || '').trim();
    if (!new RegExp(`^${sinav} ${bugun} .*onay`, 'i').test(onay)) throw new Error(`ONAY YOK: HATIRLATMA_ONAY "${sinav} ${bugun} Cem onayı" olmalı - gönderilmedi`);
    if (!RESEND_KEY) throw new Error('RESEND_KEY yok');
    const kalan = Math.round((new Date(S.tarih + 'T00:00:00+03:00') - Date.now()) / 864e5);
    if (kalan < 4 || kalan > 8) throw new Error(`PENCERE DIŞI: sınava ${kalan} gün var (gönderim 4-8 gün kala) - gönderilmedi`);
  }
  const sinir = new Date(new Date(S.tarih + 'T00:00:00+03:00') - 7 * 864e5);
  const karne = await hepsi(`form_kayit?select=eposta,alanlar,olusturma&konu=eq.${encodeURIComponent('Seviye testi karnesi')}&order=olusturma.asc`);
  const gitti = new Set((await hepsi(`form_kayit?select=eposta,alanlar&konu=eq.${encodeURIComponent(KAYIT_KONU)}`)).filter(x => (x.alanlar || {}).Sınav === sinav && (x.alanlar || {}).Dönem === S.donem).map(x => String(x.eposta || '').toLowerCase()));
  const ret = new Set((await hepsi(`form_kayit?select=eposta&konu=eq.${encodeURIComponent(RET_KONU)}`)).map(x => String(x.eposta || '').toLowerCase()));
  const kisi = new Map();   // adres -> son kayıt (izin son kayda göre)
  for (const k of karne) {
    const a = k.alanlar || {}, ks = a['Sınav'] === 'Yeterlilik' ? 'yeterlilik' : 'sgs'; if (ks !== sinav) continue;
    const e = String(k.eposta || '').toLowerCase(); if (!e) continue;
    kisi.set(e, { izin: a['Kampanya/hatırlatma izni'] === 'evet', gecme: a['Geçme ihtimali'], tarih: k.olusturma });
  }
  const say = { kayit: kisi.size, izinsiz: 0, yakin: 0, zaten: 0, ret: 0, alici: 0, gitti: 0, dustu: 0 };
  const alici = [];
  for (const [e, k] of kisi) {
    if (!k.izin) { say.izinsiz++; continue; } if (ret.has(e)) { say.ret++; continue; } if (gitti.has(e)) { say.zaten++; continue; }
    if (new Date(k.tarih) >= sinir) { say.yakin++; continue; }
    alici.push([e, k]);
  }
  say.alici = alici.length;
  if (gonder) {
    for (const [e, k] of alici) {
      const m = mailKur(sinav, k);
      const r = await fetch('https://api.resend.com/emails', { method: 'POST', headers: { Authorization: 'Bearer ' + RESEND_KEY, 'Content-Type': 'application/json' },
        body: JSON.stringify({ from: RESEND_FROM, to: [e], subject: m.konu, text: m.metin, html: m.html }) });
      if (r.ok) { say.gitti++; await sb('form_kayit', { method: 'POST', headers: { Prefer: 'return=minimal' }, body: JSON.stringify({ konu: KAYIT_KONU, gonderen: 'motor/sinav-oncesi-hatirlatma.mjs', eposta: e, alanlar: { 'Sınav': sinav, 'Dönem': S.donem } }) }); }
      else say.dustu++;
      await new Promise(r => setTimeout(r, 600));   // Resend hız sınırı
    }
  }
  console.log(`HATIRLATMA ${sinav} ${S.donem} ${gonder ? 'GÖNDERİM' : 'KURU'}: karne alan ${say.kayit} · izinsiz ${say.izinsiz} · ret ${say.ret} · zaten gitti ${say.zaten} · son 7 günde çözdü ${say.yakin} · ALICI ${say.alici}` + (gonder ? ` · gitti ${say.gitti} · düştü ${say.dustu}` : ''));
  if (gonder && say.dustu) process.exitCode = 1;
}
if (import.meta.url === new URL(process.argv[1], 'file:').href || process.argv[1].endsWith('sinav-oncesi-hatirlatma.mjs')) ana().catch(e => { console.log('HATIRLATMA HATA: ' + e.message); process.exitCode = 1; });
