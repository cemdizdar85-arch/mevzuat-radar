# ============================================================================
#  KAYNAK KOK ADI — TEK KURAL, IKI KULLANICI (30.08.2026)
#
#  NEDEN AYRI DOSYA: bu kural iki yerde birden lazim ve ikisinin AYNI olmasi
#  sart:
#    motor/ambar-envanteri.ps1  -> envanter satirlarini bu kokle gruplar
#    motor/butunluk-kapisi.ps1  -> "hangi kaynagi olctum" listesini bu kokle yazar
#  Envanterin TAM MI sutunu, kapinin OLCTUGU kaynak listesine baglanacak.
#  Iki taraf kok adini FARKLI turetirse liste hicbir zaman eslesmez ve baglama
#  sessizce ise yaramaz - yani bugunku "sahte TAM" kusuru sekil degistirerek
#  geri gelir. Kural tek yerde durur; iki taraf da buradan okur.
#
#  KURAL, ENVANTERIN 30.08 ONCESI DAVRANISIYLA BIREBIR AYNIDIR (bilerek):
#  envanter satirlarinin adlari degismesin diye. Kural degisecekse iki tarafta
#  ayni anda degisir.
#
#  Kullanim:  . (Join-Path $here 'kaynak-kok.ps1')   ->  KaynakKok $ad $tur
# ============================================================================

function KaynakKok([string]$kaynakAd, [string]$tur){
  $k = "$kaynakAd"
  $t = "$tur"

  # 1) Cikmis sinav arsivi: tekil belge kalabaligi TEK gruba katlanir
  if($t -in @('cikmis-soru','cikmis-komisyon-cevabi')){ return "[ARŞİV] ÇIKMIŞ SINAV ($t)" }

  # 2) Teori notlari tek grup
  if($t -eq 'teori-notu' -or $k -match '^(TEORI|Teori Notu)'){ return '[GRUP] TEORİ NOTLARI' }

  # 3) SONDAKI KOSELI EK kirpilir: " [2/5]" (bolunmus parca) · " [giris]"
  # 30.08 EKLENDI: bu kirpma OLMADAN her parca AYRI kaynak sayiliyordu.
  # Iki zarar birden: (a) envanterde 405 SPK karari + 215 rehber parcasi ayri
  # ayri satir aciyordu, (b) butunluk kapisi parcalari GRUPLAYAMADIGI icin
  # "[2/5] eksik" gibi bir deligi ASLA goremiyordu (her grup tek uyeli kaliyor,
  # kapi da tek uyeli grupta aralik cozumlemesi yapmiyor).
  # DIKKAT: yalniz SONDAKI koseli ek kirpilir - "[ARŞİV] ..." gibi BASTAKI
  # etiketler korunur.
  $k = ($k -replace '\s*\[[^\]]{1,20}\]\s*$','').Trim()

  # 4) Konum ekini kirp: " m.5", " p.12", " ek m.3", " bolum 2", " kisim 1" ...
  if($k -match '^(.*?)\s+(m\.|muk\. m\.|md\.|p\.\d|p\.[A-Z]|ilke|ek m\.|gec\. m\.|geçici m\.|Ek [A-Z]|b[oö]l[uü]m \d|bolum \d|k[iı]s[iı]m \d)'){
    return $Matches[1].Trim()
  }
  return $k.Trim()
}
