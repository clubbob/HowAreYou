# EGL_emulation / app_time_stats 로그 제외 후 flutter run 실행
# 반복 로그 방지: 터미널에서는 반드시 이 스크립트로 실행 (flutter run 직접 사용 시 EGL 로그 반복)
# 사용: .\run-android.ps1   또는   .\run-android.ps1 -d emulator-5554

$ErrorActionPreference = "Stop"

# 필터링할 패턴들 (더 강력한 필터링)
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

function Filter-EGLLogs {
    process {
        $line = $_
        if ([string]::IsNullOrWhiteSpace($line)) {
            return
        }
        
        # EGL 관련 로그 완전 차단
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

# legal/ → assets/ 동기화 (약관·개인정보처리방침)
try { node scripts/sync-legal.js 2>$null } catch { }

Write-Host "`n앱 실행 중 (EGL 로그 필터링)...`n" -ForegroundColor Cyan

flutter run @args 2>&1 | Filter-EGLLogs
