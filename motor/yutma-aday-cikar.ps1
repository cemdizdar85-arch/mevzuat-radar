# ============================================================================
#  YUTMA ADAY CIKARICI - 27.08.2026 (Cem onayi: GM onerisi 2)
#
#  Kor hakem sonuc dosyasindaki 'teyit-edilemedi' bayraklarini toplar ve
#  veri/fabrika/yutma-aday.json listesine ekler (id bazinda tekil).
#  MANTIK: hakem bir dayanagi ambarda dogrulayamiyorsa iki ihtimal var -
#  (a) kaynak ambarda hic yok (238 no.lu VUK GT vakasi), (b) parca kesik
#  (TMS 36 p.105 vakasi). Iki durumda da yutma/onarim adayidir; hakem turlari
#  boylece kendiliginden yutma-is-listesi uretir, "sik konu sessizce bos
#  kalmaz" sozunun ikinci ayagi budur.
#
#  Kullanim: .\motor\yutma-aday-cikar.ps1 -sonuc <hakem-sonuc.jsonl>
#  Cikti: veri/fabrika/yutma-aday.json (okuma: her satir {id, sinav, gerekce,
#  tarih, durum='acik'}) - kapatilan aday elle 'kapandi' yapilir.
# ============================================================================
param([Parameter(Mandatory=$true)][string]$sonuc)
$ErrorActionPreference='Stop'
$here=Split-Path -Parent $MyInvocation.MyCommand.Path
$kok=Split-Path -Parent $here
$adayYol=Join-Path $kok 'veri\fabrika\yutma-aday.json'
# PS 5.1: ConvertFrom-Json ust-duzey JSON dizisini TEK nesne olarak dondurur -
# boruyla acilmazsa @() sarmasi 1 elemanli olur ve dosya bozulur (27.08 oz-sinav yakaladi)
$mevcut=@()
if(Test-Path $adayYol){ $mevcut=@((Get-Content $adayYol -Raw -Encoding UTF8 | ConvertFrom-Json) | % { $_ }) }
$gorulen=@{}; foreach($m in $mevcut){ $gorulen[$m.id]=1 }
$yeni=0
foreach($sat in (Get-Content $sonuc -Encoding UTF8)){
  $p=$sat | ConvertFrom-Json
  foreach($s in @($p.sonuclar)){
    if(@($s.bayraklar) -notcontains 'teyit-edilemedi'){ continue }
    if($gorulen["$($s.id)"]){ continue }
    $gorulen["$($s.id)"]=1; $yeni++
    $mevcut+=[pscustomobject]@{
      id=$s.id
      sinav=($s.id -split '-')[0]
      gerekce=$s.gerekce
      tarih=(Get-Date -Format 'dd.MM.yyyy')
      durum='acik'
    }
  }
}
ConvertTo-Json @($mevcut) -Depth 4 | Out-File $adayYol -Encoding utf8
"yutma-aday: +$yeni yeni / toplam $($mevcut.Count) ($adayYol)"
# oz-sinav: dosya geri okunabiliyor mu + az once eklenenler icinde mi
$kontrol=@((Get-Content $adayYol -Raw -Encoding UTF8 | ConvertFrom-Json) | % { $_ })
if($kontrol.Count -ne $mevcut.Count){ throw "OZ-SINAV KIRMIZI: yazilan $($mevcut.Count) != okunan $($kontrol.Count)" }
"oz-sinav yesil: $($kontrol.Count) kayit geri okundu"
