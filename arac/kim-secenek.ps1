# ============================================================================
#  KONU GİRİŞİ "KİM BELİRLER" SEÇENEKLERİ (motor/kalip-parti-uret.ps1 yükler; 06.10.2026 Cem "1.2.3" GM3)
#  NEDEN (SGS oturumu ölçtü 06.10): istem Denetim ve Vergi/Ticaret/Borçlar/İş/Meslek DIŞINDAKİ her derse muhasebe listesini
#    veriyordu ("Tekdüzen hesap planı tanımlar · kanun sabitler · işletme yönetimi belirler"). SGS'de Türkçe, Matematik, İnkılap,
#    Ekonomi, Maliye, Yabancı Dil konu girişlerinde 8.153 terimde "kanun sabitler / Tekdüzen hesap planı" çıktı. SMMM "Hukuk" ve
#    "Sermaye Piyasası Mevzuatı" da muhasebe listesine düşüyordu (ders adı hukuk desenine uymuyordu).
#  ⛔ İSTEM BAYTI KORUMASI (kalip-parti-uret.ps1 KURAL0310 düzeninin aynısı): $Yeni=$false iken çıktı ESKİ istemle bayt bayt aynıdır
#    (toplu parti parmak izi istemden hesaplanır; değişirse ödenmiş partiler ikinci kez ödenir). Yeni listeler yalnız çağıran
#    KURAL0610 açıkken verilir (≥ 2026-10-07 ve etiketin daha önce gönderilmiş partisi yok).
#  🚫 GÖRMEZ: modelin listeye uyup uymadığı (yumuşak kapı) · ders adı burada sayılmayan yeni bir ders.
#  Öz-sınav: powershell -NoProfile -File arac/kim-secenek.ps1 -Sinav  (mutasyon: $env:KIM_SECENEK_MUTASYON='eski-bozuk' | 'yeni-kapali')
# ============================================================================
function KimSecenekEski([string]$d){
  $kimDenetim=($d -match 'Denetim'); $kimHukuk=($d -match 'Vergi|Ticaret|Borclar|Borçlar|Is ve Sosyal|İş ve Sosyal|Meslek')
  if("$env:KIM_SECENEK_MUTASYON" -eq 'eski-bozuk'){ $kimHukuk=($d -match 'Vergi|Ticaret') }
  return $(if($kimDenetim){ 'denetçi mesleki yargıyla belirler · standart (BDS) sabitler · işletme yönetimi yalnız finansal tabloyu ve beyanı hazırlar (belirleyici değildir)' }
    elseif($kimHukuk){ 'kanun sabitler · mahkeme ya da idare karar verir · taraflar sözleşmeyle belirler · meslek kuruluşu düzenler · mükellef / işveren beyan eder. Denetçi bu derste belirleyici DEĞİLDİR, yazma.' }
    else { 'işletme yönetimi tahmin eder ya da belirler (faydalı ömür, tamamlanma yüzdesi, normal kapasite) · piyasa fiyatlar (satış bedeli, alış bedeli gibi gerçekleşen tutarlar) · Tekdüzen hesap planı ya da standart tanımlar · kanun sabitler. DENETÇİ bu derste belirleyici DEĞİLDİR, yazma.' })
}
function KimSecenek([string]$d,[bool]$Yeni){
  if(-not $Yeni -or "$env:KIM_SECENEK_MUTASYON" -eq 'yeni-kapali'){ return (KimSecenekEski $d) }
  $yok=' Tekdüzen hesap planı, işletme yönetimi ve denetçi bu derste belirleyici DEĞİLDİR, yazma.'
  if($d -match 'T[uü]rk[cç]e'){ return 'dil bilgisi kuralı ve Türk Dil Kurumu yazım kuralları belirler · metnin bağlamı ve yazarın amacı belirler.' + $yok }
  if($d -match 'Matematik|Say[ıi]sal|[İI]statistik'){ return 'tanım ve formül sabitler · soruda verilen değerler ve koşullar belirler.' + $yok }
  if($d -match '[İI]nk[ıi]lap|Atat[uü]rk|Tarih'){ return 'antlaşma, kongre kararı ve kanun metni sabitler · Meclis ya da hükûmet karar verir · tarihî olayın koşulları belirler.' + $yok }
  if($d -match 'Yabanc[ıi] Dil|[İI]ngilizce|English'){ return 'dil bilgisi kuralı belirler · cümlenin ve paragrafın bağlamı belirler.' + $yok }
  if($d -match 'Ekonomi|[İI]ktisat'){ return 'piyasa (arz ve talep) belirler · merkez bankası para politikasıyla, devlet maliye politikasıyla düzenler · iktisat kuramı tanımlar.' + $yok }
  if($d -match 'Maliye(?!t)'){ return 'Anayasa ve kanun sabitler · TBMM bütçe kanunuyla belirler · idare uygular ve tahsil eder · maliye kuramı tanımlar.' + $yok }
  if($d -match 'Sermaye Piyasas|SPK'){ return 'kanun sabitler · Sermaye Piyasası Kurulu düzenler ve izin verir · borsa ve merkezî kuruluşlar işletir · ihraççı ve aracı kurum beyan eder. Denetçi ve Tekdüzen hesap planı bu derste belirleyici DEĞİLDİR, yazma.' }
  if($d -match '^Hukuk$|Hukuk(?! Denetim)'){ if(-not ($d -match 'Denetim')){ return 'kanun sabitler · mahkeme ya da idare karar verir · taraflar sözleşmeyle belirler · meslek kuruluşu düzenler · mükellef / işveren beyan eder. Denetçi bu derste belirleyici DEĞİLDİR, yazma.' } }
  return (KimSecenekEski $d)
}
# 07.11.2026 B33 (Cem "kural oluştur"): kim zorunlu kapalı listeydi; kimsenin koymadığı kalemde model en yakın seçeneği uyduruyordu
#   ("Dönem Sonu Stok · piyasa fiyatlar"). Ek, yalnız KURAL0711 açıkken isteme girer (istem baytı koruması, kalip-parti-uret.ps1).
function KimSecenekEk0711(){
  if("$env:KIM_SECENEK_MUTASYON" -eq 'ek-yok'){ return '' }
  return ' Listeden hiçbiri gerçekten uymuyorsa seçenek uydurma, "kim" alanını BOŞ bırak (""). Kayıttan gelen ya da formülle çıkan kalemin belirleyicisi yoktur: dönem başı/sonu stok, ortalama stok, devir hızı, finansal analiz oranı için "piyasa fiyatlar" ya da "işletme yönetimi belirler" YAZMA.'
}
# 07.11.2026 B35 (Cem "bir daha yanlış soru basmak istemiyorum"): Yeterlilik D1 160 soruda 140 konu özeti kusurlu, 352 alan, cevap hatası 0.
#   Konu özeti bulutta sorudan SONRA üretilir; istem bu kuralları bilmiyordu. Ek yalnız KURAL0711 açıkken girer (istem baytı koruması).
function KonuOzetEk0711(){
  if("$env:KIM_SECENEK_MUTASYON" -eq 'ozet-yok'){ return '' }
  return @'


ÖNCELİKLİ KURALLAR (yukarıdaki yönergeyle çelişirse bunlar geçerlidir):
1. desen, harita, yontemler, sinavda alanları doğru şıkkı, doğru tarihi ya da "III yanlıştır" gibi cevabı SÖYLEMEZ; yalnız tuzağı ve ilgili maddeyi söyler.
2. Özet kuralın bütün şart, eşik ve istisnalarını taşır. Kaynakta olmayan "hiç, yalnız, her zaman" yazılmaz.
3. Muhasebe, vergi, hukuk ve denetim derslerinde örnek gündelik benzetme olamaz (arkadaş, kantin, telefon, harçlık). Örneğin öznesi kuralın gerçek öznesidir (meslek mensubu, ortaklık, mükellef) ve örnek rakamlıdır.
4. Örnekteki her ara rakamı kaynağın hesap yoluyla yeniden hesapla.
5. Atıf madde metnindeki fıkra ve bent sayımıyla yazılır; kaynak parça adı atıf yapılmaz.
6. Kuralı bir düzenleme koyuyorsa kim alanına o düzenleme yazılır; "kanun sabitler" yalnız kural kanundaysa yazılır.
7. Terim, örnek ve harita aynı kuralı söyler; ornek ile panel_ornek çelişmez.
'@
}
if($MyInvocation.InvocationName -ne '.' -and @($args) -contains '-Sinav'){
  $dersler=@('Finansal Muhasebe','Maliyet Muhasebesi','Finansal Tablolar ve Analizi','Muhasebe Denetimi','Vergi Mevzuatı ve Uygulaması','Hukuk','Sermaye Piyasası Mevzuatı','Muh. ve Mali Müş. Meslek Hukuku','Türkçe','Matematik','Atatürk İlkeleri ve İnkılap Tarihi','Yabancı Dil','Ekonomi','Maliye','Ticaret Hukuku','Borçlar Hukuku','İş ve Sosyal Güvenlik Hukuku','Muhasebe')
  $muh='Tekdüzen hesap planı ya da standart tanımlar'
  # 1) KORUMA: $Yeni=$false → eski işlevle birebir (bütün dersler); eski işlev mutasyonsuz sabit metinlerle (istem baytı)
  $v=@(); foreach($d in $dersler){ $v+=,@("eski istem aynı: $d", ((KimSecenek $d $false) -ceq (KimSecenekEski $d))) }
  $v+=,@('eski: Türkçe muhasebe listesi alıyordu (bayt koruması)', ((KimSecenek 'Türkçe' $false).Contains($muh)))
  $v+=,@('eski: Vergi hukuk listesi', ((KimSecenek 'Vergi Mevzuatı ve Uygulaması' $false).StartsWith('kanun sabitler')))
  $v+=,@('eski: Meslek Hukuku hukuk listesi', ((KimSecenek 'Muh. ve Mali Müş. Meslek Hukuku' $false).StartsWith('kanun sabitler')))
  $v+=,@('eski: İş ve Sosyal Güvenlik hukuk listesi', ((KimSecenek 'İş ve Sosyal Güvenlik Hukuku' $false).StartsWith('kanun sabitler')))
  # 2) YENİ: genel kültür / SPK / Hukuk muhasebe listesi ALMAZ; muhasebe dersleri ve Denetim eskisi gibi
  foreach($d in 'Türkçe','Matematik','Atatürk İlkeleri ve İnkılap Tarihi','Yabancı Dil','Ekonomi','Maliye','Sermaye Piyasası Mevzuatı','Hukuk'){ $v+=,@("yeni: $d muhasebe listesi almaz", (-not (KimSecenek $d $true).Contains($muh))) }
  foreach($d in 'Finansal Muhasebe','Maliyet Muhasebesi','Finansal Tablolar ve Analizi','Muhasebe Denetimi','Vergi Mevzuatı ve Uygulaması'){ $v+=,@("yeni: $d eskisiyle aynı", ((KimSecenek $d $true) -ceq (KimSecenekEski $d))) }
  # 3) 07.11 B33: boş bırakma izni ve hesap kalemi yasağı istem ekinde durur
  $ek=KimSecenekEk0711; $v+=,@('B33 ek: boş bırakma izni', ($ek.Contains('BOŞ bırak'))); $v+=,@('B33 ek: stok ve oran yasağı', ($ek.Contains('ortalama stok') -and $ek.Contains('YAZMA')))
  $oz=KonuOzetEk0711; $v+=,@('B35 ek: cevabı söyleme', ($oz.Contains('SÖYLEMEZ'))); $v+=,@('B35 ek: gündelik benzetme', ($oz.Contains('gündelik benzetme'))); $v+=,@('B35 ek: yedi madde', ($oz.Contains("`n7. ") -or $oz.Contains('7. Terim')))
  $h=0; foreach($x in $v){ if(-not $x[1]){ $h++; "  DUSTU: $($x[0])" } }
  if($h){ "KIM SECENEK SINAVI KIRMIZI: $h/$($v.Count)"; exit 1 } else { "KIM SECENEK SINAVI YESIL: $($v.Count)/$($v.Count)"; exit 0 }
}
