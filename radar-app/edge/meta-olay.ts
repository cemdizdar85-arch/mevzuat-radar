// ============================================================================
//  META-OLAY Edge Function (Supabase) — Meta Conversions API köprüsü.
//
//  NEDEN VAR (29.09.2026, Cem: "dönüşüm kodları ve Instagram reklam işleri"):
//  Tarayıcı pikseli reklam engelleyicide / Safari'de kaybolur. Aynı olay
//  sunucudan da aynı event_id ile gider, Meta ikisini tekilleştirir.
//  Tarayıcı tarafı: donusum.js (yalnız ziyaretçi onay bandında "Kabul et" dediyse çağırır).
//
//  KURALLAR:
//    - Olay adı beyaz listede (STANDART); serbest ad kabul edilmez.
//    - Köken listesi (tetikte.com + yerel geliştirme). IP başına 10 dk'da 60 (rate_limit_check).
//    - E-posta AÇIK METİN KABUL EDİLMEZ: yalnız 64 haneli SHA-256 özeti (tarayıcıda alınır).
//    - IP ve tarayıcı kimliği Meta'ya eşleştirme için iletilir, BİZDE SAKLANMAZ (tabloya yazılmaz).
//    - Değer yalnız sayı, para birimi yalnız TRY.
//
//  API: POST {olay, event_id, url, fbp?, fbc?, em?, value?, currency?, content_name?}
//       -> 200 {success:true, meta:bool}
//  TEŞHİS: ?tani=1 -> secret tanımlı mı (değer DÖNMEZ). ?surum=1 -> KOD_IMZA.
//  YAYIN: Supabase panel -> Edge Functions -> yeni fonksiyon "meta-olay" -> bu dosya,
//         "Verify JWT" KAPALI (tarayıcı yayımlanabilir anahtarla çağırır).
//         Secrets: META_PIXEL_ID, META_CAPI_TOKEN (Events Manager -> Ayarlar ->
//         Conversions API -> "Erişim belirteci oluştur"), isteğe bağlı META_TEST_KODU
//         (Test Events ekranındaki TEST12345 kodu — canlıya geçerken SİL).
//  Graph sürümü: v26.0 (developers.facebook.com/docs/graph-api/changelog, 29.09.2026 okundu).
// ============================================================================

export const KOD_IMZA = "meta-olay 2026-09-29";
export const GRAPH_SURUM = "v26.0";
export const STANDART = new Set(["PageView", "ViewContent", "Lead", "CompleteRegistration", "InitiateCheckout", "AddPaymentInfo", "Purchase", "Subscribe"]);
export const IZINLI_KOKEN = new Set(["https://tetikte.com", "https://www.tetikte.com"]);
const YEREL_KOKEN = /^http:\/\/(localhost|127\.0\.0\.1)(:\d{1,5})?$/;
export function kokenIzinli(o: string | null): boolean { return !!o && (IZINLI_KOKEN.has(o) || YEREL_KOKEN.test(o)); }

const kisa = (v: unknown, n: number) => (typeof v === "string" && v.length <= n) ? v : "";

export type Olay = { olay: string; event_id: string; url: string; fbp: string; fbc: string; em: string;
  value?: number; currency?: string; content_name: string };

export function dogrula(g: any): { ok: true; olay: Olay } | { ok: false; neden: string } {
  g = g ?? {};
  if (!STANDART.has(g.olay)) return { ok: false, neden: "olay adi gecersiz" };
  const event_id = kisa(g.event_id, 64);
  if (!/^[A-Za-z0-9-]{8,64}$/.test(event_id)) return { ok: false, neden: "event_id gecersiz" };
  const url = kisa(g.url, 2000);
  let host = "";
  try { host = new URL(url).hostname; } catch { return { ok: false, neden: "url gecersiz" }; }
  if (!/^(www\.)?tetikte\.com$|^localhost$|^127\.0\.0\.1$/.test(host)) return { ok: false, neden: "url tetikte degil" };
  const em = kisa(g.em, 64);
  if (em && !/^[0-9a-f]{64}$/.test(em)) return { ok: false, neden: "em yalniz sha256 ozeti olabilir" };
  const fbp = kisa(g.fbp, 200), fbc = kisa(g.fbc, 500);
  const content_name = /^[a-z0-9-]{0,40}$/.test(kisa(g.content_name, 40)) ? kisa(g.content_name, 40) : "";
  const o: Olay = { olay: g.olay, event_id, url, fbp, fbc, em, content_name };
  if (g.value !== undefined && g.value !== null) {
    if (typeof g.value !== "number" || !isFinite(g.value) || g.value < 0 || g.value > 1_000_000) return { ok: false, neden: "value gecersiz" };
    if (g.currency !== "TRY") return { ok: false, neden: "currency yalniz TRY" };
    o.value = g.value; o.currency = "TRY";
  }
  return { ok: true, olay: o };
}

export function metaGovde(o: Olay, ip: string, ua: string, testKodu: string) {
  const user_data: Record<string, unknown> = {};
  if (ip) user_data.client_ip_address = ip;
  if (ua) user_data.client_user_agent = ua;
  if (o.fbp) user_data.fbp = o.fbp;
  if (o.fbc) user_data.fbc = o.fbc;
  if (o.em) user_data.em = [o.em];
  const custom_data: Record<string, unknown> = {};
  if (o.content_name) custom_data.content_name = o.content_name;
  if (o.value !== undefined) { custom_data.value = o.value; custom_data.currency = o.currency; }
  const govde: Record<string, unknown> = { data: [{ event_name: o.olay, event_time: Math.floor(Date.now() / 1000),
    event_id: o.event_id, action_source: "website", event_source_url: o.url, user_data, custom_data }] };
  if (testKodu) govde.test_event_code = testKodu;
  return govde;
}

if (typeof Deno !== "undefined" && Deno.serve) {
  const SB_URL = (Deno.env.get("SUPABASE_URL") ?? "https://bjrleanjpyujtajmazxn.supabase.co").replace(/\/$/, "");
  const SB_ANON = (Deno.env.get("SUPABASE_ANON_KEY") ?? "").trim();
  const PIKSEL = (Deno.env.get("META_PIXEL_ID") ?? "").trim();
  const TOKEN = (Deno.env.get("META_CAPI_TOKEN") ?? "").trim();
  const TEST = (Deno.env.get("META_TEST_KODU") ?? "").trim();

  const cors = (origin: string | null) => ({
    "Access-Control-Allow-Origin": kokenIzinli(origin) ? (origin as string) : "https://tetikte.com",
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, accept",
    "Access-Control-Allow-Methods": "POST, OPTIONS", "Vary": "Origin", "Content-Type": "application/json; charset=utf-8",
  });
  const cevap = (d: number, g: unknown, o: string | null) => new Response(JSON.stringify(g), { status: d, headers: cors(o) });

  const hizAsti = async (ip: string): Promise<boolean> => {
    if (!ip || ip === "anon" || !SB_ANON) return false;
    try {
      const r = await fetch(`${SB_URL}/rest/v1/rpc/rate_limit_check`, { method: "POST",
        headers: { "content-type": "application/json", apikey: SB_ANON, Authorization: `Bearer ${SB_ANON}` },
        // 'meta:' öneki ŞART: rate_log IP başına tek sayaç; öneksiz olsaydı sayfa görüntülemeleri
        // form-al/karne-gonder'in 5'lik sınırını tüketir, ziyaretçi e-posta bırakamazdı.
        body: JSON.stringify({ p_ip: "meta:" + ip, p_limit: 60, p_pencere_sn: 600 }) });
      if (!r.ok) return false;
      return (await r.json()) === false;
    } catch { return false; }
  };

  Deno.serve(async (req) => {
    const origin = req.headers.get("origin");
    if (req.method === "OPTIONS") return new Response(null, { status: 204, headers: cors(origin) });
    const q = new URL(req.url).searchParams;
    if (q.get("surum") === "1") return new Response(JSON.stringify({ surum: KOD_IMZA }), { status: 200, headers: { "Content-Type": "application/json; charset=utf-8", "Access-Control-Allow-Origin": "*" } });
    if (q.get("tani") === "1") return cevap(200, { tani: true, secret_tanimli: { META_PIXEL_ID: !!PIKSEL, META_CAPI_TOKEN: !!TOKEN, META_TEST_KODU: !!TEST, ANON: !!SB_ANON } }, origin);
    if (req.method !== "POST") return cevap(405, { success: false, hata: "yalniz POST" }, origin);
    if (!kokenIzinli(origin)) return cevap(403, { success: false, hata: "koken" }, origin);

    let g: unknown;
    try { g = await req.json(); } catch { return cevap(400, { success: false, hata: "json" }, origin); }
    const d = dogrula(g);
    if (!d.ok) return cevap(400, { success: false, hata: d.neden }, origin);

    const ip = (req.headers.get("x-forwarded-for") || "").split(",")[0].trim();
    if (await hizAsti(ip || "anon")) return cevap(429, { success: false, hata: "cok sik" }, origin);
    if (!PIKSEL || !TOKEN) return cevap(200, { success: true, meta: false }, origin);   // kurulmadıysa sessizce geç

    try {
      const r = await fetch(`https://graph.facebook.com/${GRAPH_SURUM}/${PIKSEL}/events?access_token=${encodeURIComponent(TOKEN)}`, {
        method: "POST", headers: { "content-type": "application/json" },
        body: JSON.stringify(metaGovde(d.olay, ip, (req.headers.get("user-agent") || "").slice(0, 500), TEST)) });
      if (!r.ok) console.error("meta-olay graph", r.status, (await r.text()).slice(0, 300));
      return cevap(200, { success: true, meta: r.ok }, origin);
    } catch (e) {
      console.error("meta-olay ag", String(e).slice(0, 200));
      return cevap(200, { success: true, meta: false }, origin);
    }
  });
}
