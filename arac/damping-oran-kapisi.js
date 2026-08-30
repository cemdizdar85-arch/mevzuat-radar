/* ============================================================================
   DAMPİNG ORAN KAPISI — 30.08.2026

   NE ÖLÇER: veri/gtip-damping.json'daki her kaydın önlem oranı, ortak çözücü
   (gtip-damping-oran.js) tarafından okunabiliyor mu?

   NİYE VAR: 30.08'de bulundu — 141 kaydın 30'unda oran ÜÇ FARKLI biçimde
   yazılıydı ("0.29" Excel ondalığı, "21,12%" yüzde sonda) ve okuyucu bunları
   sessizce SIFIR sayıyordu. Sonuç: 140 GTİP kodunda damping yokmuş gibi
   görünüyordu, araç cezalı menşeyi "en avantajlı" diye öneriyordu (en büyüğü
   %56,50 — Çin, 8415.83 klima, tebliğ 2022/1).

   Bu kapı aynı hatanın sessizce geri gelmesini engeller: kaynak Excel'e yeni
   bir biçim girerse burada KIRMIZI yanar.

   ÇIKIŞ: 0 = yeşil, 1 = kırmızı. Kör kalırsa (dosya yok/bozuk) 0 döner ama
   "KÖR" der — sürekli kırmızı kapı kapı değildir, kör kapı da öyle.
   ========================================================================== */
const fs = require('fs');
const path = require('path');

const KOK = path.resolve(__dirname, '..');
const VERI = path.join(KOK, 'veri', 'gtip-damping.json');
const LOG  = path.join(KOK, 'veri', 'damping-oran-log.txt');

function yaz(satirlar, kod){
  try{ fs.writeFileSync(LOG, satirlar.join('\n') + '\n', 'utf8'); }catch(e){}
  process.exit(kod);
}

let G, DMP;
try{
  G = require(path.join(KOK, 'gtip-damping-oran.js'));
  DMP = JSON.parse(fs.readFileSync(VERI, 'utf8').replace(/^﻿/, ''));
}catch(e){
  console.log('DAMPING ORAN KAPISI: KÖR — ' + e.message);
  yaz(['KÖR: ' + e.message], 0);
}

if(!Array.isArray(DMP) || !DMP.length){
  console.log('DAMPING ORAN KAPISI: KÖR — kayıt yok');
  yaz(['KÖR: gtip-damping.json boş ya da dizi değil'], 0);
}

const okunamayan = [];   // biçim hiç tanınmadı
const sessizSifir = []; // oran alanı dolu ama ne yüzde ne spesifik çıktı
const bicim = {};

DMP.forEach((m, i) => {
  const ham = (m && m.t !== undefined && m.t !== null && String(m.t).trim() !== '') ? m.t : (m ? m.o : '');
  const t = String(ham || '').trim();
  const c = G.coz(t);
  bicim[c.bicim] = (bicim[c.bicim] || 0) + 1;
  if(!t) return;                                    // oran boş olabilir: önlemin VARLIĞI bile uyarıdır
  if(c.okunamadi) okunamayan.push({ i, t, u: m.u, k: String(m.k || '').split(' ')[0] });
  else if(!c.yuzdeler.length && !c.spesifik) sessizSifir.push({ i, t, u: m.u, k: String(m.k || '').split(' ')[0] });
});

const rapor = [];
rapor.push('DAMPİNG ORAN KAPISI — ' + new Date().toISOString().slice(0, 10));
rapor.push('kayıt: ' + DMP.length);
Object.keys(bicim).sort().forEach(b => rapor.push('  biçim ' + b + ': ' + bicim[b]));

console.log('DAMPİNG ORAN KAPISI');
console.log('  kayıt: ' + DMP.length + '  ·  biçimler: ' +
            Object.keys(bicim).map(b => b + '=' + bicim[b]).join(', '));

if(okunamayan.length || sessizSifir.length){
  console.log('');
  console.log('  KIRMIZI — oranı okunamayan kayıt var. Bu kayıtlar araçta');
  console.log('  "damping yok" gibi görünür; cezalı menşe ucuz sanılır.');
  rapor.push('SONUÇ: KIRMIZI');
  [{ ad: 'okunamadı (biçim tanınmadı)', liste: okunamayan },
   { ad: 'sessiz sıfır (ne yüzde ne spesifik)', liste: sessizSifir }].forEach(g => {
    if(!g.liste.length) return;
    console.log('    ' + g.ad + ': ' + g.liste.length);
    rapor.push(g.ad + ': ' + g.liste.length);
    g.liste.slice(0, 10).forEach(x => {
      const s = '      GTİP ' + x.k + '  ' + (x.u || '') + '  ham="' + x.t + '"';
      console.log(s); rapor.push(s.trim());
    });
    if(g.liste.length > 10) console.log('      ... ' + (g.liste.length - 10) + ' tane daha');
  });
  console.log('');
  console.log('  Çözüm: yeni biçimi gtip-damping-oran.js içindeki coz() fonksiyonuna ekle,');
  console.log('  ya da motor/damping-hasat.ps1 hasat sırasında "%X" metnine normalize etsin.');
  yaz(rapor, 1);
}

rapor.push('SONUÇ: YEŞİL');
console.log('  Temiz — ' + DMP.length + ' kaydın oranı da okunabiliyor.');
yaz(rapor, 0);
