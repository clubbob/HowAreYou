# EGL 로그 완전 필터링 버전
# 사용: .\run-android-filtered.ps1 또는 .\run-android-filtered.ps1 -d emulator-5554

$ErrorActionPreference = "Stop"

# EGL 및 불필요한 로그 필터링 함수
function Filter-Logs {
    $filterPatterns = @(
        'EGL_emulation',
        'app_time_stats',
        'FrameTracker',
        'PRIMARY FOCUS',
        'FocusScopeNode',
        'FocusNode',
        'FocusManager',
        'Root Focus Scope',
        '_ModalScopeState'
    )
    
    process {
        $line = $_
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

Write-Host "`n앱 실행 중 (EGL 로그 필터링)...`n" -ForegroundColor Cyan

# Flutter 앱 실행 (모든 출력을 필터링)
flutter run @args 2>&1 | Filter-Logs
