# 프로젝트 폴더에서 이렇게 쓰세요: .\adb.ps1 devices
# 예: .\adb.ps1 devices   또는   .\adb.ps1 shell am start -a android.settings.INPUT_METHOD_SETTINGS

$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
if (!(Test-Path $adb)) {
    Write-Host "adb를 찾을 수 없습니다: $adb"
    exit 1
}
& $adb @args
