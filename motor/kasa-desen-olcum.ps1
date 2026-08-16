# ============================================================================
#  KASA DESEN OLCUMU — 02.08.2026  (0 USD, yalniz Supabase okumasi)
#
#  NEDEN: 40 aday sorunun elle okunmasinda uc sey cikti:
#    (1) 40 sorunun 23'u YALNIZ 4 maddeden yazilmis (VUK 275: 12, Is K. 11: 4,
#        TTK 720: 4, TTK 516: 3). Yani soru cesitli gorunuyor ama kural ayni.
#    (2) Ayni kural farkli sirket adi/rakamla tekrar yazilmis; 60-karakter
#        mukerrer kapisi bunu goremiyor cunku cumle basi degisiyor.
#    (3) Sorunun ders/konu etiketi ile dayandigi kaynak tutmuyor (36. soru:
#        konu "kismi ve tam BOLUNME turleri" -> kaynak "KISMI sureli calisma";
#        eslestirici kelimeye takilmis).
#  Bu betik ayni uc olcumu 40 soruda degil KASANIN TAMAMINDA yapar.
#
#  OLCTUKLERI:
#   A) Kaynak yigilmasi: hangi madde kac soru yazmis, ilk 10 madde kasanin
#      yuzde kacini tutuyor.
#   B) Kural doygunlugu: bir maddeden yazilan sorularin DOGRU SIKKI kac farkli
#      metne dusuyor. 900 soru / 40 farkli dogru sik = ayni kural 22 kez.
#   C) Etiket-kaynak uyumsuzlugu: dersin ait oldugu mevzuat ailesi ile sorunun
#      dayandigi mevzuat ailesi ayni mi. (Kaba ama gercek bir sayim; ornegin
#      ders "Maliyet Muhasebesi" iken kaynak TTK ise isaretlenir.)
#
#  PARA HARCAMAZ. ENV: SUPABASE_SERVICE_KEY
#  Cikti: veri/kasa-desen-olcum.json  (+ ekrana ozet)
# ============================================================================
param([int]$ornekSayisi = 12)
$ErrorActionPreference = 'Stop'
# Supabase gizli anahtarli istegi KIMLIKSIZ gelirse 401 ile reddeder.
# (16.08.2026 olculdu: ayni sorgu UA'siz 401, UA'li 5 kayit. madde-coz.ps1
#  bu yuzden her kaynaga "ambarda-yok" diyordu.) IRM ve IWR AYRI yazilir.
$PSDefaultParameterValues['Invoke-RestMethod:UserAgent'] = 'mevzuat-radar-robot/1.0'
$PSDefaultParameterValues['Invoke-WebRequest:UserAgent'] = 'mevzuat-radar-robot/1.0'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
if(-not $env:SUPABASE_SERVICE_KEY){ Write-Host "SUPABASE_SERVICE_KEY yok - cikildi."; exit 0 }
$U  = "https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/soru_havuzu"
$SB = @{ apikey = $env:SUPABASE_SERVICE_KEY; Authorization = "Bearer $($env:SUPABASE_SERVICE_KEY)" }
$ciktiYol = Join-Path $kok 'veri/kasa-desen-olcum.json'

# --- kasayi cek
$kasa = New-Object System.Collections.Generic.List[object]
$ofs = 0
while($true){
  $w = Invoke-WebRequest -Uri "${U}?select=id,sinav,ders,konu,soru,siklar,dogru,kaynak,yayin&order=id&limit=1000&offset=$ofs" -Headers $SB -UseBasicParsing -TimeoutSec 180
  $ham = if($w.RawContentStream){ [Text.Encoding]::UTF8.GetString($w.RawContentStream.ToArray()) } else { $w.Content }
  $l = @($ham | ConvertFrom-Json); if($l.Count -eq 0){ break }
  foreach($s in $l){ $kasa.Add($s) }
  if($l.Count -lt 1000){ break }
  $ofs += 1000
}
Write-Host ("Kasa: {0} soru" -f $kasa.Count)
if($kasa.Count -eq 0){ Write-Host "Kasa bos - cikildi."; exit 0 }

# --- yardimci: metni sadelestir (buyuk/kucuk, noktalama, RAKAMLAR atilir).
#     Rakamlar atilir cunku mukerreri gizleyen sey tam olarak degisen tutarlar
#     ve tarihlerdir: "18.750 TL" ile "127.350 TL" ayni kurali sorar.
function Sade([string]$m){
  if([string]::IsNullOrWhiteSpace($m)){ return '' }
  $t = $m.ToLowerInvariant()
  $t = [regex]::Replace($t, '[0-9]+', ' ')
  $t = [regex]::Replace($t, '[^\p{L}\s]', ' ')
  $t = [regex]::Replace($t, '\s+', ' ')
  return $t.Trim()
}
# --- yardimci: kaynagin mevzuat ailesi
function Aile([string]$k){
  $t = "$k".ToUpperInvariant()
  if($t -match 'VUK|213')            { return 'VERGI' }
  if($t -match 'KDV|3065')           { return 'VERGI' }
  if($t -match 'GVK|193|KVK|5520')   { return 'VERGI' }
  if($t -match 'TTK|6102')           { return 'TICARET' }
  if($t -match 'TBK|6098|BORCLAR')   { return 'BORCLAR' }
  if($t -match 'İŞ K|IS K|4857')     { return 'IS' }
  if($t -match 'SGK|5510|SOSYAL')    { return 'IS' }
  if($t -match 'TMS|TFRS|BOBI|KUMI') { return 'STANDART' }
  if($t -match 'BDS|KGK|DENETIM')    { return 'DENETIM' }
  if($t -match 'İİK|IIK|2004')       { return 'ICRA' }
  if($t -match 'SMK|6769')           { return 'MARKA' }
  return 'DIGER'
}
# --- yardimci: dersin beklenen mevzuat ailesi (birden fazla olabilir)
function DersAile([string]$d){
  $t = "$d".ToLowerInvariant()
  if($t -match 'vergi|turk vergi|türk vergi')          { return @('VERGI') }
  if($t -match 'maliyet|finansal muhasebe|genel muhasebe|muhasebe uygulama'){ return @('VERGI','STANDART') }
  if($t -match 'mali tablolar|finansal tablolar|analiz'){ return @('STANDART','VERGI') }
  if($t -match 'denetim')                               { return @('DENETIM','STANDART') }
  if($t -match 'ticaret hukuku|sirketler')              { return @('TICARET') }
  if($t -match 'borclar|borçlar')                       { return @('BORCLAR','TICARET') }
  if($t -match 'is ve sosyal|iş ve sosyal|sosyal guvenlik|sosyal güvenlik'){ return @('IS') }
  if($t -match 'hukuk')                                 { return @('TICARET','BORCLAR','IS','ICRA','MARKA') }
  if($t -match 'standart|tms|tfrs|raporlama')           { return @('STANDART') }
  return @()   # bilinmeyen ders: uyusmazlik sayilmaz (haksiz suclama olmasin)
}

# --- D) SIK DAGILIMI (SINAV-KURALLARI C6: her harf %12-30 arasi olmali).
#     02.08: sozlesmede kural vardi ama OLCEN KOD YOKTU. Dogrularin cogu tek
#     harfte toplanirsa aday soruyu okumadan bilir.
$harfSayim = [ordered]@{ A=0; B=0; C=0; D=0; E=0 }
foreach($s in $kasa){
  $h = "$($s.dogru)".Trim().ToUpperInvariant()
  if($harfSayim.Contains($h)){ $harfSayim[$h] = [int]$harfSayim[$h] + 1 }
}

# --- A) kaynak yigilmasi + B) kural doygunlugu
$kaynakSayim = @{}
$kaynakDogruMetin = @{}      # kaynak -> HashSet(sadelestirilmis dogru sik)
$kaynakOrnek = @{}
# --- C) etiket-kaynak uyumsuzlugu
$uyumsuz = 0; $olculebilir = 0
$uyumsuzOrnek = New-Object System.Collections.Generic.List[object]
$kaynaksiz = 0

foreach($s in $kasa){
  $k = "$($s.kaynak)".Trim()
  if($k.Length -eq 0){ $kaynaksiz++; continue }
  # kaynagi maddeye indirge: aciklama kuyrugunu at ("VUK m.275 - Imal edilen..." -> "VUK m.275")
  $kisa = ($k -split ' - ')[0].Trim()
  if($kisa.Length -gt 60){ $kisa = $kisa.Substring(0,60) }
  $kaynakSayim[$kisa] = 1 + [int]$kaynakSayim[$kisa]

  # dogru sikkin metni
  $harf = "$($s.dogru)".Trim().ToUpperInvariant()
  $dm = ''
  if($harf.Length -gt 0 -and $s.siklar){ $dm = "$($s.siklar.$harf)" }
  $sade = Sade $dm
  if($sade.Length -gt 90){ $sade = $sade.Substring(0,90) }
  if($sade.Length -gt 0){
    if(-not $kaynakDogruMetin.ContainsKey($kisa)){ $kaynakDogruMetin[$kisa] = New-Object 'System.Collections.Generic.HashSet[string]' }
    [void]$kaynakDogruMetin[$kisa].Add($sade)
  }
  if(-not $kaynakOrnek.ContainsKey($kisa)){ $kaynakOrnek[$kisa] = "$($s.ders) / $($s.konu)" }

  # C) etiket uyumu
  $bek = DersAile "$($s.ders)"
  if($bek.Count -gt 0){
    $ger = Aile $kisa
    if($ger -ne 'DIGER'){
      $olculebilir++
      if($bek -notcontains $ger){
        $uyumsuz++
        if($uyumsuzOrnek.Count -lt $ornekSayisi){
          $uyumsuzOrnek.Add([ordered]@{
            id = "$($s.id)"; sinav = "$($s.sinav)"; ders = "$($s.ders)"; konu = "$($s.konu)"
            kaynak = $kisa; beklenen = ($bek -join '|'); gercek = $ger
            soru_bas = $(if("$($s.soru)".Length -gt 120){ "$($s.soru)".Substring(0,120) } else { "$($s.soru)" })
          })
        }
      }
    }
  }
}

# --- siralamalar
$sirali = @($kaynakSayim.GetEnumerator() | Sort-Object Value -Descending)
$ilk10 = 0; $i = 0
foreach($e in $sirali){ if($i -ge 10){ break }; $ilk10 += [int]$e.Value; $i++ }
$kaynakliToplam = $kasa.Count - $kaynaksiz
$ilk10Yuzde = if($kaynakliToplam -gt 0){ [math]::Round(100 * $ilk10 / $kaynakliToplam, 1) } else { 0 }

$ustListe = New-Object System.Collections.Generic.List[object]
$i = 0
foreach($e in $sirali){
  if($i -ge 25){ break }
  $kk = $e.Key
  $farkli = if($kaynakDogruMetin.ContainsKey($kk)){ $kaynakDogruMetin[$kk].Count } else { 0 }
  $tekrar = if($farkli -gt 0){ [math]::Round([int]$e.Value / $farkli, 1) } else { $null }
  $ustListe.Add([ordered]@{
    kaynak = $kk
    soru = [int]$e.Value
    farkli_dogru_sik = $farkli
    ayni_kural_kac_kez = $tekrar      # 1,0 = her soru farkli kural; 20 = ayni kural 20 kez
    ornek_etiket = "$($kaynakOrnek[$kk])"
  })
  $i++
}

$uyumsuzYuzde = if($olculebilir -gt 0){ [math]::Round(100 * $uyumsuz / $olculebilir, 1) } else { 0 }

Write-Host ""
Write-Host ("A) Farkli kaynak (madde) sayisi : {0}" -f $kaynakSayim.Count)
Write-Host ("   Ilk 10 madde kasanin %{0}'ini yaziyor" -f $ilk10Yuzde)
Write-Host ("   Kaynagi bos soru: {0}" -f $kaynaksiz)
Write-Host ""
Write-Host "B) En cok soru yazilan 10 madde (ayni kural kac kez tekrar etmis):"
$i = 0
foreach($u in $ustListe){
  if($i -ge 10){ break }
  Write-Host ("   {0,-34} {1,5} soru | {2,4} farkli dogru sik | tekrar x{3}" -f $u.kaynak, $u.soru, $u.farkli_dogru_sik, $u.ayni_kural_kac_kez)
  $i++
}
Write-Host ""
Write-Host ("C) Etiket-kaynak uyumsuzlugu: {0} / {1} olculebilir soru  (%{2})" -f $uyumsuz, $olculebilir, $uyumsuzYuzde)
$harfYuzde = [ordered]@{}
$c6Ihlal = New-Object System.Collections.Generic.List[string]
foreach($h in @('A','B','C','D','E')){
  $y = if($kasa.Count -gt 0){ [math]::Round(100 * [int]$harfSayim[$h] / $kasa.Count, 1) } else { 0 }
  $harfYuzde[$h] = $y
  if($y -lt 12 -or $y -gt 30){ $c6Ihlal.Add("$h=%$y") }
}
Write-Host ("D) Dogru sik dagilimi (C6 kurali %12-30): A=%{0} B=%{1} C=%{2} D=%{3} E=%{4}  {5}" -f $harfYuzde.A, $harfYuzde.B, $harfYuzde.C, $harfYuzde.D, $harfYuzde.E, $(if($c6Ihlal.Count){ "IHLAL: " + ($c6Ihlal -join ' ') } else { "UYGUN" }))

$paket = [ordered]@{
  tarih = (Get-Date -Format 'dd.MM.yyyy HH:mm')
  kasa = $kasa.Count
  kaynaksiz_soru = $kaynaksiz
  farkli_kaynak = $kaynakSayim.Count
  ilk10_madde_yuzde = $ilk10Yuzde
  en_cok_yazilan = $ustListe.ToArray()
  etiket_uyumsuz = $uyumsuz
  etiket_olculebilir = $olculebilir
  etiket_uyumsuz_yuzde = $uyumsuzYuzde
  etiket_uyumsuz_ornek = $uyumsuzOrnek.ToArray()
  sik_dagilimi_yuzde = $harfYuzde
  c6_ihlal = $c6Ihlal.ToArray()
  not = "0 USD olcum. 'ayni_kural_kac_kez' = o maddeden yazilan soru / farkli dogru sik sayisi; 1'e yakin iyi, buyudukce ayni kural kilik degistirerek tekrar ediyor demektir."
}
$j = ConvertTo-Json -InputObject $paket -Depth 6
if($j -isnot [string]){ $j = ($j -join [Environment]::NewLine) }
Set-Content -LiteralPath $ciktiYol -Value ([string]$j) -Encoding UTF8 -NoNewline
Write-Host ("-> {0}" -f $ciktiYol)
