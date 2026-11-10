// KART KAPISI (10.11.2026) — ders notu kartlarını HER koşuda, HER kart için denetler. Bedel 0.
// Kullanım: node arac/kart-kapisi.js <kart.json> <kaynak-tekil.txt> <çıktı.md>   (çıkış 1 = kusur var)
//   kaynak-tekil.txt: kartların dayandığı ambar parçaları, "=== [parça kimliği] kaynak adı\nmetin" biçiminde (arac/kart-kaynak-cek.js üretir).
// Denetlediği: (1) her kuralın alıntısı kaynak parçada harfi harfine var mı · (2) zorunlu alanlar dolu mu · (3) son basamak sınav düzeyi mi ·
//   (4) D2b: öğrencinin gördüğü kısımda anılan kaynak, kural bölümünde var mı · (5) D2a: sayma hükmünde bent sayısı kaynakla eşit mi · (6) onay kaydı tam mı.
// Mutasyon (10.11, dört bozuk kopya): okunmamış kaynaktan çeldirici · silinmiş alan · düşürülmüş bent · uydurma alıntı → dördünde de çıkış 1.
// 🚫 GÖRMEZ: kural cümlesinin alıntıyı doğru özetleyip özetlemediği · bent harfi taşımayan listelerde eksik · istisna cümlesinin düşmesi
//   (BDS 210 p.8'deki "19 uncu paragraf" istisnasını bu kapı YAKALAMAZDI, ikinci okuma buldu) · kaynak adı anmadan yazılmış dayanaksız çeldirici ·
//   yalın anlatımın doğruluğu ve yalınlığı. Bunlar kaynakla yan yana ikinci okuma ve Cem onayı ister.
// EKSİK: kaynağı doğrudan ambardan okumuyor (yerel dosya ister) · dogrula.yml'de koşmuyor · öz-sınav betiği yok (mutasyon elle yapıldı).
const fs=require('fs'); const [,, kartYol, kaynakYol, mdYol]=process.argv;
const n=s=>String(s).replace(/\s+/g,' ').trim();
const kay={}, adIle={}; for(const b of fs.readFileSync(kaynakYol,'utf8').split(/\n(?==== \[)/)){ const m=b.match(/^=== \[(.+?)\] (.+?)\n([\s\S]*)$/); if(m){ kay[m[1]]={ad:m[2],metin:n(m[3])}; adIle[m[2].replace(/ - .*/,'')]=n(m[3]); } }
const j=JSON.parse(fs.readFileSync(kartYol,'utf8')); let top=0,ok=0,hata=[];
let md=`# CEM OKUMA — Muhasebe Denetimi ders notu kartları (TASLAK, ilk ${j.kart.length})\n\n> ${j.tarih} · Her kural yalnız ambardaki resmî metinden yazıldı. Tırnak içindeki satır, kaynaktan harfi harfine alıntıdır ve betikle kaynak metinde arandı.\n> Onaylamadığın kart soru basımında kullanılmaz. "Böyle düşürürler" satırı eski karttan aktarıldı, çıkmış soruyla yeniden sayılmadı.\n\n`;
for(const k of j.kart){ md+=`## ${k.no}. ${k.konu}\n\nÇıkmış örnek: ${k.cikmis.join(' · ')||'—'}\n\n**Kural**\n\n`;
  for(const o of k.ozet){ top++; const src=kay[o.parca]; const g=src&&src.ad===o.kaynak&&src.metin.includes(n(o.alinti)); if(g)ok++; else hata.push(`kart ${k.no} özet: [${o.kaynak}] "${o.alinti}"`+(src?(src.ad!==o.kaynak?' (parça adı uyuşmuyor: '+src.ad+')':''):' (parça yok)'));
    md+=`- ${o.kural}\n  - Kaynak: ${o.kaynak.replace(/ - .*/,'')} · "${o.alinti}"\n`; }
  if(k.terimler.length){ md+=`\n**Terimler**\n\n`; for(const t of k.terimler){ if(t.alinti){ top++; const src=adIle[t.kaynak]; const g=src&&src.includes(n(t.alinti)); if(g)ok++; else hata.push(`kart ${k.no} terim ${t.ad}: [${t.kaynak}] "${t.alinti}"`); } md+=`- **${t.ad}:** ${t.tanim} (${t.kaynak})\n`; } }
  md+=`\n**Böyle düşürürler:** ${k.dusururler}\n\n**Kaynak notu:** ${k.kaynak_notu}\n\n**Onay:** ☐ doğru ☐ düzelt: …\n\n---\n\n`; }
md+=`Alıntı denetimi: ${ok}/${top} alıntı kaynak metinde harfi harfine bulundu.\n`;
// KART KAPISI (10.11): kural bir karta değil HER karta, HER koşuda uygulanır.
const kusur=[]; const ATIF=/\b(BDS|TMS|TFRS|KKS|BOBI FRS)\s*\d+|\bTTK\b|\bVUK\b|\bGVK\b|\bKVK\b/g;
for(const k of j.kart){
  for(const a of ['gorsel','yalin','ana_fikir','basamaklar','soru_kapsami','dusururler','kaynak_notu']) if(k[a]===undefined||k[a]===null||(Array.isArray(k[a])&&!k[a].length)||k[a]==='') kusur.push(`kart ${k.no}: alan eksik → ${a}`);
  if(Array.isArray(k.basamaklar)&&k.basamaklar.length&&!/^SINAV DÜZEYİ/.test(k.basamaklar[k.basamaklar.length-1])) kusur.push(`kart ${k.no}: son basamak sınav düzeyi değil`);
  // D2b: çeldirici, soru kapsamı, basamak ve yalın anlatımda anılan kaynak, kural bölümünde olmalı
  const kuralMetni=k.ozet.map(o=>o.kaynak+' '+o.kural).join(' ');
  const ogr=[k.dusururler,(k.soru_kapsami||[]).join(' '),(k.basamaklar||[]).join(' '),k.yalin,k.ana_fikir,k.gorsel?JSON.stringify(k.gorsel):''].join(' ');
  for(const m of new Set(ogr.match(ATIF)||[])){ const ad=m.replace(/\s+/g,' '); if(!kuralMetni.includes(ad)) kusur.push(`kart ${k.no}: "${ad}" öğrenci kısmında anılıyor ama kural bölümünde yok (D2b)`); }
  // D2a: sayma hükmü — kuralda "(a)…(i)" bent dizisi varsa kaynak parçadaki bent sayısıyla karşılaştır
  for(const o of k.ozet){ const src=kay[o.parca]; if(!src) continue; const kb=new Set(o.kural.match(/\((?:[a-zçğıöşü])\)/g)||[]); if(kb.size<5) continue; const sb=new Set((src.metin.match(/(?:^|\s)([a-zçğıöşü])\s?\)/g)||[]).map(x=>x.trim().replace(/\s?\)/,''))); if(sb.size>kb.size) kusur.push(`kart ${k.no}: sayma hükmü eksik olabilir — kuralda ${kb.size} bent, kaynak parçada ${sb.size} (${o.kaynak})`); }
  if(k.onay&&!(k.onay.kim&&k.onay.tarih&&k.onay.mevzuat&&k.onay.anlatim&&k.onay.soru_kapsami)) kusur.push(`kart ${k.no}: onay kaydı eksik`);
}
fs.writeFileSync(mdYol,md,'utf8'); console.log(`alıntı: ${ok}/${top}`); console.log(`kart kapısı: ${j.kart.length} kart, ${kusur.length} kusur`); if(kusur.length){ console.log(kusur.join('\n')); process.exit(1); } if(hata.length){ console.log('BULUNAMAYAN:\n'+hata.join('\n')); process.exit(1); }
