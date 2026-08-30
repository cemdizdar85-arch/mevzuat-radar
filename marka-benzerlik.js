/* ============================================================================
   MARKA BENZERLİK MOTORU — ORTAK KAYNAK

   NEDEN VAR (29.08.2026)
   Aynı motorun ÜÇ kopyası vardı: marka-izleme.html içinde (istemci),
   motor/marka-watch-kullanici.ps1 içinde (PowerShell portu) ve elle giriş
   için marka-itiraz.html içinde. İtiraz Radarı dördüncüsünü açacaktı.
   Kopya açılmaz: istemci tarafındaki iki sayfa artık bu tek dosyayı okur.
   (PowerShell portu ayrı dil olduğu için kaçınılmaz; eşik değerleri burada
   yazılıdır ki iki taraf aynı sayıyı kullansın.)

   NE YAPAR
   İki marka adının ne kadar karışabileceğini ölçer ve Nice sınıf çakışmasına
   göre ağırlıklandırır.
     · norm  — Türkçe harfleri sadeleştirir, noktalama atar
     · fon   — FONETİK sadeleştirme (i/y, u/v, k/q, s/z, c/j, ph→f, tekrar harf)
     · lev   — Levenshtein uzaklığı
     · benz  — yüzdelik benzerlik
     · riskHesapla — işaret benzerliği × sınıf çakışması

   🔒 SINIF KİLİDİ — bu motorun en önemli kuralı
   Benzer işaret ama FARKLI sınıf → DÜŞÜK. Aynı kelime farklı sınıflarda
   yasal olarak yan yana durabilir (Cem'in "bir sürü DIZDAR var" derdi).
   Sınıf çakışmasını bilmiyorsak (taraflardan biri sınıf vermemişse) puanı
   düşürürüz ama sıfırlamayız — "bilinmiyor" ile "farklı" aynı şey değildir.

   Dayanak: SMK m.6/1 — işaret benzerliği + mal/hizmet benzerliği →
   KARIŞTIRILMA İHTİMALİ. Motor ihtimali ÖLÇMEZ, sıralar; kararı insan verir.
   ============================================================================ */
(function(k){
  'use strict';

  function norm(s){
    return (s||'').toLowerCase()
      .replace(/ç/g,'c').replace(/ğ/g,'g').replace(/ı/g,'i').replace(/İ/g,'i')
      .replace(/ö/g,'o').replace(/ş/g,'s').replace(/ü/g,'u')
      .replace(/[^a-z0-9]/g,'');
  }
  function fon(s){
    return norm(s)
      .replace(/[iy]/g,'i').replace(/[uv]/g,'u').replace(/[kq]/g,'k')
      .replace(/[sz]/g,'s').replace(/[cj]/g,'c').replace(/ph/g,'f')
      .replace(/(.)\1+/g,'$1');
  }
  function lev(a,b){
    var m=a.length,n=b.length; if(!m)return n; if(!n)return m;
    var p=[],i,j; for(i=0;i<=n;i++)p[i]=i;
    for(i=1;i<=m;i++){ var prev=p[0]; p[0]=i;
      for(j=1;j<=n;j++){ var t=p[j];
        p[j]=Math.min(p[j]+1, p[j-1]+1, prev+(a.charAt(i-1)===b.charAt(j-1)?0:1));
        prev=t; } }
    return p[n];
  }
  function benz(a,b){ if(!a||!b)return 0; return Math.round((1-lev(a,b)/Math.max(a.length,b.length))*100); }

  /* Sinif girdisi UC bicimde gelebiliyor - cagiran taraflar farkli:
     dizi [9,42] · metin "9, 42" · zaten kurulmus kume {"9":1,"42":1}.
     Ucu de kabul edilir; yoksa cagiranlari degistirmek gerekirdi ve
     calisan sayfalari kirma riski dogardi. */
  function sinifSet(s){
    if(s && typeof s === 'object' && !Array.isArray(s)) return s;
    var o={};
    (Array.isArray(s) ? s.join(',') : (s||'')).split(/[^0-9]+/).filter(Boolean)
      .forEach(function(x){ o[x]=1; });
    return o;
  }
  function kesisim(a,b){ for(var x in a){ if(b[x]) return true; } return false; }
  function bos(o){ for(var x in o){ return false; } return true; }

  /* kad/ksin = KULLANICININ markasi ve siniflari
     yad/ysin = karsilastirilan basvuru
     Doner: {risk, isaret, yazim, fonetik, cak}  cak: true|false|null(bilinmiyor) */
  function riskHesapla(kad, ksin, yad, ysin){
    var yazim   = benz(norm(kad), norm(yad));
    var fonetik = benz(fon(kad),  fon(yad));
    var isaret  = Math.max(yazim, fonetik);
    var a = sinifSet(ksin), b = sinifSet(ysin);
    var cak = (!bos(a) && !bos(b)) ? kesisim(a,b) : null;
    var risk;
    if(cak === true)      risk = isaret;            // ayni sinif: tam agirlik
    else if(cak === null) risk = Math.round(isaret*0.85);  // bilinmiyor: hafif indir
    else                  risk = Math.round(isaret*0.55);  // FARKLI sinif: zayif (m.6)
    return { risk:risk, isaret:isaret, yazim:yazim, fonetik:fonetik, cak:cak };
  }

  function seviye(r){ return r>=70 ? ['YÜKSEK','y'] : r>=45 ? ['ORTA','o'] : ['DÜŞÜK','d']; }

  /* PowerShell portuyla (motor/marka-watch-kullanici.ps1) AYNI kalsin diye
     esikler burada yazili - iki taraf ayni sayiyi kullanmali. */
  var ESIK = { isaret:65, yuksek:70, orta:45, farkliSinifCarpan:0.55, bilinmiyorCarpan:0.85 };

  k.MarkaBenzerlik = { norm:norm, fon:fon, lev:lev, benz:benz,
                       sinifSet:sinifSet, riskHesapla:riskHesapla,
                       seviye:seviye, ESIK:ESIK };
})(window);
