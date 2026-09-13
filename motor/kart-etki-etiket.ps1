# ============================================================================
#  KART ETKİ ETİKETİ — hap kartındaki "Ne anlama geliyor (yorum · …)" etiketinin
#  TEK çevirisi. kart-toplu.ps1 bunu nokta-kaynak (dot-source) ile yükler.
#
#  NEDEN VAR (13.09.2026, Cem: "ham kodları Türkçe karşılığına çevirelim")
#  Model etki yönünü bir KOD olarak döndürüyor (istem: "ithalatci aleyhine" |
#  "ithalatci lehine" | "karisik" | "notr" | "belirsiz") ve kart-toplu.ps1 bu kodu
#  sayfaya OLDUĞU GİBİ basıyordu: kartlar.html'de "yorum · karisik", "yorum · notr".
#  13.09 ölçümü: 121 sayfada 199 etiket; 5'i modelin Türkçe harfle yazdığı
#  "ithalatçı aleyhine/lehine" idi ve renk seçimi yalnız harfsiz yazımı tanıdığı
#  için bu 5 kart yanlış renkte (gri) basılmıştı.
#
#  KURAL: veri dosyasında (kartlar-guncel.json, arşiv) KOD kalır - uyari-robotu ve
#  radar-app onu okuyor. Çeviri yalnız EKRANA basılırken yapılır.
# ============================================================================

function KartEtkiKatla([string]$KartEtkiHam){
  if(-not $KartEtkiHam){ return "" }
  $katli = ($KartEtkiHam -replace "\s+"," ").Trim()
  $katli = $katli -creplace "İ","i" -creplace "I","i" -creplace "ı","i" -creplace "Ç","c" -creplace "ç","c" -creplace "Ş","s" -creplace "ş","s" -creplace "Ğ","g" -creplace "ğ","g" -creplace "Ü","u" -creplace "ü","u" -creplace "Ö","o" -creplace "ö","o"
  return $katli.ToLowerInvariant()
}

# Dönüş: @{ etiket = ekranda yazan Türkçe; renk = CSS jetonu }
function KartEtkiEtiket([string]$KartEtkiHam){
  switch(KartEtkiKatla $KartEtkiHam){
    "ithalatci aleyhine" { return @{ etiket = "ithalatçı aleyhine"; renk = "var(--amber)" } }
    "ithalatci lehine"   { return @{ etiket = "ithalatçı lehine";   renk = "var(--green)" } }
    "karisik"            { return @{ etiket = "etkisi karışık";     renk = "var(--dim)" } }
    "notr"               { return @{ etiket = "nötr";               renk = "var(--dim)" } }
    "belirsiz"           { return @{ etiket = "belirsiz";           renk = "var(--dim)" } }
    default              { return @{ etiket = "$KartEtkiHam".Trim(); renk = "var(--dim)" } }
  }
}

# ÖZ-SINAV: -Sinav ile koşulur (kart-toplu.ps1 yüklerken koşmaz). Bozuk eşleme yakalanmalı.
function KartEtkiOzSinav{
  $vakalar = @(
    @("ithalatci aleyhine","ithalatçı aleyhine","var(--amber)"),
    @("ithalatçı aleyhine","ithalatçı aleyhine","var(--amber)"),
    @("İthalatçı Lehine","ithalatçı lehine","var(--green)"),
    @("ithalatci lehine","ithalatçı lehine","var(--green)"),
    @("karisik","etkisi karışık","var(--dim)"),
    @("karışık","etkisi karışık","var(--dim)"),
    @("notr","nötr","var(--dim)"),
    @(" nötr ","nötr","var(--dim)"),
    @("belirsiz","belirsiz","var(--dim)"),
    @("bilinmeyen kod","bilinmeyen kod","var(--dim)")
  )
  $dusen = 0
  foreach($v in $vakalar){
    $sonuc = KartEtkiEtiket $v[0]
    if($sonuc.etiket -ne $v[1] -or $sonuc.renk -ne $v[2]){ $dusen++; Write-Host ("  DÜŞTÜ: [{0}] -> [{1}|{2}] beklenen [{3}|{4}]" -f $v[0],$sonuc.etiket,$sonuc.renk,$v[1],$v[2]) }
  }
  Write-Host ("KART ETKİ ETİKETİ öz-sınav: {0}/{1} geçti" -f ($vakalar.Count-$dusen), $vakalar.Count)
  return ($dusen -eq 0)
}
