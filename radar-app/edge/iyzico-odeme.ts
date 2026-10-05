// iyzico-odeme — KART ÖDEMESİ (05.10.2026, Cem "iyzico onay geldi" + "gerçekte 5 TL'lik ödeme yapalım")
//   ?surum=1            → kod imzası + hangi anahtar ADLARI tanımlı (değer ASLA dönmez)
//   ?saglik=1           → (yalnız servis) PARA ÇEKMEYEN taksit sorgusu; anahtar canlı uçta kabul ediliyor mu
//   POST ?islem=deneme  → (yalnız YÖNETİCİ, kullanıcı JWT) 5,00 TL gerçek kart denemesi; sipariş tablosuna dokunmaz
//   POST ?islem=baslat  → {siparis_no}: ödeme bekleyen siparişin TUTARI SUNUCUDA hesaplanır (fiyat-motoru.js'in
//                          canlı kopyası + kurucu kotası + sunucunun damgaladığı elçi indirimi); siparişteki tutarla
//                          uyuşmazsa ödeme BAŞLAMAZ. iyzico ödeme sayfası adresi döner.
//   POST ?islem=donus   → iyzico'nun geri çağrısı (form: token). Sonuç iyzico'nun KENDİSİNDEN okunur (detail);
//                          durum SUCCESS + fraudStatus 1 + ödenen = kayıttaki tutar + sepet no = kayıt → başarılı.
//                          Siparişse kart_siparis_odendi (paket açılır) + "paketin açıldı" maili. 303 ile sayfaya döner.
// ⛔ Kart bilgisi bize HİÇ gelmez (iyzico sayfası). Anahtar/imza/yetki başlığı hiçbir cevapta ve günlükte yok.
// iyzico yetkisi IYZWSv2: imza = HMAC-SHA256(gizli, rastgele + uri yolu + gövde) hex;
//   "IYZWSv2 " + base64("apiKey:<api>&randomKey:<rnd>&signature:<imza>"), x-iyzi-rnd başlığı.
// 🚫 GÖRMEZ: iade (iyzico panelinden) · taksit (kapalı, enabledInstallments [1]) · KGK paketleri (satışta değil → reddedilir).

const KOD_IMZA = "4d91d2efeea1d5f6";
const SB_URL = (Deno.env.get("SUPABASE_URL") ?? "https://bjrleanjpyujtajmazxn.supabase.co").replace(/\/$/, "");
const SB_SERVICE = (Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "").trim();
const SB_ANON = "sb_publishable_kTZpYwrL7skw8Ryj5Vs8_Q_-5_Fhkcg";
const IYZ = "https://api.iyzipay.com";
const SITE = "https://tetikte.com";
const DONUS = `${SB_URL}/functions/v1/iyzico-odeme?islem=donus`;
const DENEME_TL = 5;

function cevap(kod: number, govde: unknown) {
  return new Response(kod === 204 ? null : JSON.stringify(govde), { status: kod, headers: { "Content-Type": "application/json; charset=utf-8", "Access-Control-Allow-Origin": "*", "Access-Control-Allow-Headers": "authorization, content-type, apikey" } });
}
const yonlen = (adres: string) => new Response(null, { status: 303, headers: { Location: adres } });
function anahtar(ad: string) { return (Deno.env.get(ad) ?? "").trim(); }
const hex = (b: ArrayBuffer) => [...new Uint8Array(b)].map((x) => x.toString(16).padStart(2, "0")).join("");
const para = (n: number) => (Math.round(n * 100) / 100).toFixed(2);

// deno-lint-ignore no-explicit-any
async function iyzico(yol: string, govde: Record<string, unknown>): Promise<Record<string, any>> {
  const metin = JSON.stringify(govde);
  const rnd = crypto.randomUUID().replace(/-/g, "");
  const k = await crypto.subtle.importKey("raw", new TextEncoder().encode(anahtar("IYZICO_SECRET_KEY")), { name: "HMAC", hash: "SHA-256" }, false, ["sign"]);
  const imza = hex(await crypto.subtle.sign("HMAC", k, new TextEncoder().encode(rnd + yol + metin)));
  const r = await fetch(IYZ + yol, { method: "POST", headers: { "Content-Type": "application/json", "Authorization": "IYZWSv2 " + btoa(`apiKey:${anahtar("IYZICO_API_KEY")}&randomKey:${rnd}&signature:${imza}`), "x-iyzi-rnd": rnd }, body: metin });
  let j: Record<string, unknown> = {};
  try { j = await r.json(); } catch { /* boş */ }
  return { http: r.status, ...j };
}

const sbH = { apikey: SB_SERVICE, Authorization: `Bearer ${SB_SERVICE}`, "Content-Type": "application/json" };
function sb(yol: string, sec: RequestInit = {}) { return fetch(`${SB_URL}/rest/v1/${yol}`, { ...sec, headers: { ...sbH, ...(sec.headers || {}) } }); }

async function servisMi(req: Request) {
  const t = (req.headers.get("Authorization") ?? "").replace(/^Bearer\s+/i, "").trim();
  if (!t) return false;
  const r = await fetch(`${SB_URL}/rest/v1/yoneticiler?select=*&limit=1`, { headers: { apikey: t } });
  return r.status === 200;
}
async function kullanici(req: Request) {
  const t = (req.headers.get("Authorization") ?? "").replace(/^Bearer\s+/i, "").trim();
  if (!t) return null;
  const r = await fetch(`${SB_URL}/auth/v1/user`, { headers: { apikey: SB_ANON, Authorization: `Bearer ${t}` } });
  if (!r.ok) return null;
  return await r.json() as { id: string; email: string };
}

// fiyat-motoru.js — sitenin gösterdiği fiyatın TEK kaynağı; sunucu da aynı dosyayı okur (çift kayıt yok)
async function fiyatlar() {
  const js = await (await fetch(`${SITE}/fiyat-motoru.js?_=${Date.now()}`)).text();
  const nesne = (bas: string) => {
    const i = js.indexOf(bas); if (i < 0) throw new Error("FIYAT_OKUNAMADI " + bas);
    let d = 0, j = js.indexOf("{", i);
    for (let k = j; k < js.length; k++) { if (js[k] === "{") d++; else if (js[k] === "}") { d--; if (!d) { j = k; break; } } }
    const ham = js.slice(js.indexOf("{", i), j + 1).replace(/\/\*[\s\S]*?\*\//g, "").replace(/\/\/[^\n]*/g, "")
      .replace(/([{,\[]\s*)([A-Za-z_]\w*)\s*:/g, '$1"$2":').replace(/'/g, '"');
    return JSON.parse(ham);
  };
  return { FIYAT: nesne("var FIYAT = {"), KOTA: nesne("var KOTA = {") };
}
// deno-lint-ignore no-explicit-any
function paketFiyat(F: any, paket: string) {
  if (paket === "sgs") return { f: F.sgs, sinav: "sgs" };
  const m = paket.match(/^yeterlilik-([1-4])$/); if (m) return { f: F.yeterlilik[+m[1]], sinav: "yeterlilik" };
  if (paket === "yeterlilik-tum") return { f: F.yeterlilikTum, sinav: "yeterlilik" };
  return null;
}

function alici(ad: string, eposta: string, adres: string, tckn: string, ip: string, id: string) {
  const p = (ad || "Tetikte Uye").trim().split(/\s+/); const soyad = p.length > 1 ? p.pop()! : "Uye"; const isim = p.join(" ") || "Tetikte";
  const adr = (adres || "Türkiye").slice(0, 250);
  return {
    buyer: { id, name: isim, surname: soyad, email: eposta, identityNumber: /^\d{11}$/.test(tckn) ? tckn : "11111111111", registrationAddress: adr, ip: ip || "85.34.78.112", city: "Türkiye", country: "Turkey" },
    billingAddress: { contactName: `${isim} ${soyad}`, city: "Türkiye", country: "Turkey", address: adr },
  };
}

function odemeBaslat(tutar: number, conv: string, urunAd: string, kisi: ReturnType<typeof alici>) {
  return iyzico("/payment/iyzipos/checkoutform/initialize/auth/ecom", {
    locale: "tr", conversationId: conv, price: para(tutar), paidPrice: para(tutar), currency: "TRY", basketId: conv,
    paymentGroup: "PRODUCT", callbackUrl: DONUS, enabledInstallments: [1], ...kisi,
    basketItems: [{ id: conv, name: urunAd.slice(0, 100), category1: "Dijital soru bankasi", itemType: "VIRTUAL", price: para(tutar) }],
  });
}

Deno.serve(async (req) => {
  const u = new URL(req.url);
  if (req.method === "OPTIONS") return cevap(204, null);
  const ad = { api: !!anahtar("IYZICO_API_KEY"), gizli: !!anahtar("IYZICO_SECRET_KEY"), servis: !!SB_SERVICE };
  if (u.searchParams.get("surum") === "1") return cevap(200, { surum: KOD_IMZA, secret: ad });
  if (!ad.api || !ad.gizli || !ad.servis) return cevap(503, { hata: "kurulum eksik" });
  const islem = u.searchParams.get("islem") ?? "";
  const ip = (req.headers.get("x-forwarded-for") ?? "").split(",")[0].trim();

  if (u.searchParams.get("saglik") === "1") {
    if (!(await servisMi(req))) return cevap(403, { hata: "yetki yok" });
    const r = await iyzico("/payment/iyzipos/installment", { locale: "tr", conversationId: "saglik-" + Date.now(), binNumber: "554960", price: "100.0" });
    return cevap(200, { canli: { http: r.http, status: r.status ?? null, errorCode: r.errorCode ?? null } });
  }

  // ---------------------------------------------------------------- yönetici 5 TL denemesi
  if (islem === "deneme" && req.method === "POST") {
    const k = await kullanici(req); if (!k) return cevap(401, { hata: "giris gerekli" });
    const yj = await (await sb(`yoneticiler?select=user_id&user_id=eq.${k.id}&limit=1`)).json().catch(() => []);
    if (!Array.isArray(yj) || !yj.length) return cevap(403, { hata: "yalniz yonetici" });
    const conv = "DENEME-" + Date.now();
    const r = await odemeBaslat(DENEME_TL, conv, "Tetikte kart denemesi", alici("Tetikte Deneme", k.email, "", "", ip, k.id));
    if (r.status !== "success" || !r.token) return cevap(502, { hata: "iyzico baslatmadi", errorCode: r.errorCode ?? null, errorMessage: r.errorMessage ?? null });
    await sb("kart_odemeleri", { method: "POST", body: JSON.stringify({ siparis_no: null, deneme: true, tutar: DENEME_TL, conversation_id: conv, token: r.token, baslatan: k.id }) });
    return cevap(200, { odemeSayfasi: r.paymentPageUrl });
  }

  // ---------------------------------------------------------------- sipariş ödemesi başlat
  if (islem === "baslat" && req.method === "POST") {
    const g = await req.json().catch(() => ({})) as { siparis_no?: string };
    const no = String(g.siparis_no ?? "");
    if (!/^TT-[0-9]{8}-[ACDEFHJKLMNPRTUVXYZ2345679]{4}$/.test(no)) return cevap(400, { hata: "siparis no gecersiz" });
    const s = (await (await sb(`siparisler?select=siparis_no,paket,paket_ad,tutar,indirim_tl,durum,ad_soyad,email,adres,fatura&siparis_no=eq.${encodeURIComponent(no)}&limit=1`)).json().catch(() => []))[0];
    if (!s) return cevap(404, { hata: "siparis yok" });
    if (s.durum !== "odeme_bekliyor") return cevap(409, { hata: "siparis odeme beklemiyor", durum: s.durum });
    let F; try { F = await fiyatlar(); } catch { return cevap(503, { hata: "fiyat okunamadi" }); }
    const pf = paketFiyat(F.FIYAT, s.paket); if (!pf) return cevap(400, { hata: "bu paket kartla satilmiyor" });
    const say = await (await fetch(`${SB_URL}/rest/v1/rpc/kurucu_sayac`, { method: "POST", headers: { apikey: SB_ANON, "Content-Type": "application/json" }, body: "{}" })).json().catch(() => []);
    // deno-lint-ignore no-explicit-any
    const satilan = (Array.isArray(say) ? say : []).find((x: any) => x.sinav === pf.sinav)?.satilan ?? 0;
    const taban = satilan >= (F.KOTA[pf.sinav] ?? 0) ? pf.f.liste : pf.f.kurulus;
    const beklenen = taban - (Number(s.indirim_tl) || 0);
    if (Number(s.tutar) !== beklenen) return cevap(409, { hata: "tutar guncel fiyatla uyusmuyor", siparis: s.tutar, guncel: beklenen });
    const r = await odemeBaslat(beklenen, no, s.paket_ad || s.paket, alici(s.ad_soyad, s.email, s.adres, String(s.fatura?.tckn ?? ""), ip, no));
    if (r.status !== "success" || !r.token) return cevap(502, { hata: "iyzico baslatmadi", errorCode: r.errorCode ?? null, errorMessage: r.errorMessage ?? null });
    await sb("kart_odemeleri", { method: "POST", body: JSON.stringify({ siparis_no: no, deneme: false, tutar: beklenen, conversation_id: no, token: r.token }) });
    return cevap(200, { odemeSayfasi: r.paymentPageUrl });
  }

  // ---------------------------------------------------------------- iyzico geri çağrısı
  if (islem === "donus" && req.method === "POST") {
    let token = "";
    try { const f = await req.formData(); token = String(f.get("token") ?? ""); } catch { /* boş */ }
    if (!token) return yonlen(`${SITE}/satin-al.html?odeme=hata`);
    const k = (await (await sb(`kart_odemeleri?select=*&token=eq.${encodeURIComponent(token)}&limit=1`)).json().catch(() => []))[0];
    if (!k) return yonlen(`${SITE}/satin-al.html?odeme=hata`);
    const d = await iyzico("/payment/iyzipos/checkoutform/auth/ecom/detail", { locale: "tr", conversationId: k.conversation_id, token });
    const tamam = d.status === "success" && d.paymentStatus === "SUCCESS" && Number(d.fraudStatus) === 1
      && Math.abs(Number(d.paidPrice) - Number(k.tutar)) < 0.005 && d.basketId === k.conversation_id;
    await sb(`kart_odemeleri?id=eq.${k.id}`, { method: "PATCH", body: JSON.stringify({ durum: tamam ? "basarili" : "basarisiz", payment_id: d.paymentId ?? null, iyzico_durum: String(d.paymentStatus ?? d.status ?? ""), hata: tamam ? null : String(d.errorMessage ?? (d.fraudStatus !== undefined ? "fraudStatus " + d.fraudStatus : "dogrulanamadi")).slice(0, 300), guncelleme: new Date().toISOString() }) });
    if (k.deneme) return yonlen(`${SITE}/yonetim.html?kart=${tamam ? "ok" : "hata"}`);
    if (!tamam) return yonlen(`${SITE}/satin-al.html?odeme=hata&no=${encodeURIComponent(k.siparis_no)}`);
    const o = await fetch(`${SB_URL}/rest/v1/rpc/kart_siparis_odendi`, { method: "POST", headers: sbH, body: JSON.stringify({ p_no: k.siparis_no, p_payment_id: String(d.paymentId ?? "") }) });
    if (o.ok) {
      try { await fetch(`${SB_URL}/functions/v1/siparis-bildirim`, { method: "POST", headers: { "Content-Type": "application/json", apikey: SB_ANON, Authorization: `Bearer ${SB_ANON}` }, body: JSON.stringify({ tur: "acildi", no: k.siparis_no }) }); } catch { /* mail düşerse ödeme bozulmaz */ }
    }
    return yonlen(`${SITE}/ogrenci.html?odeme=${o.ok ? "ok" : "kontrol"}&no=${encodeURIComponent(k.siparis_no)}`);
  }
  return cevap(404, { hata: "bilinmeyen islem" });
});
