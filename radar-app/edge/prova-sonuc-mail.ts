// ============================================================================
//  PROVA-SONUC-MAIL Edge Function — Sınav Provası sonuç maili (11.10.2026, Cem: "sonucu sonra mail ile atmak mantıklı")
//
//  AKIŞ: canli-deneme.html teslimde üye ise public.prova_sonuc_mail'e tek satır bırakır (üye kimliği + doğru/yanlış/boş
//  + ders ders özet; e-posta YOK). Prova kapanıp motor/canli-yuzdelik.ps1 sonuc-<kod>.json'u yayınlayınca bu fonksiyon
//  motor/prova-sonuc-mail.ps1 ile çağrılır: satırları okur, üyenin e-postasını auth.users'tan SUNUCUDA bulur, yüzdeliği
//  yayınlanmış eşik tablosundan oturtur, kurumsal kabuklu maili Resend toplu ucuyla yollar, satırı damgalar.
//
//  KİŞİ VERİSİ: tarayıcıdan, Actions'tan, depodan geçmez. Çağıran yalnız oturum kodu + mod gönderir; cevapta ve
//  günlükte yalnız SAYI döner (gönderilen / atlanan / kalan). Prova modunda alıcı yalnız istekte verilen adres.
//
//  YETKİ: çağıranın anahtarı servis anahtarı olmalı — Authorization'daki anahtarla auth admin ucu okunabiliyorsa geçer
//  (yeni sb_secret_ anahtarı JWT değil; bu yüzden YAYIN.json'da jwt:false, yetki burada). Anahtar günlüğe yazılmaz.
//
//  MODLAR (POST JSON):
//    {oturum:'SGS-1710', mod:'prova', alici:'x@y'}  -> tek mail, YALNIZ alici'ya; damga YOK. Tabloda satır yoksa ya da
//        yüzdelik yayınlanmadıysa ÖRNEK veriyle gider, konu "[PROVA · örnek veri]" ile başlar.
//    {oturum:'SGS-1710', mod:'toplu', onay:'<Cem onayı: tarih + söz>'} -> damgasız satırlardan en çok 90'ı; yüzdelik
//        yayınlanmadıysa 409. onay boşsa 403 (Cem onayı olmadan toplu gönderim YOK). Kalan varsa betik yeniden çağırır.
//  🚫 GÖRMEZ: üyenin aynı provayı başka cihazdan ikinci kez çözmesi (ilk satır kalır) · Resend'in "gönderildi" deyip
//     kutuya düşürmemesi (teslim ölçümü Resend panelinde) · uye_id'nin gerçekten o cihazın sahibi olması (uuid bilmek gerekir).
//  YAYIN: .github/workflows/edge-yukle.yml OTOMATİK (YAYIN.json). Secrets: RESEND_KEY, RESEND_FROM (ortak).
// ============================================================================

const KOD_IMZA = "f53af7306a432900";
const SITE = "https://tetikte.com";
const kacis = (s: string) => String(s ?? "").replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");

// KURUMSAL-MAIL-BASLA — 05.10.2026 Cem ("kurumsal bir yapı yap ... diğerlerine de bunu yapalım"): bütün müşteri
// maillerinin ORTAK kabuğu. Edge fonksiyonları TEK DOSYA yüklenir (edge-yukle.yml) → bu blok karne-gonder, siparis-bildirim,
// elci-sozlesme, nobetci-sor'da AYNEN durur; birinde değişirse hepsinde değiştir (şifre maili radar-app/auth-mail/recovery.html
// aynı görünüm, Supabase panelinden). Mail istemcileri CSS/SVG çizmez: tablo düzeni + satır içi stil; logo gorsel/logo-mail.png
// (Outlook ilk açılışta resmi gizleyebilir → alt="Tetikte"). "neden" yalnız sabit metin alır (kullanıcı verisi GİRMEZ).
export function kurumsalMail(ic: string, neden: string): string {
  return `<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="background:#f3f4f6;padding:28px 12px;font-family:Segoe UI,Roboto,Helvetica,Arial,sans-serif"><tr><td align="center">
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="max-width:600px;background:#ffffff;border:1px solid #e5e7eb;border-radius:12px">
<tr><td style="padding:26px 32px 18px;border-bottom:1px solid #f0f1f3"><img src="https://tetikte.com/gorsel/logo-mail.png" width="137" height="40" alt="Tetikte" style="display:block;border:0;outline:none"></td></tr>
<tr><td style="padding:26px 32px 6px;color:#16191d;font-size:15px;line-height:1.6">${ic}</td></tr>
<tr><td style="padding:14px 32px 26px"><p style="margin:0;font-size:14px;color:#16191d">Saygılarımızla,<br><b>Tetikte Destek Ekibi</b></p></td></tr>
<tr><td style="padding:18px 32px;background:#fafafa;border-top:1px solid #f0f1f3;border-radius:0 0 12px 12px;font-size:12px;line-height:1.6;color:#6b7280">
<b style="color:#16191d">Sınava tetikte gir.</b><br>
<b style="color:#4b5563">Dizdar Denetim Danışmanlık ve Yazılım A.Ş.</b><br>Alsancak Mah. Atatürk Cad. Kavalalı İş Merkezi No:378 B, Konak / İzmir<br>
<a href="mailto:destek@tetikte.com" style="color:#6b7280">destek@tetikte.com</a> · 0532 344 80 58 · <a href="https://tetikte.com" style="color:#6b7280">tetikte.com</a><br>
<span style="color:#9ca3af">${neden} <a href="https://tetikte.com/kvkk.html" style="color:#9ca3af">Kişisel verilerin korunması</a></span></td></tr>
</table></td></tr></table>`;
}
// KURUMSAL-MAIL-BITIR

type DersSatir = { d: string; s: number; k: number };           // ders adı · soru sayısı · doğru
type Satir = { id: number; uye_id: string; dogru: number; yanlis: number; bos: number; ders: DersSatir[] | null };
type Sonuc = { tur?: string; katilim?: number; ortalama?: number; medyan?: number; esikler?: { dogru: number; yuzde: number }[] };
type Oturum = { ad: string; sinav: string; tarih: string; saat?: string; gizli?: boolean };
const AYLAR = ["Ocak", "Şubat", "Mart", "Nisan", "Mayıs", "Haziran", "Temmuz", "Ağustos", "Eylül", "Ekim", "Kasım", "Aralık"];
const GUNLER = ["Pazar", "Pazartesi", "Salı", "Çarşamba", "Perşembe", "Cuma", "Cumartesi"];
const tarihMs = (o: Oturum) => Date.parse(o.tarih.split(".").reverse().join("-") + "T" + (o.saat || "10:00") + ":00+03:00");
// 17.10 Cem ("sonuç maili yerine 24.10 provasına davet daha iyi olur · sonuç hala atacağız tabiki de"): mailin sonunda SIRADAKİ prova daveti
//   SGS'ye giren çoğunlukla Yeterlilik adayı değil → sıradaki prova başka sınavınsa "… de hazırlanıyorsan" diye açılır.
export function davetMetni(s: Oturum | null, simdikiSinav = ""): string {
  if (!s) return "";
  const d = new Date(tarihMs(s) + 3 * 36e5);
  const ne = `${d.getUTCDate()} ${AYLAR[d.getUTCMonth()]} ${GUNLER[d.getUTCDay()]} ${s.saat || "10:00"} · ${s.sinav} ${s.ad}`;
  // 17.10 Cem: "SGS giren niye bitirme girsin, olmaz öyle" → başka sınavın provasına davet YOK; yalnız aynı sınav
  return s.sinav === simdikiSinav ? `Sıradaki prova: ${ne}. Üye olduğun için yerin hazır; o gün tetikte.com'a gir.` : "";
}

const RESMI_DEGIL = "Sınav Provası, Tetikte'nin kendi deneme sınavıdır; TÜRMOB ve TESMER'in yaptığı resmî sınavlarla bağlantısı yoktur. Yüzdelik sıralama, bu provaya katılan Tetikte üyeleri arasında hesaplanır.";
const NEDEN = "Bu e-posta, tetikte.com'da üye olarak katıldığın Sınav Provası'nın sonucu için bir kez gönderilmiştir.";
const BAG = `${SITE}/canli-deneme.html?k=mail#incele`;

// en zayıf ders: en az 3 sorulu dersler içinde doğru oranı en düşük; eşitlikte soru sayısı çok olan (daha çok puan kaybı)
export function zayifDers(ders: DersSatir[] | null): DersSatir | null {
  const l = (ders || []).filter((x) => x && x.d && x.s > 0);
  const aday = l.filter((x) => x.s >= 3).length ? l.filter((x) => x.s >= 3) : l;
  if (!aday.length) return null;
  return aday.slice().sort((a, b) => (a.k / a.s) - (b.k / b.s) || (b.s - a.s))[0];
}
export function yuzdeBul(son: Sonuc | null, dogru: number): number | null {
  if (!son || son.tur !== "yuzdelik" || !Array.isArray(son.esikler)) return null;
  let y: number | null = 0;
  for (const e of son.esikler) if (dogru >= e.dogru) y = e.yuzde;
  return y;
}

export function sonucMail(r: Satir, o: Oturum, son: Sonuc | null, prova: boolean, sonraki: Oturum | null = null) {
  const davet = davetMetni(sonraki, o.sinav);
  const soru = r.dogru + r.yanlis + r.bos;
  const ad = `${o.sinav} Sınav Provası`;
  const y = yuzdeBul(son, r.dogru);
  const zd = zayifDers(r.ders);
  const sirali = (r.ders || []).filter((x) => x && x.s > 0).slice().sort((a, b) => (a.k / a.s) - (b.k / b.s) || (b.s - a.s));
  const konu = `${prova ? "[PROVA · örnek veri] " : ""}${ad} sonucun: ${r.dogru}/${soru} doğru`;
  const sira = y !== null
    ? `Bu provaya katılan ${son!.katilim} Tetikte üyesi içinde senden düşük puan alanların oranı: %${y}.`
    : son && son.tur === "seviye"
      // 17.10 Cem ("çok az kişi girdiyse saçma olabilir"): az katılımda kişi sayısı ve ortalama YAZILMAZ — küçük grubun ortalaması yanıltır
      ? "Bu provada katılım, güvenilir bir yüzdelik sıralama hesaplamaya yetmedi; bu yüzden sıralama vermiyoruz. Puanın ve ders ders sonucun aşağıda."
      : "Yüzdelik sıralama henüz açıklanmadı.";
  const zayif = zd ? `En çok puan kaybettiğin ders: ${zd.d} (${zd.k}/${zd.s} doğru).` : "";
  const metin = [
    "Merhaba,", "",
    `${o.tarih} tarihli ${ad}'na katıldın. Sonucun:`,
    `${r.dogru} doğru · ${r.yanlis} yanlış · ${r.bos} boş (${soru} soru)`, "",
    sira, zayif, "",
    "Her sorunun cevap anahtarı ve kaynak maddesiyle açıklaması sitede:", BAG, "",
    davet, "",
    RESMI_DEGIL, "", "Sınava tetikte gir.",
  ].filter((x, i, a) => !(x === "" && a[i - 1] === "")).join("\n");
  const tablo = sirali.length ? `<table style="border-collapse:collapse;margin:8px 0 14px;font-size:13.5px;width:100%">
<tr><td style="padding:5px 8px;border-bottom:1px solid #e5e7eb;color:#6b7280">Ders</td><td style="padding:5px 8px;border-bottom:1px solid #e5e7eb;color:#6b7280;text-align:right">Doğru / Soru</td></tr>
${sirali.map((x) => `<tr><td style="padding:5px 8px;border-bottom:1px solid #f0f1f3">${kacis(x.d)}</td><td style="padding:5px 8px;border-bottom:1px solid #f0f1f3;text-align:right">${x.k} / ${x.s}</td></tr>`).join("\n")}
</table>` : "";
  const html = kurumsalMail(`${prova ? '<p style="background:#fff7e6;border:1px solid #f3a52a;border-radius:8px;padding:8px 12px;font-size:13px"><b>PROVA:</b> bu mail örnek veriyle, görünümü denetlemek için gönderildi.</p>' : ""}
<p>Merhaba,</p><p><b>${kacis(o.tarih)}</b> tarihli <b>${kacis(ad)}</b>'na katıldın. Sonucun:</p>
<p style="font-size:22px;font-weight:700;margin:6px 0">${r.dogru} doğru <span style="font-size:15px;font-weight:400;color:#4b5563">· ${r.yanlis} yanlış · ${r.bos} boş (${soru} soru)</span></p>
<p style="font-size:16px;color:#9a5b00;font-weight:700">${kacis(sira)}</p>
${zd ? `<p>En çok puan kaybettiğin ders: <b>${kacis(zd.d)}</b> (${zd.k}/${zd.s} doğru).</p>` : ""}
${tablo}
<p><a href="${BAG}" style="display:inline-block;background:#f3a52a;color:#0f1b2d;font-weight:700;padding:10px 18px;border-radius:9px;text-decoration:none">Açıklamaları sitede gör</a></p>
${davet ? `<p style="border-top:1px solid #f0f1f3;padding-top:12px">${kacis(davet)}</p>` : ""}
<p style="font-size:12.5px;color:#6b7280">${kacis(RESMI_DEGIL)}</p>`, NEDEN);
  return { konu, metin, html };
}

function oturumKodu(o: Oturum): string {
  const p = o.tarih.split(".");
  return ((o.sinav || "").indexOf("SGS") >= 0 ? "SGS" : "YET") + "-" + p[0] + p[1];
}

if (typeof Deno !== "undefined" && Deno.serve) Deno.serve(async (req: Request) => {
  const SB_URL = (Deno.env.get("SUPABASE_URL") ?? "https://bjrleanjpyujtajmazxn.supabase.co").replace(/\/$/, "");
  const SB_SERVICE = (Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "").trim();
  const RESEND_KEY = (Deno.env.get("RESEND_KEY") ?? "").trim();
  const RESEND_FROM = (Deno.env.get("RESEND_FROM") ?? "Tetikte <bildirim@tetikte.com>").trim();
  const H = { "Content-Type": "application/json; charset=utf-8" };
  const cevap = (k: number, g: unknown) => new Response(JSON.stringify(g), { status: k, headers: H });
  if (new URL(req.url).searchParams.get("surum") === "1") return cevap(200, { surum: KOD_IMZA, secret: { RESEND_KEY: !!RESEND_KEY, SERVICE: !!SB_SERVICE } });
  if (req.method !== "POST") return cevap(405, { hata: "yalniz POST" });
  if (!SB_SERVICE || !RESEND_KEY) return cevap(503, { hata: "kurulum eksik" });

  // yetki: çağıranın anahtarı auth admin ucunu okuyabiliyor mu (yalnız servis/sb_secret anahtarı okur)
  const anahtar = (req.headers.get("authorization") || "").replace(/^Bearer\s+/i, "").trim();
  if (!anahtar) return cevap(401, { hata: "yetki yok" });
  try {
    const y = await fetch(`${SB_URL}/auth/v1/admin/users?page=1&per_page=1`, { headers: { apikey: anahtar, Authorization: `Bearer ${anahtar}` } });
    if (!y.ok) return cevap(403, { hata: "yetki yok" });
  } catch { return cevap(403, { hata: "yetki yok" }); }

  let g: { oturum?: string; mod?: string; alici?: string; onay?: string } = {};
  try { g = await req.json(); } catch { return cevap(400, { hata: "gecersiz istek" }); }
  const kod = String(g.oturum || "");
  const mod = g.mod === "toplu" ? "toplu" : g.mod === "prova" ? "prova" : "";
  if (!/^(SGS|YET)-[0-9]{4}$/.test(kod) || !mod) return cevap(400, { hata: "gecersiz istek" });

  const sb = (yol: string, sec?: RequestInit) => fetch(`${SB_URL}/rest/v1/${yol}`, Object.assign({
    headers: { apikey: SB_SERVICE, Authorization: `Bearer ${SB_SERVICE}`, "Content-Type": "application/json" } }, sec || {}));

  // oturum adı/tarihi takvimden; yüzdelik yayınlanmış sonuç dosyasından (sayfanın okuduğu dosyanın aynısı)
  let o: Oturum | null = null; let sonraki: Oturum | null = null;
  try {
    const t = await (await fetch(`${SITE}/veri/canli-deneme.json?t=${Date.now()}`)).json();
    o = (t.oturumlar || []).find((x: Oturum) => oturumKodu(x) === kod) || null;
    if (o) sonraki = (t.oturumlar || []).filter((x: Oturum) => !x.gizli && x.sinav === o!.sinav && tarihMs(x) > tarihMs(o!)).sort((a: Oturum, b: Oturum) => tarihMs(a) - tarihMs(b))[0] || null;
  } catch { /* aşağıda */ }
  if (!o) return cevap(404, { hata: "oturum takvimde yok" });
  let son: Sonuc | null = null;
  try { const r = await fetch(`${SITE}/veri/canli/sonuc-${kod}.json?t=${Date.now()}`); if (r.ok) son = await r.json(); } catch { /* yok */ }

  const posta = async (uid: string): Promise<string> => {
    try {
      const u = await fetch(`${SB_URL}/auth/v1/admin/users/${uid}`, { headers: { apikey: SB_SERVICE, Authorization: `Bearer ${SB_SERVICE}` } });
      if (!u.ok) return "";
      const j = await u.json(); return String(j.email || "").trim();
    } catch { return ""; }
  };
  const resend = (mailler: unknown[]) => fetch("https://api.resend.com/emails/batch", { method: "POST",
    headers: { Authorization: `Bearer ${RESEND_KEY}`, "content-type": "application/json" }, body: JSON.stringify(mailler) });

  if (mod === "prova") {
    const alici = String(g.alici || "").trim();
    if (!/^[^@\s]{1,64}@[^@\s]{1,190}\.[a-z]{2,}$/i.test(alici)) return cevap(400, { hata: "alici gecersiz" });
    let r: Satir | null = null;
    try { const x = await sb(`prova_sonuc_mail?select=id,uye_id,dogru,yanlis,bos,ders&oturum=eq.${kod}&order=id&limit=1`); if (x.ok) r = (await x.json())[0] || null; } catch { /* örnek */ }
    const ornekDers: DersSatir[] = [{ d: "Finansal Muhasebe", s: 26, k: 15 }, { d: "Denetim", s: 16, k: 6 }, { d: "Vergi Hukuku", s: 6, k: 4 }, { d: "Ticaret Hukuku", s: 6, k: 3 }];
    const ornek = !r || !son;
    const satir: Satir = r || { id: 0, uye_id: "", dogru: 28, yanlis: 17, bos: 9, ders: ornekDers };
    const sonuc: Sonuc = son || { tur: "yuzdelik", katilim: 120, esikler: [{ dogru: 0, yuzde: 0 }, { dogru: 20, yuzde: 40 }, { dogru: 28, yuzde: 63 }] };
    const m = sonucMail(satir, o, sonuc, ornek, sonraki);
    const s = await resend([{ from: RESEND_FROM, to: [alici], subject: m.konu, text: m.metin, html: m.html, reply_to: "destek@tetikte.com" }]);
    console.log(`prova-sonuc-mail ${kod} prova ornek=${ornek} RESEND ${s.status}`);
    return s.ok ? cevap(200, { success: true, prova: true, ornek, gercek_satir: !!r, yuzdelik_yayinda: !!son }) : cevap(502, { hata: "mail gonderilemedi", durum: s.status });
  }

  // toplu
  if (!String(g.onay || "").trim()) return cevap(403, { hata: "Cem onayi yok" });
  if (!son || (son.tur !== "yuzdelik" && son.tur !== "seviye")) return cevap(409, { hata: "yuzdelik yayinlanmadi" });
  const x = await sb(`prova_sonuc_mail?select=id,uye_id,dogru,yanlis,bos,ders&oturum=eq.${kod}&gonderim=is.null&order=id&limit=90`);
  if (!x.ok) return cevap(502, { hata: "tablo okunamadi" });
  const satirlar: Satir[] = await x.json();
  if (!satirlar.length) return cevap(200, { success: true, gonderilen: 0, kalan: 0 });
  // önce damga (eşzamanlı iki çağrı aynı kişiye iki mail atmasın): yalnız damgası boş satırlar alınır
  const an = new Date().toISOString();
  const d = await sb(`prova_sonuc_mail?id=in.(${satirlar.map((s) => s.id).join(",")})&gonderim=is.null`, { method: "PATCH", body: JSON.stringify({ gonderim: an }),
    headers: { apikey: SB_SERVICE, Authorization: `Bearer ${SB_SERVICE}`, "Content-Type": "application/json", Prefer: "return=representation" } });
  const alinan: Satir[] = d.ok ? await d.json() : [];
  const mailler: unknown[] = []; const gidenId: number[] = []; let adressiz = 0;
  for (let i = 0; i < alinan.length; i += 10) {
    const parca = alinan.slice(i, i + 10);
    const adresler = await Promise.all(parca.map((s) => posta(s.uye_id)));
    parca.forEach((s, j) => {
      if (!adresler[j]) { adressiz++; return; }
      const m = sonucMail(s, o!, son, false, sonraki);
      mailler.push({ from: RESEND_FROM, to: [adresler[j]], subject: m.konu, text: m.metin, html: m.html, reply_to: "destek@tetikte.com" });
      gidenId.push(s.id);
    });
  }
  if (mailler.length) {
    const s = await resend(mailler);
    if (!s.ok) {
      // gönderilemedi: damgayı geri al ki yeniden denensin
      await sb(`prova_sonuc_mail?id=in.(${gidenId.join(",")})`, { method: "PATCH", body: JSON.stringify({ gonderim: null }) });
      console.log(`prova-sonuc-mail ${kod} toplu RESEND ${s.status} (${mailler.length} geri alindi)`);
      return cevap(502, { hata: "mail gonderilemedi", durum: s.status });
    }
  }
  const k = await sb(`prova_sonuc_mail?select=id&oturum=eq.${kod}&gonderim=is.null&limit=1000`);
  const kalan = k.ok ? (await k.json()).length : -1;
  console.log(`prova-sonuc-mail ${kod} toplu gonderilen ${mailler.length} adressiz ${adressiz} kalan ${kalan}`);
  return cevap(200, { success: true, gonderilen: mailler.length, adressiz, kalan });
});
