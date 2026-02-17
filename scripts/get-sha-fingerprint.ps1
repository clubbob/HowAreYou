# SHA 지문 확인 스크립트 (Firebase Console 등록용)
# 사용: .\scripts\get-sha-fingerprint.ps1

$ErrorActionPreference = "Stop"
$keystore = "$env:USERPROFILE\.android\debug.keystore"

if (-not (Test-Path $keystore)) {
    Write-Host "오류: debug.keystore를 찾을 수 없습니다." -ForegroundColor Red
    Write-Host "  경로: $keystore" -ForegroundColor Yellow
    exit 1
}

# keytool 경로 (Eclipse Adoptium 또는 시스템 PATH)
$keytool = $null
if (Test-Path "C:\Program Files\Eclipse Adoptium\jdk-25.0.1.8-hotspot\bin\keytool.exe") {
    $keytool = "C:\Program Files\Eclipse Adoptium\jdk-25.0.1.8-hotspot\bin\keytool.exe"
} else {
    $keytool = (Get-Command keytool -ErrorAction SilentlyContinue).Source
}
if (-not $keytool) {
    Write-Host "오류: keytool을 찾을 수 없습니다. Java JDK가 설치되어 있는지 확인하세요." -ForegroundColor Red
    exit 1
}

Write-Host "`n=== 디버그 키스토어 SHA 지문 ===" -ForegroundColor Cyan
$env:JAVA_TOOL_OPTIONS = $null
$output = & $keytool -list -keystore $keystore -alias androiddebugkey -storepass android -keypass android 2>$null
if (-not $output) {
    $output = & $keytool -list -keystore $keystore -alias androiddebugkey -storepass android -keypass android 2>&1 | Out-String
}

$sha256 = $output | Select-String "SHA-256" | ForEach-Object { ($_ -split ":")[-1].Trim() }
if ($sha256) {
    Write-Host "`nSHA-256 (Firebase에 이 값 등록):" -ForegroundColor Green
    Write-Host "  $sha256" -ForegroundColor White
}

# SHA-1 시도 (export 후 printcert)
$certFile = "$env:TEMP\howareyou_debug_cert.der"
try {
    & $keytool -exportcert -alias androiddebugkey -keystore $keystore -storepass android -file $certFile 2>&1 | Out-Null
    if (Test-Path $certFile) {
        $printOut = & $keytool -printcert -file $certFile 2>&1
        $sha1 = $printOut | Select-String "SHA1:" | ForEach-Object { ($_ -split ":", 2)[-1].Trim() }
        if ($sha1) {
            Write-Host "`nSHA-1 (Firebase에 이 값 등록):" -ForegroundColor Green
            Write-Host "  $sha1" -ForegroundColor White
        }
        Remove-Item $certFile -Force -ErrorAction SilentlyContinue
    }
} catch {}

Write-Host "`n=== Firebase Console 등록 방법 ===" -ForegroundColor Cyan
Write-Host "1. https://console.firebase.google.com/ 접속"
Write-Host "2. 프로젝트 howareyou-1c5de 선택"
Write-Host "3. 프로젝트 설정 > 내 앱 > Android 앱 선택"
Write-Host "4. SHA 인증서 지문 > 지문 추가"
Write-Host "5. 위 SHA-256 또는 SHA-1 값 붙여넣기"
Write-Host "6. 저장 후 google-services.json 다시 다운로드하여 android/app/에 복사"
Write-Host ""
