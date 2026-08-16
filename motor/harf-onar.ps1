# ============================================================================
#  TURKCE HARF ONARIMI - Sinif 1 (serpme bozulma)   16.08.2026
#
#  NEDEN: Kasada Turkce harfini yitirmis kelimeler var. Baskin vaka: "sik"
#  ("sik" yerine) - Turkcede kufur, ADAY EKRANINDA GORUNUR. Acilis durdurucu.
#
#  BU DETERMINISTIK BIR DEGISIMDIR - MODEL GEREKMEZ, 0 USD.
#
#  EMNIYET KURALLARI (uculu, hepsi zorunlu):
#   1) Yalniz SOZLUKTEKI kelimeler cevrilir (veri/harf-sozlugu.json).
#      Sozluk elle onaylanir; belirsiz kelime sozluge GIRMEZ ("kismi" vakasi:
#      "kismi" mi "kismi" mi baglamsiz bilinemez -> disarida kalir).
#   2) Kelime SINIRI ile eslesir (icine gomulu parca degistirilmez).
#   3) YAZ -> GERI OKU -> KARSILASTIR. Yazilan her satir tekrar cekilir,
#      beklenen metinle birebir kiyaslanir. Tutmayan varsa rapor KIRMIZI olur.
#      ("yesil kosu != tam veri" - yukleyici sessiz kayip dersi.)
#
#  VARSAYILAN: OLCUM (hicbir sey yazilmaz). Yazmak icin: -uygula
#  ENV: SUPABASE_SERVICE_KEY. Rapor: veri/harf-onarim.json
# ============================================================================
param([switch]$uygula, [int]$sinir = 0)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$TABAN = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/soru_havuzu'
$ciktiYol = Join-Path $kok 'veri/harf-onarim.json'

function Yaz($n){ [IO.File]::WriteAllText($ciktiYol, (ConvertTo-Json -InputObject $n -Depth 6), (New-Object Text.UTF8Encoding($false))) }
trap {
  $g = ''; if($_.ErrorDetails -and $_.ErrorDetails.Message){ $g = $_.ErrorDetails.Message }
  Yaz ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='HATA'; hata="$($_.Exception.Message)"; sunucu=$g; satir=$_.InvocationInfo.ScriptLineNumber })
  Write-Host ("HATA (satir {0}): {1}" -f $_.InvocationInfo.ScriptLineNumber, $_.Exception.Message)
  exit 1
}

$KEY = "$env:SUPABASE_SERVICE_KEY"
if([string]::IsNullOrWhiteSpace($KEY)){
  Yaz ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='ATLANDI'; not='SUPABASE_SERVICE_KEY yok' })
  Write-Host 'SUPABASE_SERVICE_KEY yok - atlandi.'; exit 0
}
$BASLIK = @{ apikey=$KEY; Authorization=("Bearer " + $KEY) }

# --- PS 5.1 UTF-8 tuzagi: IRM/IWR .Content Turkce harfi bozar -> ham bayt oku
function KasaGetir([string]$sorgu, [int]$zamanAsimi = 300){
  $r = Invoke-WebRequest -Uri ($TABAN + '?' + $sorgu) -Headers $BASLIK -UserAgent 'mevzuat-radar-robot/1.0' -UseBasicParsing -TimeoutSec $zamanAsimi
  return ([Text.Encoding]::UTF8.GetString($r.RawContentStream.ToArray()) | ConvertFrom-Json)
}
# Kismi guncelleme PATCH ile yapilir (POST/upsert NOT NULL kolonlarda 23502 verir)
function KasaYama([string]$id, $govde){
  $j = ConvertTo-Json -InputObject $govde -Depth 8 -Compress
  Invoke-WebRequest -Uri ($TABAN + '?id=eq.' + $id) -Method Patch -Headers ($BASLIK + @{ 'Content-Type'='application/json'; 'Prefer'='return=minimal' }) `
    -UserAgent 'mevzuat-radar-robot/1.0' -Body ([Text.Encoding]::UTF8.GetBytes($j)) -UseBasicParsing -TimeoutSec 120 | Out-Null
}

# --- SOZLUK: ascii_form -> dogru_form (elle onayli)
$sozlukYol = Join-Path $kok 'veri/harf-sozlugu.json'
if(-not (Test-Path $sozlukYol)){
  Yaz ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='ATLANDI'; not='veri/harf-sozlugu.json yok - onayli sozluk olmadan tek karakter degistirilmez.' })
  Write-Host 'Sozluk yok - cikildi.'; exit 0
}
$sozlukHam = Get-Content $sozlukYol -Raw -Encoding UTF8 | ConvertFrom-Json
# DIKKAT: PowerShell'in @{} tablosu anahtarlari BUYUK/KUCUK HARF AYIRMAZ.
# "sik" ile "Sik" ayni anahtara duser ve biri SESSIZCE kaybolur; ayrica
# "SIK" (mesru) yanlislikla "sik" kuralina baglanirdi. Bu yuzden ordinal
# karsilastiran generic Dictionary kullaniliyor.
$SOZLUK = New-Object 'System.Collections.Generic.Dictionary[string,string]'
foreach($e in @($sozlukHam.kelimeler)){
  $a = "$($e.ascii)"; $d = "$($e.dogru)"
  if($SOZLUK.ContainsKey($a)){ throw ("Sozlukte mukerrer anahtar: {0}" -f $a) }
  $SOZLUK[$a] = $d
}
if($SOZLUK.Count -eq 0){ throw 'Sozluk bos.' }
Write-Host ("Sozluk: {0} kelime" -f $SOZLUK.Count)

# --- kelime sinirli, BUYUK/KUCUK HARFE DUYARLI degisim
#
#  NEDEN DUYARLI: "sik" bozulmadir ama "SIK" MESRUDUR ("EN SIK HATA" =
#  en cok yapilan hata). 16.08'de olculdu: 2 gecis, ikisi de gecerli.
#  Harf-korur otomatik cevrim bu ikisini "SIK" yapip metni bozardi.
#  Bu yuzden sozlukte her buyuk/kucuk varyant AYRI SATIRDIR ve eslesme
#  tam olarak o yaziliMI arar.
#
#  TURKCE I TUZAGI (16.08'de olculdu): RegexOptions.IgnoreCase yerel kulture
#  bakar; tr-TR'de 'I' ile 'i' ayni harf DEGILDIR, bu yuzden IgnoreCase
#  kullanan bir esleme buyuk harfli bicimleri sessizce kacirirdi. Duyarli
#  esleme bu tuzagi tamamen ortadan kaldirir.
$SECENEK = [Text.RegularExpressions.RegexOptions]::CultureInvariant
$desenler = New-Object 'System.Collections.Generic.Dictionary[string,regex]'   # @{} harf ayirmaz - kullanma
foreach($a in $SOZLUK.Keys){
  $desenler[$a] = [regex]::new('(?<![\p{L}])' + [regex]::Escape($a) + '(?![\p{L}])', $SECENEK)
}
function MetinOnar([string]$metin, [ref]$sayac){
  if([string]::IsNullOrEmpty($metin)){ return $metin }
  $sonuc = $metin
  foreach($a in $SOZLUK.Keys){
    $dogru = $SOZLUK[$a]
    $sonuc = $desenler[$a].Replace($sonuc, {
      param($m)
      $sayac.Value = $sayac.Value + 1
      $dogru
    })
  }
  return $sonuc
}

# --- kasayi tara
$ALANLAR = 'id,soru,siklar,aciklama,hap'
$SAYFA = 1000
$satirlar = New-Object System.Collections.Generic.List[object]
$bas = 0
while($true){
  $d = @(KasaGetir ("select={0}&order=id&limit={1}&offset={2}" -f $ALANLAR, $SAYFA, $bas))
  if($d.Count -eq 0){ break }
  foreach($x in $d){ [void]$satirlar.Add($x) }
  $bas += $SAYFA
  if($d.Count -lt $SAYFA){ break }
}
Write-Host ("Taranan satir: {0}" -f $satirlar.Count)

$degisecek = New-Object System.Collections.Generic.List[object]
$toplamIsaret = 0
foreach($s in $satirlar){
  $sayac = 0
  $yeni = @{}
  $ySoru = MetinOnar "$($s.soru)" ([ref]$sayac)
  if($ySoru -ne "$($s.soru)"){ $yeni['soru'] = $ySoru }
  $yHap = MetinOnar "$($s.hap)" ([ref]$sayac)
  if($null -ne $s.hap -and $yHap -ne "$($s.hap)"){ $yeni['hap'] = $yHap }
  foreach($kolon in @('siklar','aciklama')){
    $nesne = $s.$kolon
    if($null -eq $nesne){ continue }
    $degisti = $false
    $kopya = [ordered]@{}
    foreach($h in @('A','B','C','D','E')){
      $v = $null; try { $v = "$($nesne.$h)" } catch {}
      if($null -eq $v){ continue }
      $yv = MetinOnar $v ([ref]$sayac)
      $kopya[$h] = $yv
      if($yv -ne $v){ $degisti = $true }
    }
    if($degisti){ $yeni[$kolon] = $kopya }
  }
  if($yeni.Count -gt 0){
    $toplamIsaret += $sayac
    [void]$degisecek.Add([pscustomobject]@{ id="$($s.id)"; isaret=$sayac; govde=$yeni })
  }
}
Write-Host ("Degisecek satir: {0} | toplam isaret: {1}" -f $degisecek.Count, $toplamIsaret)

if(-not $uygula){
  Yaz ([ordered]@{
    tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='OLCUM'; mod='olcum (yazma yok)'
    sozluk_kelime=$SOZLUK.Count; taranan=$satirlar.Count
    degisecek_satir=$degisecek.Count; degisecek_isaret=$toplamIsaret
    ornek=@($degisecek | Select-Object -First 5 | ForEach-Object { $_.id })
  })
  Write-Host 'OLCUM modu - hicbir sey yazilmadi. Yazmak icin: -uygula'
  exit 0
}

# --- UYGULA + GERI OKU + KARSILASTIR
$parti = @($degisecek)
if($sinir -gt 0){ $parti = @($degisecek | Select-Object -First $sinir) }
Write-Host ("YAZILIYOR: {0} satir" -f $parti.Count)
$yazildi = 0; $yazmaHatasi = 0; $hatalar = @()
foreach($d in $parti){
  try { KasaYama $d.id $d.govde; $yazildi++ }
  catch { $yazmaHatasi++; if($hatalar.Count -lt 10){ $hatalar += ("{0}: {1}" -f $d.id, $_.Exception.Message) } }
}
Write-Host ("Yazildi: {0} | yazma hatasi: {1}" -f $yazildi, $yazmaHatasi)

# GERI OKUMA: yazilan her satir tekrar cekilir, beklenenle BIREBIR kiyaslanir
$tutmayan = @()
foreach($d in $parti){
  $g = @(KasaGetir ("select={0}&id=eq.{1}" -f $ALANLAR, $d.id))
  if($g.Count -eq 0){ $tutmayan += ("{0}: geri okunamadi" -f $d.id); continue }
  $r = $g[0]
  foreach($kolon in $d.govde.Keys){
    if($kolon -eq 'soru' -or $kolon -eq 'hap'){
      if("$($r.$kolon)" -ne "$($d.govde[$kolon])"){ $tutmayan += ("{0}/{1}" -f $d.id, $kolon) }
    } else {
      foreach($h in $d.govde[$kolon].Keys){
        $bek = "$($d.govde[$kolon][$h])"; $ger = ''
        try { $ger = "$($r.$kolon.$h)" } catch {}
        if($ger -ne $bek){ $tutmayan += ("{0}/{1}.{2}" -f $d.id, $kolon, $h) }
      }
    }
  }
}

$durum = if($yazmaHatasi -eq 0 -and $tutmayan.Count -eq 0){ 'TAMAM' } else { 'KIRMIZI' }
Yaz ([ordered]@{
  tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum=$durum; mod='uygula'
  sozluk_kelime=$SOZLUK.Count; taranan=$satirlar.Count
  hedef_satir=$parti.Count; yazildi=$yazildi; yazma_hatasi=$yazmaHatasi
  geri_okuma_tutmayan=$tutmayan.Count; tutmayan_ornek=@($tutmayan | Select-Object -First 20)
  ilk_hatalar=$hatalar
})
Write-Host ("GERI OKUMA: tutmayan {0}" -f $tutmayan.Count)
if($durum -eq 'KIRMIZI'){ Write-Host 'KIRMIZI - rapora bak.'; exit 1 }
Write-Host 'TAMAM.'
