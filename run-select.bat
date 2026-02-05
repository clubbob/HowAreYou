@echo off
REM 에뮬레이터 선택 후 실행 (EGL 로그 제외)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0run-select-device.ps1" %*
