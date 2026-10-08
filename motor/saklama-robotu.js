// motor/saklama-robotu.js — KVKK SAKLAMA SÜRESİ ROBOTU (14.09.2026)
//
// kvkk.html 1. bölümdeki saklama sözlerini KODLA tutar. Metin "2 yıl" diyorsa
// 2 yılı dolan kayıt ya kimliksizleşir ya silinir; söz yalnız kâğıtta kalmaz.
//
//   Kural                       Tablo           İşlem (kesim = bugünden tam 2 takvim yılı önce)
//   soru çözme kaydı            cevap_kayit     oturum -> null  (toplu istatistik kalır)
//   hesap kâğıdı                kagit_kayit     oturum + metin -> null (serbest metin kişisel veri taşıyabilir;
//                                               eksik/tablo_disi sayıları istatistik olarak kalır)
//   form / karne / hata bildir  form_kayit      satır silinir — AMA duyuru izni "evet" olan satır
//                                               KALIR: kvkk.html "izin kaydı, ispat için" saklanır der.
//   takip formu (Kuruluş Nöbeti) kurulus_nobet  satır silinir
//   SİPARİŞ ONAY KAYDI          form_kayit      konusu "YENİ SİPARİŞ" olan satır 3 YIL sonra silinir (08.10.2026:
//                                               Mesafeli Sözleşmeler Yön. m.20/1 bilgilendirme+onay kayıtları 3 yıl;
//                                               Tetikte-Hukuk/resmi-mesafeli-sozlesmeler-yonetmeligi.md). 2 yıl kuralı bu satırlara DOKUNMAZ.
//   Nöbetçi soruları            nobetci_soru    1 yıl (tarih) sonra silinir   } 08.10.2026 Cem "mevzuat süreleri + kodu düzelt":
//   Ekibe sor                   ekibe_soru      1 yıl (tarih) sonra silinir   } önceden hiç silinmiyordu (yasal tarama)
//   paylaşım koruması cihazları uye_cihazlar    son_gorulme 6 ay geride ise silinir
//   sipariş + kart ödemesi      siparisler,     10 yıl: kaydın yılını izleyen takvim yılı başından 10 yıl (TTK m.82/5-6,
//                               kart_odemeleri  VUK m.253; resmi-saklama-vuk-ttk.md) — kesim = (bu yıl − 10)'un 1 Ocak'ı
//   hız sınırı sayacı (IP)      rate_log        1 günden eski satır silinir (sayaç 10 dk'ya bakar;
//                                               RPC içindeki %5 olasılıklı temizlik trafik azken çalışmıyor —
//                                               14.09 ölçümü: 2 gün önceki IP satırları duruyordu)
//
// "Hesap kapatılınca 30 gün içinde silinir" sözü bu robotta DEĞİL: hesap kapatma elle
// gelen "hesabımı sil" e-postasıyla başlar -> motor/hesap-sil.js.
//
// Kullanım:
//   node motor/saklama-robotu.js           KURU: ne yapılacağını sayar, hiçbir şeye dokunmaz
//   node motor/saklama-robotu.js --yaz     uygular (günlük akış: .github/workflows/saklama-robotu.yml)
//   node motor/saklama-robotu.js --sinav   öz-sınav (ağ yok)
//
// Kapılar: kesim tarihi bugünden 729 günden yakınsa DURUR (yanlış hesap canlı veriyi silmesin);
// tek koşuda silinecek satır TAVAN'ı aşarsa DURUR (beklenmedik yığın = önce insan baksın).
// Anahtar: SUPABASE_SERVICE_KEY. Supabase gizli anahtarı tarayıcı benzeri UA ile reddeder -> UA açık verilir.
'use strict';

const SB = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1';
const UA = 'tetikte-saklama-robotu/1.0';
const TAVAN = 5000;
const GUN = 24 * 3600 * 1000;

function kesimTarihi(simdi, yil) {
  const d = new Date(simdi.getTime());
  d.setUTCFullYear(d.getUTCFullYear() - yil);
  return d;
}

// form_kayit.alanlar içinde duyuru/kampanya izni "evet" (ya da true) olan satır rıza kanıtıdır.
function rizaKaniti(alanlar) {
  if (!alanlar || typeof alanlar !== 'object') return false;
  return Object.keys(alanlar).some(k => {
    if (!/izin|r[ıi]za|pazarlama|kampanya|duyuru/i.test(k)) return false;
    const v = alanlar[k];
    return v === true || (typeof v === 'string' && /^(evet|true|var|1)$/i.test(v.trim()));
  });
}

function kesimGuvenli(kesim, simdi, enAzGun) {
  return (simdi.getTime() - kesim.getTime()) >= (enAzGun || 729) * GUN;
}
// 08.10: sipariş onay kaydı form_kayit'ta "YENİ SİPARİŞ TT-… — tutar TL" konusuyla durur (satin-al.html form gönderimi)
function siparisKaydi(konu) {
  if (process.env.SR_MUTASYON === 'siparis-gormez') return false;
  return /^\s*YEN[İI]\s+S[İI]PAR[İI][ŞS]/i.test(String(konu || ''));
}
function kesimAy(simdi, ay) { const d = new Date(simdi.getTime()); d.setUTCMonth(d.getUTCMonth() - ay); return d; }
// TTK m.82: süre takvim yılı sonundan işler -> X yılındaki kayıt (X+10) yılı sonuna dek kalır -> kesim = (bu yıl - 10) 1 Ocak
function kesimTakvim10(simdi) { return new Date(Date.UTC(simdi.getUTCFullYear() - 10, 0, 1)); }

async function istek(yol, secenek) {
  const K = process.env.SUPABASE_SERVICE_KEY;
  const h = Object.assign({ apikey: K, Authorization: `Bearer ${K}`, 'User-Agent': UA }, (secenek && secenek.headers) || {});
  const r = await fetch(`${SB}/${yol}`, Object.assign({}, secenek, { headers: h }));
  if (!r.ok) throw new Error(`${(secenek && secenek.method) || 'GET'} ${yol.split('?')[0]} -> ${r.status} ${(await r.text()).slice(0, 200)}`);
  return r;
}

async function say(tablo, filtre) {
  const r = await istek(`${tablo}?select=*&${filtre}`, { method: 'HEAD', headers: { Prefer: 'count=exact', Range: '0-0' } });
  const cr = r.headers.get('content-range') || '';
  const n = Number(cr.split('/')[1]);
  if (!Number.isFinite(n)) throw new Error(`${tablo}: sayım okunamadı (${cr})`);
  return n;
}

async function yamala(tablo, filtre, govde) {
  const r = await istek(`${tablo}?${filtre}`, { method: 'PATCH', body: JSON.stringify(govde),
    headers: { 'content-type': 'application/json', Prefer: 'return=minimal,count=exact' } });
  return Number((r.headers.get('content-range') || '').split('/')[1]) || 0;
}

async function sil(tablo, filtre) {
  const r = await istek(`${tablo}?${filtre}`, { method: 'DELETE', headers: { Prefer: 'return=minimal,count=exact' } });
  return Number((r.headers.get('content-range') || '').split('/')[1]) || 0;
}

async function kos(yaz) {
  if (!process.env.SUPABASE_SERVICE_KEY) throw new Error('SUPABASE_SERVICE_KEY yok');
  const simdi = new Date();
  const kesim2 = kesimTarihi(simdi, 2);
  if (!kesimGuvenli(kesim2, simdi)) throw new Error(`KAPI: kesim ${kesim2.toISOString()} bugüne çok yakın`);
  const k2 = encodeURIComponent(kesim2.toISOString());
  const k1g = encodeURIComponent(new Date(simdi.getTime() - GUN).toISOString());
  const rapor = [];
  const not = (kural, aday, yapilan, ek) => rapor.push({ kural, aday, yapilan: yaz ? yapilan : 0, ek: ek || '' });

  // 1) cevap_kayit: oturum kimliksizleştir
  {
    const f = `olusturma=lt.${k2}&oturum=not.is.null`;
    const n = await say('cevap_kayit', f);
    if (n > TAVAN) throw new Error(`KAPI: cevap_kayit ${n} > ${TAVAN}`);
    not('cevap_kayit oturum->null (2 yıl)', n, yaz && n ? await yamala('cevap_kayit', f, { oturum: null }) : 0);
  }
  // 2) kagit_kayit: oturum + serbest metin
  {
    const f = `olusturma=lt.${k2}&or=(oturum.not.is.null,metin.not.is.null)`;
    const n = await say('kagit_kayit', f);
    if (n > TAVAN) throw new Error(`KAPI: kagit_kayit ${n} > ${TAVAN}`);
    not('kagit_kayit oturum+metin->null (2 yıl)', n, yaz && n ? await yamala('kagit_kayit', f, { oturum: null, metin: null }) : 0);
  }
  // 3) form_kayit: sil, rıza kanıtı kalır
  {
    const r = await istek(`form_kayit?select=id,alanlar,konu&olusturma=lt.${k2}&order=olusturma.asc&limit=${TAVAN + 1}`);
    const satir = await r.json();
    if (satir.length > TAVAN) throw new Error(`KAPI: form_kayit ${satir.length} > ${TAVAN}`);
    const silinecek = satir.filter(s => !rizaKaniti(s.alanlar) && !siparisKaydi(s.konu)).map(s => s.id);
    const siparisAtlanan = satir.filter(s => siparisKaydi(s.konu)).length;
    let yapilan = 0;
    if (yaz) {
      for (let i = 0; i < silinecek.length; i += 100) {
        const parca = silinecek.slice(i, i + 100).map(id => `"${id}"`).join(',');
        yapilan += await sil('form_kayit', `id=in.(${encodeURIComponent(parca)})`);
      }
    }
    not('form_kayit sil (2 yıl)', silinecek.length, yapilan, `kalan: rıza kanıtı ${satir.length - silinecek.length - siparisAtlanan} · sipariş onayı (3 yıl kuralında) ${siparisAtlanan}`);
  }
  // 4) kurulus_nobet: sil
  {
    const f = `olusturma=lt.${k2}`;
    const n = await say('kurulus_nobet', f);
    if (n > TAVAN) throw new Error(`KAPI: kurulus_nobet ${n} > ${TAVAN}`);
    not('kurulus_nobet sil (2 yıl)', n, yaz && n ? await sil('kurulus_nobet', f) : 0);
  }
  // 6) 08.10: form_kayit sipariş onayı 3 yıl
  {
    const kesim3 = kesimTarihi(simdi, 3);
    if (!kesimGuvenli(kesim3, simdi, 1094)) throw new Error('KAPI: 3 yıl kesimi bugüne çok yakın');
    const r = await istek(`form_kayit?select=id,konu&olusturma=lt.${encodeURIComponent(kesim3.toISOString())}&order=olusturma.asc&limit=${TAVAN + 1}`);
    const satir = await r.json();
    if (satir.length > TAVAN) throw new Error(`KAPI: form_kayit (3 yıl) ${satir.length} > ${TAVAN}`);
    const sil3 = satir.filter(s => siparisKaydi(s.konu)).map(s => s.id);
    let yapilan = 0;
    if (yaz) for (let i = 0; i < sil3.length; i += 100) {
      const parca = sil3.slice(i, i + 100).map(id => `"${id}"`).join(',');
      yapilan += await sil('form_kayit', `id=in.(${encodeURIComponent(parca)})`);
    }
    not('form_kayit sipariş onayı sil (3 yıl)', sil3.length, yapilan);
  }
  // 7-9) 08.10: Nöbetçi / Ekibe sor 1 yıl, cihaz 6 ay
  for (const [tablo, sutun, kesim, enAz, ad] of [
    ['nobetci_soru', 'tarih', kesimTarihi(simdi, 1), 364, 'nobetci_soru sil (1 yıl)'],
    ['ekibe_soru', 'tarih', kesimTarihi(simdi, 1), 364, 'ekibe_soru sil (1 yıl)'],
    ['uye_cihazlar', 'son_gorulme', kesimAy(simdi, 6), 180, 'uye_cihazlar sil (son görülme 6 ay)'],
    ['siparisler', 'olusturma', kesimTakvim10(simdi), 3650, 'siparisler sil (10 yıl, takvim yılı)'],
    ['kart_odemeleri', 'olusturma', kesimTakvim10(simdi), 3650, 'kart_odemeleri sil (10 yıl, takvim yılı)'],
  ]) {
    if (!kesimGuvenli(kesim, simdi, enAz)) throw new Error(`KAPI: ${tablo} kesimi bugüne çok yakın`);
    const f = `${sutun}=lt.${encodeURIComponent(kesim.toISOString())}`;
    const n = await say(tablo, f);
    if (n > TAVAN) throw new Error(`KAPI: ${tablo} ${n} > ${TAVAN}`);
    not(ad, n, yaz && n ? await sil(tablo, f) : 0);
  }
  // 5) rate_log: 1 günden eski IP satırları
  {
    const f = `ts=lt.${k1g}`;
    const n = await say('rate_log', f);
    not('rate_log sil (1 gün)', n, yaz && n ? await sil('rate_log', f) : 0);
  }
  return { simdi: simdi.toISOString(), kesim2yil: kesim2.toISOString(), kip: yaz ? 'YAZ' : 'KURU', rapor };
}

function sinav() {
  let hata = 0; const t = (ad, kosul) => { if (!kosul) { hata++; console.log('  DÜŞTÜ: ' + ad); } else console.log('  geçti: ' + ad); };
  const s = new Date('2026-09-14T10:00:00Z');
  t('kesim tam 2 takvim yılı', kesimTarihi(s, 2).toISOString() === '2024-09-14T10:00:00.000Z');
  t('29 Şubat kesimi geçerli tarih', !isNaN(kesimTarihi(new Date('2028-02-29T00:00:00Z'), 2).getTime()));
  t('2 yıl kesimi kapıdan geçer', kesimGuvenli(kesimTarihi(s, 2), s));
  t('1 yıl kesimi kapıda durur', !kesimGuvenli(kesimTarihi(s, 1), s));
  t('karne izni evet = kanıt', rizaKaniti({ 'KVKK onayı': 'evet', 'Kampanya/hatırlatma izni': 'evet' }));
  t('karne izni hayır = kanıt değil', !rizaKaniti({ 'KVKK onayı': 'evet', 'Kampanya/hatırlatma izni': 'hayır' }));
  t('KVKK onayı tek başına kanıt değil', !rizaKaniti({ 'KVKK onayı': 'evet' }));
  t('pazarlama_rizasi true = kanıt', rizaKaniti({ pazarlama_rizasi: true }));
  t('boş alanlar', !rizaKaniti(null) && !rizaKaniti({}));
  t('mesaj içinde "izin" kelimesi değer değilse kanıt değil', !rizaKaniti({ message: 'izin evet' }));
  // 08.10 yeni kurallar
  t('sipariş konusu tanınır (büyük harf, TT no, tutar)', siparisKaydi('YENİ SİPARİŞ TT-20261008-VJY4 — 1.138 TL'));
  t('sipariş konusu tanınır (ASCII yazım)', siparisKaydi('YENI SIPARIS TT-20261008-VJY4'));
  t('sipariş konusu tanınır (küçük harf)', siparisKaydi('Yeni sipariş TT-1'));
  t('karne konusu sipariş değil', !siparisKaydi('Seviye testi karnesi'));
  t('danışmanlık talebi sipariş değil', !siparisKaydi('DANIŞMANLIK TALEBİ (/hizmet.html)'));
  t('"sipariş" geçen ama sipariş olmayan konu', !siparisKaydi('Sipariş hakkında soru'));
  t('boş konu', !siparisKaydi(null) && !siparisKaydi(''));
  t('6 ay kesimi', kesimAy(s, 6).toISOString() === '2026-03-14T10:00:00.000Z');
  t('10 yıl takvim kesimi', kesimTakvim10(s).toISOString() === '2016-01-01T00:00:00.000Z');
  t('1 yıl kesimi 364 gün kapısından geçer', kesimGuvenli(kesimTarihi(s, 1), s, 364));
  t('6 ay kesimi 180 gün kapısından geçer', kesimGuvenli(kesimAy(s, 6), s, 180));
  t('3 ay kesimi 180 gün kapısında durur', !kesimGuvenli(kesimAy(s, 3), s, 180));
  t('10 yıl takvim kesimi 3650 gün kapısından geçer', kesimGuvenli(kesimTakvim10(s), s, 3650));
  t('3 yıl kesimi 1094 gün kapısından geçer', kesimGuvenli(kesimTarihi(s, 3), s, 1094));
  console.log(hata ? `ÖZ-SINAV DÜŞTÜ (${hata})` : 'ÖZ-SINAV GEÇTİ');
  return hata ? 1 : 0;
}

if (require.main === module) {
  if (process.argv.includes('--sinav')) process.exit(sinav());
  const yaz = process.argv.includes('--yaz');
  kos(yaz).then(sonuc => {
    console.log(`SAKLAMA ROBOTU · ${sonuc.kip} · kesim(2 yıl) ${sonuc.kesim2yil}`);
    for (const r of sonuc.rapor) console.log(`  ${r.kural}: aday ${r.aday}, yapılan ${r.yapilan}${r.ek ? ' · ' + r.ek : ''}`);
    if (process.env.GITHUB_STEP_SUMMARY) {
      const md = [`### Saklama robotu · ${sonuc.kip}`, `kesim (2 yıl): ${sonuc.kesim2yil}`, '', '| kural | aday | yapılan | not |', '|---|---:|---:|---|']
        .concat(sonuc.rapor.map(r => `| ${r.kural} | ${r.aday} | ${r.yapilan} | ${r.ek} |`)).join('\n');
      require('fs').appendFileSync(process.env.GITHUB_STEP_SUMMARY, md + '\n');
    }
  }).catch(e => { console.error('SAKLAMA ROBOTU DÜŞTÜ: ' + e.message); process.exit(1); });
}

module.exports = { kesimTarihi, rizaKaniti, kesimGuvenli, siparisKaydi, kesimAy, kesimTakvim10 };
