@echo off
REM Flutter devices 번호 선택 (Windows)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0flutter-devices.ps1" %*
