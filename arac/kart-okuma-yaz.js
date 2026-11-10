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
if (j.sinav_profili) {
  const p = j.sinav_profili;
  md += `## Sınav bu dersi nasıl soruyor\n\n${p.kaynak}\n\n| Ölçü | Değer |\n|---|---|\n| Şık sayısı | ${p.sik_sayisi} |\n| Kök uzunluğu (karakter) | ortanca ${p.kok_karakter.ortanca} · en kısa ${p.kok_karakter.en_kisa} · en uzun ${p.kok_karakter.en_uzun} |\n| Şık uzunluğu (karakter) | ortanca ${p.sik_karakter_ortanca} |\n| Olumsuz kök | ${p.olumsuz_kok} |\n| Boşluk doldurma | ${p.bosluk_doldurma} |\n| Öncüllü | ${p.oncullu} |\n| Kökte mevzuat adı geçen | ${p.kokte_mevzuat_adi} |\n\n${p.okuma}\n\n**Çeldirici taktikleri:**\n\n` + p.celdirici_taktikleri.map(t => `- ${t}`).join('\n') + `\n\n> Görmediği: ${p.gormedigi}\n\n---\n\n`;
}
for (const k of j.kart) {
  md += `## ${k.no}. ${k.konu}\n\nÇıkmış örnek: ${k.cikmis.join(' · ') || '—'}\n\n`;
  if (k.cikmis_inceleme) {
    md += `### Sınavda nasıl soruldu\n\n| Soru | Kalıp | Kök (kr) | Taktik |\n|---|---|---:|---|\n` + k.cikmis_inceleme.sorular.map(s => `| ${s.ref} | ${s.kalip} | ${s.kok_kr} | ${s.taktik} |`).join('\n') + `\n\n**Sonuç:** ${k.cikmis_inceleme.sonuc}\n\n` + (k.cikmis_inceleme.kaynak_farki ? `> ${k.cikmis_inceleme.kaynak_farki}\n\n` : '');
  }
  md += `### Öğrencinin göreceği\n\n**Şekil — ${k.gorsel.baslik}** *(${k.gorsel.tur})*\n\n![${k.gorsel.baslik}](kart-sekil/${j.sekil_onek || 'denetim'}-${k.no}.svg)\n\nŞeklin yazı hâli (çizim bundan üretilir):\n\n`;
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
  if (k.onay) { md += `\n**İç not (öğrenci görmez):** ${k.kaynak_notu}\n\n**${k.onay.mevzuat && k.onay.anlatim && k.onay.soru_kapsami ? '✅ ONAYLANDI' : '🟡 KISMEN ONAYLI'} — ${k.onay.kim}, ${k.onay.tarih}:** mevzuat doğru ve eksiksiz ${k.onay.mevzuat ? '☑' : '☐'} · anlatım yalın ve doğru ${k.onay.anlatim ? '☑' : '☐'} · soru kapsamı yeterli ${k.onay.soru_kapsami ? '☑' : '☐'} (${k.onay.yol}). Yeniden onay: ${k.onay.yeniden_onay} ya da dayandığı metin değişince.${k.onay_notu ? '\n\n> ' + k.onay_notu : ''}\n\n---\n\n`; continue; }
  md += `\n**İç not (öğrenci görmez):** ${k.kaynak_notu}\n\n**Onay (Cem) — üçü de işaretlenmeden kart onaylı sayılmaz:**\n\n- ☐ Mevzuat doğru ve eksiksiz\n- ☐ Anlatım yalın ve doğru\n- ☐ Soru kapsamı yeterli\n- düzelt: …\n\n---\n\n`;
}
fs.writeFileSync(mdYol, md, 'utf8');
console.log('kart:', j.kart.length, '| yeni alanlı:', j.kart.filter(k => k.gorsel && k.yalin && k.ana_fikir && k.basamaklar).length);
