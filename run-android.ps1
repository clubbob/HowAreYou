# EGL_emulation / app_time_stats 로그 제외 후 flutter run 실행
# 반복 로그 방지: 터미널에서는 반드시 이 스크립트로 실행 (flutter run 직접 사용 시 EGL 로그 반복)
# 사용: .\run-android.ps1   또는   .\run-android.ps1 -d emulator-5554

$ErrorActionPreference = "Stop"
# D/EGL_emulation, app_time_stats 포함 줄 제거
$filterPattern = 'EGL_emulation|app_time_stats'

function Filter-EGLLogs {
    process {
        if ($_ -notmatch $filterPattern) { $_ }
    }
}

flutter run @args 2>&1 | Filter-EGLLogs
