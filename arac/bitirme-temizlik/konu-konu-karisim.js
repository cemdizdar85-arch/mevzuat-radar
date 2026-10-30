// KONU KONU kalıp karşılaştırması: her konu için gerçek 2026 testindeki kalıplar ↔ sitedeki soruların kalıp dağılımı.
// Site soru→konu: veri/sinav/smmm-banka-esleme.json (okunmuş, aynı konu sözlüğü). Salt okuma, bedel 0. Çıktı: Markdown (argv[2]).
const fs = require('fs'), path = require('path'); const { ayir } = require('./kalip-ayirici.js');
const D = __dirname; const J = f => JSON.parse(fs.readFileSync(f, 'utf8').replace(/^﻿/, ''));
const V = path.join(D, '..', '..', 'veri', 'sinav'); const ok = J(path.join(V, 'smmm-konu-okuma.json')), elle = J(path.join(V, 'bitirme-kalip-elle-320.json')), es = J(process.argv[3] || path.join(V, 'smmm-banka-esleme.json')).sorular;
const KOD = { 'Finansal Muhasebe': '01', 'Finansal Tablolar ve Analizi': '02', 'Maliyet Muhasebesi': '03', 'Muhasebe Denetimi': '04', 'Vergi Mevzuatı ve Uygulaması': '05', 'Hukuk': '06', 'Meslek Hukuku': '07', 'Sermaye Piyasası Mevzuatı': '08' };
const AD = { A: 'doğrudur', B: 'yanlıştır', C: 'değildir', U: 'sayılır', D: 'öncüllü', E: 'boşluk', G: 'kaç gün/yıl', F: 'hesap', L: 'sırasıyla', I: 'kayıt', J: 'hangi hesap', K: 'kayıt→işlem', M: 'tanım', N: 'merci', O: 'eylem→ceza', P: 'durum→davranış', S: 'grafik' };
const g = {}; for (const r of ok.kararlar) { if (!r.donem.startsWith('2026')) continue; const no = parseInt(r.soru, 10); const h = (elle[`${KOD[r.ders]}|${r.donem}`] || '')[no - 1]; if (!h) continue; ((g[r.ders] ||= {})[r.konu] ||= []).push({ h, yer: `${r.donem} S${no}` }); }
const K = process.env.SUPABASE_SERVICE_KEY, hd = { apikey: K, Authorization: 'Bearer ' + K };
(async () => {
  const tum = []; for (let off = 0; ; off += 1000) { const r = await fetch(`https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/paket_soru?select=id,ders,veri->soru,veri->siklar&sinav=eq.smmm&order=id&limit=1000&offset=${off}`, { headers: hd }).then(r => r.json()); tum.push(...r); if (r.length < 1000) break; }
  const s = {}; let eslesmeyen = 0;
  for (const q of tum) { const e = es[q.id]; if (!e || !e.konular || !e.konular.length) { eslesmeyen++; continue; } const k = ayir(String(q.soru || ''), Object.values(q.siklar || {})); for (const kn of e.konular) ((s[q.ders] ||= {})[kn] ||= []).push(k); }
  let md = `# BİTİRME — KONU KONU KALIP KARŞILAŞTIRMASI (30.10.2026)\n\n> Gerçek = 2026/1 + 2026/2 test sorusu (elle kalıp) · Site = paket_soru (${tum.length} soru; eşlemesi olmayan ${eslesmeyen}) konu eşlemesi \`smmm-banka-esleme.json\`, kalıp ayırıcı (%94).\n> **Eksik kalıp** = gerçek sınavın o konuda kullandığı ama sitede o konuda HİÇ olmayan kalıp · **Tek tip** = sitede konunun sorularının %80+'ı tek kalıpta.\n\n`;
  const ozet = [];
  for (const ders of Object.keys(KOD)) {
    const kon = g[ders] || {}; const site = s[ders] || {};
    md += `## ${ders}\n\n| Konu | Gerçek sınavda nasıl soruldu | Sitede soru | Sitede kalıp dağılımı | Eksik kalıp | Tek tip |\n|---|---|---|---|---|---|\n`;
    const satir = Object.entries(kon).sort((a, b) => b[1].length - a[1].length);
    for (const [kn, gl] of satir) {
      const sa = site[kn] || []; const say = {}; sa.forEach(x => say[x] = (say[x] || 0) + 1);
      const dag = Object.entries(say).sort((a, b) => b[1] - a[1]).map(([h, n]) => `${AD[h]} ${n}`).join(', ') || '—';
      const gH = [...new Set(gl.map(x => x.h))]; const eksik = gH.filter(h => !say[h]).map(h => AD[h]);
      const tek = sa.length >= 5 && Math.max(...Object.values(say)) / sa.length >= 0.8;
      md += `| ${kn} | ${gl.map(x => `${AD[x.h]} (${x.yer})`).join(' · ')} | ${sa.length} | ${dag} | ${eksik.join(', ') || '—'} | ${tek ? 'EVET' : ''} |\n`;
      ozet.push({ ders, kn, gercek: gH.length, site: sa.length, eksik: eksik.length, tek });
    }
    md += '\n';
  }
  fs.writeFileSync(process.argv[2], md);
  const by = {}; for (const o of ozet) { const b = (by[o.ders] ||= { konu: 0, eksik_kalipli: 0, sitede_hic_yok: 0, tek_tip: 0 }); b.konu++; if (o.eksik) b.eksik_kalipli++; if (!o.site) b.sitede_hic_yok++; if (o.tek) b.tek_tip++; }
  console.table(by); console.log('yazıldı', process.argv[2]);
})();
