// ============================================================================
//  KARNE-GÖNDER Edge Function (Supabase) — seviye testi karnesini ÖĞRENCİNİN
//  kendi e-postasına gönderir.
//
//  NEDEN VAR (13.09.2026, Cem): "e-posta işlemini yapalım; şu an yok diye bir
//  şey önermemezlik yapma." Mevcut form kapısı (form-al.ts, canlı adı quick-task)
//  maili YALNIZ bize atıyor. O kapıya dokunulmadı; bu ayrı fonksiyon kuruldu.
//
//  SPAM KAPISI OLMASIN DİYE (bu fonksiyon dışarıya, kullanıcının yazdığı adrese mail atıyor):
//    - Mail İÇERİĞİ SUNUCUDA kurulur. Tarayıcıdan yalnız SAYILAR ve bilinen grup
//      adları gelir; serbest metin/HTML kabul edilmez -> kimse bu uçla başkasına
//      kendi yazdığı mesajı gönderemez.
//    - Köken listesi (tetikte.com + yerel geliştirme), bal küpü (_hp).
//    - Hız: IP başına 10 dk'da 5 (rate_limit_check RPC, form-al ile aynı) +
//      AYNI E-POSTAYA 24 saatte en çok 3 karne (form_kayit sayımı).
//    - KVKK onayı (kvkk:true) olmadan gönderilmez. Kampanya/hatırlatma izni AYRI
//      kutu (izin_ileti) - yalnız kaydedilir, bu fonksiyon kampanya maili ATMAZ.
//  KAYIT: form_kayit tablosuna (konu "Seviye testi karnesi") - IP yazılmaz.
//
//  API: POST {eposta, kvkk:true, izin_ileti:bool, sinav:"sgs",
//             sonuc:{gecme:5..95, dogru130:0..130, soru:1..40, dogru:0..soru,
//                    gruplar:[{ad:<GRUP_ADLARI>, dogru, soru}]}, _hp?}
//       -> 200 {success:true, posta:bool, kayit:bool}
//  TEŞHİS: ?tani=1 -> secret tanımlı mı (değer DÖNMEZ).
//  YAYIN: Supabase panel -> Edge Functions -> yeni fonksiyon "karne-gonder" -> bu dosya.
//         Secrets form-al ile ORTAK (RESEND_KEY, RESEND_FROM; SUPABASE_* otomatik).
// ============================================================================

export const GRUP_ADLARI = ["Muhasebe", "Hukuk", "Ekonomi ve Maliye", "Genel Kültür ve Yabancı Dil"];
export const IZINLI_KOKEN = new Set(["https://tetikte.com", "https://www.tetikte.com"]);
const YEREL_KOKEN = /^http:\/\/(localhost|127\.0\.0\.1)(:\d{1,5})?$/;
export function kokenIzinli(o: string | null): boolean { return !!o && (IZINLI_KOKEN.has(o) || YEREL_KOKEN.test(o)); }
export function epostaGecerli(e: string): boolean { return /^[^\s@]{1,64}@[^\s@]{1,190}\.[^\s@]{2,}$/.test(e) && e.length <= 254; }
function tamsayi(v: unknown, alt: number, ust: number): number | null {
  return (typeof v === "number" && Number.isInteger(v) && v >= alt && v <= ust) ? v : null;
}
function kacis(s: string): string { return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;"); }

export type Sonuc = { gecme: number; dogru130: number; soru: number; dogru: number; gruplar: { ad: string; dogru: number; soru: number }[] };

// Doğrulama: yalnız sayılar ve bilinen grup adları. Hata varsa null + neden.
export function dogrula(veri: any): { ok: true; eposta: string; izin: boolean; sonuc: Sonuc } | { ok: false; neden: string } {
  if (!veri || typeof veri !== "object" || Array.isArray(veri)) return { ok: false, neden: "nesne degil" };
  const eposta = String(veri.eposta ?? "").trim().toLowerCase();
  if (!epostaGecerli(eposta)) return { ok: false, neden: "e-posta bicimi gecersiz" };
  if (veri.kvkk !== true) return { ok: false, neden: "kvkk onayi yok" };
  if (veri.sinav !== "sgs") return { ok: false, neden: "sinav desteklenmiyor" };
  const s = veri.sonuc ?? {};
  const soru = tamsayi(s.soru, 1, 40);
  const gecme = tamsayi(s.gecme, 5, 95), dogru130 = tamsayi(s.dogru130, 0, 130);
  const dogru = soru === null ? null : tamsayi(s.dogru, 0, soru);
  if (soru === null || gecme === null || dogru130 === null || dogru === null) return { ok: false, neden: "sonuc sayilari gecersiz" };
  if (!Array.isArray(s.gruplar) || s.gruplar.length < 1 || s.gruplar.length > GRUP_ADLARI.length) return { ok: false, neden: "gruplar gecersiz" };
  const gruplar: Sonuc["gruplar"] = [];
  const gorulen = new Set<string>();
  let toplamSoru = 0, toplamDogru = 0;
  for (const g of s.gruplar) {
    if (!g || !GRUP_ADLARI.includes(g.ad) || gorulen.has(g.ad)) return { ok: false, neden: "grup adi gecersiz" };
    const gs = tamsayi(g.soru, 1, 40); const gd = gs === null ? null : tamsayi(g.dogru, 0, gs);
    if (gs === null || gd === null) return { ok: false, neden: "grup sayilari gecersiz" };
    gorulen.add(g.ad); gruplar.push({ ad: g.ad, dogru: gd, soru: gs }); toplamSoru += gs; toplamDogru += gd;
  }
  if (toplamSoru !== soru || toplamDogru !== dogru) return { ok: false, neden: "grup toplami tutmuyor" };
  return { ok: true, eposta, izin: veri.izin_ileti === true, sonuc: { gecme, dogru130, soru, dogru, gruplar } };
}

// Mail içeriği TAMAMEN sunucuda: kullanıcı metni yok, yalnız doğrulanmış sayılar.
export function mailKur(s: Sonuc): { konu: string; metin: string; html: string } {
  const seviye = s.gecme >= 70 ? "Hazıra yakınsın" : s.gecme >= 40 ? "Sınırdasın" : "Bugün girsen zorlanırsın";
  const oneri = s.gecme >= 70
    ? "130 soruluk \"Sınav gibi çöz\" denemesiyle bu sonucu doğrula: gerçek süre, gerçek ders dağılımı."
    : s.gecme >= 40
      ? "Seni geçirecek şey birkaç fazla doğru. En zayıf grubundan başla; her yanlışını Nöbetçi adım adım anlatır."
      : "Sınava zaman var. En zayıf grubundan başla; yanlışların kutuna düşer, 2 gün sonra yeniden karşına çıkar.";
  const enZayif = s.gruplar.slice().sort((a, b) => a.dogru / a.soru - b.dogru / b.soru)[0];
  const satirlar = s.gruplar.map(g => `${g.ad}: ${g.dogru} / ${g.soru}`).join("\n");
  const site = "https://tetikte.com";
  const metin = [
    `Tetikte seviye testi karnen - Staja Giriş`,
    ``,
    `Geçme ihtimalin: %${s.gecme} (${seviye})`,
    `130 soruluk sınavda tahmini doğru sayın: yaklaşık ${s.dogru130}`,
    `Bu testte: ${s.dogru} / ${s.soru} doğru`,
    ``,
    satirlar,
    ``,
    `En çok çalışman gereken grup: ${enZayif.ad}`,
    oneri,
    ``,
    `Tam soru bankası, deneme setleri ve "sınav gibi" süreli mod pakette; bu testteki yanlışlarının adım adım anlatımı da orada.`,
    `Tam bankayı aç: ${site}/satin-al.html?paket=sgs`,
    `Önce örnek soruları çöz (ücretsiz): ${site}/kaydir/vitrin/sgs.html`,
    `Testi yeniden çöz: ${site}/seviye-testi.html`,
    ``,
    `Nasıl hesaplandı? Bu bir TAHMİNDİR. Staja Giriş'te puan bağıl hesaplanır ve geçme sınırı her dönem değişir; resmî sınır yayımlanmaz. Tahmin, bu testteki cevaplarından ve TESMER yönergesindeki "%80 doğruyla geçilen, %60 doğruyla kalınan sınavlar oldu" bilgisine dayanan bir sınır varsayımından hesaplanır. Ayrıntı: ${site}/seviye-testi.html#nasil`,
    ``,
    `Bu e-postayı, seviye testinin sonunda karneni istediğin için aldın. Tetikte - Dizdar Denetim Danışmanlık ve Yazılım A.Ş. · info@dizdardenetim.com · Kişisel verilerin: ${site}/kvkk.html`,
  ].join("\n");
  const g = s.gruplar.map(x => `<tr><td style="padding:6px 10px;border-bottom:1px solid #e5e7eb">${kacis(x.ad)}</td><td style="padding:6px 10px;border-bottom:1px solid #e5e7eb;text-align:right">${x.dogru} / ${x.soru}</td></tr>`).join("");
  const html = `<div style="font-family:system-ui,-apple-system,Segoe UI,sans-serif;font-size:15px;line-height:1.55;color:#16191d;max-width:560px">
<p style="font-size:12px;letter-spacing:.12em;text-transform:uppercase;color:#8d6c38;font-weight:700;margin:0 0 6px">Tetikte · Staja Giriş seviye testi</p>
<h1 style="font-size:26px;margin:0 0 4px">Geçme ihtimalin: %${s.gecme}</h1>
<p style="margin:0 0 14px;color:#4b5563">${kacis(seviye)} · 130 soruda tahmini doğru: yaklaşık <b>${s.dogru130}</b> · bu testte ${s.dogru} / ${s.soru}</p>
<table style="border-collapse:collapse;width:100%;margin:0 0 14px">${g}</table>
<p style="margin:0 0 6px"><b>En çok çalışman gereken grup:</b> ${kacis(enZayif.ad)}</p>
<p style="margin:0 0 16px">${kacis(oneri)}</p>
<p style="margin:0 0 10px">Tam soru bankası, deneme setleri ve "sınav gibi" süreli mod pakette; bu testteki yanlışlarının adım adım anlatımı da orada.</p>
<p style="margin:0 0 18px"><a href="${site}/satin-al.html?paket=sgs" style="background:#cfa163;color:#221704;text-decoration:none;font-weight:700;padding:10px 16px;border-radius:8px;display:inline-block">Tam bankayı aç →</a>
&nbsp; <a href="${site}/kaydir/vitrin/sgs.html" style="color:#8d6c38;font-weight:700">Önce örnek soruları çöz (ücretsiz)</a></p>
<p style="font-size:12.5px;color:#6b7280;margin:0 0 10px"><b>Nasıl hesaplandı?</b> Bu bir tahmindir. Staja Giriş'te puan bağıl hesaplanır ve geçme sınırı her dönem değişir; resmî sınır yayımlanmaz. Tahmin, cevaplarından ve TESMER yönergesindeki "%80 doğruyla geçilen, %60 doğruyla kalınan sınavlar oldu" bilgisine dayanan bir sınır varsayımından hesaplanır. <a href="${site}/seviye-testi.html#nasil" style="color:#6b7280">Ayrıntı</a></p>
<p style="font-size:12px;color:#9ca3af;margin:0">Bu e-postayı, seviye testinin sonunda karneni istediğin için aldın. Tetikte · Dizdar Denetim Danışmanlık ve Yazılım A.Ş. · info@dizdardenetim.com · <a href="${site}/kvkk.html" style="color:#9ca3af">Kişisel verilerin</a></p>
</div>`;
  return { konu: `Seviye testi karnen: geçme ihtimalin %${s.gecme}`, metin, html };
}

// ---------------------------------------------------------------------------
// Sunucu bölümü yalnız Deno'da çalışır (Node'daki öz-sınav bu kısmı atlar).
const Deno: any = (globalThis as any).Deno;
// Kod imzası: arac/edge-imza.js --yaz yazar, ELLE DEĞİŞTİRME. ?surum=1 bunu döndürür; motor/edge-nobetcisi.js canlıyla depoyu bununla kıyaslar.
const KOD_IMZA = "05689ba2c711c316";

if (Deno && Deno.serve) {
  const SB_URL = (Deno.env.get("SUPABASE_URL") ?? "https://bjrleanjpyujtajmazxn.supabase.co").replace(/\/$/, "");
  const SB_SERVICE = (Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "").trim();
  const SB_ANON = (Deno.env.get("SUPABASE_ANON_KEY") ?? "").trim();
  const RESEND_KEY = (Deno.env.get("RESEND_KEY") ?? "").trim();
  const RESEND_FROM = (Deno.env.get("RESEND_FROM") ?? "Tetikte <bildirim@tetikte.com>").trim();
  const KONU = "Seviye testi karnesi";

  const cors = (origin: string | null) => ({
    "Access-Control-Allow-Origin": kokenIzinli(origin) ? (origin as string) : "https://tetikte.com",
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, accept",
    "Access-Control-Allow-Methods": "POST, OPTIONS", "Vary": "Origin", "Content-Type": "application/json; charset=utf-8",
  });
  const cevap = (d: number, g: unknown, o: string | null) => new Response(JSON.stringify(g), { status: d, headers: cors(o) });

  async function hizAsti(ip: string): Promise<boolean> {
    if (!ip || ip === "anon" || !SB_ANON) return false;
    try {
      const r = await fetch(`${SB_URL}/rest/v1/rpc/rate_limit_check`, { method: "POST",
        headers: { "content-type": "application/json", apikey: SB_ANON, Authorization: `Bearer ${SB_ANON}` },
        body: JSON.stringify({ p_ip: ip, p_limit: 5, p_pencere_sn: 600 }) });
      if (!r.ok) return false; return (await r.json()) === false;
    } catch { return false; }
  }
  async function epostaSiniri(eposta: string): Promise<boolean> {
    if (!SB_SERVICE) return false;
    try {
      const once = new Date(Date.now() - 24 * 3600 * 1000).toISOString();
      const r = await fetch(`${SB_URL}/rest/v1/form_kayit?select=konu&konu=eq.${encodeURIComponent(KONU)}&eposta=eq.${encodeURIComponent(eposta)}&olusturma=gte.${encodeURIComponent(once)}`,
        { headers: { apikey: SB_SERVICE, Authorization: `Bearer ${SB_SERVICE}` } });
      if (!r.ok) return false; const satir = await r.json(); return Array.isArray(satir) && satir.length >= 3;
    } catch { return false; }
  }
  async function kasayaYaz(kayit: Record<string, unknown>): Promise<boolean> {
    if (!SB_SERVICE) return false;
    try {
      const r = await fetch(`${SB_URL}/rest/v1/form_kayit`, { method: "POST",
        headers: { "content-type": "application/json", apikey: SB_SERVICE, Authorization: `Bearer ${SB_SERVICE}`, Prefer: "return=minimal" },
        body: JSON.stringify(kayit) });
      return r.status === 201;
    } catch { return false; }
  }

  Deno.serve(async (req: Request) => {
    const origin = req.headers.get("origin");
    if (req.method === "OPTIONS") return new Response(null, { status: 204, headers: cors(origin) });
    // 15.09 SÜRÜM UCU: kimlik/köken/hız sınırından ÖNCE; ücretli çağrı yapmaz, veri döndürmez.
    if (new URL(req.url).searchParams.get("surum") === "1") return new Response(JSON.stringify({ surum: KOD_IMZA }), { status: 200, headers: { "Content-Type": "application/json; charset=utf-8", "Access-Control-Allow-Origin": "*" } });
    if (new URL(req.url).searchParams.get("tani") === "1") {
      return cevap(200, { tani: true, secret_tanimli: { RESEND_KEY: !!RESEND_KEY, RESEND_FROM: !!Deno.env.get("RESEND_FROM"), SERVICE_ROLE: !!SB_SERVICE, ANON: !!SB_ANON } }, origin);
    }
    if (req.method !== "POST") return cevap(405, { success: false, hata: "yalniz POST" }, origin);
    if (!kokenIzinli(origin)) return cevap(403, { success: false, hata: "koken izinli degil" }, origin);
    const ham = await req.text();
    if (ham.length > 4096) return cevap(413, { success: false, hata: "govde cok buyuk" }, origin);
    let veri: any; try { veri = JSON.parse(ham); } catch { return cevap(400, { success: false, hata: "json degil" }, origin); }
    if (veri && (veri._hp || veri.botcheck)) return cevap(200, { success: true, posta: false, kayit: false }, origin);
    const d = dogrula(veri);
    if (!d.ok) return cevap(400, { success: false, hata: d.neden }, origin);
    const ip = (req.headers.get("x-forwarded-for") || "").split(",")[0].trim() || "anon";
    if (await hizAsti(ip)) return cevap(429, { success: false, hata: "cok sik gonderi, biraz sonra dene" }, origin);
    if (await epostaSiniri(d.eposta)) return cevap(429, { success: false, hata: "bu adrese bugun yeterince karne gonderildi" }, origin);
    if (!RESEND_KEY) return cevap(503, { success: false, hata: "posta anahtari tanimli degil" }, origin);

    const m = mailKur(d.sonuc);
    let postaOk = false;
    try {
      const r = await fetch("https://api.resend.com/emails", { method: "POST",
        headers: { Authorization: `Bearer ${RESEND_KEY}`, "content-type": "application/json" },
        body: JSON.stringify({ from: RESEND_FROM, to: [d.eposta], subject: m.konu, text: m.metin, html: m.html }) });
      postaOk = r.ok;
    } catch { postaOk = false; }

    const kayitOk = await kasayaYaz({ konu: KONU, gonderen: "Seviye testi", eposta: d.eposta, sayfa: req.headers.get("referer")?.slice(0, 300) ?? null, koken: origin,
      alanlar: { "Geçme ihtimali": `%${d.sonuc.gecme}`, "Tahmini doğru (130)": String(d.sonuc.dogru130), "Test": `${d.sonuc.dogru}/${d.sonuc.soru}`,
        "Gruplar": d.sonuc.gruplar.map(g => `${g.ad} ${g.dogru}/${g.soru}`).join(" · "), "KVKK onayı": "evet", "Kampanya/hatırlatma izni": d.izin ? "evet" : "hayır",
        "Karne maili": postaOk ? "gitti" : "GİTMEDİ" } });

    if (!postaOk) return cevap(502, { success: false, posta: false, kayit: kayitOk, hata: "posta gonderilemedi" }, origin);
    return cevap(200, { success: true, posta: true, kayit: kayitOk }, origin);
  });
}
