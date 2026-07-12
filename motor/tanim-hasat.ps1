# ============================================================================
#  TANIM HASAT - Turk Gumruk Tarife Cetveli esya tanimlari (97 fasil .xls)
#  Kaynak: Ticaret Bakanligi GGM resmi Excel seti (Karar 10781, RG 30.12.2025/33123)
#  Yapi: kolon1 = POZISYON NO, kolon2 = ESYANIN TANIMI
#    - 12 haneli noktali kod = LEAF (aranabilir GTIP)
#    - kodsuz + tire ile baslayan satir = ara baslik (tire sayisi = derinlik)
#    - kodsuz + tiresiz satir = onceki girdinin devami
#  LEAF metni = ust baslik zinciri + kendi metni (arama icin tam baglam)
#  Cikti: veri\gtip-tanim.json = { "2501.00.31.00.00": "Tuz ... > ... > tanim" }
# ============================================================================
param(
  [string]$TgtcKlasor = "C:\Users\cemdi\AppData\Local\Temp\claude\C--Users-cemdi-OneDrive-Masa-st--mevzuat-i-i\45bc0a17-a2f9-4845-8233-eb8caab2a9d2\scratchpad\tgtc2026\2026 TGTC\2026 TGTC"
)
$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here

function Temiz([string]$s){
  if(-not $s){ return "" }
  return (($s -replace "\s+"," ").Trim())
}
# metnin basindaki tire grubunu say: " - - Diger" -> 2
function TireDerinlik([string]$s){
  $m = [regex]::Match($s, '^\s*((?:-\s*)+)')
  if(-not $m.Success){ return 0 }
  return ([regex]::Matches($m.Groups[1].Value,'-')).Count
}

$dosyalar = Get-ChildItem $TgtcKlasor -Filter "*.xls" | Sort-Object Name
"Fasil dosyasi: $($dosyalar.Count)"

$xl = New-Object -ComObject Excel.Application
$xl.Visible = $false; $xl.DisplayAlerts = $false
$tanim = [ordered]@{}
$dosyaNo = 0

foreach($d in $dosyalar){
  $dosyaNo++
  $wb = $xl.Workbooks.Open($d.FullName, 0, $true)
  try {
    $ws = $wb.Worksheets.Item(1)
    $deger = $ws.UsedRange.Value2   # tek COM cagrisi: 2D dizi
    if($null -eq $deger){ continue }
    $satirN = $deger.GetLength(0)

    # --- satirlari GIRDI'lere birlestir (kod/baslik + devam satirlari) ---
    $girdiler = @()   # her girdi: @{ kod=..; metin=.. }
    $aktif = $null
    for($r=1; $r -le $satirN; $r++){
      $kod   = Temiz ([string]$deger[$r,1])
      $metin = Temiz ([string]$deger[$r,2])
      if($kod -eq "" -and $metin -eq ""){ continue }
      if($kod -match '^\d'){
        # yeni kodlu girdi
        if($aktif){ $girdiler += ,$aktif }
        $aktif = @{ kod = $kod; metin = $metin }
      }
      elseif($metin -match '^\s*-'){
        # kodsuz ara baslik (yeni girdi)
        if($aktif){ $girdiler += ,$aktif }
        $aktif = @{ kod = ""; metin = $metin }
      }
      elseif($metin -ne "" -and $metin -notmatch '^(POZİSYON|EŞYANIN|ÖLÇÜ|474|VERGİ|\d\s*$)'){
        # devam satiri
        if($aktif){ $aktif.metin = ($aktif.metin + " " + $metin) }
        else { $aktif = @{ kod = ""; metin = $metin } }
      }
    }
    if($aktif){ $girdiler += ,$aktif }

    # --- hiyerarsi yigini ile leaf'lere tam baglam yaz ---
    # yigin: derinlik -> baslik metni (tiresiz temiz)
    $yigin = @{}
    foreach($g in $girdiler){
      $m = Temiz $g.metin
      if($m -eq ""){ continue }
      $d0 = TireDerinlik $m
      $sade = Temiz ($m -replace '^\s*(?:-\s*)+','')
      $kodDuz = ($g.kod -replace '\.','')
      if($kodDuz -match '^\d{11,12}$'){
        # LEAF: 12 haneli kod
        if($kodDuz.Length -eq 11){ $kodDuz = "0" + $kodDuz }
        $kodN = $kodDuz.Substring(0,4)+"."+$kodDuz.Substring(4,2)+"."+$kodDuz.Substring(6,2)+"."+$kodDuz.Substring(8,2)+"."+$kodDuz.Substring(10,2)
        $parcalar = @()
        foreach($dk in ($yigin.Keys | Where-Object { $_ -lt $d0 } | Sort-Object)){
          if($yigin[$dk]){ $parcalar += $yigin[$dk] }
        }
        $parcalar += $sade
        $tanim[$kodN] = (($parcalar -join " › ") -replace '\s+',' ').Trim()
        # leaf de bir sonraki daha derin leafler icin baslik olabilir mi? Hayir - leaf yigina girmez
      }
      else {
        # BASLIK (pozisyon basligi veya tireli ara baslik)
        # kendinden derin eski basliklari temizle
        foreach($dk in @($yigin.Keys | Where-Object { $_ -ge $d0 })){ $yigin.Remove($dk) }
        $yigin[$d0] = $sade
      }
    }
  }
  finally { $wb.Close($false) }
  if($dosyaNo % 10 -eq 0){ Write-Host ("  {0}/{1} dosya - toplam {2} kod" -f $dosyaNo, $dosyalar.Count, $tanim.Count) }
}
$xl.Quit()
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($xl) | Out-Null

$veriDir = Join-Path $kok "veri"; New-Item -ItemType Directory -Force $veriDir | Out-Null
$hedef = Join-Path $veriDir "gtip-tanim.json"
($tanim | ConvertTo-Json -Depth 2 -Compress) | Out-File $hedef -Encoding utf8

""
"TANIM HASAT BITTI. Kod: $($tanim.Count)"
"veri\gtip-tanim.json ($([math]::Round((Get-Item $hedef).Length/1MB,2)) MB)"
"--- ornek 2501.00.31.00.00 ---"
if($tanim.Contains("2501.00.31.00.00")){ "  " + $tanim["2501.00.31.00.00"] }
"--- ornek 2515.11.00.00.00 (mermer) ---"
if($tanim.Contains("2515.11.00.00.00")){ "  " + $tanim["2515.11.00.00.00"] }
"--- ornek 0403.20.51.00.00 ---"
if($tanim.Contains("0403.20.51.00.00")){ "  " + $tanim["0403.20.51.00.00"] }
