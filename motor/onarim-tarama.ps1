# ============================================================================
#  ONARIM TARAMASI — 500'luk el okumasinin makinelesen dersleri (03.08.2026)
#
#  NEDEN: GM 500 soruyu elle okudu; cikan kusurlarin bir kismi MAKINEYLE
#  yakalanabilir turden. Bu robot o desenleri KASANIN TAMAMINDA sayar ki
#  onarim partisi (tek parali koasu) hedefli ve olculu gitsin.
#  TARAMA BEDAVA — yalniz Supabase okumasi, model cagrisi yok.
#
#  KONTROLLER (500-okumasindaki karsiligi):
#   T1 mukerrer_parmak_izi : ayni kaynak + ayni RAKAMSIZ dogru-sik ozu
#                            (A7 kurali; 322=352, 318=349=385, sut izni x6...)
#   T2 etiket_ders_uyumsuz : kaynak ailesi o derse ait degil
#                            (3568 -> Finansal Muhasebe; 6183/4054 -> FTA...)
#   T3 konu_kaynak_ilgisiz : konu adinin hicbir anlamli kelimesi soru+kaynakta
#                            gecmiyor ("ifac yonetim merkezi" -> 5018 sorusu)
#   T5 ascii_metin         : uzun soru metninde HIC Turkce karakter yok
#                            (311/325/495 — farkli uretim kanali izi)
#   T6 istem_artigi        : "175 karakter." / "JSON dondur" gibi uretim
#                            talimati kalintisi (B16)
#   T7 mulga_rejim         : olu rejim anahtar kelimeleri (goturu usul...) (B17)
#   T8 homoglif            : Kiril/Yunan karakter sizintisi (B9; "amortisман")
#
#  Cikti: veri/onarim-tarama.json — SAYILAR + soru ID'leri (UUID) + T1 için
#  id gruplari. Soru METNI ASLA yazilmaz (depo public; parali icerik sizmaz).
#  ENV: SUPABASE_SERVICE_KEY (zorunlu).
# ============================================================================
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$SB_URL = "https://bjrleanjpyujtajmazxn.supabase.co"
$cikti = Join-Path $kok "veri/onarim-tarama.json"

function Yaz($n){ [IO.File]::WriteAllText($cikti, (ConvertTo-Json -InputObject $n -Depth 6), (New-Object Text.UTF8Encoding($false))) }
trap {
  Yaz ([ordered]@{ tarih=(Get-Date -Format "dd.MM.yyyy HH:mm"); durum="HATA"
    hata="$($_.Exception.Message)"; satir=$_.InvocationInfo.ScriptLineNumber })
  Write-Host ("HATA (satir {0}): {1}" -f $_.InvocationInfo.ScriptLineNumber, $_.Exception.Message)
  exit 1
}

$KEY = "$env:SUPABASE_SERVICE_KEY"
if([string]::IsNullOrWhiteSpace($KEY)){
  Yaz ([ordered]@{ tarih=(Get-Date -Format "dd.MM.yyyy HH:mm"); durum="ATLANDI"; not="SUPABASE_SERVICE_KEY yok" })
  Write-Host "SUPABASE_SERVICE_KEY yok - atlandi."; exit 0
}
$BASLIK = @{ apikey = $KEY; Authorization = "Bearer $KEY" }   # $H kullanma (kalite-tarama dersi)

function Fold([string]$s){ if($null -eq $s){ return '' }
  $s = $s.ToLowerInvariant()
  return ($s -replace 'ı','i' -replace 'ş','s' -replace 'ğ','g' -replace 'ü','u' -replace 'ö','o' -replace 'ç','c' -replace 'İ','i') }
function Sade([string]$s){
  $s = Fold $s
  $s = $s -replace '\d+',' ' -replace '[^\w\s]',' ' -replace '\s+',' '
  return $s.Trim() }

# --- kaynak ailesi (denetim-500 Aile + 500-okumasinda cikan eksik aileler)
function Aile([string]$k){
  $t = "$k".ToUpperInvariant()
  if($t -match '3568')                  { return 'MESLEK' }   # SMMM/YMM meslek mevzuati
  if($t -match '4054|REKABET')          { return 'REKABET' }
  if($t -match '6183|AATUHK')           { return 'TAKIP' }    # amme alacaklari
  if($t -match '5018')                  { return 'KAMU' }     # kamu mali yonetimi (kamu muhasebesi)
  if($t -match '6356|SENDIKA')          { return 'IS' }
  if($t -match 'VUK|213|KDV|3065|GVK|193|KVK|5520|ÖTV|OTV|4760'){ return 'VERGI' }
  if($t -match 'TTK|6102')              { return 'TICARET' }
  if($t -match 'TBK|6098|BORCLAR')      { return 'BORCLAR' }
  if($t -match 'İŞ K|IS K|4857|SGK|5510|SOSYAL'){ return 'IS' }
  if($t -match 'TMS|TFRS|BOBI|KUMI|MSUGT|TEKDUZEN'){ return 'STANDART' }
  if($t -match 'BDS|KGK|KYS|GDS|SBDS')  { return 'DENETIM' }
  if($t -match 'İİK|IIK|2004')          { return 'ICRA' }
  if($t -match 'SMK|6769')              { return 'MARKA' }
  if($t -match 'SPK|6362')              { return 'SERMAYE' }
  return 'DIGER'
}
# --- derse izin verilen aileler. Kural: listede olmayan aile o derste KAYMA.
#     KAMU muhasebe derslerinde MESRU (devlet muhasebesi mufredatta var).
function DersAile([string]$d){
  $t = Fold $d
  if($t -match 'meslek')                                { return @('MESLEK') }
  if($t -match 'vergi')                                 { return @('VERGI','TAKIP') }
  # 1. tur ince ayari (03.08): TICARET muhasebe/mali-tablo derslerinde MESRUDUR
  # (TTK ticari defter, sirket, birlesme hukumleri mufredatta) - ilk kosuda
  # 2.251 yanlis alarm vermisti. MESLEK (3568) ise gercek kaymadir, kalir.
  # 2. tur ince ayari: 'denetim' kontrolu MUHASEBEDEN ONCE gelmeli - "Muhasebe
  # Denetimi" dersi 'muhasebe' desenine takilip BDS sorularini kayma sayiyordu.
  if($t -match 'denetim')                               { return @('DENETIM','STANDART') }
  if($t -match 'maliyet|finansal muhasebe|genel muhasebe|muhasebe'){ return @('VERGI','STANDART','KAMU','TICARET') }
  if($t -match 'mali tablo|finansal tablo|analiz')      { return @('STANDART','VERGI','KAMU','TICARET') }
  if($t -match 'ticaret hukuku|sirketler')              { return @('TICARET','SERMAYE') }
  if($t -match 'borclar')                               { return @('BORCLAR','TICARET') }
  if($t -match 'is ve sosyal|sosyal g')                 { return @('IS') }
  if($t -match 'hukuk')                                 { return @('TICARET','BORCLAR','IS','ICRA','MARKA','SERMAYE','TAKIP') }
  if($t -match 'standart|tms|tfrs|raporlama')           { return @('STANDART') }
  if($t -match 'ekonomi|maliye')                        { return @('REKABET','KAMU','DIGER') }
  return @()
}
# T3 konu kelimeleri icin gurultu listesi (tek basina anlam tasimayanlar)
$DUR = @('genel','temel','ozel','sureleri','suresi','turleri','islemleri','hukuku','kanunu','testi','testleri','kavrami','tanimlar','tanimi','hesaplama','hesaplari','sistemi','bilgi')

# ------------------------------------------------------------- kasayi cek
$hepsi = 0
$T1grup   = @{}   # parmakizi -> List[id]
$T2liste  = New-Object System.Collections.Generic.List[string]
$T3liste  = New-Object System.Collections.Generic.List[string]
$T5liste  = New-Object System.Collections.Generic.List[string]
$T6liste  = New-Object System.Collections.Generic.List[string]
$T7liste  = New-Object System.Collections.Generic.List[string]
$T8liste  = New-Object System.Collections.Generic.List[string]
$T2dagilim = @{}  # "ders -> aile" kac kez

$reIstem   = [regex]'(?i)\d+\s*karakter\s*(\.|olacak|ile sinirli)|sadece\s+json|json\s+dondur|gecerli\s+json'
$reHomog   = [regex]'[Ѐ-ӿͰ-Ͽ]'
$reTurkce  = [regex]'[çğıöşüÇĞİÖŞÜ]'
$reMulga   = [regex]'(?i)g[oö]t[uü]r[uü]\s+usul'

$offset = 0; $sayfa = 1000
while($true){
  $u = "$SB_URL/rest/v1/soru_havuzu?select=id,ders,konu,soru,siklar,dogru,aciklama,kaynak,hap&order=id&limit=$sayfa&offset=$offset"
  $hw = Invoke-WebRequest -UseBasicParsing -Uri $u -Headers $BASLIK -TimeoutSec 180
  $gv = if($hw.Content -is [byte[]]){ [Text.Encoding]::UTF8.GetString($hw.Content) } else { "$($hw.Content)" }
  $parti = @(); foreach($x in (ConvertFrom-Json $gv)){ $parti += $x }
  if(-not $parti.Count){ break }
  foreach($s in $parti){
    $hepsi++
    $id = "$($s.id)"
    $soruM = "$($s.soru)"
    $kaynakM = "$($s.kaynak)"

    # butun sik + aciklama metni (T6/T7/T8 icin)
    $tum = $soruM + ' ' + "$($s.hap)"
    if($s.siklar){   foreach($p in $s.siklar.PSObject.Properties){   $tum += ' ' + "$($p.Value)" } }
    if($s.aciklama){ foreach($p in $s.aciklama.PSObject.Properties){ $tum += ' ' + "$($p.Value)" } }

    # T1 parmak izi
    $kk = ($kaynakM -split ' - ')[0].Trim()
    $harf = "$($s.dogru)".Trim().ToUpperInvariant()
    $dm = if($harf.Length -gt 0 -and $s.siklar){ "$($s.siklar.$harf)" } else { '' }
    $sd = Sade $dm
    if($sd.Length -gt 80){ $sd = $sd.Substring(0,80) }
    if($kk.Length -gt 2 -and $sd.Length -gt 15){
      $iz = "$kk|$sd"
      if(-not $T1grup.ContainsKey($iz)){ $T1grup[$iz] = New-Object System.Collections.Generic.List[string] }
      $T1grup[$iz].Add($id)
    }

    # T2 etiket-ders
    $izinli = DersAile "$($s.ders)"
    if($izinli.Count -gt 0){
      $a = Aile $kaynakM
      if($a -ne 'DIGER' -and $izinli -notcontains $a){
        $T2liste.Add($id)
        $anah = ("{0} -> {1}" -f "$($s.ders)", $a)
        $T2dagilim[$anah] = 1 + [int]$T2dagilim[$anah]
      }
    }

    # T3 konu-kaynak ilgisizligi. 1. tur ince ayari (03.08): hedef metne
    # ACIKLAMALAR da katildi - konu kelimesi cogu zaman gerekcede gecer;
    # yalniz soru metnine bakmak 7.389 supheli uretmisti (asiri gurultu).
    $konuKel = @((Sade "$($s.konu)") -split ' ' | Where-Object { $_.Length -ge 5 -and $DUR -notcontains $_ })
    if($konuKel.Count -ge 2){
      $hedef = Sade ($tum + ' ' + $kaynakM)
      $vurdu = $false
      foreach($w in $konuKel){ if($hedef.Contains($w)){ $vurdu = $true; break } }
      if(-not $vurdu){ $T3liste.Add($id) }
    }

    # T5 ascii metin
    if($soruM.Length -gt 150 -and -not $reTurkce.IsMatch($soruM)){ $T5liste.Add($id) }

    # T6 istem artigi
    if($reIstem.IsMatch($tum)){ $T6liste.Add($id) }

    # T7 mulga rejim
    if($reMulga.IsMatch($tum)){ $T7liste.Add($id) }

    # T8 homoglif
    if($reHomog.IsMatch($tum)){ $T8liste.Add($id) }
  }
  if($parti.Count -lt $sayfa){ break }
  $offset += $sayfa
  Write-Host ("  ...{0}" -f $hepsi)
}

# T1: yalniz coklu gruplar
$mukGrup = @()
$mukSoru = 0
foreach($k in $T1grup.Keys){
  $g = $T1grup[$k]
  if($g.Count -gt 1){ $mukGrup += ,@($g.ToArray()); $mukSoru += $g.Count }
}
# buyukten kucuge sirala (en kabarik aile en uste)
$mukGrup = @($mukGrup | Sort-Object { -$_.Count })

$sonuc = [ordered]@{
  tarih   = (Get-Date -Format "dd.MM.yyyy HH:mm")
  durum   = "TAMAM"
  taranan = $hepsi
  ozet    = [ordered]@{
    T1_mukerrer_grup  = $mukGrup.Count
    T1_mukerrer_soru  = $mukSoru
    T2_etiket_ders    = $T2liste.Count
    T3_konu_ilgisiz   = $T3liste.Count
    T5_ascii_metin    = $T5liste.Count
    T6_istem_artigi   = $T6liste.Count
    T7_mulga_rejim    = $T7liste.Count
    T8_homoglif       = $T8liste.Count
  }
  T2_dagilim = $T2dagilim
  T1_gruplar = $mukGrup
  T2_idler   = $T2liste
  T3_idler   = $T3liste
  T5_idler   = $T5liste
  T6_idler   = $T6liste
  T7_idler   = $T7liste
  T8_idler   = $T8liste
}
Yaz $sonuc
Write-Host ""
Write-Host "======== ONARIM TARAMASI ========"
Write-Host ("Taranan: {0}" -f $hepsi)
foreach($k in $sonuc.ozet.Keys){ Write-Host ("  {0,-20} {1}" -f $k, $sonuc.ozet[$k]) }
Write-Host "Rapor: veri/onarim-tarama.json"
