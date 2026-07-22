# ============================================================================
#  KARSIT-PROFESOR — canli icerigi CURUTMEYE calisan haftalik hata avcisi.
#  bilgi-tabani.json'dan rastgele N kayit ceker; guclu modele tek gorev verir:
#  "Bu cevabi curut. Yururlukteki mevzuattan delil getir."
#  Bir kaydi KARANTINAYA almak icin IKI bagimsiz kosunun da curutmesi gerekir
#  (yanlis pozitif freni). Karantina = yayindan otomatik silme DEGIL:
#  veri/karantina.json + Cem'e mail -> insan karari (robot da yanilabilir).
#  ENV: ANTHROPIC_API_KEY zorunlu; RESEND_KEY/RESEND_FROM varsa mail atar.
# ============================================================================
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$MODEL = "claude-sonnet-5"
$ORNEKLEM = 10
$key = $env:ANTHROPIC_API_KEY
if(-not $key){ Write-Host "ANTHROPIC_API_KEY yok - atlandi."; exit 0 }

function Claude($istem,$maxtok){
  $body = @{ model=$MODEL; max_tokens=$maxtok; messages=@(@{ role="user"; content=$istem }) } | ConvertTo-Json -Depth 6 -Compress
  $r = Invoke-RestMethod -Method Post -Uri "https://api.anthropic.com/v1/messages" `
        -Headers @{ "x-api-key"=$key; "anthropic-version"="2023-06-01" } `
        -Body ([Text.Encoding]::UTF8.GetBytes($body)) -ContentType "application/json" -TimeoutSec 300
  return (@($r.content) | Where-Object { $_.type -eq 'text' } | ForEach-Object { $_.text }) -join ""
}
function JsonBul($t){ $m=[regex]::Match($t,'(?s)\{.*\}'); if($m.Success){ return $m.Value }; return $null }

$kb = Get-Content (Join-Path $kok "veri/bilgi-tabani.json") -Raw -Encoding UTF8 | ConvertFrom-Json
$havuz = @($kb.kayitlar)
if($havuz.Count -lt $ORNEKLEM){ $ORNEKLEM = $havuz.Count }
$secilen = $havuz | Get-Random -Count $ORNEKLEM
Write-Host ("Karsit-Profesor: {0} kayitlik havuzdan {1} kayit sorgulanacak." -f $havuz.Count, $ORNEKLEM)

$karantina = New-Object System.Collections.Generic.List[object]
$rapor = New-Object System.Collections.Generic.List[string]

foreach($k in $secilen){
  $istem = @"
Sen Turkiye vergi/ticaret/is mevzuatinda HASIM bir profesorsun. Tek gorevin asagidaki yayimlanmis cevabi CURUTMEK.
Su acilardan saldir: (1) yanlis/uydurma madde atifi, (2) yururlukten kalkmis/degistirilmis hukum (guncel mevzuata gore ESKIMIS bilgi), (3) yanlis oran/sure/esik, (4) asiri genelleme (istisnayi yutmus), (5) kavram karisikligi.
Curutebiliyorsan somut DELIL goster (madde no / degisiklik kanunu). Emin degilsen curutme — supheni belirt ama curudu:false de. Ciddi ve savunulabilir hatalarda curudu:true.
KONU: $($k.konu)
CEVAP: $($k.cevap)
KAYNAK GOSTERILEN: $($k.kaynak)
SADECE JSON: {"curudu":true/false,"ciddiyet":1-5,"delil":"madde/kanun","aciklama":"kisa"}
"@
  $c1=$null
  try{ $c1=(JsonBul (Claude $istem 700)) | ConvertFrom-Json }catch{}
  if(-not $c1){ $rapor.Add("SORGU HATASI: $($k.id)"); continue }
  if(-not [bool]$c1.curudu){ $rapor.Add("SAGLAM: $($k.id) ($($k.konu))"); continue }
  # ilk kosu curuttu -> ikinci bagimsiz gorus
  $c2=$null
  try{ $c2=(JsonBul (Claude $istem 700)) | ConvertFrom-Json }catch{}
  if($c2 -and [bool]$c2.curudu){
    $karantina.Add([ordered]@{ id=$k.id; konu=$k.konu; kaynak=$k.kaynak; ciddiyet=[Math]::Max([int]$c1.ciddiyet,[int]$c2.ciddiyet);
      delil1="$($c1.delil) - $($c1.aciklama)"; delil2="$($c2.delil) - $($c2.aciklama)"; tarih=(Get-Date -Format "dd.MM.yyyy") })
    $rapor.Add("KARANTINA (2/2 curuttu, ciddiyet $([Math]::Max([int]$c1.ciddiyet,[int]$c2.ciddiyet))): $($k.id) -> $($c1.delil)")
  } else {
    $rapor.Add("TEK OY (1/2, karantina yok): $($k.id) -> $($c1.aciklama)")
  }
}

Write-Host "--- RAPOR ---"; $rapor | ForEach-Object { Write-Host "  $_" }

if($karantina.Count -gt 0){
  $kYol = Join-Path $kok "veri/karantina.json"
  $mevcut = if(Test-Path $kYol){ Get-Content $kYol -Raw -Encoding UTF8 | ConvertFrom-Json } else { [pscustomobject]@{ kayitlar=@() } }
  $liste = New-Object System.Collections.Generic.List[object]
  if($mevcut.kayitlar){ $liste.AddRange(@($mevcut.kayitlar)) }
  foreach($x in $karantina){ if(-not ($liste | Where-Object { $_.id -eq $x.id })){ $liste.Add([pscustomobject]$x) } }
  $out = [pscustomobject]@{ guncelleme=(Get-Date -Format "dd.MM.yyyy HH:mm"); kayitlar=$liste.ToArray() }
  [IO.File]::WriteAllText($kYol, ($out | ConvertTo-Json -Depth 6), (New-Object Text.UTF8Encoding($false)))
  Write-Host ("KARANTINA: {0} yeni supheli kayit yazildi (insan karari bekliyor)." -f $karantina.Count)
  if($env:RESEND_KEY){
    $satirlar = ($karantina | ForEach-Object { "<li><b>$($_.id)</b> ($($_.konu)) — ciddiyet $($_.ciddiyet)/5<br>Delil-1: $($_.delil1)<br>Delil-2: $($_.delil2)</li>" }) -join ""
    $html = "<h3>Karsit-Profesor haftalik raporu</h3><p>$($secilen.Count) kayit sorgulandi; $($karantina.Count) kayit IKI bagimsiz kosuda da curutuldu ve karantinaya alindi. Icerik CANLIDA duruyor — karar sizin: duzelt / kaldir / robot yaniliyor.</p><ul>$satirlar</ul><p>Tetikte — hata avcisi</p>"
    $mb = @{ from=$env:RESEND_FROM; to=@("cemdizdar85@hotmail.com"); subject="TETIKTE HATA AVCISI: $($karantina.Count) supheli kayit (insan karari gerekli)"; html=$html } | ConvertTo-Json -Depth 3
    try { Invoke-RestMethod -Method Post -Uri "https://api.resend.com/emails" -Headers @{ Authorization="Bearer $($env:RESEND_KEY)" } -Body ([Text.Encoding]::UTF8.GetBytes($mb)) -ContentType "application/json" | Out-Null; Write-Host "rapor maili gitti" } catch { Write-Host "mail hatasi: $_" }
  }
} else {
  Write-Host "TEMIZ HAFTA: orneklemdeki hicbir kayit iki oyla curutulmedi."
}
exit 0
