// iyzico-odeme — KART ÖDEMESİ (05.10.2026, Cem "iyzico onay geldi")
// AŞAMA 1 (bu sürüm): yalnız SAĞLIK KONTROLÜ. Ödeme başlatma/dönüş sonraki sürümde eklenecek.
//   ?surum=1   → kod imzası + hangi anahtar ADLARI tanımlı (değer ASLA dönmez)
//   ?saglik=1  → anahtarlarla iyzico'ya PARA ÇEKMEYEN bir sorgu (taksit bilgisi, BIN) atar; gerçek ve test
//                uçlarının hangisinin anahtarı kabul ettiğini söyler. Yalnız servis anahtarıyla çağrılır
//                (Authorization: Bearer <service key>; PostgREST'te kapalı tabloyu okuyabiliyorsa servis sayılır).
// ⛔ Anahtar değeri, imza, yetki başlığı hiçbir cevapta ve günlükte yer almaz.
// iyzico yetkilendirme: IYZWSv2 — imza = HMAC-SHA256(gizli anahtar, rastgele + uri yolu + gövde) hex;
//   yetki = "IYZWSv2 " + base64("apiKey:<api>&randomKey:<rnd>&signature:<imza>"), x-iyzi-rnd başlığı.
// 🚫 GÖRMEZ: anahtarın ödeme yetkisinin açık olup olmadığı (taksit sorgusu yalnız kimliği doğrular).

const KOD_IMZA = "cce445476503e410";
const SB_URL = (Deno.env.get("SUPABASE_URL") ?? "https://bjrleanjpyujtajmazxn.supabase.co").replace(/\/$/, "");
const UC = { canli: "https://api.iyzipay.com", test: "https://sandbox-api.iyzipay.com" };

function cevap(kod: number, govde: unknown) {
  return new Response(JSON.stringify(govde), { status: kod, headers: { "Content-Type": "application/json; charset=utf-8", "Access-Control-Allow-Origin": "*" } });
}
function anahtar(ad: string) { return (Deno.env.get(ad) ?? "").trim(); }
const hex = (b: ArrayBuffer) => [...new Uint8Array(b)].map((x) => x.toString(16).padStart(2, "0")).join("");

async function iyzicoCagir(taban: string, api: string, gizli: string, yol: string, govde: Record<string, unknown>) {
  const metin = JSON.stringify(govde);
  const rnd = crypto.randomUUID().replace(/-/g, "");
  const k = await crypto.subtle.importKey("raw", new TextEncoder().encode(gizli), { name: "HMAC", hash: "SHA-256" }, false, ["sign"]);
  const imza = hex(await crypto.subtle.sign("HMAC", k, new TextEncoder().encode(rnd + yol + metin)));
  const yetki = "IYZWSv2 " + btoa(`apiKey:${api}&randomKey:${rnd}&signature:${imza}`);
  const r = await fetch(taban + yol, { method: "POST", headers: { "Content-Type": "application/json", "Authorization": yetki, "x-iyzi-rnd": rnd }, body: metin });
  let j: Record<string, unknown> = {};
  try { j = await r.json(); } catch { /* boş */ }
  return { http: r.status, status: j.status ?? null, errorCode: j.errorCode ?? null, errorMessage: j.errorMessage ?? null };
}

async function servisMi(req: Request) {
  const t = (req.headers.get("Authorization") ?? "").replace(/^Bearer\s+/i, "").trim();
  if (!t) return false;
  const r = await fetch(`${SB_URL}/rest/v1/yoneticiler?select=eposta&limit=1`, { headers: { apikey: t, Authorization: `Bearer ${t}` } });
  return r.status === 200;
}

Deno.serve(async (req) => {
  const u = new URL(req.url);
  const ad = { api: !!anahtar("IYZICO_API_KEY"), gizli: !!anahtar("IYZICO_SECRET_KEY"), testApi: !!anahtar("IYZICO_TEST_API_KEY"), testGizli: !!anahtar("IYZICO_TEST_SECRET_KEY") };
  if (u.searchParams.get("surum") === "1") return cevap(200, { surum: KOD_IMZA, secret: ad });
  if (u.searchParams.get("saglik") === "1") {
    if (!(await servisMi(req))) return cevap(403, { hata: "yetki yok" });
    const sorgu = { locale: "tr", conversationId: "saglik-" + Date.now(), binNumber: "554960", price: "100.0" };
    const sonuc: Record<string, unknown> = {};
    for (const [cift, api, gizli] of [["ana", anahtar("IYZICO_API_KEY"), anahtar("IYZICO_SECRET_KEY")], ["test", anahtar("IYZICO_TEST_API_KEY"), anahtar("IYZICO_TEST_SECRET_KEY")]] as const) {
      if (!api || !gizli) { sonuc[cift] = "tanimli degil"; continue; }
      const o: Record<string, unknown> = {};
      for (const [uc, taban] of Object.entries(UC)) {
        try { o[uc] = await iyzicoCagir(taban, api, gizli, "/payment/iyzipos/installment", sorgu); } catch (e) { o[uc] = { hata: String((e as Error).message).slice(0, 120) }; }
      }
      sonuc[cift] = o;
    }
    return cevap(200, { anahtar: ad, sonuc });
  }
  return cevap(404, { hata: "bu surumde yalniz ?surum=1 ve ?saglik=1 var" });
});
