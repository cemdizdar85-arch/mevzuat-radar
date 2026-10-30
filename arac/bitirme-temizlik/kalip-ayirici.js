// 17 soru cümlesi kalıbı ayırıcısı. Önce 320 gerçek soruda elle etikete karşı sınanır, sonra site bankasına uygulanır.
// kullanım: node kalip-ayirici.js --sinav          (gerçek 320'de doğruluk + karışanlar)
//           node kalip-ayirici.js --banka <json>   (site bankası ders ders sayım)
const fs = require('fs'), path = require('path');
const tr = s => (s || '').toLocaleLowerCase('tr');
function ayir(kok, siklar) {
  const k = tr(kok).replace(/\s+/g, ' ').trim(), sik = siklar.join(' | '), ks = tr(sik);
  const son = k.slice(Math.max(0, k.lastIndexOf('. ', k.length - 30) + 1)); // soru cümlesi ağırlıklı son kısım
  const sayiSik = siklar.length >= 4 && siklar.filter(s => /^[\s\-−%]*[\d.,]+\s*(₺|tl|gün|ay|yıl|saat|%)?[\s/;,\d.₺%-]*$/i.test(s.trim())).length >= 4;
  const kokSayi = (kok.replace(/\d+ sayılı/g,'').replace(/\b(19|20)\d\d\b/g,'').match(/\d[\d.,]*/g) || []).filter(x => x.replace(/\D/g, '').length >= 3).length;
  if (/(^|\s)I\.\s/.test(kok) && /\sII\.\s/.test(kok) || /yalnız i\b|\bi ve ii\b|i, ii ve iii/.test(ks) || /yukarıdakilerden hangileri|yukarıdaki .{0,40}hangileri|hangisi\/hangileri|hangisini\/hangilerini|yukarıda sayılan .{0,60}hangilerinde/.test(k)) return 'D';
  if (/----|_{3,}|\(i\)\s*[-_.…]|boş bırakılan|boşlu[kğ]/.test(k)) return 'E';
  if (/hangi işlemin karşılığı/.test(k)) return 'K';
  if (/grafik/.test(k)) return 'S';
  if (/sırasıyla/.test(k)) return 'L';
  if (/(defter kayd[ıi]|muhasebe kayd[ıi]|yapılacak kayıt|dönem sonu kaydı|kayıt) aşağıdakilerden hangisidir|yapılan kayıt aşağıdakilerden/.test(k) || (siklar.filter(s => (s.match(/\b[1-7]\d\d\s+[A-ZÇĞİÖŞÜ]/g) || []).length >= 2).length >= 3 && !/doğru|yanlış/.test(son))) return 'I';
  if (/hesapta muhasebeleştir|hesapların hangisinde|borçlandırılacak hesap|alacaklandırılacak hesap|hesap grubu|izlendiği bir hesap|hangi hesap/.test(k)) return 'J';
  if (/yanlış(tır|tir| olarak| verilmiş)/.test(son) || /hangisi .{0,80}yanlıştır/.test(k)) return 'B';
  if (/(değildir|değil midir|biri değil|sayılmaz|sayılmamıştır|yer almaz|girmez|bakılmaz|kullanılmaz|bulunmaz|belirlenmez|aranmaz|imkanı yoktur|olamaz|gerekmez)\s*\??\s*$/.test(k) || /(değildir|sayılmaz|yer almaz|girmez|kullanılmaz)\?/.test(k)) return 'C';
  if (/ne yapmalıdır|hangi görüş|kararlardan hangisi|hangi karar/.test(k)) return 'P';
  if (/hangi ceza|cezası uygulanır|suçlarından hangisinin|suçun kapsamına/.test(k)) return 'O';
  if (/(kurumlardan|mercilerden|kurumlar|merci|kişilerden) hangisine|tarafından yapılır|görevidir\?|yetkili kurum|hangisine verir|hangisine bildirmek/.test(k)) return 'N';
  if (/doğrudur|doğru olarak|doğru bir şekilde|doğru bir ifade|doğru tanımlan|tam olarak ifade/.test(son) || /hangisi doğru/.test(k)) return 'A';
  if (/ne zaman/.test(k)) return 'G';
  if (/kaç ₺|(yılının|itibari|çeyrek|döneminde|dönemi sonunda) .{0,80}(kaç|oran|yüzde)/.test(son)) return 'F';
  if (/kaç|ne kadar|yüzde|oranı|tutarı|matrah|devir hızı|miktarları|derecesi|kârı aşağıdakilerden/.test(son) || (sayiSik && /hangisidir\??$/.test(k))) return (kokSayi >= 2 || /hesapla|oranı|yüzde|tutarı|matrah|maliyet|devir|dikey|trend|eğilim|kâr/.test(son)) ? 'F' : 'G';
  if (/(sayılır|girer|kapsamındadır|biridir|dönüştürülebilir|tabidir|yararlanılır)\??\s*$/.test(k)) return 'U';
  return 'M';
}
function gercekSorular() {
  const dir = path.join(__dirname, 'kitapcik'), out = [];
  for (const f of fs.readdirSync(dir).sort()) {
    const m = f.match(/smmm_(\d{4})_(\d)_(\d\d)\.txt/); if (!m) continue;
    const p = fs.readFileSync(path.join(dir, f), 'utf8').split(/SORU (\d+):/);
    for (let i = 1; i < p.length; i += 2) {
      const g = p[i + 1].replace(/TÜRMO.*$/s, '').replace(/\s+/g, ' ');
      const ai = g.search(/\sA\)\s/); const kok = ai >= 0 ? g.slice(0, ai) : g;
      const siklar = [...g.slice(ai).matchAll(/([A-E])\)\s*(.*?)(?=\s[A-E]\)\s|$)/g)].map(x => x[2]);
      out.push({ ders: m[3], donem: `${m[1]}/${m[2]}`, no: +p[i], kok, siklar });
    }
  }
  return out;
}
const arg = process.argv[2];
if (arg === '--sinav') {
  const elle = JSON.parse(fs.readFileSync(path.join(__dirname, '..', '..', 'veri', 'sinav', 'bitirme-kalip-elle-320.json'), 'utf8'));
  let ok = 0, n = 0; const kar = {};
  for (const s of gercekSorular()) {
    const e = (elle[`${s.ders}|${s.donem}`] || '')[s.no - 1]; if (!e) continue; n++;
    const a = ayir(s.kok, s.siklar); if (a === e) ok++; else { kar[`${e}->${a}`] = (kar[`${e}->${a}`] || 0) + 1; if (process.argv[3]) console.log(`${s.ders} ${s.donem} S${s.no} elle ${e} / ayırıcı ${a}: …${s.kok.slice(-140)}`); }
  }
  console.log(`DOĞRULUK: ${ok}/${n} = %${Math.round(100 * ok / n)}`); console.log('karışanlar:', kar);
} else if (arg === '--banka') {
  const b = JSON.parse(fs.readFileSync(process.argv[3], 'utf8')); const say = {};
  for (const s of b) { const k = ayir(s.soru, Object.values(s.siklar || {})); const d = (say[s.ders] ||= { n: 0 }); d.n++; d[k] = (d[k] || 0) + 1; }
  fs.writeFileSync(path.join(__dirname, 'site-kalip-sayim.json'), JSON.stringify(say, null, 1));
  const harf = 'ABCUDEGFLIJKMNOPS'.split('');
  console.table(Object.fromEntries(Object.entries(say).map(([d, v]) => [d, Object.fromEntries([['n', v.n], ...harf.map(h => [h, v[h] ? Math.round(100 * v[h] / v.n) : 0])])])));
}
module.exports = { ayir };
