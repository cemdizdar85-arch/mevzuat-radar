# ETİK KURALLAR SAYFA NUMARASI + BÖLÜM ADLARI (08.10.2026, KGK oturumu) — 0 USD.
# NE YAPAR: motor/kgk-standart-yut.ps1 Parcala paragraf yolu YALNIZ Etik Kurallar için iki işlev kullanır:
#   1) SayfaNoAyikla: pdftotext her sayfanın sonuna (\f'den önce) tek başına sayfa numarası koyuyor. Paragraf deseni bu sayıyı paragraf
#      numarası sanıyordu ("227 TERİMLER SÖZLÜĞÜ" → "Etik Kurallar p.227 [1/3]"; 08.10 ölçümü 81 sahte ad) ya da sayı cümlenin ortasında
#      kalıyordu ("mesleki şüphecilik 80 içinde"). KURAL: \f'den önceki SON dolu satır yalnız rakamsa (1–4 hane) sayfa numarasıdır, satır silinir.
#      \f korunur. Ölçüm (08.10, Etik 2025 PDF): 240 satır, 238/239 ardışık artan (2…242).
#   2) EtikBolumBasliklari: sayfa numarası silinince numarasız bloklar (KISIM/BÖLÜM girişleri, Terimler Sözlüğü) ÖNCEKİ paragrafa yapışıyordu
#      (08.10 ilk deneme: sözlük → "p.A990.8 [1/9]"). Satır başındaki KISIM n – / BÖLÜM nnn / ALT BÖLÜM nnn başlığı yeni blok açar ve kendi
#      adını alır ("Etik Kurallar - Bölüm 340"); paragraf araya girmeden gelen ardışık başlıklar ilk başlığın bloğunda kalır (kısım kapak
#      sayfası tek blok). Belge sonu bölümleri (Terimler Sözlüğü · Kısaltmalar · Yürürlük Tarihi) her zaman ayrı blok açar.
#      İçindekiler (İÇİNDEKİLER satırından gövdenin ilk "KISIM n – … BÖLÜM nnn" kapağına dek) tek bloktur; içindeki "100 ETİK KURALLARA UYUM"
#      gibi satırlar paragraf açmaz.
# Mutasyon: $env:ESB_MUTASYON = sayfano (sayfa numarası silinmez) | bolum (başlık bloğu yok) | son (belge sonu bölümü ayrılmaz)
#           | icindekiler (içindekiler bloğu yok) | ardisik (ardışık başlıklar birleşmez) | resmi (resmî metin düzeltmesi yok) | kuyruk (içindekiler kuyruğu sonraki bloğa geçer) → öz-sınav KIRMIZI düşmeli.
# 🚫 GÖRMEZ: sayfa numarası \f'den önceki son satır değilse (alt bilgi altında başka satır) · "Sayfa 12" / "12/240" biçimi · \f üretmeyen
#   metin dökümü · küçük harfle ya da satır ortasında yazılmış başlık · listede olmayan belge sonu bölümü. Yalnız Etik Kurallar'a bağlı;
#   öteki standartlarda (KYS 1, BDS …) aynı sayfa numarası kusuru ÖLÇÜLMEDİ.
function SayfaNoAyikla([string]$metin){
  if("$env:ESB_MUTASYON" -eq 'sayfano'){ return $metin }
  return [regex]::Replace($metin, '(?m)^[ \t]*\d{1,4}[ \t]*\n(?=(?:[ \t]*\n)*\f)', '')
}
# RESMÎ METİN DÜZELTMESİ (08.10): pdftotext iki yana yaslı satırın son kelimesini ayrı sütun sanıp yerinden kaydırıyor. Her satır resmî KGK PDF'i
#   OKUNARAK yazılır (dayanak: sayfa no). Desen bulunmazsa (PDF değişti) metne dokunulmaz, uyarı yazılır — sessiz geçilmez.
#   p.400.5 (PDF s.81): "(a) … mesleki muhakemesini olumsuz etkileyebilecek tesirlerden ari …" · "(b) Şekilde bağımsızlık –" (çıktı: "(b) olumsuz Şekilde").
$ETIK_RESMI_DUZELTME = @(
  @{ dayanak = 'p.400.5 · Etik 2025 PDF s.81'; desen = '(mesleki muhakemesini)(\s+etkileyebilecek tesirlerden ari olarak görüş/sonuç açıklamasıdır\.\s+\(b\)\s+)olumsuz\s+(Şekilde bağımsızlık)'; yerine = '$1 olumsuz$2$3' }
)
function EtikResmiDuzelt([string]$duz){
  if("$env:ESB_MUTASYON" -eq 'resmi'){ return $duz }
  foreach($d in $ETIK_RESMI_DUZELTME){
    $n = [regex]::Matches($duz, $d.desen).Count
    if($n -eq 1){ $duz = [regex]::Replace($duz, $d.desen, $d.yerine) } else { Write-Host ("UYARI Etik resmî düzeltme uygulanmadı ({0}): desen {1} kez" -f $d.dayanak, $n) }
  }
  return $duz
}
function EtikBolumBasliklari([string]$duz){
  # dönüş: @{ kesim = [ {Index; Ad; Baslik} ... ]; kapaliBas; kapaliSon }  — kapalı aralıktaki paragraf eşleşmeleri yok sayılır (içindekiler)
  $sonuc = [pscustomobject]@{ kesim = New-Object System.Collections.Generic.List[object]; kapaliBas = -1; kapaliSon = -1 }
  if("$env:ESB_MUTASYON" -eq 'bolum'){ return $sonuc }
  $govdeBas = [regex]::Match($duz, '(?m)^[\f ]*KISIM \d[AB]? [–-][^\n]*\n(?:[^\n]*\n){0,2}?[\f ]*BÖLÜM \d{3}')
  if(-not $govdeBas.Success){ return $sonuc }
  $ib = [regex]::Match($duz.Substring(0, $govdeBas.Index), '(?m)^[\f ]*İÇİNDEKİLER *$')
  if($ib.Success -and "$env:ESB_MUTASYON" -ne 'icindekiler'){
    $sonuc.kapaliBas = $ib.Index; $sonuc.kapaliSon = $govdeBas.Index
    $sonuc.kesim.Add([pscustomobject]@{ Index = $ib.Index; Ad = 'İçindekiler'; Son = $true })
  }
  $rx = [regex]'(?m)^[\f ]*(?:KISIM (?<kno>\d[AB]?) [–-]|(?<alt>ALT )?BÖLÜM (?<bno>\d{3})(?= |$)|(?<son>TERİMLER SÖZLÜĞÜ|KISALTMALARA VE ETİK KURALLARDA|YÜRÜRLÜK TARİHİ *$))'
  foreach($m in $rx.Matches($duz, $govdeBas.Index)){
    if($m.Groups['son'].Success){
      if("$env:ESB_MUTASYON" -eq 'son'){ continue }
      $s = $m.Groups['son'].Value
      $ad = if($s.StartsWith('TERİMLER')){ 'Terimler Sözlüğü' } elseif($s.StartsWith('KISALTMA')){ 'Kısaltmalar Listesi' } else { 'Yürürlük Tarihi' }
      $sonuc.kesim.Add([pscustomobject]@{ Index = $m.Index; Ad = $ad; Son = $true })
    } elseif($m.Groups['kno'].Success){
      $sonuc.kesim.Add([pscustomobject]@{ Index = $m.Index; Ad = ('Kısım {0}' -f $m.Groups['kno'].Value); Son = $false })
    } else {
      $ad = if($m.Groups['alt'].Success){ 'Alt Bölüm {0}' } else { 'Bölüm {0}' }
      $sonuc.kesim.Add([pscustomobject]@{ Index = $m.Index; Ad = ($ad -f $m.Groups['bno'].Value); Son = $false })
    }
  }
  return $sonuc
}
function EtikSonBlokMu([string]$ad){ if("$env:ESB_MUTASYON" -eq 'kuyruk'){ return $false }; return ($ad -match ' - (İçindekiler|Terimler Sözlüğü|Kısaltmalar Listesi|Yürürlük Tarihi)( \[\d+/\d+\])?$') }
# Paragraf eşleşmeleri + başlık kesimleri → sıralı kesim listesi. Paragraf araya girmeden gelen başlık (Son değilse) önceki başlığın bloğunda kalır.
function EtikKesimBirlestir($parEsler, $bb){
  $hepsi = New-Object System.Collections.Generic.List[object]
  foreach($m in $parEsler){
    if($bb.kapaliBas -ge 0 -and $m.Index -ge $bb.kapaliBas -and $m.Index -lt $bb.kapaliSon){ continue }
    $hepsi.Add([pscustomobject]@{ Index = $m.Index; Par = $m; Ad = $null; Son = $false })
  }
  foreach($k in $bb.kesim){ $hepsi.Add([pscustomobject]@{ Index = $k.Index; Par = $null; Ad = $k.Ad; Son = $k.Son }) }
  $sirali = @($hepsi | Sort-Object Index)
  $cikti = New-Object System.Collections.Generic.List[object]
  $sonBolumde = $false   # Terimler Sözlüğü / Kısaltmalar / Yürürlük: içindeki "120.6 U3" gibi satır başı atıflar paragraf açmaz
  foreach($k in $sirali){
    $onceki = if($cikti.Count){ $cikti[$cikti.Count-1] } else { $null }
    if($k.Ad -and $k.Son -and $k.Ad -ne 'İçindekiler'){ $sonBolumde = $true }
    if(-not $k.Ad -and $sonBolumde -and "$env:ESB_MUTASYON" -ne 'son'){ continue }
    if($k.Ad -and -not $k.Son -and $onceki -and $onceki.Ad -and -not $onceki.Son -and "$env:ESB_MUTASYON" -ne 'ardisik'){ continue }
    $cikti.Add($k)
  }
  return ,$cikti
}
if($MyInvocation.InvocationName -ne '.' -and $args -contains '-Sinav'){
  $h = 0; $n = 0
  function Vaka([string]$ad, [bool]$ok){ $script:n++; if(-not $ok){ $script:h++; "  DUSTU: $ad" } }
  $f = [string][char]12
  # --- 1) sayfa numarası
  Vaka 'sayfa no silinir' ((SayfaNoAyikla "metin biter`n12`n${f}devam") -eq "metin biter`n${f}devam")
  Vaka 'boş satırlı sayfa no silinir' ((SayfaNoAyikla "metin`n227`n`n`n${f}TERİMLER") -eq "metin`n`n`n${f}TERİMLER")
  Vaka 'sayfa sonunda olmayan sayı kalır (içindekiler 100)' ((SayfaNoAyikla "100`n`nETİK KURALLARA UYUM`n") -eq "100`n`nETİK KURALLARA UYUM`n")
  Vaka 'satır ortasındaki sayı kalır' ((SayfaNoAyikla "toplam 12`n${f}x") -eq "toplam 12`n${f}x")
  Vaka 'paragraf no + metin satırı kalır' ((SayfaNoAyikla "metin`n120.6`n${f}x") -eq "metin`n120.6`n${f}x")
  Vaka 'sayfa sonu olmayan son satır sayı kalır' ((SayfaNoAyikla "metin`n45`n") -eq "metin`n45`n")
  # --- 2) başlıklar
  $metin = "İÇİNDEKİLER`nKISIM 1 – UYUM`n100`n`nETİK KURALLARA UYUM`n990`n`nKULLANIM VE DAĞITIM RAPORLARI`n(GÜVENCE DENETİMLERİ)`nTERİMLER SÖZLÜĞÜ VE KISALTMALAR LİSTESİ`nYÜRÜRLÜK TARİHİ`n${f}" +
           "KISIM 1 – UYUM`nBÖLÜM 100`nETİK KURALLARA UYUM`nGiriş`n100.1 Denetçi uyar ve bu cümle yeterince uzun bir paragraf gövdesidir.`n" +
           "100.2 Bölüm 120 uyarınca denetçi değerlendirir ve bu da yeterince uzun bir paragraf gövdesidir.`n" +
           "BÖLÜM 340 HEDİYELER`nGiriş`n340.1 Denetçi hediye kabul etmez ve bu cümle yeterince uzun bir paragraf gövdesidir.`n" +
           "ALT BÖLÜM 601 – MUHASEBE`n601.1 Muhasebe hizmeti verilmez ve bu cümle yeterince uzun bir paragraf gövdesidir.`n" +
           "990.1 Son paragraf gövdesi burada biter ve bu cümle yeterince uzun bir paragraf gövdesidir.`n50`n${f}TERİMLER SÖZLÜĞÜ VE KISALTMALAR LİSTESİ`nKilit yönetici Yönetim organı üyesidir.`n977.1 Sözlükte satır başına düşen atıf, paragraf değildir ve sözlükte kalır.`n" +
           "KISALTMALARA VE ETİK KURALLARDA ATIFTA BULUNULAN STANDARTLAR`nBDS Bağımsız Denetim Standardı`nYÜRÜRLÜK TARİHİ`nBu Kurallar yürürlüğe girer.`n51`n${f}"
  $bb = EtikBolumBasliklari (SayfaNoAyikla $metin)
  $adlar = @($bb.kesim | ForEach-Object { $_.Ad }) -join '|'
  Vaka 'başlık listesi' ($adlar -eq 'İçindekiler|Kısım 1|Bölüm 100|Bölüm 340|Alt Bölüm 601|Terimler Sözlüğü|Kısaltmalar Listesi|Yürürlük Tarihi')
  Vaka 'satır içi "Bölüm 120" başlık değil' ($adlar -notmatch 'Bölüm 120')
  # --- 2b) resmî metin düzeltmesi (p.400.5)
  $k400 = "mesleki muhakemesini`netkileyebilecek tesirlerden ari olarak görüş/sonuç açıklamasıdır.`n(b)`n`nolumsuz`n`nŞekilde bağımsızlık – Denetim"
  $d400 = EtikResmiDuzelt $k400
  Vaka 'p.400.5: "olumsuz" yerine döner' ($d400 -eq "mesleki muhakemesini olumsuz`netkileyebilecek tesirlerden ari olarak görüş/sonuç açıklamasıdır.`n(b)`n`nŞekilde bağımsızlık – Denetim")
  Vaka 'desen yoksa metne dokunulmaz' ((EtikResmiDuzelt "(b) Şekilde bağımsızlık") -eq "(b) Şekilde bağımsızlık")
  # --- 3) uçtan uca: gerçek Parcala (motor/kgk-standart-yut.ps1'den yalnız işlevler)
  $kok = Split-Path -Parent $PSScriptRoot
  . (Join-Path $kok 'arac/dipnot-ayir.ps1'); . (Join-Path $kok 'arac/standart-baslik-kuyrugu.ps1')
  $ast = [System.Management.Automation.Language.Parser]::ParseFile((Join-Path $kok 'motor/kgk-standart-yut.ps1'), [ref]$null, [ref]$null)
  foreach($fd in $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $false)){ . ([scriptblock]::Create($fd.Extent.Text)) }
  $ek = (1..10 | ForEach-Object { "10$_.1 Ek paragraf $_ gövdesi yeterince uzun bir cümledir ve burada nokta ile biter.`n" }) -join ''
  $parca = @(Parcala ($metin -replace '990\.1', ($ek + '990.1')) 'Etik Kurallar')
  $pa = @($parca | ForEach-Object { $_.kaynak_ad })
  Vaka 'uçtan uca: Terimler Sözlüğü kendi adını alır' ($pa -contains 'Etik Kurallar - Terimler Sözlüğü')
  Vaka 'uçtan uca: Bölüm 340 kendi adını alır' ($pa -contains 'Etik Kurallar - Bölüm 340')
  Vaka 'uçtan uca: sayfa no adı yok' (-not ($pa -match '^Etik Kurallar p\.(50|51)$'))
  $son = $parca | Where-Object { $_.kaynak_ad -eq 'Etik Kurallar p.990.1' }
  Vaka 'uçtan uca: sözlük önceki paragrafa yapışmaz' ($son -and "$($son.metin)" -notmatch 'Kilit yönetici' -and "$($son.metin)" -notmatch '\b50\b')
  $b340 = $parca | Where-Object { $_.kaynak_ad -eq 'Etik Kurallar - Bölüm 340' }
  Vaka 'uçtan uca: başlık bloğu tam metin (tek dilim)' ($b340 -and "$($b340.metin)" -match 'HEDİYELER')
  Vaka 'uçtan uca: Kısım 1 içindekilerden sonra kendi adını alır' ($pa -contains 'Etik Kurallar - Kısım 1')
  Vaka 'uçtan uca: kapak + giriş başlıkları tek blok (Bölüm 100 ayrı ad almaz)' (-not ($pa -contains 'Etik Kurallar - Bölüm 100'))
  Vaka 'uçtan uca: sözlük içi atıf paragraf açmaz' (-not ($pa -contains 'Etik Kurallar p.977.1'))
  $k1 = $parca | Where-Object { $_.kaynak_ad -eq 'Etik Kurallar - Kısım 1' }
  Vaka 'uçtan uca: içindekiler kuyruğu Kısım 1e geçmez' ($k1 -and "$($k1.metin)" -cmatch '^KISIM 1')
  Vaka 'uçtan uca: içindekiler satırı paragraf açmaz' (-not ($pa -contains 'Etik Kurallar p.100'))
  Vaka 'uçtan uca: ad tekil' ($pa.Count -eq @($pa | Select-Object -Unique).Count)
  $bir = (@($parca | ForEach-Object { $_.metin }) -join ' ') -replace '\s+', ' '
  $bek = (($metin -replace '990\.1', ($ek + '990.1')) -replace '(?m)^\d+\n(?=\f)', '') -replace '\s+', ' '
  Vaka 'uçtan uca: birleşik metin = kaynak − sayfa no' ($bir.Trim() -eq $bek.Trim())
  if($h){ "ETIK SAYFA/BOLUM SINAVI KIRMIZI: $h/$n"; exit 1 } else { "ETIK SAYFA/BOLUM SINAVI YESIL: $n/$n"; exit 0 }
}
