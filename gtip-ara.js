// Ortak GTİP ürün-adı arama motoru — gtip.html + senaryo-raporu.html + fiyatfarki.html
// Resmî Gümrük Tarife Cetveli eşya tanımlarında arar (veri/gtip-tanim.json, ~5MB, 15.717 kod).
// Veri İLK aramada bir kez yüklenir; sayfaların normal akışını yavaşlatmaz.
// Sayfa tarafı yalnız "yapıştırma" yazar: girdi dinleyici + seçim fonksiyonu (kartlarHtml'e adı verilir).
var GtipAra = (function(){
  let TANIM = null, IDX = null, SOZ = null;
  function trFold(s){ return (''+s).toLocaleLowerCase('tr')
    .replace(/ç/g,'c').replace(/ğ/g,'g').replace(/ı/g,'i').replace(/î/g,'i')
    .replace(/ö/g,'o').replace(/ş/g,'s').replace(/ü/g,'u').replace(/â/g,'a').replace(/û/g,'u'); }
  function htmlEsc(s){ return (''+s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;'); }
  function harfliMi(s){ return /[a-zçğıöşüâîû]/i.test(s); }
  function yukle(){
    if(TANIM) return Promise.resolve();
    if(SOZ) return SOZ;
    SOZ = fetch('veri/gtip-tanim.json').then(r=>r.json()).then(j=>{
      TANIM = j;
      IDX = Object.keys(j).map(k => [k, trFold(j[k])]);
    }).catch(()=>{ SOZ = null; });
    return SOZ;
  }
  function hazir(){ return !!IDX; }
  function tanim(kod){ return TANIM ? (TANIM[kod] || null) : null; }
  // Bir kod önekiyle başlayan TGTC kodları — "böyle bir kod yok" uyarısında
  // kullanıcıya EN YAKIN GERÇEK kodları göstermek için (uydurma yok, cetvelden).
  function onekli(onek, ust){
    if(!TANIM) return [];
    const p = (''+onek).replace(/\./g,'');
    if(!p) return [];
    return Object.keys(TANIM).filter(k => k.replace(/\./g,'').startsWith(p)).slice(0, ust||8);
  }
  function ara(ham){
    const q = trFold((''+ham).trim());
    const parcalar = q.split(/\s+/).filter(t => t.length >= 2);
    if(!IDX || !parcalar.length) return [];
    const bulunan = [];
    for(const [kod, txt] of IDX){
      let hepsiVar = true;
      for(const p of parcalar){ if(txt.indexOf(p) < 0){ hepsiVar = false; break; } }
      if(!hepsiVar) continue;
      // puan: kelime kodun KENDİ tanımında (son › parçası) geçiyorsa öne al; kısa metin öne al
      const sonAyrac = txt.lastIndexOf('›');
      const kendi = sonAyrac >= 0 ? txt.slice(sonAyrac+1) : txt;
      let puan = 0;
      for(const p of parcalar){ if(kendi.indexOf(p) >= 0) puan += 10; }
      puan -= txt.length / 800;
      bulunan.push([puan, kod]);
    }
    bulunan.sort((a,b) => b[0]-a[0]);
    return bulunan.map(x => x[1]);
  }
  function kartlarHtml(kodlar, secFnAdi, ust){
    return kodlar.slice(0, ust).map(kod => {
      const t = TANIM[kod];
      const sonAyrac = t.lastIndexOf('›');
      const zincir = sonAyrac >= 0 ? t.slice(0, sonAyrac).trim() : '';
      const kendi  = sonAyrac >= 0 ? t.slice(sonAyrac+1).trim() : t;
      return `<div onclick="${secFnAdi}('${kod}')" style="padding:10px 12px;margin-top:6px;border:1px solid var(--line2);border-radius:10px;background:#06090f;cursor:pointer" onmouseover="this.style.borderColor='var(--accent)'" onmouseout="this.style.borderColor='var(--line2)'">
        <b style="color:var(--green);font-size:14px">${kod}</b>
        <div style="font-size:13px;color:var(--ink);margin-top:2px">${htmlEsc(kendi)}</div>
        ${zincir ? `<div style="font-size:11.5px;color:var(--dim);margin-top:2px">${htmlEsc(zincir)}</div>` : ''}
      </div>`;
    }).join('') + (kodlar.length > ust ? `<div style="font-size:12px;color:var(--dim);margin-top:8px">+${kodlar.length-ust} eşleşme daha var, kelime ekleyerek daralt.</div>` : '');
  }
  const MESAJ = {
    az: '<div style="font-size:12.5px;color:var(--dim);margin-top:6px">En az 3 harf yaz…</div>',
    yukleniyor: '<div style="font-size:12.5px;color:var(--muted);margin-top:6px">⏳ Tarife cetveli yükleniyor (ilk açılışta bir kez)…</div>',
    bos: '<div style="font-size:13px;color:var(--muted);margin-top:6px">Eşleşme çıkmadı. Resmî tanımlar teknik dille yazılır, eş anlamlı dene (ör. "cep telefonu" → "telefon", "buzdolabı" → "soğutucu") ya da malzemesiyle ara.</div>'
  };
  return { yukle, hazir, tanim, onekli, ara, kartlarHtml, trFold, htmlEsc, harfliMi, MESAJ };
})();
