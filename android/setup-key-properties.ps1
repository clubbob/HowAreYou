# key.properties 설정 스크립트
# Usage: .\setup-key-properties.ps1
# key.properties가 없으면 example을 복사하고, 실제 비밀번호 입력을 안내합니다.

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$keyProps = Join-Path $scriptDir "key.properties"
$example = Join-Path $scriptDir "key.properties.example"

if (-not (Test-Path $example)) {
    Write-Host "에러: key.properties.example을 찾을 수 없습니다." -ForegroundColor Red
    exit 1
}

if (Test-Path $keyProps) {
    Write-Host "key.properties가 이미 존재합니다." -ForegroundColor Green
    Write-Host "경로: $keyProps" -ForegroundColor Gray
    Write-Host "`n수정이 필요하면 직접 편집하세요. (storePassword, keyPassword, keyAlias, storeFile)" -ForegroundColor Cyan
    exit 0
}

Copy-Item $example $keyProps
Write-Host "key.properties를 생성했습니다." -ForegroundColor Green
Write-Host "경로: $keyProps`n" -ForegroundColor Gray
Write-Host "다음 단계:" -ForegroundColor Yellow
Write-Host "1. key.properties를 열어 YOUR_STORE_PASSWORD, YOUR_KEY_PASSWORD를 실제 비밀번호로 교체" -ForegroundColor White
Write-Host "2. upload-keystore.jks 생성 시 설정한 비밀번호와 동일해야 합니다" -ForegroundColor White
Write-Host "3. keyAlias=upload, storeFile=../upload-keystore.jks 는 그대로 두세요`n" -ForegroundColor White
Write-Host "참고: docs\스토어-서명-키-준비.md" -ForegroundColor Cyan
