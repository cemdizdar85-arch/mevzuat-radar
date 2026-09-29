# Reklam metinleri

Instagram/Meta'ya çıkacak her reklam (ve organik gönderi) metni **yayından önce** buraya
bir `.md` dosyası olarak yazılır. Görseldeki yazı, seslendirme ve açıklama metni
birlikte bu dosyada durur. Meta paneline elle yazılan ama buraya girmeyen metni kapı göremez.

Kapı: `node arac/reklam-metni-kapisi.js` (her push'ta `dogrula.yml`'de koşar).
Tek dosyayı yayından önce denemek için: `node arac/reklam-metni-kapisi.js pazarlama/reklam/<ad>.md`

Başlangıç için `_sablon.md` dosyasını kopyala. `_` ya da `README` ile başlayan dosyalar taranmaz.
Kuralların tam listesi ve dayanakları kapı dosyasının başında yazılıdır.
