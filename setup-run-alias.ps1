# run 명령어 설정 스크립트
# 사용법: .\setup-run-alias.ps1

Write-Host "`n'run' 명령어 설정 중...`n" -ForegroundColor Cyan

# PowerShell 프로필 경로 확인
$profilePath = $PROFILE.CurrentUserAllHosts

# 프로필 디렉토리가 없으면 생성
$profileDir = Split-Path -Parent $profilePath
if (-not (Test-Path $profileDir)) {
    New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
    Write-Host "프로필 디렉토리 생성: $profileDir" -ForegroundColor Green
}

# 현재 스크립트의 절대 경로
$scriptPath = Join-Path $PSScriptRoot "run.ps1"
$scriptPath = (Resolve-Path $scriptPath).Path

# 함수 추가
$functionCode = @"
# Flutter run 함수
function run {
    & "$scriptPath"
}
"@

# 프로필이 있으면 읽기, 없으면 새로 만들기
if (Test-Path $profilePath) {
    $profileContent = Get-Content $profilePath -Raw
    
    # 이미 함수가 있는지 확인
    if ($profileContent -match "function run\s*\{" -or $profileContent -match "function global:run\s*\{" ) {
        Write-Host "이미 'run' 함수가 프로필에 있습니다." -ForegroundColor Yellow
        Write-Host "프로필 위치: $profilePath" -ForegroundColor Gray
        Write-Host "`n기존 함수를 업데이트하시겠습니까? (Y/N): " -NoNewline -ForegroundColor Yellow
        $update = Read-Host
        
        if ($update -eq "Y" -or $update -eq "y") {
            # 기존 함수 제거
            $profileContent = $profileContent -replace "(?s)function (global:)?run\s*\{[^\}]*\}", ""
            $profileContent = $profileContent -replace "(?s)# Flutter run 함수.*?^}", "", "Multiline"
            $newContent = $profileContent.TrimEnd() + "`n`n" + $functionCode
            Set-Content -Path $profilePath -Value $newContent
            Write-Host "`n'run' 함수가 업데이트되었습니다!" -ForegroundColor Green
        } else {
            Write-Host "취소되었습니다." -ForegroundColor Yellow
            exit 0
        }
    } else {
        # 함수 추가
        Add-Content -Path $profilePath -Value "`n`n$functionCode"
        Write-Host "'run' 함수가 추가되었습니다!" -ForegroundColor Green
    }
} else {
    # 프로필이 없으면 새로 만들기
    Set-Content -Path $profilePath -Value $functionCode
    Write-Host "프로필이 생성되고 'run' 함수가 추가되었습니다!" -ForegroundColor Green
}

Write-Host "`n프로필 위치: $profilePath" -ForegroundColor Gray
Write-Host "`n설정 완료! 이제 'run'만 입력하면 됩니다." -ForegroundColor Green
Write-Host "`n주의: 새 PowerShell 창을 열어야 적용됩니다." -ForegroundColor Yellow
Write-Host "또는 다음 명령어로 현재 세션에 적용: " -ForegroundColor Yellow
Write-Host "  . `$PROFILE" -ForegroundColor Cyan
Write-Host ""
