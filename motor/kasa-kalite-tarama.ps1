# ============================================================================
#  KASA KALITE TARAMASI — 1 Agustos onarimlarinin kesif robotu. (30.07.2026)
#
#  NEDEN: Cem 30.07'de canli sinavda iki kusur gordu:
#   (a) tek cumlelik "AKILDA KALSIN" (kisa hap) - eski 3.355'lik orneklemde
#       sifirdi, yeni kurtarilan partilerde var; kasada KAC tane bilinmiyor.
#   (b) gerekce icinde robot sablon basliklari ("Ne soruluyor:", "Bu olayda:",
#       "Akilda kalsin:") - yapayzeka kokusu, kac soruda oldugu bilinmiyor.
#  Onarim API ister (1 Agustos); TARAMA BEDAVA - yalniz Supabase okumasi.
#  Bu robot sayar ve id listesini cikarir ki onarim partisi hedefli ve
#  olculu gitsin ("kac soru, kac dolar" sorusu tahminle cevaplanmaz).
#
#  Cikti: veri/kalite-tarama.json — YALNIZ sayilar + soru ID'leri (UUID).
#  Soru METNI ASLA yazilmaz (depo public; parali icerik sizmaz).
#  ENV: SUPABASE_SERVICE_KEY (zorunlu).
# ============================================================================
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$SB_URL = "https://bjrleanjpyujtajmazxn.supabase.co"
$cikti = Join-Path $kok "veri/kalite-tarama.json"

function Yaz($n){ [IO.File]::WriteAllText($cikti, (ConvertTo-Json -InputObject $n -Depth 5), (New-Object Text.UTF8Encoding($false))) }
trap {
  Yaz ([ordered]@{ tarih=(Get-Date -Format "dd.MM.yyyy HH:mm"); durum="HATA"
    hata="$($_.Exception.Message)"; satir=$_.InvocationInfo.ScriptLineNumber })
  Write-Host ("HATA (satir {0}): {1}" -f $_.InvocationInfo.ScriptLineNumber, $_.Exception.Message)
  exit 1
}

$KEY = "$env:SUPABASE_SERVICE_KEY"
if([string]::IsNullOrWhiteSpace($KEY)){
  Yaz ([ordered]@{ tarih=(Get-Date -Format "dd.MM.yyyy HH:mm"); durum="ATLANDI"; not="SUPABASE_SERVICE_KEY yok" })
  Write-Host "SUPABASE_SERVICE_KEY yok - atlandi."; exit 0
}
$H = @{ apikey = $KEY; Authorization = "Bearer $KEY" }

# --- sablon basliklari: robotun kendi kendine konustugu kaliplar.
#     ASCII/fold ile aranir (gerekceler cogunlukla duzgun Turkce ama kalip
#     karisik gelebilir) - kucult + fold sonra ara.
$SABLONLAR = @('ne soruluyor', 'bu olayda', 'akilda kalsin:', 'kural:', 'bu soruda:')
function Fold([string]$s){ if($null -eq $s){ return '' }
  $s = $s.ToLowerInvariant()
  return ($s -replace 'ı','i' -replace 'ş','s' -replace 'ğ','g' -replace 'ü','u' -replace 'ö','o' -replace 'ç','c') }

# --- kasayi sayfa sayfa cek (id + hap + aciklama + etiketler; soru metni YOK
#     cunku gerekmez - trafik ve bellek kucuk kalir)
$KISA_ESIK = 90
$hepsi = 0
$kisaHap    = New-Object System.Collections.Generic.List[string]
$hapYok     = New-Object System.Collections.Generic.List[string]
$sablonlu   = New-Object System.Collections.Generic.List[string]
$sablonDagilim = @{}
$yayinKisa = 0; $yayinSablon = 0
$offset = 0; $sayfa = 1000
while($true){
  $u = "$SB_URL/rest/v1/soru_havuzu?select=id,hap,aciklama,yayin&order=id&limit=$sayfa&offset=$offset"
  # 30.07 IKI PS TUZAGI UST USTE:
  # (1) @(Invoke-RestMethod) diziyi tek nesne sarar (ilk kosu 1 "soru" taradi).
  # (2) IRM, aciklama gibi karisik JSON alanlarinda kendi cozumunde patliyor
  #     ("String -> IDictionary" hatasi). kasa-sayim'in aciklama ceken dongusu
  #     bosuna Invoke-WebRequest + ConvertFrom-Json kullanmiyor - ayni desen.
  $hw = Invoke-WebRequest -UseBasicParsing -Uri $u -Headers $H -TimeoutSec 120
  $gv = if($hw.Content -is [byte[]]){ [Text.Encoding]::UTF8.GetString($hw.Content) } else { "$($hw.Content)" }
  $parti = @(); foreach($x in (ConvertFrom-Json $gv)){ $parti += $x }
  if(-not $parti.Count){ break }
  foreach($s in $parti){
    $hepsi++
    # DIKKAT: degisken adi $h OLAMAZ - PowerShell buyuk/kucuk duyarsizdir,
    # $h = hap metni atamasi baslik sozlugu $H'yi EZIYORDU; ikinci sayfa
    # istegi "Headers = hap cumlesi" ile baglanip patliyordu (iki kosu).
    $hapM = "$($s.hap)"
    if($hapM.Trim().Length -lt 5){ $hapYok.Add("$($s.id)") }
    elseif($hapM.Length -lt $KISA_ESIK){ $kisaHap.Add("$($s.id)"); if($s.yayin){ $yayinKisa++ } }
    # aciklama JSON nesnesi ({A:...,B:...}) - tum degerleri tek metinde tara
    $acik = ''
    if($s.aciklama){ foreach($p in $s.aciklama.PSObject.Properties){ $acik += ' ' + "$($p.Value)" } }
    $af = Fold $acik
    $vurdu = $false
    foreach($k in $SABLONLAR){
      if($af.Contains($k)){
        if(-not $vurdu){ $sablonlu.Add("$($s.id)"); if($s.yayin){ $yayinSablon++ }; $vurdu = $true }
        if($sablonDagilim.ContainsKey($k)){ $sablonDagilim[$k]++ } else { $sablonDagilim[$k] = 1 }
      }
    }
  }
  $offset += $sayfa
  if($parti.Count -lt $sayfa){ break }
}

Yaz ([ordered]@{
  tarih = (Get-Date -Format "dd.MM.yyyy HH:mm"); durum = "TAMAM"
  taranan = $hepsi
  kisa_hap = [ordered]@{ esik = $KISA_ESIK; adet = $kisaHap.Count; yayinda = $yayinKisa
    idler = @($kisaHap | Select-Object -First 400) }
  hap_yok = [ordered]@{ adet = $hapYok.Count; idler = @($hapYok | Select-Object -First 200) }
  sablon_gerekce = [ordered]@{ adet = $sablonlu.Count; yayinda = $yayinSablon
    kalip_dagilimi = $sablonDagilim
    idler = @($sablonlu | Select-Object -First 400) }
  not = "Onarim partisi 1 Agustos'ta bu id listeleriyle HEDEFLI gider; maliyet tahmini adetten hesaplanir. Soru metni bu dosyada YOKTUR."
})
Write-Host ("TAMAM: {0} soru tarandi | kisa hap: {1} (yayinda {2}) | hap yok: {3} | sablonlu gerekce: {4} (yayinda {5})" -f `
  $hepsi, $kisaHap.Count, $yayinKisa, $hapYok.Count, $sablonlu.Count, $yayinSablon)
