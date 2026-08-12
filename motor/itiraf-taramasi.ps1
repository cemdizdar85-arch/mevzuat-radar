# ============================================================================
#  KAYNAK ITIRAF TARAMASI - GENIS DESEN                    (12.08.2026, 0 USD)
#
#  NEDEN: 11.08 dar desenle 51 itiraf bulundu; 4365c622'nin "verilmediginden"
#  kelimesi dar desende YOKTU. Genis desen ailesi ile tum kasa taranir,
#  onceden siniflanan idler (kaynak-uyumsuz-SINIF.csv) dusulur.
#
#  ITIRAF = kaynak alaninda modelin "kaynak metin X'i icermiyordu" tarzi
#  kendi kendini ele veren cumlesi. Cogu IHTIYATLI davranistir (dogru),
#  ama KAYNAKSIZ uretimi de ayni cumle ele verir - elle okunup siniflanir.
#
#  Cikti: veri\kaynak-uyumsuz-itiraf-2.csv  (id, ders, itiraf TAM METIN)
# ============================================================================
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.Encoding]::UTF8
$kok = Split-Path $PSScriptRoot -Parent

$anahtar = [Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User')
if(-not $anahtar){ $anahtar = $env:SUPABASE_SERVICE_KEY }
if(-not $anahtar){ Write-Output 'SUPABASE_SERVICE_KEY yok.'; exit 1 }
$ADRES  = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1'
$BASLIK = @{ apikey = $anahtar; Authorization = ('Bearer ' + $anahtar); 'User-Agent' = 'mevzuat-radar-robot/1.0' }

# --- genis itiraf deseni (Turkce harfler \u kacisiyla; BOM tuzagi) ---------
# govdeler: icerme- verilme- bulunma- "yer alma-" duzenle(n)me- kapsama-
#           deginme- "yer verilme-" gecme- rastlanma- olmadig- saglanmad-
# Turkce harfler [char] koduyla kurulur - BOM'suz ps1 ANSI okunur, literal yazilamaz
$Tc = [string][char]0x00E7   # c-sedilla
$Tg = [string][char]0x011F   # g-breve
$Ti = [string][char]0x0131   # noktasiz i
$Tu = [string][char]0x00FC   # u-umlaut
$desen = ('(i' + $Tc + 'erme(d|m)' +
  '|verilme(d|m)' +               # verilmediginden / verilmemis
  '|bulunma(d|m)' +               # bulunmadigindan / bulunmamaktadir
  '|yer\s+alma(d|m)' +            # yer almadigindan
  '|yer\s+verilme(d|m)' +         # yer verilmediginden
  '|d' + $Tu + 'zenle(n)?me(d|m)' +
  '|kapsama(d|m)' +               # kapsamadigindan
  '|de' + $Tg + 'inme(d|m)' +     # deginmediginden
  '|ge' + $Tc + 'me(d|m)' +       # gecmediginden
  '|rastlanma(d|m)' +             # rastlanmadigindan
  '|olmad' + $Ti + $Tg +          # olmadigindan / olmadigi icin
  '|say' + $Ti + 'lmad' +         # sayilmadigindan
  ')')
$rx = [regex]::new($desen)

# --- onceden siniflanan idler ------------------------------------------------
$eskiDosya = Join-Path $kok 'veri\kaynak-uyumsuz-SINIF.csv'
$eski = @()
if(Test-Path $eskiDosya){ $eski = @(Import-Csv $eskiDosya -Encoding UTF8 | ForEach-Object { $_.id }) }
Write-Output ("onceden siniflanan: {0}" -f $eski.Count)

# --- yeniden yazim havuzunu tara ----------------------------------------------
# ITIRAFLAR KASADA DEGIL (12.08 olculdu: kasada yalniz 1). Yeniden yazim
# havuzunun kullanilanKaynak alaninda - kasaya henuz basilmamis metinler.
$havuzDosya = Join-Path $kok 'veri\yeniden-yazim-3540.json'
$json = [IO.File]::ReadAllText($havuzDosya, [Text.Encoding]::UTF8)
$ham2 = ConvertFrom-Json $json
$kayit = @($ham2.kayit | Where-Object { $_.durum -eq 'YAZILDI' })
$toplam = $kayit.Count
$bulgu = New-Object System.Collections.ArrayList
foreach($s in $kayit){
  $k = "$($s.kullanilanKaynak)"
  if($k.Length -lt 20){ continue }
  if($rx.IsMatch($k)){
    [void]$bulgu.Add([pscustomobject]@{ id = $s.id; ders = $s.yeniDers; itiraf = $k })
  }
}

# --- eskileri dus, yaz --------------------------------------------------------
$eskiKume = @{}
foreach($e in $eski){ $eskiKume[$e] = $true }
$yeni = @($bulgu | Where-Object {
  $idTam = "$($_.id)"
  -not ($eskiKume.ContainsKey($idTam) -or $eskiKume.ContainsKey($idTam.Substring(0,8)))
})
Write-Output ""
Write-Output ("taranan soru      : {0}" -f $toplam)
Write-Output ("itiraf TOPLAM     : {0}" -f $bulgu.Count)
Write-Output ("onceden siniflanan: {0}" -f ($bulgu.Count - $yeni.Count))
Write-Output ("YENI (okunacak)   : {0}" -f $yeni.Count)

$cikti = Join-Path $kok 'veri\kaynak-uyumsuz-itiraf-2.csv'
$yeni | Export-Csv $cikti -NoTypeInformation -Encoding UTF8
Write-Output ""
Write-Output ("cikti: {0}" -f $cikti)
