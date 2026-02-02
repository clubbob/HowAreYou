@echo off
REM EGL 로그 제외하고 실행 (반복 로그 방지). 터미널에서는 이 파일 또는 run-android.ps1 사용.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0run-android.ps1" %*
