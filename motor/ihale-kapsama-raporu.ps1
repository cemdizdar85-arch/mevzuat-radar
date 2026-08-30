# ============================================================================
#  IHALE KAPSAMA RAPORU (30.08.2026)
#
#  Cem: "tam indirdigimizi, is kollarini tam indirdigimizi BILELIM."
#
#  Bu betik "tam mi?" sorusunun TEK cevabidir ve cevabi HAFIZADAN degil,
#  kasadan olcerek verir. Uc soru sorar:
#
#    1. KAPSAM   - hangi bulten gunleri kasada, hangileri eksik (ihale_eksik_gun)
#    2. TAMLIK   - inen bultenlerin icindekiler'i ile govdesi tutuyor mu (kutuk.tam)
#    3. DURUSTLUK- kutugun iddiasi ile tabloda duran satir tutuyor mu
#                  (ihale_kutuk_denetim) - kutugun kendisi yalan soyluyor mu
#
#  Her basligin sonucu YESIL / KIRMIZI / KOR olarak yazilir. "Kor" = olculemedi;
#  olculemeyene "temiz" DENMEZ. (kalici-sigorta 3+1 katman kurali)
#
#  KULLANIM:  ./motor/ihale-kapsama-raporu.ps1 [-AyGeri 36]
# ============================================================================
param([int]$AyGeri = 36)
$ErrorActionPreference = 'Continue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$SB_URL  = 'https://bjrleanjpyujtajmazxn.supabase.co'
$anahtar = "$($env:SUPABASE_SERVICE_KEY)".Trim()
if(-not $anahtar){
  Write-Host 'KOR: SUPABASE_SERVICE_KEY yok - kapsam OLCULEMEDI.'
  Write-Host '     Yerelde: anahtar-kur.cmd  |  Actions: Secrets -> SUPABASE_SERVICE_KEY'
  exit 2
}
$bas = @{ apikey=$anahtar; Authorization="Bearer $anahtar"; 'Content-Type'='application/json'
          Accept='application/json'; 'User-Agent'='MevzuatRadar-KapsamaRaporu' }
function Rpc([string]$ad, $govde){
  $j = $govde | ConvertTo-Json -Depth 6 -Compress
  $c = Invoke-RestMethod -Method Post -Uri "$SB_URL/rest/v1/rpc/$ad" `
         -Headers $bas -Body ([Text.Encoding]::UTF8.GetBytes($j)) -TimeoutSec 300
  # dizi tek ogeye sarilabiliyor (20.08 tuzagi) - bir kat duzlestir
  $duz = New-Object Collections.ArrayList
  foreach($z in $c){ if($z -is [Array]){ foreach($y in $z){ [void]$duz.Add($y) } } else { [void]$duz.Add($z) } }
  return @($duz)
}

$kirmizi = 0; $kor = 0

Write-Host "==============================================================="
Write-Host " IHALE KAPSAMA RAPORU"
Write-Host "==============================================================="

# --- 0) AMBAR DURUMU --------------------------------------------------------
try{
  $s = (Rpc 'ihale_sayi' @{})[0]
  if($null -eq $s.PSObject.Properties['damgasiz']){
    Write-Host ''
    Write-Host 'KIRMIZI: bulten kutugu gocu BASILMAMIS.'
    Write-Host '  Kanit  : ihale_sayi() cevabinda "damgasiz" alani yok.'
    Write-Host '  Cozum  : Supabase SQL Editor -> radar-app/sql/2026-08-30-ihale-bulten-kutugu.sql'
    exit 1
  }
  Write-Host ''
  Write-Host ("AMBAR : {0:N0} kayit · {1:N0} tekil IKN · {2:N0} kirim olculen · {3:N0} kisimli" -f `
              [int]$s.kayit, [int]$s.tekil_ikn, [int]$s.olculen, [int]$s.kisimli)
  Write-Host ("        bulten araligi: {0} .. {1}" -f `
              $(if($s.ilk_bulten){$s.ilk_bulten}else{'-'}), $(if($s.son_bulten){$s.son_bulten}else{'-'}))
  if([int]$s.damgasiz -gt 0){
    Write-Host ("        DAMGASIZ: {0:N0} kayit - hangi bultenden geldigi bilinmiyor." -f [int]$s.damgasiz)
    Write-Host "        (goc oncesi yazilanlar; backfill ayni gunleri yuruyunce damgalanir)"
  } else {
    Write-Host "        damgasiz kayit yok - her satir kaynak bultenini biliyor."
  }
}catch{
  Write-Host ("KOR: ambar okunamadi - {0}" -f $_.Exception.Message); exit 2
}

# --- 1) KAPSAM --------------------------------------------------------------
Write-Host ''
Write-Host "--- 1) KAPSAM (son $AyGeri ay) ------------------------------------"
try{
  $bugun = Get-Date
  $eks = Rpc 'ihale_eksik_gun' @{
    p_bas    = $bugun.AddMonths(-$AyGeri).ToString('yyyy-MM-dd')
    p_bit    = $bugun.AddDays(-1).ToString('yyyy-MM-dd')
    p_turler = @('Mal','Yapim','Hizmet','Danismanlik')
  }
  if(-not $eks.Count){
    Write-Host 'YESIL: eksik (gun,is kolu) yok - aralik tam.'
  } else {
    $kirmizi++
    $hic  = @($eks | Where-Object { $_.sebep -eq 'hic cekilmedi' })
    $yari = @($eks | Where-Object { $_.sebep -eq 'eksik indi' })
    Write-Host ("KIRMIZI: {0} (gun,is kolu) eksik" -f $eks.Count)
    Write-Host ("   hic cekilmedi : {0}" -f $hic.Count)
    Write-Host ("   eksik indi    : {0}  (icindekiler ile govde tutmuyor)" -f $yari.Count)
    Write-Host '   is kolu dagilimi:'
    foreach($g in ($eks | Group-Object tur | Sort-Object Count -Descending)){
      Write-Host ("     {0,-12} {1}" -f $g.Name, $g.Count)
    }
    Write-Host ("   en yeni eksik gun: {0}" -f @($eks)[0].gun)
    Write-Host '   Kapatmak icin: ./motor/ihale-sonuc-backfill.ps1 -AyGeri ' -NoNewline; Write-Host $AyGeri
  }
}catch{
  $kor++; Write-Host ("KOR: eksik gun sorgusu dustu - {0}" -f $_.Exception.Message)
}

# --- 2) TAMLIK --------------------------------------------------------------
# ihale_eksik_gun zaten "eksik indi" halini kapsiyor; burada EKSIK IKN'leri
# adiyla gosteriyoruz ki hangi ilanin dustugu bilinsin, "bir yerlerde eksik"
# denip gecilmesin.
Write-Host ''
Write-Host '--- 2) TAMLIK (inen bultenlerin ic tutarliligi) -------------------'
try{
  $u = "$SB_URL/rest/v1/ihale_kutuk?select=gun,tur,beklenen,bulunan,eksik_ikn&tam=is.false&order=gun.desc&limit=25"
  $ek = @(Invoke-RestMethod -Method Get -Uri $u -Headers $bas -TimeoutSec 120)
  if(-not $ek.Count){
    Write-Host 'YESIL: cekilen her bultende icindekiler = govde.'
  } else {
    $kirmizi++
    Write-Host ("KIRMIZI: {0} bulten tam inmemis (ilk 25):" -f $ek.Count)
    foreach($e in ($ek | Select-Object -First 10)){
      $ei = @($e.eksik_ikn)
      Write-Host ("   {0} {1,-12} beklenen {2} / bulunan {3} · dusen: {4}" -f `
                  $e.gun, $e.tur, $e.beklenen, $e.bulunan, $(if($ei.Count){($ei | Select-Object -First 4) -join ', '}else{'-'}))
    }
  }
}catch{
  $kor++; Write-Host ("KOR: kutuk okunamadi - {0}" -f $_.Exception.Message)
}

# --- 3) KUTUK DURUSTLUGU ----------------------------------------------------
# Kutuk "o gun 700 kayit aldim" diyorsa tabloda o bulten tarihinde 700 satir
# DURMALI. Tutmuyorsa kutuk yalan soyluyordur - bu gocun sebebi tam olarak
# yerel kutugun yalan soylemesiydi (4 gun diyordu, 62+ gun vardi).
Write-Host ''
Write-Host '--- 3) KUTUK DURUSTLUGU ------------------------------------------'
try{
  $dn = Rpc 'ihale_kutuk_denetim' @{}
  if(-not $dn.Count){
    Write-Host 'YESIL: kutugun iddiasi ile tabloda duran satir birebir tutuyor.'
  } else {
    $kirmizi++
    Write-Host ("KIRMIZI: {0} (gun,is kolu) satirinda kutuk ile tablo TUTMUYOR:" -f $dn.Count)
    foreach($d in ($dn | Select-Object -First 10)){
      Write-Host ("   {0} {1,-12} kutuk {2} · tabloda {3} · fark {4}" -f $d.gun, $d.tur, $d.kutuk_diyor, $d.tabloda_duran, $d.fark)
    }
  }
}catch{
  $kor++; Write-Host ("KOR: denetim sorgusu dustu - {0}" -f $_.Exception.Message)
}

Write-Host ''
Write-Host "==============================================================="
if($kirmizi -eq 0 -and $kor -eq 0){ Write-Host ' SONUC: YESIL - kapsam tam, tamlik tam, kutuk durust.'; exit 0 }
if($kor -gt 0 -and $kirmizi -eq 0){ Write-Host (' SONUC: KOR - {0} baslik olculemedi.' -f $kor); exit 2 }
Write-Host (' SONUC: KIRMIZI - {0} baslik dustu, {1} baslik olculemedi.' -f $kirmizi, $kor)
exit 1
