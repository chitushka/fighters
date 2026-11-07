@echo off
chcp 65001 >nul
set "GAME_DIR=%~dp0"
set "ENGINE=D:\Programs\Godot\Godot_v4.7.2-stable_win64.exe"
if exist "%GAME_DIR%build\WildInstinct.exe" (
  start "" "%GAME_DIR%build\WildInstinct.exe" --main-pack "%GAME_DIR%build\WildInstinct.pck"
  exit /b
)
if not exist "%ENGINE%" (
  echo Не найден Godot: %ENGINE%
  echo Откройте project.godot в Godot 4.7 и нажмите F6 или F5.
  pause
  exit /b 1
)
start "" "%ENGINE%" --path "%GAME_DIR%."
