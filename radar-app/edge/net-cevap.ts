// ============================================================================
//  NET-CEVAP Edge Function (Supabase)  —  soru → kaynak parçaları → Claude →
//  sade Türkçe, KAYNAĞA BAĞLI cevap. Kaynakta yoksa UYDURMAZ: kapsamda=false.
//  KURULUM (Cem): Supabase → Edge Functions → New function → adı: net-cevap →
//  bu dosyayı yapıştır → Deploy. Sonra Settings→Edge Functions→Secrets:
//  ANTHROPIC_API_KEY ekle. Function ayarında "Verify JWT" KAPAT.
//  21.08 EK: yedek hat için ikinci secret → OPENROUTER_KEY (GitHub Actions'ta
//  aynı adla zaten var; Supabase'e de eklenmeli — iki yer ayrı kasadır).
//  TEŞHİS: curl "https://<proje>.supabase.co/functions/v1/net-cevap?tani=1"
//  → hangi anahtar tanımlı (yalnız true/false) + hangi hat ne dönüyor.
// ============================================================================
// ---- 21.08.2026 ONARIM ----------------------------------------------------
// Beyin 21.08'de OLU bulundu: her soruya {"kapsamda":false,"hata":"ai"} donuyordu.
// Uc kusur olculdu ve uculu de burada kapatildi:
//  1) HATA SESSIZDI. "ai" tek kelimesi 401 mi, 429 mi, kota mi ayirt etmiyordu;
//     teshis icin fonksiyonu konusturmak gerekti (asagida ust-akis kodu +
//     hata tipi donuyor; ANAHTAR ASLA DONMEZ).
//  2) YEDEK HAT YOKTU. Depoda motor/api-hedef.ps1 zaten anthropic->aws->
//     openrouter geri dususunu yapiyor; Edge Function tek hatta kalmisti.
//     Artik Anthropic olurse OpenRouter'a duser (OpenAI bicimi, ayri govde).
//  3) LLM OLUNCE HER SEY OLUYORDU. Oysa kaynaklar BULUNMUS oluyor. Artik
//     ozetleyici olurse ham kaynak "ozetlenmedi" etiketiyle donuyor - sayfanin
//     yerel motoru yalnizca 403 kayit gorurken ambar 13 binden fazla madde
//     goruyor; olu beyin bile yerelden iyidir.
const AK = (Deno.env.get("ANTHROPIC_API_KEY") ?? "").trim();
const ORK = (Deno.env.get("OPENROUTER_KEY") ?? "").trim();
const SB_URL = "https://bjrleanjpyujtajmazxn.supabase.co";
const SB_ANON = Deno.env.get("SB_PUBLISHABLE") ?? "sb_publishable_kTZpYwrL7skw8Ryj5Vs8_Q_-5_Fhkcg"; // dokumanlar public-read; apikey ZORUNLU (yoksa 401)
const SITE = "https://tetikte.com";
const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Content-Type": "application/json; charset=utf-8",
};

function norm(s: string): string {
  return (s || "").toLocaleLowerCase("tr-TR").replace(/\./g, "").replace(/[^\wğüşıöç\s]/gi, " ").replace(/\s+/g, " ").trim();
}
// NOT (17.07.2026): 'vergi' STOP'tan CIKARILDI — kucuk bilgi tabaninda gurultuydu,
// 13k maddelik ambarda ayirt edici ('anayasada vergi odevi' m.73'u bulamiyordu).
const STOP = new Set("var varsa yok kac kaç ne nasil nasıl mi mı mu mü olur odeme ödeme sure süre suresi icin için ile bir bu kesilir geldi aldim aldım nedir kadar gibi daha cok çok hangi".split(" "));

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

// RATE LIMIT (maliyet + kötüye kullanım koruması): her çağrı Claude API'ye para.
// Postgres MERKEZİ sayaç (rate_limit_check RPC) — tüm edge isolate'leri aynı
// sayacı görür (in-memory'nin isolate-dağılımı zaafı yok). IP başına 60 sn'de 12.
// Fail-open: RPC hata verirse engellemez (kullanıcıyı mağdur etmez).
async function rlAsti(ip: string): Promise<boolean> {
  if (!ip || ip === "anon") return false;
  try {
    const r = await fetch(`${SB_URL}/rest/v1/rpc/rate_limit_check`, {
      method: "POST",
      headers: { "content-type": "application/json", apikey: SB_ANON, Authorization: `Bearer ${SB_ANON}` },
      body: JSON.stringify({ p_ip: ip, p_limit: 12, p_pencere_sn: 60 }),
    });
    if (!r.ok) return false;
    return (await r.json()) === false;   // RPC true=izin, false=limit aşıldı → rlAsti true=engelle
  } catch { return false; }
}

// ---- OZETLEYICI: once Anthropic, olurse OpenRouter --------------------------
// Donen: {metin} basarili | {hataKod, hataTip} basarisiz. ANAHTAR HIC DONMEZ.
type OzetSonuc = { metin?: string; hataKod?: number; hataTip?: string; hat?: string };

async function ustAkisHata(r: Response): Promise<string> {
  // Ust akisin hata GOVDESINDEN yalnizca tip/mesaj alanini al. Govde anahtar
  // icermez ama yine de 160 karakterle kirpilir ve dogrudan disari verilmez.
  try {
    const j = await r.json();
    return String(j?.error?.type || j?.error?.code || j?.error?.message || "").slice(0, 160);
  } catch { return ""; }
}

async function ozetle(istem: string): Promise<OzetSonuc> {
  let anKod = -1;
  let anTip = "ANTHROPIC_API_KEY yok";

  // 1) Anthropic (dogrudan hat)
  if (AK) {
    try {
      const r = await fetch("https://api.anthropic.com/v1/messages", {
        method: "POST",
        headers: { "x-api-key": AK, "anthropic-version": "2023-06-01", "content-type": "application/json" },
        body: JSON.stringify({ model: "claude-haiku-4-5-20251001", max_tokens: 700, messages: [{ role: "user", content: istem }] }),
      });
      if (r.ok) {
        const t = (await r.json()).content?.[0]?.text ?? "";
        if (t) return { metin: t, hat: "anthropic" };
        anKod = 200; anTip = "bos cevap";
      } else {
        anKod = r.status; anTip = await ustAkisHata(r);
      }
    } catch (e) { anKod = 0; anTip = String(e).slice(0, 80); }
  }

  // 2) OpenRouter (yedek hat) — OpenAI bicimi: /chat/completions, Bearer,
  //    model adi nokta ile, cevap choices[0].message.content
  if (!ORK) return { hataKod: anKod, hataTip: `an:${anKod}/${anTip} | OPENROUTER_KEY yok` };
  try {
    const r = await fetch("https://openrouter.ai/api/v1/chat/completions", {
      method: "POST",
      headers: { Authorization: `Bearer ${ORK}`, "X-Title": "Tetikte", "content-type": "application/json" },
      body: JSON.stringify({ model: "anthropic/claude-haiku-4.5", max_tokens: 700, messages: [{ role: "user", content: istem }] }),
    });
    if (r.ok) {
      const t = (await r.json()).choices?.[0]?.message?.content ?? "";
      if (t) return { metin: t, hat: "openrouter" };
      return { hataKod: 200, hataTip: `or:bos cevap | an:${anKod}/${anTip}` };
    }
    return { hataKod: r.status, hataTip: `or:${await ustAkisHata(r)} | an:${anKod}/${anTip}` };
  } catch (e) {
    return { hataKod: 0, hataTip: `or:${String(e).slice(0, 60)} | an:${anKod}/${anTip}` };
  }
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });

  // ---- TANI UCU: /net-cevap?tani=1 -----------------------------------------
  // Hangi anahtarin TANIMLI oldugunu (yalniz true/false) ve her hattin ne
  // dondugunu soyler. Anahtarin kendisi, on eki, uzunlugu HIC donmez.
  // 21.08'de bu uc olmadigi icin "hata:ai" tek kelimesiyle korlestik.
  const url = new URL(req.url);
  if (url.searchParams.get("tani") === "1") {
    const t = await ozetle('SADECE su JSON\'u dondur: {"kapsamda":true,"cevap":"tani","kaynak_no":[1]}');
    return json({
      tani: true,
      anahtar_tanimli: { ANTHROPIC_API_KEY: !!AK, OPENROUTER_KEY: !!ORK },
      ozetleyici: t.metin ? { calisiyor: true, hat: t.hat } : { calisiyor: false, kod: t.hataKod, tip: t.hataTip },
    });
  }

  const ip = (req.headers.get("x-forwarded-for") || "").split(",")[0].trim() || "anon";
  if (await rlAsti(ip)) return json({ kapsamda: false, neden: "cok fazla istek — biraz sonra tekrar dene" }, 429);
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
      // KURUM TAKMA ADI: kullanici 'SGK' der ama 5510/SSIY metni 'Kurum/sigortali/
      // prim' der ('sgk' kelimesi tam tersine KDV GUT mahsup bolumunde gecer) —
      // RPC sorgusunda kisaltma, kanunun kendi diline cevrilir. YALNIZ ambar
      // sorgusu icin: bilgi-tabani anahtarlarinda 'sgk' literal gectiginden
      // oradaki eslesmeye dokunulmaz.
      const ALIAS: Record<string, string[]> = { sgk: ["sigortali", "sosyal", "prim"] };
      // ---------------------------------------------------------------------
      // TURKCE EK SOYMA (25.08.2026) — OLCULEREK SECILDI.
      // Sorun: kullanici cekimli yazar ("ticaret siciline"), kanun metni kok
      // halinde durur ("sicil"). to_tsquery prefix'i ('kelime:*') yalniz SAGA
      // genisler, yani sorgudaki EK belgeyi bulmayi ENGELLER. Kokle aramak
      // kapsami GENISLETIR: 'sicil:*' hem sicili hem siciline hem sicilinde.
      //
      // arac/sirala-tarti.ps1 -Dil ile 48 altin vaka uzerinde UCTAN UCA olculdu:
      //     mevcut 41/48 · genis durak listesi 41 (+0) ·
      //     EK SOYMA kok>=5 -> 44 (+3) SECILEN · kok>=4 -> 40 (-1)
      // kok>=4'un tabanin ALTINA dusmesi ogretici: 'vergisi'->'verg' gibi
      // kiyimlar gurultu yayiyor. madde_ara v6 (19.08) koku Postgres'in icine
      // gomup 48->41 dusurmus ve GERI ALINMISTI; dogru katman burasi (istemci)
      // ve bu kez canliya yazmadan olculdu.
      // Kural: EN UZUN eki dene, kok 5'in altina duserse HIC SOYMA. Yanlis ek
      // soymak hic soymamaktan kotudur (cezasi->cezas gibi kelime-olmayan kok).
      //
      // ⚠️ motor/ambar-testi.ps1 ile BIREBIR SENKRON. Biri saparsa altin test
      // canli davranisi olcmuyor demektir.
      // ---------------------------------------------------------------------
      const EKLER = ["lerinin","larinin","lerine","larina","lerini","larini","sinden","sindan","inden","indan",
                     "lerin","larin","sinde","sinda","siyle","leri","lari","sinin","inde","inda","iyle",
                     "ligi","lugi","lugu","mesi","masi","ler","lar","nin","nun","sine","sina","ine","ina",
                     "den","dan","ten","tan","yle","lik","luk","mek","mak","in","un","ye","ya","de","da",
                     "te","ta","le","la","si","su","me","ma","e","a","i","u"]
                     .sort((x, y) => y.length - x.length);
      const ekSoy = (w: string, enAz = 5): string => {
        let x = w;
        for (let tur = 0; tur < 3; tur++) {
          const ek = EKLER.find((e) => x.endsWith(e));
          if (!ek) break;
          if (x.length - ek.length < enAz) break;   // kok cok kisalir -> DUR
          x = x.slice(0, x.length - ek.length);
        }
        return x;
      };
      const ftsTok: string[] = [];
      // Ek soyma takma addan ONCE: 'sgk' 3 harf, soyulmaz; ALIAS davranisi aynen korunur.
      for (const t of tok.slice(0, 8)) {
        const f = ekSoy(fold(t));
        if (f.length < 3) continue;
        const a = ALIAS[f];
        if (a) ftsTok.push(...a); else ftsTok.push(f);
      }
      const fts = ftsTok.slice(0, 8).join(" ");
      if (fts) {
        // 21.08 KRITIK AYIKLAMA: ambarda cikmis sinavlar tur='cikmis-soru'
        // olarak duruyor ve HER SINAV TEK SATIR (metin alani 68.000+ karakter,
        // "130 soru" bir arada). Tek satir her kelimeyi icerdigi icin FTS'te
        // her sorguyu kazaniyordu: 8 ornek sorgunun 6'sinda ilk sira sinav
        // kagidiydi. "katma deger vergisi iade" sorgusunda donen parca bir
        // EDEBIYAT sorusuydu. Beyin bunlardan ozet cikarsa kanun yerine sinav
        // kagidini kaynak gosterirdi - ustelik "dogrulanmis birincil kaynak"
        // rozetiyle. Cikmis sorular soru bankasinin malidir, hukuki cevap
        // motorunun degil.
        // ADET 6 -> 30 (olculdu): 14 yetmedi. "katma deger vergisi iade" ve
        // "damga vergisi kira sozlesmesi" sorgularinda ilk 14'un TAMAMI sinav
        // kagidiydi, ayiklamadan sonra SIFIR kaynak kaliyordu. 30'da kanun
        // satirlari geri geliyor (5 ve 12 kayit) ve sure ~1,2-1,8 sn'de
        // kaliyor. Ayiklamadan sonra ilk 6 alinir.
        // 23.08: ayni gerekce yeni turler icin de gecerli. Ambara eklendi:
        //   cikmis-komisyon-cevabi = TESMER Yeterlilik klasik donem (2008-2025)
        //   sinav komisyonunun RESMI cozumleri. 402 belge, her biri tek satir.
        // Bunlar soru bankasinin malzemesi; hukuki cevap motoruna girmezler.
        // YENI TUR EKLERKEN BU SETI DE GUNCELLE - yoksa ambar buyudukce
        // Net Cevap sessizce sinav kagidi alintilamaya baslar.
        const AYIKLA = new Set(["cikmis-soru", "cikmis-komisyon-cevabi"]);
        const r = await fetch(`${SB_URL}/rest/v1/rpc/madde_ara`, {
          method: "POST",
          headers: { "content-type": "application/json", ...(SB_ANON ? { apikey: SB_ANON, Authorization: `Bearer ${SB_ANON}` } : {}) },
          body: JSON.stringify({ sorgu: fts, adet: 30 }),
        });
        if (r.ok) {
          // -------------------------------------------------------------
          // CESITLILIK TAVANI (25.08.2026) — OLCULEREK EKLENDI: 44 -> 45/48.
          // Sorun: top-6'yi AYNI maddenin farkli parcalari dolduruyordu.
          // "tapu harci alim satim" sorgusunda 6 sonucun 4'u ayni belgenin
          // (Harclar GT 56 ek m.12) parcalariydi; Harclar Kanunu'nun kendisi
          // hic gorunmuyordu. Kullanici acisindan da israf: alintilarin
          // yarisi ayni metnin devami, cevap motoru bunlari bosuna okuyor.
          // Kural: ayni MADDEDEN en fazla 1, ayni BELGEDEN en fazla 2 parca.
          // Olcum (arac/sirala-tarti.ps1 -Kapak, 48 altin vaka, uctan uca):
          //   ek soyma tek basina 44/48 · + tavan 45/48. Dort farkli tavan
          //   ayari (1/2, 1/3, 2/3, havuz 60) AYNI 45'i verdi; en dar olani
          //   secildi cunku puan esitken okuyucuya en cesitli sonucu verir.
          // SQL GEREKTIRMEZ: zaten adet=30 cekiliyor, eleme burada yapiliyor.
          // ⚠️ motor/ambar-testi.ps1 ile BIREBIR SENKRON kalmali.
          // -------------------------------------------------------------
          const maddeAnahtar = (k: string) => k.replace(/\s*\[\d+\/\d+\]\s*$/, "").trim();
          const belgeAnahtar = (k: string) => maddeAnahtar(k)
            .replace(/\s+((gec\.|muk\.|mük\.|ek|mükerrer)\s+)?m\.\s*\d.*$/, "")
            .replace(/\s+(bolum|bölüm)\s+\d.*$/i, "")
            .trim();
          const havuz = (await r.json()).filter((d: any) => !AYIKLA.has(String(d.tur || "")));
          const mSay = new Map<string, number>(); const bSay = new Map<string, number>();
          const satirlar: any[] = [];
          for (const d of havuz) {
            const ad = String(d.kaynak_ad || "");
            const mk = maddeAnahtar(ad); const bk = belgeAnahtar(ad);
            if ((mSay.get(mk) || 0) >= 1) continue;
            if ((bSay.get(bk) || 0) >= 2) continue;
            mSay.set(mk, (mSay.get(mk) || 0) + 1); bSay.set(bk, (bSay.get(bk) || 0) + 1);
            satirlar.push(d);
            if (satirlar.length >= 6) break;
          }
          for (const d of satirlar) parcalar.push({ ad: d.kaynak_ad + (d.belge_tarihi ? ` (${d.belge_tarihi})` : ""), metin: (d.baslik ? d.baslik + " — " : "") + String(d.metin).slice(0, 1200), url: d.kaynak_url });
        }
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

    const oz = await ozetle(istem);

    // ---- 3b) OZETLEYICI OLU: kaynagi HAM ver, sessizce dusme ---------------
    // Eski davranis burada "hata:ai" donup pes ediyordu; sayfa da yerel motora
    // dusuyordu. Ama yerel motor yalnizca 403 kayitlik bilgi tabanini gorur,
    // OYSA KAYNAKLAR ZATEN BULUNMUS durumda (ambarda 13 binden fazla madde).
    // Ozet yazamiyorsak yazmayiz - ama kaynagin KENDISINI vermek, hic cevap
    // vermemekten iyidir. "ozetlenmedi" bayragiyla donuyor ki sayfa bunu
    // ozet gibi sunmasin; kullaniciya maddenin ham metni gosterilir.
    if (!oz.metin) {
      const ham = parcalar.slice(0, 3).map((p) => ({ ad: p.ad, metin: String(p.metin).slice(0, 1200), url: p.url }));
      return json({
        kapsamda: true, ozetlenmedi: true,
        cevap: "Bu soruyla ilgili kaynağı buldum ama şu an sadeleştiremiyorum. Maddenin kendi metni aşağıda — hüküm bu metindedir.",
        kaynaklar: ham.map((p) => ({ ad: p.ad, url: p.url })), alintilar: ham,
        hata: "ozetleyici", hata_kod: oz.hataKod, hata_tip: oz.hataTip,
      });
    }

    const m = oz.metin.match(/\{[\s\S]*\}/);
    if (!m) return json({ kapsamda: false });
    const out = JSON.parse(m[0]);
    if (!out.kapsamda || !out.cevap) return json({ kapsamda: false });

    const secilen = (out.kaynak_no || []).map((n: number) => parcalar[n - 1]).filter(Boolean);
    const kaynaklar = secilen.map((p: any) => ({ ad: p.ad, url: p.url }));
    // GUVEN KATMANI: ozetin dayandigi HAM kaynak metni de dondur — kullanici asli gorur,
    // ozetleme hatasi olsa bile kaynak ortada (denetlenebilirlik).
    const alintilar = secilen.slice(0, 3).map((p: any) => ({ ad: p.ad, metin: String(p.metin).slice(0, 1200), url: p.url }));
    return json({ kapsamda: true, cevap: String(out.cevap).slice(0, 1500), kaynaklar, alintilar, hat: oz.hat });
  } catch (e) {
    return json({ kapsamda: false, hata: String(e).slice(0, 120) }, 200);
  }
});

function json(o: unknown, s = 200) { return new Response(JSON.stringify(o), { status: s, headers: CORS }); }
