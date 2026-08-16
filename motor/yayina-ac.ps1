# ============================================================================
#  YAYINA ACMA (02.08 Cem onayi: "ONAYLIYORUM" — hakemden 3/3 gecen sorular
#  yayina acilsin). KURAL: yalnizca UCUNU DE gecen soru acilir —
#    destek = evet  AND  tek_dogru = evet  AND  celiski = hayir
#  ve hakemin alintisi MAKINEYLE dogrulanmis olacak (alinti_dogrulandi=true).
#  Alintisi dogrulanmamis hukum GUVENILMEZ sayilir, o soru ACILMAZ.
#  Kaynagi 'yetersiz' cikan sorular ACILMAZ — kaynak onarimindan sonra
#  yeniden yargilanacaklar (02.08 bulgusu: muhasebe sorulari VUK'a baglanmis,
#  dogru kaynak MSUGT/THP).
#  PATCH kullanilir (kismi-kolon upsert NOT NULL duvarina carpar - 27.07 dersi).
#  Yazdiktan sonra GERI OKUYUP SAYAR (yesil kosu != tam veri dersi).
#  ENV: SUPABASE_SERVICE_KEY. Rapor: veri/yayina-acma-raporu.json
# ============================================================================
$ErrorActionPreference = "Stop"
# Supabase gizli anahtarli istegi KIMLIKSIZ gelirse 401 ile reddeder.
# (16.08.2026 olculdu: ayni sorgu UA'siz 401, UA'li 5 kayit. madde-coz.ps1
#  bu yuzden her kaynaga "ambarda-yok" diyordu.) IRM ve IWR AYRI yazilir.
$PSDefaultParameterValues['Invoke-RestMethod:UserAgent'] = 'mevzuat-radar-robot/1.0'
$PSDefaultParameterValues['Invoke-WebRequest:UserAgent'] = 'mevzuat-radar-robot/1.0'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$U  = "https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/soru_havuzu"
$SB = @{ apikey = $env:SUPABASE_SERVICE_KEY; Authorization = "Bearer $($env:SUPABASE_SERVICE_KEY)" }
if(-not $env:SUPABASE_SERVICE_KEY){ Write-Host "SUPABASE_SERVICE_KEY yok - cikildi."; exit 0 }

$raporYol = 'veri/yayina-acma-raporu.json'
function Rapor($n){ [IO.File]::WriteAllText($raporYol, (ConvertTo-Json -InputObject $n -Depth 5), (New-Object Text.UTF8Encoding($false))) }
trap {
  $g = ""; if($_.ErrorDetails -and $_.ErrorDetails.Message){ $g = $_.ErrorDetails.Message }
  Rapor ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='HATA'; hata="$($_.Exception.Message)"; sunucu=$g; satir=$_.InvocationInfo.ScriptLineNumber })
  Write-Host ("HATA (satir {0}): {1} | sunucu: {2}" -f $_.InvocationInfo.ScriptLineNumber, $_.Exception.Message, $g)
  exit 1
}

# --- hakem raporlarindan 3/3 gecen kimlikler
$acilacak = New-Object 'System.Collections.Generic.HashSet[string]'
$okunanRapor = @()
foreach($f in (Get-ChildItem 'veri' -Filter 'profesor-rapor-*.json' -ErrorAction SilentlyContinue)){
  try { $r = Get-Content $f.FullName -Raw -Encoding UTF8 | ConvertFrom-Json } catch { continue }
  if(-not $r.sonuclar){ continue }
  $sayac = 0
  foreach($s in @($r.sonuclar)){
    if("$($s.destek)" -ne 'evet'){ continue }
    if("$($s.tek_dogru)" -ne 'evet'){ continue }
    if("$($s.celiski)" -ne 'hayir'){ continue }
    if($s.PSObject.Properties['alinti_dogrulandi'] -and $s.alinti_dogrulandi -ne $true){ continue }
    if("$($s.id)".Length -lt 8){ continue }
    [void]$acilacak.Add("$($s.id)"); $sayac++
  }
  $okunanRapor += ("{0}: {1} temiz" -f $f.Name, $sayac)
}
Write-Host ("Hakem raporlari: {0}" -f ($okunanRapor -join ' | '))
Write-Host ("3/3 gecen tekil kimlik: {0}" -f $acilacak.Count)
if($acilacak.Count -eq 0){ Rapor ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='IS YOK'; not='3/3 gecen soru bulunamadi' }); exit 0 }

# ============================================================================
#  INSAN OKUMASI KAPISI — 02.08.2026
#  SINAV-KURALLARI H1: "Insan okumasindan gecmeyen soru yayina acilamaz.
#  Robot kapilari on elemedir, YETERLILIK BELGESI DEGILDIR."
#
#  Bu betik H1'den ONCE yazilmisti ve yalniz hakem 3/3 oluyordu; yani sozlesme
#  ile kod uyusmuyordu. Dugmeye basilsa OKUNMAMIS binlerce soru yayina giderdi.
#  Artik hakem 3/3 GEREK ama YETER degil: kimligin ayrica veri/okundu-onay.json
#  icinde bulunmasi sart. O dosyaya bir kimlik ancak bir INSAN okuyup onaylayinca
#  girer. Dosya yoksa ya da bossa yayin ACILMAZ - varsayilan "hayir"dir.
# ============================================================================
$onayYol = 'veri/okundu-onay.json'
$okundu = New-Object 'System.Collections.Generic.HashSet[string]'
$partiOzet = @()
if(Test-Path $onayYol){
  try {
    $oj = Get-Content $onayYol -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach($p in @($oj.partiler)){
      $n = 0
      foreach($id in @($p.idler)){ if("$id".Length -ge 8){ [void]$okundu.Add("$id"); $n++ } }
      $partiOzet += ("{0} ({1}): {2} soru" -f "$($p.tarih)", "$($p.kaynak)", $n)
    }
  } catch { Write-Host ("okundu-onay.json okunamadi: {0}" -f $_.Exception.Message) }
}
Write-Host ("INSAN OKUMASI: {0} onayli kimlik | partiler: {1}" -f $okundu.Count, $(if($partiOzet.Count){ $partiOzet -join ' | ' } else { 'YOK' }))
if($okundu.Count -eq 0){
  Rapor ([ordered]@{
    tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='ACILMADI - INSAN OKUMASI YOK'
    kural='SINAV-KURALLARI H1'; hakem_3_3=$acilacak.Count; okundu_onayli=0
    not="veri/okundu-onay.json bos ya da yok. Hakem 3/3 gerekli ama yeterli degil; bir insan okuyup onaylamadan soru yayina acilmaz."
  })
  Write-Host "YAYIN ACILMADI: insan okumasi onayi yok (H1). 0 soru acildi."
  exit 0
}
# kesisim: hem hakem 3/3 hem insan onayli
$kesisim = New-Object 'System.Collections.Generic.HashSet[string]'
foreach($id in $acilacak){
  $kisa = if("$id".Length -ge 8){ "$id".Substring(0,8) } else { "$id" }
  if($okundu.Contains("$id") -or $okundu.Contains($kisa)){ [void]$kesisim.Add("$id") }
}
Write-Host ("Hakem 3/3 VE insan onayli: {0} soru acilacak (hakemden gecen ama okunmamis: {1})" -f $kesisim.Count, ($acilacak.Count - $kesisim.Count))
$acilacak = $kesisim
if($acilacak.Count -eq 0){
  Rapor ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='IS YOK'; not='Insan onayli kimliklerin hicbiri hakem 3/3 listesinde degil' })
  exit 0
}

# --- kasadaki kimlikler kisa (8 hane) olabilir; kasadan tam kimlikleri cek ve esle
$kasaIdler = New-Object System.Collections.Generic.List[string]
$ofs = 0
while($true){
  $w = Invoke-WebRequest -Uri "${U}?select=id&yayin=eq.false&limit=1000&offset=$ofs&order=id" -Headers $SB -UseBasicParsing -TimeoutSec 120
  $ham = if($w.RawContentStream){ [Text.Encoding]::UTF8.GetString($w.RawContentStream.ToArray()) } else { $w.Content }
  $liste = @($ham | ConvertFrom-Json)
  if($liste.Count -eq 0){ break }
  foreach($s in $liste){ $kasaIdler.Add("$($s.id)") }
  if($liste.Count -lt 1000){ break }
  $ofs += 1000
}
Write-Host ("Kasada yayin=false: {0}" -f $kasaIdler.Count)

$hedef = New-Object System.Collections.Generic.List[string]
foreach($tam in $kasaIdler){
  if($acilacak.Contains($tam)){ $hedef.Add($tam); continue }
  $kisa = $tam.Substring(0,8)
  if($acilacak.Contains($kisa)){ $hedef.Add($tam) }
}
Write-Host ("Acilacak (kasada bulunan): {0}" -f $hedef.Count)
if($hedef.Count -eq 0){ Rapor ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='ESLESME YOK'; hakem_temiz=$acilacak.Count; kasa_bekleyen=$kasaIdler.Count }); exit 1 }

# ============================================================================
#  MUKERRER FILTRESI (03.08.2026 — A7 kurali, 500-okumasi dersi)
#  Onarim taramasi ayni kural parmak izini (kaynak + rakamsiz dogru-sik ozu)
#  tasiyan 852 grup buldu (en kabarigi 186 uyeli — VUK 275 siskinligi).
#  KAPI KURALI: ayni parmak izi grubundan yayina EN FAZLA BIR soru acilir.
#  Hangisinin "en iyi yazilmis" oldugunu insan secer (okundu-onay zaten sart);
#  bu filtre yalniz emniyettir: insan yanlislikla ikisini de onaylasa bile
#  kapi tekini birakir (deterministik: id sirasina gore ilk).
# ============================================================================
$izDosya = 'veri/onarim-tarama.json'
$mukBekletilen = 0
if(Test-Path $izDosya){
  try {
    $ot = Get-Content $izDosya -Raw -Encoding UTF8 | ConvertFrom-Json
    $grupNo = @{}   # id -> grup indeksi
    $gi = 0
    foreach($g in @($ot.T1_gruplar)){ foreach($gid in @($g)){ $grupNo["$gid"] = $gi }; $gi++ }
    if($grupNo.Count -gt 0){
      $gorulenGrup = New-Object 'System.Collections.Generic.HashSet[int]'
      $suzulmus = New-Object System.Collections.Generic.List[string]
      foreach($tam in ($hedef | Sort-Object)){
        if($grupNo.ContainsKey($tam)){
          $gno = [int]$grupNo[$tam]
          if($gorulenGrup.Contains($gno)){ $mukBekletilen++; continue }
          [void]$gorulenGrup.Add($gno)
        }
        $suzulmus.Add($tam)
      }
      $hedef = $suzulmus
      Write-Host ("MUKERRER FILTRESI: {0} soru bekletildi (ayni parmak izi grubundan ikinci+), acilacak: {1}" -f $mukBekletilen, $hedef.Count)
    }
  } catch { Write-Host ("onarim-tarama.json okunamadi, mukerrer filtresi ATLANDI: {0}" -f $_.Exception.Message) }
} else {
  Write-Host "UYARI: veri/onarim-tarama.json yok - mukerrer filtresi calismadi."
}

$acilan = 0; $hata = 0
for($i = 0; $i -lt $hedef.Count; $i += 100){
  $parti = $hedef[$i..([math]::Min($i+99, $hedef.Count-1))]
  $inListe = ($parti -join ',')
  try {
    Invoke-RestMethod -Method Patch -Uri "${U}?id=in.($inListe)" `
      -Headers ($SB + @{ Prefer = "return=minimal" }) -ContentType "application/json" `
      -Body '{"yayin":true}' -TimeoutSec 120 | Out-Null
    $acilan += $parti.Count
    if(($i % 1000) -eq 0){ Write-Host ("  ... {0}/{1} acildi" -f $acilan, $hedef.Count) }
  } catch {
    $hata += $parti.Count
    Write-Host "PARTI HATASI: $($_.Exception.Message)"
    if($_.ErrorDetails -and $_.ErrorDetails.Message){ Write-Host "  sunucu: $($_.ErrorDetails.Message)" }
  }
}

# --- GERI OKUYUP DOGRULA (yesil kosu != tam veri)
$wd = Invoke-WebRequest -Uri "${U}?select=id&yayin=eq.true&limit=1" -Headers ($SB + @{ Prefer = "count=exact" }) -UseBasicParsing -Method Head -TimeoutSec 60
$yayindaki = ($wd.Headers['Content-Range'] -split '/')[-1]

Rapor ([ordered]@{
  tarih = (Get-Date -Format 'dd.MM.yyyy HH:mm')
  durum = $(if($hata -gt 0){ 'KISMI' } else { 'TAMAM' })
  gerekce = "Cem onayi 02.08: hakemden 3/3 gecen (destek=evet + tek_dogru=evet + celiski=hayir + alinti dogrulanmis) sorular yayina acildi."
  hakem_temiz_kimlik = $acilacak.Count
  kasada_bekleyen = $kasaIdler.Count
  mukerrer_bekletilen = $mukBekletilen
  acilan = $acilan
  hata = $hata
  yayindaki_toplam = $yayindaki
  not = "Kaynagi 'yetersiz' cikanlar ACILMADI - kaynak onarimi (MSUGT/THP) sonrasi yeniden yargilanacak."
})
Write-Host ("ACILAN: {0}   HATA: {1}   KASADA YAYINDA TOPLAM: {2}" -f $acilan, $hata, $yayindaki)
