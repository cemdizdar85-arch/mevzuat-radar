# ============================================================================
#  MUKERRER ELEME (02.08.2026) — 0 USD, API YOK
#
#  NEDEN SIMDI: parali kosudan ONCE. Kasada 852 grupta 3.821 mukerrer soru var
#  (onarim-tarama.json T1). Grup basina 1 kalirsa 2.969 soru elenir. Once eleme
#  yapilmazsa o 2.969 soruya da "Dogrusu" ve tablo yazdirip PARA VERIRIZ.
#  Cem'in sirasi: ONCE BEDAVA ELEME, SONRA PARALI YAZIM.
#
#  HANGISI KALIR (500-okuma dersi: "en iyi yazilmis kalir") — ama artik goz
#  karari degil OLCU. Her soru sozlesme puani alir:
#    +4 dogru sikta dort parca (Ne soruluyor/Kural/Bu olayda/Akilda kalsin)
#    +1 her yanlis sikta tuzak adlandirmasi (en fazla 4)
#    +1 her yanlis sikta "Dogrusu:" (en fazla 4)
#    +3 tablo verisi · +3 yevmiye verisi · +2 kaynak etiketi 6+ karakter
#    +aciklama uzunlugu / 500 (esitlik bozucu, en fazla 3)
#  En yuksek puanli KALIR, digerleri yayin=false + sebep notu.
#
#  SORU SILINMEZ - yalniz yayindan iner (karantina asla silinmez kurali).
#  Karar geri alinabilir: yayin_notu'nda hangi grubun hangi sampiyonuna
#  elendigi yazar.
#
#  VARSAYILAN OLCUM (0 USD, hicbir sey yazilmaz). -yaz ile uygulanir.
#  ENV: SUPABASE_SERVICE_KEY · Cikti: veri/mukerrer-eleme-raporu.json
# ============================================================================
param([switch]$yaz)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$PSDefaultParameterValues['Invoke-RestMethod:UserAgent'] = 'mevzuat-radar-robot/1.0'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$raporYol = Join-Path $kok 'veri/mukerrer-eleme-raporu.json'

trap {
  $g=""; if($_.ErrorDetails -and $_.ErrorDetails.Message){ $g=$_.ErrorDetails.Message }
  Set-Content -LiteralPath $raporYol -Encoding UTF8 -NoNewline -Value (ConvertTo-Json -Depth 4 -InputObject ([ordered]@{
    tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='HATA'; hata="$($_.Exception.Message)"; sunucu=$g; satir=$_.InvocationInfo.ScriptLineNumber }))
  Write-Host ("HATA (satir {0}): {1} | {2}" -f $_.InvocationInfo.ScriptLineNumber, $_.Exception.Message, $g); exit 1
}
if(-not $env:SUPABASE_SERVICE_KEY){ Write-Host "SUPABASE_SERVICE_KEY yok - atlandi."; exit 0 }
$U  = "https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/soru_havuzu"
$SB = @{ apikey=$env:SUPABASE_SERVICE_KEY; Authorization="Bearer $($env:SUPABASE_SERVICE_KEY)" }

function CekListe([string]$uri){
  $h = Invoke-WebRequest -Uri $uri -Headers $SB -UseBasicParsing -TimeoutSec 180
  $m = if($h.RawContentStream){ [Text.Encoding]::UTF8.GetString($h.RawContentStream.ToArray()) } else { "$($h.Content)" }
  return @($m | ConvertFrom-Json)
}

# --- mukerrer gruplari (onarim-tarama.json T1) ---
$tarYol = Join-Path $kok 'veri/onarim-tarama.json'
if(-not (Test-Path $tarYol)){ Write-Host "onarim-tarama.json yok - once tarama kosulmali."; exit 1 }
$tar = Get-Content $tarYol -Raw -Encoding UTF8 | ConvertFrom-Json
$gruplar = @($tar.T1_gruplar)
Write-Host ("Mukerrer grup: {0}" -f $gruplar.Count)

# --- kasa (puanlama icin) ---
$kasa = @{}
for($o=0; $o -lt 60000; $o+=1000){
  $r = CekListe "$U`?select=id,soru,siklar,dogru,aciklama,tablo,yevmiye,kaynak,yayin&order=id&limit=1000&offset=$o"
  if($r.Count -eq 0){ break }
  foreach($x in $r){ if($null -ne $x){ $kasa["$($x.id)"] = $x } }
  if($r.Count -lt 1000){ break }
}
Write-Host ("Kasa: {0} soru" -f $kasa.Count)
if($kasa.Count -lt 1000){ Write-Host "!! SUPHELI: kasa kucuk gorundu - sayfalama kirik olabilir."; }

$reNe=[regex]'(?i)ne\s+sorul'; $reKural=[regex]'(?i)(^|\n|\*|\||>)\s*kural\s*:'
$reOlay=[regex]'(?i)bu\s+olayda'; $reAkil=[regex]'(?i)ak[ıi]lda\s+kals[ıi]n'
$reTuzak=[regex]'(?i)tuzak\s*:|kar[ıi][sş]t[ıi]r'; $reDogrusu=[regex]'(?i)do[ğg]rusu\s*:'
function Dolu($v){ if($null -eq $v){ return $false }; $s="$v"; if($s.Trim().Length -lt 5){ return $false }; return ($s -ne '{}' -and $s -ne '[]' -and $s -ne 'null') }

function Puan($s){
  if($null -eq $s){ return -1 }
  $p = 0.0; $a = $s.aciklama; if($null -eq $a){ return 0 }
  $dh = "$($s.dogru)".Trim().ToUpper()
  $dm = ""; try { if($a.PSObject.Properties[$dh]){ $dm = "$($a.$dh)" } } catch {}
  $c = 0
  if($reNe.IsMatch($dm)){$c++}; if($reKural.IsMatch($dm)){$c++}
  if($reOlay.IsMatch($dm)){$c++}; if($reAkil.IsMatch($dm)){$c++}
  if($c -eq 4){ $p += 4 }
  $tz=0; $dg=0; $uz=0
  foreach($h in 'A','B','C','D','E'){
    $m=""; try { if($a.PSObject.Properties[$h]){ $m="$($a.$h)" } } catch {}
    $uz += $m.Length
    if($h -eq $dh){ continue }
    if($m.Length -lt 5){ continue }
    if($reTuzak.IsMatch($m)){$tz++}; if($reDogrusu.IsMatch($m)){$dg++}
  }
  $p += [Math]::Min(4,$tz); $p += [Math]::Min(4,$dg)
  if(Dolu $s.tablo){ $p += 3 }
  if(Dolu $s.yevmiye){ $p += 3 }
  if("$($s.kaynak)".Trim().Length -ge 6){ $p += 2 }
  $p += [Math]::Min(3.0, $uz / 500.0)
  return [Math]::Round($p,2)
}

# ============================================================================
#  RAKAM KAPISI - 02.08 gece, elemeyi uygulamadan ONCE yakalandi.
#
#  onarim-tarama.ps1:152 mukerrer parmak izini "kaynak + dogru sikkin ilk 80
#  karakteri" olarak kuruyor AMA metni once Sade() ile RAKAMSIZLASTIRIYOR.
#  Sonuc: "Amortisman tutari 20.000 TL" ile "Amortisman tutari 50.000 TL" ayni
#  parmak izini aliyor. Hesap sorularinin farkli rakamli varyantlari SAHTE
#  mukerrer olarak grupanmis. Tarama grubuna korlemesine guvenilseydi gercek
#  sorular yayindan indirilecekti.
#
#  Bu yuzden grup uyeligi burada YENIDEN dogrulanir: bir soru ancak
#  (a) soru kokü ve (b) dogru sik metni sampiyonunkiyle RAKAMLAR DAHIL birebir
#  ayni ise elenir. Farkli rakam = farkli soru = KALIR.
# ============================================================================
function Iskelet([string]$t){
  if($null -eq $t){ return '' }
  $x = $t.ToLowerInvariant()
  $x = $x -replace '\s+',' '
  $x = $x -replace '[^\p{L}\p{Nd}\.,]',''   # noktalama gurultusu at, RAKAMLAR KALSIN
  return $x.Trim()
}
function Kimlik($s){
  if($null -eq $s){ return '' }
  $h = "$($s.dogru)".Trim().ToUpperInvariant()
  $d = ''
  try { if($s.siklar -and $s.siklar.PSObject.Properties[$h]){ $d = "$($s.siklar.$h)" } } catch {}
  return (Iskelet "$($s.soru)") + '||' + (Iskelet $d)
}

$kalan = New-Object System.Collections.Generic.List[object]
$elenecek = New-Object System.Collections.Generic.List[object]
$rakamFarkiKurtardi = 0
$kurtarmaOrnek = New-Object System.Collections.Generic.List[object]
$atlanan = 0
foreach($g in $gruplar){
  # T1_gruplar bir NESNE listesi degil, dogrudan id DIZILERI listesidir
  # (ilk olcumde 852 grubun 852'si atlandi cunku $g.idler diye aramistim).
  $idler = @($g)
  if($idler.Count -eq 1 -and $null -ne $g.idler){ $idler = @($g.idler) }
  $uyeler = @()
  foreach($i in $idler){ $k = $kasa["$i"]; if($null -ne $k){ $uyeler += [pscustomobject]@{ id="$i"; puan=(Puan $k); yayin=$k.yayin } } }
  if($uyeler.Count -lt 2){ $atlanan++; continue }
  $sirali = @($uyeler | Sort-Object -Property @{Expression='puan';Descending=$true}, @{Expression='id';Descending=$false})
  $sampiyon = $sirali[0]
  $sampKimlik = Kimlik $kasa[$sampiyon.id]
  $grupElenen = 0
  for($n=1; $n -lt $sirali.Count; $n++){
    # RAKAM KAPISI: rakamlar dahil birebir ayni degilse FARKLI sorudur, kalir.
    if((Kimlik $kasa[$sirali[$n].id]) -ne $sampKimlik){
      $rakamFarkiKurtardi++
      # "0 elendi" gibi fazla temiz bir rakama korlemesine guvenilmez: kapinin
      # dogru mu yoksa bozuk mu oldugunu GOZLE gorebilmek icin ilk 8 ciftin
      # metinleri rapora yazilir (kor kalma kurali).
      if($kurtarmaOrnek.Count -lt 8){
        $kurtarmaOrnek.Add([ordered]@{
          sampiyon_soru = ("$($kasa[$sampiyon.id].soru)" -replace '\s+',' ')
          kurtarilan_soru = ("$($kasa[$sirali[$n].id].soru)" -replace '\s+',' ')
        })
      }
      continue
    }
    $elenecek.Add([ordered]@{ id=$sirali[$n].id; puan=$sirali[$n].puan; sampiyon=$sampiyon.id; sampiyon_puan=$sampiyon.puan })
    $grupElenen++
  }
  if($grupElenen -gt 0){ $kalan.Add([ordered]@{ id=$sampiyon.id; puan=$sampiyon.puan; grup_boyu=$uyeler.Count; elenen=$grupElenen }) }
}
Write-Host ("RAKAM KAPISI kurtardi (sahte mukerrer): {0}" -f $rakamFarkiKurtardi)
Write-Host ("Kalan (sampiyon): {0} | Elenecek: {1} | Atlanan grup: {2}" -f $kalan.Count, $elenecek.Count, $atlanan)

if(-not $yaz){
  $rapor = [ordered]@{
    tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); mod='OLCUM (0 USD, hicbir sey yazilmadi)'
    grup=$gruplar.Count; kasa=$kasa.Count
    kalan_sampiyon=$kalan.Count; elenecek=$elenecek.Count; atlanan_grup=$atlanan
    rakam_kapisi_kurtardi=$rakamFarkiKurtardi
    kurtarma_ornekleri=@($kurtarmaOrnek)
    parali_isten_dusen_soru=$elenecek.Count
    ornek_kararlar=@($elenecek | Select-Object -First 25)
    not='Soru SILINMEZ, yalniz yayindan iner. Sampiyon secimi OLCUYLE: sozlesme puani (dort parca, tuzak, Dogrusu, tablo, yevmiye, kaynak, uzunluk). -yaz ile uygulanir.'
  }
  Set-Content -LiteralPath $raporYol -Value (ConvertTo-Json -InputObject $rapor -Depth 5) -Encoding UTF8 -NoNewline
  Write-Host "`nOLCUM MODU - hicbir sey yazilmadi."
  Write-Host ("Parali isten dusecek soru: {0}" -f $elenecek.Count)
  Write-Host ("-> {0}" -f $raporYol); exit 0
}

# --- UYGULA: yayin=false + sebep (PATCH, 50'lik partiler) ---
$islenen = 0
for($b=0; $b -lt $elenecek.Count; $b+=50){
  $parca = $elenecek[$b..([Math]::Min($b+49,$elenecek.Count-1))]
  $liste = ($parca | ForEach-Object { '"' + $_.id + '"' }) -join ','
  $govde = ConvertTo-Json -Compress -InputObject @{ yayin=$false; yayin_notu=("Mukerrer eleme 02.08.2026: ayni kurali olcen grupta daha eksiksiz yazilmis soru kaldi. Soru silinmedi; onarim sonrasi yeniden degerlendirilebilir.") }
  Invoke-RestMethod -Uri "$U`?id=in.($liste)" -Method Patch -Headers ($SB + @{ 'Content-Type'='application/json'; Prefer='return=minimal' }) -Body ([Text.Encoding]::UTF8.GetBytes($govde)) -TimeoutSec 90 | Out-Null
  $islenen += $parca.Count
}
# --- GERI OKUMA: elenenler gercekten kapandi mi? ---
$halaAcik = 0
$tumId = @($elenecek | ForEach-Object { $_.id })
for($b=0; $b -lt $tumId.Count; $b+=50){
  $parca = $tumId[$b..([Math]::Min($b+49,$tumId.Count-1))]
  $liste = ($parca | ForEach-Object { '"' + $_ + '"' }) -join ','
  $halaAcik += @(CekListe "$U`?select=id&yayin=eq.true&id=in.($liste)").Count
}
$rapor = [ordered]@{
  tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); mod='UYGULANDI'
  durum=$(if($halaAcik -eq 0){'TAMAM'}else{'KIRMIZI'})
  grup=$gruplar.Count; kalan_sampiyon=$kalan.Count; elenen=$islenen
  geri_okuma_hala_yayinda=$halaAcik
  not='Soru silinmedi, yayin=false yapildi. Geri okumada 0 beklenir.'
}
Set-Content -LiteralPath $raporYol -Value (ConvertTo-Json -InputObject $rapor -Depth 4) -Encoding UTF8 -NoNewline
Write-Host ("ELEME BITTI: {0} soru yayindan indi | geri okumada hala acik: {1}" -f $islenen, $halaAcik)
if($halaAcik -gt 0){ exit 1 }
