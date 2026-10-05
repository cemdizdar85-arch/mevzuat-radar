// ============================================================================
//  SIPARIS-BILDIRIM Edge Function — müşteriye sipariş mailleri (04.10.2026, Cem: "üye olanlar, ücret ödeyenlerin
//  hepsi Amazon / Trendyol gibi otomatik olsun ... eksiğimiz varsa site açılmadan düzeltelim")
//
//  BOŞLUK (04.10 ölçüldü): sipariş bilgisi (no + IBAN + tutar) yalnız ekranda kalıyordu; sayfayı kapatan IBAN'ı
//  kaybediyordu. Ödeme onaylanınca da müşteriye haber gitmiyordu.
//
//  İKİ MAİL:
//    tur:'alindi'  -> satin-al.html sipariş kaydından hemen sonra çağırır: sipariş no, tutar, IBAN, açıklama notu.
//    tur:'acildi'  -> yonetim.html "Ödendi, paketi aç" başarılı olunca çağırır: paketin açıldı / üye ol.
//
//  SPAM / İSTİSMAR KAPISI OLMASIN DİYE:
//    - Tarayıcıdan YALNIZ sipariş no + tür gelir. Alıcı adresi, ad, tutar, paket SUNUCUDA siparisler'den okunur.
//    - Her mail siparişte BİR KEZ (alindi_mail / acildi_mail damgası). 'alindi' yalnız ödeme bekleyen ve 2 saatten
//      yeni siparişte; 'acildi' yalnız durumu 'odendi' olan siparişte. Başka biri sipariş no tahmin etse bile
//      yalnız o siparişin sahibine, yalnız bir kez, doğru içerikli mail gider.
//    - Günlüğe kişi verisi basılmaz (yalnız sipariş no + sonuç).
//  SQL: radar-app/sql/2026-10-05-otomatik-paket.sql (alindi_mail, acildi_mail, paket_bitis kolonları).
//  YAYIN: .github/workflows/edge-yukle.yml OTOMATİK (radar-app/edge/YAYIN.json'da listeli). Secrets karne-gonder ile
//         ortak: RESEND_KEY, RESEND_FROM; SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY Supabase'in kendi değişkenleri.
//  ⚠ IBAN fiyat-motoru.js ODEME_BANKA ile AYNI olmalı (orada değişirse burada da).
// ============================================================================

const KOD_IMZA = "70ee50d10fae7ba5";
const BANKA = { ad: "VakıfBank", iban: "TR74 0001 5001 5800 7376 2710 72", alici: "Dizdar Denetim Danışmanlık ve Yazılım A.Ş." };
const IZINLI = new Set(["https://tetikte.com", "https://www.tetikte.com"]);
const YEREL = /^http:\/\/(localhost|127\.0\.0\.1)(:\d{1,5})?$/;
const izinli = (o: string | null) => !!o && (IZINLI.has(o) || YEREL.test(o));
const kacis = (s: string) => String(s ?? "").replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");
const tl = (n: number) => Number(n || 0).toLocaleString("tr-TR") + " TL";
const tarih = (d: string | null) => { if (!d) return ""; const [y, a, g] = String(d).slice(0, 10).split("-"); return `${g}.${a}.${y}`; };

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

export function alindiMail(s: { siparis_no: string; ad_soyad: string; paket_ad: string | null; paket: string; tutar: number }) {
  const ad = (s.ad_soyad || "").split(/\s+/)[0] || "Merhaba";
  const konu = `Siparişin alındı: ${s.siparis_no} · ${tl(s.tutar)}`;
  const satirlar = [
    `Merhaba ${ad},`, "",
    `Tetikte siparişin alındı. Ödemeni aşağıdaki hesaba havale/EFT ile yapınca paketin açılır.`, "",
    `Sipariş no: ${s.siparis_no}`, `Paket: ${s.paket_ad || s.paket}`, `Ödenecek tutar (KDV dahil): ${tl(s.tutar)}`, "",
    `Banka: ${BANKA.ad}`, `Alıcı: ${BANKA.alici}`, `IBAN: ${BANKA.iban}`,
    `Açıklama: ${s.siparis_no}  (havale açıklamasına yalnız sipariş numaranı yaz)`, "",
    "Ödemen hesabımıza geçtiği gün paketin açılır ve sana ayrıca e-posta gelir. E-arşiv faturan da bu adrese gönderilir.",
    "Siparişi verdiğin e-postayla tetikte.com'da ücretsiz hesap açmadıysan şimdi açabilirsin; ödeme onaylanınca paket o hesaba kendiliğinden bağlanır.", "",
    "Sorun olursa bu e-postayı yanıtla ya da destek@tetikte.com'a yaz.", "", "Sınava tetikte gir.",
  ];
  const html = kurumsalMail(`<p>Merhaba ${kacis(ad)},</p><p>Tetikte siparişin alındı. Ödemeni aşağıdaki hesaba <b>havale/EFT</b> ile yapınca paketin açılır.</p>
<table style="border-collapse:collapse;margin:10px 0">
<tr><td style="padding:4px 14px 4px 0;color:#3d4b63">Sipariş no</td><td><b>${kacis(s.siparis_no)}</b></td></tr>
<tr><td style="padding:4px 14px 4px 0;color:#3d4b63">Paket</td><td>${kacis(s.paket_ad || s.paket)}</td></tr>
<tr><td style="padding:4px 14px 4px 0;color:#3d4b63">Ödenecek (KDV dahil)</td><td><b>${kacis(tl(s.tutar))}</b></td></tr>
<tr><td style="padding:12px 14px 4px 0;color:#3d4b63">Banka</td><td style="padding-top:12px">${kacis(BANKA.ad)}</td></tr>
<tr><td style="padding:4px 14px 4px 0;color:#3d4b63">Alıcı</td><td>${kacis(BANKA.alici)}</td></tr>
<tr><td style="padding:4px 14px 4px 0;color:#3d4b63">IBAN</td><td><b>${kacis(BANKA.iban)}</b></td></tr>
<tr><td style="padding:4px 14px 4px 0;color:#3d4b63">Açıklama</td><td><b>${kacis(s.siparis_no)}</b> <span style="color:#3d4b63">(yalnız sipariş numaran)</span></td></tr>
</table>
<p>Ödemen hesabımıza geçtiği gün paketin açılır ve sana ayrıca e-posta gelir. E-arşiv faturan da bu adrese gönderilir.</p>
<p>Siparişi verdiğin e-postayla <a href="https://tetikte.com/ogrenci.html#uye-ol">tetikte.com'da ücretsiz hesap</a> açmadıysan şimdi açabilirsin; ödeme onaylanınca paket o hesaba kendiliğinden bağlanır.</p>
<p style="color:#3d4b63">Sorun olursa bu e-postayı yanıtla ya da destek@tetikte.com'a yaz.</p>`, "Bu e-posta, tetikte.com'da verdiğin sipariş üzerine gönderilmiştir.");
  return { konu, metin: satirlar.join("\n"), html };
}

export function acildiMail(s: { siparis_no: string; ad_soyad: string; paket_ad: string | null; paket: string; paket_bitis: string | null }, hesapVar: boolean) {
  const ad = (s.ad_soyad || "").split(/\s+/)[0] || "Merhaba";
  const konu = `Ödemen onaylandı, paketin açıldı: ${s.paket_ad || s.paket}`;
  const bitis = s.paket_bitis ? tarih(s.paket_bitis) : "";
  const giris = hesapVar
    ? "tetikte.com'a bu e-postayla giriş yap; Hesabım'da paketin görünür, soru çözmeye hemen başlayabilirsin."
    : "Bu e-postayla tetikte.com'da ücretsiz hesap aç (Hesabım → Üye ol ya da Google ile); paketin hesabına kendiliğinden bağlanır.";
  const satirlar = [`Merhaba ${ad},`, "", `${s.siparis_no} numaralı siparişinin ödemesi hesabımıza geçti.`,
    `Paket: ${s.paket_ad || s.paket}${bitis ? " · " + bitis + " tarihine kadar" : ""}`, "", giris, "", "https://tetikte.com/ogrenci.html", "",
    "Sorun olursa bu e-postayı yanıtla ya da destek@tetikte.com'a yaz.", "", "Sınava tetikte gir."];
  const html = kurumsalMail(`<p>Merhaba ${kacis(ad)},</p><p><b>${kacis(s.siparis_no)}</b> numaralı siparişinin ödemesi hesabımıza geçti.</p>
<p>Paket: <b>${kacis(s.paket_ad || s.paket)}</b>${bitis ? " · " + kacis(bitis) + " tarihine kadar" : ""}</p>
<p>${kacis(giris)}</p>
<p><a href="https://tetikte.com/ogrenci.html" style="display:inline-block;background:#f3a52a;color:#0f1b2d;font-weight:700;padding:10px 18px;border-radius:9px;text-decoration:none">${hesapVar ? "Hesabıma git" : "Ücretsiz hesap aç"}</a></p>
<p style="color:#3d4b63">Sorun olursa bu e-postayı yanıtla ya da destek@tetikte.com'a yaz.</p>`, "Bu e-posta, tetikte.com'da verdiğin sipariş üzerine gönderilmiştir.");
  return { konu, metin: satirlar.join("\n"), html };
}

if (typeof Deno !== "undefined" && Deno.serve) Deno.serve(async (req: Request) => {
  const SB_URL = (Deno.env.get("SUPABASE_URL") ?? "https://bjrleanjpyujtajmazxn.supabase.co").replace(/\/$/, "");
  const SB_SERVICE = (Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "").trim();
  const RESEND_KEY = (Deno.env.get("RESEND_KEY") ?? "").trim();
  const RESEND_FROM = (Deno.env.get("RESEND_FROM") ?? "Tetikte <bildirim@tetikte.com>").trim();
  const origin = req.headers.get("origin");
  const cors = {
    "Access-Control-Allow-Origin": izinli(origin) ? (origin as string) : "https://tetikte.com",
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, accept",
    "Access-Control-Allow-Methods": "POST, OPTIONS", "Vary": "Origin", "Content-Type": "application/json; charset=utf-8",
  };
  const cevap = (k: number, g: unknown) => new Response(JSON.stringify(g), { status: k, headers: cors });
  if (req.method === "OPTIONS") return new Response(null, { status: 204, headers: cors });
  if (new URL(req.url).searchParams.get("surum") === "1") return cevap(200, { surum: KOD_IMZA, secret: { RESEND_KEY: !!RESEND_KEY, SERVICE: !!SB_SERVICE } });
  if (req.method !== "POST") return cevap(405, { hata: "yalniz POST" });
  if (!SB_SERVICE || !RESEND_KEY) return cevap(503, { hata: "kurulum eksik" });

  let g: { tur?: string; no?: string } = {};
  try { g = await req.json(); } catch { return cevap(400, { hata: "gecersiz istek" }); }
  const tur = g.tur === "acildi" ? "acildi" : g.tur === "alindi" ? "alindi" : "";
  const no = String(g.no ?? "");
  if (!tur || !/^TT-[0-9]{8}-[ACDEFHJKLMNPRTUVXYZ2345679]{4}$/.test(no)) return cevap(400, { hata: "gecersiz istek" });

  const sb = (yol: string, sec?: RequestInit) => fetch(`${SB_URL}/rest/v1/${yol}`, Object.assign({
    headers: { apikey: SB_SERVICE, Authorization: `Bearer ${SB_SERVICE}`, "Content-Type": "application/json" } }, sec || {}));
  const r = await sb(`siparisler?select=id,siparis_no,ad_soyad,email,paket,paket_ad,tutar,durum,olusturma,paket_bitis,alindi_mail,acildi_mail&siparis_no=eq.${encodeURIComponent(no)}&limit=1`);
  if (!r.ok) return cevap(502, { hata: "siparis okunamadi" });
  const s = (await r.json())[0];
  if (!s) return cevap(404, { hata: "siparis yok" });

  let m: { konu: string; metin: string; html: string }; let damga: string;
  if (tur === "alindi") {
    if (s.alindi_mail) return cevap(200, { success: true, zaten: true });
    if (s.durum !== "odeme_bekliyor" || Date.now() - new Date(s.olusturma).getTime() > 2 * 3600 * 1000) return cevap(409, { hata: "uygun degil" });
    m = alindiMail(s); damga = "alindi_mail";
  } else {
    if (s.acildi_mail) return cevap(200, { success: true, zaten: true });
    if (s.durum !== "odendi") return cevap(409, { hata: "odenmemis" });
    // hesap var mı: paket_uyeler üzerinden değil, auth admin ile (e-posta eşleşmesi) — yalnız var/yok
    let hesapVar = false;
    try {
      const u = await fetch(`${SB_URL}/auth/v1/admin/users?page=1&per_page=1000`, { headers: { apikey: SB_SERVICE, Authorization: `Bearer ${SB_SERVICE}` } });
      const j = await u.json(); hesapVar = (j.users || []).some((x: { email?: string }) => String(x.email || "").toLowerCase() === String(s.email).toLowerCase());
    } catch { /* bilinmiyorsa "hesap aç" metni gider - zararsız */ }
    m = acildiMail(s, hesapVar); damga = "acildi_mail";
  }

  // önce damga (iki eşzamanlı istekte iki mail gitmesin): yalnız damga boşsa yazılır
  const d = await sb(`siparisler?id=eq.${s.id}&${damga}=is.null`, { method: "PATCH", body: JSON.stringify({ [damga]: new Date().toISOString() }),
    headers: { apikey: SB_SERVICE, Authorization: `Bearer ${SB_SERVICE}`, "Content-Type": "application/json", Prefer: "return=representation" } });
  const dj = d.ok ? await d.json() : [];
  if (!dj.length) return cevap(200, { success: true, zaten: true });

  const gonder = await fetch("https://api.resend.com/emails", { method: "POST",
    headers: { Authorization: `Bearer ${RESEND_KEY}`, "content-type": "application/json" },
    body: JSON.stringify({ from: RESEND_FROM, to: [s.email], subject: m.konu, text: m.metin, html: m.html, reply_to: "destek@tetikte.com" }) });
  if (!gonder.ok) {
    // gönderilemedi: damgayı geri al ki yeniden denenebilsin
    await sb(`siparisler?id=eq.${s.id}`, { method: "PATCH", body: JSON.stringify({ [damga]: null }) });
    console.log(`siparis-bildirim ${no} ${tur} RESEND ${gonder.status}`);
    return cevap(502, { hata: "mail gonderilemedi" });
  }
  console.log(`siparis-bildirim ${no} ${tur} gonderildi`);
  return cevap(200, { success: true, gonderildi: true });
});
