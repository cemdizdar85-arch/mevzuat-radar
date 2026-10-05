// ============================================================================
//  ELCI-SOZLESME Edge Function (Supabase) — elçi sözleşmeyi panelde onaylayınca,
//  ONAYLANAN SÜRÜMÜN PDF'ini elçinin kendi e-postasına gönderir.
//
//  NEDEN (01.10.2026, Cem "hepsini yap"): sözleşme Madde 4.2 "onaylanan sürümün PDF kopyası onay anında
//  Elçinin e-posta adresine gönderilir" der. Tıklama kaydı yalnız bizim veritabanımızda kalırsa güçlü
//  delil değil (HMK m.199, 202/2: delil başlangıcı, karşı taraftan çıkan belge). Elçinin kendi e-postasına
//  giden, PDF'in SHA-256 özetini taşıyan kopya + kayıt delili güçlendirir (Masaüstü/Tetikte-Hukuk/sozlesme-gizli-riskler.md §3).
//
//  SPAM KAPISI OLMASIN DİYE:
//    - Yalnız GİRİŞ YAPMIŞ ve elçi kaydına BAĞLI kullanıcı (JWT → auth/v1/user → elciler.user_id).
//    - Alıcı adresi tarayıcıdan GELMEZ: hesabın kendi e-postası (auth) kullanılır.
//    - Mail içeriği tamamen sunucuda kurulur; tarayıcıdan yalnız sürüm etiketi gelir ve kayıttaki
//      onaylı sürümle AYNI olmak zorundadır.
//    - Aynı elçiye aynı sürüm BİR KEZ gider (elciler.sozlesme_eposta_surum).
//  PDF: https://tetikte.com/elci-sozlesmesi-<SÜRÜM>.pdf (sürümlü kopya, depoda; içeriği sonradan değişmez).
//  SQL: radar-app/sql/2026-10-01-elci-sozlesme-kaydi.sql (3 kolon). Basılmadan fonksiyon 503 döner.
//  API: POST {surum:"YYYY-AA-GG"}  (Authorization: Bearer <kullanıcı JWT>, supabase-js functions.invoke)
//       -> 200 {success:true, gonderildi:bool, zaten:bool}
//  YAYIN: Supabase panel → Edge Functions → yeni fonksiyon "elci-sozlesme" → bu dosya.
//         Secrets karne-gonder ile ORTAK (RESEND_KEY, RESEND_FROM; SUPABASE_* otomatik). İsteğe bağlı ELCI_KOPYA (gizli kopya adresi).
// ============================================================================

export const IZINLI_KOKEN = new Set(["https://tetikte.com", "https://www.tetikte.com"]);
const YEREL_KOKEN = /^http:\/\/(localhost|127\.0\.0\.1)(:\d{1,5})?$/;
export function kokenIzinli(o: string | null): boolean { return !!o && (IZINLI_KOKEN.has(o) || YEREL_KOKEN.test(o)); }
export function surumGecerli(s: unknown): s is string { return typeof s === "string" && /^20\d{2}-[01]\d-[0-3]\d$/.test(s); }
function kacis(s: string): string { return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;"); }

export function mailKur(p: { ad: string; kod: string; surum: string; onay: string; ozet: string; site: string }) {
  const onayTr = new Date(p.onay).toLocaleString("tr-TR", { timeZone: "Europe/Istanbul" });
  const konu = `Tetikte Elçi Sözleşmesi — onayladığın sürüm (${p.surum})`;
  const metin = [
    `Merhaba ${p.ad},`,
    ``,
    `Tetikte Elçi Programı Katılım Sözleşmesi'ni elçi panelinde onayladın. Onayladığın metnin PDF kopyası ektedir.`,
    ``,
    `Elçi kodu: ${p.kod}`,
    `Sözleşme sürümü: ${p.surum}`,
    `Onay zamanı: ${onayTr} (Türkiye saati)`,
    `PDF SHA-256 özeti: ${p.ozet}`,
    ``,
    `Bu e-postayı saklamanı öneririz. Aynı metin: ${p.site}/elci-sozlesmesi-${p.surum}.pdf`,
    `Kişisel verilerin: ${p.site}/elci-aydinlatma.html`,
    `Sorun ya da itiraz için bu e-postayı yanıtlayabilir ya da destek@tetikte.com adresine yazabilirsin.`,
    ``,
    `Tetikte · Dizdar Denetim Danışmanlık ve Yazılım A.Ş.`,
  ].join("\n");
  const html = `<div style="font-family:system-ui,-apple-system,Segoe UI,sans-serif;font-size:15px;line-height:1.55;color:#16191d;max-width:560px"><img src="https://tetikte.com/gorsel/logo-mail.png" width="137" height="40" alt="tetikte" style="display:block;border:0;outline:none;margin:0 0 16px">
<p style="font-size:12px;letter-spacing:.12em;text-transform:uppercase;color:#8d6c38;font-weight:700;margin:0 0 6px">Tetikte · Elçi Programı</p>
<p>Merhaba ${kacis(p.ad)},</p>
<p>Tetikte Elçi Programı Katılım Sözleşmesi'ni elçi panelinde onayladın. <b>Onayladığın metnin PDF kopyası ektedir.</b></p>
<table style="border-collapse:collapse;margin:0 0 14px;font-size:14px">
<tr><td style="padding:4px 12px 4px 0;color:#6b7280">Elçi kodu</td><td><b>${kacis(p.kod)}</b></td></tr>
<tr><td style="padding:4px 12px 4px 0;color:#6b7280">Sözleşme sürümü</td><td>${kacis(p.surum)}</td></tr>
<tr><td style="padding:4px 12px 4px 0;color:#6b7280">Onay zamanı</td><td>${kacis(onayTr)} (Türkiye saati)</td></tr>
<tr><td style="padding:4px 12px 4px 0;color:#6b7280">PDF SHA-256</td><td style="font-family:monospace;font-size:12px;word-break:break-all">${kacis(p.ozet)}</td></tr>
</table>
<p style="font-size:13.5px;color:#4b5563">Bu e-postayı saklamanı öneririz. Aynı metin: <a href="${p.site}/elci-sozlesmesi-${p.surum}.pdf" style="color:#8d6c38">elci-sozlesmesi-${kacis(p.surum)}.pdf</a> · <a href="${p.site}/elci-aydinlatma.html" style="color:#8d6c38">Elçi Aydınlatma Metni</a></p>
<p style="font-size:13.5px;color:#4b5563">Sorun ya da itiraz için bu e-postayı yanıtlayabilir ya da destek@tetikte.com adresine yazabilirsin.</p>
<p style="font-size:12px;color:#9ca3af;margin:0">Tetikte · Dizdar Denetim Danışmanlık ve Yazılım A.Ş.</p>
</div>`;
  return { konu, metin, html };
}

// ---------------------------------------------------------------------------
const Deno: any = (globalThis as any).Deno;
// Kod imzası: arac/edge-imza.js --yaz yazar, ELLE DEĞİŞTİRME.
const KOD_IMZA = "b8eedfedc348104b";

if (Deno && Deno.serve) {
  const SB_URL = (Deno.env.get("SUPABASE_URL") ?? "https://bjrleanjpyujtajmazxn.supabase.co").replace(/\/$/, "");
  const SB_SERVICE = (Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "").trim();
  const SB_ANON = (Deno.env.get("SUPABASE_ANON_KEY") ?? "").trim();
  const RESEND_KEY = (Deno.env.get("RESEND_KEY") ?? "").trim();
  const RESEND_FROM = (Deno.env.get("RESEND_FROM") ?? "Tetikte <bildirim@tetikte.com>").trim();
  const KOPYA = (Deno.env.get("ELCI_KOPYA") ?? "").trim();
  const SITE = "https://tetikte.com";

  const cors = (origin: string | null) => ({
    "Access-Control-Allow-Origin": kokenIzinli(origin) ? (origin as string) : "https://tetikte.com",
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, accept",
    "Access-Control-Allow-Methods": "POST, OPTIONS", "Vary": "Origin", "Content-Type": "application/json; charset=utf-8",
  });
  const cevap = (d: number, g: unknown, o: string | null) => new Response(JSON.stringify(g), { status: d, headers: cors(o) });
  const servis = { apikey: SB_SERVICE, Authorization: `Bearer ${SB_SERVICE}` };

  Deno.serve(async (req: Request) => {
    const origin = req.headers.get("origin");
    if (req.method === "OPTIONS") return new Response(null, { status: 204, headers: cors(origin) });
    if (new URL(req.url).searchParams.get("surum") === "1") return new Response(JSON.stringify({ surum: KOD_IMZA }), { status: 200, headers: { "Content-Type": "application/json; charset=utf-8", "Access-Control-Allow-Origin": "*" } });
    if (new URL(req.url).searchParams.get("tani") === "1") {
      return cevap(200, { tani: true, secret_tanimli: { RESEND_KEY: !!RESEND_KEY, RESEND_FROM: !!Deno.env.get("RESEND_FROM"), SERVICE_ROLE: !!SB_SERVICE, ANON: !!SB_ANON, ELCI_KOPYA: !!KOPYA } }, origin);
    }
    if (req.method !== "POST") return cevap(405, { success: false, hata: "yalniz POST" }, origin);
    if (!kokenIzinli(origin)) return cevap(403, { success: false, hata: "koken izinli degil" }, origin);
    if (!SB_SERVICE || !SB_ANON || !RESEND_KEY) return cevap(503, { success: false, hata: "sunucu ayari eksik" }, origin);
    const ham = await req.text();
    if (ham.length > 512) return cevap(413, { success: false, hata: "govde cok buyuk" }, origin);
    let veri: any; try { veri = JSON.parse(ham); } catch { return cevap(400, { success: false, hata: "json degil" }, origin); }
    if (!surumGecerli(veri?.surum)) return cevap(400, { success: false, hata: "surum gecersiz" }, origin);

    // 1) Kim? Kullanıcının kendi JWT'si ile auth/v1/user
    const jwt = (req.headers.get("authorization") || "").replace(/^Bearer\s+/i, "");
    if (!jwt || jwt === SB_ANON) return cevap(401, { success: false, hata: "giris gerekli" }, origin);
    const u = await fetch(`${SB_URL}/auth/v1/user`, { headers: { apikey: SB_ANON, Authorization: `Bearer ${jwt}` } });
    if (!u.ok) return cevap(401, { success: false, hata: "giris gecersiz" }, origin);
    const kullanici = await u.json();
    const uid = String(kullanici?.id || ""), eposta = String(kullanici?.email || "").trim();
    if (!/^[0-9a-f-]{36}$/.test(uid) || !eposta) return cevap(401, { success: false, hata: "hesap okunamadi" }, origin);

    // 2) Elçi kaydı (servis anahtarı; tablo anonime kapalı)
    const er = await fetch(`${SB_URL}/rest/v1/elciler?select=kod,ad_soyad,sozlesme_onay,sozlesme_surum,sozlesme_eposta_surum&user_id=eq.${uid}`, { headers: servis });
    if (!er.ok) return cevap(503, { success: false, hata: "kayit okunamadi (SQL basildi mi?)" }, origin);
    const satir = (await er.json())[0];
    if (!satir) return cevap(403, { success: false, hata: "elci kaydi yok" }, origin);
    if (!satir.sozlesme_onay || satir.sozlesme_surum !== veri.surum) return cevap(409, { success: false, hata: "bu surum onaylanmamis" }, origin);
    if (satir.sozlesme_eposta_surum === veri.surum) return cevap(200, { success: true, gonderildi: false, zaten: true }, origin);

    // 3) Sürümlü PDF + özet
    const pr = await fetch(`${SITE}/elci-sozlesmesi-${veri.surum}.pdf`);
    if (!pr.ok) return cevap(502, { success: false, hata: "surumlu PDF bulunamadi" }, origin);
    const pdf = new Uint8Array(await pr.arrayBuffer());
    if (pdf.length < 1000 || pdf.length > 5_000_000 || String.fromCharCode(...pdf.slice(0, 4)) !== "%PDF") return cevap(502, { success: false, hata: "PDF gecersiz" }, origin);
    const ozet = Array.from(new Uint8Array(await crypto.subtle.digest("SHA-256", pdf))).map(b => b.toString(16).padStart(2, "0")).join("");
    let b64 = ""; for (let i = 0; i < pdf.length; i += 0x8000) b64 += String.fromCharCode(...pdf.subarray(i, i + 0x8000)); b64 = btoa(b64);

    // 4) Posta
    const m = mailKur({ ad: String(satir.ad_soyad || "").slice(0, 100), kod: satir.kod, surum: veri.surum, onay: satir.sozlesme_onay, ozet, site: SITE });
    const govde: Record<string, unknown> = { from: RESEND_FROM, to: [eposta], subject: m.konu, text: m.metin, html: m.html, reply_to: "destek@tetikte.com",
      attachments: [{ filename: `Tetikte-Elci-Sozlesmesi-${veri.surum}.pdf`, content: b64 }] };
    if (KOPYA) govde.bcc = [KOPYA];
    let postaOk = false;
    try {
      const r = await fetch("https://api.resend.com/emails", { method: "POST", headers: { Authorization: `Bearer ${RESEND_KEY}`, "content-type": "application/json" }, body: JSON.stringify(govde) });
      postaOk = r.ok;
    } catch { postaOk = false; }
    if (!postaOk) return cevap(502, { success: false, gonderildi: false, hata: "posta gonderilemedi" }, origin);

    // 5) Kayıt: aynı sürüm ikinci kez gitmesin + delil
    await fetch(`${SB_URL}/rest/v1/elciler?user_id=eq.${uid}`, { method: "PATCH",
      headers: { ...servis, "content-type": "application/json", Prefer: "return=minimal" },
      body: JSON.stringify({ sozlesme_eposta: new Date().toISOString(), sozlesme_eposta_surum: veri.surum, sozlesme_ozet: ozet }) });
    return cevap(200, { success: true, gonderildi: true, zaten: false }, origin);
  });
}
