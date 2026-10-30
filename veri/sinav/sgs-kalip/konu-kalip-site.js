// B30/B31 (Cem 30.10) SGS konu konu kalıp tablosu: gerçek SGS (sgs-konu-okuma.json e=1 etiket + cikmis-sgs-onbellek metni) ↔ SİTEDEKİ SGS bankası (paket_soru sinav=sgs).
// Aynı konu ifadesi (regex) iki tarafa, aynı kalıp ayırıcı (kalip-olcum/kalip-ayirici.js). Salt okuma, bedel 0. Soru METNİ yazılmaz (yalnız sayılar).
// node konu-kalip-site.js <çıktı.md>  · SUPABASE_SERVICE_KEY gerekir (tarayıcı dışı UA şart).
const fs = require('fs'), path = require('path'); const { ayir } = require('./ayir-sgs.js');
const J = f => JSON.parse(fs.readFileSync(f, 'utf8').replace(/^\uFEFF/, '')), S20 = 'C:/TETIKTE-CALISMA/sgs-s20-arac';
const AD = { A: 'doğrudur', B: 'yanlıştır', C: 'değildir', U: 'sayılır', D: 'öncüllü', E: 'boşluk', G: 'kaç gün/yıl', F: 'hesap', L: 'sırasıyla', I: 'kayıt', J: 'hangi hesap', K: 'kayıt→işlem', M: 'doğrudan hangisidir', N: 'merci', O: 'eylem→ceza', P: 'durum→davranış', S: 'grafik' };
const ok = J('C:/TETIKTE-CALISMA/site-s20/veri/sinav/sgs-konu-okuma.json'), RX = ok.konular.map(k => ({ ...k, rx: new RegExp(k.ifade.replace(/^\/|\/[a-z]*$/g, ''), 'i') }));
const MET = {}; for (const d of J(path.join(S20, 'cikmis-sgs-onbellek.json'))) { const p = String(d.m).split(/SORU (\d+):/); for (let i = 1; i < p.length; i += 2) MET[`${d.d}#${+p[i]}`] = p[i + 1].replace(/\s+/g, ' '); }
const bol = g => { const ai = g.search(/\sA\)\s/); return { kok: ai >= 0 ? g.slice(0, ai) : g, siklar: ai >= 0 ? [...g.slice(ai).matchAll(/([A-E])\)\s*(.*?)(?=\s[A-E]\)\s|$)/g)].map(x => x[2]) : [] }; };
const G = {}; for (const r of ok.kararlar) { if (!r.e) continue; const t = MET[`${r.donem}#${r.soru}`]; if (!t) continue; const b = bol(t); ((G[r.konu] ||= { ders: r.ders, k: [] }).k).push(ayir(b.kok, b.siklar)); }
const K = (process.env.SUPABASE_SERVICE_KEY || '').trim(), hd = { apikey: K, Authorization: 'Bearer ' + K, 'User-Agent': 'tetikte-bakim/1.0' };
const sikM = s => typeof s === 'object' && s ? (s.metin ?? '') : String(s ?? '');
(async () => {
  const tum = []; for (let off = 0; ; off += 1000) { const r = await fetch(`https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/paket_soru?select=id,ders,veri->soru,veri->siklar&sinav=eq.sgs&order=id&limit=1000&offset=${off}`, { headers: hd }).then(r => r.json());
    if (!Array.isArray(r)) { console.log('HATA', JSON.stringify(r).slice(0, 200)); process.exit(1); } tum.push(...r); if (r.length < 1000) break; }
  const S = {}; let bagsiz = 0;
  for (const q of tum) { const sk = Array.isArray(q.siklar) ? q.siklar.map(sikM) : Object.values(q.siklar || {}).map(sikM), t = `${q.soru} ${sk.join(' ')}`, h = ayir(String(q.soru || ''), sk); let b = 0;
    for (const k of RX) if (k.rx.test(t)) { (S[k.konu] ||= []).push(h); b++; } if (!b) bagsiz++; }
  const dag = a => { const s = {}; a.forEach(x => s[x] = (s[x] || 0) + 1); return s; }, yaz = s => Object.entries(s).sort((a, b) => b[1] - a[1]).map(([h, n]) => `${AD[h]} ${n}`).join(', ');
  let md = `# SGS — KONU KONU KALIP TABLOSU (B30, ${new Date().toISOString().slice(0, 10)})\n\n> Gerçek = ${ok.pencere} SGS kitapçıkları, ${ok.konular.length} konu, okunmuş etiket (sgs-konu-okuma.json e=1) · Site = paket_soru sinav=sgs (${tum.length} soru; konuya bağlanmayan ${bagsiz}).\n> Kalıp ayırıcı: kalip-olcum/kalip-ayirici.js (SGS elle etikete uyumu SGS-OLCU-TABLOSU.md'de). Konu bağlama aynı regex iki tarafa (sayı alt sınır).\n> **Eksik kalıp** = gerçek sınav o konuda ≥2 kez kullanmış, sitede o konuda hiç yok · **Tek tip** = sitede ≥5 soru ve tek kalıp >%60 (B30).\n\n| Ders | Konu | Gerçek n | Gerçek kalıplar | Site n | Site dağılımı | Eksik kalıp | Tek tip |\n|---|---|---|---|---|---|---|---|\n`;
  const oz = {};
  for (const [konu, g] of Object.entries(G).sort((a, b) => a[1].ders.localeCompare(b[1].ders) || b[1].k.length - a[1].k.length)) {
    const gd = dag(g.k), s = S[konu] || [], sd = dag(s), eksik = Object.entries(gd).filter(([h, n]) => n >= 2 && !sd[h]).map(([h]) => AD[h]);
    const tek = s.length >= 5 && Math.max(...Object.values(sd)) / s.length > 0.6;
    md += `| ${g.ders} | ${konu} | ${g.k.length} | ${yaz(gd)} | ${s.length} | ${yaz(sd) || '—'} | ${eksik.join(', ') || '—'} | ${tek ? 'EVET' : ''} |\n`;
    const o = (oz[g.ders] ||= { konu: 0, sitede_yok: 0, eksik_kalipli: 0, tek_tip: 0 }); o.konu++; if (!s.length) o.sitede_yok++; if (eksik.length) o.eksik_kalipli++; if (tek) o.tek_tip++;
  }
  const T = Object.values(oz).reduce((a, o) => ({ konu: a.konu + o.konu, sitede_yok: a.sitede_yok + o.sitede_yok, eksik_kalipli: a.eksik_kalipli + o.eksik_kalipli, tek_tip: a.tek_tip + o.tek_tip }), { konu: 0, sitede_yok: 0, eksik_kalipli: 0, tek_tip: 0 });
  md += `\n**Toplam:** ${T.konu} konu · sitede hiç sorusu olmayan ${T.sitede_yok} · gerçek kalıbı sitede eksik ${T.eksik_kalipli} · tek tip ${T.tek_tip}\n`;
  fs.writeFileSync(process.argv[2], md); console.table(oz); console.log('TOPLAM', JSON.stringify(T), '· site soru', tum.length, '· yazıldı', process.argv[2]);
})();

