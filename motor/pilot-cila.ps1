# ============================================================================
#  PILOT CILA - 26.08.2026 (Cem onayi: "PILOT 200 ONAY BASLAT")
#
#  NE: Ayni 100 soruyu IKI modele (claude-sonnet-5 + claude-haiku-4-5) cilalatir
#      = 200 cagri. Cila = ACIKLAMA KATMANININ yeniden yazimi; soru/sik/dogru
#      cevaba DOKUNULMAZ. Kasaya YAZMAZ - cikti veri/fabrika/pilot-cila-*.json.
#
#  AMAC: (1) gercek birim fatura (ana parti fiyati kesinlessin)
#        (2) Haiku cilasi yeter mi - ayni sorularda dogrudan A/B
#        (3) cila istemi 25.08 orneklem kusur siniflarini kapatiyor mu
#
#  SECIM: ince dersler agirlikli (onarim partisinin gercek hedef kitlesi),
#  tohum sabit -> tekrarlanabilir. Istem, STANDART-ACIKLAMA + GM-OKUYUCU K-B
#  + 25.08 orneklem kusur listesinden turetildi.
#  HAT: api-hedef.ps1 / Invoke-ClaudeMesaj (Anthropic -> OpenRouter yedekli).
# ============================================================================
param([int]$SoruSayisi = 100, [int]$Tohum = 20260826, [switch]$SadeceSonnet, [string]$CiktiEk = '')
$ErrorActionPreference='Stop'
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
$PSDefaultParameterValues['Invoke-RestMethod:UserAgent']='mevzuat-radar-robot/1.0'
$here=Split-Path -Parent $MyInvocation.MyCommand.Path
$kok=Split-Path -Parent $here
. (Join-Path $here 'api-hedef.ps1')
if(-not $env:SUPABASE_SERVICE_KEY){ $env:SUPABASE_SERVICE_KEY=[Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User') }
$KEY=$env:SUPABASE_SERVICE_KEY
$H=@{apikey=$KEY; Authorization="Bearer $KEY"}
$U='https://bjrleanjpyujtajmazxn.supabase.co/rest/v1'

# ---------- 1) SECIM: ince dersler agirlikli, ders ici rastgele (tohumlu) ----------
$plan=@(
  @('Vergi Hukuku',12), @('Ticaret Hukuku',12), @('Borclar Hukuku',12),
  @('Is ve Sosyal Guvenlik Hukuku',10), @('Meslek Hukuku',10), @('Ekonomi',10),
  @('Maliye',10), @('Ataturk Ilke ve Inkilap Tarihi',6),
  @('Finansal Muhasebe',10), @('Maliyet Muhasebesi',8)
)
$rnd=New-Object System.Random($Tohum)
$secilen=New-Object System.Collections.Generic.List[object]
foreach($p in $plan){
  $ders=$p[0]; $adet=$p[1]
  $e=[uri]::EscapeDataString($ders)
  $r=@()
  foreach($deneme in 1..3){
    try{
      $r=@(Invoke-RestMethod -Uri "$U/soru_havuzu?select=id,sinav,ders,konu,soru,siklar,dogru,aciklama,hap,kaynak,kanun_no,madde_no&ders=eq.$e&order=id&limit=400" -Headers $H -TimeoutSec 120 | % { $_ })
      break
    }catch{ if($deneme -eq 3){ throw }; Start-Sleep -Seconds (3*$deneme) }
  }
  if($r.Count -eq 0){ Write-Host "  UYARI: $ders 0 kayit"; continue }
  $sec=$r | Sort-Object { $rnd.Next() } | Select-Object -First $adet
  foreach($s in $sec){ $secilen.Add($s) }
  Write-Host ("  {0,-34} havuz {1,5} -> secilen {2}" -f $ders,$r.Count,$sec.Count)
}
if($SoruSayisi -lt $secilen.Count){ $secilen=[System.Collections.Generic.List[object]]@($secilen | Select-Object -First $SoruSayisi) }
Write-Host "TOPLAM SECILEN: $($secilen.Count)"

# ---------- 2) DAYANAK METNI CEK (her soru icin, bulunamazsa bos) ----------
function DayanakMetni($s){
  try{
    if($s.kanun_no -and $s.madde_no){
      $q=[uri]::EscapeDataString("*$($s.kanun_no)*$($s.madde_no)*")
      $r=@(Invoke-RestMethod -Uri "$U/dokumanlar?select=metin&kaynak_ad=ilike.$q&limit=1" -Headers $H -TimeoutSec 30 | % { $_ })
      if($r.Count -ge 1){ return $r[0].metin }
    }
    if($s.kaynak){
      $ilk=("$($s.kaynak)" -split '[;,]')[0].Trim()
      if($ilk.Length -ge 4){
        $q=[uri]::EscapeDataString('*'+$ilk+'*')
        $r=@(Invoke-RestMethod -Uri "$U/dokumanlar?select=metin&kaynak_ad=ilike.$q&limit=1" -Headers $H -TimeoutSec 30 | % { $_ })
        if($r.Count -ge 1){ return $r[0].metin }
      }
    }
  }catch{}
  return ''
}

# ---------- 3) CILA ISTEMI ----------
$istemSablon=@'
Sen SMMM/KGK sinav sorulari icin ACIKLAMA YAZARI'sin. Asagidaki sorunun SORU METNI, SIKLARI ve DOGRU CEVABI SABITTIR - onlara dokunma, sadece ACIKLAMA katmanini ve HAP'i yeniden yaz.

PAZARLIKSIZ KURALLAR:
1. DOGRU sikkin aciklamasi DORT PARCA: "Ne soruluyor:" / "Kural:" / "Bu olayda:" / "Akilda kalsin:" basliklariyla.
2. HER YANLIS sik icin: tuzagi ADLANDIR, sikkin neden yanlis oldugunu anlat ve "Dogrusu:" cumlesiyle dogru bilgiyi ver. "Bu sik yanlistir cunku dogrusu X" gibi ogretmeyen kalip YASAK.
2a. TUZAK ADLANDIRMA PALETI: "TUZAK" kelimesini bir soruda EN FAZLA BIR kez kullan; diger yanlis siklarda tuzagi DOGAL kaliplarla adlandir ve ayni kalibi bir soruda tekrarlama. Palet: "Bu sik X ile Y'yi karistiriyor" / "X'i Y sanan ogrenci bu sikki secer" / "Buradaki yanilgi ..." / "Bu deger, ...'i unutanin bulacagi sonuctur" / "Sik yapilan hata: ..." / "... zannedilirse bu sik cazip gorunur". Her aciklama farkli nefes alsin - ayni cumle iskeletiyle baslayan iki sik aciklamasi YASAK.
2b. OLUMSUZ KOKLU SORU ISTISNASI ("hangisi YANLIStir / degildir / soylenemez / yer almaz" tipli soru): isaretlenMEyen siklar DOGRU ifadelerdir - onlara TUZAK etiketi ve "Dogrusu:" YAZILMAZ; her birinde ifadenin neden DOGRU oldugu 1-2 cumleyle anlatilir. Dort parca duzeni ve tuzak analizi bu soru tipinde ISARETLI (dogru cevap olan) sikkin aciklamasinda kurulur.
3. HESAPLI soruda her yanlis sikkin gerekcesi O SIKKIN RAKAMINI TURETMELI ("30.000 yazan ogrenci amortismani dusmayi unutmustur: 50.000-20.000=30.000"). Rakami turetilemeyen celdirici icin acikca "Bu deger sorudaki verilerden turetilemez; rastgele celdiricidir" yaz - UYDURMA turetim YASAK. ISRAR ETME: bir celdiriciyi EN COK IKI farkli hata senaryosuyla dene; ikisinde de cikmiyorsa "turetilemez" yazip GEC - uzun deneme dongusu kurma.
4. KAYNAK metni verildiyse hukuki iddialar SADECE o metne dayanir; kaynak metninde olmayan oran/sure/rakam EKLEME. Kaynak verilmediyse mevcut aciklamadaki hukuki iddialari koru, yenisini ekleme.
5. IC MONOLOG YASAK: "dur", "kontrol edeyim", "tersine muhendislik", "o halde cevap X olmali" gibi cozum-sureci cumleleri ASLA yazma. Ogrenciye konusan bitmis metin yaz.
6. DIL: "kar" kelimesi kazanc anlaminda hep sapkali ("kâr", "kâra", "kârin"). Uydurma sikistirilmis terim yasak ("cok donemli gider" degil "gelecek aylara/yillara ait giderler"). Resmi terimleri kullan.
6b. TERIM TERCIHI - SINAV DILI ESASTIR: ogrencinin sinav kitapciginda gorecegi GUNCEL terim ana terimdir; kanun metni eski/farkli terim kullaniyorsa kanun terimi YALNIZCA BIR KEZ parantezle verilir. Ornek: "genel uretim giderleri (VUK m.275'teki adiyla 'genel imal giderleri')" DOGRU; "genel imal (uretim) giderleri" YANLIS - eski terimi ana terim yapmak yasak. Ayni kural tum eski kanun dili icin gecerli (emtia->ticari mal, iptidai madde->ilk madde ve malzeme vb.).
6b-2. TERIM KOPRUSU OGRETIR (Cem 26.08): kilit terimin ILK gecisinde karsiliklarini parantezle OGRET - ogrenci hangi adla karsilasirsa karsilassin tanisin: "genel uretim giderleri (kanundaki adiyla 'genel imal giderleri'; THP 730)" · "genel idare giderleri (THP'de 770 Genel Yonetim Giderleri)". Muhasebe konusunda THP hesap karsiligi da verilir. Kopru YALNIZ ilk geciste kurulur; sonraki gecislerde tek terim (sinav dili) kullanilir - her cumlede parantez tekrarı yasak.
6c. ESKI KANUN CUMLESI AYNEN TASINMAZ: kanundaki arkaik ifadeler aciklamada MODERN Turkceyle soylenir - "mamulun vucuda getirilmesinde sarf olunan" DEGIL "mamulun uretiminde kullanilan"; "ihtiva eder" DEGIL "icerir"; "tayin edebilirler" DEGIL "belirleyebilirler"; "zaruri" DEGIL "zorunlu". Kanunun birebir sozunu aktarmak GEREKIYORSA tirnak icinde BIR kez verilir ve hemen ardindan sade karsiligi soylenir. Olcut: 20 yasindaki aday cumleyi ilk okuyusta anlamali.
6d. TON BANDI - IKI UC DA YASAK: arkaik kanun dili yasak (6c) AMA gunluk konusma/sokak agzi da yasak: "iste ekle iste ekleme" DEGIL "maliyete katilmasi istege baglidir (ihtiyari)"; "atlanamaz" gibi kaba kisaltmalar yerine "maliyet disinda birakilamaz". Hedef ton: sade, profesyonel ders anlatimi - bir SMMM'nin staja giren asistanina anlatisi gibi; ne resmi gazete ne kahve sohbeti.
7. HAP: 2-3 cumle, sorunun oğrettigi KURALI ve EN BUYUK TUZAGI ozetler; soruya degil kurala odakli.
7b. OZLULUK: her yanlis sik aciklamasi 60-90 kelime, dogru sik aciklamasi en cok 140 kelime. Sisirme merit DEGILDIR - ayni bilgiyi iki kez soyleme, ogrenci 5 aciklamayi sinav arasinda okuyabilmeli.
7c. SINAV TAKTIGI: "sinav_taktigi" alanina TEK cumle yaz - bu soru TIPINDE gercek sinavda zaman kazandiran somut taktik ("Bu tip soruda once verilen tutarlari isaretle, siklara bakmadan kendi sonucunu bul" gibi). Genel geçer laf YASAK ("dikkatli oku" yazma), tipe ozel ol.
7d. DAYANAK: "dayanak" alanina sorunun dayandigi kaynagi kisa kunye olarak yaz (orn. "VUK m.275" / "TTK m.483/3" / "TMS 16 p.30" / "BDS 315 p.A21"). YALNIZCA sana verilen KAYNAK METNI'nin kunyesinden veya mevcut aciklamada gecen atiftan al - kendin kaynak UYDURMA; emin degilsen bos birak.
7e. COZUM TABLOSU: SORU HESAPLIYSA "cozum_tablo" alanina cozumu tablo olarak koy: {"basliklar":["Kalem","Tutar"],"satirlar":[["Ilk madde",127680],...]} bicimi. Yevmiye gerekiyorsa satirlar borc/alacak kolonlu olsun. Hesapsiz soruda ve akis-mantikli konuda (surec/asama ogreten soru) "akis" alanina 3-6 adimlik ok-listesi koy: ["Once X","Sonra Y","Karar: Z"]. Ikisi de uymuyorsa iki alani da bos birak - ZORAKI tablo/akis uydurma.
7f. NOTLANDIRICI GOZU: "notlandirici" alanina TEK-IKI cumle yaz - bu soru TIPINDE adaylarin en cok nereden puan kaybettigi (Ingiliz examiner-report gelenegi: "adaylar cogunlukla X'i Y ile karistirir ve ikinci adimi atlar" gibi). Sorunun kendi tuzagindan GENELLE - soru tipine dair konus, bu soruya ozel cozumu tekrarlamak YASAK.
7h. KAVRAM KAPISI (Cem 27.08 - "hic bilmeyene ogretecegiz"): dogru sikkin "Kural:" parcasinin ILK cumlesi, dayanagin KIMLIGINI sade dille tanitir - "BDS 500, 'Denetim Kaniti' standardidir; denetcinin gorusune dayanak olacak delillerin nasil toplanacagini duzenler" gibi. Standart/kanun adini bilmeyen aday o cumleyle konuya girer. Paragraf/madde numarasi TEK BASINA anilmaz; once kavram adi, parantezde numara: "orneklemenin amaci hukmu (A67)". Teknik jargon (anakitle, testlet, rucu...) ilk geciste yarim-cumle tanimla acilir: "anakitle (denetlenen kalemlerin tamami)".
7i. TAKTIK SORUDAN KONUSUR: sinav_taktigi SINAV ANINDA uygulanabilir olmali (elde kaynak metni yokmus gibi); ornek verilecekse SORUNUN GERCEK ifadesinden verilir - soru disindan ornek uydurmak YASAK.
7g. GOVDE IHBARI (dokunma, isaretle): SORU METNININ KENDISINDE anlami bozan bir kusur gorursen - arkaik kanun dili ("vucuda getirilmek", "iptidai" gibi), bozuk/anlasilmaz cumle, ASCII'lesmis Turkce, ic monolog kacagi - "govde_kusuru" alanina TEK cumleyle yaz (orn. "govdede 'sarf olunan' arkaik ifadesi var"). Soru metnini DEGISTIRMEK senin isin degil; kusur yoksa alani bos birak. Uslup begenisi ihbar edilmez, yalniz ANLAMA engel olan yazilir.
8. Yanit YALNIZCA su JSON (baska hicbir sey yazma):
{"aciklama":{"A":"...","B":"...","C":"...","D":"...","E":"..."},"hap":"...","sinav_taktigi":"...","dayanak":"...","notlandirici":"...","cozum_tablo":{"basliklar":[],"satirlar":[]},"akis":[],"govde_kusuru":"","supheli_cevap":false,"supheli_not":""}
Eger dogru isaretlenen cevabin YANLIS oldugunu dusunuyorsan aciklamayi yine isaretli cevaba gore yaz AMA "supheli_cevap":true yap ve "supheli_not"a tek cumlelik gerekceni yaz.

=== SORU (ders: {DERS} | konu: {KONU}) ===
{SORU}

SIKLAR:
{SIKLAR}

ISARETLI DOGRU CEVAP: {DOGRU}

MEVCUT ACIKLAMA (yetersiz - yeniden yazilacak):
{ESKI}

KAYNAK METNI:
{KAYNAK}
'@

function IstemKur($s,$dayanak){
  $sik=@(); foreach($k in 'A','B','C','D','E'){ if($s.siklar.PSObject.Properties[$k] -and $s.siklar.$k){ $sik+="$k) $($s.siklar.$k)" } }
  $eski=@(); foreach($k in 'A','B','C','D','E'){ if($s.aciklama -and $s.aciklama.PSObject.Properties[$k]){ $eski+="$k) $($s.aciklama.$k)" } }
  $kay = if([string]::IsNullOrWhiteSpace($dayanak)){'(kaynak metni bulunamadi - kural 4 ikinci cumle gecerli)'} else { $dayanak.Substring(0,[Math]::Min(3000,$dayanak.Length)) }
  $t=$istemSablon
  $t=$t.Replace('{DERS}',"$($s.ders)").Replace('{KONU}',"$($s.konu)").Replace('{SORU}',"$($s.soru)")
  $t=$t.Replace('{SIKLAR}',($sik -join "`n")).Replace('{DOGRU}',"$($s.dogru)")
  $t=$t.Replace('{ESKI}',($eski -join "`n")).Replace('{KAYNAK}',$kay)
  return $t
}

# ---------- 4) KOSU: ayni sorular x iki model ----------
$modeller=@('claude-sonnet-5','claude-haiku-4-5')
if($SadeceSonnet){ $modeller=@('claude-sonnet-5') }
$sonuc=New-Object System.Collections.Generic.List[object]
$sayac=@{}
foreach($m in $modeller){ $sayac[$m]=@{girdi=0;cikti=0;hata=0;tamam=0} }
$n=0
foreach($s in $secilen){
  $n++
  $dayanak=DayanakMetni $s
  $istem=IstemKur $s $dayanak
  foreach($model in $modeller){
    try{
      $r=$null
      foreach($deneme in 1..3){
        try{ $r=Invoke-ClaudeMesaj -Model $model -Icerik $istem -MaxTok 3500; break }
        catch{ if($deneme -eq 3){ throw }; Start-Sleep -Seconds (5*$deneme) }
      }
      $sayac[$model].girdi+=[int]$r.girdi; $sayac[$model].cikti+=[int]$r.cikti; $sayac[$model].tamam++
      $ham=$r.metin.Trim()
      # JSON disi sargi temizligi (```json ... ```)
      $ham=$ham -replace '^```json\s*','' -replace '^```\s*','' -replace '\s*```$',''
      $parse=$null; try{ $parse=$ham | ConvertFrom-Json }catch{}
      $sonuc.Add([pscustomobject]@{
        id=$s.id; ders=$s.ders; konu=$s.konu; model=$model; kaynakHat=$r.kaynak
        dayanakVar=(-not [string]::IsNullOrWhiteSpace($dayanak))
        girdiTok=$r.girdi; ciktiTok=$r.cikti; dur=$r.dur
        jsonGecerli=($null -ne $parse)
        cikti=$(if($parse){$parse}else{$ham})
      })
    }catch{
      $sayac[$model].hata++
      $sonuc.Add([pscustomobject]@{ id=$s.id; ders=$s.ders; model=$model; hata="$($_.Exception.Message)" })
    }
  }
  if($n % 10 -eq 0){ Write-Host ("  ...{0}/{1} soru (S5: {2} ok/{3} hata | H45: {4} ok/{5} hata)" -f $n,$secilen.Count,$sayac['claude-sonnet-5'].tamam,$sayac['claude-sonnet-5'].hata,$sayac['claude-haiku-4-5'].tamam,$sayac['claude-haiku-4-5'].hata) }
}

# ---------- 5) FATURA + KAYIT ----------
# Liste fiyat (USD/1M): Sonnet 5 tanitim $2/$10 (31.08'e kadar), Haiku 4.5 $1/$5. OpenRouter batch yok.
$fiyat=@{ 'claude-sonnet-5'=@{g=2.0;c=10.0}; 'claude-haiku-4-5'=@{g=1.0;c=5.0} }
$rapor=[ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); tohum=$Tohum; soru=$secilen.Count; model=@{} }
Write-Host ''
Write-Host '======== PILOT FATURA ========'
foreach($m in $modeller){
  $g=$sayac[$m].girdi; $c=$sayac[$m].cikti
  $usd=[math]::Round(($g*$fiyat[$m].g + $c*$fiyat[$m].c)/1e6, 3)
  $rapor.model[$m]=@{ tamam=$sayac[$m].tamam; hata=$sayac[$m].hata; girdiTok=$g; ciktiTok=$c; tahminiUSD=$usd }
  Write-Host ("  {0,-18} tamam {1,3} / hata {2}  girdi {3:N0} tok  cikti {4:N0} tok  = ~{5} USD (liste)" -f $m,$sayac[$m].tamam,$sayac[$m].hata,$g,$c,$usd)
}
$rapor.sonuclar=$sonuc
$yol=Join-Path $kok ("veri\fabrika\pilot-cila-20260826$CiktiEk.json")
$rapor | ConvertTo-Json -Depth 8 | Out-File $yol -Encoding utf8
Write-Host "-> $yol"
Write-Host 'KASAYA YAZILMADI - cikti yalniz dosyada; sirada okuyucu denetimi var.'
