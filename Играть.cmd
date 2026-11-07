@echo off
setlocal
chcp 65001 >nul
set "GAME_DIR=%~dp0"
set "ENGINE=D:\Programs\Godot\Godot_v4.7.2-stable_win64.exe"
if not exist "%GAME_DIR%build\WildInstinct.exe" goto source
if not exist "%GAME_DIR%build\WildInstinct.pck" goto source
start "" /D "%GAME_DIR%build" "%GAME_DIR%build\WildInstinct.exe" --main-pack "%GAME_DIR%build\WildInstinct.pck" %*
exit /b 0
:source
if not exist "%ENGINE%" (
  echo Godot not found: %ENGINE%
  echo Open project.godot in Godot 4.7 and press F5.
  pause
  exit /b 1
)
start "" /D "%GAME_DIR%." "%ENGINE%" --path "%GAME_DIR%." %*
