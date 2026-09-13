// Öz-sınav: node radar-app/edge/karne-gonder.sinav.ts  (Node 24 tür silme; ağ/posta YOK)
import { dogrula, mailKur, kokenIzinli } from "./karne-gonder.ts";

let hata = 0;
const bekle = (ad: string, k: boolean) => { console.log((k ? "  geçti  " : "  DÜŞTÜ  ") + ad); if (!k) hata++; };
const iyi = () => ({ eposta: "Aday@Ornek.com", kvkk: true, izin_ileti: false, sinav: "sgs",
  sonuc: { gecme: 62, dogru130: 91, soru: 20, dogru: 14, gruplar: [
    { ad: "Muhasebe", dogru: 6, soru: 8 }, { ad: "Hukuk", dogru: 4, soru: 5 },
    { ad: "Ekonomi ve Maliye", dogru: 1, soru: 2 }, { ad: "Genel Kültür ve Yabancı Dil", dogru: 3, soru: 5 } ] } });

const d = dogrula(iyi());
bekle("geçerli gövde kabul, e-posta küçük harfe iner", d.ok === true && (d as any).eposta === "aday@ornek.com");
const boz = (f: (v: any) => void) => { const v = iyi(); f(v); return dogrula(v).ok; };
bekle("KVKK onayı yoksa RED", boz(v => { v.kvkk = false; }) === false);
bekle("e-posta bozuksa RED", boz(v => { v.eposta = "a@b"; }) === false);
bekle("geçme %96 (aralık dışı) RED", boz(v => { v.sonuc.gecme = 96; }) === false);
bekle("ondalık sayı RED", boz(v => { v.sonuc.gecme = 61.5; }) === false);
bekle("bilinmeyen grup adı (serbest metin) RED", boz(v => { v.sonuc.gruplar[0].ad = "<a href=x>tıkla</a>"; }) === false);
bekle("grup toplamı tutmazsa RED", boz(v => { v.sonuc.gruplar[0].dogru = 7; }) === false);
bekle("tekrarlanan grup RED", boz(v => { v.sonuc.gruplar[1].ad = "Muhasebe"; }) === false);
bekle("desteklenmeyen sınav RED", boz(v => { v.sinav = "smmm"; }) === false);
bekle("fazladan serbest alan (mesaj) mail içeriğine GİRMEZ", (() => { const v: any = iyi(); v.mesaj = "SPAM-METNI-XYZ"; const r: any = dogrula(v); const m = mailKur(r.sonuc); return r.ok && !m.html.includes("SPAM-METNI-XYZ") && !m.metin.includes("SPAM-METNI-XYZ"); })());
const m = mailKur((d as any).sonuc);
bekle("mail: geçme yüzdesi, tahmini doğru, en zayıf grup, 'tahmin' notu, KVKK bağlantısı var",
  m.konu.includes("%62") && m.html.includes("yaklaşık <b>91</b>") && m.metin.includes("En çok çalışman gereken grup: Ekonomi ve Maliye") && m.metin.includes("Bu bir TAHMİNDİR") && m.html.includes("/kvkk.html"));
bekle("seviye metni eşikleri: 62 -> Sınırdasın", m.metin.includes("Sınırdasın"));
bekle("köken: tetikte.com izinli, başka site değil", kokenIzinli("https://tetikte.com") && kokenIzinli("http://localhost:5173") && !kokenIzinli("https://kotu.example"));
console.log(`KARNE-GÖNDER öz-sınav: ${13 - hata}/13`);
if (hata) process.exit(1);
