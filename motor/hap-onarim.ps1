# ============================================================================
#  HAP ONARIMI — kisa "AKILDA KALSIN" alanlarini gerekceden mekanik doldurur.
#  (30.07.2026 - kalite taramasi: 4.911 kisa hap; cogunun gercek hap icerigi
#  gerekcenin "Akılda kalsın:" bolumunde zaten YAZILI. AI GEREKMEZ - bedava.)
#
#  IKI MOD:
#    varsayilan  = KURU KOSU: yalniz sayar, hicbir sey YAZMAZ.
#                  Cikti: veri/hap-onarim-plan.json (yalniz SAYILAR - soru
#                  metni public depoya asla; ornekler yalniz Actions log'una,
#                  o da admin-kilitli).
#    UYGULA=1    = kasaya yazar (PostgREST upsert, 500'luk partiler).
#                  YALNIZ workflow_dispatch'te elle acilir - push/cron ASLA
#                  yazamaz. Yazim oncesi ayni kural seti yeniden olculur.
#
#  CIKARMA KURALLARI (nitelik kapisi - "bir sey yazmis olmak icin" yazilmaz):
#    - mevcut hap <90 karakter (kisa) VE
#    - gerekce degerlerinden birinde "Akılda kalsın:" bolumu var VE
#    - cikarilan metin >=60 karakter VE mevcut haptan UZUN.
#  ENV: SUPABASE_SERVICE_KEY (zorunlu), UYGULA=1 (yalniz yazim icin).
# ============================================================================
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$SB_URL = "https://bjrleanjpyujtajmazxn.supabase.co"
$cikti = Join-Path $kok "veri/hap-onarim-plan.json"

function Yaz($n){ [IO.File]::WriteAllText($cikti, (ConvertTo-Json -InputObject $n -Depth 5), (New-Object Text.UTF8Encoding($false))) }
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
$UYGULA = ("$env:UYGULA" -eq '1')
$BASLIK = @{ apikey = $KEY; Authorization = "Bearer $KEY" }   # $H KULLANMA: dongudeki $h ile carpisir (30.07 dersi)

$KISA_ESIK = 90; $MIN_CIKARIM = 60
# "Akılda kalsın:" sonrasi metin; varsa sonraki sablon basligina kadar.
$reAk = [regex]'(?:Akılda kalsın|AKILDA KALSIN|Akilda kalsin)\s*:\s*(.+)$'
$reKes = [regex]'\s*(?:Ne soruluyor|NE SORULUYOR|Kural|KURAL|Bu olayda|BU OLAYDA|Bu soruda)\s*:.*$'

$taranan = 0; $kisa = 0
$aday = New-Object System.Collections.Generic.List[object]   # {id; yeni}
$cikamayan = 0; $ornekYazildi = 0
$offset = 0; $sayfa = 1000
while($true){
  $u = "$SB_URL/rest/v1/soru_havuzu?select=id,hap,aciklama,yayin&order=id&limit=$sayfa&offset=$offset"
  $hw = Invoke-WebRequest -UseBasicParsing -Uri $u -Headers $BASLIK -TimeoutSec 120
  $gv = if($hw.Content -is [byte[]]){ [Text.Encoding]::UTF8.GetString($hw.Content) } else { "$($hw.Content)" }
  $parti = @(); foreach($x in (ConvertFrom-Json $gv)){ $parti += $x }
  if(-not $parti.Count){ break }
  foreach($s in $parti){
    $taranan++
    $hapM = "$($s.hap)"
    if($hapM.Trim().Length -ge $KISA_ESIK){ continue }
    $kisa++
    # gerekce degerlerinde en uzun "Akılda kalsın" bolumunu bul
    $enIyi = ''
    if($s.aciklama){
      foreach($p in $s.aciklama.PSObject.Properties){
        $m = $reAk.Match("$($p.Value)")
        if($m.Success){
          $t = $reKes.Replace($m.Groups[1].Value, '').Trim()
          if($t.Length -gt $enIyi.Length){ $enIyi = $t }
        }
      }
    }
    if($enIyi.Length -ge $MIN_CIKARIM -and $enIyi.Length -gt $hapM.Trim().Length){
      $aday.Add([pscustomobject]@{ id = "$($s.id)"; hap = $enIyi })
      if($ornekYazildi -lt 3){   # ornekler YALNIZ log'a (admin-kilitli) - dosyaya asla
        Write-Host ("ORNEK {0}: eski({1}kr) -> yeni({2}kr): {3}" -f ($ornekYazildi+1), $hapM.Trim().Length, $enIyi.Length, $enIyi.Substring(0,[Math]::Min(140,$enIyi.Length)))
        $ornekYazildi++
      }
    } else { $cikamayan++ }
  }
  $offset += $sayfa
  if($parti.Count -lt $sayfa){ break }
}
Write-Host ("taranan {0} | kisa {1} | cikarilabilen {2} | cikamayan {3}" -f $taranan, $kisa, $aday.Count, $cikamayan)

$yazilan = 0
if($UYGULA -and $aday.Count){
  Write-Host "UYGULA=1 - kasaya yaziliyor (500'luk upsert partileri)..."
  for($i=0; $i -lt $aday.Count; $i+=500){
    $grup = $aday[$i..([Math]::Min($i+499, $aday.Count-1))]
    $govde = ConvertTo-Json -InputObject ([object[]]$grup) -Depth 3
    Invoke-RestMethod -Method Post -Uri "$SB_URL/rest/v1/soru_havuzu?on_conflict=id" `
      -Headers ($BASLIK + @{ 'Content-Type'='application/json'; Prefer='resolution=merge-duplicates,return=minimal' }) `
      -Body ([Text.Encoding]::UTF8.GetBytes($govde)) -TimeoutSec 180 | Out-Null
    $yazilan += @($grup).Count
    Write-Host ("  ...{0}/{1}" -f $yazilan, $aday.Count)
  }
  # YAZMA SONRASI SAYIM (yukleyici dersi: yesil kosu != tam veri)
  $dogrulama = Invoke-WebRequest -UseBasicParsing -Uri "$SB_URL/rest/v1/soru_havuzu?select=id&hap=not.is.null&limit=1" `
    -Headers ($BASLIK + @{ Prefer='count=exact' }) -TimeoutSec 60
  Write-Host ("dogrulama - hap dolu kayit: {0}" -f (($dogrulama.Headers['Content-Range'] -split '/')[-1]))
}

Yaz ([ordered]@{
  tarih = (Get-Date -Format "dd.MM.yyyy HH:mm")
  durum = "TAMAM"; mod = $(if($UYGULA){'UYGULANDI'}else{'KURU KOSU'})
  taranan = $taranan; kisa_hap = $kisa
  cikarilabilen = $aday.Count; cikamayan = $cikamayan; yazilan = $yazilan
  kural = "hap<$KISA_ESIK kr + gerekcede 'Akılda kalsın:' bolumu >=$MIN_CIKARIM kr + mevcuttan uzun"
  not = $(if($UYGULA){"Kasaya yazildi. Cikamayan $cikamayan kayit 1 Agustos Haiku partisine kalir."}else{"KURU KOSU - hicbir sey yazilmadi. Uygulamak: Actions -> Hap Onarimi -> Run workflow -> uygula=true (yalniz elle)."})
})
Write-Host "TAMAM."
