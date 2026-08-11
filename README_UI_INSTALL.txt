SUIKAI UI UPDATE

1) Put suikai_ui_update.zip in ~/Downloads
2) Open Terminal
3) Go to project:
   cd ~/Desktop/suikai
4) Backup current lib:
   cp -r lib lib_backup_before_ui
5) Install UI update:
   unzip -o ~/Downloads/suikai_ui_update.zip -d .
6) Refresh packages:
   flutter clean
   flutter pub get
7) Run on Android:
   flutter devices
   flutter run -d PJYTOZSOGI5TE675

If the device ID changes, use the ID shown by flutter devices.
