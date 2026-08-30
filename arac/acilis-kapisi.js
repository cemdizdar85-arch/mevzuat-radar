/* ============================================================================
   AÇILIŞ KAPISI — "bu sayfa gerçekten açılıyor mu?"

   NEDEN VAR (29.08.2026)
   Cem "sadece marka işine bakalım" dedi; o turda çıkan üç kusurun ÜÇÜ DE
   SESSİZ ÖLÜMDÜ - hiçbiri hata vermiyor, hiçbiri kırmızı yakmıyor, sadece
   işi yapmıyordu:
     · marka-rapor.html'de kagit div'inde IKI id vardi. HTML ayristiricisi
       birinciyi alir, ikinciyi atar; betik ikinciyi ariyordu -> her dal
       ilk satirinda patliyordu. Sayfa sonsuza kadar "Rapor yukleniyor..."
       gosteriyordu ve portfoy panosundaki "Rapor al" dugmesi OLU bir
       sayfaya goturuyordu. Musavirin muvekkiline gonderecegi belge buydu.
     · iki marka sayfasi hala dis CDN'den (esm.sh) kutuphane cekiyordu.
   Kurulu kapilarin hicbiri bunlari goremezdi: kontrast kapisi RENGI olcer,
   koku olcer DILI olcer, renk sabiti denetcisi KAYNAK METNI okur. "Sayfa
   acildi mi" diye soran yoktu.

   NE OLCER (uc soru, hepsi sayfayi gercekten acarak)
   1. YAKALANMAMIS HATA: sayfa yuklenirken atilan istisna ya da console.error.
      -> marka-rapor'daki "Cannot set properties of null" tam bu siniftan.
   2. ASILI KALAN YUKLENME: sayfa bekleme suresi sonunda hala bir yuklenme
      metni gosteriyorsa ("...yukleniyor", "okunuyor...") is bitmemis
      demektir. -> "Rapor yukleniyor..." tam bu siniftan.
   3. DIS KAYNAK: sayfanin cektigi her alt kaynak KENDI sunucumuzdan mi?
      Sitenin dis istek sayisi 19.08'de bilerek sifira indirildi; bir sayfa
      yeniden disariya baglanirsa vaadimiz ucuncu tarafa bagimli hale gelir.

   YANLIS ALARM FRENLERI (surekli kirmizi kapi kapi degildir)
   - Bekleme suresi UZUN (VARSAYILAN 6 sn): agdan veri ceken sayfalar
     (durum.html, kartlar.html) yetissin diye. Yetismezse bu gercekten
     kullanicinin da gordugu hal olur.
   - Yuklenme metni ancak GORUNUR bir ogede sayilir (display:none olan
     sablon metinleri sayilmaz) ve sayfanin GOVDESI kisaysa (<400 karakter)
     aranir; uzun sayfada gecen "yukleniyor" kelimesi kusur degildir.
   - Sunucu 4xx/5xx dondurmesi TEK BASINA kirmizi degildir: jeton isteyen
     uclar (marka_talep_sonuc) bilerek hata doner. Yalniz SAYFA KAYNAKLARI
     (script/stylesheet/font/img) icin 404 kirmizidir.
   - Olculemeyen sayfa "temiz" sayilmaz: ucuncu sonuc KOR.

   API maliyeti SIFIR. Dis baglanti YOK. Bagimlilik YOK.
   Tarayici surucusu arac/tarayici.js ile PAYLASILIR (kopya acilmaz).

   Kullanim:  node arac/acilis-kapisi.js
              node arac/acilis-kapisi.js marka-rapor.html gtip.html
   ============================================================================ */
'use strict';
const { spawn } = require('child_process');
const fs   = require('fs');
const path = require('path');
const { tarayiciAc, BAKILAN_YOLLAR, bekle } = require('./tarayici.js');

const KOK      = path.resolve(__dirname, '..');
const PORT     = 8141;                 // kontrast kapisi 8137 kullaniyor
const BEKLE_MS = 6000;                 // ag isi yapan sayfalar yetissin
const GOVDE_ESIK = 400;                // "asili kaldi" yalnizca kisa govdede aranir
const RAPOR_YOL  = path.join(KOK, 'veri', 'acilis-raporu.json');

/* Bu kaliplar EKRANDA kalirsa is bitmemis demektir. Turkce buyuk/kucuk
   harf tuzagi (I/ı) yuzunden desen hem 'I' hem 'İ' hem 'ı' karsilar. */
const YUKLENME = /(y[uü]kleniyor|okunuyor|haz[iı]rlan[iı]yor|loading\b|l[uü]tfen bekleyin)/i;

/* Bilincli dis bagimliliklar (veri/dis-kaynak-izinli.json). Ilk kosuda
   olculdu: sitenin "dis istek sifir" iddiasi tam degilmis - GoatCounter
   sayaci 30+ sayfada duruyor ve bu BILINCLI. Listede olmayan her dis
   sunucu KIRMIZIDIR; boylece yeni bir ucuncu taraf sessizce giremez. */
const IZINLI = (()=>{
  try{
    const j = JSON.parse(fs.readFileSync(path.join(KOK,'veri','dis-kaynak-izinli.json'),'utf8'));
    return new Set((j.izinli||[]).map(x=>String(x.sunucu||'').toLowerCase()).filter(Boolean));
  }catch(e){ return new Set(); }
})();
const izinliMi = (u)=>{
  try{ const h = new URL(u, 'http://x').hostname.toLowerCase();
       return IZINLI.has(h) || [...IZINLI].some(a=>h===a || h.endsWith('.'+a)); }
  catch(e){ return false; }
};

function raporYaz(icerik){
  try{
    fs.mkdirSync(path.dirname(RAPOR_YOL), {recursive:true});
    fs.writeFileSync(RAPOR_YOL, JSON.stringify({ tarih:new Date().toISOString().slice(0,19).replace('T',' '), ...icerik }, null, 2));
  }catch(e){ console.log('  (rapor yazilamadi: '+e.message+')'); }
}

/* Sayfa icinde kosar: govde metni + gorunur yuklenme metni */
const SAYFA_OLCUM = function(YUKLENME_KAYNAK, GOVDE_ESIK){
  const re = new RegExp(YUKLENME_KAYNAK, 'i');
  const govde = (document.body ? document.body.innerText : '') || '';
  const sade = govde.replace(/\s+/g,' ').trim();
  let asili = null;
  if(sade.length < GOVDE_ESIK){
    const hepsi = document.querySelectorAll('body *');
    for(let i=0;i<hepsi.length;i++){
      const el = hepsi[i];
      let metin = '';
      for(let j=0;j<el.childNodes.length;j++)
        if(el.childNodes[j].nodeType === 3) metin += el.childNodes[j].nodeValue;
      metin = metin.replace(/\s+/g,' ').trim();
      if(!metin || !re.test(metin)) continue;
      const st = getComputedStyle(el);
      if(st.display==='none' || st.visibility==='hidden' || parseFloat(st.opacity)===0) continue;
      const r = el.getBoundingClientRect();
      if(!r.width || !r.height) continue;
      asili = { oge: el.tagName.toLowerCase() + (el.id ? '#'+el.id : ''), yazi: metin.slice(0,70) };
      break;
    }
  }
  return { govdeUzunluk: sade.length, govdeBas: sade.slice(0,90), asili: asili };
};

(async function(){
  const secili = process.argv.slice(2).filter(a=>a.endsWith('.html'));
  const sayfalar = secili.length ? secili
    : fs.readdirSync(KOK).filter(f=>f.endsWith('.html'))
        .filter(f=>!/-yedek|^_/.test(f)).sort();
  if(!sayfalar.length){ console.log('ACILIS KAPISI: kokte .html yok, atlandi.'); process.exit(0); }

  const ci = process.env.CI === 'true' || process.env.GITHUB_ACTIONS === 'true';

  const t = await tarayiciAc();
  if(t.hata){
    /* Kor kalma kurali: olcemedigimizde "temiz" demeyiz. */
    console.log('ACILIS KAPISI: KOR — tarayici acilmadi ('+t.hata+').');
    if(t.bakilan) for(const y of t.bakilan.slice(0,12)) console.log('    ' + y);
    if(t.stderr) console.log('  chrome stderr: ' + String(t.stderr).slice(0,600));
    raporYaz({ durum:'KOR', sebep:t.hata, ci, bakilan_yol_sayisi:(t.bakilan||BAKILAN_YOLLAR).length });
    process.exit(ci ? 1 : 0);
  }

  const sunucu = spawn(process.execPath, [path.join(KOK,'arac','yerel-sunucu.js')],
                       { env:{...process.env, PORT:String(PORT)}, stdio:'ignore' });
  await bekle(700);
  const bitir = (kod)=>{ try{t.kapat();}catch(e){} try{sunucu.kill();}catch(e){} process.exit(kod); };

  console.log('ACILIS KAPISI: '+sayfalar.length+' sayfa · bekleme '+(BEKLE_MS/1000)+' sn.');
  const olcumIfade = '('+SAYFA_OLCUM.toString()+')('+JSON.stringify(YUKLENME.source)+','+GOVDE_ESIK+')';
  const KAYNAK_TUR = new Set(['Script','Stylesheet','Font','Image','Media','Manifest']);

  const sonuc = [];
  for(const sayfa of sayfalar){
    let hedef=null, oturum=null;
    const hatalar=[], disKaynak=[], eksikKaynak=[];
    try{
      const c = await t.cdp.cagir('Target.createTarget', { url:'about:blank' });
      hedef = c.targetId;
      const a = await t.cdp.cagir('Target.attachToTarget', { targetId:hedef, flatten:true });
      oturum = a.sessionId;

      /* Olaylar oturum kimligiyle gelir - baska sekmenin gurultusu karismasin */
      const dinle = (m)=>{
        try{
          const o = JSON.parse(m.data);
          if(o.sessionId !== oturum) return;
          if(o.method === 'Runtime.exceptionThrown'){
            const d = o.params.exceptionDetails || {};
            const msg = (d.exception && (d.exception.description || d.exception.value)) || d.text || 'bilinmeyen istisna';
            hatalar.push({ tur:'istisna', mesaj:String(msg).replace(/\s+/g,' ').slice(0,180),
                           yer:(d.url||'')+':'+((d.lineNumber||0)+1) });
          }
          if(o.method === 'Runtime.consoleAPICalled' && o.params.type === 'error'){
            const arg = (o.params.args||[]).map(x=>x.description||x.value||'').join(' ');
            hatalar.push({ tur:'console.error', mesaj:String(arg).replace(/\s+/g,' ').slice(0,180), yer:'' });
          }
          if(o.method === 'Network.requestWillBeSent'){
            const u = o.params.request.url || '';
            if(/^https?:/i.test(u) && !/^https?:\/\/(127\.0\.0\.1|localhost)/i.test(u) && !izinliMi(u))
              disKaynak.push({ url:u.slice(0,140), tur:o.params.type||'?' });
          }
          if(o.method === 'Network.responseReceived'){
            const r = o.params.response || {};
            if(r.status >= 400 && KAYNAK_TUR.has(o.params.type||''))
              eksikKaynak.push({ url:String(r.url||'').slice(0,140), kod:r.status, tur:o.params.type });
          }
        }catch(e){}
      };
      t.cdp.ws.addEventListener('message', dinle);

      await t.cdp.cagir('Runtime.enable', {}, oturum);
      await t.cdp.cagir('Network.enable', {}, oturum);
      await t.cdp.cagir('Page.enable', {}, oturum);
      await t.cdp.cagir('Page.navigate', { url:'http://127.0.0.1:'+PORT+'/'+sayfa+'?kapi='+Date.now() }, oturum);
      await bekle(BEKLE_MS);

      const r = await t.cdp.cagir('Runtime.evaluate',
        { expression:olcumIfade, returnByValue:true, awaitPromise:true }, oturum);
      t.cdp.ws.removeEventListener('message', dinle);
      if(r.exceptionDetails) throw new Error(r.exceptionDetails.text || 'sayfa ici hata');
      const v = r.result.value || {};

      sonuc.push({ sayfa, govde:v.govdeUzunluk, govdeBas:v.govdeBas, asili:v.asili,
                   hatalar, disKaynak, eksikKaynak });
    }catch(e){
      sonuc.push({ sayfa, olculemedi:true, sebep:String(e.message).slice(0,80) });
    }finally{
      if(hedef) try{ await t.cdp.cagir('Target.closeTarget',{targetId:hedef}); }catch(e){}
    }
  }

  /* --- hüküm ------------------------------------------------------------ */
  const olculemeyen = sonuc.filter(s=>s.olculemedi);
  const hataliSayfa = sonuc.filter(s=>s.hatalar && s.hatalar.length);
  const asiliSayfa  = sonuc.filter(s=>s.asili);
  const disSayfa    = sonuc.filter(s=>s.disKaynak && s.disKaynak.length);
  const eksikSayfa  = sonuc.filter(s=>s.eksikKaynak && s.eksikKaynak.length);
  const kirikSayi   = hataliSayfa.length + asiliSayfa.length + disSayfa.length + eksikSayfa.length;

  raporYaz({
    durum: kirikSayi ? 'KIRMIZI' : (olculemeyen.length ? 'KOR' : 'YESIL'),
    ci, sayfa: sayfalar.length, bekleme_ms: BEKLE_MS,
    yakalanmamis_hata_sayfa: hataliSayfa.length,
    asili_yuklenme_sayfa: asiliSayfa.length,
    dis_kaynak_sayfa: disSayfa.length,
    eksik_kaynak_sayfa: eksikSayfa.length,
    olculemeyen: olculemeyen.length,
    yakalanmamis_hata: hataliSayfa.map(s=>({ sayfa:s.sayfa, hatalar:s.hatalar.slice(0,4) })),
    asili_yuklenme: asiliSayfa.map(s=>({ sayfa:s.sayfa, oge:s.asili.oge, yazi:s.asili.yazi, govde:s.govde })),
    dis_kaynak: disSayfa.map(s=>({ sayfa:s.sayfa, kaynaklar:s.disKaynak.slice(0,6) })),
    eksik_kaynak: eksikSayfa.map(s=>({ sayfa:s.sayfa, kaynaklar:s.eksikKaynak.slice(0,6) })),
    olculemeyenler: olculemeyen.map(s=>({ sayfa:s.sayfa, sebep:s.sebep||'bilinmiyor' }))
  });

  console.log('  Yakalanmamis hata: '+hataliSayfa.length+' sayfa   Asili yuklenme: '+asiliSayfa.length
              +'   Dis kaynak: '+disSayfa.length+'   Eksik kaynak: '+eksikSayfa.length
              +(olculemeyen.length?('   OLCULEMEDI: '+olculemeyen.length):''));

  const yaz = (baslik, liste, satir)=>{
    if(!liste.length) return;
    console.log('');
    console.log('  KIRMIZI — '+baslik);
    for(const s of liste.slice(0,12)) satir(s);
  };
  yaz('sayfa acilirken hata atiyor:', hataliSayfa, s=>{
    console.log('    '+s.sayfa);
    for(const h of s.hatalar.slice(0,3)) console.log('      ['+h.tur+'] '+h.mesaj+(h.yer?('  @ '+h.yer):''));
  });
  yaz('sayfa hala "yukleniyor" diyor (is bitmemis):', asiliSayfa, s=>
    console.log('    '+s.sayfa+'  <'+s.asili.oge+'> "'+s.asili.yazi+'"  (govde '+s.govde+' karakter)'));
  yaz('sayfa DISARIDAN kaynak cekiyor (dis istek sifir olmali):', disSayfa, s=>{
    console.log('    '+s.sayfa);
    for(const d of s.disKaynak.slice(0,4)) console.log('      '+d.tur+'  '+d.url);
  });
  yaz('sayfa kaynagi bulunamadi (404/500):', eksikSayfa, s=>{
    console.log('    '+s.sayfa);
    for(const d of s.eksikKaynak.slice(0,4)) console.log('      '+d.kod+'  '+d.tur+'  '+d.url);
  });

  if(olculemeyen.length){
    console.log('');
    console.log('  KOR — su sayfalar olculemedi (temiz DEGIL, bilinmiyor):');
    for(const s of olculemeyen) console.log('    '+s.sayfa+(s.sebep?('  <- '+s.sebep):''));
  }

  if(kirikSayi){ console.log(''); console.log('  Ayrinti: veri/acilis-raporu.json'); bitir(1); }
  if(olculemeyen.length){ bitir(1); }
  console.log('  Temiz - her sayfa aciliyor, asili kalan yok, dis kaynak yok.');
  bitir(0);
})().catch(e=>{ console.log('ACILIS KAPISI: KOR — '+e.message); process.exit(0); });
