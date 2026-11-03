// KGK soru cümlesi kalıbı ayırıcısı (03.11, Cem "Evet, kur"; B30/B31). Bitirme ayırıcısı (arac/bitirme-temizlik/kalip-ayirici.js)
// KGK elle etiketinde %76 tuttu (eşik %90): KGK olumsuzu cümle ORTASINDA ("hangisi … değildir?"), merci/izin, vaka→davranış ve
// "doğru olarak verilmiştir" tanım kalıpları farklı. Bitirme dosyasına DOKUNULMAZ; bu KGK'ya özgü ayrı ayırıcıdır.
// Harfler ve öncelik BRIF-KALIP.md ile aynı: D > E > K > S > L > I > J > B > C > P > O > N > A > G > F > U > M.
// node kgk-kalip-ayirici.js --sinav [--ornek]   → elle etiketle uyum (etiket-*.json ↔ ayirici-girdi*.json)
'use strict';
const fs = require('fs'), path = require('path');
const tr = s => String(s || '').toLocaleLowerCase('tr').replace(/\s+/g, ' ').trim();
// soru cümlesi: kökün son "?"ına kadar; o cümlenin başı = önceki nokta/soru işareti/öncül sonu
function soruCumlesi(kok) {
  let k = String(kok || ''); const q = k.lastIndexOf('?'); if (q >= 0) k = k.slice(0, q + 1);
  const bas = Math.max(k.lastIndexOf('. ', k.length - 3), k.lastIndexOf('? ', k.length - 3), k.lastIndexOf(') ', k.length - 3));
  return tr(bas > 0 && k.length - bas > 25 ? k.slice(bas + 1) : k.slice(-260));
}
const SAYI_SIK = s => /^\s*[-−(]?\s*%?\s*[\d.,]+\s*(₺|tl|gün|ay|yıl|saat|%|kat)?\s*$/i.test(String(s).trim());
// süre/oran/eşik şıkkı: "5 yıl", "%25", "binde 2", "1 yıl içinde…" (kural ezberi → G; hesap → F)
const OLCU_SIK = s => /^\s*(%\s*\d|\d[\d.,]*\s*(gün|ay|yıl|hafta|saat|iş günü|%|katı?)|binde|yüzde|onda|\d+\/\d+)/i.test(String(s).trim());
// olumsuz fiil cümle sonunda: "-maz/-mez", "-mamaktadır", "yoktur" ("olmaz" dahil)
const OLUMSUZ_SON = /(\S{2,}(maz|mez|mamaktadır|memektedir|mamıştır|memiştir|mamalıdır|memelidir)|yoktur|değildir)\s*\??$/;
function ayir(kok, siklar) {
  const K = tr(kok), c = soruCumlesi(kok), S = (siklar || []).map(x => tr(x)), sikMetin = S.join(' | ');
  const sayiSik = S.filter(SAYI_SIK).length >= 4, olcuSik = S.filter(OLCU_SIK).length >= 3;
  const kokSayi = (String(kok).replace(/\d+ sayılı/g, '').replace(/\b(19|20)\d\d\b/g, '').match(/\d[\d.,]*/g) || []).filter(x => x.replace(/\D/g, '').length >= 3).length;
  const kokSayiHepsi = (String(kok).replace(/\d+ sayılı/g, '').replace(/\b(19|20)\d\d\b/g, '').replace(/(tms|tfrs|bds|kys|gds|tsrs|ihs|madde|m\.)\s*\d+/gi, '').match(/\d[\d.,]*/g) || []).length;
  // D öncüllü
  if ((/(^|\s)(i|ı)[.)]\s/.test(K) && /\s(ii|ıı)[.)]\s/.test(K)) || /hangisi veya hangileri|hangileri/.test(c) || /yalnız (i|ı)\b|(i|ı) ve (ii|ıı)\b|(i|ı), (ii|ıı) ve (iii|ııı)/.test(sikMetin)) return 'D';
  // E boşluk
  if (/boş (bırakılan|kalan|olan)|boşluk/.test(K)) return 'E';
  // K kayıt → işlem
  if (/kayd[ıi] (aşağıdaki işlemlerden|hangi işlem)|hangi işlemin karşılığı|işlemlerden hangisine ilişkin/.test(c)) return 'K';
  if (/grafik/.test(c)) return 'S';
  if (/sırasıyla/.test(c)) return 'L';
  // I defter kaydı (hesap kodlu ya da çizgili kayıt şıkları da kayıt sorusudur)
  // hesap kodu = 3 haneli kod + BÜYÜK harfle başlayan hesap adı ("102 Bankalar"); "120 milyon TL" / "3000 Birim" tutardır, kayıt değil
  const kayitSik = (siklar || []).filter(s => /(^|\s)[1-7]\d\d\s+(?!TL|Birim|Adet|milyon|bin)[A-ZÇĞİÖŞÜ][a-zçğıöşü]/.test(String(s)) || /^\s*-{5,}/.test(String(s)) || /hesabına (borç|alacak)/i.test(String(s))).length >= 3;
  if ((/(yevmiye|muhasebe) kayd[ıi]|yap(ılacak|ması gereken|acağı|tığı) (.{0,30})?kayıt|kayıt aşağıdakilerden hangisidir|kayıtlardan hangisi yapılır|doğru kayıt/.test(c) || (kayitSik && !/hangi hesap/.test(c))) && !/doğrudur|yanlış|değildir/.test(c)) return 'I';
  if (/hangi hesap(ta|a|ın)|hesaplardan hangisinde/.test(c)) return 'J';
  // B yanlış
  if (/yanlış(tır|tir| olarak| bir| verilmiş)|yanlıştır/.test(c)) return 'B';
  // C olumsuz (cümlenin herhangi yerinde)
  // F/G önce: kökte en az 2 sayı + sayı şıklar = hesap (likidite oranı, faaliyet döngüsü, F/K…); "kaç üyeden az olamaz" ezberi C/G'ye kalır
  if (sayiSik && kokSayiHepsi >= 2 && !/az olamaz|fazla olamaz/.test(c)) return 'F';
  if (/(değildir|değil midir|biri değil|sayılmaz|sayılamaz|yer almaz|yer verilmez|girmez|kullanılamaz|kullanılmaz|bulunmaz|bulunamaz|aranmaz|olamaz|gerekmez|söylenemez|edilemez|yapılamaz|uygulanmaz|dahil edilmez|dâhil edilmez|kapsamında değil|mümkün değil|tabi değil|imkânı yoktur|imkanı yoktur|beklenmez|gerektirmez|değerlendirilmez|bulundurmayan|zorunluluğu yoktur|dikkate almamaktadır)\b/.test(c) || OLUMSUZ_SON.test(c)) return (olcuSik && /kaç|oran|süre/.test(c)) ? 'G' : 'C';
  // F: kökte en az 2 sayı + şıkların en az 3'ü tutar/birim taşıyor ("tutarı … hangisinde doğru olarak verilmiştir" = hesap; brif: tablo verip hesap isteyen F)
  const sikRakam = S.filter(s => !/\b\d{1,2}[./]\d{1,2}[./]\d{2,4}\b/.test(s) && /\d{1,3}(\.\d{3})+|\b\d{3,}\b|\d+\s*(tl|₺|birim|adet)|\(\d/.test(s)).length >= 3;
  if (sikRakam && kokSayiHepsi >= 2) return 'F';
  // F: oran/kârlılık/getiri hesabı — veri tabloda (kökte sayı görünmeyebilir), şıklar saf sayı
  if (sayiSik && /oran(ı|lar)|kârlılı|getiri|fiyat\/kazanç|devir|döngü|bugünkü değer|maliyeti|tutarı|kaç tl|ne kadardır|kaçtır|olur\s*\??$/.test(c) && !/içinde|en az|en fazla|az olamaz|aşamaz|zamanaşımı|kaç (gün|yıl|ay)/.test(c)) return 'F';
  // P durum → davranış
  if (/(malıdır|melidir)\s*\??$|en uygun(dur| olur)|yapması gerekir|gerektirir\s*\??$|beklenir\s*\??$|olacaktır\s*\??$|test eder|odaklanacak|gerçekleştirmelidir|uygulaması beklenir|vermesi beklenir|ne yapmalıdır|ne yapmalı|yapması gereken|atması gereken|hangi görüş|görüş(ün)? türü|nasıl hareket|hangisi gerçekleşir|sonuç doğurur|sebep olur|hangi karar|adımlardan hangisi|hangisini (atar|yapar|uygular|tasarlar|seçer|bildirir|kullanır)|yapması (en )?uygun|yapması beklenir|bildirmesi gerekir|hangi aşama(sında)?|nasıl (raporla|sınıflandır|muhasebeleştir|yansıt)|ne şekilde (raporla|sınıflandır|yansıt|muhasebeleştir)/.test(c)) return 'P';
  // O eylem → ceza / suç / yaptırım
  if (/yaptırım|cezası|ceza(ları)? uygula|suç(u|un|larından|lardan)|hapis/.test(c)) return 'O';
  // N yetkili merci
  if (/iznine tabi|izni(yle| ile)|onayı(yla| ile)|yetkili(dir)?\b|tarafından (belirlenir|verilir|yapılır|onaylanır|atanır|izlenir|oluşturulur|yürütülür|düzenlenir)|tarafından \S+(ır|ir|ur|ür)\s*\??$|kime |hangi (kurum|kuruluş|merci|organ)|kurumlardan hangisi|mercilerden hangisi|hangisine (bildirilir|bildirmek|başvur)|kimin |sorumludur\s*\??$|organdır\s*\??$|yerine getirir/.test(c)) return 'N';
  // A doğru / söylenebilir
  if (/doğrudur|doğru olarak|doğru bir|doğru ifade|tam ve eksiksiz|doğru şekilde|doğru verilmiştir|söylenebilir|söylenmesi (en )?uygun|en iyi açıklar|olumlu katkı/.test(c)) return (sayiSik && kokSayi >= 2) ? 'F' : 'A';
  // F / G sayı
  if (sayiSik || /kaç (tl|₺)|tutarı|kaçtır|ne kadardır|kaç(tır)?\?|yüzde kaç|oranı (nedir|kaçtır|aşağıdakilerden)/.test(c))
    return (kokSayi >= 2 || /hesapla|tutar|maliyet|değeri|getirisi|kârı|zararı|faiz/.test(c)) ? 'F' : 'G';
  if (/ne zaman|süre(si)? (içinde|kaç)|kaç gün|kaç yıl|en az kaç|en fazla kaç|hangi oranda|ne kadarlık|ara verme süresi/.test(c) || (olcuSik && kokSayiHepsi < 2)) return 'G';
  // M: tanım/kavram eşlemesi ("tanım … hangisine aittir", "kavramlardan hangisiyle ilişkilendirilebilir")
  if (/tanım|kavram(lar)?(ın)?dan hangisi|ne ad verilir|olarak adlandırılır|ifade edilmektedir/.test(c)) return 'M';
  // U sayılır / kapsam / üyelik
  if (/(örnektir|örnek teşkil eder|yer almaktadır|ilişkilidir|zorunlu tutulmuştur|sayılır|girer|girmektedir|kapsamındadır|kapsamında|biridir|birisidir|yer alır|tabidir|esas alınır|dikkate alınır|azaltır|artırır|örneğidir|örneklerdendir|aittir|içerir|kalemidir|unsurudur|sunabilir|açıklanır|iptal edilir|gösterilir|gösterilebilir|ilişkilendirilebilir|uygulanmaktadır|zorunludur|\S+(dandır|dendir|tandır|tendir)|yapılması gerekir|içermesi gerekir|yansıtılmalıdır|uygun olabilir)\s*\??$/.test(c)) return 'U';
  return 'M';
}
module.exports = { ayir, soruCumlesi };

if (require.main === module && process.argv.includes('--sinav')) {
  const D = __dirname, oku = f => JSON.parse(fs.readFileSync(path.join(D, f), 'utf8').replace(/^﻿/, ''));
  const girdi = {}; for (const q of oku('ayirici-girdi-yeni.json')) girdi[q.kimlik] = q;
  const elle = require('./elle-oku.js')(D).etiket;
  let n = 0, ok = 0; const kar = {};
  for (const [k, h] of Object.entries(elle)) {
    const q = girdi[k]; if (!q || h === '?') continue; n++; const a = ayir(q.kok, q.siklar);
    if (a === h) ok++; else { kar[`${h}→${a}`] = (kar[`${h}→${a}`] || 0) + 1; if (process.argv.includes('--ornek') && kar[`${h}→${a}`] <= 2) console.log(`  ${h}→${a} ${k}: «${soruCumlesi(q.kok).slice(-150)}»`); }
  }
  console.log(`KGK AYIRICI UYUMU: ${ok}/${n} = %${(100 * ok / n).toFixed(1)}`);
  console.log('en sık karışanlar:', Object.entries(kar).sort((a, b) => b[1] - a[1]).slice(0, 14).map(([k, v]) => `${k} ${v}`).join(' · '));
}
