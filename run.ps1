# Flutter 실행 스크립트 - 디바이스 자동 선택
# 사용법: .\run.ps1 또는 run

Write-Host "연결된 디바이스 확인 중..." -ForegroundColor Cyan
$devices = flutter devices --machine | ConvertFrom-Json

if ($devices.Count -eq 0) {
    Write-Host "연결된 디바이스가 없습니다." -ForegroundColor Red
    Write-Host "에뮬레이터를 실행하거나 기기를 연결해주세요." -ForegroundColor Yellow
    exit 1
}

if ($devices.Count -eq 1) {
    $device = $devices[0]
    Write-Host "`n디바이스 1개 발견: $($device.name) ($($device.id))" -ForegroundColor Green
    Write-Host "자동으로 선택하여 실행합니다...`n" -ForegroundColor Cyan
    flutter run -d $device.id
} else {
    Write-Host "`n연결된 디바이스 목록:" -ForegroundColor Cyan
    Write-Host "========================`n" -ForegroundColor Cyan
    
    $index = 1
    foreach ($device in $devices) {
        $status = if ($device.category -eq "mobile") { "📱" } else { "💻" }
        Write-Host "[$index] $status $($device.name)" -ForegroundColor White
        Write-Host "    ID: $($device.id)" -ForegroundColor Gray
        Write-Host "    타입: $($device.category)" -ForegroundColor Gray
        Write-Host ""
        $index++
    }
    
    Write-Host "실행할 디바이스 번호를 선택하세요 (1-$($devices.Count)): " -NoNewline -ForegroundColor Yellow
    $choice = Read-Host
    
    try {
        $selectedIndex = [int]$choice - 1
        if ($selectedIndex -ge 0 -and $selectedIndex -lt $devices.Count) {
            $selectedDevice = $devices[$selectedIndex]
            Write-Host "`n선택된 디바이스: $($selectedDevice.name) ($($selectedDevice.id))" -ForegroundColor Green
            Write-Host "실행 중...`n" -ForegroundColor Cyan
            flutter run -d $selectedDevice.id
        } else {
            Write-Host "잘못된 번호입니다." -ForegroundColor Red
            exit 1
        }
    } catch {
        Write-Host "숫자를 입력해주세요." -ForegroundColor Red
        exit 1
    }
}
