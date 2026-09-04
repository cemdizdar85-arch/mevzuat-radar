// ============================================================================
//  FORM-AL Edge Function (Supabase) — sitedeki her formun TEK kapısı.
//
//  NEDEN VAR (04.09.2026, Cem): "Kurumsal firma olacağız, müşterinin gireceği
//  bilgiler güvenli yerde olsun." O güne kadar 19 sayfa formu üçüncü bir
//  aracıya (web3forms) gönderiyordu: bağımsız denetimi yok, KVKK metninde adı
//  geçmiyor, veri hangi ülkede durur bilinmiyor. Bu fonksiyon o aracının
//  yerine geçer: form verisi Supabase'e (Frankfurt) yazılır, Resend ile
//  bize mail düşer. Zincirde tanımadığımız halka kalmaz.
//
//  API BİÇİMİ web3forms ile AYNI tutuldu ki sayfalar tek satır değişsin:
//    POST {subject, from_name, email?, message?, ...serbest alanlar}
//    → 200 {success:true, kayit:bool, posta:bool}
//
//  KURULUM (Cem, panel — kod girmez):
//    1) Supabase → Edge Functions → New function → adı: form-al → bu dosyayı
//       yapıştır → Deploy. Ayarda "Verify JWT" KAPAT (tarayıcıdan anonim gelir).
//    2) Settings → Edge Functions → Secrets:
//         RESEND_KEY   = GitHub Actions'taki RESEND_KEY ile aynı değer
//         RESEND_FROM  = 'Tetikte <bildirim@tetikte.com>' (GitHub'daki ile aynı)
//         FORM_ALICI   = form maillerinin düşeceği adres (yazılmazsa
//                        info@dizdardenetim.com — sitenin altbilgisindeki adres)
//       SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY / SUPABASE_ANON_KEY'i Supabase
//       kendisi verir, elle girilmez.
//    3) SQL Editor → veri/sql-form-kasasi.sql bas (form_kayit tablosu).
//       Basılmadan da çalışır: kayıt düşmez, yalnız mail gider (kayit:false).
//
//  ⚠️ CANLI ADI "quick-task" (04.09.2026): panelde isim kutusu boş kalınca
//  Supabase kendi adını verdi; kod bu dosya. "Verify JWT" AÇIK kaldı, bu yüzden
//  sayfalar isteğe apikey + Authorization (açık anahtar) başlığı ekler.
//  Adı form-al'a çevirmek = yeniden deploy + eski adı silme (Chrome eklentisi
//  bağlanınca GM yapar). Uç: …/functions/v1/quick-task
//
//  TEŞHİS: curl -X POST .../functions/v1/form-al?tani=1  → hangi secret tanımlı
//  (yalnız true/false, değer ASLA dönmez).
//
//  KORUMA KATMANLARI (hepsi sunucuda, tarayıcı atlatamaz):
//    - Origin allowlist (tetikte.com + yerel geliştirme)
//    - bal küpü: _hp / botcheck dolu → sessiz 200, hiçbir yere yazılmaz
//    - hız sınırı: IP başına 10 dk'da 10 gönderi (rate_limit_check RPC,
//      sunucu IP'yi x-forwarded-for'dan okur — sahtelenemez)
//    - boy tavanları: gövde 8 KB, alan 30, alan değeri 2.000 karakter
//    - KVKK asgarilik: IP kasaya YAZILMAZ, yalnız sayaçta kullanılır
// ============================================================================

const SB_URL = (Deno.env.get("SUPABASE_URL") ?? "https://bjrleanjpyujtajmazxn.supabase.co").replace(/\/$/, "");
const SB_SERVICE = (Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "").trim();
const SB_ANON = (Deno.env.get("SUPABASE_ANON_KEY") ?? "").trim();
const RESEND_KEY = (Deno.env.get("RESEND_KEY") ?? "").trim();
const RESEND_FROM = (Deno.env.get("RESEND_FROM") ?? "Tetikte <bildirim@tetikte.com>").trim();
const ALICI = (Deno.env.get("FORM_ALICI") ?? "info@dizdardenetim.com").trim();

const IZINLI_KOKEN = new Set(["https://tetikte.com", "https://www.tetikte.com"]);
// Yerel geliştirme: arac/yerel-sunucu.js rastgele port alabiliyor (04.09: 56194).
const YEREL_KOKEN = /^http:\/\/(localhost|127\.0\.0\.1)(:\d{1,5})?$/;
function kokenIzinli(o: string | null): boolean {
  return !!o && (IZINLI_KOKEN.has(o) || YEREL_KOKEN.test(o));
}

const GOVDE_TAVAN = 8 * 1024;
const ALAN_TAVAN = 30;
const DEGER_TAVAN = 2000;
const HIZ_LIMIT = 10;
const HIZ_PENCERE_SN = 600;

function cors(origin: string | null): Record<string, string> {
  const o = kokenIzinli(origin) ? (origin as string) : "https://tetikte.com";
  return {
    "Access-Control-Allow-Origin": o,
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, accept",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Vary": "Origin",
    "Content-Type": "application/json; charset=utf-8",
  };
}

function cevap(durum: number, govde: unknown, origin: string | null): Response {
  return new Response(JSON.stringify(govde), { status: durum, headers: cors(origin) });
}

function metin(v: unknown, tavan: number): string {
  if (v === null || v === undefined) return "";
  const s = typeof v === "string" ? v : (typeof v === "number" || typeof v === "boolean") ? String(v) : JSON.stringify(v);
  // Kontrol karakterleri atilir (satir sonu ve sekme kalir).
  return s.replace(/[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F]/g, "").slice(0, tavan);
}

function epostaGecerli(e: string): boolean {
  return /^[^\s@]{1,64}@[^\s@]{1,190}\.[^\s@]{2,}$/.test(e) && e.length <= 254;
}

// HTML kaçış: mail gövdesine kullanıcı metni ham girmez.
function kacis(s: string): string {
  return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");
}

async function hizAsti(ip: string): Promise<boolean> {
  if (!ip || ip === "anon" || !SB_ANON) return false;
  try {
    const r = await fetch(`${SB_URL}/rest/v1/rpc/rate_limit_check`, {
      method: "POST",
      headers: { "content-type": "application/json", apikey: SB_ANON, Authorization: `Bearer ${SB_ANON}` },
      body: JSON.stringify({ p_ip: ip, p_limit: HIZ_LIMIT, p_pencere_sn: HIZ_PENCERE_SN }),
    });
    if (!r.ok) return false;                 // fail-open: sayaç ölürse formu öldürme
    return (await r.json()) === false;       // RPC true=izin, false=aşıldı
  } catch { return false; }
}

async function kasayaYaz(kayit: Record<string, unknown>): Promise<boolean> {
  if (!SB_SERVICE) return false;
  try {
    const r = await fetch(`${SB_URL}/rest/v1/form_kayit`, {
      method: "POST",
      headers: {
        "content-type": "application/json",
        apikey: SB_SERVICE,
        Authorization: `Bearer ${SB_SERVICE}`,
        Prefer: "return=minimal",
      },
      body: JSON.stringify(kayit),
    });
    return r.status === 201;
  } catch { return false; }
}

async function mailGonder(konu: string, satirlar: [string, string][], yanitAdresi: string): Promise<boolean> {
  if (!RESEND_KEY) return false;
  const duz = satirlar.map(([k, v]) => `${k}: ${v}`).join("\n");
  const html = `<div style="font-family:system-ui,sans-serif;font-size:14px;line-height:1.5">` +
    satirlar.map(([k, v]) => `<p><b>${kacis(k)}</b><br>${kacis(v).replace(/\n/g, "<br>")}</p>`).join("") +
    `</div>`;
  const govde: Record<string, unknown> = { from: RESEND_FROM, to: [ALICI], subject: konu, text: duz, html };
  if (yanitAdresi) govde.reply_to = yanitAdresi;
  try {
    const r = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: { Authorization: `Bearer ${RESEND_KEY}`, "content-type": "application/json" },
      body: JSON.stringify(govde),
    });
    return r.ok;
  } catch { return false; }
}

Deno.serve(async (req) => {
  const origin = req.headers.get("origin");
  if (req.method === "OPTIONS") return new Response(null, { status: 204, headers: cors(origin) });

  const url = new URL(req.url);
  if (url.searchParams.get("tani") === "1") {
    return cevap(200, {
      tani: true,
      secret_tanimli: { RESEND_KEY: !!RESEND_KEY, RESEND_FROM: !!Deno.env.get("RESEND_FROM"), FORM_ALICI: !!Deno.env.get("FORM_ALICI"), SERVICE_ROLE: !!SB_SERVICE },
      alici_ayarli: !!Deno.env.get("FORM_ALICI"),
    }, origin);
  }

  if (req.method !== "POST") return cevap(405, { success: false, hata: "yalniz POST" }, origin);
  if (!kokenIzinli(origin)) return cevap(403, { success: false, hata: "koken izinli degil" }, origin);

  const ham = await req.text();
  if (ham.length > GOVDE_TAVAN) return cevap(413, { success: false, hata: "govde cok buyuk" }, origin);
  let veri: Record<string, unknown>;
  try { veri = JSON.parse(ham); } catch { return cevap(400, { success: false, hata: "json degil" }, origin); }
  if (!veri || typeof veri !== "object" || Array.isArray(veri)) return cevap(400, { success: false, hata: "nesne degil" }, origin);

  // Bal küpü: bot doldurmuşsa "başarılı" de, hiçbir yere yazma.
  if (metin(veri._hp, 10) || metin(veri.botcheck, 10)) return cevap(200, { success: true, kayit: false, posta: false }, origin);

  const ip = (req.headers.get("x-forwarded-for") || "").split(",")[0].trim() || "anon";
  if (await hizAsti(ip)) return cevap(429, { success: false, hata: "cok sik gonderi, biraz sonra dene" }, origin);

  const konu = metin(veri.subject, 160) || "Site formu";
  const gonderen = metin(veri.from_name, 80) || "Tetikte";
  const eposta = metin(veri.email, 254).trim().toLowerCase();
  const epostaOk = eposta ? epostaGecerli(eposta) : true;
  if (!epostaOk) return cevap(400, { success: false, hata: "e-posta bicimi gecersiz" }, origin);

  // Serbest alanlar (web3forms uyumu): access_key gibi eski kalıntılar atılır.
  const atla = new Set(["subject", "from_name", "email", "_hp", "botcheck", "access_key", "redirect", "ccemail"]);
  const alanlar: Record<string, string> = {};
  let sayi = 0;
  for (const [k, v] of Object.entries(veri)) {
    if (atla.has(k)) continue;
    if (++sayi > ALAN_TAVAN) break;
    const ad = metin(k, 80).trim();
    if (!ad) continue;
    alanlar[ad] = metin(v, DEGER_TAVAN);
  }

  const sayfa = metin(req.headers.get("referer"), 300);
  const kayitOk = await kasayaYaz({
    konu, gonderen, eposta: eposta || null, sayfa: sayfa || null, koken: origin, alanlar,
  });

  const satirlar: [string, string][] = [["Konu", konu], ["Kaynak", gonderen]];
  if (eposta) satirlar.push(["E-posta", eposta]);
  for (const [k, v] of Object.entries(alanlar)) if (v) satirlar.push([k, v]);
  if (sayfa) satirlar.push(["Sayfa", sayfa]);
  satirlar.push(["Kasaya yazıldı", kayitOk ? "evet" : "HAYIR (form_kayit tablosu ya da service role eksik)"]);
  const postaOk = await mailGonder(`[Tetikte] ${konu}`, satirlar, eposta);

  if (kayitOk && postaOk && SB_SERVICE) {
    // posta_gitti damgası: kayıt vardı, mail de gitti. Hata olursa sessiz —
    // asıl iş (kayıt + mail) bitti.
    try {
      await fetch(`${SB_URL}/rest/v1/form_kayit?konu=eq.${encodeURIComponent(konu)}&posta_gitti=is.false&order=olusturma.desc&limit=1`, {
        method: "PATCH",
        headers: { "content-type": "application/json", apikey: SB_SERVICE, Authorization: `Bearer ${SB_SERVICE}`, Prefer: "return=minimal" },
        body: JSON.stringify({ posta_gitti: true }),
      });
    } catch { /* sessiz */ }
  }

  if (!kayitOk && !postaOk) return cevap(502, { success: false, kayit: false, posta: false, hata: "ne kasa ne posta calisti" }, origin);
  return cevap(200, { success: true, kayit: kayitOk, posta: postaOk }, origin);
});
