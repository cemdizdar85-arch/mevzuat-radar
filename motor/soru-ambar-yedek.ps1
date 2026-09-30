#requires -Version 5.1
<#
================================================================================
  SORU AMBARI YEDEGI — dokum betigi  (12.09.2026, Cem "1 sen yap")

  NIYE VAR: 11.09 gecesi uretimin uc yerel durumu ambara tasindi (kalip_parti,
  bedel_kaydi, konu_koprusu). O ana kadar her sey IKI yerdeydi - Cem'in
  dizustunde VE ambarda; yani yedek kendiliginden vardi. Bulut uretimine
  gecince o ikilik BITIYOR: uretim yalniz ambara yazacak, tek kopya kalacak.
  Alacak kasasinin sifreli bulut yedegi 07.09'da kurulmustu; SORU AMBARININ
  boyle bir yedegi YOKTU. Bu betik o acigi kapatir.

  NE YEDEKLENIR (olculdu 12.09 07:30):
    dokumanlar    45.741  <- TAC MUCEVHER. Yutulmus mevzuat. Kaynaklarin bir
                             kismi artik KAPALI (TMview ag duzeyinde kapali,
                             mevzuat.gov.tr yalniz TR-IP); yeniden yutmak
                             haftalar surer, bir kismi hic geri gelmez.
    soru_havuzu   30.569  <- yayin havuzu, insan onayi tasiyan satirlar var
    konu_koprusu  21.292  <- cikmis sinav arsivinden turetilmis siklik
    bedel_kaydi      423  <- harcama defteri
    kalip_parti      298  <- uretim onbellegi (soru metni + hakem kararlari)
  30.09 EKLENDI (yedek olcumu: bizim yedegimizde YOKTU): ihale_sonuc 523.264 ·
    paket_soru 8.806 · ihale_kutuk · uygulama_olay · elci_indirim · sinav_donemleri.
  KISI VERISI kumesi (-Kume Kisi): uye/cevap/elci tablolari - YALNIZ yerel gorev.

  ⛔ SIFRELEME BURADA YAPILMAZ. Bu betik duz NDJSON yazar; sifreleme akista
     (.github/workflows/soru-ambar-yedek.yml) openssl ile yapilir - alacak
     kasasiyla AYNI desen, AYNI acik anahtar (motor/anahtar/alacak-yedek.pub).
     Depo PUBLIC oldugu icin artifact'i herkes indirebilir; sifresiz birakilan
     yedek, yedek degil SIZINTIDIR (08.09'da 7 sifresiz artifact silinmisti).

  ⛔ SAYFALAMA OFFSET ILE YAPILMAZ. Olculdu (08.09): offset 15.000'de HTTP 500,
     25.000'de 57014 timeout. Imlec (keyset) kullanilir: order=<pk>.asc +
     <pk>=gt.<son>. 45.741 satirlik dokumanlar ancak boyle iner.

  ⛔ BELLEGE TOPLANMAZ. dokumanlar ~200 MB; satirlar diske AKITILIR.

  KULLANIM
    $env:YEDEK_KOK='C:\gecici\_yedek'; powershell -NoProfile -File motor/soru-ambar-yedek.ps1
  BEDEL 0 - yalniz ambar okuma.
================================================================================
#>
param(
  [string]$Kok = '',                 # cikti klasoru (bos = $env:YEDEK_KOK ya da _yedek)
  [string[]]$Tablolar = @(),         # bos = secilen kumenin tamami
  [ValidateSet('Bulut','Kisi','Marka')][string]$Kume = 'Bulut',
  [int]$SaklaGun = 0,                # >0: $Kok'ta bu kadar gunden eski soru-ambar-* dosyalari silinir (yalniz yerel gorev)
  [switch]$Gzip,                     # dogrudan .ndjson.gz yazar (marka_bulten ~7 GB duz; runner diskine sigmaz)
  [int]$DenemeSayfa = 0              # >0: tablo basina en fazla bu kadar sayfa (yalniz yerel deneme; kunye EKSIK der)
)
$ErrorActionPreference='Stop'
$buDizin=$(if($PSScriptRoot){ $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path })
$depoKok=Split-Path -Parent $buDizin

if(-not $Kok){ $Kok="$($env:YEDEK_KOK)".Trim() }
if(-not $Kok){ $Kok=Join-Path $depoKok '_yedek' }
New-Item -ItemType Directory -Force $Kok | Out-Null

$AMBAR_ANAHTAR="$($env:SUPABASE_SERVICE_KEY)".Trim()
if(-not $AMBAR_ANAHTAR){ $AMBAR_ANAHTAR="$([Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User'))".Trim() }
if(-not $AMBAR_ANAHTAR){ throw 'SUPABASE_SERVICE_KEY yok - yedek alinamaz.' }
# ⛔ Ad UZUN. Kisa $ANAHTAR yazilsaydi asagidaki bir $anahtar onu ezerdi
#    (PS harf AYIRMAZ). Bu tuzaga 11.09'da ALTI kez dusuldu; bkz CLAUDE.md.
$AMBAR_BASLIK=@{ apikey=$AMBAR_ANAHTAR; Authorization="Bearer $AMBAR_ANAHTAR"
                 Accept='application/json'; 'User-Agent'='mevzuat-radar-robot/1.0' }
$AMBAR_TABAN='https://bjrleanjpyujtajmazxn.supabase.co/rest/v1'
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12

# tablo -> imlec alani + SAYFA BOYU.
# ⛔ SAYFA BOYU TABLOYA GORE. Ilk surumde hepsi 1000'di ve bulut kosusu #1
#    KIRMIZI dustu. Yerelde birebir tekrarlandi:
#      "kalip_parti sayfa 0 okunamadi: (500) Ic Sunucu Hatasi"
#    Sebep: kalip_parti 298 satir ama 106 MB - satir basina ~350 KB jsonb.
#    1000 satirlik sayfa = TEK YANITTA 106 MB; PostgREST tasiyamiyor.
#    Satir SAYISI degil satir AGIRLIGI onemli. dokumanlar 45.741 satir ama
#    1000'lik sayfalarla sorunsuz indi (satir ~6 KB).
$VARSAYILAN=[ordered]@{
  'dokumanlar'   = @{ pk='id';     sayfa=1000 }   # ~6 KB/satir
  'soru_havuzu'  = @{ pk='id';     sayfa=1000 }   # ~3,5 KB/satir (olculdu: 108 MB/30.569)
  'konu_koprusu' = @{ pk='id';     sayfa=1000 }
  'bedel_kaydi'  = @{ pk='id';     sayfa=1000 }
  'kalip_parti'  = @{ pk='etiket'; sayfa=5    }   # ~350 KB/satir -> sayfa ~1,75 MB
  # 30.09.2026 (Cem "1 yap"): yedek olcumunde bu tablolar HICBIR bizim yedegimizde yoktu;
  # tek kopya Supabase'in 7 gunluk fiziksel yedegiydi. Kisi verisi TASIMAYANLAR buraya.
  'ihale_sonuc'     = @{ pk='anahtar'; sayfa=1000 }   # 523.264 satir, ~0,8 KB/satir; EKAP toplu cekim YOK -> geri gelmez
  'paket_soru'      = @{ pk='id';      sayfa=200  }   # ~18 KB/satir -> sayfa ~3,6 MB
  'ihale_kutuk'     = @{ sira='gun.asc,tur.asc';                  sayfa=1000 }   # bilesik anahtar (gun,tur)
  'uygulama_olay'   = @{ sira='gun.asc,olay.asc,platform.asc';    sayfa=1000 }   # bilesik anahtar
  'elci_indirim'    = @{ pk='paket';   sayfa=1000 }
  'sinav_donemleri' = @{ pk='ad';      sayfa=1000 }
  'konu_karti'         = @{ pk='id';        sayfa=200  }
  'konu_semasi'        = @{ pk='id';        sayfa=200  }
  'marka_ayna'         = @{ pk='st13';      sayfa=1000 }
  'marka_ayna_dilim'   = @{ pk='dilim';     sayfa=1000 }
  'marka_bulten_kutuk' = @{ pk='bulten_no'; sayfa=1000 }
  # ⚠ marka_bulten (1.727.332 satir, ~4 KB/satir = ~7 GB duz, 30.09 olculdu) BURADA YOK:
  #   gunluk yedege sigmaz; ayri karar (haftalik/aylik ayri akis) Cem'de.
}
# ⛔ KISI VERISI BULUTA/ACTIONS'A GIRMEZ (CLAUDE.md "BULUT GUVENLIGI" madde 4).
#    Bu kume yalniz Cem'in makinesindeki gunluk gorevle (TETIKTE-KisiVerisiYedek)
#    C:\TETIKTE-YEDEK altina (OneDrive DISI) yazilir; betik Actions'ta bu kumeyi REDDEDER.
#    Olculdu 30.09: e-posta, ad-soyad, odeme_bilgisi, user_id, oturum tasiyorlar.
$KISI=[ordered]@{
  'cevap_kayit'                = @{ pk='id';      sayfa=1000 }
  'cevap_kayit_yedek_20260926' = @{ pk='id';      sayfa=1000 }
  'kagit_kayit'                = @{ pk='id';      sayfa=1000 }
  'firma_uyarilari'            = @{ pk='id';      sayfa=1000 }
  'uye_cihaz_olay'             = @{ pk='id';      sayfa=1000 }
  'uye_cihazlar'               = @{ sira='user_id.asc,cihaz_id.asc'; sayfa=1000 }
  'paket_uyeler'               = @{ pk='user_id'; sayfa=1000 }
  'ogrenci_ilerleme'           = @{ pk='user_id'; sayfa=200  }
  'kurulus_nobet'              = @{ pk='id';      sayfa=1000 }
  'uye_ekran'                  = @{ pk='user_id'; sayfa=1000 }
  'elciler'                    = @{ pk='kod';     sayfa=1000 }
  # 30.09 ikinci tarama (depodaki TUM .sql): uye/odeme/marka musteri tablolari.
  # Bos olanlar da listede - site acilinca dolacaklar (siparis, abonelik, odeme).
  'cevap_kaydi'          = @{ pk='id'; sayfa=1000 }
  'soru_bildirim'        = @{ pk='id'; sayfa=1000 }
  'form_kayit'           = @{ pk='id'; sayfa=1000 }
  'istekler'             = @{ pk='id'; sayfa=1000 }
  'sorular'              = @{ pk='id'; sayfa=1000 }
  'kullanim_delilleri'   = @{ pk='id'; sayfa=1000 }
  'markalar'             = @{ pk='id'; sayfa=1000 }
  'marka_rakip'          = @{ pk='id'; sayfa=1000 }
  'marka_takip'          = @{ pk='id'; sayfa=1000 }
  'marka_talep'          = @{ pk='id'; sayfa=1000 }
  'marka_uyari'          = @{ pk='id'; sayfa=1000 }
  'marka_uyarilari'      = @{ pk='id'; sayfa=1000 }
  'marka_durum'          = @{ sira='user_id.asc,marka.asc';          sayfa=1000 }
  'marka_portfoy'        = @{ sira='user_id.asc,unvan.asc';          sayfa=200  }
  'marka_takip_gonderim' = @{ sira='takip_id.asc,basvuru_no.asc';    sayfa=1000 }
  'siparisler'           = @{ pk='id';      sayfa=1000 }
  'magaza_siparis'       = @{ pk='id';      sayfa=1000 }
  'abonelikler'          = @{ pk='user_id'; sayfa=1000 }
  'elci_odemeler'        = @{ pk='id';      sayfa=1000 }
  'davet_kullanim'       = @{ pk='id';      sayfa=1000 }
  'canli_sonuc'          = @{ pk='id';      sayfa=1000 }
  'ogrenci_sonuc'        = @{ pk='id';      sayfa=1000 }
  'destek_takip'         = @{ pk='id';      sayfa=1000 }
  'destek_uyari'         = @{ pk='id';      sayfa=1000 }
}
# 30.09 (Cem "1.2.3"): marka_bulten AYLIK ayri akista (.github/workflows/marka-bulten-yedek.yml).
#   1.727.332 satir, 1000 satir = 4.158 KB olculdu. Bilesik anahtar (basvuru_no, bulten_no) ->
#   IKI ALANLI IMLEC: or=(a.gt.X,and(a.eq.X,b.gt.Y)). Offset bu boyda 500/57014 verir (08.09).
#   Kisi verisi DEGIL: TURKPATENT bulteninde yayimlanmis kamuya acik kayit.
$MARKA=[ordered]@{
  'marka_bulten' = @{ imlec2=@('basvuru_no','bulten_no'); sayfa=1000 }
}
if($Kume -eq 'Marka'){ $VARSAYILAN=$MARKA }
if($Kume -eq 'Kisi'){
  if("$env:GITHUB_ACTIONS" -eq 'true'){ throw 'KISI VERISI Actions''ta yedeklenmez (CLAUDE.md bulut guvenligi m.4).' }
  $VARSAYILAN=$KISI
}
# "powershell -File ... -Tablolar a,b" diziyi TEK metin "a,b" olarak verir (30.09 olculdu) -> virgulden bol.
$Tablolar=@($Tablolar | ForEach-Object { "$_" -split ',' } | ForEach-Object { $_.Trim() } | Where-Object { $_ })
if($Tablolar.Count){
  $secili=[ordered]@{}
  foreach($t in $Tablolar){ if($VARSAYILAN.Contains($t)){ $secili[$t]=$VARSAYILAN[$t] } else { throw "bilinmeyen tablo ($Kume kumesinde yok): $t" } }
  $VARSAYILAN=$secili
}

function SatirSayisi([string]$tablo){
  $b=$AMBAR_BASLIK.Clone(); $b['Prefer']='count=exact'
  try{
    $y=Invoke-WebRequest -Uri ($AMBAR_TABAN+'/'+$tablo+'?select=*&limit=1') -Headers $b -TimeoutSec 120 -UseBasicParsing
    return [int](("$($y.Headers['Content-Range'])") -split '/')[-1]
  }catch{ return -1 }
}

$damga=(Get-Date -Format 'yyyyMMdd-HHmm')
$kunye=[ordered]@{ olcum=(Get-Date -Format 'yyyy-MM-dd HH:mm'); damga=$damga; tablolar=@() }
$toplamSatir=0; $toplamBayt=0

foreach($tablo in $VARSAYILAN.Keys){
  $ayar=$VARSAYILAN[$tablo]
  $imlecAlan=$ayar.pk
  $sayfaBoyu=[int]$ayar.sayfa
  # Bilesik anahtarli kucuk tablolar (tek alanli imlec YOK): sabit sirayla OFFSET.
  # Offset 15.000'de 500 veriyordu (08.09) -> bu yol yalniz kucuk tablo icin; buyurse DUSER.
  $ofsetSira="$($ayar.sira)"
  $iki=@($ayar.imlec2 | Where-Object { $_ })
  $beklenen=SatirSayisi $tablo
  $hedef=Join-Path $Kok ("soru-ambar-$damga-$tablo.ndjson" + $(if($Gzip){'.gz'}else{''}))
  Write-Host ("{0,-14} bekleniyor {1,7:N0} satir -> {2}" -f $tablo,$beklenen,(Split-Path $hedef -Leaf)) -ForegroundColor Cyan
  if($ofsetSira -and $beklenen -gt 10000){ throw "$tablo offset yoluyla alinamayacak kadar buyudu ($beklenen satir) - tek alanli imlec tanimla." }

  # ⚠ StreamWriter: 200 MB'lik tablo bellege TOPLANMAZ, satir satir akitilir.
  if($Gzip){
    $gzDosya=[IO.File]::Create($hedef)
    $gzAkis=New-Object System.IO.Compression.GZipStream($gzDosya,[IO.Compression.CompressionLevel]::Optimal)
    $yazici=New-Object System.IO.StreamWriter($gzAkis,(New-Object Text.UTF8Encoding $false))
  } else {
    $yazici=New-Object System.IO.StreamWriter($hedef,$false,(New-Object Text.UTF8Encoding $false))
  }
  $sayac=0; $imlec=$null; $imlec2=$null; $sayfa=0
  # Sayfa adresi uc yoldan biri: sabit sirali OFFSET (kucuk bilesik) · IKI ALANLI imlec · tek alanli imlec.
  function SayfaAdresi([int]$boy){
    if($ofsetSira){ return $AMBAR_TABAN+'/'+$tablo+'?select=*&order='+$ofsetSira+'&limit='+$boy+'&offset='+$sayac }
    if($iki.Count -eq 2){
      $a=$AMBAR_TABAN+'/'+$tablo+'?select=*&order='+$iki[0]+'.asc,'+$iki[1]+'.asc&limit='+$boy
      if($imlec -ne $null){
        # Deger cift tirnakla: basvuru_no '2024/012345' gibi; tirnak/ters bolu kacirilir.
        $v1='"'+("$imlec" -replace '\\','\\' -replace '"','\"')+'"'; $v2='"'+("$imlec2" -replace '\\','\\' -replace '"','\"')+'"'
        $a+='&or='+[uri]::EscapeDataString("($($iki[0]).gt.$v1,and($($iki[0]).eq.$v1,$($iki[1]).gt.$v2))")
      }
      return $a
    }
    $a=$AMBAR_TABAN+'/'+$tablo+'?select=*&order='+$imlecAlan+'.asc&limit='+$boy
    if($imlec -ne $null){ $a+='&'+$imlecAlan+'=gt.'+[uri]::EscapeDataString("$imlec") }
    return $a
  }
  try{
    $buSayfa=$sayfaBoyu
    while($true){
      $adres=SayfaAdresi $buSayfa
      $cevap=$null
      foreach($deneme in 1..4){
        try{ $cevap=Invoke-RestMethod -Uri $adres -Headers $AMBAR_BASLIK -TimeoutSec 300; break }
        catch{
          if($deneme -eq 4){ throw ("$tablo sayfa $sayfa okunamadi (limit=$buSayfa): " + $_.Exception.Message) }
          # ⛔ UYARLANIR SAYFA: 500/57014 cogu zaman "yanit COK BUYUK" demektir.
          #    Beklemek cozmez - sayfayi KUCULTMEK cozer. Tablolar buyudukce
          #    (satir agirligi artikca) bu kendiliginden devreye girsin diye
          #    sabit degil uyarlanir yapildi.
          if($buSayfa -gt 1){
            $buSayfa=[Math]::Max(1,[int]($buSayfa/4))
            $adres=SayfaAdresi $buSayfa
            Write-Host ("   ! sayfa kuculttu -> limit=$buSayfa") -ForegroundColor Yellow
          }
          Start-Sleep -Seconds (3*$deneme)
        }
      }
      $satirlar=@($cevap)
      if(-not $satirlar.Count){ break }
      foreach($satir in $satirlar){
        $yazici.WriteLine(($satir|ConvertTo-Json -Depth 20 -Compress))
        $sayac++
      }
      if($iki.Count -eq 2){ $imlec=$satirlar[-1].($iki[0]); $imlec2=$satirlar[-1].($iki[1]) }
      elseif(-not $ofsetSira){ $imlec=$satirlar[-1].$imlecAlan }
      $sayfa++
      if($satirlar.Count -lt $buSayfa){ break }
      if($DenemeSayfa -gt 0 -and $sayfa -ge $DenemeSayfa){ break }
      if($sayfa % 10 -eq 0){ Write-Host ("   ... {0:N0}" -f $sayac) -ForegroundColor DarkGray }
    }
  } finally { $yazici.Close(); $yazici.Dispose() }

  $boy=(Get-Item $hedef).Length
  $toplamSatir+=$sayac; $toplamBayt+=$boy
  # ⛔ YAZ -> GERI OKU -> KARSILASTIR. Eksik yedek, yedek degildir.
  $tam = ($beklenen -lt 0) -or ($sayac -ge $beklenen)
  $kunye.tablolar+=[ordered]@{ tablo=$tablo; beklenen=$beklenen; yazilan=$sayac; bayt=$boy; tam=$tam }
  $renk=$(if($tam){'Green'}else{'Red'})
  Write-Host ("{0,-14} YAZILDI {1,7:N0} satir · {2,8:N1} MB · {3}" -f $tablo,$sayac,($boy/1MB),$(if($tam){'TAM'}else{'⛔ EKSIK'})) -ForegroundColor $renk
}

$kunye.toplam_satir=$toplamSatir
$kunye.toplam_bayt=$toplamBayt
$eksikler=@($kunye.tablolar|Where-Object{ -not $_.tam })
$kunye.eksik_tablo=$eksikler.Count
[IO.File]::WriteAllText((Join-Path $Kok "soru-ambar-$damga-kunye.json"),($kunye|ConvertTo-Json -Depth 6),(New-Object Text.UTF8Encoding $false))

Write-Host ("`nTOPLAM: {0:N0} satir · {1:N1} MB · eksik tablo {2}" -f $toplamSatir,($toplamBayt/1MB),$eksikler.Count) -ForegroundColor $(if($eksikler.Count){'Red'}else{'Green'})
# ⛔ Eksik yedekle "yedek aldik" denmez - akis burada DUSER ve artifact yazilmaz.
if($eksikler.Count){ throw ("YEDEK EKSIK: " + (($eksikler|ForEach-Object{ "$($_.tablo) $($_.yazilan)/$($_.beklenen)" }) -join ' · ')) }
Write-Host "kunye: soru-ambar-$damga-kunye.json" -ForegroundColor DarkGray

# Yerel gorev icin eskiyi budama - yalniz TAM yedekten SONRA (eksik yedekte yukarida dusuldu).
if($SaklaGun -gt 0){
  $esik=(Get-Date).AddDays(-$SaklaGun)
  $eskiler=@(Get-ChildItem $Kok -File -Filter 'soru-ambar-*' | Where-Object { $_.LastWriteTime -lt $esik })
  foreach($e in $eskiler){ Remove-Item $e.FullName -Force }
  Write-Host ("budandi: {0} dosya ({1} gunden eski)" -f $eskiler.Count,$SaklaGun) -ForegroundColor DarkGray
}
