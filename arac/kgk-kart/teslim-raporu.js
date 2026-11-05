// TESLİM RAPORU (BITIRME-SORU-STANDARDI §7 son paragraf + D4 Cem okuması). Bedel 0. Çıktı YEREL (soru metni içerir — depo PUBLIC, commit'lenmez).
// node teslim-raporu.js <grup> <cikti.md>
'use strict';
const fs = require('fs'), path = require('path'), cp = require('child_process'); const IS = path.join(__dirname, '..');
const [grup, cikti] = process.argv.slice(2); const FAB = 'C:/TETIKTE-CALISMA/kgk-basim/veri/fabrika/', B = path.join(IS, 'basim');
const oku = p => JSON.parse(fs.readFileSync(p, 'utf8').replace(/^\uFEFF/, ''));
const kart = {}; for (const c of oku('C:/TETIKTE-CALISMA/kgk-basim/veri/sinav/kgk-konu-kartlari.json').kart) kart[c.konu] = c;
const A = oku(path.join(B, 'kor', `cozum-${grup}-A.json`)), Bc = oku(path.join(B, 'kor', `cozum-${grup}-B.json`));
const kararF = path.join(B, '_anahtar-gizli', `karar-${grup}.json`), K = fs.existsSync(kararF) ? oku(kararF) : [];
const olc = {}; for (const l of (cp.spawnSync(process.execPath, [path.join(__dirname, 'kart-olc.js'), grup, '--tsv'], { encoding: 'utf8' }).stdout || '').split('\n').slice(1)) { const p = l.split('\t'); if (p[0]) olc[p[0]] = p; }
const kan = {}; for (const l of (cp.spawnSync(process.execPath, [path.join(__dirname, 'kanit-ara.js'), grup], { encoding: 'utf8' }).stdout || '').split('\n')) { const m = l.match(/^(\S+)\s+(BULUNDU|KISMEN|YOK|ÖLÇÜLMEDİ)/); if (m) kan[m[1]] = m[2]; }
const kal = {}; for (const z of ['kolay', 'zor', 'cokzor']) { const o = cp.spawnSync('powershell', ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', 'arac/hazir-soru-denetle.ps1', '-Dosya', `veri/fabrika/hazir-kgk-t10-${grup}-${z}.json`, '-IkizEtiket', `kgk-t10-${grup}-${z}`, '-Tavan', '995'], { cwd: 'C:/TETIKTE-CALISMA/kgk-basim', encoding: 'utf8' }).stdout || ''; kal[z] = (o.match(/ozet: (\d+\/\d+)/) || [])[1] || 'ÖLÇÜLMEDİ'; }
const ornekMetin = (konu, n) => (cp.spawnSync(process.execPath, [path.join(__dirname, 'kart-ornek.js'), konu, String(n)], { encoding: 'utf8' }).stdout || '').trim();
let md = `# TESLİM RAPORU — ${grup} (KGK TSRS ilk parti · ${new Date().toISOString().slice(0, 10)})\n\n> Standart §6 sırası: kart → yazım → mekanik kapı → iki kör çözücü → açıklama doğrulayıcısı → **Cem okuması (D4)**. Bu dosya YEREL (soru metni var; depoya girmez).\n> Teslim denetimi: kolay ${kal.kolay} · zor ${kal.zor} · cokzor ${kal.cokzor} kusursuz.\n\n`;
md += `## Ölçü satırları\n| kimlik | konu | kalıp ölçülen/atama | kök / hedef | şık ~kr / kart | çözücü A / B / anahtar | kanıt (D2) | yıl | doğrulayıcı |\n|---|---|---|---|---|---|---|---|---|\n`;
const satirlar = [];
for (const z of ['kolay', 'zor', 'cokzor']) oku(FAB + `hazir-kgk-t10-${grup}-${z}.json`).forEach((q, i) => {
  const id = `${grup}-${z}[${i}]`, o = olc[id] || [], a = A.find(x => x.id === id) || {}, b = Bc.find(x => x.id === id) || {}, k = K.find(x => x.id === id) || {};
  md += `| ${id} | ${q.konu} | ${o[2] || '?'}/${o[3] || '?'} | ${o[4] || '?'} / ${o[5] || '?'} | ${o[6] || '?'} / ${o[7] || '?'} | ${a.cevap || '—'} / ${b.cevap || '—'} / ${q.dogru} | ${kan[id] || 'ÖLÇÜLMEDİ'} | ${/\b20\d\d\b/.test(q.soru) ? 'kökte yıl' : '-'} | ${k.karar || 'ÖLÇÜLMEDİ'} |\n`;
  satirlar.push({ id, q, a, b, k });
});
md += `\n## Sorular (Cem okuması — her sorunun altında aynı konunun GERÇEK çıkmış sorusu)\n\n`;
for (const { id, q, a, b, k } of satirlar) {
  const c = kart[q.konu] || {};
  md += `### ${id} · ${q.konu}\n**Kart:** kalıp ${(c.kalip || []).join(' / ')} · kök ${(c.kok_hedef_kr || []).join('–')} kr · örnek ${(c.ornek || []).join(', ')}\n\n${q.soru}\n\n`;
  for (const [h, s] of Object.entries(q.siklar || {})) md += `- ${h}) ${s}${h === q.dogru ? ' ✅' : ''}\n`;
  md += `\n**Dayanak:** ${q.dayanak}\n\n**Hap:** ${q.hap || ''}\n\n**Çözücüler:** A ${a.cevap || '—'} (emin ${a.emin || '?'}${a.kusur ? ', not: ' + a.kusur : ''}) · B ${b.cevap || '—'} (emin ${b.emin || '?'}${b.kusur ? ', not: ' + b.kusur : ''})\n\n**Doğrulayıcı:** ${k.karar || 'ÖLÇÜLMEDİ'}${k.gerekce ? ' — ' + k.gerekce : ''}\n\n<details><summary>Gerçek çıkmış soru (aynı konu)</summary>\n\n\`\`\`\n${ornekMetin(q.konu, 1)}\n\`\`\`\n</details>\n\n---\n\n`;
}
fs.writeFileSync(cikti, md); console.log('yazıldı', cikti, satirlar.length, 'soru');
