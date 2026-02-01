# Android SDK platform-tools를 사용자 PATH에 추가합니다.
# 이 스크립트를 PowerShell에서 한 번 실행하세요: .\add-adb-to-path.ps1

$platformTools = "$env:LOCALAPPDATA\Android\Sdk\platform-tools"
$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")

if ($currentPath -like "*platform-tools*") {
    Write-Host "이미 PATH에 있습니다: $platformTools"
} else {
    [Environment]::SetEnvironmentVariable("Path", "$currentPath;$platformTools", "User")
    Write-Host "PATH에 추가했습니다: $platformTools"
    Write-Host "새 터미널을 열면 'adb' 명령을 사용할 수 있습니다."
}
