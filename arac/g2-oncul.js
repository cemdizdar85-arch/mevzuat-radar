// Öncüllü sorularda G2: her yanlış şık doğru öncül kümesinden TEK öğeyle ayrılmalı (simetrik fark = 1). node g2-oncul.js <dosya...>
const fs=require('fs');const R=s=>{const m=String(s).replace(/Yalnız/gi,'').match(/\b(IV|V|I{1,3})\b/g);return m?new Set(m):null;};
for(const F of process.argv.slice(2)){const A=JSON.parse(fs.readFileSync(F,'utf8'));A.forEach((q,i)=>{
 const S={};for(const [h,t] of Object.entries(q.siklar)){const r=R(t);if(!r||String(t).replace(/\b(IV|V|I{1,3})\b|Yalnız|ve|,|\s/gi,'').length>0)return;S[h]=r;}
 if(Object.keys(S).length<5)return;const d=S[q.dogru];const bad=[];
 for(const [h,s] of Object.entries(S)){if(h===q.dogru)continue;const f=[...s].filter(x=>!d.has(x)).length+[...d].filter(x=>!s.has(x)).length;if(f!==1)bad.push(h+'('+f+')');}
 console.log(F.split('hazir-smmm-s20-').pop(),'['+i+']',q.konu.slice(0,40),'doğru',[...d].join(','),bad.length?'G2 İHLAL '+bad.join(' '):'ok');});}
