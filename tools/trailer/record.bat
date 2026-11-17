@echo off
rem Fragmani 1920x1080, 30 fps kaydeder: marketing\trailer\raw\trailer.avi
rem Godot'nun kayit modu pencere boyutunu kullanir. Windows olceklemesi (ornegin %%120) pencereyi kucultmesin diye
rem kayit suresince override.cfg ile pencere 1920x1080, kenarliksiz ve yuksek DPI'a duyarli yapilir; sonra silinir.
rem Steam ekran goruntuleri (yazi kartlari olmadan): record.bat stills
cd /d "%~dp0\..\.."
set GODOT=C:\Users\osonm\Tools\Godot\Godot_v4.7.2-stable_win64_console.exe
if not exist marketing\trailer\raw mkdir marketing\trailer\raw
(
echo [display]
echo window/size/window_width_override=1920
echo window/size/window_height_override=1080
echo window/size/borderless=true
echo window/dpi/allow_hidpi=true
) > override.cfg
if "%1"=="stills" (
  "%GODOT%" --path . --position 0,0 res://tools/trailer/trailer.tscn -- --stills="%cd%\marketing\trailer\screenshots" --no-cards
) else (
  "%GODOT%" --path . --position 0,0 --write-movie "%cd%\marketing\trailer\raw\trailer.avi" --fixed-fps 30 res://tools/trailer/trailer.tscn
)
del override.cfg
echo Bitti.
