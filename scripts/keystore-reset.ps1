# Keystore 리셋 스크립트 (Play Console 미배포 시에만 실행)
# 실행: .\scripts\keystore-reset.ps1

$ErrorActionPreference = "Stop"
$projectRoot = Join-Path $PSScriptRoot ".."
$androidDir = Join-Path $projectRoot "android"
$keystorePath = Join-Path $androidDir "upload-keystore.jks"
$keyPropsPath = Join-Path $androidDir "key.properties"

Write-Host "=== Keystore 리셋 ===" -ForegroundColor Cyan
Write-Host ""

# 0. 삭제 실패 방지: Gradle/Java 파일 핸들 해제
Write-Host "0. Gradle/Java daemon 종료 (파일 잠금 해제)" -ForegroundColor Yellow
Push-Location $projectRoot
try {
    $gradlew = Join-Path $projectRoot "android\gradlew.bat"
    if (Test-Path $gradlew) {
        & $gradlew --stop 2>$null
        Write-Host "   gradlew --stop 완료" -ForegroundColor Gray
    }
    # java.exe 전체 종료가 부담되면 아래 줄 주석 처리 (gradlew --stop만으로 충분할 수 있음)
    # taskkill /F /IM java.exe 2>$null
    # taskkill /F /IM studio64.exe 2>$null
} finally {
    Pop-Location
}
Write-Host ""

# 1. 기존 keystore 삭제
if (Test-Path $keystorePath) {
    Write-Host "1. 기존 keystore 삭제 중..." -ForegroundColor Yellow
    try {
        Remove-Item $keystorePath -Force -ErrorAction Stop
        Write-Host "   삭제 완료" -ForegroundColor Green
    } catch {
        Write-Host "   Remove-Item 실패. del /F 시도..." -ForegroundColor Yellow
        $delResult = cmd /c "del /F `"$keystorePath`""
        if ($LASTEXITCODE -ne 0) {
            Write-Host "   오류: 파일이 다른 프로세스에서 사용 중입니다." -ForegroundColor Red
            Write-Host "   Android Studio, Cursor를 완전 종료한 뒤 다시 시도하세요." -ForegroundColor Red
            Write-Host "   또는 수동: gradlew --stop 후 taskkill /F /IM java.exe" -ForegroundColor Gray
            exit 1
        }
        Write-Host "   삭제 완료" -ForegroundColor Green
    }
} else {
    Write-Host "1. 기존 keystore 없음 (건너뜀)" -ForegroundColor Gray
}

# 2. 새 keystore 생성 (대화형)
Write-Host ""
Write-Host "2. 새 keystore 생성" -ForegroundColor Yellow
Write-Host "   아래 입력 시: Keystore password = Hru2026!, Key password = Enter (동일)" -ForegroundColor Gray
Write-Host ""

Push-Location $androidDir
try {
    keytool -genkeypair -v -keystore upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
    if ($LASTEXITCODE -ne 0) { exit 1 }
} finally {
    Pop-Location
}

Write-Host ""
Write-Host "   [Storing upload-keystore.jks] 메시지가 보이면 성공" -ForegroundColor Green
Write-Host ""

# 2.5 즉시 검증 (비번/경로/alias 문제를 빌드 전에 발견)
Write-Host "2.5 keystore 즉시 검증" -ForegroundColor Yellow
$verifyResult = keytool -list -v -keystore $keystorePath -alias upload -storepass "Hru2026!" 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "   검증 실패: keytool이 keystore를 열 수 없습니다." -ForegroundColor Red
    Write-Host "   비밀번호/경로/alias를 확인하세요. 빌드 전에 수정 필요." -ForegroundColor Red
    exit 1
}
Write-Host "   검증 성공 (keystore 정상)" -ForegroundColor Green
Write-Host ""

# 3. key.properties 업데이트
Write-Host "3. key.properties 업데이트" -ForegroundColor Yellow
$content = @"
storePassword=Hru2026!
keyPassword=Hru2026!
keyAlias=upload
storeFile=upload-keystore.jks
"@
Set-Content -Path $keyPropsPath -Value $content -Encoding UTF8
Write-Host "   완료" -ForegroundColor Green
Write-Host ""

# 4. SHA-1 추출
Write-Host "4. SHA-1 추출 (Firebase Console에 등록하세요)" -ForegroundColor Yellow
$sha1Output = keytool -list -v -keystore $keystorePath -alias upload -storepass "Hru2026!" 2>&1
$sha1Line = $sha1Output | Select-String "SHA1:"
if ($sha1Line) {
    Write-Host $sha1Line -ForegroundColor White
    Write-Host ""
    Write-Host "   Firebase Console -> 프로젝트 설정 -> Android 앱 -> SHA 인증서 지문 추가" -ForegroundColor Gray
} else {
    Write-Host "   SHA-1 추출 실패. 수동 실행: keytool -list -v -keystore android/upload-keystore.jks -alias upload" -ForegroundColor Red
}
Write-Host ""

# 5. google-services.json 안내
Write-Host "5. google-services.json 재다운로드 필요" -ForegroundColor Yellow
Write-Host "   Firebase Console에서 다운로드 -> android/app/google-services.json 덮어쓰기" -ForegroundColor Gray
Write-Host ""

# 6. 빌드 안내
Write-Host "6. 클린 빌드" -ForegroundColor Yellow
Write-Host "   flutter clean" -ForegroundColor Gray
Write-Host "   flutter build appbundle --release" -ForegroundColor Gray
Write-Host ""
Write-Host "=== 완료 ===" -ForegroundColor Cyan
