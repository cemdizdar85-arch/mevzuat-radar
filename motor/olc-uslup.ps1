# ============================================================================
#  USLUP OLCUMU - kasadaki sorular "baglayici senaryo" mu "kuru kalip" mi?
#  (Cem 31.07: "komik/dikkat ceken sorular yaptilar mi yapmadilar mi olcelim")
#  Ornekleme: yayindaki + bekleyen sorulardan parcali kesitler. YALNIZ SAYI
#  doker - ucretli soru metni CI loguna YAZILMAZ (gizlilik kurali).
#  ENV: SUPABASE_SERVICE_KEY
# ============================================================================
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$U = "https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/soru_havuzu"
$SB = @{ apikey = $env:SUPABASE_SERVICE_KEY; Authorization = "Bearer $($env:SUPABASE_SERVICE_KEY)" }

function Olc([string]$filtre, [string]$etiket){
  $topla = @()
  foreach($ofs in @(0, 800, 1900, 3100, 4300)){
    try {
      $w = Invoke-WebRequest -Uri "${U}?select=soru&$filtre&limit=60&offset=$ofs&order=id" -Headers $SB -UseBasicParsing -TimeoutSec 90
      $ham = [Text.Encoding]::UTF8.GetString($w.RawContentStream.ToArray())
      $topla += @($ham | ConvertFrom-Json)
    } catch {}
  }
  if(-not $topla.Count){ Write-Host "$etiket : ornek cekilemedi"; return }
  $unvanli=0; $isimli=0; $rakamli=0; $kuruVaka=0; $ayniBaslangic=0
  foreach($s in $topla){
    $t = "$($s.soru)"
    $u = $t -match '(Ltd|A\.Ş|Şti|San\.|Tic\.)'
    $i = $t -match '\b(Usta|Bey|Hanım|Mehmet|Ayşe|Mustafa|Fatma|Hatice|Ahmet|Hasan|Hüseyin|Emine|Zeynep|Ramazan|Osman|Kemal|Elif|Murat|Serpil|Nurten|Kadir)\b'
    $r = $t -match '\d{1,3}(\.\d{3})+'
    if($u){ $unvanli++ }; if($i){ $isimli++ }; if($r){ $rakamli++ }
    if($r -and -not $u -and -not $i){ $kuruVaka++ }
    if($t -match '^(Aşağıdakilerden|Asagidakilerden|Hangisi|Aşağıdaki)'){ $ayniBaslangic++ }
  }
  $n = $topla.Count
  Write-Host ("{0} : n={1} | unvanli %{2} | isimli %{3} | rakamli %{4} | rakamli-ama-KIMSESIZ(kuru vaka) %{5} | 'Asagidakilerden...' baslangici %{6}" -f `
    $etiket, $n, [math]::Round($unvanli*100/$n), [math]::Round($isimli*100/$n), [math]::Round($rakamli*100/$n), [math]::Round($kuruVaka*100/$n), [math]::Round($ayniBaslangic*100/$n))
}

Olc "yayin=eq.true" "YAYINDA"
Olc "yayin=eq.false" "BEKLEYEN"

# cevap logu nabzi (31.07 kuruldu): kac kayit dustu? (yalniz sayi)
try {
  $wc = Invoke-WebRequest -Uri "https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/cevap_kaydi?select=id&limit=1" `
    -Headers ($SB + @{ Prefer = "count=exact" }) -Method Head -UseBasicParsing -TimeoutSec 60
  Write-Host ("CEVAP LOGU: {0} kayit" -f (($wc.Headers['Content-Range'] -split '/')[-1]))
} catch { Write-Host "CEVAP LOGU: okunamadi ($($_.Exception.Message))" }
