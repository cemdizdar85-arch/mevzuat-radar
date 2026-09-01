# ============================================================================
#  KONU KÖPRÜSÜ — v1 TOHUM (01.09.2026, Cem: "KÖPRÜYÜ KUR")
#
#  NEDEN VAR: İki taksonomi köprüsüz — bizim ders/konu adları ile çıkmış-arşiv
#  etiketleri ayrı evrenler; "eksik konu" ölçümü bu yüzden sahte-eksik üretiyor
#  (25.08: 66'nın 62'si sahteydi). Köprü = sinav>ders>konu kanonik sözlüğü +
#  arşiv-adı eşleşmesi + bizim/çıkmış sayılar + durum + dayanak.
#
#  V1 KAYNAĞI: SINAVKONUDAYANAKHARITASI31082026.xlsx / '4-KONU BIRLESIK'
#  (kardeş oturumun 31.08 ölçümü; 5/5 sondajla doğrulandı). V2 HEDEFİ: bu
#  betik xlsx yerine doğrudan kasadan+arşiv etiketlerinden türetecek — o gün
#  köprü günlük görevin halkası olur ve kendini tazeler (bekleyenlerde).
#
#  ÇIKTI:
#   veri/fabrika/konu-koprusu.json  -> TAM köprü (23k konu; gitignore içi)
#   veri/konu-koprusu-ozet.json     -> repo'ya giren kompakt özet:
#        durum sayıları + ders-köprü sözlüğü + AĞIR BOŞLUK listesi (>=3 dönem)
#  Excel COM kullanır (bu makinede python yok, Office 16 var).
# ============================================================================
param([string]$xlsxYol='C:\Users\cemdi\OneDrive\Masaüstü\SINAVKONUDAYANAKHARITASI31082026.xlsx')
$ErrorActionPreference='Stop'
$here=if($PSScriptRoot){ $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$kok=Split-Path -Parent $here
if(-not (Test-Path $xlsxYol)){ throw "harita bulunamadi: $xlsxYol" }

Write-Host 'Harita okunuyor (Excel COM)...'
$xl=New-Object -ComObject Excel.Application; $xl.DisplayAlerts=$false
$wb=$xl.Workbooks.Open($xlsxYol,$null,$true)
$ws=$wb.Worksheets.Item('4-KONU BIRLESIK')
$V=$ws.UsedRange.Value2
$n=$V.GetLength(0)
Write-Host "  satir: $($n-1)"

$kayitlar=New-Object System.Collections.Generic.List[object]
for($r=2;$r -le $n;$r++){
  $kayitlar.Add([pscustomobject]@{
    sinav="$($V[$r,1])"; konu="$($V[$r,2])"
    bizim_ders="$($V[$r,3])"; arsiv_ders="$($V[$r,4])"
    bizim=[int]"0$($V[$r,5])"; cikmis=[int]"0$($V[$r,6])"
    durum="$($V[$r,7])"; dayanak="$($V[$r,8])"
    cikmis_dayanak="$($V[$r,9])"; guc="$($V[$r,10])"
    donem=[int]"0$($V[$r,11])"
  })
}
$wb.Close($false); $xl.Quit()
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($xl) | Out-Null

# --- TAM kopru (fabrika) ---
$fab=Join-Path $kok 'veri\fabrika'
if(-not (Test-Path $fab)){ New-Item -ItemType Directory -Path $fab -Force | Out-Null }
[IO.File]::WriteAllText((Join-Path $fab 'konu-koprusu.json'),(ConvertTo-Json -InputObject $kayitlar.ToArray() -Depth 3 -Compress),[Text.UTF8Encoding]::new($false))
Write-Host "  TAM kopru yazildi: veri/fabrika/konu-koprusu.json ($($kayitlar.Count) konu)"

# --- OZET (repo) ---
$durumSay=@{}
$dersKoprusu=@{}     # 'SINAV|arsiv_ders' -> @{bizim_ders=..; konu=N}
$agir=New-Object System.Collections.Generic.List[object]
foreach($x in $kayitlar){
  $d="$($x.durum)"; if(-not $durumSay[$d]){$durumSay[$d]=0}; $durumSay[$d]++
  if($x.arsiv_ders){
    $dk="$($x.sinav)|$($x.arsiv_ders)"
    if(-not $dersKoprusu[$dk]){ $dersKoprusu[$dk]=@{bizim_ders="$($x.bizim_ders)";konu=0} }
    $dersKoprusu[$dk].konu++
    if(-not $dersKoprusu[$dk].bizim_ders -and $x.bizim_ders){ $dersKoprusu[$dk].bizim_ders="$($x.bizim_ders)" }
  }
  if($d -like 'BOSLUK*' -and $x.donem -ge 3){
    $agir.Add([pscustomobject]@{sinav=$x.sinav;konu=$x.konu;donem=$x.donem;cikmis=$x.cikmis;arsiv_ders=$x.arsiv_ders;dayanak=$x.cikmis_dayanak;guc=$x.guc})
  }
}
$dersListe=New-Object System.Collections.Generic.List[object]
foreach($k in ($dersKoprusu.Keys|Sort-Object)){
  $p=$k -split '\|'
  $dersListe.Add([pscustomobject]@{sinav=$p[0];arsiv_ders=$p[1];bizim_ders=$dersKoprusu[$k].bizim_ders;konu_sayisi=$dersKoprusu[$k].konu})
}
$ozet=[ordered]@{
  kaynak='SINAVKONUDAYANAKHARITASI31082026.xlsx / 4-KONU BIRLESIK (31.08 olcumu; 5/5 sondaj dogrulamali)'
  konu_sayisi=$kayitlar.Count
  durum=$durumSay
  ders_koprusu=$dersListe.ToArray()
  agir_bosluk_sayisi=$agir.Count
  agir_bosluklar=@($agir | Sort-Object donem -Descending)
  not='V1 tohum: xlsx kaynakli. V2: kasa+arsiv etiketlerinden canli turetim (gunluk halka) - bekleyenlerde.'
}
. (Join-Path $kok 'arac\rapor-yaz.ps1')
RaporYaz -Hedef (Join-Path $kok 'veri\konu-koprusu-ozet.json') -Nesne $ozet
Write-Host "  OZET: $($kayitlar.Count) konu | durum: $((@($durumSay.GetEnumerator()|%{"$($_.Key.Split(' ')[0])=$($_.Value)"}) -join ' ')) | ders-koprusu: $($dersListe.Count) | agir bosluk: $($agir.Count)"
