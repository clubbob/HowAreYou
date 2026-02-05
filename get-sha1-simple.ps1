# Simple SHA-1 fingerprint checker using Android Studio's JDK
# Usage: .\get-sha1-simple.ps1

$ErrorActionPreference = "Continue"

Write-Host "`nSHA-1 지문 확인 중...`n" -ForegroundColor Cyan

# Try to find Android Studio JDK
$possibleJdkPaths = @(
    "$env:LOCALAPPDATA\Android\Sdk",
    "$env:ProgramFiles\Android\Android Studio\jbr",
    "$env:ProgramFiles\Android\Android Studio\jre",
    "$env:ProgramFiles\Android\Android Studio\jdk",
    "C:\Program Files\Android\Android Studio\jbr",
    "C:\Program Files\Android\Android Studio\jre"
)

$keytoolPath = $null
foreach ($jdkPath in $possibleJdkPaths) {
    $ktPath = Join-Path $jdkPath "bin\keytool.exe"
    if (Test-Path $ktPath) {
        $keytoolPath = $ktPath
        Write-Host "JDK 발견: $jdkPath" -ForegroundColor Green
        break
    }
}

if (-not $keytoolPath) {
    Write-Host "Android Studio JDK를 찾을 수 없습니다. 시스템 Java를 사용합니다." -ForegroundColor Yellow
    $keytoolPath = "keytool"
}

$keystorePath = "$env:USERPROFILE\.android\debug.keystore"

if (-not (Test-Path $keystorePath)) {
    Write-Host "에러: 디버그 키스토어를 찾을 수 없습니다." -ForegroundColor Red
    Write-Host "경로: $keystorePath" -ForegroundColor Yellow
    exit 1
}

Write-Host "키스토어 경로: $keystorePath" -ForegroundColor Gray
Write-Host "keytool 경로: $keytoolPath`n" -ForegroundColor Gray

try {
    Write-Host "keytool 실행 중...`n" -ForegroundColor Cyan
    
    $output = & $keytoolPath -list -v -keystore $keystorePath -alias androiddebugkey -storepass android -keypass android 2>&1
    
    $sha1 = $null
    $sha256 = $null
    
    foreach ($line in $output) {
        if ($line -match "SHA1:\s*(.+)") {
            $sha1 = $matches[1].Trim()
        }
        if ($line -match "SHA256:\s*(.+)") {
            $sha256 = $matches[1].Trim()
        }
    }
    
    if ($sha1) {
        Write-Host ("=" * 70) -ForegroundColor Green
        Write-Host "SHA-1 지문 (Firebase에 등록할 값):" -ForegroundColor Yellow
        Write-Host $sha1 -ForegroundColor White -BackgroundColor DarkGreen
        Write-Host ("=" * 70) -ForegroundColor Green
        
        Write-Host "`nSHA-256 지문 (선택사항):" -ForegroundColor Gray
        Write-Host $sha256 -ForegroundColor Gray
        
        Write-Host "`n" + ("=" * 70) -ForegroundColor Cyan
        Write-Host "다음 단계:" -ForegroundColor Yellow
        Write-Host "1. 위의 SHA-1 지문을 복사하세요" -ForegroundColor White
        Write-Host "2. Firebase Console 접속: https://console.firebase.google.com/" -ForegroundColor White
        Write-Host "3. 프로젝트 선택: howareyou-1c5de" -ForegroundColor White
        Write-Host "4. 프로젝트 설정 (톱니바퀴 아이콘) 클릭" -ForegroundColor White
        Write-Host "5. 내 앱 → Android 앱 선택" -ForegroundColor White
        Write-Host "6. SHA 인증서 지문 → 지문 추가" -ForegroundColor White
        Write-Host "7. Copy and paste the SHA-1 fingerprint above and save" -ForegroundColor White
        Write-Host ("=" * 70) -ForegroundColor Cyan
    } else {
        Write-Host "`n에러: SHA 지문을 찾을 수 없습니다." -ForegroundColor Red
        Write-Host "`n전체 출력:" -ForegroundColor Yellow
        $output | Write-Host
    }
} catch {
    Write-Host "`n에러: keytool 실행 실패" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host "`n수동으로 실행해보세요:" -ForegroundColor Yellow
    Write-Host "keytool -list -v -keystore `"$keystorePath`" -alias androiddebugkey -storepass android -keypass android" -ForegroundColor Gray
}
