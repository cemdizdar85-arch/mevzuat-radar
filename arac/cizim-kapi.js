// node cizim-kapi.js <depo> <hazir.json> — her soruda sitedeki "Nöbetçi çizerek çözsün" kapısı (cizimKapi)
const path=require('path'),fs=require('fs');const [depo,f]=process.argv.slice(2);const C=require(path.resolve(depo,'cizerek-coz.js'));
const A=JSON.parse(fs.readFileSync(path.resolve(depo,f),'utf8').replace(/^\uFEFF/,''));let g=0;
A.forEach((s,i)=>{let r;try{r=C.cizimKapi(s)}catch(e){r={gecer:false,neden:['HATA '+e.message]}}if(r.gecer)g++;console.log((r.gecer?'GECER ':'DONDU ')+i+' '+s.konu+(r.gecer?'':' :: '+r.neden.slice(0,3).join(' | ')));});
console.log('ozet: '+g+'/'+A.length+' cizim kapisini gecer');process.exit(g===A.length?0:1);