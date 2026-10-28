// ============================================================================
//  MARKA-NOBET Edge Function — marka nöbeti e-posta onayı (28.10.2026; Cem → "marka nöbetine e-posta onayı")
//
//  NEDEN: nöbet sayfadan doğrudan açılıyordu (marka_takip_ac, anon) — çift onay yoktu: herkes başkasının adresine nöbet
//  açıp robotun uyarı maillerini yağdırabilirdi; aynı marka+adresle yeniden kayıt, nöbetin yönetim jetonunu sayfaya veriyordu.
//  AKIŞ: marka-itiraz.html → POST {ad, sinif, eposta} → hız sınırı (IP başına 10 dk'da 5) → marka_takip_ac2 (servis) →
//        ONAY_GONDER ise kurumsal kabuklu onay maili (bağlantı 48 saat, tek kullanımlık) → sayfaya YALNIZ durum döner.
//        Bağlantı marka-itiraz.html?nobet=onay&j=… → sayfa marka_takip_onayla(p_onay) çağırır (anon; 48 haneli jeton şart).
//  KİŞİ VERİSİ: e-posta günlüğe ve cevaba yazılmaz; günlükte yalnız durum + Resend kodu.
//  PROVA (servis anahtarıyla): POST {mod:'prova', alici} → örnek onay maili ("[PROVA]", sahte bağlantı, veritabanına yazmaz),
//        Resend'den teslim durumu 15 sn boyunca sorulur → {gonderim_ms, ilk_durum, teslim_ms, son_durum}. Teslim = alıcı
//        sunucusunun kabulü; KUTUYA düştüğü ayrıca insan gözüyle ölçülür.
//  🚫 GÖRMEZ: maili spam klasörüne düşüren alıcı süzgeci · aynı kişinin farklı adresleri.
//  YAYIN: .github/workflows/edge-yukle.yml OTOMATİK (YAYIN.json, jwt:false — tarayıcıdan anonim gelir). Secrets: RESEND_KEY, RESEND_FROM.
// ============================================================================

const KOD_IMZA = "5f53b459cb60ca53";
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

const NEDEN = "Bu e-posta, tetikte.com'da bu adres için marka nöbeti kurma isteği yapıldığı için bir kez gönderilmiştir.";

export function onayMail(ad: string, sinif: number[], onay: string, prova = false) {
  const bag = `${SITE}/marka-itiraz.html?nobet=onay&j=${encodeURIComponent(onay)}`;
  const sn = sinif && sinif.length ? ` (Nice sınıfı ${sinif.join(", ")})` : "";
  const konu = `${prova ? "[PROVA] " : ""}Marka nöbetini onayla: ${ad}`;
  const metin = [
    "Merhaba,", "",
    `tetikte.com'da "${ad}"${sn} markası için nöbet kurma isteği aldık. Nöbet, onayladığında başlar:`,
    bag, "",
    "Bağlantı 48 saat geçerlidir ve bir kez kullanılabilir.",
    "Bu isteği sen yapmadıysan bu e-postayı yok say: onaylanmayan nöbet açılmaz, bu adrese başka e-posta gelmez.", "",
    "Sınava tetikte gir.",
  ].join("\n");
  const html = kurumsalMail(`${prova ? '<p style="background:#fff7e6;border:1px solid #f3a52a;border-radius:8px;padding:8px 12px;font-size:13px"><b>PROVA:</b> görünüm ve teslim süresi ölçümü; bağlantı çalışmaz.</p>' : ""}
<p>Merhaba,</p>
<p>tetikte.com'da <b>${kacis(ad)}</b>${kacis(sn)} markası için <b>nöbet kurma isteği</b> aldık. Nöbet, onayladığında başlar; sonra her yeni Resmî Marka Bülteni'nde benzeyen bir başvuru çıkarsa sana yazarız.</p>
<p><a href="${bag}" style="display:inline-block;background:#f3a52a;color:#0f1b2d;font-weight:700;padding:11px 20px;border-radius:9px;text-decoration:none">Nöbeti onayla</a></p>
<p style="font-size:13px;color:#4b5563">Bağlantı <b>48 saat</b> geçerlidir ve <b>bir kez</b> kullanılabilir.</p>
<p style="font-size:13px;color:#4b5563">Bu isteği sen yapmadıysan bu e-postayı yok say: onaylanmayan nöbet açılmaz, bu adrese başka e-posta gelmez.</p>`, NEDEN);
  return { konu, metin, html };
}

const KOKENLER = ["https://tetikte.com", "https://www.tetikte.com"];
const kokenIzinli = (o: string | null) => !!o && (KOKENLER.includes(o) || /^http:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/.test(o));

if (typeof Deno !== "undefined" && Deno.serve) Deno.serve(async (req: Request) => {
  const SB_URL = (Deno.env.get("SUPABASE_URL") ?? "https://bjrleanjpyujtajmazxn.supabase.co").replace(/\/$/, "");
  const SB_SERVICE = (Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "").trim();
  const RESEND_KEY = (Deno.env.get("RESEND_KEY") ?? "").trim();
  const RESEND_FROM = (Deno.env.get("RESEND_FROM") ?? "Tetikte <bildirim@tetikte.com>").trim();
  const origin = req.headers.get("origin");
  const H = { "Content-Type": "application/json; charset=utf-8", "Access-Control-Allow-Origin": kokenIzinli(origin) ? origin as string : SITE,
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type", "Access-Control-Allow-Methods": "POST, OPTIONS", "Vary": "Origin" };
  const cevap = (k: number, g: unknown) => new Response(JSON.stringify(g), { status: k, headers: H });
  if (req.method === "OPTIONS") return new Response(null, { status: 204, headers: H });
  const q = new URL(req.url).searchParams;
  if (q.get("surum") === "1") return cevap(200, { surum: KOD_IMZA, secret: { RESEND_KEY: !!RESEND_KEY, SERVICE: !!SB_SERVICE } });
  const sbH = { apikey: SB_SERVICE, Authorization: `Bearer ${SB_SERVICE}`, "content-type": "application/json" };
  const hiz = async (anahtar: string, limit: number) => {
    const r = await fetch(`${SB_URL}/rest/v1/rpc/rate_limit_check`, { method: "POST", headers: sbH, body: JSON.stringify({ p_ip: anahtar, p_limit: limit, p_pencere_sn: 600 }) }).catch(() => null);
    return r;
  };
  if (q.get("tani") === "hiz") { const r = await hiz("tani:" + crypto.randomUUID(), 1000); return cevap(200, { hiz: r ? r.status : 0 }); }
  if (req.method !== "POST") return cevap(405, { hata: "yalniz POST" });
  if (!SB_SERVICE || !RESEND_KEY) return cevap(503, { hata: "kurulum eksik" });

  let g: { ad?: string; sinif?: number[]; eposta?: string; mod?: string; alici?: string } = {};
  try { g = await req.json(); } catch { return cevap(400, { hata: "gecersiz istek" }); }
  const resend = (m: Record<string, unknown>) => fetch("https://api.resend.com/emails", { method: "POST",
    headers: { Authorization: `Bearer ${RESEND_KEY}`, "content-type": "application/json" }, body: JSON.stringify(m) });

  // PROVA: yalnız servis anahtarıyla (auth admin ucunu okuyabilen anahtar)
  if (g.mod === "prova") {
    const anahtar = (req.headers.get("authorization") || "").replace(/^Bearer\s+/i, "").trim();
    const y = anahtar ? await fetch(`${SB_URL}/auth/v1/admin/users?page=1&per_page=1`, { headers: { apikey: anahtar, Authorization: `Bearer ${anahtar}` } }).catch(() => null) : null;
    if (!y || !y.ok) return cevap(403, { hata: "yetki yok" });
    const alici = String(g.alici || "").trim();
    if (!/^[^@\s]{1,64}@[^@\s]{1,190}\.[a-z]{2,}$/i.test(alici)) return cevap(400, { hata: "alici gecersiz" });
    const m = onayMail("TETİKTE", [9, 41], "0".repeat(48), true);
    const t0 = Date.now();
    const s = await resend({ from: RESEND_FROM, to: [alici], subject: m.konu, text: m.metin, html: m.html, reply_to: "destek@tetikte.com" });
    const gonderimMs = Date.now() - t0;
    const sj = await s.json().catch(() => ({}));
    if (!s.ok || !sj.id) return cevap(502, { hata: "gonderilemedi", durum: s.status });
    let ilk = "", son = "", teslimMs: number | null = null;
    for (let i = 0; i < 30; i++) {
      await new Promise((r) => setTimeout(r, 500));
      const d = await fetch(`https://api.resend.com/emails/${sj.id}`, { headers: { Authorization: `Bearer ${RESEND_KEY}` } }).catch(() => null);
      const dj = d && d.ok ? await d.json().catch(() => ({})) : {};
      son = String(dj.last_event || ""); if (!ilk && son) ilk = son;
      if (son === "delivered" || son === "bounced" || son === "complained") { if (son === "delivered") teslimMs = Date.now() - t0; break; }
    }
    console.log(`marka-nobet prova RESEND ${s.status} son=${son} teslim_ms=${teslimMs}`);
    return cevap(200, { success: true, gonderim_ms: gonderimMs, ilk_durum: ilk, son_durum: son, teslim_ms: teslimMs });
  }

  // NÖBET İSTEĞİ (tarayıcıdan)
  const ip = (req.headers.get("x-forwarded-for") || "").split(",")[0].trim();
  if (!ip) return cevap(400, { hata: "istek okunamadi" });
  const rl = await hiz("marka-nobet:" + ip, 5);
  if (!rl || !rl.ok) return cevap(503, { hata: "gecici sorun, biraz sonra tekrar dene" });   // sayaç yoksa mail atmayız (kötüye kullanım kapısı)
  if ((await rl.json()) === false) return cevap(429, { hata: "cok sik istek - 10 dakika sonra tekrar dene" });
  const ad = String(g.ad || "").trim().slice(0, 120);
  const sinif = Array.isArray(g.sinif) ? g.sinif.map(Number).filter((n) => Number.isInteger(n) && n >= 1 && n <= 45).slice(0, 45) : [];
  const eposta = String(g.eposta || "").trim().slice(0, 254);
  const a = await fetch(`${SB_URL}/rest/v1/rpc/marka_takip_ac2`, { method: "POST", headers: sbH,
    body: JSON.stringify({ p_ad: ad, p_sinif: sinif.length ? sinif : null, p_eposta: eposta }) }).catch(() => null);
  if (!a || !a.ok) { console.log(`marka-nobet ac2 HTTP ${a ? a.status : 0}`); return cevap(502, { hata: "kayit acilamadi" }); }
  const k = await a.json();
  if (k.durum !== "ONAY_GONDER") { console.log(`marka-nobet durum ${k.durum}`); return cevap(200, { durum: k.durum, ad: k.ad || ad }); }
  const m = onayMail(String(k.ad || ad), (k.sinif || []) as number[], String(k.onay));
  const s = await resend({ from: RESEND_FROM, to: [eposta], subject: m.konu, text: m.metin, html: m.html, reply_to: "destek@tetikte.com" });
  console.log(`marka-nobet onay RESEND ${s.status}`);
  if (!s.ok) {
    // mail gitmedi: 10 dk bekleme damgasını sil ki kullanıcı hemen yeniden deneyebilsin
    await fetch(`${SB_URL}/rest/v1/marka_takip?onay_jeton=eq.${encodeURIComponent(String(k.onay))}`, { method: "PATCH", headers: sbH, body: JSON.stringify({ onay_gonderim: null }) }).catch(() => null);
    return cevap(502, { hata: "onay e-postasi gonderilemedi, tekrar dene" });
  }
  return cevap(200, { durum: "ONAY_GONDERILDI", ad: k.ad });
});
