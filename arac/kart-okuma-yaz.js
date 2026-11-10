// İlk 6 karta yeni biçim alanlarını ekler (gorsel, yalin, ana_fikir, basamaklar) ve Cem okuma dosyasını üretir. Bedel 0.
const fs = require('fs');
const [, , kartYol, ekYol, mdYol, alintiSonuc] = process.argv;
const EK = JSON.parse(fs.readFileSync(ekYol, 'utf8'));
const j = JSON.parse(fs.readFileSync(kartYol, 'utf8'));
const ALAN = ['gorsel', 'yalin', 'ana_fikir', 'basamaklar', 'basamak_notu'];
for (const k of j.kart) {
  const e = EK[String(k.no)]; if (!e) continue;
  const yeni = {};
  for (const a of Object.keys(k)) {
    if (a === 'sablon_notu') continue;
    if (a === 'dusururler') for (const b of ALAN) { const v = e[b] !== undefined ? e[b] : k[b]; if (v !== undefined) yeni[b] = v; }
    if (!ALAN.includes(a)) yeni[a] = k[a];
  }
  for (const a of Object.keys(k)) delete k[a];
  Object.assign(k, yeni);
}
if (!/YENİ BİÇİM/.test(j.aciklama)) j.aciklama += ' YENİ BİÇİM (10.11): her kartta gorsel + yalin + ana_fikir + basamaklar; bu dört alan özetteki alıntılı kurallardan türetildi, ayrıca alıntıya bağlanmadı ve bağımsız okunmadı.';
j.onaylayan = 'Cem (karar 10.11); onay alanı boş kart onaysızdır';
fs.writeFileSync(kartYol, JSON.stringify(j, null, 2) + '\n', 'utf8');

let md = `# CEM OKUMA — Muhasebe Denetimi ders notu kartları (TASLAK, ilk ${j.kart.length}, yeni biçim)\n\n`;
md += `> ${j.tarih} · Kartları sen onaylıyorsun. Her kartın altındaki kutuya "doğru" ya da "düzelt: …" yaz.\n`;
md += `> **Öğrencinin göreceği:** şekil, yalın anlatım, aklında kalsın, basamaklar. **Dayandığı resmî metin:** tırnak içi kaynaktan harfi harfine.\n`;
md += `> ${alintiSonuc}\n`;
md += `> Dikkat: şekil, yalın anlatım, ana fikir ve basamaklar kurallardan TÜRETİLDİ; bunları senden önce bağımsız kimse okumadı.\n\n`;
for (const k of j.kart) {
  md += `## ${k.no}. ${k.konu}\n\nÇıkmış örnek: ${k.cikmis.join(' · ') || '—'}\n\n### Öğrencinin göreceği\n\n**Şekil — ${k.gorsel.baslik}** *(${k.gorsel.tur})*\n\n`;
  if (k.gorsel.sutunlar) {
    md += `| ${k.gorsel.sutunlar.join(' | ')} |\n|${k.gorsel.sutunlar.map(() => '---').join('|')}|\n`;
    md += k.gorsel.satirlar.map(s => `| ${s.join(' | ')} |`).join('\n') + `\n\n${k.gorsel.alt_not || ''}\n\n`;
  } else {
    md += '```\n' + k.gorsel.satirlar.join('\n') + '\n```\n\n';
  }
  md += `**Yalın anlatım:** ${k.yalin}\n\n**Aklında kalsın:** ${k.ana_fikir}\n\n**Basamaklar (soruların öğretim sırası)**\n\n`;
  md += k.basamaklar.map((b, i) => `${i + 1}. ${b}`).join('\n') + '\n\n';
  if (k.basamak_notu) md += `> ${k.basamak_notu}\n\n`;
  if (k.ogretim_gruplamasi) md += `**On iki unsuru akılda tutma grupları:** ${k.ogretim_gruplamasi.gruplar.join(' · ')}\n\n> ${k.ogretim_gruplamasi.not}\n\n`;
  if (k.soru_kapsami) md += `**Bu konudan yazılacak soru türleri**\n\n` + k.soru_kapsami.map(s => `- ${s}`).join('\n') + '\n\n';
  md += `**Böyle düşürürler:** ${k.dusururler}\n\n### Dayandığı resmî metin\n\n`;
  for (const o of k.ozet) md += `- ${o.kural}\n  - ${o.kaynak.replace(/ - .*/, '')} · "${o.alinti}"\n`;
  if (k.terimler.length) md += `\n**Terimler:** ` + k.terimler.map(t => `**${t.ad}:** ${t.tanim} (${t.kaynak})`).join(' · ') + '\n';
  if (k.onay) { md += `\n**İç not (öğrenci görmez):** ${k.kaynak_notu}\n\n**✅ ONAYLANDI — ${k.onay.kim}, ${k.onay.tarih}:** mevzuat doğru ve eksiksiz ☑ · anlatım yalın ve doğru ☑ · soru kapsamı yeterli ☑ (${k.onay.yol}). Yeniden onay: ${k.onay.yeniden_onay} ya da dayandığı metin değişince.\n\n---\n\n`; continue; }
  md += `\n**İç not (öğrenci görmez):** ${k.kaynak_notu}\n\n**Onay (Cem) — üçü de işaretlenmeden kart onaylı sayılmaz:**\n\n- ☐ Mevzuat doğru ve eksiksiz\n- ☐ Anlatım yalın ve doğru\n- ☐ Soru kapsamı yeterli\n- düzelt: …\n\n---\n\n`;
}
fs.writeFileSync(mdYol, md, 'utf8');
console.log('kart:', j.kart.length, '| yeni alanlı:', j.kart.filter(k => k.gorsel && k.yalin && k.ana_fikir && k.basamaklar).length);
