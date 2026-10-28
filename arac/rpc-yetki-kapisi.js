#!/usr/bin/env node
/* ============================================================================
 *  RPC YETKİ KAPISI (28.10.2026, Cem "1.2.3" madde 2)
 *
 *  NEDEN: Supabase public şemada her YENİ fonksiyona anon + authenticated'a açık grant veriyor; göçlerdeki
 *  "revoke ... from public" bunu kaldırmıyor. Üç kez yaşandı: cizim_ses_erisim (22.10, göç öz-sınavı yakaladı),
 *  s20_deneme_yukle (28.10, anon çalıştırdı), kasa_cekim_izin2 (10.10'dan 28.10'a dek anon/üyeye açık kaldı).
 *  Kapı: public şemadaki her SECURITY DEFINER fonksiyonun anon/authenticated çalıştırma yetkisi, depodaki izin
 *  listesiyle (radar-app/acik-rpc.txt) karşılaştırılır. Listede olmayan açık yetki = KIRMIZI.
 *
 *    node arac/rpc-yetki-kapisi.js --tsv sd-yetki.tsv [--liste radar-app/acik-rpc.txt]
 *         TSV (psql -qtA -F tab): ad <TAB> argümanlar <TAB> anon t/f <TAB> uye t/f   (yalnız SD, tetikleyici hariç)
 *    node arac/rpc-yetki-kapisi.js --sinav [--mutasyon]
 *
 *  İzin listesi satırı:  <ad>  A|U  # gerekçe     A = anon + üye çalıştırabilir · U = yalnız üye (authenticated)
 *
 *  KURALLAR: K1 anon açık ama listede A değil · K2 üye açık ama listede yok · K3 bozuk liste satırı ·
 *            KÖR: TSV boş/çok kısa (sorgu düştüyse "temiz" denmez). Listede olup kapalı/olmayan = NOT (durdurmaz).
 *  🚫 GÖRMEZ: SECURITY INVOKER fonksiyonlar (RLS'e bağlı; kapı bakmaz) · public dışı şemalar · fonksiyonun içinde
 *     oturum/yetki denetimi yapıp yapmadığı (listedeki A/U'nun DOĞRU olduğunu insan karar verir) · aynı adlı
 *     aşırı yüklemeler tek satırla izinlenir · göç uygulandıktan SONRA koşar: yetkiyi geri almaz, KIRMIZI + mail verir.
 * ==========================================================================*/
'use strict';
const fs = require('fs'), path = require('path');
const a = process.argv.slice(2), arg = (k, v) => { const i = a.indexOf(k); return i > -1 ? a[i + 1] : v; };
const MUT = process.env.RPC_MUTASYON || '';
const KOR_ESIK = 20;

function listeOku(metin) {
  const liste = {}, bozuk = [];
  metin.split(/\r?\n/).forEach((s, i) => {
    const t = s.replace(/#.*/, '').trim(); if (!t) return;
    const m = t.match(/^([a-z_][a-z0-9_]*)\s+(A|U)$/);
    if (!m) { bozuk.push((i + 1) + ': ' + s.trim()); return; }
    if (liste[m[1]] && MUT !== 'cift') bozuk.push((i + 1) + ': cift satir ' + m[1]);
    liste[m[1]] = m[2];
  });
  return { liste, bozuk };
}

function denetle(tsvMetin, listeMetin) {
  const satir = tsvMetin.split(/\r?\n/).map(s => s.trim()).filter(Boolean).map(s => s.split('\t'));
  const { liste, bozuk } = listeOku(listeMetin);
  const ihlal = [], not = [];
  if (MUT !== 'bicim') bozuk.forEach(b => ihlal.push('K3 BOZUK LISTE SATIRI ' + b));
  if (satir.length < KOR_ESIK && MUT !== 'kor') ihlal.push('KOR: veritabanindan ' + satir.length + ' satir geldi (<' + KOR_ESIK + ') - sorgu dustu mu? temiz SAYILMAZ');
  const gorulen = new Set();
  for (const [ad, arg2, anon, uye] of satir) {
    gorulen.add(ad);
    const izin = liste[ad];
    if (anon === 't' && izin !== 'A' && MUT !== 'anon') ihlal.push(`K1 ANON ACIK: ${ad}(${arg2}) - listede ${izin || 'yok'}; ic fonksiyonsa: revoke execute ... from public, anon, authenticated`);
    else if (uye === 't' && !izin && MUT !== 'uye') ihlal.push(`K2 UYE ACIK: ${ad}(${arg2}) - listede yok; ic fonksiyonsa revoke, sayfa cagiriyorsa listeye "${ad} U"`);
    else if (izin === 'A' && anon !== 't') not.push(`listede A ama anon kapali: ${ad}`);
    else if (izin === 'U' && uye !== 't') not.push(`listede U ama uye kapali: ${ad}`);
  }
  for (const ad of Object.keys(liste)) if (!gorulen.has(ad)) not.push(`listede var, veritabaninda acik SD fonksiyon olarak yok: ${ad}`);
  return { ihlal, not, sayi: satir.length, liste: Object.keys(liste).length };
}

if (a.includes('--sinav')) {
  const dolgu = Array.from({ length: KOR_ESIK }, (_, i) => `dolgu_${i}\t\tt\tt`).join('\n');
  const dolguListe = Array.from({ length: KOR_ESIK }, (_, i) => `dolgu_${i} A`).join('\n');
  const V = [
    // [ad, tsv ek, liste ek, beklenen ihlal deseni | null]
    ['temiz: listede A, anon acik', 'sayfa_rpc\tp text\tt\tt', 'sayfa_rpc A  # sayfa', null],
    ['temiz: listede U, yalniz uye', 'uye_rpc\t\tf\tt', 'uye_rpc U', null],
    ['temiz: kapali ic fonksiyon listede yok', '_ic\tp int\tf\tf', '', null],
    ['K1: yeni ic fonksiyon anon acik (s20_deneme_yukle olayi)', 's20_deneme_yukle\tp jsonb\tt\tt', '', /^K1 .*s20_deneme_yukle/],
    ['K1: listede U ama anon acik', 'uye_rpc\t\tt\tt', 'uye_rpc U', /^K1 .*uye_rpc/],
    ['K2: anon kapali ama uye acik, listede yok (kasa_cekim_izin2 uye ayagi)', 'kasa_cekim_izin2\tp text\tf\tt', '', /^K2 .*kasa_cekim_izin2/],
    ['K3: bozuk satir (rol harfi yanlis)', '', 'sayfa_rpc X', /^K3 /],
    ['K3: cift satir', 'sayfa_rpc\t\tt\tt', 'sayfa_rpc A\nsayfa_rpc A', /^K3 .*cift/],
    ['KOR: bos tsv', null, '', /^KOR/],
    ['NOT: listede A ama kapali durdurmaz', 'x_rpc\t\tf\tf', 'x_rpc A', null],
  ];
  let gec = 0; const H = [];
  for (const [ad, tsvEk, listeEk, bek] of V) {
    const tsv = tsvEk === null ? '' : dolgu + (tsvEk ? '\n' + tsvEk : '');
    const r = denetle(tsv, dolguListe + '\n' + listeEk);
    const ok = bek ? r.ihlal.some(x => bek.test(x)) : r.ihlal.length === 0;
    if (ok) gec++; else H.push('KALDI ' + ad + ' -> ' + JSON.stringify(r.ihlal));
  }
  const mut = MUT ? ' (MUTASYON: ' + MUT + ')' : '';
  H.forEach(h => console.log(h));
  console.log(`OZ-SINAV${mut}: ${gec}/${V.length}`);
  let kod = gec === V.length ? 0 : 1;
  if (a.includes('--mutasyon') && !MUT && kod === 0) {
    const { spawnSync } = require('child_process'); const M = ['anon', 'uye', 'bicim', 'cift', 'kor']; let kac = 0;
    for (const m of M) {
      const r = spawnSync(process.execPath, [__filename, '--sinav'], { env: Object.assign({}, process.env, { RPC_MUTASYON: m }), encoding: 'utf8' });
      const kirmizi = r.status !== 0; if (!kirmizi) kac++;
      console.log('  mutasyon ' + m.padEnd(6) + (kirmizi ? 'KIRMIZI ✓' : 'YEŞİL ✗ (sınav bu bozmayı görmüyor)'));
    }
    if (kac) { console.log('MUTASYON: ' + kac + '/' + M.length + ' bozma yakalanmadı'); kod = 1; } else console.log('MUTASYON: ' + M.length + '/' + M.length + ' bozma KIRMIZI');
  }
  process.exit(kod);
}

if (a.includes('--ozet')) {
  // canli-sema.yml: tüm fonksiyon TSV'si (ad, arg, SD/inv, anon, üye, dönüş) → yetki.tsv (+depoda) + OZET.md
  // tanım aranan yerler: göçler (radar-app/sql) + eski radar SQL'leri (veri/sql-*.sql; 28.10: marka_* orada, özet "yok" sanmıştı)
  const kok = path.join(__dirname, '..');
  const sqlMetin = [path.join(kok, 'radar-app', 'sql'), path.join(kok, 'veri')]
    .flatMap(k => fs.existsSync(k) ? fs.readdirSync(k).filter(f => f.endsWith('.sql')).map(f => path.join(k, f)) : [])
    .map(f => fs.readFileSync(f, 'utf8')).join('\n').toLowerCase();
  const satir = fs.readFileSync(arg('--ozet'), 'utf8').split(/\r?\n/).filter(Boolean).map(s => s.split('\t'));
  const depoda = ad => new RegExp('function\\s+(public\\.)?"?' + ad + '"?\\s*\\(').test(sqlMetin);
  const out = satir.map(([ad, ar, sd, an, uy, don]) => [ad, ar, sd, an, uy, don, depoda(ad) ? 'depoda' : 'DEPODA-YOK']);
  const dizin = arg('--dizin');
  fs.writeFileSync(path.join(dizin, 'yetki.tsv'), 'ad\targumanlar\ttur\tanon\tuye\tdonus\ttanim\n' + out.map(r => r.join('\t')).join('\n') + '\n');
  const yok = out.filter(r => r[6] === 'DEPODA-YOK');
  const say = f => out.filter(f).length;
  fs.writeFileSync(path.join(dizin, 'OZET.md'), [
    '# Canlı veritabanı fonksiyonları — özet', '',
    '> Robot yazar (`.github/workflows/canli-sema.yml`); elle düzenlenmez. Tanımlar `fonksiyonlar.sql`, yetkiler `yetki.tsv`.',
    '> Güvenlik kapısı: `arac/rpc-yetki-kapisi.js` + izin listesi `radar-app/acik-rpc.txt`.', '',
    `- public fonksiyon: **${out.length}** · SECURITY DEFINER: ${say(r => r[2] === 'SD')} · anon çalıştırabilir: ${say(r => r[3] === 't')} · üye çalıştırabilir: ${say(r => r[4] === 't')}`,
    `- depoda tanımı OLMAYAN (panelden kurulmuş / göçü kayıp): **${yok.length}**`, '',
    '| fonksiyon | tür | anon | üye |', '|---|---|---|---|',
    ...yok.map(r => `| \`${r[0]}(${r[1]})\` | ${r[2]} | ${r[3] === 't' ? 'AÇIK' : '-'} | ${r[4] === 't' ? 'AÇIK' : '-'} |`), ''
  ].join('\n'));
  console.log(`OZET: ${out.length} fonksiyon · depoda yok ${yok.length}`);
  process.exit(0);
}

const tsv = fs.readFileSync(arg('--tsv'), 'utf8');
const listeYol = arg('--liste', path.join(__dirname, '..', 'radar-app', 'acik-rpc.txt'));
const r = denetle(tsv, fs.readFileSync(listeYol, 'utf8'));
r.not.forEach(n => console.log('NOT ' + n));
r.ihlal.forEach(n => console.log('IHLAL ' + n));
console.log(`RPC YETKI KAPISI: ${r.ihlal.length ? 'KIRMIZI' : 'YESIL'} · SD fonksiyon ${r.sayi} · izin listesi ${r.liste} · ihlal ${r.ihlal.length} · not ${r.not.length}`);
process.exit(r.ihlal.length ? 1 : 0);
