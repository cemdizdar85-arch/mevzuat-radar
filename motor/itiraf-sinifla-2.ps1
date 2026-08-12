# 132 yeni itirafin GM el siniflandirmasi (12.08.2026) -> kaynak-uyumsuz-SINIF-2.csv
# Siniflar: ALINTI (yanlis pozitif: negatif fiil MADDENIN KENDI METNI, itiraf degil)
#           KAYNAKSIZ-KISMI (kaynak var ama hukum ambar disi, numarasiz anlatilmis)
#           KAYNAKSIZ (kaynak ilgisiz, tamamen genel bilgiden)
#           BECERI-MUAF (hesap/oran/olasilik becerisi, mevzuat gerektirmez)
#           TEORI-SUPHELI (ogreti sorusu, teori notu ambarda dogrulanmadi)
#           PIVOT-KAYNAKLI / PIVOT-THP (gercek kaynaga donmus, disiplinli)
$ErrorActionPreference = 'Stop'
$kok = Split-Path $PSScriptRoot -Parent

$sinif = @{
'00841973'='KAYNAKSIZ-KISMI';'01dfcde1'='ALINTI';'02b9a22e'='ALINTI';'0563a593'='KAYNAKSIZ-KISMI'
'07901f41'='ALINTI';'0930b6e5'='ALINTI';'0b8fd27c'='ALINTI';'0c379e6a'='KAYNAKSIZ-KISMI'
'0e34436d'='ALINTI';'0ff81fc5'='KAYNAKSIZ-KISMI';'11a5b256'='KAYNAKSIZ-KISMI';'15dc1516'='ALINTI'
'16305aef'='KAYNAKSIZ-KISMI';'169e12af'='TEORI-SUPHELI';'181ca5b2'='KAYNAKSIZ';'1a37d6ce'='KAYNAKSIZ'
'1ad25382'='ALINTI';'1cc4d4d8'='ALINTI';'1cea2666'='ALINTI';'1fba0aab'='KAYNAKSIZ-KISMI'
'2558ca0f'='KAYNAKSIZ-KISMI';'2953a877'='ALINTI';'2a5117f6'='ALINTI';'2b118013'='ALINTI'
'2d4ccce0'='ALINTI';'2f37d87f'='KAYNAKSIZ-KISMI';'2f969808'='ALINTI';'2fd49908'='KAYNAKSIZ-KISMI'
'31160875'='ALINTI';'334a5e5c'='ALINTI';'344d9f21'='ALINTI';'345686b7'='ALINTI'
'3601859e'='BECERI-MUAF';'3945b153'='KAYNAKSIZ';'395b1cc4'='KAYNAKSIZ-KISMI';'3ce1d321'='ALINTI'
'3e27f9f3'='ALINTI';'45454790'='ALINTI';'498211d6'='KAYNAKSIZ-KISMI';'4b3c11f0'='BECERI-MUAF'
'4b3d8ae9'='KAYNAKSIZ-KISMI';'4b5b2c12'='BECERI-MUAF';'4e4ececf'='BECERI-MUAF';'4e50e8d9'='ALINTI'
'503e815b'='KAYNAKSIZ-KISMI';'51c01ad1'='ALINTI';'529ec507'='KAYNAKSIZ';'58957152'='ALINTI'
'5b9adebd'='ALINTI';'5d77d15a'='ALINTI';'5f9d656d'='ALINTI';'628bb840'='BECERI-MUAF'
'651ed317'='ALINTI';'677dfe4e'='BECERI-MUAF';'6809e9a0'='ALINTI';'69a20490'='ALINTI'
'6a060362'='ALINTI';'6a6029db'='KAYNAKSIZ';'6abc053b'='KAYNAKSIZ-KISMI';'71980e19'='KAYNAKSIZ-KISMI'
'72ed6bf4'='ALINTI';'745b3097'='KAYNAKSIZ-KISMI';'751bbdc1'='KAYNAKSIZ';'75cdf5b8'='ALINTI'
'76b64258'='ALINTI';'76d9e4a7'='BECERI-MUAF';'786b232e'='BECERI-MUAF';'79cfd988'='ALINTI'
'7c8be996'='ALINTI';'7f37c4cf'='BECERI-MUAF';'807ce029'='KAYNAKSIZ-KISMI';'811fa295'='ALINTI'
'878db482'='ALINTI';'886f0954'='ALINTI';'8c20bbeb'='ALINTI';'8efc2b13'='BECERI-MUAF'
'9100905e'='ALINTI';'94b4ce80'='ALINTI';'97e3aa99'='ALINTI';'9c03d1f1'='ALINTI'
'9d13b20a'='TEORI-SUPHELI';'9d4d9d95'='ALINTI';'9da3c8e3'='ALINTI';'9e5d1e60'='ALINTI'
'9e99f75b'='KAYNAKSIZ-KISMI';'a0b52129'='BECERI-MUAF';'a3680431'='KAYNAKSIZ-KISMI';'a3f15986'='ALINTI'
'a5096425'='BECERI-MUAF';'a6a1f40b'='ALINTI';'a831792d'='ALINTI';'a858be75'='KAYNAKSIZ-KISMI'
'aa40bdc5'='ALINTI';'aaeeafa2'='KAYNAKSIZ-KISMI';'ad27efa9'='ALINTI';'ae0b5a34'='ALINTI'
'aed86ac0'='BECERI-MUAF';'b0d2f94a'='ALINTI';'b14b7c83'='ALINTI';'b5a5e1cf'='TEORI-SUPHELI'
'bc74cec8'='ALINTI';'bcadce90'='PIVOT-KAYNAKLI';'beecdb63'='ALINTI';'c33b22f0'='KAYNAKSIZ-KISMI'
'c54e3e73'='ALINTI';'c98549e7'='KAYNAKSIZ';'ced278e8'='KAYNAKSIZ';'d048c63a'='ALINTI'
'd0822150'='ALINTI';'d0b520b5'='KAYNAKSIZ';'d1f13899'='BECERI-MUAF';'d42e87d2'='KAYNAKSIZ-KISMI'
'd4536652'='KAYNAKSIZ-KISMI';'d52bc07c'='KAYNAKSIZ';'d5f7ae92'='ALINTI';'d684d48a'='KAYNAKSIZ-KISMI'
'd8481fdc'='ALINTI';'dd672851'='KAYNAKSIZ-KISMI';'dfb2847e'='ALINTI';'e0fd432e'='KAYNAKSIZ-KISMI'
'e5e21db5'='ALINTI';'e6f0e07f'='ALINTI';'e7aafa13'='KAYNAKSIZ-KISMI';'e7c10c62'='ALINTI'
'eb6d3b8d'='ALINTI';'eca74407'='PIVOT-THP';'efd2ef69'='KAYNAKSIZ-KISMI';'f2e6c14d'='ALINTI'
'f6ea893a'='KAYNAKSIZ-KISMI';'fa647408'='BECERI-MUAF';'fa6bde73'='ALINTI';'ff838166'='ALINTI'
}

$itiraf = @(Import-Csv (Join-Path $kok 'veri\kaynak-uyumsuz-itiraf-2.csv') -Encoding UTF8)
$cikti = New-Object System.Collections.ArrayList
$eksik = 0
foreach($r in $itiraf){
  $on = "$($r.id)".Substring(0,8)
  if(-not $sinif.ContainsKey($on)){ Write-Output "SINIFSIZ: $($r.id)"; $eksik++; continue }
  [void]$cikti.Add([pscustomobject]@{ id=$r.id; ders=$r.ders; sinif=$sinif[$on] })
}
Write-Output ("itiraf {0} | siniflanan {1} | sinifsiz {2}" -f $itiraf.Count, $cikti.Count, $eksik)
$dosya = Join-Path $kok 'veri\kaynak-uyumsuz-SINIF-2.csv'
$cikti | Export-Csv $dosya -NoTypeInformation -Encoding UTF8
$cikti | Group-Object sinif | Sort-Object Count -Descending | ForEach-Object { Write-Output ("  {0,-16} {1}" -f $_.Name, $_.Count) }
Write-Output ("yazildi: {0}" -f $dosya)
