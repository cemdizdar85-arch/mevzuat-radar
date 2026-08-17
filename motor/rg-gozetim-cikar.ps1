# ============================================================================
#  RG GOZETIM ZINCIRI CIKARICI (17.08.2026)
#
#  Cem: "eski hali kanun buymus yeni hali bu oldu gibi guzel bir aciklama
#  yapmamiz lazim." Bugun olculdu: arsivdeki 189 hap kartin YALNIZ 3'unde
#  (%1,6) eski->yeni satiri var. Sebep modelin uydurmamasi - eski degeri ancak
#  teblig METNI acikca yaziyorsa dolduruyor (dogru davranis).
#
#  AMA 189 kartin 130'unda "degistirilen_teblig" DOLU. Yani "hangi tebligi
#  degistirdigini" biliyoruz, "eskiden ne yaziyordu"yu bilmiyoruz. Kopru bu:
#  degistirilen teblig no -> onu daha once degistiren RG belgesi -> o belgenin
#  metnindeki deger = ESKI DEGER.
#
#  BU BETIK O ZINCIRI KURAR. veri/rg-gozetim-haritasi.json (3.023 gun taranmis,
#  231 belge) ham listedir; buradan:
#    (1) GERCEK ithalat tedbiri tebliglerini ayirir - ham listede "Piyasa
#        Gozetimi", "Sigorta Bilgi ve Gozetim Merkezi", "Nukleer Tesislerde
#        Bagimsiz Gozetim" gibi YANLIS POZITIFLER var.
#    (2) baslikta gecen teblig numarasini cikarir. Ham listede teblig_no alani
#        231 kaydin 231'inde de BOS - oysa numara baslikta duz metin. (4
#        kayitta ayirac HTML varligi: "No:&#8200;2024/6" - once cozulur.)
#    (3) turunu belirler: asil / degisiklik / mulga
#    (4) numaraya gore KRONOLOJIK zincir kurar.
#
#  KOVA KURALI: ithalatta + disarida = taranan. Tutmazsa kirmizi.
#
#  Kullanim:
#    ./motor/rg-gozetim-cikar.ps1            # OLCUM (yazmaz)
#    ./motor/rg-gozetim-cikar.ps1 -Uygula    # veri/gozetim-teblig-zinciri.json yazar
#
#  PARA HARCAMAZ - tamamen yerel, cagri yok.
# ============================================================================
param([switch]$Uygula)
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here

$haritaYol = Join-Path $kok 'veri/rg-gozetim-haritasi.json'
if(-not (Test-Path $haritaYol)){ Write-Host "BULUNAMADI: veri/rg-gozetim-haritasi.json" -ForegroundColor Red; exit 1 }
$h = Get-Content $haritaYol -Raw -Encoding UTF8 | ConvertFrom-Json
$kayitlar = @($h.kayit)

# TURKCE HARFLER \u KACISIYLA. Sebep: bu betik BOM'suz UTF-8 kaydedilirse
# PS 5.1 dosyayi ANSI okur ve "Ithalatta" deseni SESSIZCE bozulur - hicbir
# kayit eslesmez, betik "0 bulundu" der ve dogru sanilir. Kacis dizisi
# kodlamadan bagimsizdir; bu dosyada Turkce harf desene GIRMEZ.
# İ=I(noktali) ö=o ı=i(noktasiz) Ü=U ü=u
# ğ=g(yumusak) ş=s(cedilli)
$ICERI     = 'İthalatta\s+(Gözetim|Korunma|Haksız\s+Rekabetin|Kota|Bazı\s+Ürünlerin)'
$NO_DESENI = '(?:Tebliğ\s*)?No\s*:?\s*(\d{4}\s*/\s*\d+)'
$MULGA     = 'Yürürlükten\s+Kaldırıl'
$DEGISIK   = 'Değişiklik\s+Yapılmasına'

function HtmlCoz([string]$s){
  $t = [Net.WebUtility]::HtmlDecode("$s")
  # cozulen dar/kirilmayan bosluklar ("No:&#8200;2024/6") normale cevrilir.
  # Sinif kacis dizisiyle yazilir - dosyaya ciplak U+2008 gomulurse bozuluyor.
  return ([regex]::Replace($t, "[  -​  　]", ' ')).Trim()
}

$ithalatta = New-Object System.Collections.Generic.List[object]
$disarida  = New-Object System.Collections.Generic.List[object]
foreach($k in $kayitlar){
  $b = HtmlCoz $k.baslik
  if($b -match $ICERI){ $ithalatta.Add([pscustomobject]@{ tarih=$k.tarih; kod=$k.kod; url=$k.url; baslik=$b }) }
  else { $disarida.Add([pscustomobject]@{ tarih=$k.tarih; baslik=$b }) }
}

Write-Host '======== RG GOZETIM ZINCIRI ========'
Write-Host ("  ham kayit                  : {0}" -f $kayitlar.Count)
Write-Host ("  GERCEK ithalat tedbiri     : {0}" -f $ithalatta.Count)
Write-Host ("  ilgisiz (yanlis pozitif)   : {0}" -f $disarida.Count)
Write-Host ("  kova toplami dogrulama     : {0} = {1}" -f ($ithalatta.Count + $disarida.Count), $kayitlar.Count)
if(($ithalatta.Count + $disarida.Count) -ne $kayitlar.Count){ Write-Host '  KIRMIZI: kova toplami tutmadi.' -ForegroundColor Red; exit 1 }
if($ithalatta.Count -eq 0){
  # kodlama bozulmasi tam olarak boyle gorunur: hata yok ama sonuc sifir
  Write-Host '  KIRMIZI: hicbir kayit eslesmedi - desen ya da kodlama bozuk olabilir.' -ForegroundColor Red; exit 1
}

# --- numara + tur
$noYok = New-Object System.Collections.Generic.List[string]
$zincir = @{}
$asil=0; $degisiklik=0; $mulga=0
foreach($x in $ithalatta){
  $m = [regex]::Match($x.baslik, $NO_DESENI)
  if(-not $m.Success){ $noYok.Add($x.baslik); continue }
  $no = ($m.Groups[1].Value -replace '\s','')
  $tur = 'asil'
  if($x.baslik -match $MULGA){ $tur='mulga'; $mulga++ }
  elseif($x.baslik -match $DEGISIK){ $tur='degisiklik'; $degisiklik++ }
  else { $asil++ }
  if(-not $zincir.ContainsKey($no)){ $zincir[$no] = New-Object System.Collections.Generic.List[object] }
  $zincir[$no].Add([pscustomobject]@{ tarih=$x.tarih; kod=$x.kod; url=$x.url; tur=$tur; baslik=$x.baslik })
}

Write-Host ''
Write-Host ("  teblig no CIKAN            : {0}" -f ($ithalatta.Count - $noYok.Count))
Write-Host ("  teblig no cikmayan         : {0}" -f $noYok.Count)
Write-Host ("  ayri teblig numarasi       : {0}" -f $zincir.Count)
Write-Host ("    asil / degisiklik / mulga: {0} / {1} / {2}" -f $asil, $degisiklik, $mulga)
if($noYok.Count -gt 0){
  Write-Host '  --- numara cikmayan basliklar ---'
  foreach($b in ($noYok | Select-Object -First 5)){ Write-Host ("     " + $b) }
}

# --- zinciri tarihe gore sirala (eskiden yeniye)
$sirali = [ordered]@{}
foreach($no in ($zincir.Keys | Sort-Object)){
  $liste = @($zincir[$no] | Sort-Object { [datetime]::ParseExact($_.tarih,'dd.MM.yyyy',$null) })
  $sirali[$no] = $liste
}
$cokluk = @($sirali.Keys | Where-Object { @($sirali[$_]).Count -gt 1 })
Write-Host ''
Write-Host ("  birden fazla belgesi olan teblig : {0}  <-- 'eski hali' bunlarda bulunabilir" -f $cokluk.Count)
foreach($no in ($cokluk | Select-Object -First 6)){
  $l = @($sirali[$no])
  Write-Host ("     {0} : {1} belge ({2} -> {3})" -f $no, $l.Count, $l[0].tarih, $l[-1].tarih)
}

if(-not $Uygula){
  Write-Host ''
  Write-Host 'OLCUM MODU - veri/gozetim-teblig-zinciri.json YAZILMADI.'
  Write-Host 'Yazmak icin: ./motor/rg-gozetim-cikar.ps1 -Uygula'
  exit 0
}

$cikti = [ordered]@{
  aciklama = 'Ithalat gozetim/korunma tebliglerinin numaraya gore kronolojik zinciri. Kart motoru "bu teblig neyi degistirdi, oncesinde ne vardi" sorusunu buradan cozer.'
  kaynak = 'veri/rg-gozetim-haritasi.json (RG taramasi)'
  uretim = (Get-Date -Format 'dd.MM.yyyy HH:mm')
  ham_kayit = $kayitlar.Count
  ithalat_tedbiri = $ithalatta.Count
  ilgisiz = $disarida.Count
  teblig_sayisi = $sirali.Count
  zincir = $sirali
}
$ciktiYol = Join-Path $kok 'veri/gozetim-teblig-zinciri.json'
[IO.File]::WriteAllText($ciktiYol, ($cikti | ConvertTo-Json -Depth 6), (New-Object Text.UTF8Encoding($true)))
Write-Host ''
Write-Host ("Yazildi: veri/gozetim-teblig-zinciri.json ({0} teblig)" -f $sirali.Count)
exit 0
