# ============================================================================
#  IHALE AMBARINI OKU  (20.08.2026)
#
#  Ambar artik depoda DEGIL, Supabase'de (veri/ihale-sonuc.json cikti - 28,2 MB
#  acik dosyaydi). Ozet ureten uc betik (tur/firma/idare) kaynagi buradan alir.
#  Tek yerden okunmasinin sebebi: alan adlari iki tarafta farkli (tabloda
#  snake_case, betiklerde camelCase). Esleme TEK yerde dursun ki uc betikten
#  biri unutulup sessizce bos kayit uretmesin.
#
#  DONEN SEKIL eski JSON kaydinin AYNISI - ozet betiklerinin hesap kismina hic
#  dokunulmadi (o kod olculmus ve dogrulanmis durumda).
#
#  KIRIM burada HESAPLANMAZ. Tablodaki ihale_sonuc_v gorunumu kisimliligi TUM
#  HAVUZ uzerinden olcup kirimi turetiyor; gun-ici hesap 1.133 kaydi yanlis
#  olcmustu. Buradaki is yalnizca tasimak.
#
#  Anahtar yoksa: eski JSON dosyasina duser (gecis donemi + yerel calisma).
#  Ikisi de yoksa BOS DONMEZ, ekrana sebep yazar (kor kalma kurali).
# ============================================================================

function Ihale-AmbarOku {
  param(
    [string]$Kok,
    # 1.000: PostgREST'in sunucu tarafi tavani. Daha buyuk istemek ise yaramaz,
    # yalniz "eksik geldi" yanilgisi uretir.
    [int]$Sayfa = 1000
  )
  $SB_URL  = 'https://bjrleanjpyujtajmazxn.supabase.co'
  $anahtar = "$($env:SUPABASE_SERVICE_KEY)".Trim()

  if (-not $anahtar) {
    $dosya = Join-Path $Kok 'veri\ihale-sonuc.json'
    if (Test-Path $dosya) {
      Write-Host "AMBAR: SUPABASE_SERVICE_KEY yok -> eski JSON dosyasindan okunuyor ($dosya)"
      return @((Get-Content $dosya -Raw -Encoding UTF8 | ConvertFrom-Json).sonuclar)
    }
    Write-Host 'AMBAR OKUNAMADI: ne SUPABASE_SERVICE_KEY var ne de veri\ihale-sonuc.json.'
    Write-Host '                 Yerelde: anahtar-kur.cmd | Actions: Secrets -> SUPABASE_SERVICE_KEY'
    return @()
  }

  $basliklar = @{
    'apikey'        = $anahtar
    'Authorization' = "Bearer $anahtar"
    'Content-Type'  = 'application/json'
    'Accept'        = 'application/json'
    'User-Agent'    = 'MevzuatRadar-AmbarOkuyucu'
  }

  $hepsi = New-Object Collections.ArrayList
  $offset = 0
  while ($true) {
    $govde = @{ p_offset = $offset; p_limit = $Sayfa } | ConvertTo-Json -Compress
    $cevap = Invoke-RestMethod -Method Post -Uri "$SB_URL/rest/v1/rpc/ihale_dokum" `
               -Headers $basliklar -Body ([Text.Encoding]::UTF8.GetBytes($govde)) -TimeoutSec 300
    # TUZAK (olculdu 20.08): fonksiyon icinde cagrildiginda Invoke-RestMethod'un
    # dondurdugu dizi TEK OGEYE sariliyor - @() bunu acmiyor. Fark edilmezse
    # sessizce "1 kayit okundu" der ve ozet 24.043 yerine 1 kaydin uzerinden
    # uretilir (ekranda hata yok, sayilar bos cikar). Bir kat DUZLESTIRILIR.
    $duz = New-Object Collections.ArrayList
    foreach ($z in $cevap) {
      if ($z -is [Array]) { foreach ($y in $z) { [void]$duz.Add($y) } } else { [void]$duz.Add($z) }
    }
    $parca = @($duz)
    if (-not $parca.Count) { break }
    foreach ($r in $parca) {
      [void]$hepsi.Add([pscustomobject]@{
        ikn             = $r.ikn
        tur             = $r.tur
        isAdi           = $r.is_adi
        idare           = $r.idare
        ihaleTarih      = $r.ihale_tarih
        ihaleTuru       = $r.ihale_turu
        usul            = $r.usul
        yaklasikMaliyet = $r.yaklasik_maliyet
        ymBirim         = $r.ym_birim
        sbBirim         = $r.sb_birim
        dokumanIndiren  = $r.dokuman_indiren
        teklifSayisi    = $r.teklif_sayisi
        gecerliTeklif   = $r.gecerli_teklif
        yerliAvantaj    = $r.yerli_avantaj
        sozlesmeTarih   = $r.sozlesme_tarih
        sozlesmeBedeli  = $r.sozlesme_bedeli
        yuklenici       = $r.yuklenici
        kisimKaniti     = $r.kisim_kaniti
        kisimSayisi     = $r.kisim_sayisi
        kisimliMi       = $r.kisimli_mi
        kirimYuzde      = $r.kirim_yuzde
      })
    }
    $offset += $parca.Count
    # TUZAK 2 (olculdu 20.08): "istedigimden az geldiyse bitmistir" YANLIS.
    # PostgREST sunucu tarafinda sayfa basina 1.000 satirda kesiyor; 5.000
    # isteyip 1.000 alinca dongü "bitti" sanip 24.043 kaydin 1.000'iyle ozet
    # uretiyordu. Tek dogru bitis olcutu: BOS SAYFA.
    if ($parca.Count -eq 0) { break }
  }
  Write-Host ("AMBAR: Supabase kasasindan {0:N0} sonuc ilani okundu" -f $hepsi.Count)
  return @($hepsi)
}
