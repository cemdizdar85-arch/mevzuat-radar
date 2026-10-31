// SGS Son 20 Gün — İKİ KÖR ÇÖZÜCÜ (bitirme standardı D3, Cem 31.10 "bulutta koştur", onay ≈25 USD).
// Her soru, anahtar/açıklama/adım/teşhis GÖRMEDEN, yalnız öğrencinin gördüğüyle (kök + şıklar + sorunun verdiği tablo) İKİ AYRI modelle çözülür:
// claude-opus-5-5 ve claude-sonnet-5-5 (effort high), Message Batches API (%50 indirim, "HEP TOPLU"). Soru metni hiçbir dosyaya YAZILMAZ;
// çıktı yalnız {id, anahtar, cozucu cevapları, iki_sik, kok_eksik, not}. Bedel tavanı aşılırsa yeni batch açılmaz.
// node arac/kor-cozucu-s20.js <liste.json> <cikti.json> [--limit N] [--butce USD]
//   liste: {ids:["<etiket>/kp-NN", …], desenler:["sgs-s20-%-k5-%", …]}  (desen: kalip_parti etiket LIKE; o etiketlerin bütün kp'leri eklenir)
const fs = require('fs');
const [, , LISTE, CIKTI] = process.argv, arg = k => { const i = process.argv.indexOf(k); return i > 0 ? process.argv[i + 1] : null; };
const LIMIT = +(arg('--limit') || 0), BUTCE = +(arg('--butce') || 25);
const SB = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1', SK = (process.env.SUPABASE_SERVICE_KEY || '').trim(), AK = (process.env.ANTHROPIC_API_KEY || '').trim();
const sbh = { apikey: SK, Authorization: 'Bearer ' + SK, 'User-Agent': 'tetikte-bakim/1.0' };
const ah = { 'x-api-key': AK, 'anthropic-version': '2023-06-01', 'content-type': 'application/json' };
// fiyat $/MTok (batch = %50): claude-api skill tablosu 06.10.2026
const COZUCU = [{ ad: 'opus', model: 'claude-opus-5-5', gir: 4 / 2, cik: 20 / 2 }, { ad: 'sonnet', model: 'claude-sonnet-5-5', gir: 2 / 2, cik: 10 / 2 }];
const L = 'ABCDE';
const ISTEM = `Sen Türkiye'de SMMM Staja Giriş Sınavı (SGS) adayısın. Aşağıdaki çoktan seçmeli soruyu yalnız verilenlerle çöz.
Sorunun tek doğru cevabı olmalı. Birden fazla şık savunulabiliyorsa ya da cevap için kökte bir bilgi eksikse bunu bildir.
Yanıtının SON satırı yalnız şu JSON olsun (başka metin yok): {"cevap":"<A-E>","iki_sik":<true|false>,"kok_eksik":<true|false>,"not":"<en çok 1 cümle>"}`;
const metinSik = s => typeof s === 'object' && s ? (s.metin ?? JSON.stringify(s)) : String(s ?? '');
const tabloMetni = v => { if (!v) return ''; if (typeof v === 'string') return v; try { return JSON.stringify(v); } catch (e) { return ''; } };
const soruMetni = q => { const S = Array.isArray(q.siklar) ? q.siklar.map(metinSik) : L.split('').map(h => metinSik((q.siklar || {})[h]));
  const ek = [q.verilenler, q.verilen, q.tablo].map(tabloMetni).filter(Boolean).join('\n');
  return `${q.soru}${ek ? '\n\nVerilenler:\n' + ek : ''}\n\n${S.map((s, i) => `${L[i]}) ${s}`).join('\n')}`; };
const bekle = ms => new Promise(r => setTimeout(r, ms));
async function sb(yol) { const r = await fetch(SB + yol, { headers: sbh }); if (!r.ok) throw new Error(`kasa ${r.status} ${await r.text()}`); return r.json(); }
(async () => {
  if (!SK || !AK) throw new Error('SUPABASE_SERVICE_KEY / ANTHROPIC_API_KEY yok');
  const lis = JSON.parse(fs.readFileSync(LISTE, 'utf8')), istek = new Set(lis.ids || []), etiketler = new Set([...istek].map(i => i.split('/')[0]));
  const parti = {};
  for (const d of lis.desenler || []) for (const r of await sb(`/kalip_parti?select=etiket,icerik&etiket=like.${encodeURIComponent(d.replace(/%/g, '*'))}`)) { parti[r.etiket] = r.icerik; for (const k of Object.keys(r.icerik || {})) istek.add(`${r.etiket}/${k}`); }
  const eksikE = [...etiketler].filter(e => !parti[e]);
  for (let i = 0; i < eksikE.length; i += 40) { const grup = eksikE.slice(i, i + 40).map(e => `"${e}"`).join(','); for (const r of await sb(`/kalip_parti?select=etiket,icerik&etiket=in.(${encodeURIComponent(grup)})`)) parti[r.etiket] = r.icerik; }
  let ids = [...istek].sort(); const yok = ids.filter(id => { const [e, k] = id.split('/'); return !(parti[e] && parti[e][k]); }); ids = ids.filter(id => !yok.includes(id));
  if (LIMIT) ids = ids.slice(0, LIMIT);
  console.log(`soru ${ids.length} · metni bulunmayan ${yok.length}${yok.length ? ' (' + yok.slice(0, 5).join(' ') + ')' : ''}`);
  const Q = ids.map(id => { const [e, k] = id.split('/'); return { id, q: parti[e][k] }; });
  const sonuc = Object.fromEntries(Q.map(x => [x.id, { id: x.id, anahtar: x.q.dogru }])); let usd = 0;
  for (const c of COZUCU) {
    if (usd >= BUTCE) { console.log(`BÜTÇE (${usd.toFixed(2)} / ${BUTCE}) — ${c.ad} AÇILMADI`); break; }
    const requests = Q.map((x, i) => ({ custom_id: `${c.ad}-${i}`, params: { model: c.model, max_tokens: 16000, output_config: { effort: 'high' },
      messages: [{ role: 'user', content: `${ISTEM}\n\n---\n${soruMetni(x.q)}` }] } }));
    const b = await fetch('https://api.anthropic.com/v1/messages/batches', { method: 'POST', headers: ah, body: JSON.stringify({ requests }) }).then(r => r.json());
    if (!b.id) throw new Error('batch açılamadı: ' + JSON.stringify(b).slice(0, 300));
    console.log(`${c.ad}: batch ${b.id} (${requests.length})`);
    let d; do { await bekle(30000); d = await fetch(`https://api.anthropic.com/v1/messages/batches/${b.id}`, { headers: ah }).then(r => r.json()); console.log(`  ${c.ad} ${d.processing_status} ${JSON.stringify(d.request_counts)}`); } while (d.processing_status !== 'ended');
    const satir = (await fetch(d.results_url, { headers: ah }).then(r => r.text())).split('\n').filter(Boolean).map(s => JSON.parse(s));
    let gir = 0, cik = 0;
    for (const s of satir) { const i = +s.custom_id.split('-')[1], x = Q[i], o = sonuc[x.id];
      if (s.result.type !== 'succeeded') { o[c.ad] = { hata: s.result.type }; continue; }
      const m = s.result.message, u = m.usage || {}; gir += (u.input_tokens || 0); cik += (u.output_tokens || 0);
      const txt = (m.content || []).filter(b => b.type === 'text').map(b => b.text).join('\n'), js = (txt.match(/\{[^{}]*"cevap"[^{}]*\}\s*$/) || [])[0];
      try { const j = JSON.parse(js); o[c.ad] = { cevap: String(j.cevap || '').trim().toUpperCase().slice(0, 1), iki_sik: !!j.iki_sik, kok_eksik: !!j.kok_eksik, not: String(j.not || '').slice(0, 200) }; }
      catch (e) { o[c.ad] = { hata: 'json', stop: m.stop_reason }; } }
    const bu = gir / 1e6 * c.gir + cik / 1e6 * c.cik; usd += bu;
    console.log(`${c.ad}: giriş ${gir} · çıkış ${cik} · ≈${bu.toFixed(2)} USD (soru başı ${(bu / Q.length).toFixed(4)})`);
  }
  const R = Object.values(sonuc); for (const o of R) { const c = COZUCU.map(x => o[x.ad]).filter(Boolean);
    o.gecti = c.length === COZUCU.length && c.every(x => x.cevap === o.anahtar && !x.iki_sik && !x.kok_eksik); }
  fs.writeFileSync(CIKTI, JSON.stringify({ tarih: new Date().toISOString(), usd: +usd.toFixed(2), soru: R.length, gecti: R.filter(o => o.gecti).length, sonuc: R }, null, 1));
  console.log(`TOPLAM ≈${usd.toFixed(2)} USD · geçen ${R.filter(o => o.gecti).length}/${R.length} · yazıldı ${CIKTI}`);
})().catch(e => { console.error(e); process.exit(1); });
