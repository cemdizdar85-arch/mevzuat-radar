# ============================================================================
#  YAYIN SIFIRLAMA — GUVENLI HALE DON (02.08.2026)
#
#  Cem'in emri: "1 adet bile yanlis soru ve cevap istemiyorum - bugune kadar
#  yayinlanmis ve yayinlanacak hicbirinde. Ne gerekirse yap."
#
#  DURUST DURUM: yayinda 9.905 soru var ve HICBIRINI insan okumadi. Hepsi robot
#  kapilarindan gecti; ama olctuk, robot kapilari kusursuz degil:
#    - hakem 12.996 hukmun 630'unda (%5) kendi alintisini UYDURDU,
#    - teori eslestirmesi ornekte %40 yanlis nota bagladi,
#    - uretim, kaynagi cozulemeyen soruları yine de kasaya yazabiliyordu.
#  Bu tabloda "yayindaki her soru dogru" DIYEMEM. Diyemedigim seyi yayinda
#  tutmak, Cem'in kuralini cignemektir.
#
#  NE YAPAR: yayindaki TUM sorulari yayin=false yapar (SILMEZ - kasada durur,
#  yayin_notu'na sebep yazilir). Yayin, ancak insan okumasindan gecen partilerle
#  YENIDEN acilir. Geri donusu vardir: her soru yerinde, yalnizca perde iner.
#
#  PARA HARCAMAZ. ENV: SUPABASE_SERVICE_KEY
#  Cikti: veri/yayin-sifirlama-raporu.json
# ============================================================================
param([switch]$uygula)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
if(-not $env:SUPABASE_SERVICE_KEY){ Write-Host "SUPABASE_SERVICE_KEY yok - cikildi."; exit 0 }
$U  = "https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/soru_havuzu"
$SB = @{ apikey = $env:SUPABASE_SERVICE_KEY; Authorization = "Bearer $($env:SUPABASE_SERVICE_KEY)" }
$raporYol = Join-Path $kok 'veri/yayin-sifirlama-raporu.json'

# yayindaki kimlikler
$idler = New-Object System.Collections.Generic.List[string]
$ofs = 0
while($true){
  $w = Invoke-WebRequest -Uri "${U}?select=id&yayin=eq.true&order=id&limit=1000&offset=$ofs" -Headers $SB -UseBasicParsing -TimeoutSec 120
  $ham = if($w.RawContentStream){ [Text.Encoding]::UTF8.GetString($w.RawContentStream.ToArray()) } else { $w.Content }
  $l = @($ham | ConvertFrom-Json); if($l.Count -eq 0){ break }
  foreach($s in $l){ $idler.Add("$($s.id)") }
  if($l.Count -lt 1000){ break }
  $ofs += 1000
}
Write-Host ("Yayinda: {0} soru" -f $idler.Count)

$cekilen = 0; $hata = 0
if($uygula -and $idler.Count){
  $govde = '{"yayin":false,"yayin_notu":"02.08.2026 GM: insan okumasindan gecmeden yayinda kalamaz (Cem kurali: tek bir yanlis soru bile olmayacak). Kasada duruyor, okunan partiyle yeniden acilacak."}'
  for($i = 0; $i -lt $idler.Count; $i += 100){
    $parti = $idler[$i..([Math]::Min($i+99, $idler.Count-1))]
    $inListe = ($parti -join ',')
    try {
      Invoke-RestMethod -Method Patch -Uri "${U}?id=in.($inListe)" `
        -Headers ($SB + @{ Prefer='return=minimal' }) -ContentType 'application/json' `
        -Body ([Text.Encoding]::UTF8.GetBytes($govde)) -TimeoutSec 120 | Out-Null
      $cekilen += $parti.Count
      if(($cekilen % 1000) -lt 100){ Write-Host ("  ... {0}/{1} cekildi" -f $cekilen, $idler.Count) }
    } catch {
      $hata += $parti.Count
      Write-Host "PARTI HATASI: $($_.Exception.Message)"
    }
  }
}

# GERI OKUYUP DOGRULA (yesil kosu != tam veri)
$wd = Invoke-WebRequest -Uri "${U}?select=id&yayin=eq.true&limit=1" -Headers ($SB + @{ Prefer='count=exact' }) -UseBasicParsing -Method Head -TimeoutSec 60
$kalan = ($wd.Headers['Content-Range'] -split '/')[-1]

$ozet = [ordered]@{
  tarih = (Get-Date -Format 'dd.MM.yyyy HH:mm')
  mod = $(if($uygula){'UYGULA'}else{'KURU KOSU'})
  gerekce = "Cem 02.08: 'tek bir yanlis soru ve cevap istemiyorum'. Yayindaki hicbir soru insan okumasindan gecmemisti; olculen robot kusurlari (%5 uydurma alinti, teori eslemede %40 yanlis) sebebiyle 'hepsi dogru' denemez. Perde indirildi; soru SILINMEDI."
  yayindaydi = $idler.Count
  cekilen = $cekilen
  hata = $hata
  yayinda_kalan = $kalan
  sonraki_adim = "Insan okumasi (motor/yayin-denetim.ps1) + ikinci bagimsiz hakem; yalniz okunan ve temiz cikan partiler yeniden yayina acilacak."
}
$j = ConvertTo-Json -InputObject $ozet -Depth 5
if($j -isnot [string]){ $j = ($j -join [Environment]::NewLine) }
Set-Content -LiteralPath $raporYol -Value ([string]$j) -Encoding UTF8 -NoNewline
Write-Host ("CEKILEN: {0} | HATA: {1} | YAYINDA KALAN: {2}" -f $cekilen, $hata, $kalan)
