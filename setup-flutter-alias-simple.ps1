# Flutter 별칭 설정 스크립트 (간단 버전)
# 사용: .\setup-flutter-alias-simple.ps1
# 실행 후: . $PROFILE (현재 세션에 적용)

$ErrorActionPreference = "Stop"

Write-Host "`nFlutter 별칭 설정 중...`n" -ForegroundColor Cyan

# 현재 프로젝트 경로
$projectPath = $PSScriptRoot
$runScriptPath = Join-Path $projectPath "run-android.ps1"
$devicesScriptPath = Join-Path $projectPath "flutter-devices.ps1"
$selectScriptPath = Join-Path $projectPath "run-select-device.ps1"

# PowerShell 프로필 경로 확인
$profilePath = $PROFILE.CurrentUserAllHosts
$profileDir = Split-Path -Parent $profilePath

# 프로필 디렉토리가 없으면 생성
if (-not (Test-Path $profileDir)) {
    New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
    Write-Host "프로필 디렉토리 생성: $profileDir" -ForegroundColor Green
}

# 프로필 파일이 없으면 생성
if (-not (Test-Path $profilePath)) {
    New-Item -ItemType File -Path $profilePath -Force | Out-Null
    Write-Host "프로필 파일 생성: $profilePath" -ForegroundColor Green
}

# 별칭 함수 정의
$aliasFunction = @"

# Flutter Run 별칭 (EGL 로그 자동 필터링) - HowAreYou 프로젝트
function fr {
    param(
        [Parameter(ValueFromRemainingArguments=`$true)]
        [string[]]`$args
    )
    
    `$scriptPath = "$runScriptPath"
    
    if (Test-Path `$scriptPath) {
        & `$scriptPath @args
    } else {
        Write-Host "경고: run-android.ps1 스크립트를 찾을 수 없습니다." -ForegroundColor Yellow
        Write-Host "경로: `$scriptPath" -ForegroundColor Yellow
        flutter run @args
    }
}

# Flutter Devices 별칭 (번호 선택)
function fd {
    param(
        [Parameter(ValueFromRemainingArguments=`$true)]
        [string[]]`$args
    )
    
    `$scriptPath = "$devicesScriptPath"
    
    if (Test-Path `$scriptPath) {
        & `$scriptPath @args
    } else {
        flutter devices @args
    }
}

# Flutter Run Select Device 별칭 (에뮬레이터 선택)
function frs {
    param(
        [Parameter(ValueFromRemainingArguments=`$true)]
        [string[]]`$args
    )
    
    `$scriptPath = "$selectScriptPath"
    
    if (Test-Path `$scriptPath) {
        & `$scriptPath @args
    } else {
        Write-Host "경고: run-select-device.ps1 스크립트를 찾을 수 없습니다." -ForegroundColor Yellow
        flutter run @args
    }
}

"@

# 프로필 파일에 이미 별칭이 있는지 확인
$profileContent = Get-Content $profilePath -ErrorAction SilentlyContinue -Raw
$hasAlias = $profileContent -match "# Flutter Run 별칭.*HowAreYou"

if ($hasAlias) {
    Write-Host "별칭이 이미 설정되어 있습니다." -ForegroundColor Yellow
    Write-Host "프로필 파일: $profilePath" -ForegroundColor Gray
    Write-Host "`n현재 세션에 적용하려면 다음 명령어 실행:" -ForegroundColor Cyan
    Write-Host "  . `$PROFILE" -ForegroundColor White
    Write-Host "`n사용 가능한 별칭:" -ForegroundColor Green
    Write-Host "  fr  - flutter run (EGL 로그 필터링)" -ForegroundColor White
    Write-Host "  fd  - flutter devices (번호 선택)" -ForegroundColor White
    Write-Host "  frs - flutter run select (에뮬레이터 선택)" -ForegroundColor White
} else {
    # 프로필 파일에 추가
    $separator = "`n# ========================================`n"
    Add-Content -Path $profilePath -Value "$separator# Flutter 별칭 (HowAreYou 프로젝트)$separator$aliasFunction"
    Write-Host "별칭이 성공적으로 추가되었습니다!" -ForegroundColor Green
    Write-Host "프로필 파일: $profilePath" -ForegroundColor Gray
    Write-Host "`n현재 세션에 적용하려면 다음 명령어 실행:" -ForegroundColor Cyan
    Write-Host "  . `$PROFILE" -ForegroundColor White
    Write-Host "`n사용 가능한 별칭:" -ForegroundColor Green
    Write-Host "  fr  - flutter run (EGL 로그 필터링)" -ForegroundColor White
    Write-Host "  fd  - flutter devices (번호 선택)" -ForegroundColor White
    Write-Host "  frs - flutter run select (에뮬레이터 선택)" -ForegroundColor White
}

Write-Host "`n사용 예시:" -ForegroundColor Green
Write-Host "  fr -d emulator-5554    # 앱 실행 (EGL 로그 필터링)" -ForegroundColor Gray
Write-Host "  fd                     # 기기 목록 (번호 선택)" -ForegroundColor Gray
Write-Host "  frs                    # 에뮬레이터 선택 후 실행" -ForegroundColor Gray
