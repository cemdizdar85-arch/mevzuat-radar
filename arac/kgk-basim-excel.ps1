# ============================================================================
#  KGK SINAV KAYNAK + BASIM EXCEL'İ — 16.09.2026
#  Cem 15.09: "kgk için … çıkmış sorular ve dersler … sonra biz bunları yutmuş muyuz … ne kadar soru basalım".
#
#  NE ÜRETİR (7 sayfa): modül özeti · kanun/standart · plan konuları · yutulmayanlar · çıkmış konu etiketleri ·
#  nasıl hesaplandı · 2022 öncesi-sonrası kıyası.
#  GİRDİ (hepsi ölçülmüş, yazma yok): veri/kgk-analiz.json (29 dönem çıkmış soru) · veri/kgk-kaynak-olcumu.json ·
#  veri/kgk-hakikat-olcumu.json (standart tamlığı) · veri/kgk-mevzuat-tamlik.json (tebliğ/yönetmelik tamlığı) ·
#  veri/kgk-uretim-kotasi.json · veri/fabrika/kosucu-log/kgk-kaynak-adlar.json.
#  Bedel 0, model yok. Excel COM ile yazılır (bu makinede Office var).
#  Kullanım: powershell -NoProfile -File arac/kgk-basim-excel.ps1 [-ModulBanka 400] [-Cikti <yol>] [-ExcelYok]
# ============================================================================param([int]$ModulBanka = 400, [string]$Cikti = 'C:\Users\cemdi\OneDrive\Masaüstü\KGK-Sinav-Kaynak-Basim-Plani.xlsx', [switch]$ExcelYok)
$ErrorActionPreference = 'Stop'
$depoKok = Split-Path -Parent $PSScriptRoot
$sp = Join-Path ([IO.Path]::GetTempPath()) 'kgk-basim-excel'; New-Item -ItemType Directory -Force $sp | Out-Null
$USD_SORU = 0.11
function Katla([string]$metin){ $m=$metin.ToLowerInvariant(); foreach($cift in @(@('i̇','i'),@('ı','i'),@('ş','s'),@('ğ','g'),@('ü','u'),@('ö','o'),@('ç','c'),@('â','a'),@('î','i'),@('û','u'))){ $m=$m.Replace($cift[0],$cift[1]) }; return $m }

$olcum = Get-Content "$depoKok\veri\kgk-kaynak-olcumu.json" -Raw -Encoding UTF8 | ConvertFrom-Json
$kota  = Get-Content "$depoKok\veri\kgk-uretim-kotasi.json" -Raw -Encoding UTF8 | ConvertFrom-Json
$arsiv = Get-Content "$depoKok\veri\kgk-analiz.json" -Raw -Encoding UTF8 | ConvertFrom-Json
$adlar = Get-Content "$depoKok\veri\fabrika\kosucu-log\kgk-kaynak-adlar.json" -Raw -Encoding UTF8 | ConvertFrom-Json
$ambarAdlari = @($adlar | ForEach-Object { "$($_.kaynak_ad)" })

$dersAdi=@{ 'Muhasebe Standartlari'='a) Türkiye Muhasebe Standartları'; 'Denetim Standartlari'='b) Türkiye Denetim Standartları'; 'Kurumsal Yonetim'='c) Kurumsal Yönetim İlkeleri ve Finansal Yönetim'; 'Finansal Yonetim'='c) Kurumsal Yönetim İlkeleri ve Finansal Yönetim'; 'Sermaye Piyasasi Mevzuati'='ç) Sermaye Piyasası Mevzuatı'; 'Bankacilik Mevzuati'='d) Bankacılık Mevzuatı'; 'Sigortacilik ve Ozel Emeklilik Mevzuati'='e) Sigortacılık ve Özel Emeklilik Mevzuatı'; 'Surdurulebilirlik Raporlamasi'='f) Kurumsal Sürdürülebilirlik Raporlaması'; 'Surdurulebilirlik Denetimi'='g) Sürdürülebilirlik Denetimi' }
$modulAdi=@{ 'a) Türkiye Muhasebe Standartları'='1) Türkiye Muhasebe Standartları'; 'b) Türkiye Denetim Standartları'='2) Türkiye Denetim Standartları'; 'c) Kurumsal Yönetim İlkeleri ve Finansal Yönetim'='3) Kurumsal Yönetim İlkeleri ve Finansal Yönetim'; 'ç) Sermaye Piyasası Mevzuatı'='4) Sermaye Piyasası Mevzuatı'; 'd) Bankacılık Mevzuatı'='5) Bankacılık Mevzuatı'; 'e) Sigortacılık ve Özel Emeklilik Mevzuatı'='6) Sigortacılık ve Özel Emeklilik Mevzuatı'; 'f) Kurumsal Sürdürülebilirlik Raporlaması'='7) Kurumsal Sürdürülebilirlik (Raporlama + Denetim)'; 'g) Sürdürülebilirlik Denetimi'='7) Kurumsal Sürdürülebilirlik (Raporlama + Denetim)' }

# ---------------- kaynak kütüğü: kod -> okunur ad + (ölçülmemişse) ambar ad deseni
$kaynakAdi=@{ 'BDY'='Bağımsız Denetim Yönetmeliği'; '660 KHK'='660 sayılı KHK (KGK teşkilat)'; 'ETIK'='Bağımsız Denetçiler için Etik Kurallar'; 'KYS 1'='KYS 1 Kalite Yönetim Standardı'; 'II-17.1'='SPK Kurumsal Yönetim Tebliği (II-17.1)'; 'FY-TEORI'='Finansal Yönetim (kanun/standart metni yok)'; 'KY-TEORI'='Kurumsal Yönetim teori notu'; '6361'='6361 s. Finansal Kiralama, Faktoring ve Finansman Şirketleri K.'; '6362'='6362 s. Sermaye Piyasası Kanunu'; 'BORSA-YON'='Borsa İstanbul / borsacılık yönetmeliği'; 'II-5.2'='SPK Satış Tebliği (II-5.2)'; 'II-5.1'='SPK İzahname ve İhraç Belgesi Tebliği (II-5.1)'; 'VII-128.8'='SPK Borçlanma Araçları Tebliği (VII-128.8)'; 'II-18.1'='SPK Kayıtlı Sermaye Sistemi Tebliği (II-18.1)'; '5411'='5411 s. Bankacılık Kanunu'; 'VYS-YON'='Varlık Yönetim Şirketleri Yönetmeliği'; 'BBD-YON'='Bankaların Bağımsız Denetimi Hakkında Yönetmelik'; 'KREDI-YON'='Bankaların Kredi İşlemlerine İlişkin Yönetmelik'; 'BANKA-THP'='Bankalar Tek Düzen Hesap Planı'; 'SY-YON'='Bankaların Sermaye Yeterliliği Yönetmeliği'; 'KSK-YON'='Kredi Sınıflandırma ve Karşılıklar Yönetmeliği'; 'SORUNLU-REH'='BDDK Sorunlu Alacak Çözümleme Rehberi'; 'IC-SIS-BANKA'='Bankaların İç Sistemleri ve ICAAP Yönetmeliği'; '5684'='5684 s. Sigortacılık Kanunu'; '4632'='4632 s. Bireysel Emeklilik Kanunu'; 'TK-YON'='Sigorta Teknik Karşılıklar Yönetmeliği'; 'TTK-SORUMLULUK'='TTK sorumluluk sigortası hükümleri'; 'TTK-HAYAT'='TTK hayat sigortası hükümleri'; 'IC-SIS-SIGORTA'='Sigortacılık ve Özel Emeklilik İç Sistemler Yönetmeliği'; 'DEVLET-KATKI-YON'='BES Devlet Katkısı Yönetmeliği'; 'TSRS-KAPSAM'='TSRS kapsam Kurul kararı'; 'SGDS 5000'='SGDS 5000 (TASLAK)'; 'BOBI FRS'='BOBİ FRS'
 'KAVRAMSAL'='Finansal Raporlamaya İlişkin Kavramsal Çerçeve'; 'KUMI FRS'='KÜMİ FRS'; 'GENEL-MUH'='Genel muhasebe kayıtları (MSUGT / THP / VUK değerleme)'; 'MALIYET'='Maliyet muhasebesi (teori; kanun/standart metni yok)'; 'FIN-ANALIZ'='Finansal tablolar analizi (teori; kanun/standart metni yok)'
 'SBDS 2400'='SBDS 2400/2410 Sınırlı Bağımsız Denetim'; 'II-15.1'='SPK Özel Durumlar Tebliği (II-15.1)'; 'II-14.1'='SPK Finansal Raporlama Tebliği (II-14.1)'; 'SPK-BD'='SPK Bağımsız Denetim Standartları Tebliği (Seri X No 22)'; 'VII-128.1'='SPK Pay Tebliği (VII-128.1)'; 'VII-128.3'='SPK Varant ve Yatırım Kuruluşu Sertifikaları Tebliği (VII-128.3)'; 'III-52.1'='SPK Yatırım Fonları Tebliği (III-52.1)'; 'III-55.1'='SPK Portföy Yönetim Şirketleri Tebliği (III-55.1)'; 'EYF-YON'='Emeklilik Yatırım Fonları Yönetmeliği'; 'III-48.1'='SPK GYO Tebliği (III-48.1)'; 'III-48.5'='SPK Menkul Kıymet Yatırım Ortaklıkları Tebliği (III-48.5)'; 'III-48.3'='SPK Girişim Sermayesi Yatırım Ortaklıkları Tebliği (III-48.3)'; 'III-37.1'='SPK Yatırım Hizmetleri Tebliği (III-37.1)'; 'III-39.1'='SPK Yatırım Kuruluşları Kuruluş ve Faaliyet Tebliği (III-39.1)'; 'III-61.1'='SPK Kira Sertifikaları Tebliği (III-61.1)'; 'III-58.1'='SPK Varlığa/İpoteğe Dayalı Menkul Kıymetler Tebliği (III-58.1)'; 'III-59.1'='SPK Teminatlı Menkul Kıymetler Tebliği (III-59.1)'; 'II-26.1'='SPK Pay Alım Teklifi Tebliği (II-26.1)'; 'II-23.2'='SPK Birleşme ve Bölünme Tebliği (II-23.2)'; 'II-13.1'='SPK Kaydileştirme Tebliği (II-13.1)'; 'TAKAS-YON'='Merkezi takas / saklama yönetmelikleri'; 'YTM-YON'='Yatırımcı Tazmin Merkezi Yönetmeliği'; 'III-35/A.2'='SPK Kitle Fonlaması Tebliği'; 'LISANS-YON'='SPK Lisanslama ve Sicil Tutma Tebliği'; 'DERECE-YON'='Derecelendirme faaliyetleri düzenlemesi'; 'DEGERLEME'='Değerleme hizmetleri düzenlemesi'; 'III-62.1'='SPK Bilgi Sistemleri Tebliği (III-62.1/62.2)'; 'BILGI-SIS-BANKA'='Bankaların Bilgi Sistemleri ve Elektronik Bankacılık Yönetmeliği'; 'OZKAYNAK-YON'='Bankaların Özkaynaklarına İlişkin Yönetmelik'; 'DERECE-BANKA'='Derecelendirme kuruluşları yönetmeliği'; '5464'='5464 s. Banka Kartları ve Kredi Kartları K.'; '6493'='6493 s. Ödeme Hizmetleri K.'; 'TTK-SIGORTA'='TTK sigorta hukuku (m.1401–1520)'; 'SIGORTA-THP'='Sigortacılık hesap planı / finansal raporlama'; 'ZORUNLU-SIG'='Zorunlu sigortalar (DASK / trafik)'; 'SURD-DEN-YON'='Sürdürülebilirlik denetimi yönetmeliği / kurul kararı'; 'SIGORTA-ACENTE'='Sigorta acenteleri / brokerler / eksperler yönetmelikleri' }
$ekDesen=@{ 'KAVRAMSAL'='Kavramsal [ÇC]er[çc]eve'; 'KUMI FRS'='^K[ÜU]M[İI] FRS'; 'GENEL-MUH'='MUHASEBE S[İI]STEM[İI] UYGULAMA GENEL TEBL'; 'MALIYET'='(?!)'; 'FIN-ANALIZ'='(?!)'; 'SBDS 2400'='^SBDS 24'; 'II-15.1'='II-15\.1'; 'II-14.1'='II-14\.1'; 'SPK-BD'='Seri: X, No: 22'; 'VII-128.1'='VII-128\.1\b'; 'VII-128.3'='VII-128\.3'; 'III-52.1'='III-52\.1'; 'III-55.1'='III-55\.1'; 'EYF-YON'='Emeklilik Yat[ıi]r[ıi]m Fonlar[ıi]n[ıi]n Kurulu'; 'III-48.1'='III-48\.1'; 'III-48.5'='III-48\.5'; 'III-48.3'='III-48\.3'; 'III-37.1'='III-37\.1'; 'III-39.1'='III-39\.1'; 'III-61.1'='III-61\.1'; 'III-58.1'='III-58\.1'; 'III-59.1'='III-59\.1'; 'II-26.1'='II-26\.1'; 'II-23.2'='II-23\.2'; 'II-13.1'='II-13\.1'; 'TAKAS-YON'='Takas'; 'YTM-YON'='Yat[ıi]r[ıi]mc[ıi] Tazmin'; 'III-35/A.2'='III-35/A'; 'LISANS-YON'='Lisanslama|III-40\.2'; 'DERECE-YON'='Derecelendirme'; 'DEGERLEME'='De[ğg]erleme (Kurulu|Hizmet)|III-62\.3'; 'III-62.1'='III-62\.[12]'; 'OZKAYNAK-YON'='[ÖO]zkaynaklar[ıi]na [İI]li[şs]kin Y|Ozkaynaklari Yonetmeli'; 'DERECE-BANKA'='Derecelendirme'; '5464'='5464 s\.K'; '6493'='6493 s\.K'; 'TTK-SIGORTA'='^TTK \(6102 s\.K\.\) m\.1(4\d\d|5[0-2]\d)\b'; 'SIGORTA-THP'='Sigorta.{0,40}Hesap Plan|Sigorta.{0,40}Finansal Raporlama'; 'ZORUNLU-SIG'='Zorunlu Deprem|6305 s\.K|Karayolları Trafik K\.'; 'SURD-DEN-YON'='S[üu]rd[üu]r[üu]lebilirlik.{0,60}(Denetim|Yönetmeli)'; 'SIGORTA-ACENTE'='Sigorta Acente|Sigorta ve Reas[üu]rans Brokerl|Sigorta Eksper' }
$kaynakAdi['KGK-KARAR']='KGK Kurul / ilke kararları (TFRS uygulama kapsamı)'; $ekDesen['KGK-KARAR']='[İI]lke Karar|Kurul Karar[ıi].{0,40}(TFRS|Uygulama Kapsam)|Uygulama Kapsam[ıi]na'
$kaynakAdi['İHS 4400']='İHS 4400 Üzerinde Mutabık Kalınan Prosedürlerin Uygulandığı İşler'
$kaynakAdi['TTK-DENETIM']='TTK bağımsız denetim hükümleri (m.397–406)'; $ekDesen['TTK-DENETIM']='^TTK \(6102 s\.K\.\) m\.(39[7-9]|40[0-6])\b'
$kaynakAdi['II-19.1']='SPK Kâr Payı Tebliği (II-19.1)'; $ekDesen['II-19.1']='II-19\.1'
$kaynakAdi['VII-128.2']='SPK Gayrimenkul Sertifikaları Tebliği (VII-128.2)'; $ekDesen['VII-128.2']='VII-128\.2'
$kaynakAdi['II-23.3']='SPK Önemli Nitelikteki İşlemler ve Ayrılma Hakkı Tebliği (II-23.3)'; $ekDesen['II-23.3']='II-23\.3'
$kaynakAdi['II-22.1']='SPK Geri Alınan Paylar Tebliği (II-22.1)'; $ekDesen['II-22.1']='II-22\.1'
$kaynakAdi['III-52.3']='SPK Gayrimenkul Yatırım Fonları Tebliği (III-52.3)'; $ekDesen['III-52.3']='III-52\.3'
$kaynakAdi['DEPO-SERT']='SPK Depo Sertifikaları Tebliği'; $ekDesen['DEPO-SERT']='Depo Sertifika'
$kaynakAdi['REPO']='Repo / ters repo işlemleri düzenlemesi'; $ekDesen['REPO']='[Rr]epo'
$kaynakAdi['TSPB']='Türkiye Sermaye Piyasaları Birliği düzenlemeleri'; $ekDesen['TSPB']='TSPB|Sermaye Piyasalar[ıi] Birli[ğg]i'
# mülga standartlar → halef (soru içeriği bugün halef standarttan sorulur)
$halef=@{ 'TMS 11'='TFRS 15'; 'TMS 18'='TFRS 15'; 'TMS 17'='TFRS 16'; 'TMS 39'='TFRS 9'; 'TFRS 4'='TFRS 17'; 'TMS 31'='TFRS 11'; 'TMS 30'='TFRS 7'; 'TMS 14'='TFRS 8'; 'TMS 22'='TFRS 3'; 'TMS 35'='TFRS 5' }
function KaynakOku([string]$kod){ if($kaynakAdi.ContainsKey($kod)){ return $kaynakAdi[$kod] }; return $kod }
$ambarSayimOnbellek=@{}
# 16.09: arac/kgk-mevzuat-tamlik.ps1 tebliğ/yönetmelikleri RESMÎ METİNLE ölçtü (veri/kgk-mevzuat-tamlik.json).
# Kaynak kodu ile ölçüm satırı, belge adı deseniyle eşleşir; birden çok satır eşleşirse EKSİK olan öne alınır.
$mtBelgeDeseni=@{ 'BDY'='^Bagimsiz Denetim Yonetmeligi'; 'BBD-YON'='Bankalarin Bagimsiz Denetimi'; 'KREDI-YON'='Bankalarin Kredi Islemlerine'; 'SY-YON'='Bankalarin Sermaye Yeterliliginin'; 'KSK-YON'='Kredilerin Siniflandirilmasi'; 'VYS-YON'='Varlik Yonetim Sirketlerinin'
 'IC-SIS-BANKA'='Bankalarin Ic Sistemleri'; 'IC-SIS-SIGORTA'='Sektorlerinde Ic Sistemlere'; 'DEVLET-KATKI-YON'='Devlet Katkisi Hakkinda'; 'TK-YON'='Teknik Karsiliklarina'; 'BANKA-THP'='Bankalarin Tekduzen Hesap'; 'BILGI-SIS-BANKA'='Bankalarin Bilgi Sistemleri'
 'EYF-YON'='Emeklilik Yatirim Fonlarinin'; 'SIGORTA-ACENTE'='Sigorta Acenteleri'; 'SIGORTA-THP'='Sigortacilik Tekduzen Hesap'; 'TAKAS-YON'='Merkezi Takas|Takas ve Saklama'; 'YTM-YON'='Yatirimci Tazmin'; 'BORSA-YON'='Borsalar ve Piyasa|Borsa İstanbul A'; 'OZKAYNAK-YON'='Ozkaynaklari Yonetmeligi'
 'DERECE-BANKA'='Derecelendirme'; 'III-62.1'='Degerleme Standartlari|III-62\.'; 'SPK-BD'='Seri: X, No: 22'; 'TSPB'='TSPB|Sermaye Piyasalari Birligi' }
$mevzuatTamlik=@{}
$mtYol=Join-Path $depoKok 'veri\kgk-mevzuat-tamlik.json'
if(Test-Path $mtYol){
  $mtHam=@((Get-Content $mtYol -Raw -Encoding UTF8 | ConvertFrom-Json).belgeler | Where-Object { $_.durum -in 'TAM','EKSİK' })
  foreach($kodX in (@($ekDesen.Keys) + @($mtBelgeDeseni.Keys) | Select-Object -Unique)){
    $d = if($mtBelgeDeseni.ContainsKey($kodX)){ $mtBelgeDeseni[$kodX] } else { $ekDesen[$kodX] }
    if(-not $d -or $d -eq '(?!)'){ continue }
    $es=@($mtHam | Where-Object { "$($_.belge)" -match $d })
    if($es.Count){ $mevzuatTamlik[$kodX]=@($es | Sort-Object @{ e={ if($_.durum -eq 'EKSİK'){ 0 } else { 1 } } })[0] }
  }
}
function AmbarSay([string]$desen){ if(-not $ambarSayimOnbellek.ContainsKey($desen)){ $ambarSayimOnbellek[$desen]=@($ambarAdlari | Where-Object { $_ -match $desen }).Count }; return $ambarSayimOnbellek[$desen] }

function KaynakDurumu([string]$kod){
  if(-not $kod){ return [pscustomobject]@{ durum='BELİRLENEMEDİ'; kova='Önce kaynak belirlenmeli'; aciklama='Konu adından kanun/standart çıkarılamadı'; parca=0 } }
  $a=$olcum.aileler.$kod
  if($a){
    $p=[int]$a.parca
    if($p -eq 0){ return [pscustomobject]@{ durum='YUTULMADI'; kova='Basılamaz (önce yutulmalı)'; aciklama='Resmî metin ambarda hiç yok'; parca=0 } }
    switch("$($a.nitelik)"){
      'RESMI'      { if("$($a.tamlik)" -eq 'TAM'){ return [pscustomobject]@{ durum='YUTULDU (tam)'; kova='Şimdi basılabilir'; aciklama='Resmî metin ambarda, tam'; parca=$p } } else { if($kod -match '^(TMS|TFRS|BDS|GDS|İHS)\s'){ return [pscustomobject]@{ durum='YUTULDU (etiket eksik)'; kova='Şimdi basılabilir (paket hassasiyeti düşük)'; aciklama="Resmî PDF kıyası: $($a.numara_delik) paragraf ayrı parça değil; metni komşu parçada (15.09 örneklem 134/137)"; parca=$p } }; return [pscustomobject]@{ durum='YUTULDU (delikli)'; kova='Önce parasız onarım'; aciklama="Resmî metin ambarda ama bazı madde parçası eksik ($($a.numara_delik) delik)"; parca=$p } } }
      'KARISIK'    { return [pscustomobject]@{ durum='YUTULDU (karışık)'; kova='Önce parasız onarım'; aciklama='Resmî metin + özet karışık'; parca=$p } }
      'OZET'       { return [pscustomobject]@{ durum='RESMÎ METİN YOK (yalnız özet)'; kova='Basılamaz (önce yutulmalı)'; aciklama='Ambarda yalnız özet — resmî metin yutulmalı'; parca=$p } }
      'TEORI-NOTU' { return [pscustomobject]@{ durum='RESMÎ METİN YOK (teori notu)'; kova='Basılamaz (Cem kararı)'; aciklama='Bu alanın kanun/standart metni yok; yalnız teori notu'; parca=$p } }
      'TASLAK'     { return [pscustomobject]@{ durum='TASLAK'; kova='Basılamaz (taslak)'; aciklama='Taslak metin, soru dayanağı yapılamaz'; parca=$p } }
    }
  }
  # 16.09: tebliğ/yönetmelik resmî metinle ölçüldüyse KARAR ONUN
  if($mevzuatTamlik.ContainsKey($kod)){
    $mt=$mevzuatTamlik[$kod]
    if($mt.durum -eq 'TAM'){ return [pscustomobject]@{ durum='YUTULDU (tam)'; kova='Şimdi basılabilir'; aciklama="Resmî metinle ölçüldü: $($mt.resmi_madde) maddenin hepsi ambarda (mülga $($mt.mulga))"; parca=[int]$mt.ambar_madde } }
    return [pscustomobject]@{ durum='YUTULDU (eksik madde)'; kova='Önce parasız onarım'; aciklama="Resmî metinle ölçüldü: $($mt.eksik) madde ambarda yok (ör. $($mt.eksik_ornek))"; parca=[int]$mt.ambar_madde }
  }
  if($ekDesen.ContainsKey($kod)){
    if($kod -in 'MALIYET','FIN-ANALIZ'){ return [pscustomobject]@{ durum='RESMÎ METİN YOK (teori konusu)'; kova='Basılamaz (Cem kararı)'; aciklama='Kanun/standart metni olmayan teori konusu'; parca=0 } }
    $n=AmbarSay $ekDesen[$kod]
    if($n -gt 0){ return [pscustomobject]@{ durum='AMBARDA VAR (tamlığı ölçülmedi)'; kova='Önce parasız ölçüm'; aciklama="Ambarda $n parça; resmî/tam ölçümü yapılmadı"; parca=$n } }
    return [pscustomobject]@{ durum='YUTULMADI'; kova='Basılamaz (önce yutulmalı)'; aciklama='Ambarda bu adla metin bulunamadı'; parca=0 }
  }
  $m=[regex]::Match($kod,'^(TMS|TFRS|BDS|GDS|TSRS|SBDS|KYS)\s+(\d+)$')
  if($m.Success){
    $n=AmbarSay ('^' + [regex]::Escape($kod) + '\b')
    if($n -gt 0){ return [pscustomobject]@{ durum='AMBARDA VAR (tamlığı ölçülmedi)'; kova='Önce parasız ölçüm'; aciklama="Ambarda $n parça; resmî/tam ölçümü yapılmadı"; parca=$n } }
    return [pscustomobject]@{ durum='YUTULMADI'; kova='Basılamaz (önce yutulmalı)'; aciklama='Standart ambarda yok (yürürlükten kalkmış olabilir)'; parca=0 }
  }
  return [pscustomobject]@{ durum='BELİRLENEMEDİ'; kova='Önce kaynak belirlenmeli'; aciklama="Kod tanınmadı: $kod"; parca=0 }
}

# ---------------- anahtar kelime sözlüğü (ders içi, sıra önemli: özgül önce)
$sozluk=@{
 'Muhasebe Standartlari'=@(
  @('insaat sozlesme|tamamlanma yuzdesi|tamamlanma asamasi|sabit fiyatli sozlesme|sozlesme varlig|degisken bedel','TFRS 15'),@('gecerli para birimi|parasal kalem|dovizli|kur cevrim','TMS 21'),
  @('ekonomik dezavantajli sozlesme|karsilik kosul|karsilik bugunku deger|karsilik yansitma','TMS 37'),@('politika degisikligi|gecmis donem hatasi|yararli omur degisikligi|faydali omur degisikligi|tahmin degisikligi','TMS 8'),
  @('arastirma degerlendirme|maden arastirma','TFRS 6'),@('yazilim itfa|isletme ici gelistirme|haklar hesabi|isletme ici varlik','TMS 38'),
  @('satin alma yontemi|transfer edilen bedel|ortak kontrol birlesme','TFRS 3'),@('kontrol gosterge|oy hakki guc|grup ici eliminasyon|grup ici kar','TFRS 10'),@('onemli etki esigi','TMS 28'),
  @('finansal tablo disi birakma|ozkaynak yukumluluk ayrimi|piyasa riski turleri','TFRS 9'),@('asil piyasa olcumu','TFRS 13'),
  @('nakit benzerleri|isletme faaliyeti giris|finansman faaliyeti cikis|dolayli yontem|nakit yaratmayan islem','TMS 7'),@('kisa vadeli faydalar|sgk kesenegi','TMS 19'),
  @('devlet tesvigi|tesvik geri odemesi','TMS 20'),@('raporlama sonrasi karsilik|raporlama donemi degisikligi','TMS 10'),@('satilmaya hazir varlik','TFRS 5'),@('hasat sonrasi urun','TMS 41'),
  @('emlakci gayrimenkul|ucuncu kisi gayrimenkul','TMS 40'),@('takas yoluyla edinim|varlik defter degeri|duran varlik yenileme|duran varlik tutari|yapilmakta olan yatirim|duran varlik degisimi|duran varliklar','TMS 16'),
  @('indirilebilir gecici fark','TMS 12'),@('tfrs gecis tarihi|ilk kez tfrs','TFRS 1'),@('ufrs ilke temelli|kayik tfrs uyumu|muhasebe hukuki duzenleme','KGK-KARAR'),
  @('ozkaynak degisim tablosu|finansal tablolar seti|finansal durum tablosu kalem|finansal durum tablosu unsur|genel amacli tablolarin amaci|temel ek finansal tablo|finansal tablo aciklama|yeniden siniflandirma kurallari|ozkaynak kalemleri|finansal tablo unsurlari','TMS 1'),
  @('ustabasi ucreti|ilk madde|yardimci malzeme|es deger birim|kademeli dagitim|uretimde malzeme|guvenlik payi|hedef kar analizi|alternatif secim karari|kar fonksiyonu|7b yansitma','MALIYET'),
  @('statik analiz|dagilim grafigi|finansal tablo nitelik|finansal tablo ilkeleri|finansal tablo ozellik|donen varliklar toplami|oz kaynak toplami','FIN-ANALIZ'),  @('kavramsal cerceve|faydali bilgi|niteliksel ozellik|temel ozellik','KAVRAMSAL'),@('bobi|buyuk ve orta boy|buyuk isletme','BOBI FRS'),@('tfrs uygulama kapsam|kurul karari|ilke karari','KGK-KARAR'),@('etkin faiz','TFRS 9'),@('maden arama','TFRS 6'),@('garanti karsilig','TMS 37'),@('raporlama sonrasi olay','TMS 10'),@('esas faaliyet kar','TMS 1'),@('kumi|kucuk ve mikro','KUMI FRS'),
  @('borclanma maliyet','TMS 23'),@('nakit akis','TMS 7'),@('muhasebe politika|tahmin degisik|hata duzelt|onceki donem hata','TMS 8'),@('raporlama donemi sonrasi|bilanco tarihinden sonra','TMS 10'),
  @('ertelenmis vergi|gelir vergiler|vergi gideri|vergi varlig','TMS 12'),@('calisanlara saglanan|kidem tazminat','TMS 19'),@('devlet tesvik|devlet yardim|devlet hibe','TMS 20'),@('kur fark|yabanci para|fonksiyonel para','TMS 21'),
  @('iliskili taraf','TMS 24'),@('emeklilik plan','TMS 26'),@('konsolid|bagli ortaklik|kontrol gucu|yatirim isletmesi','TFRS 10'),@('istirak|ozkaynak yontem','TMS 28'),@('yuksek enflasyon|enflasyon duzelt|enflasyon muhasebe','TMS 29'),
  @('hisse basina|pay basina','TMS 33'),@('ara donem','TMS 34'),@('deger dusuklug|geri kazanilabilir','TMS 36'),@('kosullu|karsiliklar','TMS 37'),@('serefiye|isletme birlesme|pazarlikli satin','TFRS 3'),@('maddi olmayan','TMS 38'),
  @('yatirim amacli gayrimenkul','TMS 40'),@('canli varlik|tarimsal','TMS 41'),@('ilk uygulama|ilk kez uygula','TFRS 1'),@('hisse bazli|pay bazli','TFRS 2'),@('satis amacli elde|durdurulan faaliyet','TFRS 5'),@('bolum raporlama|faaliyet bolum','TFRS 8'),
  @('beklenen kredi zarar|riskten korunma|itfa edilmis maliyet|finansal varlik|finansal arac|finansal yukumlulu','TFRS 9'),@('musterek anlasma|musterek kontrol|is ortaklig','TFRS 11'),@('diger isletmelerdeki paylar','TFRS 12'),@('gercege uygun deger','TFRS 13'),
  @('hasilat|musteri sozlesme|edim yukumlu|musteriyle yapilan','TFRS 15'),@('kiralama|leasing','TFRS 16'),@('sigorta sozlesme','TFRS 17'),@('finansal tablolarin sunulus|kapsamli gelir|ozkaynak degisim|finansal tablo seti','TMS 1'),
  @('stok','TMS 2'),@('maddi duran|yeniden degerleme|yenileme fonu|bilesen amortisman','TMS 16'),
  @('oran analiz|cari oran|likidite oran|asit|net isletme sermaye|kaldirac oran|devir hiz|dikey analiz|yatay analiz|trend analiz|fon akim|finansal analiz|karlilik oran|rantabilite|orani','FIN-ANALIZ'),
  @('maliyet muhasebe|mamul|uretim maliyet|siparis maliyet|safha maliyet|standart maliyet|basabas|degisken maliyet|sabit maliyet|katki pay|direkt ilk madde|genel uretim gider|yari mamul|esdeger birim|birlesik maliyet|yan urun|iscilik|direkt endirekt|satilan mal maliyet','MALIYET'),
  @('kaydi|yevmiye|hesap plan|reeskont|senet|supheli alacak|envanter|donem sonu|tahakkuk|sermaye artir|kar dagit|yedek akce|amortisman|degerleme|kasa|banka hesab|cek|alacak|borc|gider|gelir|satis|alis|iskonto|bilanco|gelir tablosu|sermaye|kayit|kavram|hesap|mizan|kari|yedek|ihrac prim|ihrac fark|vergi|matrah|faiz|karsilig|kiymet|sayim|hazir deger|ticari mal|maliyet|donemsellik|ozun onceligi','GENEL-MUH'),
  @('.','GENEL-MUH')   # 16.09: TMS modülünde başka izi olmayan etiket = genel muhasebe (eski modülün kalıntısı); yöntem sütununda 'ders varsayılanı' görünür
 )
 'Denetim Standartlari'=@(
  @('topluluk denet|topluluk ici|bilesen denetci','BDS 600'),@('musteri kabul|denetimi kabul|raporlama cercevesi kabul|denetimden cekilme|denetim kistasi|on sart','BDS 210'),
  @('anomali|anakitle|ana kitle|sapma orani|gelisiguzel secim|belirli kalem|orneklem','BDS 530'),@('tahmin belirsiz|nokta tahmini|muhasebe tahmin','BDS 540'),
  @('onemliligin|onemlilik','BDS 320'),@('cari oran|asit test|dikey yuzde|aktif devir|brut kar analiz|stok devir|mantiklilik analiz|oran analiz','BDS 520'),
  @('stok yanlislig|stok kayit zaman|donem sonu stok|stok denetimi|sarta bagli borc|dava','BDS 501'),@('mevzuat uygunluk|mevzuata aykiri','BDS 250'),
  @('durustluk ilkesi|mesleki yeterlik|denetci ozellik|denetim agi|cikar iliski|bagimsizlik|tehdit','ETIK'),@('yeniden uygulama|gorev ayrilig|gorevler ayrilig|kontrol test|maddi dogrulama','BDS 330'),
  @('kontrol faaliyet|kontrollerin izlen|zayif kontrol|kontrol isleyis|ic kontrol|isletme risk sureci|risk iliski|ciddi risk|harici risk|risk esasli|risk kavram|sektor daralmasi|onemli risk|is hayati riskleri|kontrol bilesen','BDS 315'),
  @('eksiklik bildirim|yonetim mektubu','BDS 265'),@('kilit konu','BDS 701'),@('karsilik gelen bilgi','BDS 710'),@('faaliyet raporu denet|diger bilgi','BDS 720'),
  @('dosya birlestirme|saklama|calisma kagid','BDS 230'),@('kdk bildirim|denetim yonetmeligi|borsa denetim yukumlulugu|denetime tabi tablo|denetci olma engel|denetci hizmet yasak|denetci degisimi|onceki denetci','BDY'),
  @('yapisal kisitlama|denetim riski|makul guvence|tds seti|turkiye denetim standartlari|standartlara uygunluk|finansal tablo sorumlulugu|yanlis ret riski|tespit edememe','BDS 200'),
  @('ticari borclar tamlik|zayif kontrol tamlik|denetim kaniti|kanit','BDS 500'),@('arge gideri|kaynak dogrulama','BDS 520'),  @('ihs 4400|mutabik kalinan|mutabik prosedur','İHS 4400'),@('ozet finansal tablo','BDS 810'),@('ozel amacli','BDS 800'),@('ttk denetim','TTK-DENETIM'),@('kks 1|kalite gozden','KYS 1'),@('tehdid|meslege uygun davranis|sarta bagli ucret|dusuk ucret|kendi kendini denetle','ETIK'),@('kapsam sinirlama','BDS 705'),@('bilanco sonrasi','BDS 560'),@('sureklilik belirsiz','BDS 570'),
  @('sinirli denetim|sinirli bagimsiz|ara donem finansal bilgilerin incelen|inceleme','SBDS 2400'),@('guvence denetim|guvence','GDS 3000'),@('kamu gozetimi|\bkgk\b|660','660 KHK'),
  @('bagimsiz denetim yonetmeli|denetim kurulus|yetkilendirme|surekli egitim|rotasyon|sicil|denetim ucret|ucret tarife|yetki belgesi','BDY'),
  @('etik|bagimsizlik|tehdit|tarafsizlik|dogruluk ilkesi|mesleki davranis|gizlilik|cikar catis','ETIK'),@('kalite kontrol|kalite yonetim','KYS 1'),
  @('mesleki suphecilik|genel amac|makul guvence|denetim riski|tespit edememe','BDS 200'),@('denetim sozlesme|sozlesme sart|denetim kabul|denetime baslama','BDS 210'),@('calisma kagit|belgelendirme|denetim dosya','BDS 230'),
  @('hile|suistimal|kotuye kullan','BDS 240'),@('mevzuata uyum|kanun ve diger duzenleme|mevzuata aykiri','BDS 250'),@('ic kontrol eksiklik|eksikliklerin bildir','BDS 265'),@('ust yonetim|yonetimden sorumlu','BDS 260'),
  @('planlama|denetim plan|denetim stratej','BDS 300'),@('onemlilik','BDS 320'),@('riske karsi|kontrol test|maddi dogrulama|detay test','BDS 330'),@('hizmet kurulus','BDS 402'),@('yanlisliklarin degerlendir|duzeltilmemis yanlis','BDS 450'),
  @('sayim|stok sayim|dava|bolum bilgi','BDS 501'),@('dis teyit|teyit','BDS 505'),@('acilis bakiye|ilk denetim','BDS 510'),@('analitik','BDS 520'),@('ornekleme|orneklem','BDS 530'),@('muhasebe tahmin','BDS 540'),@('iliskili taraf','BDS 550'),
  @('sonraki olay|raporlama donemi sonrasi|bilanco tarihinden sonra','BDS 560'),@('sureklil','BDS 570'),@('yazili aciklama|yonetim beyan|temsil mektub','BDS 580'),@('grup denetim|bilesen denetci|grup finansal','BDS 600'),@('ic denetci|ic denetim','BDS 610'),@('uzman','BDS 620'),
  @('kilit denetim','BDS 701'),@('dikkat cekme|diger husus','BDS 706'),@('sartli gorus|olumsuz gorus|kacinma|gorus degisik|sinirlandir','BDS 705'),@('karsilastirma','BDS 710'),@('diger bilgi','BDS 720'),@('gorus|denetci rapor|denetim rapor','BDS 700'),
  @('ic kontrol|kontrol riski|kontrol cevresi|risk degerlendirme|isletme ve cevres|onemli yanlislik risk|yapisal risk|dogal risk|beyan|kontrol bilesen|izleme|uygulama kontrol|manuel kontrol|tablo duzeyi risk','BDS 315'),@('kanit|dis bilgi kaynag','BDS 500'),
  @('.','BDS 200'),   # 16.09: denetim modülünde başka izi olmayan etiket = BDS 200 genel ilkeler (zayıf bağ; yöntem sütununda 'ders varsayılanı')
  @('yanlislik','BDS 450'),@('calisma kagid|dosya suresi|nihai dosya','BDS 230'),@('on sart|on denetim|tablo hazirlama sorumlu|yonetim sorumlulu','BDS 210'),@('test kalemi|ornek sec','BDS 530'),@('alacak','BDS 505'),@('prosedur|dogrulama|tamlik test|tetkik','BDS 330')
 )
 'Kurumsal Yonetim'=@( ,@('.','II-17.1') )
 'Finansal Yonetim'=@( @('faktoring|finansal kiralama|leasing','6361'), @('.','FY-TEORI') )
 'Sermaye Piyasasi Mevzuati'=@(
  @('emeklilik yatirim fon','EYF-YON'),@('gayrimenkul yatirim ortak|\bgyo\b','III-48.1'),@('girisim sermayesi','III-48.3'),@('menkul kiymet yatirim ortak','III-48.5'),@('kira sertifika','III-61.1'),@('ipotege dayali|varliga dayali|ipotek teminatli|varlik teminatli','III-58.1'),@('teminatli menkul','III-59.1'),
  @('kitle fonlama','III-35/A.2'),@('portfoy yonetim','III-55.1'),@('yatirim fon|katilma pay|fon kurulu|degisken sermayeli','III-52.1'),@('yatirim ortaklig','III-48.5'),
  @('pay alim teklif|zorunlu cagri|cagri','II-26.1'),@('birlesme|bolunme','II-23.2'),@('kaydilestir|merkezi kayit|\bmkk\b','II-13.1'),@('takas|saklama|merkezi karsi taraf|takasbank','TAKAS-YON'),@('yatirimci tazmin|tazmin merkez','YTM-YON'),
  @('kurumsal yonetim','II-17.1'),@('kayitli sermaye','II-18.1'),@('ozel durum|kamuyu aydinlatma|icsel bilgi|kap\b','II-15.1'),@('finansal raporlama|finansal tablo','II-14.1'),@('bagimsiz denetim','SPK-BD'),
  @('halka arz|izahname|ihrac belgesi|ihrahc','II-5.1'),@('satis yontem|talep toplama|satis tebli|borsada satis','II-5.2'),@('borclanma arac|tahvil|finansman bonosu|kupon','VII-128.8'),@('varant|yatirim kurulusu sertifika','VII-128.3'),
  @('pay tebli|bedelli|bedelsiz|sermaye artir|onemli nitelikte|ortaklara ait|imtiyazli pay','VII-128.1'),@('yatirim hizmet|araci kurum|yatirim kurulus|saklama hizmet|kredili islem|aciga satis|portfoy aracilig','III-37.1'),
  @('lisans|sicil','LISANS-YON'),@('derecelendirme','DERECE-YON'),@('degerleme','DEGERLEME'),@('bilgi sistem','III-62.1'),@('borsa|piyasa isletici|borsa istanbul','BORSA-YON'),
  @('kar payi|kâr payi|bagis esas','II-19.1'),@('gayrimenkul sertifika','VII-128.2'),@('ayrilma hakki','II-23.3'),@('geri alinan pay','II-22.1'),@('gyf|gayrimenkul yatirim fon','III-52.3'),@('proje finansman|konut finansman|varlik finansman fon','III-58.1'),@('varlik kiralama','III-61.1'),
  @('alternatif islem|kotasyon','BORSA-YON'),@('teminat yonetim','TAKAS-YON'),@('arz program','II-5.1'),@('depo sertifika','DEPO-SERT'),@('repo','REPO'),@('sermaye piyasalari birligi|tspb','TSPB'),@('bireysel portfoy','III-55.1'),@('ara donem finansal rapor','II-14.1'),@('tazmin','YTM-YON'),
  @('piyasa bozucu|manipulasyon|sermaye piyasasi suclari|bilgi suistimal|idari para|suc|yaptirim|tedbir|kurulun|sermaye piyasasi kurulu|sermaye piyasasi arac|halka acik|ihrac|yatirimci|kurul|tedrici tasfiye|sermaye piyasasi kurumlari|kripto|6362|spkn|cikarilmis sermaye|dolandiric|suistimal|faaliyet izni','6362'),
  @('.','6362')
 )
 'Bankacilik Mevzuati'=@(
  @('faktoring|finansal kiralama|finansman sirket','6361'),@('varlik yonetim','VYS-YON'),@('banka kart|kredi kart','5464'),@('odeme hizmet|elektronik para','6493'),@('tek duzen hesap|hesap plan','BANKA-THP'),
  @('bagimsiz denetim|denetim kurulus','BBD-YON'),@('bilgi sistem|dijital|elektronik bankacil','BILGI-SIS-BANKA'),@('ic sistem|ic kontrol|ic denetim|risk yonetim|denetim komite|icaap','IC-SIS-BANKA'),
  @('kredi islem|hesap durumu belgesi|kredi dosya|kredi karar|kredi tahsis','KREDI-YON'),@('donuk alacak|karsilik|siniflandirma|sorunlu alacak|yeniden yapilandir|takipteki','KSK-YON'),@('sermaye yeterlil|operasyonel risk|piyasa riski|kredi riski|kaldirac|likidite','SY-YON'),@('ozkaynak','OZKAYNAK-YON'),
  @('derecelendirme','DERECE-BANKA'),@('.','5411')
 )
 'Sigortacilik ve Ozel Emeklilik Mevzuati'=@(
  @('devlet katki','DEVLET-KATKI-YON'),@('bireysel emeklilik|emeklilik sirket|katilimci|otomatik katilim|emeklilik plan|\bbes\b','4632'),@('emeklilik yatirim fon','EYF-YON'),
  @('teknik karsilik|muallak|kazanilmamis prim|matematik karsilik|devam eden riskler','TK-YON'),@('ic sistem|ic kontrol|ic denetim|risk yonetim','IC-SIS-SIGORTA'),
  @('sigorta muhasebe|hesap plan|finansal tablo|sigortacilik muhasebe','SIGORTA-THP'),@('acente|broker|eksper|aktuer','SIGORTA-ACENTE'),@('zorunlu deprem|dask|trafik sigorta|zorunlu sigorta','ZORUNLU-SIG'),
  @('hayat sigorta','TTK-HAYAT'),@('sorumluluk sigorta','TTK-SORUMLULUK'),@('police|sigorta ettiren|riziko|tazminat|zamanasim|teklifname|rucu|halefiyet|sigorta sozlesme|sigortaci|eksik sigorta|askin sigorta|prim','TTK-SIGORTA'),
  @('.','5684')
 )
 'Surdurulebilirlik Raporlamasi'=@( @('kapsam|gecis|muafiyet','TSRS-KAPSAM'), @('iklim|emisyon|sera gazi|kapsam 3|metrik|senaryo|gecis plan|finanse edilen','TSRS 2'), @('.','TSRS 1') )
 'Surdurulebilirlik Denetimi'=@( @('gds 3410|sera gazi','GDS 3410'), @('gds 3000|guvence','GDS 3000'), @('yonetmeli|kurul karar|yetki|surdurulebilirlik denetim','SURD-DEN-YON'), @('.','GDS 3000') )
}

# ---------------- arşiv etiketleri
$etiket=@{}
foreach($d in $arsiv.donemler){
  $yil=[int]([regex]::Match("$($d.donem)",'(\d{4})').Groups[1].Value)
  foreach($p in $d.konuSayim.PSObject.Properties){
    if(-not $etiket.ContainsKey($p.Name)){ $etiket[$p.Name]=[pscustomobject]@{ anahtar=$p.Name; soru=0; donem=0; ilk=9999; son=0; s2022=0; s2024=0 } }
    $e=$etiket[$p.Name]; $v=[int]$p.Value; $e.soru+=$v; $e.donem++; if($yil -lt $e.ilk){ $e.ilk=$yil }; if($yil -gt $e.son){ $e.son=$yil }; if($yil -ge 2022){ $e.s2022+=$v }; if($yil -ge 2024){ $e.s2024+=$v }
  }
}
$bosKelimeler='ve','ile','icin','bir','iliskin','olan','gore','hesabi','hesaplama','tanimi','turleri','ozellikleri','kapsami','yonetmeligi','tebligi','kanunu','hukumleri','esaslari','sartlari','islemleri','finansal','denetim','muhasebe','raporlama','yonetimi','degeri','tablolar','tablolari','bankalarin','sirketleri','varliklar','sermaye','piyasasi'
function KonuKelimeleri([string]$t){ return @((Katla $t) -split '[^a-z0-9]+' | Where-Object { $_.Length -ge 4 -and $bosKelimeler -notcontains $_ }) }
$satirKelime=@{}; $satirStd=@{}
foreach($ps in $kota.plan){ $satirKelime[$ps.konu]=KonuKelimeleri $ps.konu; $se=[regex]::Match((Katla $ps.konu),'^(tms|tfrs|bds|gds|tsrs) (\d+)'); $satirStd[$ps.konu]= if($se.Success){ "$($se.Groups[1].Value) $($se.Groups[2].Value)" } else { '' } }
$arsivDersEsleme=@{ 'muhasebe standartlari'='Muhasebe Standartlari'; 'muhasebe'='Muhasebe Standartlari'; 'turkiye muhasebe standartlari'='Muhasebe Standartlari'; 'denetim'='Denetim Standartlari'; 'turkiye denetim standartlari'='Denetim Standartlari'; 'kurumsal yonetim ilkeleri ve finansal yonetim'='KYFY'; 'kurumsal yonetim ve finansal yonetim'='KYFY'; 'sermaye piyasasi, bankacilik, sigortacilik ve ozel emeklilik mevzuati'='SBS'; 'sermaye piyasasi bankacilik sigortacilik'='SBS'; 'sermaye piyasasi mevzuati'='Sermaye Piyasasi Mevzuati'; 'sermaye piyasasi'='Sermaye Piyasasi Mevzuati'; 'bankacilik mevzuati'='Bankacilik Mevzuati'; 'bankacilik'='Bankacilik Mevzuati'; 'sigortacilik ve ozel emeklilik mevzuati'='Sigortacilik ve Ozel Emeklilik Mevzuati'; 'sigortacilik ve ozel emeklilik'='Sigortacilik ve Ozel Emeklilik Mevzuati'; 'kurumsal surdurulebilirlik raporlamasi ve denetimi'='SURD'; 'genel hukuk mevzuati'='KAPSAM-DISI' }
$konuSonuc=@{}; foreach($k in $olcum.konular){ $konuSonuc[$k.konu]=$k }

$satirlar=New-Object System.Collections.Generic.List[object]; $genelHukuk=0; $bilinmeyenDers=@{}
foreach($e in $etiket.Values){
  $pa=$e.anahtar -split '\|',2; $ka=$arsivDersEsleme[(Katla $pa[0]).Trim()]; $konuAd=$pa[1]; $kt=Katla $konuAd
  if($ka -eq 'KAPSAM-DISI'){ $genelHukuk+=$e.soru; continue }
  if(-not $ka){ $bilinmeyenDers[$pa[0]]=[int]$bilinmeyenDers[$pa[0]]+$e.soru; continue }
  if($ka -eq 'KYFY'){ $ka= if($kt -match 'kurumsal yonetim|komite|yonetim kurulu|genel kurul|pay sahip|menfaat|yatirimci iliskileri|faaliyet raporu|kamuyu aydinlatma|seffaflik|bagimsiz uye|uyum rapor|iliskili taraf|azlik|oy hakki|imtiyaz'){ 'Kurumsal Yonetim' } else { 'Finansal Yonetim' } }
  if($ka -eq 'SBS'){ $ka= if($kt -match 'bank|bddk|5411|kredi|mevduat|katilim|tmsf|varlik yonetim|faktoring|leasing|kiralama'){ 'Bankacilik Mevzuati' } elseif($kt -match 'sigorta|emeklilik|bes|5684|4632|reasurans|acente|broker|hasar|police|teknik karsilik|tfrs 17'){ 'Sigortacilik ve Ozel Emeklilik Mevzuati' } else { 'Sermaye Piyasasi Mevzuati' } }
  if($ka -eq 'SURD'){ $ka= if($kt -match 'gds|guvence|denetci|denetim'){ 'Surdurulebilirlik Denetimi' } else { 'Surdurulebilirlik Raporlamasi' } }
  # plan konusu (kgk-kaynak-olcumu.ps1 ile aynı puanlama)
  $se=[regex]::Match($kt,'(tms|tfrs|bds|gds|tsrs|isa|uds)\s*(\d+)'); $ks= if($se.Success){ ($se.Groups[1].Value -replace 'isa|uds','bds') + ' ' + $se.Groups[2].Value } else { '' }
  $kk=KonuKelimeleri $konuAd; $enIyi=$null; $puan=0
  foreach($ps in @($kota.plan | Where-Object { $_.ders -eq $ka })){ $p=0; if($ks -and $satirStd[$ps.konu] -eq $ks){ $p+=10 } elseif($ks -and $satirStd[$ps.konu]){ continue }; foreach($w in $kk){ if($satirKelime[$ps.konu] -contains $w){ $p+=2 } }; if($p -gt $puan){ $puan=$p; $enIyi=$ps.konu } }
  $planKonu= if($enIyi -and $puan -ge 4){ $enIyi } else { '' }
  # kaynak: (1) konu adında standart numarası (2) anahtar kelime (3) plan konusunun ailesi
  $kod=''; $yontem=''
  $sm=[regex]::Match($kt,'\b(tms|tfrs|bds|isa|uds|gds|tsrs|sbds|kys)\s*(\d+)')
  if($sm.Success){ $kod=(($sm.Groups[1].Value.ToUpperInvariant()) -replace '^(ISA|UDS)$','BDS') + ' ' + $sm.Groups[2].Value; if($kod -match '^SBDS 24'){ $kod='SBDS 2400' }; $yontem='konu adında numara' }
  if(-not $kod){ foreach($s in $sozluk[$ka]){ if($kt -match $s[0]){ $kod=$s[1]; $yontem= if($s[0] -eq '.'){ 'ders varsayılanı' } else { 'anahtar kelime' }; break } } }
  if((-not $kod -or $yontem -eq 'ders varsayılanı') -and $planKonu){ $pk=("$($konuSonuc[$planKonu].aileler)" -split ' \+ ')[0]; if($pk){ $kod=$pk; $yontem='plan konusu' } }
  if($halef.ContainsKey($kod)){ $yontem="$yontem · mülga $kod → $($halef[$kod])"; $kod=$halef[$kod] }
  $dersTam=$dersAdi[$ka]
  $satirlar.Add([pscustomobject]@{ modul=$modulAdi[$dersTam]; ders=$dersTam; kaynak_kod=$kod; yontem=$yontem; plan_konu=$planKonu; etiket=$konuAd; soru=$e.soru; donem=$e.donem; ilk=$e.ilk; son=$e.son; s2022=$e.s2022; s2024=$e.s2024 })
}
$es=$satirlar.ToArray()
$toplamGuncel=($es | Measure-Object soru -Sum).Sum
"çıkmış (güncel modüller): $toplamGuncel · Genel Hukuk (güncel sınavda yok): $genelHukuk · ders tanınmayan: $(($bilinmeyenDers.Values | Measure-Object -Sum).Sum)"
foreach($y in ($es | Group-Object yontem)){ "  yöntem {0,-22} soru {1,5}" -f $(if($y.Name){$y.Name}else{'(bulunamadı)'}),($y.Group | Measure-Object soru -Sum).Sum }

# ---------------- kaynak düzeyi + basım önerisi
$kaynakSatir=New-Object System.Collections.Generic.List[object]
foreach($g in ($es | Group-Object modul,ders,kaynak_kod)){
  $r=$g.Group; $kod=$r[0].kaynak_kod; $dz=KaynakDurumu $kod
  $kaynakSatir.Add([pscustomobject]@{ modul=$r[0].modul; ders=$r[0].ders; kaynak_kod=$kod; kaynak=$(if($kod){ KaynakOku $kod } else { '(konu adından kaynak çıkarılamadı)' }); soru=($r | Measure-Object soru -Sum).Sum; s2022=($r | Measure-Object s2022 -Sum).Sum; s2024=($r | Measure-Object s2024 -Sum).Sum; etiket=$r.Count; son=($r | Measure-Object son -Maximum).Maximum; durum=$dz.durum; kova=$dz.kova; aciklama=$dz.aciklama; parca=$dz.parca; agirlik=0.0; oneri=0 })
}
$ks=$kaynakSatir.ToArray()
foreach($k in $ks){ $k.agirlik = [double]$k.s2022 }   # yalnız 2022+ (güncel 7 modüllü yapı); eski dönemde çıkıp o zamandan beri çıkmayana taban 5
foreach($mg in ($ks | Group-Object modul)){
  $bilinen=@($mg.Group | Where-Object { $_.kaynak_kod }); $top=($bilinen | Measure-Object agirlik -Sum).Sum
  foreach($k in $bilinen){ if($top -gt 0 -and $k.soru -gt 0){ $k.oneri=[int][math]::Max(5,[math]::Round($ModulBanka*$k.agirlik/$top)) } }
}
$ksSirali=@($ks | Sort-Object modul,ders,@{e={-$_.soru}})

# ---------------- plan konuları (127)
$planSatir=foreach($k in $olcum.konular){
  $etk=@($es | Where-Object { $_.plan_konu -eq $k.konu }); $kod=("$($k.aileler)" -split ' \+ ')[0]
  [pscustomobject]@{ modul=$modulAdi[$k.ders]; ders=$k.ders; kaynak=$(KaynakOku $kod); aileler=$k.aileler; konu=$k.konu; cikmis=($etk | Measure-Object soru -Sum).Sum; s2022=($etk | Measure-Object s2022 -Sum).Sum; donem=($etk | Measure-Object donem -Sum).Sum; sinif=$k.sinif; gerekce=$k.gerekce; kota=[int]$k.kota; kasada=[int]$k.kasada_ayni_konu }
}
$planSatir=@($planSatir | Sort-Object modul,ders,kaynak,@{e={-$_.cikmis}})

# ---------------- modül özeti
$gmKasa=@{ '1) Türkiye Muhasebe Standartları'=10; '3) Kurumsal Yönetim İlkeleri ve Finansal Yönetim'=10; '4) Sermaye Piyasası Mevzuatı'=7; '5) Bankacılık Mevzuatı'=6; '7) Kurumsal Sürdürülebilirlik (Raporlama + Denetim)'=4 }
$ozet=foreach($mg in ($ks | Group-Object modul | Sort-Object Name)){
  $g=@($mg.Group); $s=($g | Measure-Object soru -Sum).Sum
  $belirsiz=(@($g | Where-Object { -not $_.kaynak_kod }) | Measure-Object soru -Sum).Sum
  $hemen=(@($g | Where-Object { $_.kova -like 'Şimdi basılabilir*' }) | Measure-Object oneri -Sum).Sum
  $onarim=(@($g | Where-Object { $_.kova -in 'Önce parasız onarım','Önce parasız ölçüm' }) | Measure-Object oneri -Sum).Sum
  $engel=(@($g | Where-Object { $_.kova -like 'Basılamaz*' }) | Measure-Object oneri -Sum).Sum
  [pscustomobject]@{ modul=$mg.Name; cikmis=$s; s2022=($g | Measure-Object s2022 -Sum).Sum; s2024=($g | Measure-Object s2024 -Sum).Sum; kaynak_sayisi=@($g | Where-Object kaynak_kod).Count; kaynakli_oran=[math]::Round(100.0*($s-$belirsiz)/[math]::Max(1,$s),0); yutulmamis_kaynak=@($g | Where-Object { $_.kova -like 'Basılamaz*' }).Count; oneri=($g | Measure-Object oneri -Sum).Sum; hemen=$hemen; onarim=$onarim; engel=$engel; gm_kasada=[int]$gmKasa[$mg.Name]; basilacak_hemen=[math]::Max(0,$hemen-[int]$gmKasa[$mg.Name]) }
}
$ozet=@($ozet)
foreach($o in $ozet){ "{0,-52} çıkmış {1,5} · kaynaklı %{2,3} · öneri {3,4} · hemen {4,4} · onarım {5,4} · engel {6,4}" -f $o.modul,$o.cikmis,$o.kaynakli_oran,$o.oneri,$o.hemen,$o.onarim,$o.engel }
$yut=@($ksSirali | Where-Object { $_.kova -like 'Basılamaz*' } | Sort-Object @{e={-$_.soru}})
"--- basılamaz kaynaklar:"; foreach($y in $yut){ "  {0,-45} {1,-48} çıkmış {2,4} (2022+ {3,3}) · {4}" -f $y.ders.Substring(0,[Math]::Min(45,$y.ders.Length)),$y.kaynak.Substring(0,[Math]::Min(48,$y.kaynak.Length)),$y.soru,$y.s2022,$y.durum }
@{ ozet=$ozet; kaynak=$ksSirali; plan=$planSatir; etiket=$es; genelHukuk=$genelHukuk; toplam=$toplamGuncel } | Export-Clixml "$sp\kgk-excel-veri.xml"
if($ExcelYok){ return }

# ---------------- Excel
function Tablo($sayfa, [string[]]$basliklar, $satirlarDizi, [scriptblock]$degerler, [int]$basSatir=1){
  $n=@($satirlarDizi).Count; $c=$basliklar.Count
  $dizi=New-Object 'object[,]' ($n+1),$c
  for($j=0;$j -lt $c;$j++){ $dizi[0,$j]=$basliklar[$j] }
  $i=1; foreach($r in $satirlarDizi){ $v=@(& $degerler $r); for($j=0;$j -lt $c;$j++){ $dizi[$i,$j]=$v[$j] }; $i++ }
  $alan=$sayfa.Range($sayfa.Cells($basSatir,1),$sayfa.Cells($basSatir+$n,$c)); $alan.Value2=$dizi
  $bas=$sayfa.Range($sayfa.Cells($basSatir,1),$sayfa.Cells($basSatir,$c)); $bas.Font.Bold=$true; $bas.Interior.Color=0x5E3A1F; $bas.Font.Color=0xFFFFFF; $bas.WrapText=$true
  [void]$alan.AutoFilter()
  return $alan
}
$xl=New-Object -ComObject Excel.Application; $xl.Visible=$false; $xl.DisplayAlerts=$false
try{
  $wb=$xl.Workbooks.Add()
  while($wb.Worksheets.Count -lt 6){ [void]$wb.Worksheets.Add([Type]::Missing,$wb.Worksheets.Item($wb.Worksheets.Count)) }
  $s1=$wb.Worksheets.Item(1); $s1.Name='1 Özet'
  $s2=$wb.Worksheets.Item(2); $s2.Name='2 Kanun-Standart'
  $s3=$wb.Worksheets.Item(3); $s3.Name='3 Konular (plan)'
  $s4=$wb.Worksheets.Item(4); $s4.Name='4 Yutulmayanlar'
  $s5=$wb.Worksheets.Item(5); $s5.Name='5 Çıkmış konu etiketleri'
  $s6=$wb.Worksheets.Item(6); $s6.Name='6 Nasıl hesaplandı'

  # 1 Özet
  $s1.Cells(1,1).Value2='KGK Bağımsız Denetçilik — çıkmış sorular, kaynak (yutma) durumu ve basım önerisi'; $s1.Cells(1,1).Font.Size=14; $s1.Cells(1,1).Font.Bold=$true
  $s1.Cells(2,1).Value2=("Arşiv: 29 dönem (2013–2026), güncel modüllerde {0:N0} çıkmış soru. Genel Hukuk ({1:N0} soru) güncel sınavda yok, dışarıda. Basım önerisi: modül başına {2} soru (≈10 tam sınav), modül içinde 2022–2026 (güncel sınav yapısı) çıkmış soru payına göre; eskiden çıkıp son dönemde çıkmayana 5. Tahmini bedel {3:N2} USD/soru. Ölçüm: {4}." -f $toplamGuncel,$genelHukuk,$ModulBanka,$USD_SORU,(Get-Date -Format 'dd.MM.yyyy HH:mm'))
  $s1.Range('A2:N2').Merge(); $s1.Range('A2').WrapText=$true; $s1.Rows(2).RowHeight=48
  $a1=Tablo $s1 @('Modül (sınavda 40 soru)','Çıkmış soru (2013–2026)','2022+ çıkmış','2024+ çıkmış','Kaynak (kanun/standart) sayısı','Kaynağı belli soru %','Basılamaz kaynak sayısı','Önerilen banka (soru)','Şimdi basılabilir','Önce parasız onarım/ölçüm','Basılamaz (yut/karar)','Kasada GM sorusu','Şimdi basılacak (GM düşülmüş)','Tahmini bedel şimdi (USD)') $ozet { param($o) @($o.modul,$o.cikmis,$o.s2022,$o.s2024,$o.kaynak_sayisi,$o.kaynakli_oran,$o.yutulmamis_kaynak,$o.oneri,$o.hemen,$o.onarim,$o.engel,$o.gm_kasada,$o.basilacak_hemen,[math]::Round($o.basilacak_hemen*$USD_SORU,1)) } 4
  $son=4+$ozet.Count+1
  $s1.Cells($son,1).Value2='TOPLAM'; $s1.Cells($son,1).Font.Bold=$true
  foreach($col in 2,3,4,5,7,8,9,10,11,12,13,14){ $harf=[char](64+$col); $s1.Cells($son,$col).Formula="=SUM($($harf)5:$($harf)$($son-1))"; $s1.Cells($son,$col).Font.Bold=$true }
  $s1.Columns('A').ColumnWidth=46; $s1.Range('B:N').ColumnWidth=14; $s1.Rows(4).RowHeight=45

  # 2 Kanun-Standart
  [void](Tablo $s2 @('Modül','Ders','Kaynak (kanun / yönetmelik / tebliğ / standart)','Kod','Çıkmış soru (2013–2026)','2022+','2024+','Konu etiketi','Son çıktığı yıl','YUTTUK MU?','Ne yapılmalı','Açıklama','Ambarda parça','Önerilen basım') $ksSirali { param($k) @($k.modul,$k.ders,$k.kaynak,$k.kaynak_kod,$k.soru,$k.s2022,$k.s2024,$k.etiket,$k.son,$k.durum,$k.kova,$k.aciklama,$k.parca,$k.oneri) })
  $s2.Columns('A').ColumnWidth=30; $s2.Columns('B').ColumnWidth=30; $s2.Columns('C').ColumnWidth=52; $s2.Columns('D').ColumnWidth=14; $s2.Range('E:I').ColumnWidth=10; $s2.Columns('J').ColumnWidth=30; $s2.Columns('K').ColumnWidth=26; $s2.Columns('L').ColumnWidth=50; $s2.Range('M:N').ColumnWidth=11

  # 3 Plan konuları
  [void](Tablo $s3 @('Modül','Ders','Kaynak','Kaynak kodları','Konu (üretim planı)','Çıkmış soru','2022+','Çıktığı dönem','Kaynak sınıfı','Gerekçe','Onaylı kota (01.08)','Kasada aynı konu (eski havuz)') $planSatir { param($p) @($p.modul,$p.ders,$p.kaynak,$p.aileler,$p.konu,$p.cikmis,$p.s2022,$p.donem,$p.sinif,$p.gerekce,$p.kota,$p.kasada) })
  $s3.Columns('A').ColumnWidth=30; $s3.Columns('B').ColumnWidth=30; $s3.Columns('C').ColumnWidth=40; $s3.Columns('D').ColumnWidth=18; $s3.Columns('E').ColumnWidth=55; $s3.Range('F:H').ColumnWidth=10; $s3.Columns('I').ColumnWidth=10; $s3.Columns('J').ColumnWidth=60; $s3.Range('K:L').ColumnWidth=12

  # 4 Yutulmayanlar
  $s4.Cells(1,1).Value2='Soru basmayı engelleyen kaynaklar (çıkmış soru sayısına göre sıralı)'; $s4.Cells(1,1).Font.Bold=$true; $s4.Cells(1,1).Font.Size=13
  [void](Tablo $s4 @('Modül','Ders','Kaynak','Kod','Çıkmış soru','2022+','YUTTUK MU?','Ne yapılmalı','Açıklama','Önerilen basım (engelli)') $yut { param($k) @($k.modul,$k.ders,$k.kaynak,$k.kaynak_kod,$k.soru,$k.s2022,$k.durum,$k.kova,$k.aciklama,$k.oneri) } 3)
  $s4.Columns('A').ColumnWidth=30; $s4.Columns('B').ColumnWidth=30; $s4.Columns('C').ColumnWidth=52; $s4.Columns('D').ColumnWidth=16; $s4.Range('E:F').ColumnWidth=10; $s4.Columns('G').ColumnWidth=30; $s4.Columns('H').ColumnWidth=26; $s4.Columns('I').ColumnWidth=55; $s4.Columns('J').ColumnWidth=12

  # 5 Etiketler
  $etSirali=@($es | Sort-Object modul,ders,kaynak_kod,@{e={-$_.soru}})
  [void](Tablo $s5 @('Modül','Ders','Kaynak kodu','Kaynak nasıl bulundu','Plan konusu','Çıkmış konu etiketi','Çıkmış soru','Dönem','İlk yıl','Son yıl','2022+') $etSirali { param($r) @($r.modul,$r.ders,$r.kaynak_kod,$r.yontem,$r.plan_konu,$r.etiket,$r.soru,$r.donem,$r.ilk,$r.son,$r.s2022) })
  $s5.Columns('A').ColumnWidth=28; $s5.Columns('B').ColumnWidth=28; $s5.Columns('C').ColumnWidth=14; $s5.Columns('D').ColumnWidth=18; $s5.Columns('E').ColumnWidth=40; $s5.Columns('F').ColumnWidth=55

  # 6 Açıklama
  $not=@(
    'NEREDEN GELDİ',
    ' • Çıkmış sorular: veri/kgk-analiz.json — 29 dönem, 2013–2026, her soru konu etiketli (19.08.2026 tam arşiv).',
    ' • Yutma durumu: arac/kgk-kaynak-olcumu.ps1 bugün (-Tazele) yeniden koşuldu — ambardaki 47.710 satır; her kaynak ailesi için resmî mi, tam mı ölçüldü.',
    ' • Ambarda olup bu ölçüme girmemiş kaynaklar (SPK tebliğleri, BDDK yönetmelikleri…) yalnız ADIYLA arandı: "AMBARDA VAR (tamlığı ölçülmedi)".',
    '',
    'KAYNAK NASIL BULUNDU (5. sayfada her satırda yazıyor)',
    ' • konu adında numara: etikette TMS/TFRS/BDS/GDS/TSRS numarası geçiyor — en güvenilir.',
    ' • anahtar kelime: konu adındaki kelimeden (ör. "ertelenmiş vergi" → TMS 12, "halka arz" → II-5.1) — yüksek güven, ama tek tek gözle doğrulanmadı.',
    ' • plan konusu: onaylı üretim planındaki konuya bağlandı ve o konunun ölçülmüş kaynağı alındı.',
    ' • ders varsayılanı: başka iz yoksa dersin ana kanunu (Bankacılık → 5411, Sigortacılık → 5684, Sürdürülebilirlik → TSRS 1) — en zayıf güven.',
    '',
    'YUTTUK MU? sütunu',
    ' • YUTULDU (tam): resmî metin ambarda, paragraf/madde deliği ≤ %5 → şimdi soru basılabilir.',
    ' • YUTULDU (delikli) / (karışık): resmî metin var ama eksik parça var → önce parasız onarım (resmî PDF''ten yeniden parçalama).',
    ' • AMBARDA VAR (tamlığı ölçülmedi): ad olarak var; basımdan önce parasız ölçüm gerekir.',
    ' • RESMÎ METİN YOK / YUTULMADI / TASLAK: soru basılamaz. Cem şartı: "tüm yerlerde resmî metin ve metnin tam olması".',
    '',
    'BASIM ÖNERİSİ',
    (' • Her modül sınavda 40 soru → modül başına {0} soru (≈10 tam sınav). Rakip iddiası toplam ≈980 soru; öneri 7 modülde ≈{1:N0}.' -f $ModulBanka,(7*$ModulBanka)),
    ' • Modül içinde her kaynağa, 2022–2026 çıkmış soru payı kadar pay verildi (2022''de modüller ayrıldı, güncel sınav o yapıda). Eskiden çıkıp 2022''den beri çıkmayan kaynağa taban 5 soru. 2013–2021 sayıları bilgi olarak duruyor, basım payını belirlemiyor.',
    ' • Kaynağı belirlenemeyen çıkmış sorular pay dağıtımına girmedi (payları belli kaynaklara orantılı dağıldı).',
    (' • Bedel tahmini {0:N2} USD/soru (veri/fabrika/KGK-PLAN.md ölçüsü). Hiçbir basım başlatılmadı; para harcayan her adım ayrıca sorulur.' -f $USD_SORU),
    '',
    'SINIRLAR (dürüst not)',
    ' • Etiketler soru başına çok ince (5.147 etiket / 5.440 soru); aynı konu farklı yazımla ayrı etiket olabilir.',
    ' • 2013–2021 birleşik "Sermaye Piyasası, Bankacılık, Sigortacılık" modülündeki sorular konu adındaki kelimeyle üç derse ayrıldı.',
    ' • Eski "Muhasebe" modülündeki genel muhasebe / maliyet / finansal analiz soruları güncel TMS modülünde az çıkıyor; 2022+ sütununa bakın.',
    ' • Kasadaki eski KGK havuzu (2.166 soru) konu planına uymadığı için düşülmedi; yalnız 15.09 GM soruları (47) düşüldü.'
  )
  for($i=0;$i -lt $not.Count;$i++){ $s6.Cells($i+1,1).Value2=$not[$i]; if($not[$i] -and $not[$i] -notmatch '^ '){ $s6.Cells($i+1,1).Font.Bold=$true } }
  $s6.Columns('A').ColumnWidth=160

  # 7 Dönem karşılaştırması (Cem 15.09: "2022 öncesi çıkıp yeni sınavda çıkan var mı")
  [void]$wb.Worksheets.Add([Type]::Missing,$wb.Worksheets.Item($wb.Worksheets.Count)); $s7=$wb.Worksheets.Item($wb.Worksheets.Count); $s7.Name='7 2022 öncesi-sonrası'
  $modEski=@{}; $modYeni=@{}; foreach($o in $ozet){ $modEski[$o.modul]=[math]::Max(1,$o.cikmis-$o.s2022); $modYeni[$o.modul]=[math]::Max(1,$o.s2022) }
  $donemSatir=foreach($k in @($ksSirali | Where-Object kaynak_kod)){
    $eski=$k.soru-$k.s2022; $pe=100.0*$eski/$modEski[$k.modul]; $py=100.0*$k.s2022/$modYeni[$k.modul]
    $etiketD= if($k.s2022 -eq 0){ 'YALNIZ 2022 ÖNCESİ (sonra hiç çıkmadı)' } elseif($eski -eq 0){ 'YALNIZ 2022 SONRASI (yeni)' } elseif($eski -ge 10 -and $py -lt $pe/3){ 'İKİSİNDE DE VAR — belirgin DÜŞTÜ' } elseif($k.s2022 -ge 10 -and $py -gt 3*$pe){ 'İKİSİNDE DE VAR — belirgin ARTTI' } else { 'İKİSİNDE DE VAR' }
    [pscustomobject]@{ modul=$k.modul; kaynak=$k.kaynak; eski=$eski; yeni=$k.s2022; pe=[math]::Round($pe,1); py=[math]::Round($py,1); etiket=$etiketD; durum=$k.durum; oneri=$k.oneri }
  }
  $donemSatir=@($donemSatir | Sort-Object modul,etiket,@{e={-($_.eski+$_.yeni)}})
  [void](Tablo $s7 @('Modül','Kaynak','2013–2021 çıkmış','2022–2026 çıkmış','Modül içi pay 2013–2021 %','Modül içi pay 2022–2026 %','Dönem durumu','YUTTUK MU?','Önerilen basım') $donemSatir { param($d) @($d.modul,$d.kaynak,$d.eski,$d.yeni,$d.pe,$d.py,$d.etiket,$d.durum,$d.oneri) })
  $s7.Columns('A').ColumnWidth=30; $s7.Columns('B').ColumnWidth=55; $s7.Range('C:F').ColumnWidth=12; $s7.Columns('G').ColumnWidth=36; $s7.Columns('H').ColumnWidth=30; $s7.Columns('I').ColumnWidth=11
  $s7.Activate(); $xl.ActiveWindow.SplitRow=1; $xl.ActiveWindow.FreezePanes=$true
  $donemSatir | Group-Object etiket | ForEach-Object { "  dönem: {0,-42} kaynak {1,3} · 2013–21 {2,5} · 2022–26 {3,4}" -f $_.Name,$_.Count,($_.Group | Measure-Object eski -Sum).Sum,($_.Group | Measure-Object yeni -Sum).Sum } | Write-Output
  $donemSatir | Where-Object { $_.etiket -like '*DÜŞTÜ*' -or $_.etiket -like '*ARTTI*' } | ForEach-Object { "    {0,-34} {1,-55} {2,4} → {3,4}  (%{4} → %{5})" -f $_.etiket,$_.kaynak.Substring(0,[Math]::Min(55,$_.kaynak.Length)),$_.eski,$_.yeni,$_.pe,$_.py } | Write-Output

  foreach($s in @($s1,$s2,$s3,$s4,$s5)){ $s.Activate(); $xl.ActiveWindow.SplitRow=$(if($s -eq $s1){4}elseif($s -eq $s4){3}else{1}); $xl.ActiveWindow.FreezePanes=$true }
  $s1.Activate()
  if(Test-Path $Cikti){ Remove-Item $Cikti }
  $wb.SaveAs($Cikti, 51); $wb.Close($false)
  "Excel yazıldı: $Cikti"
} finally { $xl.Quit(); [void][Runtime.InteropServices.Marshal]::ReleaseComObject($xl) }
