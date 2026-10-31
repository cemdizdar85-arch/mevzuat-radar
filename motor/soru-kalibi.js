#!/usr/bin/env node
// ============================================================================
//  SORU CÜMLESİ KALIBI AYIRICISI — tek soru (30.10.2026, bedel 0, model yok)
//
//  NEDEN (Cem 30.10 "1.2.3 üçünü de yap"): sitedeki bankanın soru cümlesi gerçek sınavdan başka kalıpta. 2026/1 + 2026/2
//  Yeterlilik test kitapçıklarının 320 sorusu ELLE 17 kalıba ayrıldı (dağılım veri/sinav/smmm-soru-kalibi.json); bu ayırıcı
//  elle etikete karşı 301/320 (%94) tuttu (C:\TETIKTE-CALISMA\kalip-olcum\kalip-ayirici.js --sinav; kitapçık metni depoda YOK,
//  depo herkese açık). Ölçülen farklar (gerçek % / site %): FM doğrudur 43/5, hesap 5/74 · Hukuk değildir 28/5, hesap 0/16 ·
//  Meslek doğrudur 0/30 · SPK doğrudur 0/36. motor/smmm-ders-sira.js ders sayfası sırasında kullanır.
//  KALIPLAR: A doğrudur · B yanlıştır · C değildir/sayılmaz · U sayılır/görevidir · D öncüllü · E boşluk · G hüküm sayısı/zamanı ·
//    F hesap · L sırasıyla · I defter kaydı · J hangi hesap · K kayıt→işlem · M tanım↔terim (kalan) · N yetkili merci ·
//    O eylem→ceza/suç · P durum→davranış · S grafik yorumu.
//  vakaMi: kökte şirket adı ("(X) A.Ş.", "Ltd. Şti.", "(B) şirketi", "… Holding"). 2026 Denetim kitapçıklarında 0 eşleşme
//    (yalnız Vergi'de var); sitedeki Denetim'de 64/401 (30.10 ölçümü).
//  🚫 GÖRMEZ: sorunun anlamı · ayırıcının %6 yanılgısı (en çok M↔A, C↔U) · kökte adı geçmeyen vaka (kişi harfli "Denetçi (H)"
//    vaka sayılmaz) · şıkta geçen şirket adı.
//
//  node motor/soru-kalibi.js --sinav     öz-sınav (uydurma kökler; gerçek soru metni yok)
// ============================================================================
'use strict';
const tr = s => (s || '').toLocaleLowerCase('tr');
// C:\TETIKTE-CALISMA\kalip-olcum\kalip-ayirici.js ayir() — 301/320 ölçülen sürümün AYNEN kopyası (değiştirirsen yeniden ölç)
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
// kökte şirket adlı vaka (30.10 ölçümü: Türk Ticaret Kanunu, "(BDS)", "Denetçi (H)" YAKALANMAZ)
const VAKA = /A\.\s?Ş\.|\bLtd\.?\s*Şti|\([A-ZÇĞİÖŞÜ]{1,3}\)\s*([şŞ]irket|[gG]rub|[hH]olding|[iİ]şletme)|[A-ZÇĞİÖŞÜ][A-Za-zçğıöşüÇĞİÖŞÜ]*\s+Holding\b/;
const vakaMi = kok => VAKA.test(String(kok || ''));
// tek soru (kalip-parti biçimi: soru + siklar {A..E}) → kalıp harfi
const soruKalibi = q => ayir(String((q && q.soru) || ''), Object.values((q && q.siklar) || {}).map(String));

function sinav() {
  let hata = 0; const t = (ad, k) => { console.log((k ? '  geçti: ' : '  DÜŞTÜ: ') + ad); if (!k) hata++; };
  const s4 = ['Birinci yargı', 'İkinci yargı', 'Üçüncü yargı', 'Dördüncü yargı', 'Beşinci yargı'];
  const V = [   // uydurma kökler (gerçek soru metni değil): [beklenen, kök, şıklar]
    ['A', 'Kanuna göre ilgili kurum hakkında aşağıdakilerden hangisi doğrudur?', s4],
    ['B', 'Kanuna göre ilgili kurum hakkında aşağıdakilerden hangisi yanlıştır?', s4],
    ['C', 'Kanuna göre aşağıdakilerden hangisi ilgili kurumun görevlerinden biri değildir?', s4],
    ['U', 'Kanuna göre aşağıdakilerden hangisi ilgili istisna kapsamındadır?', s4],
    ['D', 'I. Birinci yargı II. İkinci yargı III. Üçüncü yargı Yukarıdakilerden hangileri doğrudur?', ['Yalnız I', 'I ve II', 'I ve III', 'II ve III', 'I, II ve III']],
    ['E', 'Kanuna göre itiraz süresi ---- gündür. Boş bırakılan yere aşağıdakilerden hangisi gelmelidir?', s4],
    ['F', 'İşletmenin 2025 yılı satışları 1.500.000 ₺, maliyeti 900.000 ₺ olduğuna göre brüt kâr oranı yüzde kaçtır?', ['40', '45', '50', '55', '60']],
    ['L', 'Aşağıdaki kavramlar sırasıyla hangi seçenekte doğru verilmiştir?', s4],
    ['I', 'Bu işlem için yapılacak kayıt aşağıdakilerden hangisidir?', s4],
    ['J', 'Peşin ödenen kira bedeli hangi hesapta izlenir?', s4],
    ['N', 'Kanuna göre kaydın silinmesi kararı hangi merciye aittir ve hangisine verir?', s4],
    ['M', 'Belirli bir süre içinde tamamlanan işlerin bütününe verilen ad aşağıdakilerden hangisidir?', s4],
  ];
  V.forEach(([b, k, s]) => t(`kalıp ${b}`, ayir(k, s) === b));
  t('soruKalibi: kalip-parti biçimi (siklar nesnesi)', soruKalibi({ soru: V[1][1], siklar: { A: 'a', B: 'b', C: 'c', D: 'd', E: 'e' } }) === 'B');
  t('vaka: (X) A.Ş. / Ltd. Şti. / (B) şirketi / Holding yakalanır', ['(T) A.Ş.\'nin denetiminde', 'Deneme Ltd. Şti. denetçisi', 'işletmenin (B) şirketindeki payı', 'Örnek Holding denetiminde'].every(vakaMi));
  t('vaka değil: Türk Ticaret Kanunu, (BDS) 220, Denetçi (H), anonim şirketlerde', ['Türk Ticaret Kanunu (TTK) m.400', 'Bağımsız Denetim Standardı (BDS) 220', 'Denetçi (H), müşterinin', 'anonim şirketlerde denetçi seçimi'].every(k => !vakaMi(k)));
  console.log(hata ? `ÖZ-SINAV DÜŞTÜ (${hata})` : 'ÖZ-SINAV GEÇTİ');
  return hata;
}
if (require.main === module) {
  if (process.argv.includes('--sinav')) process.exitCode = sinav() ? 1 : 0;
  else { console.log('kullanım: --sinav'); process.exitCode = 1; }
}
module.exports = { ayir, vakaMi, soruKalibi };
