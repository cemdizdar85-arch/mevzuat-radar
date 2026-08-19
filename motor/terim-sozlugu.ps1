# ---- TERIM SOZLUGU (Cem 19.08: "kisa aciklamasi olan her seyi acikla") -------
# Kartin metninde gecen dis ticaret terimleri kartin altinda halk diliyle
# aciklanir. DETERMINISTIK: desen eslesirse tanim basilir, LLM yok.
# Tanimlarin kaynaklari (hepsi birincil metinden okundu, 19.08):
#   damping/subvansiyon: 3577 s.K. m.2 (ambar damping.json)
#   gozden gecirme/yeni ihracatci: 3577 s.K. ek m.2
#   kota/tarife kontenjani: 2010/339 s. BKK m.2
#   gozetim: Ithalatta Gozetim Tebligi 2026/43 m.1-2 (arsiv 11-07-2026)
#   ek mali yukumluluk: 2976 s.K. m.1
#   mense: 4458 s.K. m.17-19 (ambar gumruk.json)
#   GTIP acilimi: teblig tanim maddeleri ("GTIP: Gumruk Tarife Istatistik Pozisyonunu")
# DIKKAT: desenler bilerek DAR - "uluslararasi gozetim sirketi", "piyasa
# gozetimi", "borsa gozetimi" AYRI kavramlardir, genel 'gozetim' deseni YASAK.
# Turkce I/i tuzagi: ToLower kullanilmaz, desenler iki harfi de acikca tasir.
$TERIM_SOZLUGU = @(
  @{ ad='GTİP';   desen='GT[İI]P';
     tanim="Gümrük Tarife İstatistik Pozisyonu; her ürüne gümrükte verilen kimlik numarası gibi bir koddur, hangi ürünün hangi vergiye ve kurala tabi olduğu bu kodla belirlenir" }
  @{ ad='GTP';    desen='\bGTP\b';
     tanim="Gümrük Tarife Pozisyonu; ürün kodunun (GTİP'in) baş hanelerinden oluşan üst gruptur" }
  @{ ad='Damping';desen='[Dd]amping';
     tanim="bir malın Türkiye'ye, kendi ülkesindeki satış fiyatının altında fiyatla satılması; 'dampinge karşı önlem' de bu haksız ucuzluğa karşı yerli üreticiyi korumak için o ülkeden ithalata getirilen ek vergidir" }
  @{ ad='Sübvansiyon'; desen='[Ss]übvansiyon|[Ss]ubvansiyon';
     tanim="ihracatçı ülkenin kendi üreticisine verdiği devlet desteği; destekli mal Türkiye'de haksız rekabet yaratırsa telafi edici önlem alınabilir" }
  @{ ad='Nihai gözden geçirme'; desen='[Nn]ihai gözden geçirme|[Nn]ihai gozden gecirme';
     tanim="süresi dolmak üzere olan mevcut önlemin kalkıp kalkmayacağının incelenmesi; inceleme bitene kadar önlem yürürlükte kalır" }
  @{ ad='Yeni ihracatçı incelemesi'; desen='[Yy]eni ihracatçı|[Yy]eni ihracatci';
     tanim="önleme tabi ülkeden, ilk soruşturma döneminde Türkiye'ye satış yapmamış bir firmanın kendisi için ayrı oran istemesi üzerine açılan inceleme" }
  @{ ad='Tarife kontenjanı'; desen='[Tt]arife [Kk]ontenjan';
     tanim="belirli bir dönemde belirli miktara kadar yapılan ithalatta gümrük vergisinin indirimli ya da sıfır uygulanması; kontenjan dolunca normal vergiye dönülür" }
  @{ ad='Kota'; desen='\b[Kk]ota\b';
     tanim="belirli bir dönemde yapılmasına izin verilen ithalatın miktar veya değer sınırı" }
  @{ ad='Gözetim belgesi'; desen='[Gg][öo]zetim belgesi|[İI]thalatta [Gg][öo]zetim|[Gg][öo]zetim uygulamas|[Gg][öo]zetime tabi|[Gg][öo]zetim e[şs]i[kğg]|[Gg][öo]zetim değeri|[Gg][öo]zetim listesi|[Gg][öo]zetim formu';
     tanim="ithalatın izlemeye alınması: belirlenen birim fiyatın altında kalan ithalat ancak Ticaret Bakanlığından alınan 'gözetim belgesi' ile yapılabilir; bu bir vergi değil izleme aracıdır" }
  @{ ad='Ek mali yükümlülük'; desen='[Ee]k mali yükümlülük|[Ee]k mali yukumluluk';
     tanim="gümrük vergisine ek olarak ithalatta alınan ilave ödeme" }
  @{ ad='Korunma önlemi'; desen='[Kk]orunma önlem|[Kk]orunma onlem';
     tanim="bir üründe ithalat artışı yerli üreticilere ciddi zarar veriyorsa veya verme tehdidi varsa soruşturma sonucunda getirilen geçici koruma; genellikle ek vergi veya miktar sınırı olarak uygulanır" }
  @{ ad='Menşe'; desen='[Mm]enşe|[Mm]ense[iy ]';
     tanim="ürünün üretildiği/elde edildiği ülke ('Çin menşeli' = Çin'de üretilmiş); ithalatta hangi ülkeye hangi verginin uygulanacağını menşe belirler" }
)
function TerimSozluguHtml($k){
  $metin = "$($k.baslik_sade) $($k.ne_oldu) $($k.urun_tanimi) $($k.kimi_ilgilendirir) $($k.ne_yapmali)"
  $parcalar = @()
  foreach($t in $TERIM_SOZLUGU){
    if([regex]::IsMatch($metin, $t.desen)){ $parcalar += "<b>$($t.ad):</b> $($t.tanim)." }
  }
  if(-not $parcalar.Count){ return "" }
  return "<div class='sozluk' style='margin:10px 0;padding:10px 13px;border:1px dashed var(--line);border-radius:10px;font-size:12px;color:var(--dim);line-height:1.6'><b style='color:var(--muted)'>📖 Bu karttaki terimler ne demek?</b> " + ($parcalar -join ' ') + "</div>"
}
