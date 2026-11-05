// kart/kartlar/*.json → depo: KGK-KONU-KARTLARI.md (okunur) + veri/sinav/kgk-konu-kartlari.json (yazar/ölçü aracı). Bitirme kart-md.js eşi. Bedel 0.
// Yalnız 4 alanı DOLU kart "kartlı" sayılır; boş kart md'de "DOLDURULMADI" yazar ve K1 gereği ona soru YAZILMAZ.
// node kart-md.js <depo>
'use strict';
const fs = require('fs'), path = require('path'); const D = __dirname, depo = process.argv[2] || 'C:/TETIKTE-CALISMA/kgk-basim';
const SIRA = ['TSRS', 'GDS', 'SIGORTA', 'BANKA', 'SPK', 'KY', 'FY', 'TMS', 'TDS'];
const ALAN = ['ne_sorar', 'dayanak', 'celdirici', 'yazim_notu'], dolu = c => ALAN.every(k => String(c[k] || '').trim());
const kart = [], say = [];
for (const k of SIRA) { const f = path.join(D, 'kartlar', `${k}.json`); if (!fs.existsSync(f)) continue; const a = JSON.parse(fs.readFileSync(f, 'utf8')); kart.push(...a.map(c => ({ kod: k, ...c }))); say.push([k, a.length, a.filter(dolu).length, a.filter(c => /AMBARDA YOK|BOZUK KAYNAK|OKUNAMADI/.test(c.dayanak || '')).length]); }
let md = `# KGK KONU KARTLARI — modül modül, konu konu · v1 · ${new Date().toISOString().slice(0, 10)}\n\n`;
md += `> BITIRME-SORU-STANDARDI K1'in KGK eşi (Cem 05.11, DEVIR-KGK-BASIM §3). Her yeni KGK sorusu bu kartlardan BİRİNE göre yazılır; kartın dışına çıkan soru atılır.\n`;
md += `> Üretim: \`C:\\TETIKTE-CALISMA\\kgk-is\\kart\` (kgk-kart-kur.js ölçülen alanlar + okuyucu doldurma KART-DOLDURMA-TALIMAT-KGK.md + kart-md.js). Veri: \`veri/sinav/kgk-konu-kartlari.json\`. Soru metni YOK.\n`;
md += `> **Dönem/Soru** = çıkmış KGK 2016+ (24 sınav; 2013–2015 ve Kasım 2018 metni bozuk, yok) · **Kalıp** = elle etiket, GERÇEK DAĞILIM (×adet) — yazılan sorular bu ORANDA dağılır (K4/K8), gerçekte olmayan kalıp yazılmaz, ≥5 sorulu konuda tek kalıp ≤%60.\n`;
md += `> **Kök** = konu medyanı ±%25 (çıkmışta <3 soru → kalıbın modül medyanı, "modül yedeği") · **Beceri** türetilmiş (KGK'da elle ölçülmedi) · **Dayanak** "AMBARDA YOK / BOZUK KAYNAK" → o karta soru YAZILMAZ (K1b) · "DOLDURULMADI" → kart yok sayılır.\n\n`;
md += `| Modül | Kart | Doldurulan | Ambarda yok / bozuk |\n|---|---:|---:|---:|\n${say.map(s => `| ${s[0]} | ${s[1]} | ${s[2]} | ${s[3]} |`).join('\n')}\n\n`;
for (const k of SIRA) {
  const a = kart.filter(c => c.kod === k); if (!a.length) continue; md += `## ${a[0].modul} — ${a.length} konu\n\n`;
  for (const c of a) {
    md += `### ${c.konu}\n- **Dönem:** ${c.donem_sayisi} (son ${c.son_donem}) · **Soru:** ${c.soru_sayisi} · **Son 10 yıl:** ${c.son10 ?? '?'} · **Sitede/hedef/eksik:** ${c.sitede ?? '?'}/${c.hedef ?? '?'}/${c.eksik ?? '?'} · **Örnek:** ${c.ornek.join(', ')}${c.tahmini_hedef ? ' · _modül yedeği_' : ''}\n`;
    md += `- **Kalıp:** ${c.kalip.join(' / ')} · **Olumsuz/öncüllü/hesap:** %${c.olumsuz_pay}/%${c.oncullu_pay}/%${c.hesap_pay} · **Kök:** ${c.kok_hedef_kr ? c.kok_hedef_kr.join('–') + ' kr' : '?'} · **Şık:** ${c.sik_turu.join(' / ')} (~${c.sik_medyan_kr} kr)\n`;
    if (dolu(c)) md += `- **Ne sorar:** ${c.ne_sorar}\n- **Dayanak:** ${c.dayanak}\n- **Çeldirici:** ${c.celdirici}\n- **Yazım notu:** ${c.yazim_notu}\n\n`;
    else md += `- **DOLDURULMADI** — bu karta soru yazılmaz (K1).\n\n`;
  }
}
fs.writeFileSync(path.join(depo, 'KGK-KONU-KARTLARI.md'), md);
fs.writeFileSync(path.join(depo, 'veri/sinav/kgk-konu-kartlari.json'), JSON.stringify({ aciklama: `KGK konu kartlari v1 ${new Date().toISOString().slice(0, 10)} - BITIRME-SORU-STANDARDI K1 KGK esi (DEVIR-KGK-BASIM §3). Soru metni YOK. Uretici: C:/TETIKTE-CALISMA/kgk-is/kart (kgk-kart-kur.js + okuyucu doldurma + kart-md.js).`, kart }, null, 1) + '\n');
console.log(say.map(s => `${s[0]} ${s[2]}/${s[1]}`).join(' · '));
