# KGK YUTUCU ÖN BÖLÜM ÖZ-SINAVI (09.10.2026) — 0 USD, ağ yok.
# NE ÖLÇER: motor/kgk-standart-yut.ps1 Parcala'nın ön bölüm dilimi (madde yolu + paragraf yolu). Kusur (08.10 ölçümü): ön bölüm ≤2.000 kr ise
#   Dilimle tek elemanlı List döndürüyor, PowerShell onu dizgiye açıyor, $onDilim[0] ilk HARF oluyordu → ambara yalnız "T"/"B" giriyordu
#   (25 belge: BDS 220/250/402/560/600/610/710/800/805/810, BOBİ FRS, GDS 3000/3402, KYS 1/2, Sürekli Eğitim Tebliği, TFRS 1/2/6/11/14/17,
#   TMS 26/32/34). Düzeltme: $onDilim = @(Dilimle $on 2000), iki yerde.
# Gerçek Parcala kullanılır: işlevler motor dosyasından AST ile okunur (betiğin indirme döngüsü koşmaz).
# Mutasyon: $env:KOB_MUTASYON = geri → işlev metninde @(Dilimle $on 2000) eski hâline döner (iki yerde) → sınav KIRMIZI düşmeli.
#   Mutasyon iki yerde uygulanamazsa (kod değişti) sınav çıkış 2 verir — sessiz yeşil yok.
# 🚫 GÖRMEZ: ön bölüm dışındaki dilimleme yolları (madde/paragraf/başlık bloğu dilimleri ayrı) · pdftotext çıktısının kendisi ·
#   ambardaki kaydın depo dosyasıyla aynı olup olmadığı (o eşdeğerlik provasıdır, bu sınav değil).
$ErrorActionPreference = 'Stop'
$kok = Split-Path -Parent $PSScriptRoot
. (Join-Path $kok 'arac/dipnot-ayir.ps1'); . (Join-Path $kok 'arac/standart-baslik-kuyrugu.ps1'); . (Join-Path $kok 'arac/etik-sayfa-bolum.ps1')
$ast = [System.Management.Automation.Language.Parser]::ParseFile((Join-Path $kok 'motor/kgk-standart-yut.ps1'), [ref]$null, [ref]$null)
$mutasyonSay = 0
foreach($fd in $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $false)){
  $kod = $fd.Extent.Text
  if("$env:KOB_MUTASYON" -eq 'geri'){
    $mutasyonSay += ([regex]::Matches($kod, [regex]::Escape('@(Dilimle $on 2000)'))).Count
    $kod = $kod.Replace('@(Dilimle $on 2000)', 'Dilimle $on 2000')
  }
  . ([scriptblock]::Create($kod))
}
if("$env:KOB_MUTASYON" -eq 'geri' -and $mutasyonSay -ne 2){ "KGK ON BOLUM SINAVI: MUTASYON UYGULANAMADI ($mutasyonSay/2 yer) - sinav kodla uyumsuz"; exit 2 }

$h = 0; $n = 0
function Vaka([string]$ad, [bool]$ok){ $script:n++; if(-not $ok){ $script:h++; "  DUSTU: $ad" } }
function Duz([string]$s){ return (($s -replace '\s+', ' ').Trim()) }

# --- madde yolu (≥3 MADDE) ---
$onKisa = "TÜRKİYE MUHASEBE STANDARDI`nKapsam ve amaç başlığı burada durur, ön bölüm iki bin karakterden kısadır."
$maddeler = (1..4 | ForEach-Object { "MADDE $_ – Bu madde $_ gövdesidir ve yeterince uzun bir cümle ile biter.`n" }) -join ''
$p1 = @(Parcala ($onKisa + "`n" + $maddeler) 'Deneme Teblig')
$on1 = @($p1 | Where-Object { $_.kaynak_ad -like 'Deneme Teblig - on bolum*' })
Vaka 'madde yolu: kısa ön bölüm tek kayıt' ($on1.Count -eq 1 -and $on1[0].kaynak_ad -eq 'Deneme Teblig - on bolum')
Vaka 'madde yolu: kısa ön bölüm tam metin (ilk harf değil)' ($on1.Count -eq 1 -and (Duz "$($on1[0].metin)") -eq (Duz $onKisa))
Vaka 'madde yolu: madde sayısı 4' (@($p1 | Where-Object { $_.kaynak_ad -match ' m\.\d+$' }).Count -eq 4)
Vaka 'madde yolu: birleşik metin = kaynak' ((Duz ((@($p1 | ForEach-Object { $_.metin })) -join ' ')) -eq (Duz ($onKisa + ' ' + $maddeler)))

# --- madde yolu, uzun ön bölüm (>2.000 → dilim) ---
$onUzun = ((1..60 | ForEach-Object { "Ön bölüm cümlesi $_ burada yazılıdır." }) -join ' ')
$p2 = @(Parcala ($onUzun + "`n" + $maddeler) 'Deneme Teblig')
$on2 = @($p2 | Where-Object { $_.kaynak_ad -like 'Deneme Teblig - on bolum*' })
Vaka 'madde yolu: uzun ön bölüm dilimlenir ([1/N] adlı)' ($on2.Count -ge 2 -and $on2[0].kaynak_ad -eq ("Deneme Teblig - on bolum [1/{0}]" -f $on2.Count))
Vaka 'madde yolu: uzun ön bölüm birleşik = kaynak' ((Duz ((@($on2 | ForEach-Object { $_.metin })) -join '')) -eq (Duz $onUzun))

# --- paragraf yolu (≥10 paragraf) ---
$onPar = "BAĞIMSIZ DENETİM STANDARDI 250`nFİNANSAL TABLOLARIN BAĞIMSIZ DENETİMİNDE MEVZUATIN DİKKATE ALINMASI"
$paragraflar = (1..12 | ForEach-Object { "$_ Bu paragraf $_ gövdesidir ve altmış karakterden uzun olacak biçimde yazılmış bir cümledir.`n" }) -join ''
$p3 = @(Parcala ($onPar + "`n" + $paragraflar) 'BDS 999')
$on3 = @($p3 | Where-Object { $_.kaynak_ad -like 'BDS 999 - on bolum*' })
Vaka 'paragraf yolu: kısa ön bölüm tek kayıt' ($on3.Count -eq 1 -and $on3[0].kaynak_ad -eq 'BDS 999 - on bolum')
Vaka 'paragraf yolu: kısa ön bölüm tam metin (ilk harf değil)' ($on3.Count -eq 1 -and (Duz "$($on3[0].metin)") -eq (Duz $onPar))
Vaka 'paragraf yolu: paragraf sayısı 12' (@($p3 | Where-Object { $_.kaynak_ad -match ' p\.\d+$' }).Count -eq 12)
Vaka 'paragraf yolu: birleşik metin = kaynak' ((Duz ((@($p3 | ForEach-Object { $_.metin })) -join ' ')) -eq (Duz ($onPar + ' ' + $paragraflar)))

# --- paragraf yolu, uzun ön bölüm ---
$p4 = @(Parcala ($onUzun + "`n" + $paragraflar) 'BDS 999')
$on4 = @($p4 | Where-Object { $_.kaynak_ad -like 'BDS 999 - on bolum*' })
Vaka 'paragraf yolu: uzun ön bölüm dilimlenir' ($on4.Count -ge 2 -and $on4[$on4.Count-1].kaynak_ad -eq ("BDS 999 - on bolum [{0}/{0}]" -f $on4.Count))
Vaka 'paragraf yolu: uzun ön bölüm birleşik = kaynak' ((Duz ((@($on4 | ForEach-Object { $_.metin })) -join '')) -eq (Duz $onUzun))

# --- sınır: tam 2.000 kr (tek dilim olmalı, Dilimle döngüye girmez) ---
$on2000 = ('x' * 1990) + ' sonu.abcdef'
$on2000 = $on2000.Substring(0, 2000)
$p5 = @(Parcala ($on2000 + "`n" + $maddeler) 'Deneme Teblig')
$on5 = @($p5 | Where-Object { $_.kaynak_ad -like 'Deneme Teblig - on bolum*' })
Vaka 'sınır 2.000 kr: tek kayıt, 2.000 kr' ($on5.Count -eq 1 -and "$($on5[0].metin)".Length -eq 2000)

if($h){ "KGK ON BOLUM SINAVI KIRMIZI: $h/$n"; exit 1 } else { "KGK ON BOLUM SINAVI YESIL: $n/$n"; exit 0 }
