# Debug keystore SHA-1 fingerprint checker
# Usage: .\get-sha1.ps1

Write-Host "`nChecking debug keystore SHA-1 fingerprint...`n" -ForegroundColor Cyan

$keystorePath = "$env:USERPROFILE\.android\debug.keystore"

if (-not (Test-Path $keystorePath)) {
    Write-Host "Error: Debug keystore not found." -ForegroundColor Red
    Write-Host "Path: $keystorePath" -ForegroundColor Yellow
    exit 1
}

try {
    $output = keytool -list -v -keystore $keystorePath -alias androiddebugkey -storepass android -keypass android 2>&1
    
    $sha1 = $output | Select-String "SHA1:" | ForEach-Object { 
        $line = $_.Line
        if ($line -match "SHA1:\s*(.+)") {
            $matches[1].Trim()
        }
    }
    
    $sha256 = $output | Select-String "SHA256:" | ForEach-Object { 
        $line = $_.Line
        if ($line -match "SHA256:\s*(.+)") {
            $matches[1].Trim()
        }
    }
    
    if ($sha1) {
        Write-Host "SHA-1 Fingerprint:" -ForegroundColor Green
        Write-Host "  $sha1`n" -ForegroundColor White
        
        Write-Host "SHA-256 Fingerprint:" -ForegroundColor Green
        Write-Host "  $sha256`n" -ForegroundColor White
        
        Write-Host ("=" * 60) -ForegroundColor Cyan
        Write-Host "Next Steps:" -ForegroundColor Yellow
        Write-Host "1. Go to Firebase Console: https://console.firebase.google.com/" -ForegroundColor White
        Write-Host "2. Select project: howareyou-1c5de" -ForegroundColor White
        Write-Host "3. Click Project Settings (gear icon)" -ForegroundColor White
        Write-Host "4. Select Android app" -ForegroundColor White
        Write-Host "5. SHA certificate fingerprints -> Add fingerprint" -ForegroundColor White
        Write-Host "6. Enter the SHA-1 fingerprint above and save" -ForegroundColor White
        Write-Host ("=" * 60) -ForegroundColor Cyan
    } else {
        Write-Host "Error: Could not find SHA fingerprints." -ForegroundColor Red
        Write-Host "`nFull output:" -ForegroundColor Yellow
        $output | Write-Host
    }
} catch {
    Write-Host "Error: Failed to check keystore" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
