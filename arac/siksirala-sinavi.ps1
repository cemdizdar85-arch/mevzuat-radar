# arac/siksirala-sinavi.ps1 — SikSirala + HarfTasi öz-sınavı (30.09.2026, Cem "1.2.3"). İşlevler üreticiden AST ile çıkarılır; üretici ÇALIŞTIRILMAZ.
# Olay: eski SikSirala şıkları sıralarken teşhis / çeldirici yolu / sade.siklar'ı taşımıyor, hashtable açıklamayı hiç taşımıyordu →
#   "Ne soruluyor" metni yanlış harfte (bankada 233 kayma; 47'si sıralanmış sayısal şıklı, kalanın kökü ölçülmedi).
# Mutasyon (30.09, düzeltme öncesi sürüme karşı): 5/9 → KIRMIZI (teşhis, çeldirici, sade, hashtable vakaları düşüyor).
# 🚫 GÖRMEZ: SikSirala'nın çağrılmadığı yoldan gelen kayma; adımlar içindeki harf atıfları ("B şıkkı").
$ErrorActionPreference='Stop'
$yol=Join-Path (Split-Path -Parent $PSScriptRoot) 'motor/kalip-parti-uret.ps1'
if($env:SIKSIRALA_YOL){ $yol=$env:SIKSIRALA_YOL }   # yalnız mutasyon provası için
$ast=[System.Management.Automation.Language.Parser]::ParseFile($yol,[ref]$null,[ref]$null)
foreach($ad in 'SikSirala','HarfTasi'){ $f=$ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq $ad },$true) | Select-Object -First 1; if(-not $f){ "işlev yok: $ad"; exit 1 }; . ([scriptblock]::Create($f.Extent.Text)) }
$gec=0; $top=0
function T($ad,$ok){ $script:top++; if($ok){ $script:gec++; "  ✓ $ad" } else { "  ✗ $ad" } }
$j='{"siklar":{"A":"50","B":"40","C":"30","D":"20","E":"10"},"dogru":"A","aciklama":{"A":"Ne soruluyor: 50","B":"40 buldun","C":"30 buldun","D":"20 buldun","E":"10 buldun"},"teshis":{"A":{"y":"a"},"B":{"y":"b40"},"C":{"y":"c30"},"D":{"y":"d20"},"E":{"y":"e10"}},"celdirici_yol":{"B":"yol40","C":"yol30","D":"yol20","E":"yol10"},"sade":{"dogru":"x","siklar":{"B":"s40","C":"s30","D":"s20","E":"s10"}}}'
$c=ConvertFrom-Json $j
$r=SikSirala $c
T 'sıralandı' ($r -eq $true)
T 'şıklar artan' ("$($c.siklar.A),$($c.siklar.E)" -eq '10,50')
T 'doğru E oldu' ($c.dogru -eq 'E')
T "aciklama taşındı (Ne soruluyor E'de)" ($c.aciklama.E -like 'Ne soruluyor*' -and $c.aciklama.A -eq '10 buldun')
T 'teşhis taşındı' ($c.teshis.A.y -eq 'e10' -and $c.teshis.E.y -eq 'a')
T "çeldirici yolu taşındı (E yok → A'da yol10)" ($c.celdirici_yol.A -eq 'yol10' -and $c.celdirici_yol.D -eq 'yol40' -and -not $c.celdirici_yol.PSObject.Properties['E'])
T 'sade.siklar taşındı' ($c.sade.siklar.A -eq 's10' -and $c.sade.siklar.B -eq 's20' -and $c.sade.dogru -eq 'x')
$h=[pscustomobject]@{ siklar=[pscustomobject]@{A='3';B='1';C='2';D='5';E='4'}; dogru='B'; aciklama=[ordered]@{A='3 buldun';B='Ne soruluyor: 1';C='2 buldun';D='5 buldun';E='4 buldun'} }
[void](SikSirala $h)
T 'hashtable aciklama taşındı' ($h.dogru -eq 'A' -and "$($h.aciklama['A'])" -like 'Ne soruluyor*' -and "$($h.aciklama['C'])" -eq '3 buldun')
$z=ConvertFrom-Json '{"siklar":{"A":"1","B":"2","C":"3","D":"4","E":"5"},"dogru":"C","aciklama":{"C":"Ne soruluyor"}}'
T 'sıralı soruya dokunmaz' ((SikSirala $z) -eq $false -and $z.dogru -eq 'C')
"SIKSIRALA-SINAVI: $(if($gec -eq $top){'YESIL'}else{'KIRMIZI'}) — $gec/$top"
if($gec -ne $top){ exit 1 }
