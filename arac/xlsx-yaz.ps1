#requires -Version 5.1
<#
================================================================================
  XLSX YAZICI — Excel KURULU OLMADAN .xlsx uretir  (12.09.2026)

  NIYE VAR: 12.09'da yil analizini Excel COM ile yazmayi denedim, IKI KEZ ayni
  satirda dustu:
      "Programin yurutulmesine devam etmek icin bellek yeterli degil"
      OutOfMemoryException · $sayfa.Range(...).Value2 = <6 hucrelik baslik>
  Alti hucrelik bir baslik icin bellek bitmez; sorun RAM degil COM arayuzuydu
  (bos bellek 543 -> 889 MB'a cikarildi, ayni yerde yine dustu).

  .xlsx zaten ZIP icinde XML'dir. Excel'e, COM'a, ek pakete GEREK YOK:
  .NET'in kendi ZipArchive'i yeter. Boylece bu arac
    - bellek darligindan etkilenmez (satir satir akitir),
    - Excel kurulu olmayan makinede de calisir (GitHub Actions dahil),
    - ve baska bir surec Excel'i mesgul ettiginde takilmaz.

  ⛔ INLINE STRING kullanilir (paylasilan dize tablosu YOK): dosya biraz buyur
     ama uretim tek gecistir ve kacis hatasi riski azalir.
  ⛔ TURKCE: XML UTF-8 yazilir, BOM'suz. & < > " ' kacilir.
  ⛔ SAYI/METIN ayrimi: [int]/[double]/[decimal] sayi hucresi olur, gerisi metin.
     Null hucre HIC YAZILMAZ (bos gorunur) - "0" yazmak veriyi bozar.

  KULLANIM
    . arac/xlsx-yaz.ps1
    $sayfalar = @(
      @{ ad='OZET';    satirlar=@( ,@('Baslik','Deger') ) + @( ,@('soru',123) ) },
      @{ ad='KONULAR'; satirlar=$digerSatirlar }   # her satir bir dizi
    )
    XlsxYaz -Hedef 'C:\yol\dosya.xlsx' -Sayfalar $sayfalar -DonukSatir 1
  BEDEL 0.
================================================================================
#>

function XlsxKacis([string]$s){
  return ([string]$s).Replace('&','&amp;').Replace('<','&lt;').Replace('>','&gt;').Replace('"','&quot;')
}
function XlsxSutunAdi([int]$n){    # 1 -> A, 27 -> AA
  $ad=''
  while($n -gt 0){ $k=($n-1)%26; $ad=[char](65+$k)+$ad; $n=[int](($n-$k)/26) }
  return $ad
}
function XlsxSayiMi($v){
  if($null -eq $v){ return $false }
  return ($v -is [int] -or $v -is [long] -or $v -is [double] -or $v -is [decimal] -or $v -is [single] -or $v -is [byte])
}

function XlsxSayfaXml($satirlar,[int]$donukSatir){
  $sb=New-Object System.Text.StringBuilder
  [void]$sb.Append('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>')
  [void]$sb.Append('<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">')
  if($donukSatir -gt 0){
    # ⚠ Bolme (freeze) basligi sabitler; ySplit=donuk satir sayisi.
    [void]$sb.Append((''+
      '<sheetViews><sheetView workbookViewId="0" tabSelected="0">'+
      '<pane ySplit="'+$donukSatir+'" topLeftCell="A'+($donukSatir+1)+'" activePane="bottomLeft" state="frozen"/>'+
      '</sheetView></sheetViews>'))
  }
  [void]$sb.Append('<sheetData>')
  $r=0
  foreach($satir in $satirlar){
    $r++
    [void]$sb.Append('<row r="'+$r+'">')
    $c=0
    foreach($hucre in $satir){
      $c++
      if($null -eq $hucre -or "$hucre" -eq ''){ continue }   # bos hucre YAZILMAZ
      $ref=(XlsxSutunAdi $c)+$r
      if(XlsxSayiMi $hucre){
        # ⛔ Sayi HER ZAMAN InvariantCulture ile: tr-TR virgulu xlsx'i bozar
        $metin=[string]::Format([cultureinfo]::InvariantCulture,'{0}',$hucre)
        [void]$sb.Append('<c r="'+$ref+'"><v>'+$metin+'</v></c>')
      } else {
        $st=$(if($r -le $donukSatir){ ' s="1"' } else { '' })
        [void]$sb.Append('<c r="'+$ref+'" t="inlineStr"'+$st+'><is><t xml:space="preserve">'+(XlsxKacis $hucre)+'</t></is></c>')
      }
    }
    [void]$sb.Append('</row>')
  }
  [void]$sb.Append('</sheetData></worksheet>')
  return $sb.ToString()
}

function XlsxYaz{
  param(
    [Parameter(Mandatory=$true)][string]$Hedef,
    [Parameter(Mandatory=$true)]$Sayfalar,     # @( @{ad=..; satirlar=..} , ... )
    [int]$DonukSatir = 1
  )
  Add-Type -AssemblyName System.IO.Compression -ErrorAction SilentlyContinue
  Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue
  $klasor=Split-Path $Hedef -Parent
  if($klasor){ New-Item -ItemType Directory -Force $klasor | Out-Null }
  if(Test-Path $Hedef){ Remove-Item $Hedef -Force }

  $utf8=New-Object System.Text.UTF8Encoding $false
  $akis=[IO.File]::Open($Hedef,[IO.FileMode]::CreateNew)
  try{
    $zip=New-Object System.IO.Compression.ZipArchive($akis,[IO.Compression.ZipArchiveMode]::Create)
    try{
      function Koy([string]$yol,[string]$icerik){
        $g=$zip.CreateEntry($yol,[IO.Compression.CompressionLevel]::Optimal)
        $s=$g.Open()
        try{ $b=$utf8.GetBytes($icerik); $s.Write($b,0,$b.Length) } finally{ $s.Dispose() }
      }
      $n=$Sayfalar.Count
      $ct=New-Object System.Text.StringBuilder
      [void]$ct.Append('<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">')
      [void]$ct.Append('<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>')
      [void]$ct.Append('<Default Extension="xml" ContentType="application/xml"/>')
      [void]$ct.Append('<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>')
      [void]$ct.Append('<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>')
      for($i=1;$i -le $n;$i++){ [void]$ct.Append('<Override PartName="/xl/worksheets/sheet'+$i+'.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>') }
      [void]$ct.Append('</Types>')
      Koy '[Content_Types].xml' $ct.ToString()

      Koy '_rels/.rels' ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/></Relationships>')

      $wb=New-Object System.Text.StringBuilder
      [void]$wb.Append('<?xml version="1.0" encoding="UTF-8" standalone="yes"?><workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheets>')
      for($i=1;$i -le $n;$i++){
        $ad=XlsxKacis ($Sayfalar[$i-1].ad)
        [void]$wb.Append('<sheet name="'+$ad+'" sheetId="'+$i+'" r:id="rId'+$i+'"/>')
      }
      [void]$wb.Append('</sheets></workbook>')
      Koy 'xl/workbook.xml' $wb.ToString()

      $wr=New-Object System.Text.StringBuilder
      [void]$wr.Append('<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">')
      for($i=1;$i -le $n;$i++){ [void]$wr.Append('<Relationship Id="rId'+$i+'" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet'+$i+'.xml"/>') }
      [void]$wr.Append('<Relationship Id="rId'+($n+1)+'" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>')
      [void]$wr.Append('</Relationships>')
      Koy 'xl/_rels/workbook.xml.rels' $wr.ToString()

      # iki bicim: 0 = normal, 1 = KALIN (baslik)
      Koy 'xl/styles.xml' ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?><styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'+
        '<fonts count="2"><font><sz val="11"/><name val="Calibri"/></font><font><b/><sz val="11"/><name val="Calibri"/></font></fonts>'+
        '<fills count="2"><fill><patternFill patternType="none"/></fill><fill><patternFill patternType="gray125"/></fill></fills>'+
        '<borders count="1"><border/></borders>'+
        '<cellStyleXfs count="1"><xf/></cellStyleXfs>'+
        '<cellXfs count="2"><xf xfId="0"/><xf xfId="0" fontId="1" applyFont="1"/></cellXfs>'+
        '</styleSheet>')

      for($i=1;$i -le $n;$i++){
        Koy ('xl/worksheets/sheet'+$i+'.xml') (XlsxSayfaXml $Sayfalar[$i-1].satirlar $DonukSatir)
      }
    } finally{ $zip.Dispose() }
  } finally{ $akis.Dispose() }
  return (Get-Item $Hedef)
}
