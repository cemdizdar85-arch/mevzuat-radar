// ============================================================================
//  MAGAZA-DOGRULA Edge Function (Supabase) — uygulama içi satın almayı doğrular,
//  paketi hesaba tanımlar (25.09.2026, Cem "1 ve 2 yap": uygulama içi satış, fiyat ÷ 0,85).
//
//  AKIŞ (Google Play):
//    1) Uygulama önce {islem:"kontrol"} ile sorar: bu ürün bu hesaba tanımlanabilir mi? (ödeme YOK)
//    2) Kullanıcı Google ekranında öder. Uygulama satın almayı ONAYLAMADAN (autoAcknowledge:false)
//       {islem:"dogrula", jeton} gönderir.
//    3) Bu fonksiyon Google Play Developer API ile jetonu doğrular: satın alındı mı, bu HESAP için mi
//       (obfuscatedExternalAccountId = Supabase user id), daha önce kullanıldı mı.
//    4) paket_uyeler'e yazar, magaza_siparis'e kaydeder, SONRA Google'da "tüketir" (consume).
//       Tüketim hem onaylar hem aynı ürünün sonraki dönem yeniden alınmasına izin verir.
//  ⛔ TANIMLANAMAYAN SATIN ALMA ONAYLANMAZ: Google, 3 gün içinde onaylanmayan ödemeyi KENDİLİĞİNDEN
//     İADE EDER. Bu yüzden emin olmadığımız her durumda (başka sınav aktif, zaten açık, doğrulama
//     hatası) paket yazılmaz ve tüketilmez → müşteri parasını geri alır, kayıt magaza_siparis'te kalır.
//
//  paket_uyeler bugün KİŞİ BAŞINA TEK SATIR (birincil anahtar user_id). Bu yüzden hesapta başka bir
//  sınavın AKTİF paketi varsa ikinci sınav buradan tanımlanamaz (red "baska-sinav"). Çok satırlı
//  yapı ayrı iş (mobil/OKU.md).
//
//  GİZLİLER (Supabase → Edge Functions → Secrets):
//    MAGAZA_GOOGLE_SERVIS_JSON  Google Cloud servis hesabının JSON anahtarı (Play Console'da
//                               "Siparişleri yönet" + "Finansal verileri görüntüle" izinli)
//    MAGAZA_APPLE_ANAHTAR_ID    App Store Connect → Users and Access → Integrations → In-App Purchase
//    MAGAZA_APPLE_YAYINCI_ID    anahtarının Key ID'si · Issuer ID · .p8 dosyasının İÇERİĞİ (26.09 Apple ayağı).
//    MAGAZA_APPLE_P8            Üçü yoksa Apple istekleri 503 "sunucu-ayari" döner.
//    SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY otomatik gelir.
//
//  AKIŞ (App Store, 26.09.2026): uygulama ödemeden önce yine {islem:"kontrol"} sorar; StoreKit 2 satın
//  almasına appAccountToken = Supabase user id iliştirilir ve işlem BİTİRİLMEDEN bırakılır. {magaza:"apple",
//  jeton: transactionId} ile gelinir; App Store Server API'den işlem okunur (önce üretim, yoksa sandbox),
//  paket/ürün/hesap/iade denetlenir, paket yazılır; uygulama sonra işlemi cihazda bitirir (finish).
//  ⚠ Apple bitirilmemiş işlemi KENDİLİĞİNDEN İADE ETMEZ — "kontrol" adımı bu yüzden şart.
//  YAYIN: Supabase panel → Edge Functions → yeni fonksiyon "magaza-dogrula" → bu dosya.
//         "Verify JWT" KAPALI (diğer uç fonksiyonlar gibi): kimlik bu dosyada /auth/v1/user ile
//         doğrulanır; kapı açıkken ?surum=1 nöbetçisi ve CORS ön isteği ağ geçidinde 401 alır.
//  TEŞHİS: ?surum=1 → kod imzası · ?tani=1 → gizli tanımlı mı (değer DÖNMEZ).
//
//  BU FONKSİYON ŞUNU YAPMAZ / GÖRMEZ:
//    - İade/iptal sonrası erişimi geri almaz (Google "voided purchases" / Apple REFUND bildirimi izlenmiyor — ayrı iş).
//    - Apple işlem yükünün (JWS) sertifika zincirini ayrıca doğrulamaz: yük, kimlik doğrulamalı istekle
//      doğrudan Apple sunucusundan okunur; istemcinin gönderdiği JWS'e hiç güvenilmez.
//    - Elçi / davet kodu indirimi uygulamaz (mağaza fiyatı sabit).
// ============================================================================

// SAF-BASLA — bu blokta TİP YAZIMI YOK: mobil/magaza-sinavi.js onu Node'da (vm) çalıştırıp ölçer.
const PAKET_ADI = "com.tetikte.app";
const URUNLER = {
  "sgs":            { paket: "sgs",            sinav: "sgs",        ders: 0 },
  "yeterlilik_1":   { paket: "yeterlilik-1",   sinav: "yeterlilik", ders: 1 },
  "yeterlilik_2":   { paket: "yeterlilik-2",   sinav: "yeterlilik", ders: 2 },
  "yeterlilik_3":   { paket: "yeterlilik-3",   sinav: "yeterlilik", ders: 3 },
  "yeterlilik_4":   { paket: "yeterlilik-4",   sinav: "yeterlilik", ders: 4 },
  "yeterlilik_tum": { paket: "yeterlilik-tum", sinav: "yeterlilik", ders: 8 }
};
// Kasadaki (paket_soru.ders) ekran adları — RLS dersler dizisini BU adlarla eşler.
const DERSLER = {
  yeterlilik: ["Finansal Muhasebe", "Finansal Tablolar ve Analizi", "Maliyet Muhasebesi", "Muhasebe Denetimi",
               "Vergi Mevzuatı ve Uygulaması", "Hukuk", "Sermaye Piyasası Mevzuatı", "Meslek Hukuku"]
};
// fiyat-motoru.js SINAVLAR + SURE_GUN + bitisTarihi() ile AYNI (mobil/magaza-sinavi.js kıyaslar).
const SINAV_TARIHI = { sgs: "2026-11-21", yeterlilik: "2026-11-28" };
const SURE_GUN = 90;

function trGunu(ms) { return new Date(ms + 3 * 3600000).toISOString().slice(0, 10); }
function bitisHesapla(sinav, simdiMs) {
  const normal = simdiMs + SURE_GUN * 86400000;
  const t = SINAV_TARIHI[sinav];
  if (!t) return trGunu(normal);
  const sg = new Date(t + "T09:00:00+03:00").getTime();
  if (sg < simdiMs) return trGunu(normal);
  const uzatilmis = sg + 3 * 86400000;
  return trGunu(uzatilmis > normal ? uzatilmis : normal);
}
// paket adı → kapsadığı sınavlar (paket-kapisi.js / paket_soru RLS ile aynı eşleme)
function paketSinavlari(paket) {
  const p = String(paket == null ? "" : paket).trim().toLowerCase();
  if (!p || p === "tam" || p === "kurucu") return ["sgs", "yeterlilik", "kgk"];
  if (p === "yeterlilik-kgk") return ["yeterlilik", "kgk"];
  if (p === "sgs" || p.indexOf("sgs-") === 0 || p === "sinav-249") return ["sgs"];
  if (p === "yeterlilik" || p === "smmm" || p.indexOf("yeterlilik-") === 0) return ["yeterlilik"];
  if (p === "kgk" || p.indexOf("kgk-") === 0) return ["kgk"];
  return [];
}
function dersleriDogrula(urunId, dersler) {
  const u = URUNLER[urunId];
  if (!u) return { tamam: false, hata: "urun-yok" };
  const liste = DERSLER[u.sinav] || [];
  if (u.ders === 0 || u.ders >= liste.length) return { tamam: true, dersler: null };
  if (!Array.isArray(dersler)) return { tamam: false, hata: "ders-secilmedi" };
  const temiz = new Array();
  for (const d of dersler) {
    if (typeof d !== "string" || liste.indexOf(d) < 0) return { tamam: false, hata: "ders-gecersiz" };
    if (temiz.indexOf(d) < 0) temiz.push(d);
  }
  if (temiz.length !== u.ders) return { tamam: false, hata: "ders-sayisi" };
  return { tamam: true, dersler: temiz };
}
// satir: paket_uyeler satırı ya da null. Döner: {islem:"ekle"|"guncelle"|"red", yeni?, neden?}
function hakKarari(satir, urunId, dersler, simdiMs) {
  const u = URUNLER[urunId];
  const yeniBitis = bitisHesapla(u.sinav, simdiMs);
  const bugun = trGunu(simdiMs);
  const tamListe = DERSLER[u.sinav] || [];
  if (!satir) return { islem: "ekle", yeni: { paket: u.paket, bitis: yeniBitis, dersler: dersler } };
  const aktif = !satir.bitis || satir.bitis >= bugun;
  if (!aktif) return { islem: "guncelle", yeni: { paket: u.paket, bitis: yeniBitis, dersler: dersler } };
  const p = String(satir.paket == null ? "" : satir.paket).trim().toLowerCase();
  if (!p || p === "tam" || p === "kurucu") return { islem: "red", neden: "zaten-acik" };
  if (paketSinavlari(p).indexOf(u.sinav) < 0) return { islem: "red", neden: "baska-sinav" };
  const uzat = satir.bitis && satir.bitis > yeniBitis ? satir.bitis : yeniBitis;
  if (u.sinav === "sgs") return { islem: "guncelle", yeni: { paket: satir.paket, bitis: uzat, dersler: satir.dersler || null } };
  const eski = Array.isArray(satir.dersler) ? satir.dersler : null;
  if (eski === null) {
    if (dersler === null) return { islem: "guncelle", yeni: { paket: satir.paket, bitis: uzat, dersler: null } };
    return { islem: "red", neden: "zaten-acik" };
  }
  if (dersler === null) return { islem: "guncelle", yeni: { paket: u.paket, bitis: uzat, dersler: null } };
  const yeniDers = dersler.filter((d) => eski.indexOf(d) < 0);
  if (!yeniDers.length) return { islem: "red", neden: "zaten-acik" };
  const birlesik = eski.concat(yeniDers);
  if (birlesik.length >= tamListe.length) return { islem: "guncelle", yeni: { paket: u.sinav + "-tum", bitis: uzat, dersler: null } };
  return { islem: "guncelle", yeni: { paket: u.sinav + "-" + birlesik.length, bitis: uzat, dersler: birlesik } };
}
// Google ProductPurchase yanıtını bu hesap için değerlendirir.
function googleHukmu(g, kullaniciId) {
  if (!g || typeof g !== "object") return "yanit-yok";
  if (g.purchaseState !== 0) return g.purchaseState === 2 ? "beklemede" : "iptal";
  if (g.obfuscatedExternalAccountId !== kullaniciId) return "baska-hesap";
  return "tamam";
}
// App Store Server API işlem yükünü (JWSTransactionDecodedPayload) bu hesap + ürün için değerlendirir.
// appAccountToken = satın alırken iliştirilen Supabase user id (UUID; Apple büyük harfle döndürebilir).
function appleHukmu(a, kullaniciId, urunId) {
  if (!a || typeof a !== "object") return "yanit-yok";
  if (a.bundleId !== PAKET_ADI) return "baska-uygulama";
  if (a.productId !== urunId) return "urun-uyusmuyor";
  if (String(a.appAccountToken || "").toLowerCase() !== String(kullaniciId).toLowerCase()) return "baska-hesap";
  if (a.revocationDate) return "iptal";
  if (a.type !== "Consumable") return "urun-turu";
  return "tamam";
}
// SAF-BITIS

// Kod imzası: arac/edge-imza.js --yaz yazar, ELLE DEĞİŞTİRME. ?surum=1 bunu döndürür.
const KOD_IMZA = "3f8d305da3a13606";

// Uygulama kökenleri: Android WebView https://localhost, iOS capacitor://localhost.
const IZINLI_KOKEN = new Set(["https://localhost", "capacitor://localhost", "http://localhost"]);

type Satir = { paket: string | null; bitis: string | null; dersler: string[] | null } | null;

function cors(origin: string | null): Record<string, string> {
  return {
    "Access-Control-Allow-Origin": origin && IZINLI_KOKEN.has(origin) ? origin : "https://localhost",
    "Access-Control-Allow-Headers": "authorization, apikey, content-type, x-client-info",
    "Access-Control-Allow-Methods": "POST, GET, OPTIONS",
    "Vary": "Origin",
  };
}
function yanit(govde: unknown, durum: number, origin: string | null): Response {
  return new Response(JSON.stringify(govde), { status: durum, headers: { "Content-Type": "application/json; charset=utf-8", ...cors(origin) } });
}

const SB_URL = typeof Deno !== "undefined" ? (Deno.env.get("SUPABASE_URL") || "") : "";
const SB_SERVIS = typeof Deno !== "undefined" ? (Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || "") : "";
const GOOGLE_JSON = typeof Deno !== "undefined" ? (Deno.env.get("MAGAZA_GOOGLE_SERVIS_JSON") || "") : "";
const APPLE_ANAHTAR_ID = typeof Deno !== "undefined" ? (Deno.env.get("MAGAZA_APPLE_ANAHTAR_ID") || "") : "";
const APPLE_YAYINCI_ID = typeof Deno !== "undefined" ? (Deno.env.get("MAGAZA_APPLE_YAYINCI_ID") || "") : "";
const APPLE_P8 = typeof Deno !== "undefined" ? (Deno.env.get("MAGAZA_APPLE_P8") || "") : "";
const APPLE_HAZIR = !!(APPLE_ANAHTAR_ID && APPLE_YAYINCI_ID && APPLE_P8);

async function rest(yol: string, secenek: RequestInit = {}): Promise<Response> {
  return await fetch(SB_URL + "/rest/v1/" + yol, {
    ...secenek,
    headers: { apikey: SB_SERVIS, Authorization: "Bearer " + SB_SERVIS, "Content-Type": "application/json", ...(secenek.headers || {}) },
  });
}
async function kullaniciBul(jwt: string): Promise<{ id: string; email: string } | null> {
  const r = await fetch(SB_URL + "/auth/v1/user", { headers: { apikey: SB_SERVIS, Authorization: "Bearer " + jwt } });
  if (!r.ok) return null;
  const j = await r.json();
  return j && j.id ? { id: j.id, email: j.email || "" } : null;
}
async function paketSatiri(userId: string): Promise<Satir> {
  const r = await rest("paket_uyeler?select=paket,bitis,dersler&user_id=eq." + encodeURIComponent(userId));
  if (!r.ok) throw new Error("paket_uyeler okunamadı " + r.status);
  const a = await r.json();
  return a.length ? a[0] : null;
}

/* ---- Google: servis hesabı JWT → erişim anahtarı (RS256, WebCrypto) ---- */
function b64url(b: ArrayBuffer | Uint8Array | string): string {
  const baytlar = typeof b === "string" ? new TextEncoder().encode(b) : new Uint8Array(b as ArrayBuffer);
  let s = ""; for (const x of baytlar) s += String.fromCharCode(x);
  return btoa(s).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}
let googleAnahtar: { deger: string; bitis: number } | null = null;
async function googleErisim(): Promise<string> {
  if (googleAnahtar && googleAnahtar.bitis > Date.now() + 60000) return googleAnahtar.deger;
  const sa = JSON.parse(GOOGLE_JSON);
  const simdi = Math.floor(Date.now() / 1000);
  const govde = b64url(JSON.stringify({ alg: "RS256", typ: "JWT" })) + "." + b64url(JSON.stringify({
    iss: sa.client_email, scope: "https://www.googleapis.com/auth/androidpublisher",
    aud: "https://oauth2.googleapis.com/token", iat: simdi, exp: simdi + 3600,
  }));
  const pem = String(sa.private_key).replace(/-----[^-]+-----/g, "").replace(/\s+/g, "");
  const der = Uint8Array.from(atob(pem), (c) => c.charCodeAt(0));
  const anahtar = await crypto.subtle.importKey("pkcs8", der, { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" }, false, ["sign"]);
  const imza = await crypto.subtle.sign("RSASSA-PKCS1-v1_5", anahtar, new TextEncoder().encode(govde));
  const r = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST", headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: "grant_type=" + encodeURIComponent("urn:ietf:params:oauth:grant-type:jwt-bearer") + "&assertion=" + govde + "." + b64url(imza),
  });
  const j = await r.json();
  if (!r.ok || !j.access_token) throw new Error("google anahtar alınamadı " + r.status);
  googleAnahtar = { deger: j.access_token, bitis: Date.now() + (j.expires_in || 3600) * 1000 };
  return googleAnahtar.deger;
}
function googleYol(urunId: string, jeton: string): string {
  return "https://androidpublisher.googleapis.com/androidpublisher/v3/applications/" + PAKET_ADI +
    "/purchases/products/" + encodeURIComponent(urunId) + "/tokens/" + encodeURIComponent(jeton);
}
async function googleOku(urunId: string, jeton: string): Promise<Record<string, unknown> | null> {
  const r = await fetch(googleYol(urunId, jeton), { headers: { Authorization: "Bearer " + await googleErisim() } });
  if (r.status === 404 || r.status === 400) return null;
  if (!r.ok) throw new Error("google doğrulama " + r.status);
  return await r.json();
}
async function googleTuket(urunId: string, jeton: string): Promise<boolean> {
  const r = await fetch(googleYol(urunId, jeton) + ":consume", { method: "POST", headers: { Authorization: "Bearer " + await googleErisim() } });
  return r.ok;
}

/* ---- Apple: In-App Purchase anahtarıyla ES256 JWT → App Store Server API ---- */
let appleAnahtar: { deger: string; bitis: number } | null = null;
async function appleErisim(): Promise<string> {
  if (appleAnahtar && appleAnahtar.bitis > Date.now() + 60000) return appleAnahtar.deger;
  const simdi = Math.floor(Date.now() / 1000);
  const govde = b64url(JSON.stringify({ alg: "ES256", kid: APPLE_ANAHTAR_ID, typ: "JWT" })) + "." + b64url(JSON.stringify({
    iss: APPLE_YAYINCI_ID, iat: simdi, exp: simdi + 1200, aud: "appstoreconnect-v1", bid: PAKET_ADI,
  }));
  const pem = APPLE_P8.replace(/-----[^-]+-----/g, "").replace(/\s+/g, "");
  const der = Uint8Array.from(atob(pem), (c) => c.charCodeAt(0));
  const anahtar = await crypto.subtle.importKey("pkcs8", der, { name: "ECDSA", namedCurve: "P-256" }, false, ["sign"]);
  // WebCrypto ECDSA imzası r||s (IEEE P1363) döner — JWS ES256'nın istediği biçim.
  const imza = await crypto.subtle.sign({ name: "ECDSA", hash: "SHA-256" }, anahtar, new TextEncoder().encode(govde));
  appleAnahtar = { deger: govde + "." + b64url(imza), bitis: Date.now() + 1100 * 1000 };
  return appleAnahtar.deger;
}
function jwsYuk(jws: string): Record<string, unknown> | null {
  const orta = String(jws || "").split(".")[1];
  if (!orta) return null;
  const b64 = orta.replace(/-/g, "+").replace(/_/g, "/") + "===".slice((orta.length + 3) % 4);
  try { return JSON.parse(new TextDecoder().decode(Uint8Array.from(atob(b64), (c) => c.charCodeAt(0)))); } catch (_e) { return null; }
}
// Önce üretim, bulunamazsa sandbox (App Review ve test kullanıcıları sandbox'ta öder).
// Yanıt Apple'ın kendi sunucusundan, kimlik doğrulamalı istekle geldiği için yük imzası ayrıca çözülmez.
async function appleOku(islemNo: string): Promise<Record<string, unknown> | null> {
  for (const kok of ["https://api.storekit.itunes.apple.com", "https://api.storekit-sandbox.itunes.apple.com"]) {
    const r = await fetch(kok + "/inApps/v1/transactions/" + encodeURIComponent(islemNo), { headers: { Authorization: "Bearer " + await appleErisim() } });
    if (r.status === 404) continue;
    if (!r.ok) throw new Error("apple doğrulama " + r.status);
    const j = await r.json();
    const yuk = jwsYuk(j.signedTransactionInfo);
    return yuk ? { ...yuk, _ortam: kok.indexOf("sandbox") > 0 ? "sandbox" : "production" } : null;
  }
  return null;
}

async function siparisYaz(alanlar: Record<string, unknown>, jeton: string): Promise<void> {
  await rest("magaza_siparis?jeton=eq." + encodeURIComponent(jeton), { method: "PATCH", body: JSON.stringify({ ...alanlar, guncelleme: new Date().toISOString() }) });
}

async function dogrula(magaza: "google" | "apple", k: { id: string }, urunId: string, jeton: string, dersler: string[] | null, origin: string | null): Promise<Response> {
  const google = magaza === "google";
  // 1) Jeton daha önce görüldü mü (aynı ödemeyle iki kez paket alınamaz; tekrar çağrı güvenli)
  const on = await rest("magaza_siparis?select=user_id,durum,paket,bitis,urun,magaza&jeton=eq." + encodeURIComponent(jeton));
  const onceki = on.ok ? (await on.json())[0] : null;
  if (onceki) {
    if (onceki.user_id !== k.id || onceki.magaza !== magaza) return yanit({ tamam: false, neden: "baska-hesap" }, 409, origin);
    if (onceki.durum === "verildi" || onceki.durum === "tuketildi") {
      if (google && onceki.durum === "verildi" && await googleTuket(onceki.urun, jeton)) await siparisYaz({ durum: "tuketildi" }, jeton);
      return yanit({ tamam: true, paket: onceki.paket, bitis: onceki.bitis, tekrar: true }, 200, origin);
    }
    if (onceki.durum === "isleniyor") return yanit({ tamam: false, neden: "isleniyor" }, 409, origin);
  } else {
    const ek = await rest("magaza_siparis", { method: "POST", headers: { Prefer: "resolution=ignore-duplicates,return=representation" },
      body: JSON.stringify({ magaza, urun: urunId, jeton, user_id: k.id, durum: "isleniyor" }) });
    const eklenen = ek.ok ? await ek.json() : [];
    if (!eklenen.length) return yanit({ tamam: false, neden: "isleniyor" }, 409, origin);
  }

  // 2) Mağazaya sor
  let g: Record<string, unknown> | null = null;
  const ulasilamadi = google ? "google-ulasilamadi" : "apple-ulasilamadi";
  try { g = google ? await googleOku(urunId, jeton) : await appleOku(jeton); }
  catch (_e) { await siparisYaz({ durum: "hata", neden: ulasilamadi }, jeton); return yanit({ tamam: false, neden: ulasilamadi }, 502, origin); }
  const gh = google ? googleHukmu(g, k.id) : appleHukmu(g, k.id, urunId);
  if (gh !== "tamam") {
    await siparisYaz({ durum: gh === "beklemede" ? "beklemede" : "red", neden: gh, ham: g, siparis_no: g ? (google ? g.orderId : g.originalTransactionId) : null }, jeton);
    return yanit({ tamam: false, neden: gh }, gh === "beklemede" ? 202 : 409, origin);
  }
  const siparisNo = google ? (g as Record<string, unknown>).orderId : (g as Record<string, unknown>).originalTransactionId;

  // 3) Hak kararı. Google: tanımlanamıyorsa TÜKETİLMEZ → Google 3 günde iade eder.
  //    Apple: kendiliğinden iade YOK — bu yüzden uygulama ödemeden ÖNCE {islem:"kontrol"} sorar; buraya düşen
  //    red nadirdir (iki cihazdan eşzamanlı alım) ve magaza_siparis'te "red" olarak iade takibine kalır.
  const karar = hakKarari(await paketSatiri(k.id), urunId, dersler, Date.now());
  if (karar.islem === "red") {
    await siparisYaz({ durum: "red", neden: karar.neden, ham: g, siparis_no: siparisNo }, jeton);
    return yanit({ tamam: false, neden: karar.neden, iade: google ? "3 gün içinde otomatik" : "apple-iade-talebi" }, 409, origin);
  }
  const y = karar.yeni!;
  const yaz = karar.islem === "ekle"
    ? await rest("paket_uyeler", { method: "POST", headers: { Prefer: "return=minimal" }, body: JSON.stringify({ user_id: k.id, paket: y.paket, bitis: y.bitis, dersler: y.dersler }) })
    : await rest("paket_uyeler?user_id=eq." + encodeURIComponent(k.id), { method: "PATCH", headers: { Prefer: "return=minimal" }, body: JSON.stringify({ paket: y.paket, bitis: y.bitis, dersler: y.dersler }) });
  if (!yaz.ok) {
    await siparisYaz({ durum: "hata", neden: "paket-yazilamadi " + yaz.status, ham: g, siparis_no: siparisNo }, jeton);
    return yanit({ tamam: false, neden: "paket-yazilamadi" }, 500, origin);
  }
  await siparisYaz({ durum: "verildi", paket: y.paket, bitis: y.bitis, dersler: y.dersler, ham: g, siparis_no: siparisNo }, jeton);

  // 4) Google: tüket (onay + yeniden satın alınabilirlik). Düşerse paket yine verildi; sonraki çağrı yeniden dener.
  //    Apple: sunucuda tüketim yok — uygulama bu yanıttan sonra işlemi cihazda bitirir (finish).
  if (google && await googleTuket(urunId, jeton)) await siparisYaz({ durum: "tuketildi" }, jeton);
  return yanit({ tamam: true, paket: y.paket, bitis: y.bitis }, 200, origin);
}

async function isle(req: Request): Promise<Response> {
  const origin = req.headers.get("origin");
  if (req.method === "OPTIONS") return new Response(null, { status: 204, headers: cors(origin) });
  const url = new URL(req.url);
  if (url.searchParams.get("surum") === "1") return new Response(JSON.stringify({ surum: KOD_IMZA }), { status: 200, headers: { "Content-Type": "application/json; charset=utf-8", "Access-Control-Allow-Origin": "*" } });
  if (url.searchParams.get("tani") === "1") return yanit({ google: !!GOOGLE_JSON, apple: APPLE_HAZIR, supabase: !!(SB_URL && SB_SERVIS) }, 200, origin);
  if (req.method !== "POST") return yanit({ tamam: false, neden: "yontem" }, 405, origin);

  const jwt = (req.headers.get("authorization") || "").replace(/^Bearer\s+/i, "");
  const k = jwt ? await kullaniciBul(jwt) : null;
  if (!k) return yanit({ tamam: false, neden: "giris-yok" }, 401, origin);

  let b: Record<string, unknown>;
  try { b = await req.json(); } catch (_e) { return yanit({ tamam: false, neden: "govde" }, 400, origin); }
  const urunId = String(b.urun || "");
  const d = dersleriDogrula(urunId, b.dersler);
  if (!d.tamam) return yanit({ tamam: false, neden: d.hata }, 400, origin);

  if (b.islem === "kontrol") {
    const karar = hakKarari(await paketSatiri(k.id), urunId, d.dersler, Date.now());
    return yanit({ tamam: karar.islem !== "red", neden: karar.neden || null, yeni: karar.yeni || null }, 200, origin);
  }
  if (b.islem !== "dogrula") return yanit({ tamam: false, neden: "islem" }, 400, origin);
  const jeton = String(b.jeton || "");
  if (b.magaza === "apple") {
    // Apple jetonu = StoreKit 2 transactionId (yalnız rakam)
    if (!/^\d{1,20}$/.test(jeton)) return yanit({ tamam: false, neden: "jeton" }, 400, origin);
    if (!APPLE_HAZIR) return yanit({ tamam: false, neden: "sunucu-ayari" }, 503, origin);
    return await dogrula("apple", k, urunId, jeton, d.dersler || null, origin);
  }
  if (b.magaza !== "google") return yanit({ tamam: false, neden: "magaza" }, 400, origin);
  if (!/^[A-Za-z0-9._\-:]{20,2000}$/.test(jeton)) return yanit({ tamam: false, neden: "jeton" }, 400, origin);
  if (!GOOGLE_JSON) return yanit({ tamam: false, neden: "sunucu-ayari" }, 503, origin);
  return await dogrula("google", k, urunId, jeton, d.dersler || null, origin);
}

if (typeof Deno !== "undefined") Deno.serve((req: Request) => isle(req).catch(() => yanit({ tamam: false, neden: "sunucu" }, 500, req.headers.get("origin"))));
