# 에뮬레이터 선택 후 실행 스크립트
# 사용: .\run-select-device.ps1

$ErrorActionPreference = "Stop"

# EGL 로그 필터링 함수 (강화 버전)
function Filter-EGLLogs {
    $filterPatterns = @(
        'EGL_emulation',
        'app_time_stats',
        'FrameTracker',
        'PRIMARY FOCUS',
        'FocusScopeNode',
        'FocusNode',
        'FocusManager',
        'Root Focus Scope',
        '_ModalScopeState',
        'IME_INSETS_ANIMATION',
        'force finish'
    )
    
    process {
        $line = $_
        if ([string]::IsNullOrWhiteSpace($line)) {
            return
        }
        
        # EGL 관련 로그 완전 차단 (최우선)
        if ($line -match 'EGL_emulation|app_time_stats') {
            return  # 즉시 필터링
        }
        
        $shouldFilter = $false
        
        foreach ($pattern in $filterPatterns) {
            if ($line -match $pattern) {
                $shouldFilter = $true
                break
            }
        }
        
        if (-not $shouldFilter) {
            $_
        }
    }
}

# 연결된 기기 목록 가져오기
Write-Host "`n연결된 기기 확인 중..." -ForegroundColor Cyan
$devicesOutput = flutter devices --machine 2>&1 | ConvertFrom-Json

# Android 에뮬레이터만 필터링
$emulators = $devicesOutput.devices | Where-Object { 
    $_.category -eq "mobile" -and $_.emulator -eq $true 
}

if ($emulators.Count -eq 0) {
    Write-Host "`n에러: 실행 중인 Android 에뮬레이터가 없습니다." -ForegroundColor Red
    Write-Host "Android Studio에서 에뮬레이터를 먼저 실행해주세요." -ForegroundColor Yellow
    exit 1
}

# 에뮬레이터 목록 표시
Write-Host "`n사용 가능한 에뮬레이터:" -ForegroundColor Green
Write-Host ""

$index = 1
$deviceMap = @{}

foreach ($emu in $emulators) {
    $deviceId = $emu.id
    $deviceName = $emu.name
    
    # 에뮬레이터 이름에서 Pixel 정보 추출 시도
    $displayName = $deviceName
    if ($deviceName -match "Pixel.*6") {
        $displayName = "Pixel 6 (보호자) - $deviceId"
    } elseif ($deviceName -match "Pixel.*7") {
        $displayName = "Pixel 7 (보호 대상자) - $deviceId"
    } else {
        $displayName = "$deviceName - $deviceId"
    }
    
    Write-Host "  [$index] $displayName" -ForegroundColor White
    $deviceMap[$index] = $deviceId
    $index++
}

Write-Host ""
$selection = Read-Host "사용할 에뮬레이터 번호를 선택하세요 (1-$($emulators.Count))"

# 선택 검증
if (-not ($selection -match '^\d+$') -or [int]$selection -lt 1 -or [int]$selection -gt $emulators.Count) {
    Write-Host "`n에러: 잘못된 선택입니다." -ForegroundColor Red
    exit 1
}

$selectedDeviceId = $deviceMap[[int]$selection]
$selectedDevice = $emulators | Where-Object { $_.id -eq $selectedDeviceId }

Write-Host "`n선택한 기기: $($selectedDevice.name) ($selectedDeviceId)" -ForegroundColor Green
Write-Host "앱 실행 중...`n" -ForegroundColor Cyan

# Flutter 앱 실행 (EGL 로그 필터링)
flutter run -d $selectedDeviceId @args 2>&1 | Filter-EGLLogs
