// ============================================================================
//  NET-CEVAP Edge Function (Supabase)  —  soru → kaynak parçaları → Claude →
//  sade Türkçe, KAYNAĞA BAĞLI cevap. Kaynakta yoksa UYDURMAZ: kapsamda=false.
//  KURULUM (Cem): Supabase → Edge Functions → New function → adı: net-cevap →
//  bu dosyayı yapıştır → Deploy. Sonra Settings→Edge Functions→Secrets:
//  ANTHROPIC_API_KEY ekle. Function ayarında "Verify JWT" KAPAT.
// ============================================================================
const AK = Deno.env.get("ANTHROPIC_API_KEY") ?? "";
const SB_URL = "https://bjrleanjpyujtajmazxn.supabase.co";
const SB_ANON = Deno.env.get("SB_PUBLISHABLE") ?? ""; // opsiyonel; dokumanlar public-read
const SITE = "https://cemdizdar85-arch.github.io/mevzuat-radar";
const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Content-Type": "application/json; charset=utf-8",
};

function norm(s: string): string {
  return (s || "").toLocaleLowerCase("tr-TR").replace(/\./g, "").replace(/[^\wğüşıöç\s]/gi, " ").replace(/\s+/g, " ").trim();
}
const STOP = new Set("vergi var varsa yok kac kaç ne nasil nasıl mi mı mu mü olur odeme ödeme sure süre suresi icin için ile bir bu kesilir geldi aldim aldım nedir kadar gibi daha cok çok hangi".split(" "));

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  try {
    const { soru } = await req.json();
    const q = String(soru || "").slice(0, 400);
    if (q.trim().length < 4) return json({ kapsamda: false, neden: "soru kisa" });

    // ---- 1) KAYNAK TOPLA -------------------------------------------------
    const parcalar: { ad: string; metin: string; url?: string }[] = [];
    const tok = norm(q).split(" ").filter((t) => t.length >= 3 && !STOP.has(t));

    // a) kürasyonlu bilgi tabanı (site, public)
    try {
      const kb = await (await fetch(`${SITE}/veri/bilgi-tabani.json`)).json();
      const skorlu = (kb.kayitlar || []).map((k: any) => {
        const hay = norm((k.anahtar || "") + " " + (k.konu || ""));
        let s = 0; tok.forEach((t) => { if (hay.includes(t)) s++; });
        return { k, s };
      }).filter((x: any) => x.s > 0).sort((a: any, b: any) => b.s - a.s).slice(0, 4);
      for (const { k } of skorlu) parcalar.push({ ad: k.kaynak, metin: `${k.konu}: ${k.cevap}`, url: k.arac ? `${SITE}/${k.arac}` : undefined });
    } catch (_) { /* site erisilemezse devam */ }

    // b) bilgi ambarı (dokumanlar, FTS — public read)
    try {
      const fts = tok.slice(0, 6).join(" | ");
      if (fts) {
        const r = await fetch(`${SB_URL}/rest/v1/dokumanlar?select=kaynak_ad,baslik,metin,kaynak_url,belge_tarihi&arama=wfts(simple).${encodeURIComponent(fts)}&limit=4`,
          { headers: SB_ANON ? { apikey: SB_ANON, Authorization: `Bearer ${SB_ANON}` } : {} });
        if (r.ok) for (const d of await r.json()) parcalar.push({ ad: d.kaynak_ad + (d.belge_tarihi ? ` (${d.belge_tarihi})` : ""), metin: (d.baslik ? d.baslik + " — " : "") + String(d.metin).slice(0, 1200), url: d.kaynak_url });
      }
    } catch (_) { /* ambar bos olabilir */ }

    // c) günün kartları (en güncel katman)
    try {
      const g = await (await fetch(`${SITE}/veri/kartlar-guncel.json`)).json();
      for (const k of (g.kartlar || [])) {
        const hay = norm((k.baslik || "") + " " + (k.ne_oldu || ""));
        let s = 0; tok.forEach((t) => { if (hay.includes(t)) s++; });
        if (s >= 2) parcalar.push({ ad: `Resmî Gazete ${g.gun || ""}`, metin: `${k.baslik}. ${k.ne_oldu}`, url: k.url });
      }
    } catch (_) {}

    // ---- 2) KAYNAK YOKSA: uydurmadan, LLM'siz dur ------------------------
    if (!parcalar.length) return json({ kapsamda: false });

    // ---- 3) CLAUDE: yalnız bu parçalardan, sade Türkçe -------------------
    const kaynakMetni = parcalar.slice(0, 8).map((p, i) => `[${i + 1}] (${p.ad}) ${p.metin}`).join("\n\n");
    const istem = `Sen Türkiye'nin en titiz mevzuat danışma servisinin cevap motorusun.
KURALLAR (ihlal edilemez):
1) YALNIZ aşağıdaki KAYNAK PARÇALARINDAN cevap ver. Parçalarda cevabı olmayan hiçbir bilgi, rakam, oran, süre YAZMA. Cevap parçalarda yoksa sadece {"kapsamda":false} döndür.
2) Sade Türkçe — muhasebe bilmeyen biri anlasın ('annem anlar mı' testi). Zorunlu terimi tek parantezle açıkla. 3-6 kısa cümle; net, kesin, samimi ama ciddi.
3) Yasak: "unutmayın", "önemlidir", "dikkat edilmelidir", "bu bağlamda", "söz konusu", ünlem, yapay dolgu.
4) Yorum katma; olguyu söyle. Karşındaki EN GÜNCEL cevabı bekliyor — tereddüt dili yok.
SADECE geçerli JSON döndür: {"kapsamda":true,"cevap":"...", "kaynak_no":[1,2]}

SORU: ${q}

KAYNAK PARÇALARI:
${kaynakMetni}`;

    const ai = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: { "x-api-key": AK, "anthropic-version": "2023-06-01", "content-type": "application/json" },
      body: JSON.stringify({ model: "claude-haiku-4-5", max_tokens: 700, messages: [{ role: "user", content: istem }] }),
    });
    if (!ai.ok) return json({ kapsamda: false, hata: "ai" }, 200);
    const at = (await ai.json()).content?.[0]?.text ?? "";
    const m = at.match(/\{[\s\S]*\}/);
    if (!m) return json({ kapsamda: false });
    const out = JSON.parse(m[0]);
    if (!out.kapsamda || !out.cevap) return json({ kapsamda: false });

    const kaynaklar = (out.kaynak_no || []).map((n: number) => parcalar[n - 1]).filter(Boolean)
      .map((p: any) => ({ ad: p.ad, url: p.url }));
    return json({ kapsamda: true, cevap: String(out.cevap).slice(0, 1500), kaynaklar });
  } catch (e) {
    return json({ kapsamda: false, hata: String(e).slice(0, 120) }, 200);
  }
});

function json(o: unknown, s = 200) { return new Response(JSON.stringify(o), { status: s, headers: CORS }); }
