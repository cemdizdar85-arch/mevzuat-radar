// ============================================================================
//  NET-CEVAP Edge Function (Supabase)  —  soru → kaynak parçaları → Claude →
//  sade Türkçe, KAYNAĞA BAĞLI cevap. Kaynakta yoksa UYDURMAZ: kapsamda=false.
//  KURULUM (Cem): Supabase → Edge Functions → New function → adı: net-cevap →
//  bu dosyayı yapıştır → Deploy. Sonra Settings→Edge Functions→Secrets:
//  ANTHROPIC_API_KEY ekle. Function ayarında "Verify JWT" KAPAT.
// ============================================================================
const AK = (Deno.env.get("ANTHROPIC_API_KEY") ?? "").trim();
const SB_URL = "https://bjrleanjpyujtajmazxn.supabase.co";
const SB_ANON = Deno.env.get("SB_PUBLISHABLE") ?? "sb_publishable_kTZpYwrL7skw8Ryj5Vs8_Q_-5_Fhkcg"; // dokumanlar public-read; apikey ZORUNLU (yoksa 401)
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

// Türkçe diakritik katlama: kullanıcı çoğu kez şapkasız yazar (sirket~şirket,
// bagkur~bağkur, ortagi~ortağı). Eşleştirmede iki tarafı da ASCII'ye indir.
function fold(s: string): string {
  return s.replace(/ı/g, "i").replace(/ş/g, "s").replace(/ğ/g, "g").replace(/ü/g, "u").replace(/ö/g, "o").replace(/ç/g, "c").replace(/â/g, "a").replace(/î/g, "i").replace(/û/g, "u");
}
// Türkçe sondan-eklemeli morfoloji: token ile kaynak-kelime 5+ harf ortak
// önek paylaşıyorsa eşleşir ('girisini'~'giris', 'bildirmeliyim'~'bildirge').
function onekEslesir(t: string, kel: string[]): boolean {
  const tf = fold(t);
  for (const w of kel) {
    const wf = fold(w);
    const n = Math.min(tf.length, wf.length);
    const need = n >= 5 ? 5 : n;
    if (tf.slice(0, need) === wf.slice(0, need)) return true;
  }
  return false;
}
function skorla(tok: string[], hay: string): number {
  const kel = hay.split(" ").filter((w) => w.length >= 3);
  let s = 0;
  for (const t of tok) if (onekEslesir(t, kel)) s++;
  return s;
}

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
      const kayitlar = kb.kayitlar || [];
      // her kaydın kelime listesi (bir kez) + IDF: nadir kelime ağır, genel kelime hafif
      const korpus: string[][] = kayitlar.map((k: any) => norm((k.anahtar || "") + " " + (k.konu || "")).split(" ").filter((w: string) => w.length >= 3));
      const N = Math.max(1, korpus.length);
      const agirlik: Record<string, number> = {};
      for (const t of tok) { let dfc = 0; for (const kel of korpus) if (onekEslesir(t, kel)) dfc++; agirlik[t] = Math.log((N + 1) / (dfc + 1)) + 0.3; }
      const skorlu = kayitlar.map((k: any, i: number) => {
        let s = 0; for (const t of tok) if (onekEslesir(t, korpus[i])) s += agirlik[t];
        return { k, s };
      }).filter((x: any) => x.s > 0).sort((a: any, b: any) => b.s - a.s).slice(0, 6);
      for (const { k } of skorlu) parcalar.push({ ad: k.kaynak, metin: `${k.konu}: ${k.cevap}`, url: k.arac ? `${SITE}/${k.arac}` : undefined });
    } catch (_) { /* site erisilemezse devam */ }

    // b) bilgi ambarı (dokumanlar, FTS — public read)
    try {
      // puanli arama (madde_ara RPC): fold'lu kolon + OR + ts_rank -> en cok
      // eslesen madde one gelir; kullanici sapkasiz yazsa da kanun maddesi bulunur
      const fts = tok.slice(0, 8).map(fold).join(" ");
      if (fts) {
        const r = await fetch(`${SB_URL}/rest/v1/rpc/madde_ara`, {
          method: "POST",
          headers: { "content-type": "application/json", ...(SB_ANON ? { apikey: SB_ANON, Authorization: `Bearer ${SB_ANON}` } : {}) },
          body: JSON.stringify({ sorgu: fts, adet: 6 }),
        });
        if (r.ok) for (const d of await r.json()) parcalar.push({ ad: d.kaynak_ad + (d.belge_tarihi ? ` (${d.belge_tarihi})` : ""), metin: (d.baslik ? d.baslik + " — " : "") + String(d.metin).slice(0, 1200), url: d.kaynak_url });
      }
    } catch (_) { /* ambar bos olabilir */ }

    // c) günün kartları (en güncel katman)
    try {
      const g = await (await fetch(`${SITE}/veri/kartlar-guncel.json`)).json();
      for (const k of (g.kartlar || [])) {
        const hay = norm((k.baslik || "") + " " + (k.ne_oldu || ""));
        const s = skorla(tok, hay);
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
      body: JSON.stringify({ model: "claude-haiku-4-5-20251001", max_tokens: 700, messages: [{ role: "user", content: istem }] }),
    });
    if (!ai.ok) return json({ kapsamda: false, hata: "ai" }, 200);
    const at = (await ai.json()).content?.[0]?.text ?? "";
    const m = at.match(/\{[\s\S]*\}/);
    if (!m) return json({ kapsamda: false });
    const out = JSON.parse(m[0]);
    if (!out.kapsamda || !out.cevap) return json({ kapsamda: false });

    const secilen = (out.kaynak_no || []).map((n: number) => parcalar[n - 1]).filter(Boolean);
    const kaynaklar = secilen.map((p: any) => ({ ad: p.ad, url: p.url }));
    // GUVEN KATMANI: ozetin dayandigi HAM kaynak metni de dondur — kullanici asli gorur,
    // ozetleme hatasi olsa bile kaynak ortada (denetlenebilirlik).
    const alintilar = secilen.slice(0, 3).map((p: any) => ({ ad: p.ad, metin: String(p.metin).slice(0, 1200), url: p.url }));
    return json({ kapsamda: true, cevap: String(out.cevap).slice(0, 1500), kaynaklar, alintilar });
  } catch (e) {
    return json({ kapsamda: false, hata: String(e).slice(0, 120) }, 200);
  }
});

function json(o: unknown, s = 200) { return new Response(JSON.stringify(o), { status: s, headers: CORS }); }
