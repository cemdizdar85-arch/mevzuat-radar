// SGS kalıp ayırıcısı = ortak kalip-olcum/kalip-ayirici.js (bitirme aracı, DEĞİŞTİRİLMEZ) + SGS düzeltme katmanı.
// Neden: SGS elle etiket 139 soru (okuma/sgs-kalip-elle.json, 31.10) → ortak ayırıcı %81 (113/139); hataların çoğu hesap sorusunun G (kaç gün/yıl) ya da M sanılması,
// olumsuz kalıbın "değildir" dışı fiillerle (kullanılmaz, yararlanamaz, sayılmamıştır) kaçması. node ayir-sgs.js → elle etikete uyum + kalan karışmalar.
const { ayir: ortak } = require('C:/TETIKTE-CALISMA/kalip-olcum/kalip-ayirici.js');
const tr = s => String(s || '').toLocaleLowerCase('tr');
function ayir(kok, siklar) {
  const h = ortak(kok, siklar), k = tr(kok).replace(/\s+/g, ' ').trim(), son = k.slice(Math.max(0, k.lastIndexOf('. ', k.length - 30) + 1));
  const sayiSik = siklar.length >= 4 && siklar.filter(s => /^[\s\-−%]*[\d.,/]+\s*(₺|tl|%)?[\s\d.,₺%/-]*$/i.test(String(s).trim())).length >= 4;
  const kokSayi = (String(kok).replace(/\d+ sayılı/g, '').replace(/\b(19|20)\d\d\b/g, '').match(/\d[\d.,]*/g) || []).length;
  const sk = tr(siklar.join(' | ')), mat = /[\u{1D400}-\u{1D7FF}√π∫]|lim\b|f\(|=\s*0/u.test(kok + sk);
  // 0) süre/tarih bilgisi: "kaç gün/saat/ay/yıl", "en geç hangi tarih" → G (olumsuz fiil taşısa da)
  if (/kaç (gün|saat|ay|yıl|hafta)|en geç hangi tarih|hangi tarihe? kadar/.test(k)) return 'G';
  // 1) matematik / sayısal sonuç: formüllü ya da sayısal şıklı, kökte veri → HESAP (süre şıkları "gün/ay/yıl" taşır)
  if ((h === 'G' || h === 'M' || h === 'L') && (mat || (sayiSik && kokSayi >= 2 && !/(gün|ay|yıl|saat)\b/.test(sk)))) return 'F';
  if (h === 'M' && /(azalırdı|artardı|değişim)/.test(sk + k) && /₺|\d/.test(sk)) return 'F';
  // 2) muhasebe: hesap adı soran ve kayıt→işlem
  if (h === 'M' && /(hesap|hesabı) aşağıdakilerden hangisidir|hangi hesaba|hesaplardan hangisine/.test(k)) return 'J';
  if (h === 'M' && /yukarıdaki kayıt .{0,40}hangisine aittir/.test(k)) return 'K';
  // 3) "değildir" dışı olumsuz fiil: kök "hangisi…" ve olumsuz geniş zaman/yeterlik ile bitiyor
  if (h === 'M' && /hangisi/.test(k) && /\b\S+(maz|mez|amaz|emez|mamıştır|memiştir|vermez|yoktur)\s*\??\s*$/.test(k)) return 'C';
  // 4) olumlu üyelik: "hangisi bir … -dir/-dır?"
  if (h === 'M' && /hangisi bir .{0,60}(dir|dır|tir|tır|dur|dür|tur|tür)\s*\??\s*$/.test(k)) return 'U';
  return h;
}
module.exports = { ayir };
if (require.main === module) {
  const fs = require('fs'), E = JSON.parse(fs.readFileSync('C:/TETIKTE-CALISMA/sgs-s20-arac/okuma/sgs-kalip-elle.json', 'utf8')), K = JSON.parse(fs.readFileSync('C:/TETIKTE-CALISMA/sgs-s20-arac/cikmis-sgs-onbellek.json', 'utf8')), M = {};
  for (const d of K) { const p = String(d.m).split(/SORU (\d+):/); for (let i = 1; i < p.length; i += 2) M[d.d + '#' + (+p[i])] = p[i + 1].replace(/\s+/g, ' '); }
  let a = 0, b = 0, n = 0; const kar = {}, ornek = [];
  for (const e of E) { const t = M[e.donem + '#' + e.soru]; if (!t) continue; const ai = t.search(/\sA\)\s/), kok = ai >= 0 ? t.slice(0, ai) : t, s = ai >= 0 ? [...t.slice(ai).matchAll(/([A-E])\)\s*(.*?)(?=\s[A-E]\)\s|$)/g)].map(x => x[2]) : [];
    n++; if (ortak(kok, s) === e.kalip) a++; const h = ayir(kok, s); if (h === e.kalip) b++; else { const k = e.kalip + '>' + h; kar[k] = (kar[k] || 0) + 1; if (process.argv.includes('--dok')) ornek.push(`${e.donem} S${e.soru} ${k} | ${kok.slice(-110)} | ${s.join(' / ').slice(0, 80)}`); } }
  console.log(`ortak ${a}/${n} (%${Math.round(100 * a / n)}) · SGS katmanlı ${b}/${n} (%${Math.round(100 * b / n)})`, JSON.stringify(Object.entries(kar).sort((x, y) => y[1] - x[1])));
  ornek.forEach(o => console.log('  ' + o));
}
