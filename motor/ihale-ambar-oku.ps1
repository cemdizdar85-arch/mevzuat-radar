# ============================================================================
#  IHALE AMBARINI OKU  (20.08.2026)
#
#  Ambar artik depoda DEGIL, Supabase'de (veri/ihale-sonuc.json cikti - 28,2 MB
#  acik dosyaydi). Ozet ureten uc betik (tur/firma/idare) kaynagi buradan alir.
#  Tek yerden okunmasinin sebebi: alan adlari iki tarafta farkli (tabloda
#  snake_case, betiklerde camelCase). Esleme TEK yerde dursun ki uc betikten
#  biri unutulup sessizce bos kayit uretmesin.
#
#  DONEN SEKIL eski JSON kaydinin AYNISI - ozet betiklerinin hesap kismina hic
#  dokunulmadi (o kod olculmus ve dogrulanmis durumda).
#
#  KIRIM burada HESAPLANMAZ. Tablodaki ihale_sonuc_v gorunumu kisimliligi TUM
#  HAVUZ uzerinden olcup kirimi turetiyor; gun-ici hesap 1.133 kaydi yanlis
#  olcmustu. Buradaki is yalnizca tasimak.
#
#  Anahtar yoksa: eski JSON dosyasina duser (gecis donemi + yerel calisma).
#  Ikisi de yoksa BOS DONMEZ, ekrana sebep yazar (kor kalma kurali).
# ============================================================================

function Ihale-AmbarOku {
  param(
    [string]$Kok,
    # 1.000: PostgREST'in sunucu tarafi tavani. Daha buyuk istemek ise yaramaz,
    # yalniz "eksik geldi" yanilgisi uretir.
    [int]$Sayfa = 1000
  )
  $SB_URL  = 'https://bjrleanjpyujtajmazxn.supabase.co'
  $anahtar = "$($env:SUPABASE_SERVICE_KEY)".Trim()

  if (-not $anahtar) {
    $dosya = Join-Path $Kok 'veri\ihale-sonuc.json'
    if (Test-Path $dosya) {
      Write-Host "AMBAR: SUPABASE_SERVICE_KEY yok -> eski JSON dosyasindan okunuyor ($dosya)"
      return @((Get-Content $dosya -Raw -Encoding UTF8 | ConvertFrom-Json).sonuclar)
    }
    Write-Host 'AMBAR OKUNAMADI: ne SUPABASE_SERVICE_KEY var ne de veri\ihale-sonuc.json.'
    Write-Host '                 Yerelde: anahtar-kur.cmd | Actions: Secrets -> SUPABASE_SERVICE_KEY'
    return @()
  }

  $basliklar = @{
    'apikey'        = $anahtar
    'Authorization' = "Bearer $anahtar"
    'Content-Type'  = 'application/json'
    'Accept'        = 'application/json'
    'User-Agent'    = 'MevzuatRadar-AmbarOkuyucu'
  }

  # 🔴 31.08 - GORUNUM OLCEGE DAYANAMADI, TURETIM YERELE ALINDI:
  # Bu islev ihale_dokum ucundan okuyordu; o da ihale_sonuc_v gorunumunu
  # kullaniyor. Gorunum kisim sayisini "count(*) over (partition by ikn)"
  # ile hesapliyor - pencere fonksiyonu, limit/offset verilse bile TUM
  # tabloyu tarar. Havuz 24.043'ten 486.000'e cikinca her sayfa istegi
  # zaman asimina dustu: OLCULDU, offset 0 ve offset 200.000 icin ikisi de
  # HTTP 500, ~9 saniyede. Yani ozet uretimi TAMAMEN durmustu.
  #
  # COZUM: duz tablo okunur (index'li, ucuz), kisimlilik ve kirim BURADA
  # turetilir. Mantik gorunumdekiyle BIREBIR ayni - degistirilen yer degil,
  # calistirildigi yer. Kisim sayimi yine TUM HAVUZ uzerinden yapilir
  # (once tum satirlar okunur, sonra IKN'e gore sayilir), yani 20.08'de
  # kapatilan "gun ici sayim" tuzagi geri gelmez.
  # ANAHTAR TABANLI SAYFALAMA (offset DEGIL) - 31.08 olculdu:
  #   offset      0 -> 1.000 satir,  5,7 sn
  #   offset 200.000 -> ZAMAN ASIMI
  #   offset 450.000 -> ZAMAN ASIMI
  # OFFSET, atlanacak satirlari de yurumek zorunda; derinlestikce pahalilasir
  # ve 486.000 satirda tavana carpar. "anahtar > son okunan" ise birincil
  # anahtar indeksinden gider, sayfa maliyeti derinlikten BAGIMSIZDIR.
  # Bitis olcutu yine BOS SAYFA (20.08 dersi).
  $ham = New-Object Collections.ArrayList
  $son = ''
  while ($true) {
    $sart = if ($son) { "&anahtar=gt.$([uri]::EscapeDataString($son))" } else { '' }
    $uri = "$SB_URL/rest/v1/ihale_sonuc?select=*&order=anahtar.asc&limit=$Sayfa$sart"
    $c = Invoke-WebRequest -UseBasicParsing -Method Get -Uri $uri -Headers $basliklar -TimeoutSec 300
    # ConvertFrom-Json boru hattinda diziyi ACMAZ (PS 5.1): once degiskene al.
    $parca = @()
    if ("$($c.Content)".Trim()) {
      $coz = ConvertFrom-Json -InputObject $c.Content
      if ($null -ne $coz) { $parca = @($coz) }
    }
    if (-not $parca.Count) { break }
    foreach ($r in $parca) { [void]$ham.Add($r) }
    $son = "$($parca[$parca.Count-1].anahtar)"
    if (-not $son) { break }   # anahtarsiz satir olursa sonsuz donguye girmesin
    if ($ham.Count % 50000 -lt $Sayfa) { Write-Host ("   ... {0:N0} satir" -f $ham.Count) }
  }

  # --- kisim sayimi: TUM HAVUZ uzerinden -------------------------------------
  # PowerShell sozlugu BUYUK-KUCUK HARF AYIRMAZ, Postgres ayirir (20.08 tuzagi).
  # IKN'de harf yok ama kural kural: sayimda da Ordinal sozluk kullaniliyor.
  $kisimSay = New-Object 'System.Collections.Generic.Dictionary[string,int]' ([StringComparer]::Ordinal)
  foreach ($r in $ham) {
    $i = "$($r.ikn)"
    if ($i) { if ($kisimSay.ContainsKey($i)) { $kisimSay[$i] += 1 } else { $kisimSay[$i] = 1 } }
  }

  $hepsi = New-Object Collections.ArrayList
  foreach ($r in $ham) {
    $i  = "$($r.ikn)"
    $ks = $(if ($kisimSay.ContainsKey($i)) { $kisimSay[$i] } else { 1 })
    $kisimli = ($ks -gt 1 -or [bool]$r.kisim_kaniti)
    # KIRIM: gorunumdeki case ifadesinin birebir karsiligi.
    $kirim = $null
    if (-not $kisimli) {
      $ym = $r.yaklasik_maliyet; $sb = $r.sozlesme_bedeli
      $birimTutuyor = -not ($r.ym_birim -and $r.sb_birim -and "$($r.ym_birim)" -ne "$($r.sb_birim)")
      if ($null -ne $ym -and $null -ne $sb -and [double]$ym -gt 0 -and $birimTutuyor) {
        $kk = [math]::Round((1 - [double]$sb / [double]$ym) * 100, 1)
        # AKIL SINIRI: kirim (-100,+100) disina cikamaz; disi ayristirma hatasi.
        if ($kk -gt -100 -and $kk -lt 100) { $kirim = $kk }
      }
    }
    [void]$hepsi.Add([pscustomobject]@{
      ikn             = $r.ikn
      tur             = $r.tur
      isAdi           = $r.is_adi
      idare           = $r.idare
      ihaleTarih      = $r.ihale_tarih
      ihaleTuru       = $r.ihale_turu
      usul            = $r.usul
      yaklasikMaliyet = $r.yaklasik_maliyet
      ymBirim         = $r.ym_birim
      sbBirim         = $r.sb_birim
      dokumanIndiren  = $r.dokuman_indiren
      teklifSayisi    = $r.teklif_sayisi
      gecerliTeklif   = $r.gecerli_teklif
      yerliAvantaj    = $r.yerli_avantaj
      sozlesmeTarih   = $r.sozlesme_tarih
      sozlesmeBedeli  = $r.sozlesme_bedeli
      yuklenici       = $r.yuklenici
      kisimKaniti     = $r.kisim_kaniti
      kisimSayisi     = $ks
      kisimliMi       = $kisimli
      kirimYuzde      = $kirim
      bultenTarih     = $r.bulten_tarih
      bultenSayi      = $r.bulten_sayi
    })
  }
  Write-Host ("AMBAR: kasadan {0:N0} sonuc ilani okundu · {1:N0} tekil IKN · kirim olculen {2:N0}" -f `
              $hepsi.Count, $kisimSay.Count, @($hepsi | Where-Object { $null -ne $_.kirimYuzde }).Count)
  return @($hepsi)
}
