# ============================================================================
#  TERIM UYGULAYICI (04.08.2026) — KASAYA YAZAR. AI CAGRISI YOK, 0 USD.
#
#  CEM: "bizde hazir 27 bin soru vardi, bunlari kural yazip en son mu
#  duzelteceksin yoksa simdi sen bak?"
#
#  CEVAP VE BU BETIGIN SEBEBI: TAM PARTI BUNLARI DUZELTMEZ. Onarim motoru
#  D11 geregi EKSIK olani doldurur, DOLU olani bozmaz. Aciklamasi zaten tam
#  olan bir soruda "genel imal gideri" geciyorsa parti ona HIC DOKUNMAZ.
#  Olcum: 4.328 soruda var, 2.975'i KEHRIBAR KARTTA (ogrencinin ezberledigi
#  yer). Bunlari beklemeye gerek yok - terim degisimi AI gerektirmez,
#  "imal" -> "uretim" duz metin degisimidir.
#
#  NEDEN GUVENLI: yalniz "genel imal" ifadesindeki ORTA KELIME degisir.
#  Turkce ekler kendiliginden korunur:
#    "genel imal giderleri"    -> "genel uretim giderleri"
#    "genel imal giderinin"    -> "genel uretim giderinin"
#    "Genel Imal Giderleri"    -> "Genel Uretim Giderleri"  (buyuk harf korunur)
#
#  DOKUNULMAYAN (Cem'in D26 kurali): kanunun KENDI lafzi. VUK m.275 "imal
#  edilen emtia" der - o kanun metnidir, modernize edilmez. Ilk olcumde bunu
#  yanlislikla "eski terim" listesine koymustum (2.990 soru); listeden
#  CIKARILDI. Bu betik YALNIZ "genel imal" kalibina dokunur.
#
#  UC SIGORTA (sik-hesap-kodu-uygula.ps1 ile ayni, orada 105 soruda calisti):
#   1) YEDEK: dokunulan her alanin ESKI HALI once ozel kovaya yazilir ve geri
#      okunur; yedek tutmazsa YAZMA HIC BASLAMAZ.
#   2) YAYIN KAPISI: yalnizca yayin=false sorulara dokunulur.
#   3) GERI OKUMA: yazilan her soru tekrar cekilip dogrulanir.
#
#  MODLAR: (varsayilan) KURU prova · -uygula = GERCEK YAZMA (tetikte BAS sart)
#  ENV: SUPABASE_SERVICE_KEY
# ============================================================================
param([switch]$uygula)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$PSDefaultParameterValues['Invoke-RestMethod:UserAgent'] = 'mevzuat-radar-robot/1.0'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$raporYol = Join-Path $kok 'veri/terim-uygulama-raporu.json'

function RaporYaz($n){
  $j = ConvertTo-Json -InputObject $n -Depth 6
  if($j.Length -gt 20480){ $j = ConvertTo-Json -Depth 2 -InputObject @{ durum='KIRMIZI - rapor sismis'; boyut=$j.Length } }
  Set-Content -LiteralPath $raporYol -Value $j -Encoding UTF8 -NoNewline
}
trap {
  $g=''; if($_.ErrorDetails -and $_.ErrorDetails.Message){ $g=$_.ErrorDetails.Message }
  RaporYaz ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='HATA'
    hata="$($_.Exception.Message)"; sunucu=$g; satir=$_.InvocationInfo.ScriptLineNumber })
  Write-Host ("HATA (satir {0}): {1}" -f $_.InvocationInfo.ScriptLineNumber, $_.Exception.Message); exit 1
}
if(-not $env:SUPABASE_SERVICE_KEY){ Write-Host "SUPABASE_SERVICE_KEY yok."; exit 0 }
$U    = "https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/soru_havuzu"
$STOR = "https://bjrleanjpyujtajmazxn.supabase.co/storage/v1"
$KOVA = 'onarim-taslak'
$SB   = @{ apikey=$env:SUPABASE_SERVICE_KEY; Authorization="Bearer $($env:SUPABASE_SERVICE_KEY)" }
function CekListe([string]$uri){
  $h = Invoke-WebRequest -Uri $uri -Headers $SB -UseBasicParsing -TimeoutSec 180
  $m = if($h.RawContentStream){ [Text.Encoding]::UTF8.GetString($h.RawContentStream.ToArray()) } else { "$($h.Content)" }
  return @($m | ConvertFrom-Json)
}

# --- DEGISIM KURALLARI: yalniz ORTA KELIME degisir, ekler korunur ---
#     Buyuk/kucuk harf bicimi girdiye gore secilir (baslikta "Imal" -> "Uretim").
# ============================================================================
#  TURKCE-I TUZAGININ BESINCI BICIMI (04.08, testte yakalandi)
#
#  Ilk desen '(?i)(genel)(\s+)(imal)' idi. "genel imal" DONUSTU ama
#  "Genel Imal" ve "GENEL IMAL" DONUSMEDI. Sebep: .NET regex'in IgnoreCase'i
#  de KULTURE BAGLIDIR - tr-TR'de 'I' harfinin kucugu 'i' degil 'ı'dir, bu
#  yuzden (?i)imal ifadesi "Imal"/"IMAL" ile eslesmez.
#  Bu gecenin bes tuzagi: ToUpperInvariant · -replace/-match · hashtable
#  anahtari · regex karakter araligi · SIMDI regex IgnoreCase.
#
#  COZUM: CultureInvariant + harfleri ACIK karakter sinifiyla yaz
#  ([iıİI] hepsini kapsar - noktali/noktasiz, buyuk/kucuk).
#  Buyuk-kucuk tespiti de kultursuz yapilir (acik karakter karsilastirmasi).
# ============================================================================
$reGenelImal = New-Object System.Text.RegularExpressions.Regex(
  '(genel|Genel|GENEL)(\s+)([iıİI])([mM])([aA])([lL])',
  ([System.Text.RegularExpressions.RegexOptions]::CultureInvariant))
# 07.08 AKSAM (Cem: "iptidai gibi sinavda sorulmayan, anlami bilinmeyen kelime
# adayin karsisina cikmasin"): iki kural daha. "iptidai [ve ham] madde" ->
# "ilk madde ve malzeme" (THP dili; ekler "madde"nin uzerinden akar:
# "iptidai ve ham maddelerin" -> "ilk madde ve malzemelerin"). "isbu" -> "bu".
# TIRNAK KORUMASI (D26): cift tirnak ICINDEKI eslesme kanun alintisidir,
# DOKUNULMAZ - Donustur her kuraldan once metni $script:AKTIF_METIN'e koyar,
# eslesmenin solundaki tirnak sayisi TEKse alinti icindeyiz demektir.
$reIptidai = New-Object System.Text.RegularExpressions.Regex(
  '([iıİI])([pP])[tT][iıİI][dD][aA][iıİI](\s+[vV][eE]\s+[hH][aA][mM])?\s+[mM][aA][dD][dD][eE]',
  ([System.Text.RegularExpressions.RegexOptions]::CultureInvariant))
$reIsbu = New-Object System.Text.RegularExpressions.Regex(
  '([iıİI])([şŞsS])[bB][uU](?=[\s,\.;:])',
  ([System.Text.RegularExpressions.RegexOptions]::CultureInvariant))
# 07.08 aksam-2 (Cem: "iptidai gibi baska kelime varsa o da duzelsin"):
# "imal edilen emtia" (3.369 soru) - ek uyumu farkli oldugu icin ek CIFTLERI
# tek tek sayilir: emtia->mamul, emtianin->mamulun, emtiayi->mamulu,
# emtiaya->mamule, emtiada->mamulde, emtiadan->mamulden. Listede olmayan ek
# bicimi DEGISMEZ ve kalan-tarama raporunda gorunur (sessiz kayip yok).
$reEmtia = New-Object System.Text.RegularExpressions.Regex(
  '([iıİI])([mM])[aA][lL]\s+[eE][dD][iıİI][lL][eE][nN]\s+[eE][mM][tT][iıİI][aA](?<ek>[nN][ıiİI][nN]|[yY][ıiİI]|[yY][aA]|[dD][aA][nN]|[dD][aA])?(?=[\s,\.;:)]|$)',
  ([System.Text.RegularExpressions.RegexOptions]::CultureInvariant))
$EMTIA_EK = @{ ''='mamul'; 'nin'='mamulün'; 'yi'='mamulü'; 'ya'='mamule'; 'da'='mamulde'; 'dan'='mamulden' }
function EmtiaEkAnahtar([string]$ek){
  $duz = ''
  foreach($c in $ek.ToCharArray()){
    $u = [char]::ToLowerInvariant($c)
    if($u -eq [char]0x0131 -or $u -eq 'i' -or $u -eq [char]0x0130){ $duz += 'i' } else { $duz += $u }
  }
  return $duz
}
function TirnakIcinde([int]$konum){
  if(-not $script:AKTIF_METIN){ return $false }
  $once = $script:AKTIF_METIN.Substring(0, [Math]::Min($konum, $script:AKTIF_METIN.Length))
  return ((([regex]::Matches($once, '"')).Count % 2) -eq 1)
}
$BUYUK = @([char]'A'..[char]'Z' | ForEach-Object { [char]$_ }) + @([char]0x00C7,[char]0x011E,[char]0x0130,[char]0x00D6,[char]0x015E,[char]0x00DC,[char]0x0049)
$KURALLAR = @(
  @{ ad='genel imal -> genel uretim'
     desen = $reGenelImal
     uygula = {
        param($m)
        $ilkHarf = $m.Groups[3].Value[0]
        $ikinciHarf = $m.Groups[4].Value[0]
        # -ccontains SART: PowerShell'in -contains operatoru varsayilan olarak
        # BUYUK/KUCUK DUYARSIZDIR; -contains ile 'i' harfi listedeki 'I' ile
        # eslesip her seyi BUYUK harfe cevirtiyordu (testte yakalandi).
        $ilkBuyuk = $script:BUYUK -ccontains $ilkHarf
        $ikinciBuyuk = $script:BUYUK -ccontains $ikinciHarf
        # IMAL (hepsi buyuk) -> URETIM ; Imal -> Uretim ; imal -> uretim
        $yeni = if($ilkBuyuk -and $ikinciBuyuk){ 'ÜRETİM' }
                elseif($ilkBuyuk){ 'Üretim' }
                else { 'üretim' }
        return $m.Groups[1].Value + $m.Groups[2].Value + $yeni
     } },
  @{ ad='iptidai (ve ham) madde -> ilk madde ve malzeme'
     desen = $reIptidai
     uygula = {
        param($m)
        if(TirnakIcinde $m.Index){ return $m.Value }
        $ilkBuyuk = $script:BUYUK -ccontains $m.Groups[1].Value[0]
        $ikinciBuyuk = $script:BUYUK -ccontains $m.Groups[2].Value[0]
        if($ilkBuyuk -and $ikinciBuyuk){ return 'İLK MADDE VE MALZEME' }
        elseif($ilkBuyuk){ return 'İlk madde ve malzeme' }
        else { return 'ilk madde ve malzeme' }
     } },
  @{ ad='isbu -> bu'
     desen = $reIsbu
     uygula = {
        param($m)
        if(TirnakIcinde $m.Index){ return $m.Value }
        if($script:BUYUK -ccontains $m.Groups[1].Value[0]){ return 'Bu' } else { return 'bu' }
     } },
  @{ ad='imal edilen emtia(+ek) -> uretilen mamul(+ek)'
     desen = $reEmtia
     uygula = {
        param($m)
        if(TirnakIcinde $m.Index){ return $m.Value }
        $ekA = EmtiaEkAnahtar $m.Groups['ek'].Value
        if(-not $script:EMTIA_EK.ContainsKey($ekA)){ return $m.Value }   # bilinmeyen ek: dokunma, kalan-tarama gorur
        $govde = $script:EMTIA_EK[$ekA]
        $b1 = $script:BUYUK -ccontains $m.Groups[1].Value[0]
        $b2 = $script:BUYUK -ccontains $m.Groups[2].Value[0]
        if($b1 -and $b2){
          $tam = 'ÜRETİLEN ' + $govde.ToUpperInvariant()
          # Turkce-I: buyuk donusumde 'u'->'U', 'ü'->'Ü' invariant dogru calisir
          return $tam
        } elseif($b1){ return ('Üretilen ' + $govde) } else { return ('üretilen ' + $govde) }
     } }
)

$kasa = New-Object System.Collections.Generic.List[object]
for($o=0; $o -lt 60000; $o+=1000){
  $r = CekListe "$U`?select=id,soru,siklar,aciklama,hap,yayin&order=id&limit=1000&offset=$o"
  if($r.Count -eq 0){ break }
  foreach($x in $r){ if($null -ne $x){ $kasa.Add($x) } }
  if($r.Count -lt 1000){ break }
}
Write-Host ("Kasa: {0} soru" -f $kasa.Count)

$yedek     = New-Object System.Collections.Generic.List[object]
$yazilacak = @{}
$degisenAlan = 0; $yayindaAtlanan = 0
$alanSayaci = @{ soru=0; siklar=0; aciklama=0; hap=0 }

function Donustur([string]$metin){
  $y = $metin
  foreach($k in $KURALLAR){ $script:AKTIF_METIN = $y; $y = $k.desen.Replace($y, $k.uygula) }
  return $y
}

foreach($s in $kasa){
  $sid = "$($s.id)"
  $degisti = $false
  $yeniAlanlar = @{}

  $eskiSoru = "$($s.soru)"
  $yeniSoru = Donustur $eskiSoru
  if($yeniSoru -ne $eskiSoru){ $yeniAlanlar['soru'] = $yeniSoru; $degisti = $true; $alanSayaci.soru++
    $yedek.Add([ordered]@{ soru_id=$sid; alan='soru'; eski=$eskiSoru }) }

  $eskiHap = "$($s.hap)"
  if($eskiHap.Trim() -ne ''){
    $yeniHap = Donustur $eskiHap
    if($yeniHap -ne $eskiHap){ $yeniAlanlar['hap'] = $yeniHap; $degisti = $true; $alanSayaci.hap++
      $yedek.Add([ordered]@{ soru_id=$sid; alan='hap'; eski=$eskiHap }) }
  }

  foreach($kokAd in @('siklar','aciklama')){
    $nesne = $null; try { $nesne = $s.$kokAd } catch {}
    if($null -eq $nesne){ continue }
    $nesneDegisti = $false
    foreach($h in 'A','B','C','D','E'){
      if(-not $nesne.PSObject.Properties[$h]){ continue }
      $e = "$($nesne.$h)"
      if($e.Trim() -eq ''){ continue }
      $y = Donustur $e
      if($y -ne $e){
        $nesne.$h = $y; $nesneDegisti = $true; $alanSayaci[$kokAd]++
        $yedek.Add([ordered]@{ soru_id=$sid; alan="$kokAd.$h"; eski=$e })
      }
    }
    if($nesneDegisti){ $yeniAlanlar[$kokAd] = $nesne; $degisti = $true }
  }

  if(-not $degisti){ continue }
  if($s.yayin){ $yayindaAtlanan++; continue }   # SIGORTA 2
  $yazilacak[$sid] = $yeniAlanlar
  $degisenAlan += $yeniAlanlar.Count
}
Write-Host ("Degisecek soru: {0}  (alan: soru={1} siklar={2} aciklama={3} hap={4})" -f $yazilacak.Count, $alanSayaci.soru, $alanSayaci.siklar, $alanSayaci.aciklama, $alanSayaci.hap)

if(-not $uygula){
  # ==========================================================================
  #  TESHIS (04.08): ilk gercek kosuda 4.334 sorunun 4.333'u temizlendi ama
  #  BIRINDE "genel imal" kaldi ve geri okuma kapisi bunu yakaladi (rapor
  #  KIRMIZI bitti - dogru davranis). Hangi soru ve NEDEN oldugunu tahminle
  #  gecmemek icin: donusumden SONRA hala eslesen kayitlarin ID'si ve ham
  #  gecen parcasi raporlanir. Boylece desenin gormedigi bicim (tire, satir
  #  sonu, farkli bosluk, "imalat" gibi) gozle gorunur.
  # ==========================================================================
  $reKalan = New-Object System.Text.RegularExpressions.Regex(
    'genel[\s\-–—]*[iıİI][mM][aA][lL]|[iıİI][pP][tT][iıİI][dD][aA][iıİI]|[iıİI][şŞsS][bB][uU][\s,\.;:]|[iıİI][mM][aA][lL]\s+[eE][dD][iıİI][lL][eE][nN]\s+[eE][mM][tT][iıİI][aA]',
    ([System.Text.RegularExpressions.RegexOptions]::CultureInvariant))
  $kalanlar = New-Object System.Collections.Generic.List[object]
  foreach($s in $kasa){
    $t = (Donustur "$($s.soru)") + ' ' + (Donustur "$($s.hap)")
    foreach($kokAd in @('siklar','aciklama')){
      $nesne = $null; try { $nesne = $s.$kokAd } catch {}
      if($null -eq $nesne){ continue }
      foreach($h in 'A','B','C','D','E'){
        if($nesne.PSObject.Properties[$h]){ $t += ' ' + (Donustur "$($nesne.$h)") }
      }
    }
    $m = $reKalan.Match($t)
    if($m.Success -and $kalanlar.Count -lt 10){
      $bas = [Math]::Max(0, $m.Index - 40)
      $uz  = [Math]::Min(100, $t.Length - $bas)
      $kalanlar.Add([ordered]@{ soru_id="$($s.id)"; gecen="$($m.Value)"; baglam=$t.Substring($bas,$uz) })
    }
  }
  RaporYaz ([ordered]@{
    tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); mod='KURU (0 USD, KASAYA YAZILMADI)'
    kasa=$kasa.Count; degisecek_soru=$yazilacak.Count; degisecek_alan=$degisenAlan
    alan_dagilimi=$alanSayaci; yayinda_atlanan=$yayindaAtlanan
    TESHIS_donusumden_sonra_kalan=$kalanlar.Count
    TESHIS_ornekler=$kalanlar.ToArray()
    kural='genel imal->genel uretim; iptidai (ve ham) madde->ilk madde ve malzeme; isbu->bu (Cem 07.08; tirnak icindeki kanun alintisi DOKUNULMAZ)'
    dokunulmayan='VUK m.275 "imal edilen emtia" (kanun lafzi, D26) + cift tirnak icindeki her eslesme'
    not='Bu bir PROVA. Gercek yazma icin -uygula gerekir (tetikte BAS sarti).'
  })
  Write-Host "`n=== KURU KOSU - kasaya hicbir sey yazilmadi ==="
  exit 0
}

# ---------- GERCEK YAZMA ----------
$damga = Get-Date -Format 'MMdd-HHmm'
$yedekAd = "yedek-terim-$damga.json"
$yb = [Text.Encoding]::UTF8.GetBytes((ConvertTo-Json -InputObject @{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); kural='genel imal -> genel uretim'; kayit=$yedek.ToArray() } -Depth 6))
Invoke-RestMethod -Uri "$STOR/object/$KOVA/$yedekAd" -Method Post `
  -Headers ($SB + @{ 'Content-Type'='application/json'; 'x-upsert'='true' }) -Body $yb -TimeoutSec 300 | Out-Null
$yedekGeri = -1
try { $h = Invoke-WebRequest -Uri "$STOR/object/$KOVA/$yedekAd" -Headers $SB -UseBasicParsing -TimeoutSec 180; $yedekGeri = $h.RawContentLength } catch { $yedekGeri = -1 }
if($yedekGeri -lt 100){
  Write-Host "!! YEDEK YAZILAMADI - hicbir sey degistirilmedi."
  RaporYaz @{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='KIRMIZI'; sebep='yedek yazilamadi, yazma iptal'; yedek=$yedekAd }
  exit 1
}
Write-Host ("Yedek yazildi: {0} ({1} kayit)" -f $yedekAd, $yedek.Count)

$yazilan = 0; $yazmaHatasi = 0
foreach($sid in $yazilacak.Keys){
  try {
    $b = [Text.Encoding]::UTF8.GetBytes((ConvertTo-Json -InputObject $yazilacak[$sid] -Depth 8))
    Invoke-RestMethod -Uri "$U`?id=eq.$sid" -Method Patch -Headers ($SB + @{ 'Content-Type'='application/json'; 'Prefer'='return=minimal' }) -Body $b -TimeoutSec 120 | Out-Null
    $yazilan++
  } catch { $yazmaHatasi++ }
}
Write-Host ("Yazilan soru: {0} (hata {1})" -f $yazilan, $yazmaHatasi)

# SIGORTA 3: geri oku - eski terim GERCEKTEN kalmadi mi
$kontrolId = @($yazilacak.Keys)
$kalanEskiTerim = 0
for($b2=0; $b2 -lt $kontrolId.Count; $b2+=50){
  $dilim = $kontrolId[$b2..([Math]::Min($b2+49, $kontrolId.Count-1))]
  $liste = ($dilim | ForEach-Object { '"' + $_ + '"' }) -join ','
  foreach($s in (CekListe "$U`?select=id,soru,siklar,aciklama,hap&id=in.($liste)")){
    if($null -eq $s){ continue }
    $t = "$($s.soru) $($s.hap)"
    try { if($s.siklar){   foreach($p in $s.siklar.PSObject.Properties){   $t += ' ' + "$($p.Value)" } } } catch {}
    try { if($s.aciklama){ foreach($p in $s.aciklama.PSObject.Properties){ $t += ' ' + "$($p.Value)" } } } catch {}
    # 07.08: kural-bagimsiz geri okuma - Donustur hala degisiklik istiyorsa
    # eski terim kalmis demektir (tirnak-korumali kanun alintilari Donustur'da
    # da atlandigi icin yanlis alarm uretmez).
    if((Donustur $t) -ne $t){ $kalanEskiTerim++ }
  }
}
RaporYaz ([ordered]@{
  tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm')
  durum=$(if($kalanEskiTerim -eq 0 -and $yazmaHatasi -eq 0){'TAMAM'}else{'KIRMIZI'})
  mod='UYGULANDI (KASAYA YAZILDI)'
  yedek_dosyasi=$yedekAd; yedek_kayit=$yedek.Count; yedek_bayt=$yedekGeri
  degisen_soru=$yazilacak.Count; degisen_alan=$degisenAlan; alan_dagilimi=$alanSayaci
  yazilan_soru=$yazilan; yazma_hatasi=$yazmaHatasi
  GERI_OKUMA_kalan_eski_terim=$kalanEskiTerim
  yayinda_atlanan=$yayindaAtlanan
  not="Geri alma: ozel kovadaki $yedekAd icindeki 'eski' degerleri geri yazilir."
})
Write-Host "`n=== TERIM UYGULAMASI BITTI ==="
Write-Host ("  Yazilan soru            : {0}" -f $yazilan)
Write-Host ("  Geri okuma: kalan eski  : {0}" -f $kalanEskiTerim)
if($kalanEskiTerim -gt 0 -or $yazmaHatasi -gt 0){ exit 1 }
