# ============================================================================
#  SAYFALI OKU — PostgREST'ten ANAHTARLI (keyset) sayfalama   (08.09.2026)
#
#  NEDEN: 24 betik kasayi/ambari "order=id&offset=N&limit=M" ile sayfaliyordu.
#  offset, her sayfada N satiri sirala-atla demektir; N buyudukce her sayfa
#  yavaslar. 08.09 olculdu: madde-damga.ps1 (order=kaynak_ad) 25.000. kayitta
#  "57014 statement timeout" (kosu 254 + 256). Ambar 44.521, kasa 30.569 kayit
#  ve ikisi de buyuyor - siradaki 23 betik ayni duvara sirayla carpacakti.
#
#  ANAHTARLI sayfalama: id=gt.<son id>&order=id&limit=M. Birincil anahtar
#  indeksinden yurur, her sayfa AYNI hizda (olculdu: 44.521 kayit / 90 sayfa /
#  36 sn, en yavas sayfa 841 ms). Suzgecler (yayin=eq.true, sinav=eq.SGS...)
#  aynen kalir; yalniz "order" ve "offset" bu yardimciya devredilir.
#
#  KULLANIM (dot-source):
#    . (Join-Path $kok 'arac\sayfali-oku.ps1')
#    $satirlar = SayfaliOku -Yol "$SB_URL/rest/v1/soru_havuzu?select=id,ders&yayin=eq.true" -Baslik $H -Sayfa 1000
#    # ya da sayfa sayfa islemek icin:
#    SayfaliOku -Yol ... -Baslik $H -Sayfa 1000 -Islem { param($parti) foreach($x in $parti){ ... } }
#
#  KURALLAR:
#   · select listesinde "id" OLMALI (yoksa eklenir - imlec bunsuz yurumez).
#   · Yol'da order/offset/limit VERILMEZ; verilirse temizlenir (uyari basar).
#   · Govde Invoke-WebRequest + UTF-8 cozumu + ConvertFrom-Json ile okunur:
#     Invoke-RestMethod "aciklama" gibi karisik JSON alanlarinda kendi cozumunde
#     patliyordu (30.07 dersi, kasa-kalite-tarama).
#   · PS 5.1 tuzagi: @(tek nesne) 1 sayar - sonuc her zaman List[object] doner.
#   · Hata: 3 deneme, artan bekleme; ucuncude firlatir (sessiz yarim liste yok).
# ============================================================================
function SayfaliOku {
  param(
    [Parameter(Mandatory=$true)][string]$Yol,
    [Parameter(Mandatory=$true)][hashtable]$Baslik,
    [int]$Sayfa = 1000,
    [int]$ZamanAsimi = 180,
    [scriptblock]$Islem = $null,
    [string]$Anahtar = 'id'
  )
  # order / offset / limit temizle
  $temiz = $Yol -replace '[&?](order|offset|limit)=[^&]*', ''
  if($temiz -ne $Yol){ Write-Host "  (sayfali-oku: Yol'daki order/offset/limit atildi - imlec sayfalamasi kullaniliyor)" }
  $Yol = $temiz
  if($Yol -notmatch '\?'){ $Yol += '?' }
  # select'te anahtar var mi
  if($Yol -match '[?&]select=([^&]*)'){
    $sel = $Matches[1]
    $kolonlar = $sel -split ','
    if($kolonlar -notcontains $Anahtar){
      $Yol = $Yol -replace '([?&]select=)([^&]*)', ('$1' + $Anahtar + ',' + '$2')
    }
  } else {
    $Yol += ('&select=' + $Anahtar + ',*')
  }
  $Yol = $Yol -replace '\?&', '?'
  $ayrac = if($Yol.EndsWith('?')){ '' } else { '&' }

  $hepsi = New-Object System.Collections.Generic.List[object]
  $son = ''
  while($true){
    $suzgec = if($son){ "&$Anahtar=gt.$([uri]::EscapeDataString($son))" } else { '' }
    $u = "$Yol$ayrac$Anahtar=gt.__X__&order=$Anahtar&limit=$Sayfa" -replace "&$Anahtar=gt\.__X__", $suzgec
    $u = $u -replace '\?&', '?'
    $govde = $null
    for($d = 1; $d -le 3; $d++){
      try {
        # UA SART: Supabase kimliksiz UA'li istegi 401 ile reddediyor (16.08 olcumu, madde-coz dersi)
        $w = Invoke-WebRequest -UseBasicParsing -Uri $u -Headers $Baslik -TimeoutSec $ZamanAsimi -UserAgent 'mevzuat-radar-robot/1.0'
        $govde = if($w.RawContentStream){ [Text.Encoding]::UTF8.GetString($w.RawContentStream.ToArray()) } elseif($w.Content -is [byte[]]){ [Text.Encoding]::UTF8.GetString($w.Content) } else { "$($w.Content)" }
        break
      } catch {
        if($d -eq 3){ throw ("sayfali-oku: 3 denemede okunamadi ({0}) - {1}" -f $u, $_.Exception.Message) }
        Start-Sleep -Seconds (2 * $d)
      }
    }
    $parti = New-Object System.Collections.Generic.List[object]
    foreach($x in (ConvertFrom-Json -InputObject $govde)){ $parti.Add($x) }
    if($parti.Count -eq 0){ break }
    if($Islem){ & $Islem $parti } else { foreach($x in $parti){ $hepsi.Add($x) } }
    $son = "$($parti[$parti.Count - 1].$Anahtar)"
    if($parti.Count -lt $Sayfa){ break }
  }
  if($Islem){ return }
  return ,$hepsi
}
