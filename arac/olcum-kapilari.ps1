#requires -Version 5.1
<#
================================================================================
  OLCUM KAPILARI — olcum aracinin KENDISINI denetler  (11.09.2026)
  Cem: "olcum araclarina oz-sinav ekle"

  NIYE VAR: 11.09'da DORT kez "olctum" dedim ve DORDUNDE DE kusur VERIDE DEGIL
  OLCUM ARACINDAYDI:
    1) ranked-N yerine first-N  -> kp-80'in kaynagi pakete hic girmedi
    2) @($list)  (List[object]) -> ArgumentException, betik coktu
    3) @(ConvertFrom-Json)      -> dizi TEK ogeye sarildi, 169 konu 57 gorundu,
                                   konu adlari birlesik string oldu
    4) Turkce katlama asimetrisi-> sorgu katlanmis, ambar Turkce harfli;
                                   "is sozlesmesi feshi" YOK sanildi (3 sonuc var)
  Her biri saatler yedi ve bazilari YANLIS KARARA goturuyordu ("288 konu
  kaynaksiz", "%74 kapsama", "86 parti dustu"). Bu dosya o dort tuzagi
  FONKSIYON HALINE getirir; olcum betikleri bunlari cagirir, kendi
  yazmaz.

  KULLANIM (dot-source):
    . (Join-Path $depoKok 'arac\olcum-kapilari.ps1')
    $liste = JsonDizi 'veri\sinav\konu\x.json'      # dizi tuzagina dusmez
    $dizi  = Dizi $birList                          # List[object] guvenli
    $q     = AmbarSorgu 'is sözleşmesi feshi'       # Turkce katlamaz
    Test-OlcumKapilari                              # OZ-SINAV

  ⛔ KURAL: yeni bir olcum tuzagi yasanirsa BURAYA fonksiyon + oz-sinav olarak
     eklenir. "Bir daha dikkat ederim" kural degildir.
================================================================================
#>

# --- 1) JSON DIZI (tuzak 3) ---------------------------------------------------
# PS 5.1'de ConvertFrom-Json bir JSON dizisini boru hattina ENUMERATE ETMEDEN
# yazar. `@(Get-Content x | ConvertFrom-Json)` bu yuzden 1 OGELI dizi verir ve
# foreach o tek ogeyi (=tum dizi) dolasir. Once DEGISKENE alinip sonra @() ile
# sarilirsa dogru calisir.
function JsonDizi([string]$yol){
  if(-not (Test-Path $yol)){ throw "JsonDizi: dosya yok - $yol" }
  $ham = Get-Content $yol -Raw -Encoding UTF8 | ConvertFrom-Json   # ONCE DEGISKENE
  $d = @($ham)
  # Tuzak imzasi: tek oge ve o oge bir koleksiyon -> sarma olmus demektir
  if($d.Count -eq 1 -and ($d[0] -is [System.Collections.IEnumerable]) -and -not ($d[0] -is [string])){
    $d = @($d[0])
  }
  return $d
}

# --- 2) LIST -> DIZI (tuzak 2) ------------------------------------------------
# @($list) -- $list bir List[object] ise -- tr-TR PS 5.1.26100'de
# "Bagimsiz degisken turleri eslesmiyor" (ArgumentException) atar.
# .ToArray() sorunsuz calisir.
function Dizi($x){
  if($null -eq $x){ return @() }
  if($x -is [string]){ return @($x) }
  if($x.GetType().Name -like 'List*'){ return $x.ToArray() }
  return @($x)
}

# --- 3) AMBAR SORGUSU (tuzak 4) ----------------------------------------------
# Ambarda metin TURKCE harflidir. Sorguyu katlarsak (ş->s, ç->c) fts eslesmez.
# Kural: sorgu HAM konu adindan kurulur; eger ad zaten ASCII katlanmissa
# Turkce harf tasiyabilecek ekler KESILIR (prefix araması ':*' bunu kurtarir).
# Ornek: "is sozlesmesi feshi" -> "sozles" prefix'i "sözleşmesi"ni TUTMAZ;
#        bu yuzden Turkce harfin GECEBILECEGI ilk konumdan kesilir -> "s".
#        Cok kisa kalan kelime ATILIR, kalanlarla aranir.
# ⛔ ILK DENEMEM YANLISTI ve oz-sinav yakaladi: "Turkce harfe donusebilecek ilk
#    harften kes" kurali "sozlesmesi"yi 1 harfe indirdi ('o' gercek o'ydu) ve
#    sorgu BOS dondu. Dogru yol: KESMEK degil, HER ASCII HARFI TURKCE ESIYLE
#    BIRLIKTE aramak - ureticinin AmbarCek'te yaptigi gibi (imatch).
$script:TR_ESLER=@{ 'c'='[cç]'; 'g'='[gğ]'; 'i'='[iı]'; 'o'='[oö]'; 's'='[sş]'; 'u'='[uü]'
                    'ç'='[cç]'; 'ğ'='[gğ]'; 'ı'='[iı]'; 'ö'='[oö]'; 'ş'='[sş]'; 'ü'='[uü]' }
function TrDesen([string]$kelime){
  $sb=New-Object System.Text.StringBuilder
  foreach($ch in "$kelime".ToLowerInvariant().ToCharArray()){
    $k="$ch"
    if($script:TR_ESLER.ContainsKey($k)){ [void]$sb.Append($script:TR_ESLER[$k]) }
    elseif($k -match '[a-z0-9]'){ [void]$sb.Append([regex]::Escape($k)) }
  }
  return $sb.ToString()
}
# Ambarda ARANACAK desen: konu adinin en ayirt edici 2 kelimesi, Turkce toleransli
# regex olarak, aralarinda "herhangi bir sey" ile. PostgREST `imatch` ile kullanilir.
function AmbarSorgu([string]$konu,[int]$kelimeSayisi=2){
  $kel = @(("$konu".ToLowerInvariant() -replace '[^a-zçğıöşü0-9 ]',' ' -split '\s+') |
           Where-Object { $_.Length -ge 4 } | Select-Object -First $kelimeSayisi)
  if(-not $kel.Count){
    $kel = @(("$konu".ToLowerInvariant() -replace '[^a-zçğıöşü0-9 ]',' ' -split '\s+') |
             Where-Object { $_.Length -ge 3 } | Select-Object -First $kelimeSayisi)
  }
  if(-not $kel.Count){ return '' }
  # Kelime govdesi: son 2 harf ek olabilir, atilir (sozlesmesi -> sozlesm)
  $parca=@($kel | ForEach-Object { $g=$_; if($g.Length -ge 6){ $g=$g.Substring(0,$g.Length-2) }; TrDesen $g })
  return ($parca -join '.*')
}

# --- 4) SIRALI-N (tuzak 1) ----------------------------------------------------
# "Ilk N'i al" ile "ilgiye gore sirala, sonra N al" AYNI SEY DEGILDIR.
# Bu oturumda bes kez ayni hata yapildi. Secim yapan her yerde bu kullanilir.
function SiraliIlkN($ogeler,[scriptblock]$puan,[int]$n){
  $d=Dizi $ogeler
  if($d.Count -le $n){ return $d }
  $i=0
  return @($d | ForEach-Object { $i++; [pscustomobject]@{ o=$_; p=(& $puan $_); s=$i } } |
           Sort-Object @{e='p';d=$true},@{e='s';d=$false} |
           Select-Object -First $n | ForEach-Object { $_.o })
}

# --- OZ-SINAV -----------------------------------------------------------------
# Her fonksiyonun BILINEN CEVAPLI bir sinamasi var. Betikler kosmadan once
# Test-OlcumKapilari cagirabilir; kirmizi donerse olcume GUVENILMEZ.
function Test-OlcumKapilari([switch]$Sessiz){
  $hata=New-Object System.Collections.Generic.List[string]

  # 1) JsonDizi: 3 ogeli dizi 3 donmeli
  $gecici=Join-Path $env:TEMP ('olcum-sinav-'+[guid]::NewGuid().ToString('N')+'.json')
  try{
    [IO.File]::WriteAllText($gecici,(@('bir','iki','uc')|ConvertTo-Json),(New-Object Text.UTF8Encoding $false))
    $d=JsonDizi $gecici
    if($d.Count -ne 3){ $hata.Add("JsonDizi: 3 beklendi, $($d.Count) geldi (dizi tuzagi)") }
    if("$($d[0])" -ne 'bir'){ $hata.Add("JsonDizi: ilk oge 'bir' degil -> '$($d[0])'") }
  }catch{ $hata.Add("JsonDizi coktu: $($_.Exception.Message)") }
  finally{ Remove-Item $gecici -Force -ErrorAction SilentlyContinue }

  # 2) Dizi: List[object] patlamadan dizi olmali
  try{
    $l=New-Object System.Collections.Generic.List[object]; $l.Add('a'); $l.Add('b')
    $d2=Dizi $l
    if($d2.Count -ne 2){ $hata.Add("Dizi: 2 beklendi, $($d2.Count) geldi") }
  }catch{ $hata.Add("Dizi coktu (List tuzagi): $($_.Exception.Message)") }

  # 3) AmbarSorgu: ASCII katlanmis ad Turkce harften ONCE kesilmeli
  $q=AmbarSorgu 'is sozlesmesi feshi'
  if(-not $q){ $hata.Add('AmbarSorgu: bos sorgu dondu') }
  # Uretilen desen GERCEK Turkce metinle eslesmeli
  if($q -and ('iş sözleşmesi feshi bildirimi' -notmatch $q)){ $hata.Add("AmbarSorgu: desen Turkce metinle eslesmedi ($q)") }
  $q2=AmbarSorgu 'sebepsiz zenginlesme'
  if($q2 -and ('sebepsiz zenginleşme davası' -notmatch $q2)){ $hata.Add("AmbarSorgu: 'zenginleşme' eslesmedi ($q2)") }
  $q3=AmbarSorgu 'cek zorunlu unsurlari'
  if($q3 -and ('çek zorunlu unsurları nelerdir' -notmatch $q3)){ $hata.Add("AmbarSorgu: 'çek/unsurları' eslesmedi ($q3)") }

  # 4) SiraliIlkN: puani yuksek olan secilmeli, ilk gelen degil
  $ogeler=@(
    [pscustomobject]@{ ad='alakasiz'; p=0 }
    [pscustomobject]@{ ad='alakasiz2'; p=0 }
    [pscustomobject]@{ ad='DOGRU';    p=9 }
  )
  $sec=SiraliIlkN $ogeler { param($x) $x.p } 1
  if("$($sec[0].ad)" -ne 'DOGRU'){ $hata.Add("SiraliIlkN: 'DOGRU' yerine '$($sec[0].ad)' secildi (first-N hatasi)") }

  if(-not $Sessiz){
    if($hata.Count){
      Write-Host "⛔ OLCUM KAPILARI OZ-SINAVI KIRMIZI ($($hata.Count) kusur):" -ForegroundColor Red
      foreach($h in $hata.ToArray()){ Write-Host "   - $h" -ForegroundColor Red }
    } else { Write-Host "OLCUM KAPILARI OZ-SINAVI YESIL (4/4)" -ForegroundColor Green }
  }
  return ,$hata.ToArray()
}

# Dogrudan calistirilirsa oz-sinav kos
if($MyInvocation.InvocationName -ne '.' -and $MyInvocation.Line -notmatch '^\s*\.\s'){ [void](Test-OlcumKapilari) }
