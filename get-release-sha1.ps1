# Release keystore SHA-1 fingerprint checker
# Usage: .\get-release-sha1.ps1
# 비밀번호: key.properties의 storePassword/keyPassword (동일한 경우 많음)

$ErrorActionPreference = "Continue"

$keystorePath = Join-Path $PSScriptRoot "android\upload-keystore.jks"
$alias = "upload"

Write-Host "`nRelease SHA-1 지문 확인 중...`n" -ForegroundColor Cyan

if (-not (Test-Path $keystorePath)) {
    Write-Host "에러: upload-keystore.jks를 찾을 수 없습니다." -ForegroundColor Red
    Write-Host "경로: $keystorePath" -ForegroundColor Yellow
    Write-Host "`n먼저 docs\스토어-서명-키-준비.md를 참고해 keystore를 생성하세요." -ForegroundColor Yellow
    exit 1
}

# Try to find keytool (JDK 17 우선 - JDK 25 keytool에 로케일 버그 있음)
$possibleJdkPaths = @(
    "C:\Program Files\Eclipse Adoptium\jdk-17.0.13.11-hotspot",
    "C:\Program Files\Eclipse Adoptium\jdk-25.0.1.8-hotspot",
    "$env:ProgramFiles\Android\Android Studio\jbr",
    "$env:ProgramFiles\Android\Android Studio\jre",
    "C:\Program Files\Android\Android Studio\jbr",
    "C:\Program Files\Java\jdk-17",
    "C:\Program Files\Java\jdk-11"
)

$keytoolPath = $null
foreach ($jdkPath in $possibleJdkPaths) {
    $ktPath = Join-Path $jdkPath "bin\keytool.exe"
    if (Test-Path $ktPath) {
        $keytoolPath = $ktPath
        break
    }
}
if (-not $keytoolPath) { $keytoolPath = "keytool" }

Write-Host "키스토어: $keystorePath" -ForegroundColor Gray

$keyPropsPath = Join-Path $PSScriptRoot "android\key.properties"
$password = $null
if (Test-Path $keyPropsPath) {
    $content = Get-Content $keyPropsPath -Raw
    if ($content -match "storePassword\s*=\s*(.+)") {
        $password = $matches[1].Trim()
        Write-Host "key.properties에서 비밀번호 로드됨`n" -ForegroundColor Green
    }
}
if (-not $password) {
    Write-Host "비밀번호 입력이 필요합니다 (key.properties의 storePassword)`n" -ForegroundColor Yellow
    $securePass = Read-Host "Keystore 비밀번호" -AsSecureString
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePass)
    $password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
}

try {
    # keytool -list -v has locale bug (IllegalFormatConversionException). Use exportcert + certutil instead.
    $tempCert = Join-Path $env:TEMP "release-sha1-temp.cer"
    $exportOut = & $keytoolPath -exportcert -alias $alias -keystore $keystorePath -file $tempCert -storepass $password -keypass $password 2>&1
    
    if (-not (Test-Path $tempCert)) {
        Write-Host "Error: 인증서 내보내기 실패. 비밀번호를 확인하세요." -ForegroundColor Red
        if ($exportOut) { $exportOut | Write-Host }
        exit 1
    }
    
    $certutilOut = certutil -hashfile $tempCert SHA1 2>&1
    Remove-Item $tempCert -Force -ErrorAction SilentlyContinue
    
    # certutil 출력에서 SHA-1 추출 (한글/영문 로케일 모두 지원)
    $sha1 = $null
    foreach ($line in $certutilOut) {
        $hexBytes = [regex]::Matches($line, '[0-9a-fA-F]{2}')
        if ($hexBytes.Count -eq 20) {
            $sha1 = ($hexBytes.Value -join ':').ToUpper()
            break
        }
    }
    
    if ($sha1) {
        $sep = '=' * 70
        Write-Host "`n" + $sep -ForegroundColor Green
        Write-Host "Release SHA-1 지문 (Firebase에 등록할 값):" -ForegroundColor Yellow
        Write-Host $sha1 -ForegroundColor White -BackgroundColor DarkGreen
        Write-Host $sep -ForegroundColor Green
        Write-Host "`n다음 단계:" -ForegroundColor Cyan
        Write-Host "1. 위 SHA-1을 복사" -ForegroundColor White
        Write-Host "2. Firebase Console -> 프로젝트 설정 -> 내 앱 -> Android 앱 (com.andy.howareyou)" -ForegroundColor White
        Write-Host "3. 디지털 지문 추가 -> SHA-1 선택 -> 붙여넣기 -> 저장" -ForegroundColor White
        Write-Host $sep -ForegroundColor Cyan
    } else {
        Write-Host ""
        Write-Host "Error: SHA-1 not found. Check password or certutil output." -ForegroundColor Red
        $certutilOut | Write-Host
    }
} catch {
    Write-Host ""
    Write-Host "Error: keytool execution failed" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}
