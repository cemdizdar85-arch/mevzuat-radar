# ============================================================================
#  SEO SAYFA ÜRETECİ — Mevzuat Radarı
#  Eşik verisini alttaki $pages tablosundan okur, şablona basar, HTML üretir.
#  Yeni sayfa = tabloya bir kayıt ekle, scripti tekrar çalıştır.
#  Çalıştırma:  bu klasörde  ->  powershell -ExecutionPolicy Bypass -File olustur.ps1
# ============================================================================

$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$enc  = New-Object System.Text.UTF8Encoding($false)  # UTF-8, BOM'suz

# ---- ORTAK CSS -------------------------------------------------------------
$CSS = @'
:root{--bg:#06090f;--panel:#0d141e;--line:rgba(255,255,255,.08);--line2:rgba(255,255,255,.13);
--ink:#eef2f7;--muted:#93a1b3;--dim:#5d6b7c;--accent:#3e9bff;--accent2:#26d0fe;
--grad:linear-gradient(135deg,#2f7bff 0%,#26d0fe 100%);
--red:#ff6b5e;--amber:#ffc24b;--green:#3ddc97;--slate:#9fb0c2}
*{box-sizing:border-box}
body{margin:0;background:var(--bg);color:var(--ink);font-family:-apple-system,"SF Pro Display","Segoe UI Variable Display","Segoe UI",system-ui,Roboto,Arial,sans-serif;line-height:1.65;-webkit-font-smoothing:antialiased;font-variant-numeric:tabular-nums}
::selection{background:rgba(62,155,255,.35)}
a{color:var(--accent2)}
.wrap{max-width:760px;margin:0 auto;padding:22px 18px 70px}
.top{display:flex;align-items:center;gap:10px;font-size:13px;margin-bottom:22px;color:var(--dim)}
.top a{color:var(--muted);text-decoration:none;font-weight:600}
.top a:hover{color:var(--ink)}
.logo{width:32px;height:32px;border-radius:9px;background:var(--grad);display:grid;place-items:center;color:#03101f;font-weight:800;font-size:14px;box-shadow:0 4px 18px rgba(46,140,255,.3)}
h1{font-size:clamp(24px,4.5vw,32px);line-height:1.18;margin:6px 0 6px;letter-spacing:-.9px;font-weight:800}
.ust{color:var(--accent2);font-size:11.5px;font-weight:800;text-transform:uppercase;letter-spacing:1.4px}
.card{background:var(--panel);border:1px solid var(--line2);border-radius:18px;padding:24px;margin:20px 0;box-shadow:0 20px 60px rgba(0,0,0,.35)}
.hesap label{display:block;font-size:13px;font-weight:600;margin:12px 0 6px}
.hesap input,.hesap select{width:100%;padding:13px 14px;border:1px solid var(--line2);border-radius:12px;background:#0a0f17;color:var(--ink);font-size:16px;font-family:inherit;transition:border-color .2s,box-shadow .2s}
.hesap input::placeholder{color:var(--dim)}
.hesap input:focus,.hesap select:focus{outline:none;border-color:var(--accent);box-shadow:0 0 0 3px rgba(62,155,255,.18)}
.btn{appearance:none;border:0;cursor:pointer;font-family:inherit;font-weight:700;font-size:14.5px;padding:12px 22px;border-radius:12px;background:var(--grad);color:#03101f;margin-top:16px;box-shadow:0 6px 24px rgba(46,140,255,.35);transition:transform .18s,box-shadow .18s,filter .18s}
.btn:hover{transform:translateY(-2px);box-shadow:0 10px 32px rgba(46,140,255,.5);filter:brightness(1.05)}
.sonuc{display:none;margin-top:16px;padding:14px 16px;border-radius:12px;border:1px solid;border-left-width:4px;font-size:14.5px}
.sonuc.evet{background:rgba(255,107,94,.09);border-color:rgba(255,107,94,.3);color:var(--red)}
.sonuc.yak{background:rgba(255,194,75,.09);border-color:rgba(255,194,75,.3);color:var(--amber)}
.sonuc.hayir{background:rgba(61,220,151,.09);border-color:rgba(61,220,151,.3);color:var(--green)}
.sonuc.bilgi,.sonuc.notr{background:rgba(159,176,194,.08);border-color:rgba(159,176,194,.25);color:var(--slate)}
.govde p{margin:13px 0;color:var(--muted);font-size:14.5px}
.govde p b{color:var(--ink)}
.cta{background:linear-gradient(135deg,rgba(47,123,255,.16),rgba(38,208,254,.07)),var(--panel);border:1px solid rgba(62,155,255,.3);color:var(--ink);border-radius:18px;padding:26px;margin-top:30px}
.cta h2{margin:0 0 6px;font-size:19px;letter-spacing:-.4px}
.cta p{margin:0 0 16px;font-size:13.5px;color:var(--muted)}
.cta a.btn{display:inline-block;text-decoration:none;margin-top:0}
.ilgili{font-size:14px;color:var(--muted)}.ilgili a{display:inline-block;margin:4px 12px 4px 0}
.dip{font-size:11.5px;color:var(--dim);margin-top:28px;padding-top:15px;border-top:1px solid var(--line)}
'@

# ---- ORTAK ŞABLON (JS dahil; @@...@@ belirteçleri PS'de değişir) ------------
$TPL = @'
<!doctype html>
<html lang="tr">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>@@TITLE@@</title>
<meta name="description" content="@@META@@">
<style>@@CSS@@</style>
<script type="application/ld+json">@@FAQ@@</script>
</head>
<body>
<div class="wrap">
  <div class="top"><span class="logo">MR</span><a href="../index.html">Mevzuat Radarı</a> · <a href="index.html">Eşik rehberi</a></div>
  <div class="ust">@@UST@@</div>
  <h1>@@H1@@</h1>

  <div class="card hesap">
    <div id="hesapKutu"></div>
    <button class="btn" id="hesapBtn" onclick="hesapla()">Hesapla</button>
    <div class="sonuc" id="sonuc"></div>
  </div>

  <div class="govde">@@BODY@@</div>

  <div class="cta">
    <h2>Bu tek yükümlülük. Peki diğerleri?</h2>
    <p>Firmanın tabi olduğu <b>tüm</b> yasal yükümlülükleri 3 dakikada, tek seferde gör — ücretsiz Yükümlülük Karnesi.</p>
    <a class="btn" href="../index.html">Ücretsiz karnemi çıkar →</a>
  </div>

  <p class="ilgili"><b>İlgili:</b> @@ILGILI@@</p>

  <div class="dip">
    Dayanak: @@DAYANAK@@ · Hazırlayan SMMM Cem Dizdar — Mevzuat Radarı.
    Bilgilendirme amaçlıdır; kesin sonuç için mevzuat metni ve uzman görüşü esastır.
    Eşik değerleri Temmuz 2026 itibarıyla güncellenmiştir.
  </div>
</div>

<script>
const HESAP = @@HESAP@@;
const fmt = n => new Intl.NumberFormat('tr-TR').format(n);
const pnum = id => { const v=(document.getElementById(id).value||'').replace(/[^\d]/g,''); return v===''?null:parseInt(v,10); };
const lbl = t => `<label>${t}</label>`;
const inpt = (id,ph)=>`<input id="${id}" inputmode="numeric" autocomplete="off" placeholder="${ph}">`;
function goster(msg,cls){ const s=document.getElementById('sonuc'); s.innerHTML=msg; s.className='sonuc '+cls; s.style.display='block'; }

(function(){
  const H=HESAP, box=document.getElementById('hesapKutu');
  if(H.tip==='sayi') box.innerHTML=lbl(H.etiket)+inpt('v0',H.birim==='TL'?'ör. 3.000.000':'ör. 25');
  else if(H.tip==='veya'||H.tip==='coklu') box.innerHTML=H.kriterler.map((k,i)=>lbl(k.ad+' ('+k.birim+')')+inpt('v'+i,k.birim==='TL'?'ör. 100.000.000':'ör. 150')).join('');
  else if(H.tip==='kademeli') box.innerHTML=lbl(H.etiket)+inpt('v0','ör. 120');
  else if(H.tip==='kategori') box.innerHTML='<label>Şirket türü</label><select id="tur"><option value="as">Anonim Şirket (AŞ)</option><option value="diger">Diğer</option></select>'+lbl('Esas sermaye (TL)')+inpt('v0','ör. 1.250.000');
  else if(H.tip==='bilgi'){ document.getElementById('hesapBtn').style.display='none'; goster(H.metin,'bilgi'); }
  box.querySelectorAll('input').forEach(el=>el.addEventListener('input',e=>{const v=e.target.value.replace(/[^\d]/g,'');e.target.value=v?fmt(parseInt(v,10)):'';}));
})();

function hesapla(){
  const H=HESAP;
  if(H.tip==='sayi'){
    const v=pnum('v0'); if(v===null){goster('Bir sayı gir.','notr');return;}
    if(v>=H.esik){ let m='<b>Evet, kapsamdasın.</b> '+(H.evet||('Eşik '+fmt(H.esik)+' '+H.birim+', sen '+fmt(v)+'.'));
      if(H.kota) m+=' En az <b>'+Math.floor(v*H.kota+0.5)+'</b> '+(H.kotaBirim||'')+' gerekir. Kesir kuralı: yarıma kadar dikkate alınmaz, yarım ve üzeri tama yuvarlanır.'; goster(m,'evet'); }
    else if(v>=H.esik*0.8) goster('<b>Sınırdasın.</b> Eşik '+fmt(H.esik)+' '+H.birim+'; '+fmt(v)+' ile çok yaklaştın.','yak');
    else goster('<b>Şimdilik kapsam dışısın.</b> Eşik '+fmt(H.esik)+' '+H.birim+', sen '+fmt(v)+'.','hayir');
  } else if(H.tip==='veya'){
    const vals=H.kriterler.map((k,i)=>pnum('v'+i));
    if(vals.every(x=>x===null)){goster('En az bir değer gir.','notr');return;}
    const asan=H.kriterler.filter((k,i)=>vals[i]!==null&&vals[i]>=k.esik);
    if(asan.length) goster('<b>Evet, kapsamdasın.</b> '+asan.map(k=>k.ad).join(' / ')+' eşiğini aşıyorsun.','evet');
    else goster('<b>Şimdilik kapsam dışısın.</b> İki eşikten birini aşınca kapsama girersin.','hayir');
  } else if(H.tip==='coklu'){
    const vals=H.kriterler.map((k,i)=>pnum('v'+i));
    if(vals.every(x=>x===null)){goster('En az iki değer gir.','notr');return;}
    const asan=H.kriterler.filter((k,i)=>vals[i]!==null&&vals[i]>=k.esik);
    if(asan.length>=H.gerek) goster('<b>Evet, kapsamdasın.</b> '+asan.length+' ölçütü aşıyorsun ('+asan.map(k=>k.ad).join(', ')+'); en az '+H.gerek+' yeterli.','evet');
    else goster('<b>Şimdilik kapsam dışısın.</b> '+asan.length+' ölçüt aşılı; kapsam için en az '+H.gerek+' gerekir (2 yıl üst üste).','hayir');
  } else if(H.tip==='kademeli'){
    const v=pnum('v0'); if(v===null){goster('Bir sayı gir.','notr');return;}
    const b=H.basamaklar.find(x=>v>=x.alt);
    if(b) goster('<b>'+b.ad+'.</b> '+fmt(v)+' '+(H.birimAd||'')+' ile bu basamaktasın.','evet');
    else goster('<b>Şimdilik kapsam dışısın.</b> İlk basamak '+H.basamaklar[H.basamaklar.length-1].alt+' değerinde başlar.','hayir');
  } else if(H.tip==='kategori'){
    const tur=document.getElementById('tur').value, v=pnum('v0');
    if(tur!=='as'){goster('<b>Kapsam dışı.</b> Bu yükümlülük anonim şirketler içindir.','hayir');return;}
    if(v===null){goster('Sermayeni gir.','notr');return;}
    if(v>=H.esik) goster('<b>Evet, kapsamdasın.</b> '+fmt(H.esik)+' TL ve üzeri sermayeli anonim şirketler için zorunlu; sen '+fmt(v)+' TL.','evet');
    else goster('<b>Şimdilik kapsam dışısın.</b> Eşik '+fmt(H.esik)+' TL sermaye; sen '+fmt(v)+' TL.','hayir');
  }
}
</script>
<script data-goatcounter="https://mevzuatradar.goatcounter.com/count" async src="//gc.zgo.at/count.js"></script>
</body>
</html>
'@

# ---- VERİ: her kayıt bir SEO sayfası --------------------------------------
$pages = @(
  @{ slug='e-fatura-zorunlulugu'; ust='e-Dönüşüm'; kisa='e-Fatura zorunluluğu';
     title='e-Fatura Zorunluluğu 2026: Hangi Ciroda Başlıyor? | Mevzuat Radarı';
     h1='e-Fatura zorunluluğu hangi ciroda başlıyor?';
     meta='2025 cironuz 3 milyon TL ve üzeriyse 1 Temmuz 2026''da e-Faturaya geçmek zorundasınız. Cironuzu girin, saniyede öğrenin.';
     hesap=@{tip='sayi';etiket='2025 yılı brüt satış hasılatın (TL)';esik=3000000;birim='TL';evet='Genel eşik 3.000.000 TL; 1 Temmuz 2026 itibarıyla e-Fatura kapsamındasın. e-Arşiv ve e-Defter de bununla gelir.'};
     body=@('Genel kural: 2025 hesap döneminde brüt satış hasılatı <b>3.000.000 TL</b> ve üzeri olan mükellefler 1 Temmuz 2026''dan itibaren e-Fatura kullanmak zorundadır.',
            'Bazı sektörlerde eşik daha düşüktür: e-ticaret, gayrimenkul ve motorlu araç alım-satımında sınır <b>500.000 TL</b>''dir. Kültür-turizm belgeli oteller ise ciroya bakılmaksızın kapsamdadır.',
            'e-Faturaya geçen mükellef, e-Arşiv Fatura ve e-Defter yükümlülüğüne de girer. Bu üçü birlikte düşünülür.');
     dayanak='VUK 509 Sıra No.lu Genel Tebliğ'; ilgili=@('e-defter-zorunlulugu','e-irsaliye-zorunlulugu','bagimsiz-denetim-esigi') },

  @{ slug='e-defter-zorunlulugu'; ust='e-Dönüşüm'; kisa='e-Defter zorunluluğu';
     title='e-Defter Zorunluluğu 2026: Kimler Tutmak Zorunda? | Mevzuat Radarı';
     h1='e-Defter zorunluluğu kimlere geldi?';
     meta='e-Faturaya geçen mükellefler e-Defter tutmak zorunda. Cironuzu girip kapsamda mısınız görün.';
     hesap=@{tip='sayi';etiket='2025 yılı brüt satış hasılatın (TL)';esik=3000000;birim='TL';evet='e-Fatura kapsamındasın; bununla birlikte e-Defter (yevmiye + kebir) tutmak ve beratları GİB''e yüklemek zorundasın.'};
     body=@('e-Defter yükümlülüğü, çoğunlukla e-Fatura mükellefiyetiyle birlikte doğar. e-Faturaya geçen mükellef, kâğıt yevmiye ve kebir defteri yerine elektronik defter tutar.',
            'Defter beratları belirlenen dönemlerde (aylık ya da üç aylık) GİB''e yüklenir. Yüklememe, usulsüzlük cezası doğurur.',
            'Ciro eşiği e-Fatura ile aynıdır: 2025 için genel sınır 3.000.000 TL''dir.');
     dayanak='VUK ve ilgili e-Defter tebliğleri'; ilgili=@('e-fatura-zorunlulugu','e-irsaliye-zorunlulugu') },

  @{ slug='e-irsaliye-zorunlulugu'; ust='e-Dönüşüm'; kisa='e-İrsaliye zorunluluğu';
     title='e-İrsaliye Zorunluluğu 2026: Ciro Haddi Kaç TL? | Mevzuat Radarı';
     h1='e-İrsaliye zorunluluğu hangi ciroda başlıyor?';
     meta='2024 veya 2025 cironuz 10 milyon TL ve üzeriyse 1 Temmuz 2026''da e-İrsaliye zorunlu. Kontrol edin.';
     hesap=@{tip='sayi';etiket='Brüt satış hasılatın (TL)';esik=10000000;birim='TL';evet='Genel eşik 10.000.000 TL; e-Fatura mükellefi olarak e-İrsaliye kapsamındasın.'};
     body=@('Genel kural: 2024 veya 2025 hesap döneminde brüt satış hasılatı <b>10.000.000 TL</b> ve üzeri olan e-Fatura mükellefleri, 1 Temmuz 2026''dan itibaren e-İrsaliye kullanmak zorundadır.',
            'Bazı sektörler ciroya bakılmaksızın kapsamdadır: ÖTV I ve III sayılı liste (akaryakıt, alkol, tütün), şeker, demir-çelik üreticileri, maden ruhsatı sahipleri ve Hal Kayıt Sistemi''ne tabi sebze-meyve tüccarları.',
            'İnşaat Demiri İzleme Sistemi (İDİS) kapsamındakiler için eşik 1.000.000 TL''ye iner.');
     dayanak='VUK 509 Sıra No.lu Genel Tebliğ'; ilgili=@('e-fatura-zorunlulugu','e-defter-zorunlulugu') },

  @{ slug='bagimsiz-denetim-esigi'; ust='Denetim & TTK'; kisa='Bağımsız denetim eşiği';
     title='Bağımsız Denetim Eşikleri 2026: Şirketiniz Kapsamda mı? | Mevzuat Radarı';
     h1='Bağımsız denetime tabi misin? (2026 eşikleri)';
     meta='2026: aktif 500M TL, net satış 1 milyar TL, 150 çalışan. En az ikisini 2 yıl üst üste aşan şirket denetime tabi. Hesaplayın.';
     hesap=@{tip='coklu';gerek=2;kriterler=@(@{ad='Aktif toplamı';esik=500000000;birim='TL'},@{ad='Net satış hasılatı';esik=1000000000;birim='TL'},@{ad='Çalışan sayısı';esik=150;birim='kişi'})};
     body=@('2026 hesap dönemi için genel eşikler (11066 sayılı Cumhurbaşkanı Kararı, 17.03.2026 RG): <b>aktif toplamı 500 milyon TL</b>, <b>yıllık net satış hasılatı 1 milyar TL</b>, <b>çalışan sayısı 150</b>.',
            'Bu üç ölçütten en az <b>ikisini</b>, <b>arka arkaya iki hesap dönemi</b> aşan şirketler, izleyen dönemden itibaren bağımsız denetime tabi olur.',
            'Bağımsız denetime tabi olmak, TTK 1524 gereği internet sitesi açma yükümlülüğünü de tetikler. Halka açık şirketler ve bazı özel sektörler için eşikler daha düşüktür.');
     dayanak='6102 sayılı TTK m.397 ve 11066 sayılı Cumhurbaşkanı Kararı'; ilgili=@('ttk-1524-internet-sitesi','transfer-fiyatlandirmasi') },

  @{ slug='isg-uzmani-isyeri-hekimi'; ust='İş Sağlığı & Güvenliği'; kisa='İSG uzmanı / işyeri hekimi';
     title='Kaç Çalışanda İSG Uzmanı ve İşyeri Hekimi Zorunlu? | Mevzuat Radarı';
     h1='Kaç çalışanda İSG uzmanı zorunlu?';
     meta='Bir kişi bile SGK''lı çalıştıran her işyeri İSG uzmanı ve işyeri hekimi hizmeti almak zorunda. Detaylar burada.';
     hesap=@{tip='bilgi';metin='<b>Bir kişi bile SGK''lı çalıştırıyorsan kapsamdasın.</b> İSG uzmanı ve işyeri hekimi bulundurma/hizmet alma yükümlülüğü çalışan sayısından bağımsızdır; süre ve nitelik tehlike sınıfına göre değişir.'};
     body=@('6331 sayılı Kanuna göre, <b>çalışan sayısına bakılmaksızın</b> bir kişi dahi SGK''lı çalıştıran her işyeri İSG uzmanı ve işyeri hekimi hizmeti almak zorundadır.',
            'Hizmet süresi ve uzmanın sınıfı (A/B/C, hekim nitelikleri) işyerinin tehlike sınıfına (az tehlikeli / tehlikeli / çok tehlikeli) göre belirlenir.',
            'Hizmeti OSGB''den alabilir ya da uygun niteliğe sahip kendi personelini görevlendirebilirsin.');
     dayanak='6331 sayılı İSG Kanunu m.6'; ilgili=@('isg-kurulu','calisan-temsilcisi') },

  @{ slug='isg-kurulu'; ust='İş Sağlığı & Güvenliği'; kisa='İSG kurulu';
     title='Kaç Çalışanda İSG Kurulu Kurmak Zorunlu? | Mevzuat Radarı';
     h1='Kaç çalışanda İSG kurulu zorunlu?';
     meta='50 ve üzeri çalışanı olan, 6 aydan uzun süren işyerleri İSG kurulu kurmak zorunda. Çalışan sayınızı girin.';
     hesap=@{tip='sayi';etiket='Çalışan sayın';esik=50;birim='kişi';evet='50 ve üzeri çalışanı olan, 6 aydan uzun süren işyerlerinde İSG kurulu kurmak zorunlu.'};
     body=@('50 ve daha fazla çalışanı olan ve altı aydan fazla süren işlerin yapıldığı işyerlerinde işveren iş sağlığı ve güvenliği kurulu oluşturmak zorundadır.',
            'Kurul; işveren/vekili, İSG uzmanı, işyeri hekimi, insan kaynakları sorumlusu, çalışan temsilcisi gibi üyelerden oluşur ve düzenli toplanır.',
            'Kurul yükümlülüğü, İSG uzmanı/işyeri hekimi yükümlülüğünden ayrıdır; ikincisi tek çalışanda bile doğar.');
     dayanak='6331 sayılı İSG Kanunu m.22'; ilgili=@('isg-uzmani-isyeri-hekimi','engelli-calistirma') },

  @{ slug='engelli-calistirma'; ust='Çalışan sayısı'; kisa='Engelli çalıştırma kotası';
     title='Engelli Çalıştırma Zorunluluğu: Kaç İşçide, Yüzde Kaç? | Mevzuat Radarı';
     h1='Kaç işçide engelli çalıştırma zorunlu?';
     meta='50 ve üzeri işçi çalıştıran özel sektör işyerleri %3 engelli çalıştırmak zorunda. Kaç engelli gerektiğini hesaplayın.';
     hesap=@{tip='sayi';etiket='İşçi sayın';esik=50;birim='kişi';kota=0.03;kotaBirim='engelli çalışan';evet='50 ve üzeri işçide %3 engelli çalıştırma zorunlu.'};
     body=@('50 veya daha fazla işçi çalıştıran <b>özel sektör</b> işyerleri, işçi sayısının <b>%3''ü</b> kadar engelli çalıştırmak zorundadır (kamuda oran farklıdır).',
            'Kontenjan İŞKUR üzerinden takip edilir. Açık kontenjanı doldurmayan işveren, çalıştırmadığı her engelli ve her ay için idari para cezası öder.',
            'Hesaplayıcı, işçi sayına göre en az kaç engelli çalıştırman gerektiğini gösterir. Kesir kuralı kanundan: yarıma kadar kesirler dikkate alınmaz, yarım ve daha fazlası tama dönüştürülür.');
     dayanak='4857 sayılı İş Kanunu m.30'; ilgili=@('isg-kurulu','toplu-isten-cikarma') },

  @{ slug='verbis-kayit'; ust='Veri / KVKK'; kisa='VERBİS kaydı';
     title='VERBİS Kayıt Zorunluluğu 2026: Eşikler | Mevzuat Radarı';
     h1='VERBİS''e kayıt zorunlu mu?';
     meta='Yıllık çalışan sayısı 50''den çok VEYA bilançosu 100 milyon TL''den çok olan veri sorumluları VERBİS''e kayıt olmak zorunda.';
     hesap=@{tip='veya';kriterler=@(@{ad='Yıllık çalışan sayısı';esik=51;birim='kişi'},@{ad='Yıllık mali bilanço (aktif) toplamı';esik=100000001;birim='TL'})};
     body=@('Yıllık çalışan sayısı <b>50''den çok</b> olan ya da yıllık mali bilanço toplamı <b>100 milyon TL''den çok</b> olan veri sorumluları VERBİS''e kayıt olmak zorundadır (2026 güncel sınır).',
            'Bu eşiklerin altında olsan bile, ana faaliyetin özel nitelikli kişisel veri (sağlık, biyometrik vb.) işlemekse kayıt zorunludur.',
            'Kayıtla birlikte veri işleme envanteri hazırlanır. Kayıt yükümlülüğünü yerine getirmemek idari para cezası doğurur.');
     dayanak='6698 sayılı KVKK ve Kişisel Verileri Koruma Kurulu kararları'; ilgili=@('kep-e-tebligat','bagimsiz-denetim-esigi') },

  @{ slug='avukat-bulundurma'; ust='Şirket türü & sermaye'; kisa='Sözleşmeli avukat';
     title='Anonim Şirkette Avukat Bulundurma Zorunluluğu 2026 | Mevzuat Radarı';
     h1='Şirketin avukat bulundurmak zorunda mı?';
     meta='Esas sermayesi 1.250.000 TL ve üzeri anonim şirketler sözleşmeli avukat bulundurmak zorunda. Kontrol edin.';
     hesap=@{tip='kategori';esik=1250000;birim='TL'};
     body=@('Esas sermayesi <b>1.250.000 TL</b> ve üzeri olan anonim şirketler, sözleşmeli bir avukat bulundurmak zorundadır. Bu eşik, TTK''daki asgari AŞ sermayesinin (250.000 TL) beş katıdır.',
            'Yükümlülük yalnızca anonim şirketleri (ve belirli üye sayısındaki yapı kooperatiflerini) kapsar; limited şirketler için böyle bir zorunluluk yoktur.',
            'Uymayan anonim şirketlere, avukat tayin edilmeyen <b>her ay için</b>, asgari ücretin <b>iki aylık brüt tutarı</b> kadar idari para cezası uygulanır (Av. K. m.35 — tutar asgari ücretle birlikte her yıl değişir).');
     dayanak='1136 sayılı Avukatlık Kanunu m.35'; ilgili=@('kep-e-tebligat','ttk-1524-internet-sitesi') },

  @{ slug='emzirme-odasi-kres'; ust='Çalışan sayısı'; kisa='Emzirme odası / kreş';
     title='Emzirme Odası ve Kreş Zorunluluğu: Kaç Kadın Çalışanda? | Mevzuat Radarı';
     h1='Kaç kadın çalışanda emzirme odası / kreş zorunlu?';
     meta='100-150 kadın çalışanda emzirme odası, 150''den çok kadın çalışanda kreş/yurt zorunlu. Kadın çalışan sayınızı girin.';
     hesap=@{tip='kademeli';etiket='Kadın çalışan sayın';birimAd='kadın çalışan';basamaklar=@(@{alt=151;ad='Kreş / yurt (bakımevi) zorunlu'},@{alt=100;ad='Emzirme odası zorunlu'})};
     body=@('Toplam kadın çalışan sayısı <b>100 ile 150 arasında</b> olan işyerlerinde, 0-1 yaş çocuklar için emzirme odası kurulması zorunludur.',
            'Kadın çalışan sayısı <b>150''den çok</b> ise, 0-6 yaş çocuklar için kreş/yurt (bakımevi) sağlanması gerekir; bu hizmet anlaşmalı kuruluşlardan da alınabilir.',
            'Eşiklerde çalışanın medeni hâli ve yaşı dikkate alınmaz; toplam kadın çalışan sayısı esastır.');
     dayanak='Gebe veya Emziren Kadınların Çalıştırılma Şartları Yönetmeliği'; ilgili=@('engelli-calistirma','isg-kurulu') },

  @{ slug='kep-e-tebligat'; ust='Şirket türü & sermaye'; kisa='KEP / e-Tebligat';
     title='KEP ve e-Tebligat Zorunluluğu: Kimler Almak Zorunda? | Mevzuat Radarı';
     h1='KEP adresi ve e-Tebligat kimlere zorunlu?';
     meta='Tüm sermaye şirketleri (AŞ, Ltd, paylı komandit) KEP adresi almak ve e-Tebligat sistemine dahil olmak zorunda.';
     hesap=@{tip='bilgi';metin='<b>Sermaye şirketiysen (AŞ, Limited, sermayesi paylara bölünmüş komandit) kapsamdasın.</b> KEP adresi almak ve e-Tebligat sistemine dahil olmak zorunludur.'};
     body=@('Anonim, limited ve sermayesi paylara bölünmüş komandit şirketler, resmî tebligatları elektronik ortamda almak üzere KEP adresi edinmek ve e-Tebligat sistemine kaydolmak zorundadır.',
            'Resmî tebligatlar KEP/e-Tebligat kutusuna düşer ve belirli süre sonunda okunmuş sayılır; kutunun düzenli kontrolü önemlidir, aksi hâlde süreler kaçırılabilir.');
     dayanak='7201 sayılı Tebligat Kanunu ve Elektronik Tebligat Yönetmeliği'; ilgili=@('avukat-bulundurma','verbis-kayit') },

  @{ slug='calisan-temsilcisi'; ust='İş Sağlığı & Güvenliği'; kisa='Çalışan temsilcisi';
     title='İSG Çalışan Temsilcisi: Kaç Çalışanda Zorunlu? | Mevzuat Radarı';
     h1='Kaç çalışanda İSG çalışan temsilcisi zorunlu?';
     meta='2 ve üzeri çalışanı olan işyerleri İSG çalışan temsilcisi belirlemek zorunda; sayı arttıkça temsilci sayısı artar.';
     hesap=@{tip='sayi';etiket='Çalışan sayın';esik=2;birim='kişi';evet='2 ve üzeri çalışanda İSG çalışan temsilcisi belirlemek zorunlu.'};
     body=@('İş sağlığı ve güvenliği konularında çalışanları temsil etmek üzere, <b>2 ve üzeri</b> çalışanı olan işyerlerinde çalışan temsilcisi görevlendirilir.',
            'Temsilci sayısı çalışan sayısıyla kademeli artar (ör. 2-50 arası 1, 51-100 arası 2 …). Temsilci öncelikle seçimle, mümkün olmazsa atamayla belirlenir.');
     dayanak='6331 sayılı İSG Kanunu m.20'; ilgili=@('isg-uzmani-isyeri-hekimi','isg-kurulu') },

  @{ slug='toplu-isten-cikarma'; ust='Çalışan sayısı'; kisa='Toplu işten çıkarma';
     title='Toplu İşten Çıkarma Bildirimi: Kaç Çalışanda? | Mevzuat Radarı';
     h1='Toplu işten çıkarma bildirimi kimler için zorunlu?';
     meta='20 ve üzeri çalışanı olan işyerlerinde toplu işten çıkarma yapılacaksa İŞKUR''a önceden bildirim zorunlu.';
     hesap=@{tip='sayi';etiket='Çalışan sayın';esik=20;birim='kişi';evet='20 ve üzeri çalışanı olan işyerinde toplu işten çıkarma yaparsan önceden bildirim zorunlu.'};
     body=@('20 ve daha fazla işçi çalıştıran işyerlerinde, belirli sayının üzerinde işçinin aynı dönemde çıkarılması "toplu işçi çıkarma" sayılır ve işverenin bunu önceden yazılı bildirmesi gerekir.',
            'Bildirim en az 30 gün önce işyeri sendika temsilcilerine, ilgili bölge müdürlüğüne ve İŞKUR''a yapılır. Bildirim yapılmadan çıkış, geçersizlik ve tazminat riski doğurur.');
     dayanak='4857 sayılı İş Kanunu m.29'; ilgili=@('engelli-calistirma','calisan-temsilcisi') },

  @{ slug='ttk-1524-internet-sitesi'; ust='Denetim & TTK'; kisa='TTK 1524 internet sitesi';
     title='TTK 1524 İnternet Sitesi Zorunluluğu: Kimlere? | Mevzuat Radarı';
     h1='İnternet sitesi açma zorunluluğu (TTK 1524) kimlerde?';
     meta='Bağımsız denetime tabi sermaye şirketleri, TTK 1524 gereği internet sitesi açmak ve belirli bilgileri yayınlamak zorunda.';
     hesap=@{tip='bilgi';metin='<b>Bağımsız denetime tabi bir sermaye şirketiysen kapsamdasın.</b> TTK 1524 gereği internet sitesi açmak ve kanunen ilan edilmesi gereken bilgileri sitede yayınlamak zorundasın.'};
     body=@('Bağımsız denetime tabi olan sermaye şirketleri, kuruluşlarının ardından belirli sürede bir internet sitesi açmak ve bu sitenin belirli bölümünü kanunen yayınlanması gereken hususlara ayırmak zorundadır.',
            'Yükümlülük bağımsız denetim kapsamına girmeye bağlıdır; denetime tabi olup olmadığını Bağımsız Denetim Eşiği sayfasından kontrol edebilirsin.');
     dayanak='6102 sayılı TTK m.1524'; ilgili=@('bagimsiz-denetim-esigi','kep-e-tebligat') },

  @{ slug='transfer-fiyatlandirmasi'; ust='Denetim & TTK'; kisa='Transfer fiyatlandırması';
     title='Transfer Fiyatlandırması Belgelendirme Yükümlülüğü | Mevzuat Radarı';
     h1='Transfer fiyatlandırması belgelendirmesi kimlere?';
     meta='İlişkili kişilerle işlemi olan kurumlar, emsale uygunluk ve belgelendirme yükümlülüğüne tabi olabilir.';
     hesap=@{tip='bilgi';metin='<b>İlişkili kişilerle (ortak, grup şirketi, yönetici vb.) mal veya hizmet alım-satımın varsa kapsamda olabilirsin.</b> İşlem tutarına ve şirket tipine göre yıllık form ve/veya rapor hazırlama yükümlülüğü doğar.'};
     body=@('Kurumlar, ilişkili kişilerle yaptıkları mal veya hizmet alım-satımında emsallere uygun bedeli esas almak zorundadır. Bu işlemler yıllık kurumlar vergisi beyannamesi ekindeki formla bildirilir.',
            'İşlem hacmi ve mükellef tipine göre ayrıca yıllık transfer fiyatlandırması raporu hazırlanması gerekebilir. Kapsam ve tutar eşikleri için mali müşavirine danışman doğru olur.');
     dayanak='5520 sayılı Kurumlar Vergisi Kanunu m.13'; ilgili=@('bagimsiz-denetim-esigi','e-fatura-zorunlulugu') }
)

# ---- ÜRETİM ----------------------------------------------------------------
$lookup = @{}; foreach($p in $pages){ $lookup[$p.slug] = $p.kisa }

function Esc($s){ return ($s -replace '&','&amp;' -replace '<','&lt;' -replace '>','&gt;').Replace('"','&quot;') }

$count = 0
foreach($p in $pages){
  $bodyHtml = ($p.body | ForEach-Object { "<p>$_</p>" }) -join "`n"
  $ilgiliHtml = ($p.ilgili | ForEach-Object { '<a href="' + $_ + '.html">' + $lookup[$_] + '</a>' }) -join ' '
  $hesapJson = ($p.hesap | ConvertTo-Json -Depth 8 -Compress)
  # FAQ (JSON-LD): ilk paragrafın düz metni
  $ans = ($p.body[0] -replace '<[^>]+>','')
  $faq = '{"@context":"https://schema.org","@type":"FAQPage","mainEntity":[{"@type":"Question","name":"' + (Esc $p.h1) + '","acceptedAnswer":{"@type":"Answer","text":"' + (Esc $ans) + '"}}]}'

  $html = $TPL
  $html = $html.Replace('@@CSS@@',$CSS)
  $html = $html.Replace('@@TITLE@@',(Esc $p.title))
  $html = $html.Replace('@@META@@',(Esc $p.meta))
  $html = $html.Replace('@@UST@@',(Esc $p.ust))
  $html = $html.Replace('@@H1@@',(Esc $p.h1))
  $html = $html.Replace('@@FAQ@@',$faq)
  $html = $html.Replace('@@BODY@@',$bodyHtml)
  $html = $html.Replace('@@ILGILI@@',$ilgiliHtml)
  $html = $html.Replace('@@DAYANAK@@',(Esc $p.dayanak))
  $html = $html.Replace('@@HESAP@@',$hesapJson)

  $path = Join-Path $here ($p.slug + '.html')
  [System.IO.File]::WriteAllText($path,$html,$enc)
  $count++
}

# ---- HUB (sayfalar/index.html) --------------------------------------------
$gruplar = $pages | Group-Object { $_.ust }  # hashtable anahtarı için script block şart
$hubBody = ""
foreach($g in $gruplar){
  $hubBody += "<h2>$($g.Name)</h2><ul>"
  foreach($p in $g.Group){ $hubBody += '<li><a href="' + $p.slug + '.html">' + (Esc $p.h1) + '</a></li>' }
  $hubBody += "</ul>"
}
$hub = @"
<!doctype html><html lang="tr"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Mevzuat Eşik Rehberi — Yükümlülük Hesaplayıcıları | Mevzuat Radarı</title>
<meta name="description" content="Firmaların yasal yükümlülük eşikleri: e-Fatura, bağımsız denetim, İSG, engelli kotası, VERBİS ve daha fazlası. Ücretsiz hesaplayıcılar.">
<style>$CSS ul{line-height:2;padding-left:20px;color:var(--muted)} ul a{color:var(--ink);text-decoration:none} ul a:hover{color:var(--accent2)} h2{font-size:15px;margin:26px 0 8px;border-bottom:1px solid var(--line);padding-bottom:6px;color:var(--accent2);text-transform:uppercase;letter-spacing:1.2px;font-weight:800}</style></head>
<body><div class="wrap">
<div class="top"><span class="logo">MR</span><a href="../index.html">Mevzuat Radarı</a> · Eşik rehberi</div>
<h1>Mevzuat eşik rehberi</h1>
<div class="govde"><p>Firmanın hangi yasal yükümlülüğe hangi eşikte girdiğini saniyede öğren. Aşağıdan konu seç, sayını gir, cevabı gör. Hepsini tek seferde görmek için ücretsiz <a href="../index.html">Yükümlülük Karnesi</a>.</p></div>
$hubBody
<div class="cta"><h2>Tüm yükümlülüklerini tek seferde gör</h2><p>3 dakikada ücretsiz Yükümlülük Karnesi.</p><a class="btn" href="../index.html">Karnemi çıkar →</a></div>
<div class="dip">Hazırlayan SMMM Cem Dizdar — Mevzuat Radarı. Bilgilendirme amaçlıdır.</div>
</div><script data-goatcounter="https://mevzuatradar.goatcounter.com/count" async src="//gc.zgo.at/count.js"></script>
</body></html>
"@
[System.IO.File]::WriteAllText((Join-Path $here 'index.html'),$hub,$enc)

Write-Host "$count sayfa + hub uretildi -> $here"
Get-ChildItem $here -Filter *.html | Select-Object -ExpandProperty Name
