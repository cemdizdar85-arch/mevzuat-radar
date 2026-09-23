#requires -Version 5.1
<#
================================================================================
  KONU ÖRNEKLEM KAPISI — model "HAYIR" dedi diye etiket değişmez; önce elle örneklem   23.09.2026 · bedel 0

  Cem 23.09 ("1.2.3 üçünü de yap"): model kontrolünün kısmi karnesinde DOĞRU etiketli 24 sorunun 4'üne "HAYIR",
  8'ine "KISMEN" dedi (%17 yanlış HAYIR). Kural: yeniden etiketleme yalnız "HAYIR" + ELLE ÖRNEKLEM ile yapılır.
  NASIL: aday listesinden BELİRLENİMLİ bir örneklem seçilir (model sonuç dosyasının damgası + kimlik → SHA1 sırası;
  aynı dosya → aynı örneklem, kimse "iyi olanları" seçemez). Örneklem büyüklüğü max(5, ⌈%10⌉).
  Her örneklem kaydı elle okunup DOĞRU/YANLIŞ işaretlenir (veri/sinav/smmm-konu-orneklem.json — soru metni YOK).
  Yazma izni: örneklemin TAMAMI okunmuş + YANLIŞ oranı ≤ %10 + damga aynı (model yeniden koştuysa yeni örneklem).
  YANLIŞ işaretli kayıt izin çıksa bile yazılmaz.
  🚫 GÖRMEZ: örneklem dışındaki adayların tek tek doğruluğu (örneklem oranı genellenir); okuyanın hatası.
  KULLANIM: dot-source — OrneklemSec / OrneklemKapisi. Öz-sınav: arac/konu-orneklem-kapisi-sinavi.ps1
================================================================================
#>
$script:ORNEKLEM_ORAN = 0.10; $script:ORNEKLEM_ASGARI = 5; $script:ORNEKLEM_YANLIS_TAVAN = 0.10

function OrneklemSira([string]$damga, [string]$an) {
  $sha = [Security.Cryptography.SHA1]::Create()
  try { return ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes("$damga|$an")))) } finally { $sha.Dispose() }
}

function OrneklemSec([string[]]$adaylar, [string]$damga) {
  $tekil = @($adaylar | Where-Object { "$_" } | Sort-Object -Unique)
  if (-not $tekil.Count) { return @() }
  $n = [Math]::Min($tekil.Count, [Math]::Max($script:ORNEKLEM_ASGARI, [int][Math]::Ceiling($tekil.Count * $script:ORNEKLEM_ORAN)))
  return @($tekil | Sort-Object { OrneklemSira $damga $_ } | Select-Object -First $n)
}

# $orneklem: { damga, kayitlar: [ { an, karar: BEKLİYOR|DOĞRU|YANLIŞ, okuyan, not } ] } ya da $null
function OrneklemKapisi([string[]]$adaylar, $orneklem, [string]$damga) {
  $gerek = @(OrneklemSec $adaylar $damga)
  if (-not $gerek.Count) { return [pscustomobject]@{ izin = $true; sebep = 'aday yok'; disla = @() } }
  if (-not $orneklem) { return [pscustomobject]@{ izin = $false; sebep = "örneklem yok — önce -OrneklemYaz, sonra $($gerek.Count) kayıt elle okunur"; disla = @() } }
  if ("$($orneklem.damga)" -ne $damga) { return [pscustomobject]@{ izin = $false; sebep = 'model sonucu değişti (damga farklı) — yeni örneklem gerekir'; disla = @() } }
  $karar = @{}; foreach ($k in @($orneklem.kayitlar | ForEach-Object { $_ })) { if ($k) { $karar["$($k.an)"] = "$($k.karar)" } }
  # TAM OKUMA (23.09, Cem "1.2.3" madde 2: "model yalnız aday bulsun, elle okunsun"): adayların HEPSİ okunduysa
  # oran eşiği aranmaz — her kayıt kendi kararıyla yazılır/dışlanır (örneklem genellemesi gerekmez)
  $tumAday = @($adaylar | Where-Object { "$_" } | Sort-Object -Unique)
  if (-not @($tumAday | Where-Object { $karar["$_"] -notin 'DOĞRU', 'YANLIŞ' }).Count) {
    $dislaT = @($tumAday | Where-Object { $karar["$_"] -eq 'YANLIŞ' })
    return [pscustomobject]@{ izin = $true; sebep = "tam okuma: $($tumAday.Count) aday okundu, YANLIŞ $($dislaT.Count) dışlandı"; disla = $dislaT }
  }
  $eksik = @($gerek | Where-Object { $karar["$_"] -notin 'DOĞRU', 'YANLIŞ' })
  if ($eksik.Count) { return [pscustomobject]@{ izin = $false; sebep = "örneklemde $($eksik.Count)/$($gerek.Count) kayıt okunmadı"; disla = @() } }
  $yanlis = @($gerek | Where-Object { $karar["$_"] -eq 'YANLIŞ' })
  $disla = @($karar.Keys | Where-Object { $karar[$_] -eq 'YANLIŞ' })
  if (($yanlis.Count / $gerek.Count) -gt $script:ORNEKLEM_YANLIS_TAVAN) {
    return [pscustomobject]@{ izin = $false; sebep = ("örneklemde yanlış {0}/{1} (%{2:N0}) > %{3:N0} — toplu yazma durdu" -f $yanlis.Count, $gerek.Count, (100 * $yanlis.Count / $gerek.Count), (100 * $script:ORNEKLEM_YANLIS_TAVAN)); disla = $disla }
  }
  return [pscustomobject]@{ izin = $true; sebep = "örneklem $($gerek.Count) okundu, yanlış $($yanlis.Count)"; disla = $disla }
}
