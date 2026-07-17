// ============================================================================
//  BEYANNAME-OKU Edge Function (Supabase) — fotoğraf/taranmış gümrük
//  beyannamesini Claude vision ile okur, yapılandırılmış alan döndürür.
//  YALNIZ kullanıcı sitede "yapay zekâ ile okut (onaylıyorum)" dediğinde çağrılır
//  (kademeli gizlilik: metin-PDF tarayıcıda okunur, buraya HİÇ gelmez).
//  Görsel işlenir, YANIT döner, SAKLANMAZ. KURULUM: New function → beyanname-oku
//  → bu dosyayı yapıştır → Deploy → "Verify JWT" KAPAT. Secret: ANTHROPIC_API_KEY.
// ============================================================================
const AK = (Deno.env.get("ANTHROPIC_API_KEY") ?? "").trim();
const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Content-Type": "application/json; charset=utf-8",
};
function json(o: unknown, s = 200) { return new Response(JSON.stringify(o), { status: s, headers: CORS }); }

// site ULKE_GRUP eşlemesiyle aynı mantık — model ISO/ad döndürür, burada gruba çevrilir
const ISO_GRUP: Record<string, string> = { CN:"du", JP:"du", IN:"du", RU:"du", TW:"du", ID:"du", VN:"du", TH:"du", DE:"abSta", IT:"abSta", FR:"abSta", ES:"abSta", NL:"abSta", BE:"abSta", PL:"abSta", GB:"abSta", IL:"abSta", KR:"abSta", RS:"abSta", MA:"abSta", EG:"abSta", TN:"abSta", US:"abd" };

// RATE LIMIT: vision çağrısı pahalı — IP başına 60 sn'de en fazla 6 istek.
const RL = new Map<string, number[]>();
function rlAsti(ip: string): boolean {
  const now = Date.now(), P = 60000, L = 6;
  const arr = (RL.get(ip) || []).filter((t) => now - t < P);
  if (arr.length >= L) { RL.set(ip, arr); return true; }
  arr.push(now); RL.set(ip, arr);
  if (RL.size > 5000) { for (const [k, v] of RL) { if (!v.some((t) => now - t < P)) RL.delete(k); } }
  return false;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  const ip = (req.headers.get("x-forwarded-for") || "").split(",")[0].trim() || "anon";
  if (rlAsti(ip)) return json({ hata: "cok fazla istek — biraz sonra tekrar dene" }, 429);
  try {
    const { resim, tur } = await req.json();
    if (!resim || typeof resim !== "string") return json({ hata: "resim yok" }, 400);
    const media = (tur && /^image\/(png|jpe?g|webp|gif)$/.test(tur)) ? tur : "image/jpeg";
    // taranmış PDF de gelebilir; Claude PDF'i document olarak alır, görseli image olarak
    const pdfMi = tur === "application/pdf";
    const kaynak = pdfMi
      ? { type: "document", source: { type: "base64", media_type: "application/pdf", data: resim } }
      : { type: "image", source: { type: "base64", media_type: media, data: resim } };

    const istem = `Bu bir Türk gümrük beyannamesi (Tek İdari Belge) görüntüsü. SADECE şu alanları oku ve JSON döndür:
- gtip: 33 no.lu kutudaki GTİP kodu (12 hane, "1234.56.78.90.12" formatında; birden çok kalem varsa İLKİ)
- ulkeIso: 34 no.lu menşe ülke kodu (2 harf ISO, ör. CN, DE) — yoksa null
- ulkeAd: menşe ülke adı (ör. Çin) — yoksa null
- kiymet: fatura/istatistiki kıymet tutarı (sadece tam sayı, ondalık ve ayraç olmadan) — yoksa null
Okuyamadığın alanı null bırak. UYDURMA. Yalnız geçerli JSON: {"gtip":...,"ulkeIso":...,"ulkeAd":...,"kiymet":...}`;

    const ai = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: { "x-api-key": AK, "anthropic-version": "2023-06-01", "content-type": "application/json" },
      body: JSON.stringify({
        model: "claude-haiku-4-5-20251001",
        max_tokens: 300,
        messages: [{ role: "user", content: [kaynak, { type: "text", text: istem }] }],
      }),
    });
    if (!ai.ok) return json({ hata: "ai" }, 200);
    const txt = (await ai.json()).content?.[0]?.text ?? "";
    const mm = txt.match(/\{[\s\S]*\}/);
    if (!mm) return json({ hata: "cozulemedi" }, 200);
    const out = JSON.parse(mm[0]);

    // grup eşlemesi (site select değeri)
    let ulkeGrup: string | null = null;
    if (out.ulkeIso && ISO_GRUP[String(out.ulkeIso).toUpperCase()]) ulkeGrup = ISO_GRUP[String(out.ulkeIso).toUpperCase()];
    const kiymet = out.kiymet != null && /^\d+$/.test(String(out.kiymet)) ? parseInt(String(out.kiymet), 10) : null;
    const gtip = out.gtip && /^\d{4}\.\d{2}\.\d{2}\.\d{2}\.\d{2}$/.test(String(out.gtip)) ? String(out.gtip) : null;
    return json({ gtip, ulkeGrup, ulkeAd: out.ulkeAd ?? out.ulkeIso ?? null, kiymet });
  } catch (e) {
    return json({ hata: String(e).slice(0, 120) }, 200);
  }
});
