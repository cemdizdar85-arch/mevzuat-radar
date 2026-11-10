// Seçilen 20 denetim kartının dayanak paragraflarını ambardan SALT OKUMA ile çeker. Bedel 0.
const fs=require('fs'),path=require('path');
const KEY=process.env.SUPABASE_SERVICE_KEY; if(!KEY){console.error('anahtar yok');process.exit(2);}
const SB='https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar'; const h={apikey:KEY,Authorization:'Bearer '+KEY};
const cik=process.argv[2]; const depo=process.argv[3];
const kart=JSON.parse(fs.readFileSync(path.join(depo,'veri/sinav/bitirme-konu-kartlari.json'),'utf8').replace(/^﻿/,'')).kart.filter(x=>x.ders==='Muhasebe Denetimi'&&/\bBDS\s*\d+/.test(x.dayanak));
kart.sort((a,c)=>(a.tahmini_kalip-c.tahmini_kalip)||(c.donem_sayisi-a.donem_sayisi));
const sec=kart.filter(x=>!/AMBARDA Y/.test(x.dayanak)).slice(0,20);
const ac=d=>{ // "BDS 200 p.5 ve p.13, p.17; BDS 315 p.34" → [{std:'BDS 200',p:[5,13,17]},...]; "m.29" → yönetmelik
  const out=[]; let cur=null;
  for(const parca of d.split(';')){
    const ms=parca.match(/\b(BDS|BOBI FRS)\s*(\d+)?/); const my=/Bagimsiz Denetim Yonetmeligi/.test(parca);
    if(ms&&ms[1]==='BDS'){ cur={tur:'bds',ad:'BDS '+ms[2],p:[]}; out.push(cur);
      for(const m of parca.matchAll(/p\.(A?\d+)(?:[–-](A?\d+))?/g)){ const a=m[1],b=m[2]; if(b&&!/A/.test(a+b)){ for(let i=+a;i<=+b;i++)cur.p.push(String(i)); } else { cur.p.push(a); if(b)cur.p.push(b); } } }
    else if(my){ cur={tur:'yon',ad:'Bagimsiz Denetim Yonetmeligi',p:[]}; out.push(cur); for(const m of parca.matchAll(/m\.(\d+)/g))cur.p.push(m[1]); }
    else if(cur){ for(const m of parca.matchAll(/p\.(A?\d+)(?:[–-](A?\d+))?/g)){ cur.p.push(m[1]); } }
  } return out; };
(async()=>{ const ozet=[];
  for(let i=0;i<sec.length;i++){ const x=sec[i]; let txt=`KART ${i+1}: ${x.konu}\nDAYANAK: ${x.dayanak}\nNE SORAR: ${x.ne_sorar}\nÇELDİRİCİ: ${JSON.stringify(x.celdirici)}\nÖRNEK: ${JSON.stringify(x.test_ornek)} dönem:${x.donem_sayisi} tahmini:${x.tahmini_kalip}\n\n`; let n=0,yok=[];
    for(const k of ac(x.dayanak)){ for(const p of [...new Set(k.p)]){
      const desen=k.tur==='bds'?`${k.ad} p.${p} -%`:`${k.ad} m.${p}%`;
      const r=await fetch(`${SB}?select=id,kaynak_ad,metin&kaynak_ad=ilike.${encodeURIComponent(desen)}&order=kaynak_ad&limit=6`,{headers:h}).then(r=>r.json());
      if(!Array.isArray(r)||!r.length){ yok.push(desen); continue; }
      for(const y of r){ n++; txt+=`=== [${y.id}] ${y.kaynak_ad}\n${y.metin}\n\n`; } } }
    fs.writeFileSync(path.join(cik,`k${String(i+1).padStart(2,'0')}.txt`),txt,'utf8'); ozet.push(`${i+1}\t${n} parça\t${txt.length} kr\tyok:${yok.join(' | ')||'-'}\t${x.konu}`); }
  console.log(ozet.join('\n')); })();
