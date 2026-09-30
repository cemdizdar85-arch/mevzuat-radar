#!/usr/bin/env node
// ============================================================================
//  KESİK PARAGRAF TARAMASI (30.09.2026, Cem "1.2.3 üçünü de yap")
//  Ambarda paragraf biçimli kayıtlarda ("<STD> <no> p.<par> - <başlık>") yutma kusurlarını arar. Yalnız OKUR.
//    K1 SON    : metin cümle sonu işaretiyle bitmiyor (BDS 250 p.5 "…elde etmekle sorumludur" — noktasız, devamı başka kayıtta)
//    K2 BENT   : (a),(b),(c)… bentlerinde atlama var ya da yalnız (a) var (BDS 330 p.17, BDS 580 p.11 — (b) düşmüş)
//    K3 ÇİFT   : aynı standart+paragraf numarası İKİ FARKLI başlıkla (BDS 250 "p.1 - Kapsam" + "p.1 - Denetçinin Sorumluluğu")
//    K4 GÖMÜLÜ : p.N gövdesinde "N+1." ile başlayan paragraf var ve p.N+1 ayrı kayıt değil (BDS 500 p.11, p.10'un içinde)
//    K5 ATLAMA : ana metin numaraları arasında boşluk (p.10 ve p.12 var, p.11 yok ve gömülü değil)
//  ÖLÇÜLDÜ (30.09): SGS onarımında elle bulunan 4 BDS kusurunun 4'ü de (250 p.5, 330 p.17, 580 p.11, 500 p.11) yakalanıyor — sonuç dosyasında.
//  Mevcut `veri/kesik-metin-adaylari.json` bu dördünü taşımıyordu (grep, 30.09).
//  🚫 GÖRMEZ: THP gibi hesap listesinde BÜTÜN grubun yokluğu (THP 170–179; resmî tam liste ambarda olmadığı için kıyas yok) ·
//     noktayla biten ama ortasından kopmuş metin · bent harfi olmayan madde içi eksik fıkra · paragraf biçimi dışındaki kayıtlar (kanun maddeleri).
//  Kullanım: node arac/kesik-paragraf-tarama.js --sinav | --tara [cikti.json]   (tara: SUPABASE_SERVICE_KEY; varsayılan çıktı veri/sinav/kesik-paragraf-adaylari.json)
// ============================================================================
'use strict';
const fs = require('fs'), path = require('path');
const KOK = path.resolve(__dirname, '..');
const CIKTI = path.join(KOK, 'veri', 'sinav', 'kesik-paragraf-adaylari.json');
const ONEKLER = ['BDS ', 'TMS ', 'TFRS ', 'BOBİ ', 'KAYDS '];
const MUT = process.env.KP_MUTASYON || '';

// kayıt adı → {std, par, baslik, parca}
function ayristir(ad) {
  const m = String(ad).match(/^((?:BDS|TMS|TFRS|BOBİ|KAYDS)\s+\S+)\s+p\.(A?\d{1,3})[a-z]?\s*-\s*(.*?)(?:\s*\[(\d+)\/(\d+)\])?$/);
  if (!m) return null;
  return { std: m[1], par: m[2], baslik: m[3].trim(), parca: m[4] ? +m[4] : 1 };
}

function denetle(kayitlar) {
  // kayitlar: [{kaynak_ad, metin}] → bulgular
  const S = {};   // std → par → {basliklar:Set, parcalar:[[no, metin]]}
  for (const x of kayitlar) {
    const a = ayristir(x.kaynak_ad); if (!a) continue;
    const p = ((S[a.std] = S[a.std] || {})[a.par] = S[a.std][a.par] || { basliklar: new Set(), parcalar: [] });
    p.basliklar.add(a.baslik); p.parcalar.push([a.parca, String(x.metin || '')]);
  }
  const out = [];
  const bul = (tur, std, par, not) => out.push({ tur, kayit: std + ' p.' + par, not });
  for (const [std, P] of Object.entries(S)) {
    const anaNo = Object.keys(P).filter(p => /^\d+$/.test(p)).map(Number).sort((a, b) => a - b);
    const gomulu = new Set();
    for (const [par, p] of Object.entries(P)) {
      const metin = p.parcalar.sort((a, b) => a[0] - b[0]).map(y => y[1]).join(' ').trim();
      if (!metin) continue;
      // K3 çift başlık
      if (p.basliklar.size > 1 && MUT !== 'cift') bul('K3-CIFT', std, par, [...p.basliklar].map(b => '"' + b.slice(0, 40) + '"').join(' + '));
      // K1 son: cümle sonu işareti yok (tırnak/parantez kapanışı sonrası da olabilir)
      // 30.09 ilk tarama 1.003 aday verdi; gürültü ayıklandı: sonda "(Bkz.: … paragrafı)" atfı · noktadan sonra dipnot rakamı (".15") ·
      //   p.0 künye/içindekiler kaydı · "[…]" / "*" dipnot işareti.
      const temizSon = metin.replace(/\s*\((Bkz|Bakınız)[^()]*\)\s*$/i, '.').replace(/([.:;!?…])\s*\d{1,3}\s*$/, '$1').replace(/\s*(\[[^\]]*\]|\*+)\s*$/, '');
      if (MUT !== 'son' && par !== '0' && !/[.:;!?…](\s*[)"”’»\]])*\s*$/.test(temizSon)) bul('K1-SON', std, par, 'metin "…' + metin.slice(-40) + '" ile bitiyor');
      // K2 bent atlaması: satır/cümle içi "(a)" biçimli harf bentleri
      const harfler = [...new Set((metin.match(/(^|[\s:;,])\(([a-hçğ])\)/g) || []).map(s => s.replace(/.*\(/, '').replace(')', '')))];
      const sira = 'abcçdefgğh'.replace(/[çğ]/g, '');   // BDS bentleri Latin a-h
      const idx = harfler.map(h => sira.indexOf(h)).filter(i => i >= 0).sort((a, b) => a - b);
      if (idx.length && MUT !== 'bent') {
        const eksik = []; for (let i = 0; i <= idx[idx.length - 1]; i++) if (!idx.includes(i)) eksik.push(sira[i]);
        if (eksik.length) bul('K2-BENT', std, par, 'bent eksik: (' + eksik.join('),(') + ')');
        else if (idx.length === 1 && MUT !== 'bent-tek') bul('K2-BENT', std, par, 'yalnız (' + sira[idx[0]] + ') bendi var');
      }
      // K4 gömülü: gövdede "N+1." paragraf başı
      const tip = par[0] === 'A' ? 'A' : '', no = parseInt(par.replace('A', ''), 10);
      for (const d of [1, 2]) {
        const hedef = tip + (no + d);
        if (!P[hedef] && new RegExp('(^|\\s)' + hedef + '\\.\\s+[A-ZÇĞİÖŞÜ]').test(metin) && MUT !== 'gomulu') { gomulu.add(hedef); bul('K4-GOMULU', std, par, hedef + ' bu kaydın içinde'); }
      }
    }
    // K5 ana metin numara atlaması (gömülü olanlar hariç)
    if (MUT !== 'atlama') for (let i = 1; i < anaNo.length; i++) for (let n = anaNo[i - 1] + 1; n < anaNo[i]; n++) if (!gomulu.has(String(n))) bul('K5-ATLAMA', std, String(n), 'p.' + anaNo[i - 1] + ' ile p.' + anaNo[i] + ' arasında kayıt yok');
  }
  return out;
}

async function tara(cikti) {
  const K = process.env.SUPABASE_SERVICE_KEY; if (!K) { console.error('SUPABASE_SERVICE_KEY yok'); process.exit(2); }
  const hepsi = []; const onekSay = {};
  for (const on of ONEKLER) {
    let n = 0;
    for (let o = 0; ; o += 500) {
      const r = await fetch('https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar?select=kaynak_ad,metin&order=kaynak_ad.asc&kaynak_ad=like.' + encodeURIComponent(on + '%') + '&limit=500&offset=' + o,
        { headers: { apikey: K, Authorization: 'Bearer ' + K, 'User-Agent': 'mevzuat-radar-robot/1.0' } });
      const j = await r.json(); if (!Array.isArray(j)) { console.error('ambar okunamadı: ' + on); process.exit(2); }
      hepsi.push(...j); n += j.length; if (j.length < 500) break;
    }
    onekSay[on.trim()] = n;
  }
  const b = denetle(hepsi); const tur = {}; for (const x of b) tur[x.tur] = (tur[x.tur] || 0) + 1;
  const bicimli = hepsi.filter(x => ayristir(x.kaynak_ad)).length;
  const sonuc = { aciklama: 'Ambar paragraf kayıtlarında yutma kusuru adayları (arac/kesik-paragraf-tarama.js). ADAY — resmî metinle doğrulanmadan kusur sayılmaz.',
    olcum: new Date().toISOString().slice(0, 10), okunan: onekSay, paragraf_bicimli: bicimli, KOR: hepsi.length - bicimli, tur, bulgular: b };
  fs.writeFileSync(cikti || CIKTI, JSON.stringify(sonuc, null, 1));
  console.log('KESİK PARAGRAF: okunan ' + JSON.stringify(onekSay) + ' · paragraf biçimli ' + bicimli + ' · KÖR (biçim dışı) ' + (hepsi.length - bicimli) + ' · aday ' + b.length + ' ' + JSON.stringify(tur));
}

function sinav() {
  const K = [
    { kaynak_ad: 'BDS 250 p.1 - Kapsam', metin: 'Bu standart mevzuatı düzenler.' },
    { kaynak_ad: 'BDS 250 p.1 - Denetçinin Sorumluluğu', metin: 'Devam eden metin burada biter.' },
    { kaynak_ad: 'BDS 250 p.2 - Amaç', metin: 'Tam bir cümle.' },
    { kaynak_ad: 'BDS 250 p.3 - Tanım', metin: 'Denetçi (a) birinciyi, (c) üçüncüyü yapar.' },
    { kaynak_ad: 'BDS 250 p.4 - Tam bent', metin: 'Denetçi: (a) bir; (b) iki; (c) üç.' },
    { kaynak_ad: 'BDS 250 p.5 - Sorumluluk', metin: 'Denetçi makul güvence elde etmekle sorumludur' },
    { kaynak_ad: 'BDS 250 p.6 - Tırnak', metin: 'Buna "önemli yanlışlık" denir.”' },
    { kaynak_ad: 'BDS 500 p.10 - Seçim', metin: 'Seçim yapılır. Güvenilirlik 11. Bir kaynaktan elde edilen kanıt tutarsızsa…' },
    { kaynak_ad: 'BDS 500 p.12 - Sonra', metin: 'Sonraki paragraf.' },
    { kaynak_ad: 'BDS 700 p.1 - Kapsam [1/2]', metin: 'İlk parça ortada' },
    { kaynak_ad: 'BDS 700 p.1 - Kapsam [2/2]', metin: 've burada biter.' },
    { kaynak_ad: 'BDS 700 p.3 - Yalnız a', metin: 'Denetçi şunu yapar: (a) tek bent.' },
    { kaynak_ad: 'BDS 700 p.4 - Liste', metin: 'Madde (i) ve (ii) ile.' },
    { kaynak_ad: 'VUK m.227 - Belge', metin: 'Kanun maddesi noktasız' },
    { kaynak_ad: 'BDS 570 p.1 - Bkz', metin: 'Denetçi bunu dikkate alır (Bkz.: 22 nci paragraf)' },
    { kaynak_ad: 'BDS 570 p.2 - Dipnot', metin: 'Süre en fazla altmış gündür.15' },
    { kaynak_ad: 'BDS 570 p.0 - Künye', metin: 'İçindekiler ....... A58-A83' },
  ];
  const b = denetle(K); const var_ = (tur, kayit) => b.some(x => x.tur === tur && x.kayit === kayit);
  const V = [
    ['K3 çift başlık (250 p.1)', var_('K3-CIFT', 'BDS 250 p.1')],
    ['K2 bent atlaması (250 p.3: (b) yok)', var_('K2-BENT', 'BDS 250 p.3')],
    ['K2 tam bent temiz (250 p.4)', !var_('K2-BENT', 'BDS 250 p.4')],
    ['K1 noktasız son (250 p.5)', var_('K1-SON', 'BDS 250 p.5')],
    ['K1 tırnakla biten cümle temiz (250 p.6)', !var_('K1-SON', 'BDS 250 p.6')],
    ['K4 gömülü (500 p.11 p.10 içinde)', var_('K4-GOMULU', 'BDS 500 p.10')],
    ['K5 gömülü numara atlama sayılmaz (500 p.11)', !var_('K5-ATLAMA', 'BDS 500 p.11')],
    ['K5 atlama (700 p.2 yok)', var_('K5-ATLAMA', 'BDS 700 p.2')],
    ['parçalı kayıt birleşir, K1 yok (700 p.1)', !var_('K1-SON', 'BDS 700 p.1')],
    ['K2 yalnız (a) (700 p.3)', var_('K2-BENT', 'BDS 700 p.3')],
    ['roma bendi harf sayılmaz (700 p.4)', !var_('K2-BENT', 'BDS 700 p.4')],
    ['"(Bkz.: …)" ile biten paragraf temiz (570 p.1)', !var_('K1-SON', 'BDS 570 p.1')],
    ['noktadan sonra dipnot rakamı temiz (570 p.2)', !var_('K1-SON', 'BDS 570 p.2')],
    ['p.0 künye taranmaz (570 p.0)', !var_('K1-SON', 'BDS 570 p.0')],
    ['paragraf biçimi dışı kayıt taranmaz (VUK)', !b.some(x => /VUK/.test(x.kayit))],
  ];
  let ok = 0; for (const [ad, g] of V) { if (g) ok++; console.log((g ? '  ✓ ' : '  ✗ ') + ad); }
  console.log(ok === V.length ? `KESİK PARAGRAF ÖZ-SINAVI YEŞİL (${ok}/${V.length})` + (MUT ? ' · KP_MUTASYON=' + MUT : '') : `KESİK PARAGRAF ÖZ-SINAVI KIRMIZI (${ok}/${V.length})` + (MUT ? ' · KP_MUTASYON=' + MUT : ''));
  return ok === V.length;
}

if (require.main === module) {
  const [a, b] = process.argv.slice(2);
  if (a === '--sinav') {
    if (process.argv.includes('--mutasyon')) {
      const { spawnSync } = require('child_process'); let tutan = 0; const ler = ['cift', 'son', 'bent', 'bent-tek', 'gomulu', 'atlama'];
      for (const m of ler) { const r = spawnSync(process.execPath, [__filename, '--sinav'], { env: { ...process.env, KP_MUTASYON: m }, encoding: 'utf8' }); const k = r.status !== 0; if (k) tutan++; console.log('  mutasyon ' + m + (k ? ' KIRMIZI (doğru)' : ' YEŞİL (SINAV KÖR!)')); }
      console.log('MUTASYON: ' + tutan + '/' + ler.length + ' → KIRMIZI'); process.exit(tutan === ler.length ? 0 : 1);
    }
    process.exit(sinav() ? 0 : 1);
  } else if (a === '--tara') tara(b);
  else { console.log('--sinav [--mutasyon] | --tara [cikti.json]'); process.exit(2); }
}
