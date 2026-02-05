# Flutter devices 번호 선택 스크립트
# 사용: .\flutter-devices.ps1
# flutter devices 명령어를 대체하여 번호로 선택 가능하게 함

$ErrorActionPreference = "Stop"

Write-Host "`n연결된 기기 확인 중...`n" -ForegroundColor Cyan

# flutter devices 실행
$devicesOutput = flutter devices 2>&1

# "Found X connected devices:" 라인 찾기
$foundLine = $devicesOutput | Select-String "Found \d+ connected devices:"
if (-not $foundLine) {
    # 기기가 없거나 다른 형식의 출력
    Write-Host $devicesOutput
    exit 0
}

# 기기 목록 파싱
$deviceLines = @()
$inDeviceList = $false
$deviceIndex = 0
$infoLines = @()

foreach ($line in $devicesOutput) {
    if ($line -match "Found \d+ connected devices:") {
        $inDeviceList = $true
        Write-Host $line -ForegroundColor Green
        Write-Host ""
        continue
    }
    
    if ($inDeviceList) {
        # 기기 라인 파싱 (예: "  sdk gphone64 x86 64 (mobile) • emulator-5554 • android-x64    • Android 14 (API 34)")
        if ($line -match "^\s+(.+?)\s+•\s+(\S+)\s+•\s+(.+?)(?:\s+•\s+(.+))?$") {
            $deviceName = $matches[1].Trim()
            $deviceId = $matches[2].Trim()
            $devicePlatform = $matches[3].Trim()
            $deviceVersion = if ($matches[4]) { $matches[4].Trim() } else { "" }
            
            $deviceIndex++
            
            # 에뮬레이터인지 확인
            $isEmulator = $deviceId -match "^emulator-"
            
            # 기기 타입과 이름 추출
            $displayName = $deviceName
            if ($deviceName -match "Pixel.*6") {
                $displayName = "Pixel 6 (보호자)"
            } elseif ($deviceName -match "Pixel.*7") {
                $displayName = "Pixel 7 (보호 대상자)"
            } elseif ($isEmulator) {
                $displayName = "$deviceName (에뮬레이터)"
            }
            
            $deviceLines += @{
                Index = $deviceIndex
                Name = $displayName
                Id = $deviceId
                Platform = $devicePlatform
                Version = $deviceVersion
                IsEmulator = $isEmulator
            }
            
            Write-Host "  [$deviceIndex] $displayName" -ForegroundColor White
            Write-Host "      ID: $deviceId" -ForegroundColor Gray
            Write-Host "      플랫폼: $devicePlatform" -ForegroundColor Gray
            if ($deviceVersion) {
                Write-Host "      버전: $deviceVersion" -ForegroundColor Gray
            }
            Write-Host ""
        } elseif ($line.Trim() -eq "") {
            # 빈 줄은 건너뛰기
            continue
        } elseif ($line -match "Run \"flutter emulators\"" -or $line -match "If you expected") {
            # 안내 메시지는 저장
            $infoLines += $line
        } else {
            # 기기 목록이 끝났거나 다른 형식의 라인
            break
        }
    }
}

if ($deviceLines.Count -eq 0) {
    Write-Host "`n선택 가능한 기기가 없습니다." -ForegroundColor Yellow
    if ($infoLines.Count -gt 0) {
        Write-Host ""
        $infoLines | Write-Host
    }
    exit 0
}

Write-Host ("=" * 60) -ForegroundColor Cyan
$selection = Read-Host "`n기기를 선택하세요 (1-$($deviceLines.Count)) 또는 Enter로 목록만 보기"

# Enter만 눌렀으면 목록만 보여주고 종료
if ([string]::IsNullOrWhiteSpace($selection)) {
    Write-Host "`n기기 선택을 취소했습니다." -ForegroundColor Gray
    exit 0
}

# 선택 검증
if (-not ($selection -match '^\d+$') -or [int]$selection -lt 1 -or [int]$selection -gt $deviceLines.Count) {
    Write-Host "`n에러: 잘못된 선택입니다. (1-$($deviceLines.Count) 사이의 숫자를 입력하세요)" -ForegroundColor Red
    exit 1
}

$selectedDevice = $deviceLines[[int]$selection - 1]

Write-Host "`n" + ("=" * 60) -ForegroundColor Green
Write-Host "선택한 기기: $($selectedDevice.Name)" -ForegroundColor Green
Write-Host "기기 ID: $($selectedDevice.Id)" -ForegroundColor Cyan
Write-Host "플랫폼: $($selectedDevice.Platform)" -ForegroundColor Gray
if ($selectedDevice.Version) {
    Write-Host "버전: $($selectedDevice.Version)" -ForegroundColor Gray
}
Write-Host ("=" * 60) -ForegroundColor Green

# 선택한 기기 ID를 환경 변수로 설정
$env:FLUTTER_DEVICE_ID = $selectedDevice.Id

Write-Host "`n이 기기에서 앱을 실행하려면:" -ForegroundColor Yellow
Write-Host "  flutter run -d $($selectedDevice.Id)" -ForegroundColor White
Write-Host "`n또는 선택 스크립트 사용 (EGL 로그 필터링 포함):" -ForegroundColor Yellow
Write-Host "  .\run-select-device.ps1" -ForegroundColor White
Write-Host ""
