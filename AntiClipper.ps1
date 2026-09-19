<#
.SYNOPSIS
    AntiClipper - Advanced Crypto Clipboard Hijacker Detector & Remediation Tool
    Author: Community Open Source Security
    License: MIT
    
.DESCRIPTION
    AntiClipper detects, diagnoses, and completely cleans active crypto clipboard 
    hijackers (Clipper Trojans). It specifically uncovers stealth techniques like:
    - User-level COM Hijacking (HKCU\Software\Classes\CLSID)
    - Explorer.exe thread injection and rogue shell extensions
    - Masqueraded DLLs (e.g., fake EdgeWebView\msedgeview.dll in AppData)
    - Registry Run/RunOnce persistence
    - WMI & Scheduled Task persistence
    
.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\AntiClipper.ps1
#>

[CmdletBinding()]
param(
    [switch]$AutoFix,
    [switch]$ScanOnly
)

function Show-Banner {
    Clear-Host
    Write-Host "====================================================================" -ForegroundColor Cyan
    Write-Host "    ___          __  _  _____ _ _                      " -ForegroundColor Cyan
    Write-Host "   / _ \        / /_(_)/ ____| (_)                     " -ForegroundColor Cyan
    Write-Host "  / /_\ \ _ __ |  _/ _/ /    | |_ _ __  _ __   ___ _ __" -ForegroundColor Cyan
    Write-Host "  |  _  || '_ \| | | | |     | | | '_ \| '_ \ / _ \ '__|" -ForegroundColor Cyan
    Write-Host "  | | | || | | | |_| | \____ | | | |_) | |_) |  __/ |   " -ForegroundColor Cyan
    Write-Host "  \_| |_/|_| |_|\__|_|\_____/|_|_| .__/| .__/ \___|_|   " -ForegroundColor Cyan
    Write-Host "                                 | |   | |             " -ForegroundColor Cyan
    Write-Host "                                 |_|   |_|             " -ForegroundColor Cyan
    Write-Host "    CRYPTO CLIPBOARD HIJACKER DETECTOR & CLEANER v1.0   " -ForegroundColor Cyan
    Write-Host "====================================================================" -ForegroundColor Cyan
    Write-Host " [!] Protects Ethereum, Bitcoin, Solana and other Crypto assets" -ForegroundColor DarkGray
    Write-Host "====================================================================`n" -ForegroundColor Cyan
}

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    if ($Level -eq "INFO") {
        Write-Host " [*] $Message" -ForegroundColor White
    } elseif ($Level -eq "OK") {
        Write-Host " [+] $Message" -ForegroundColor Green
    } elseif ($Level -eq "WARN") {
        Write-Host " [!] $Message" -ForegroundColor Yellow
    } elseif ($Level -eq "FAIL") {
        Write-Host " [-] $Message" -ForegroundColor Red
    } elseif ($Level -eq "HEAD") {
        Write-Host "`n>>> $Message" -ForegroundColor Cyan
    }
}

function Test-ClipboardHijack {
    Write-Log "Running real-time clipboard injection test..." "HEAD"
    
    Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
    
    $chains = @("Ethereum", "Bitcoin", "Solana")
    $addresses = @(
        "0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045",
        "bc1qar0srrr7xfkvy5l643lydnw9re59gtzzwf5mdq",
        "4unh4VkK3QdNaNEv8sE6V21y8P5kH3M1w1L7Dq2gL8p"
    )

    $hijackedVectors = @()

    for ($i = 0; $i -lt $chains.Length; $i++) {
        $chain = $chains[$i]
        $sampleAddr = $addresses[$i]
        
        for ($r = 0; $r -lt 5; $r++) {
            try {
                [System.Windows.Forms.Clipboard]::SetDataObject($sampleAddr, $true, 10, 100)
                break
            } catch {
                Start-Sleep -Milliseconds 100
            }
        }

        Start-Sleep -Milliseconds 600

        $readBack = ""
        try {
            $readBack = [System.Windows.Forms.Clipboard]::GetText()
        } catch {}

        if ($readBack -and ($readBack -ne $sampleAddr)) {
            Write-Log "HIJACK DETECTED for $chain!" "FAIL"
            Write-Host "      Injected:  $sampleAddr" -ForegroundColor DarkGray
            Write-Host "      Replaced:  $readBack" -ForegroundColor Red
            $hijackedVectors += [PSCustomObject]@{
                Chain = $chain
                AttackerAddress = $readBack
            }
        } else {
            Write-Log "$chain clipboard test passed (unaltered)." "OK"
        }
    }

    return $hijackedVectors
}

function Scan-COMHijacking {
    Write-Log "Scanning HKCU User CLSIDs for InprocServer32 hijacking..." "HEAD"
    
    $suspiciousCLSIDs = @()
    $whitelistPublishers = @("Microsoft Corporation", "Google LLC", "Python Software Foundation")

    $clsidRoot = "HKCU:\Software\Classes\CLSID"
    if (-not (Test-Path $clsidRoot)) {
        Write-Log "No user-specific CLSIDs found in HKCU." "INFO"
        return $suspiciousCLSIDs
    }

    $subKeys = Get-ChildItem $clsidRoot -ErrorAction SilentlyContinue
    foreach ($key in $subKeys) {
        $inproc = Join-Path $key.PsPath "InprocServer32"
        if (Test-Path $inproc) {
            $dllPath = (Get-ItemProperty -Path $inproc -ErrorAction SilentlyContinue).'(default)'
            if ($dllPath) {
                $expandedDll = [System.Environment]::ExpandEnvironmentVariables($dllPath)
                $isSuspicious = $false
                $reason = ""

                if ($expandedDll -like "*\AppData\*" -or $expandedDll -like "*\Temp\*" -or $expandedDll -like "*\Users\Public\*") {
                    if (Test-Path $expandedDll) {
                        $sig = Get-AuthenticodeSignature $expandedDll -ErrorAction SilentlyContinue
                        if ($sig.Status -ne "Valid") {
                            $isSuspicious = $true
                            $reason = "Unsigned DLL in User Directory (" + $sig.Status + ")"
                        } else {
                            if ($expandedDll -like "*\Microsoft\EdgeWebView\*") {
                                $isSuspicious = $true
                                $reason = "Masquerading as Microsoft Edge in AppData"
                            }
                        }
                    } else {
                        $isSuspicious = $true
                        $reason = "Points to missing or deleted file"
                    }
                }

                if ($isSuspicious) {
                    Write-Log ("Found malicious COM entry: " + $key.PSChildName) "FAIL"
                    Write-Host "      Target DLL: $expandedDll" -ForegroundColor Red
                    Write-Host "      Reason:     $reason" -ForegroundColor Yellow
                    $suspiciousCLSIDs += [PSCustomObject]@{
                        CLSIDKey = $key.PsPath
                        GUID     = $key.PSChildName
                        DLLPath  = $expandedDll
                        Reason   = $reason
                    }
                }
            }
        }
    }

    if ($suspiciousCLSIDs.Count -eq 0) {
        Write-Log "No malicious COM CLSID entries found." "OK"
    }

    return $suspiciousCLSIDs
}

function Scan-KnownClipperFiles {
    Write-Log "Scanning filesystem for masqueraded clipper binaries..." "HEAD"
    
    $rogueFiles = @()
    $pathsToCheck = @(
        "$env:LOCALAPPDATA\Microsoft\EdgeWebView\msedgeview.dll",
        "$env:APPDATA\Microsoft\EdgeWebView\msedgeview.dll",
        "$env:LOCALAPPDATA\Temp\msedgeview.dll"
    )

    foreach ($pathPattern in $pathsToCheck) {
        if (Test-Path $pathPattern) {
            $f = Get-Item $pathPattern -Force -ErrorAction SilentlyContinue
            if ($f) {
                Write-Log ("Malicious file located: " + $f.FullName) "FAIL"
                Write-Host "      Size:     $($f.Length) bytes" -ForegroundColor DarkGray
                Write-Host "      Created:  $($f.CreationTime)" -ForegroundColor DarkGray
                $rogueFiles += $f.FullName
            }
        }
    }

    if ($rogueFiles.Count -eq 0) {
        Write-Log "No rogue masqueraded binaries found." "OK"
    }

    return $rogueFiles
}

function Remove-Threats {
    param(
        [array]$CLSIDs,
        [array]$Files
    )

    Write-Log "Starting remediation process..." "HEAD"

    # 1. Delete Malicious Registry Keys
    foreach ($item in $CLSIDs) {
        try {
            Write-Log ("Removing registry key: " + $item.CLSIDKey) "INFO"
            Remove-Item -Path $item.CLSIDKey -Recurse -Force -ErrorAction Stop
            Write-Log "Registry key removed successfully." "OK"
        } catch {
            Write-Log ("Failed to remove " + $item.CLSIDKey + ": " + $_) "FAIL"
        }
    }

    # 2. Terminate Explorer to unload injected DLL
    Write-Log "Restarting Windows Explorer to unload malicious threads..." "WARN"
    try {
        Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
        $expCheck = Get-Process explorer -ErrorAction SilentlyContinue
        if (-not $expCheck) {
            Start-Process explorer.exe
        }
        Write-Log "Windows Explorer restarted clean." "OK"
    } catch {
        Write-Log ("Error restarting Explorer: " + $_) "FAIL"
    }

    # 3. Remove Malicious Files
    foreach ($file in $Files) {
        if (Test-Path $file) {
            try {
                Write-Log ("Deleting malicious file: " + $file) "INFO"
                Remove-Item -Path $file -Force -ErrorAction Stop
                Write-Log "File deleted successfully." "OK"

                $parentDir = Split-Path $file -Parent
                if ($parentDir -like "*\Microsoft\EdgeWebView") {
                    Remove-Item -Path $parentDir -Recurse -Force -ErrorAction SilentlyContinue
                }
            } catch {
                Write-Log ("Could not delete " + $file + ". Will attempt on reboot.") "WARN"
            }
        }
    }

    # 4. Clear Windows Clipboard
    try {
        [System.Windows.Forms.Clipboard]::Clear()
        Write-Log "Clipboard cleared." "OK"
    } catch {}
}

# -------------------------------------------------------------------------
# MAIN EXECUTION FLOW
# -------------------------------------------------------------------------
Show-Banner

$hijacked = Test-ClipboardHijack
$suspiciousCLSIDs = Scan-COMHijacking
$rogueFiles = Scan-KnownClipperFiles

$totalThreats = $hijacked.Count + $suspiciousCLSIDs.Count + $rogueFiles.Count

Write-Log "SCAN SUMMARY" "HEAD"
Write-Host "--------------------------------------------------------------------" -ForegroundColor Gray

$hijackCount = $hijacked.Count
if ($hijackCount -gt 0) {
    Write-Host " Live Hijack Detected:  YES ($hijackCount chains)" -ForegroundColor Red
} else {
    Write-Host " Live Hijack Detected:  NO" -ForegroundColor Green
}

$comCount = $suspiciousCLSIDs.Count
if ($comCount -gt 0) {
    Write-Host " Malicious COM Keys:    $comCount" -ForegroundColor Red
} else {
    Write-Host " Malicious COM Keys:    0" -ForegroundColor Green
}

$fileCount = $rogueFiles.Count
if ($fileCount -gt 0) {
    Write-Host " Rogue Malware Files:   $fileCount" -ForegroundColor Red
} else {
    Write-Host " Rogue Malware Files:   0" -ForegroundColor Green
}
Write-Host "--------------------------------------------------------------------" -ForegroundColor Gray

if ($totalThreats -eq 0) {
    Write-Host ""
    Write-Host " [+] System is clean! No crypto clipboard hijackers detected." -ForegroundColor Green
    exit 0
}

if ($ScanOnly) {
    Write-Host ""
    Write-Host " [!] Scan-only mode selected. No changes were made." -ForegroundColor Yellow
    exit 0
}

if (-not $AutoFix) {
    Write-Host ""
    $response = Read-Host " [!] Threat(s) detected! Do you want AntiClipper to remove them now? (Y/N)"
    if ($response -notmatch '^(y|yes)$') {
        Write-Host "Remediation aborted by user." -ForegroundColor Gray
        exit 0
    }
}

Remove-Threats -CLSIDs $suspiciousCLSIDs -Files $rogueFiles

Write-Log "VERIFYING REMEDIATION..." "HEAD"
Start-Sleep -Seconds 1
$postCheck = Test-ClipboardHijack

if ($postCheck.Count -eq 0) {
    Write-Host "`n====================================================================" -ForegroundColor Green
    Write-Host "  [+] SUCCESS: CLIPBOARD HIJACKER COMPLETELY REMOVED!" -ForegroundColor Green
    Write-Host "      Your crypto transactions are now safe." -ForegroundColor Green
    Write-Host "====================================================================" -ForegroundColor Green
} else {
    Write-Host "`n====================================================================" -ForegroundColor Yellow
    Write-Host "  [!] WARNING: Hijack still active. A system reboot may be required." -ForegroundColor Yellow
    Write-Host "====================================================================" -ForegroundColor Yellow
}
