# -*- coding: utf-8 -*-
"""CI: 'flutter create' sonrası Android ayarlarını düzenler."""
import re, pathlib

man = pathlib.Path("android/app/src/main/AndroidManifest.xml")
s = man.read_text(encoding="utf-8")
s = re.sub(r'android:label="[^"]*"', 'android:label="Fit Takip"', s, count=1)
if "android.permission.VIBRATE" not in s:
    s = s.replace("<application", '<uses-permission android:name="android.permission.VIBRATE" />\n    <application', 1)
man.write_text(s, encoding="utf-8")
print("AndroidManifest güncellendi")
