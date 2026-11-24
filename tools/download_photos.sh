#!/bin/bash
# Uygulamadaki gerçek fotoğrafları indirir (Unsplash — ücretsiz Unsplash Lisansı).
# Bir fotoğraf inmezse uygulama onun yerine renkli bir geçiş gösterir; derleme bozulmaz.
mkdir -p assets/photos
dl() {
  curl -fsSL --retry 3 -o "assets/photos/$1.jpg" \
    "https://images.unsplash.com/photo-$2?fm=jpg&q=78&w=1100&fit=crop" \
    && echo "✓ $1" || { echo "✗ $1 indirilemedi"; rm -f "assets/photos/$1.jpg"; }
}
dl hero     1728486145245-d4cb0c9c3470   # büyük spor salonu
dl barbell  1646492169621-d8da8016354a   # halter (siyah-beyaz)
dl dumbbell 1589579234096-25cb6b83e021   # dambıl
dl bench    1707538320664-1fca7c3c7770   # sehpada oturan sporcu
dl chest    1601422407692-ec4eeec1d9b3   # şınav / göğüs
dl back     1704374810187-154ccc66798f   # barfiks / sırt
dl shoulder 1597452485683-0e0bde820f87   # dambıllı sporcu / omuz
dl arm      1641337221253-fdc7237f6b61   # dambıl / kol
dl leg      1534368959876-26bf04f2c947   # halter taşıma / bacak
dl abs      1589955791915-526198ae4ee9   # yerde egzersiz / karın
dl cardio   1734668489582-52ad40df8fc7   # koşu bantları
dl rest     1758599879463-58aad7d947f3   # yoga / esneme
dl scale    1646829873498-e874cfa27933   # tartı
ls -la assets/photos
