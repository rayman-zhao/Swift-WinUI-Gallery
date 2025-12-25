# build-msix.ps1 - Swift WinUI 3 Gallery MSIX Build Script
# Universal version - Works on any machine with Swift installed

param(
    [string]$ProjectRoot = $PSScriptRoot,
    [string]$BuildConfig = "release",
    [string]$OutputName = "SwiftWinUIGallery"
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Swift WinUI 3 Gallery MSIX Builder" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ====================================================================================
# HELPER FUNCTIONS
# ====================================================================================

function Find-SwiftRuntime {
    Write-Host "[INFO] Searching for Swift installation..." -ForegroundColor Cyan
    
    # Method 1: Check Swift Runtimes directory
    $runtimesBase = "$env:LOCALAPPDATA\Programs\Swift\Runtimes"
    if (Test-Path $runtimesBase) {
        $runtimeVersions = Get-ChildItem -Path $runtimesBase -Directory -ErrorAction SilentlyContinue | 
                          Sort-Object Name -Descending
        if ($runtimeVersions) {
            $latestRuntime = $runtimeVersions[0]
            $binPath = Join-Path $latestRuntime.FullName "usr\bin"
            if (Test-Path $binPath) {
                Write-Host "[OK] Found Swift Runtime: $($latestRuntime.Name)" -ForegroundColor Green
                Write-Host "     Path: $binPath" -ForegroundColor Gray
                return $binPath
            }
        }
    }
    
    # Method 2: Check Swift Toolchains directory
    $toolchainsBase = "$env:LOCALAPPDATA\Programs\Swift\Toolchains"
    if (Test-Path $toolchainsBase) {
        $toolchainVersions = Get-ChildItem -Path $toolchainsBase -Directory -ErrorAction SilentlyContinue | 
                            Sort-Object Name -Descending
        if ($toolchainVersions) {
            $latestToolchain = $toolchainVersions[0]
            $binPath = Join-Path $latestToolchain.FullName "usr\bin"
            if (Test-Path $binPath) {
                Write-Host "[OK] Found Swift Toolchain: $($latestToolchain.Name)" -ForegroundColor Green
                Write-Host "     Path: $binPath" -ForegroundColor Gray
                return $binPath
            }
        }
    }
    
    # Method 3: Try to find swift.exe in PATH and locate DLLs relative to it
    $swiftExe = Get-Command swift.exe -ErrorAction SilentlyContinue
    if ($swiftExe) {
        $swiftBinDir = Split-Path $swiftExe.Source -Parent
        Write-Host "[OK] Found Swift in PATH: $swiftBinDir" -ForegroundColor Green
        return $swiftBinDir
    }
    
    return $null
}

function Test-RequiredFile {
    param(
        [string]$FilePath,
        [string]$Description,
        [string]$Suggestion = ""
    )
    
    if (-not (Test-Path $FilePath)) {
        Write-Host ""
        Write-Host "  [ERROR] $Description not found!" -ForegroundColor Red
        Write-Host "          Expected: $FilePath" -ForegroundColor Yellow
        if ($Suggestion) {
            Write-Host ""
            Write-Host "  Suggestion:" -ForegroundColor Cyan
            Write-Host "  $Suggestion" -ForegroundColor White
        }
        Write-Host ""
        return $false
    }
    return $true
}

# ====================================================================================
# CONFIGURATION
# ====================================================================================

$BuildDir = Join-Path $ProjectRoot ".build\$BuildConfig"
$PackageRoot = Join-Path $ProjectRoot "msix-package"
$OutputDir = Join-Path $ProjectRoot "msix-output"

# Find Swift Runtime DLLs
$SwiftRuntimeBinPath = Find-SwiftRuntime

if (-not $SwiftRuntimeBinPath) {
    Write-Host ""
    Write-Host "  [ERROR] Swift installation not found!" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Searched locations:" -ForegroundColor Yellow
    Write-Host "  - %LOCALAPPDATA%\Programs\Swift\Runtimes" -ForegroundColor Gray
    Write-Host "  - %LOCALAPPDATA%\Programs\Swift\Toolchains" -ForegroundColor Gray
    Write-Host "  - swift.exe in system PATH" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Please install Swift for Windows from:" -ForegroundColor Cyan
    Write-Host "  https://www.swift.org/download/" -ForegroundColor White
    Write-Host ""
    exit 1
}

Write-Host ""

# ====================================================================================
# STEP 1: Clean and Setup
# ====================================================================================
Write-Host "[STEP 1/11] Cleaning and Setup" -ForegroundColor Yellow
Write-Host "============================================" -ForegroundColor Gray

if (Test-Path $PackageRoot) {
    Remove-Item $PackageRoot -Recurse -Force
    Write-Host "  [OK] Cleaned package directory" -ForegroundColor Green
}

if (Test-Path $OutputDir) {
    $oldMsix = Get-ChildItem $OutputDir -Filter "*.msix" -ErrorAction SilentlyContinue
    if ($oldMsix) {
        Remove-Item $oldMsix.FullName -Force
        Write-Host "  [OK] Removed old MSIX file" -ForegroundColor Green
    }
}

New-Item -ItemType Directory -Path $PackageRoot -Force | Out-Null
New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
Write-Host "  [OK] Created directories" -ForegroundColor Green
Write-Host ""

# ====================================================================================
# STEP 2: Copy Executable
# ====================================================================================
Write-Host "[STEP 2/11] Copying Executable" -ForegroundColor Yellow
Write-Host "============================================" -ForegroundColor Gray

$ExePath = Join-Path $BuildDir "$OutputName.exe"
if (-not (Test-RequiredFile $ExePath "Executable" "Run: swift build -c $BuildConfig")) {
    exit 1
}

Copy-Item $ExePath $PackageRoot -Force
$exeSize = (Get-Item (Join-Path $PackageRoot "$OutputName.exe")).Length
Write-Host "  [OK] Copied: $OutputName.exe" -ForegroundColor Green
Write-Host "       Size: $([math]::Round($exeSize/1MB, 2)) MB" -ForegroundColor Gray
Write-Host ""

# ====================================================================================
# STEP 3: Copy CWinRT.dll
# ====================================================================================
Write-Host "[STEP 3/11] Copying CWinRT Dependency" -ForegroundColor Yellow
Write-Host "============================================" -ForegroundColor Gray

$CWinRTDll = Join-Path $BuildDir "CWinRT.dll"
if (Test-Path $CWinRTDll) {
    Copy-Item $CWinRTDll $PackageRoot -Force
    $dllSize = (Get-Item $CWinRTDll).Length
    Write-Host "  [OK] Copied: CWinRT.dll" -ForegroundColor Green
    Write-Host "       Size: $([math]::Round($dllSize/1KB, 2)) KB" -ForegroundColor Gray
} else {
    Write-Host "  [WARN] CWinRT.dll not found (may not be required)" -ForegroundColor Yellow
}
Write-Host ""

# ====================================================================================
# STEP 4: Copy resources.pri
# ====================================================================================
Write-Host "[STEP 4/11] Copying resources.pri" -ForegroundColor Yellow
Write-Host "============================================" -ForegroundColor Gray

$ResourcesPri = Join-Path $BuildDir "resources.pri"
if (-not (Test-RequiredFile $ResourcesPri "resources.pri" "Please place resources.pri file in the .build\$BuildConfig\ directory")) {
    exit 1
}

Copy-Item $ResourcesPri $PackageRoot -Force
$priSize = (Get-Item $ResourcesPri).Length
Write-Host "  [OK] Copied: resources.pri" -ForegroundColor Green
Write-Host "       Size: $([math]::Round($priSize/1KB, 2)) KB" -ForegroundColor Gray
Write-Host ""

# ====================================================================================
# STEP 5: Copy SPM Resources Directory (CRITICAL!)
# ====================================================================================
Write-Host "[STEP 5/11] Copying SPM Resources Directory" -ForegroundColor Yellow
Write-Host "============================================" -ForegroundColor Gray

$SPMResourcesDir = Join-Path $BuildDir "Swift-WinUI-Gallery_SwiftWinUIGallery.resources"
if (Test-Path $SPMResourcesDir) {
    $DestResourcesDir = Join-Path $PackageRoot "Swift-WinUI-Gallery_SwiftWinUIGallery.resources"
    Copy-Item -Path $SPMResourcesDir -Destination $DestResourcesDir -Recurse -Force
    
    $resourceFiles = Get-ChildItem -Path $DestResourcesDir -Recurse -File
    $resourceCount = $resourceFiles.Count
    $resourceSize = ($resourceFiles | Measure-Object -Property Length -Sum).Sum
    
    Write-Host "  [OK] Copied SPM resources directory" -ForegroundColor Green
    Write-Host "       Files: $resourceCount" -ForegroundColor Gray
    Write-Host "       Size: $([math]::Round($resourceSize/1MB, 2)) MB" -ForegroundColor Gray
    Write-Host "       (Contains Assets for Bundle.module access)" -ForegroundColor DarkGray
} else {
    Write-Host "  [WARN] SPM resources directory not found" -ForegroundColor Yellow
    Write-Host "         Path: $SPMResourcesDir" -ForegroundColor Gray
    Write-Host "         This may cause resource loading issues" -ForegroundColor Yellow
}
Write-Host ""

# ====================================================================================
# STEP 6: Copy Windows App SDK Resources (CRITICAL!)
# ====================================================================================
Write-Host "[STEP 6/11] Copying Windows App SDK Resources" -ForegroundColor Yellow
Write-Host "============================================" -ForegroundColor Gray

$WinAppSDKResourcesDir = Join-Path $BuildDir "swift-windowsappsdk_CWinAppSDK.resources"
if (Test-Path $WinAppSDKResourcesDir) {
    $DestWinAppSDKDir = Join-Path $PackageRoot "swift-windowsappsdk_CWinAppSDK.resources"
    Copy-Item -Path $WinAppSDKResourcesDir -Destination $DestWinAppSDKDir -Recurse -Force
    
    $bootstrapDll = Join-Path $DestWinAppSDKDir "Microsoft.WindowsAppRuntime.Bootstrap.dll"
    if (Test-Path $bootstrapDll) {
        $bootstrapSize = (Get-Item $bootstrapDll).Length
        Write-Host "  [OK] Copied Windows App SDK resources" -ForegroundColor Green
        Write-Host "       Bootstrap DLL: Microsoft.WindowsAppRuntime.Bootstrap.dll" -ForegroundColor Gray
        Write-Host "       Size: $([math]::Round($bootstrapSize/1KB, 2)) KB" -ForegroundColor Gray
        Write-Host "       (Required for Windows App SDK initialization)" -ForegroundColor DarkGray
    } else {
        Write-Host "  [WARN] Bootstrap DLL not found in resources" -ForegroundColor Yellow
    }
} else {
    Write-Host "  [WARN] Windows App SDK resources directory not found" -ForegroundColor Yellow
    Write-Host "         Path: $WinAppSDKResourcesDir" -ForegroundColor Gray
    Write-Host "         This may cause WinUI initialization issues" -ForegroundColor Yellow
}
Write-Host ""

# ====================================================================================
# STEP 7: Copy Swift Runtime DLLs
# ====================================================================================
Write-Host "[STEP 7/11] Copying Swift Runtime DLLs" -ForegroundColor Yellow
Write-Host "============================================" -ForegroundColor Gray

$allDlls = Get-ChildItem -Path $SwiftRuntimeBinPath -Filter "*.dll" -ErrorAction SilentlyContinue
if (-not $allDlls) {
    Write-Host "  [ERROR] No DLLs found in: $SwiftRuntimeBinPath" -ForegroundColor Red
    Write-Host "          Swift installation may be corrupted" -ForegroundColor Yellow
    exit 1
}

$copiedDllCount = 0
$totalDllSize = 0
$swiftDllCount = 0

foreach ($dll in $allDlls) {
    Copy-Item $dll.FullName $PackageRoot -Force
    $dllSize = $dll.Length
    $totalDllSize += $dllSize
    $copiedDllCount++
    
    if ($dll.Name -match "^swift") {
        $swiftDllCount++
    }
}

Write-Host "  [SUMMARY] Copied $copiedDllCount DLLs:" -ForegroundColor Cyan
Write-Host "    - Swift DLLs: $swiftDllCount" -ForegroundColor Green
Write-Host "    - Other DLLs: $($copiedDllCount - $swiftDllCount)" -ForegroundColor Gray
Write-Host "    - Total Size: $([math]::Round($totalDllSize/1MB, 2)) MB" -ForegroundColor White
Write-Host ""

# ====================================================================================
# STEP 8: Copy Manifest
# ====================================================================================
Write-Host "[STEP 8/11] Copying Manifest" -ForegroundColor Yellow
Write-Host "============================================" -ForegroundColor Gray

$manifestSource = Join-Path $ProjectRoot "AppxManifest.xml"
if (-not (Test-RequiredFile $manifestSource "AppxManifest.xml" "Create AppxManifest.xml in project root directory")) {
    exit 1
}

Copy-Item $manifestSource $PackageRoot -Force
Write-Host "  [OK] Copied: AppxManifest.xml" -ForegroundColor Green
Write-Host ""

# ====================================================================================
# STEP 9: Package Summary
# ====================================================================================
Write-Host "[STEP 9/11] Package Summary" -ForegroundColor Yellow
Write-Host "============================================" -ForegroundColor Gray

$allFiles = Get-ChildItem $PackageRoot -Recurse -File
$totalSize = ($allFiles | Measure-Object -Property Length -Sum).Sum

Write-Host "  Package Contents:" -ForegroundColor Cyan
Write-Host "    - $OutputName.exe: $([math]::Round($exeSize/1MB, 2)) MB" -ForegroundColor White
if (Test-Path (Join-Path $PackageRoot "CWinRT.dll")) {
    Write-Host "    - CWinRT.dll" -ForegroundColor White
}
if (Test-Path (Join-Path $PackageRoot "resources.pri")) {
    Write-Host "    - resources.pri" -ForegroundColor White
}
if (Test-Path (Join-Path $PackageRoot "Swift-WinUI-Gallery_SwiftWinUIGallery.resources")) {
    $resFiles = Get-ChildItem (Join-Path $PackageRoot "Swift-WinUI-Gallery_SwiftWinUIGallery.resources") -Recurse -File
    $resSize = ($resFiles | Measure-Object -Property Length -Sum).Sum
    Write-Host "    - SPM Resources: $($resFiles.Count) files ($([math]::Round($resSize/1MB, 2)) MB)" -ForegroundColor White
}
if (Test-Path (Join-Path $PackageRoot "swift-windowsappsdk_CWinAppSDK.resources")) {
    Write-Host "    - Windows App SDK Resources: Bootstrap DLL" -ForegroundColor White
}
Write-Host "    - Swift Runtime DLLs: $swiftDllCount files ($([math]::Round($totalDllSize/1MB, 2)) MB)" -ForegroundColor White
Write-Host ""
Write-Host "  Total: $($allFiles.Count) files" -ForegroundColor White
Write-Host "  Total Size: $([math]::Round($totalSize/1MB, 2)) MB" -ForegroundColor White
Write-Host ""

# ====================================================================================
# STEP 10: Create MSIX Package
# ====================================================================================
Write-Host "[STEP 10/11] Creating MSIX Package" -ForegroundColor Yellow
Write-Host "============================================" -ForegroundColor Gray

$msixPath = Join-Path $OutputDir "$OutputName.msix"

# Find makeappx.exe
$makeappxPath = "${env:ProgramFiles(x86)}\Windows Kits\10\bin\*\x64\makeappx.exe"
$makeappx = Get-ChildItem $makeappxPath -ErrorAction SilentlyContinue | 
            Sort-Object -Property FullName -Descending | 
            Select-Object -First 1

if (-not $makeappx) {
    Write-Host ""
    Write-Host "  [ERROR] makeappx.exe not found!" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Please install Windows SDK from:" -ForegroundColor Cyan
    Write-Host "  https://developer.microsoft.com/windows/downloads/windows-sdk/" -ForegroundColor White
    Write-Host ""
    exit 1
}

$sdkVersion = ($makeappx.FullName -split '\\')[-3]
Write-Host "  [INFO] Using Windows SDK: $sdkVersion" -ForegroundColor Cyan
Write-Host "  [INFO] Creating MSIX package..." -ForegroundColor Cyan
Write-Host "         This may take a while due to large size..." -ForegroundColor DarkGray
Write-Host ""

& $makeappx.FullName pack /d $PackageRoot /p $msixPath /o 2>&1 | Out-Null

if ($LASTEXITCODE -eq 0) {
    $msixSize = (Get-Item $msixPath).Length
    Write-Host "  [OK] MSIX package created successfully" -ForegroundColor Green
    Write-Host "       File: $msixPath" -ForegroundColor Gray
    Write-Host "       Size: $([math]::Round($msixSize/1MB, 2)) MB" -ForegroundColor Gray
} else {
    Write-Host "  [ERROR] MSIX packaging failed (Exit code: $LASTEXITCODE)" -ForegroundColor Red
    Write-Host "          Run makeappx manually for detailed error:" -ForegroundColor Yellow
    Write-Host "          $($makeappx.FullName) pack /d $PackageRoot /p $msixPath /o" -ForegroundColor Gray
    exit 1
}
Write-Host ""

# ====================================================================================
# STEP 11: Sign MSIX Package
# ====================================================================================
Write-Host "[STEP 11/11] Signing MSIX Package" -ForegroundColor Yellow
Write-Host "============================================" -ForegroundColor Gray

# Find signtool.exe
$signtoolPath = "${env:ProgramFiles(x86)}\Windows Kits\10\bin\*\x64\signtool.exe"
$signtool = Get-ChildItem $signtoolPath -ErrorAction SilentlyContinue | 
            Sort-Object -Property FullName -Descending | 
            Select-Object -First 1

if (-not $signtool) {
    Write-Host "  [WARN] signtool.exe not found, MSIX will not be signed" -ForegroundColor Yellow
    Write-Host "         You will need to sign it manually or install the certificate" -ForegroundColor Yellow
    Write-Host ""
} else {
    Write-Host "  [INFO] Creating self-signed test certificate..." -ForegroundColor Cyan

    $cert = New-SelfSignedCertificate `
        -Type Custom `
        -Subject "CN=TestPublisher" `
        -KeyUsage DigitalSignature `
        -FriendlyName "Swift WinUI Gallery Certificate" `
        -CertStoreLocation "Cert:\CurrentUser\My" `
        -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.3", "2.5.29.19={text}")

    Write-Host "  [OK] Certificate created" -ForegroundColor Green
    Write-Host "       Thumbprint: $($cert.Thumbprint)" -ForegroundColor Gray
    Write-Host ""

    $certPath = Join-Path $OutputDir "TestCert.pfx"
    $certPassword = "test123"
    $certPwd = ConvertTo-SecureString -String $certPassword -Force -AsPlainText
    Export-PfxCertificate -Cert $cert -FilePath $certPath -Password $certPwd | Out-Null

    Write-Host "  [OK] Certificate exported: $certPath" -ForegroundColor Green
    Write-Host "       Password: $certPassword" -ForegroundColor Gray
    Write-Host ""

    Write-Host "  [INFO] Signing MSIX with certificate..." -ForegroundColor Cyan
    & $signtool.FullName sign /fd SHA256 /sha1 $cert.Thumbprint /v $msixPath 2>&1 | Out-Null

    if ($LASTEXITCODE -eq 0) {
        Write-Host "  [OK] MSIX package signed successfully" -ForegroundColor Green
    } else {
        Write-Host "  [WARN] MSIX signing failed (Exit code: $LASTEXITCODE)" -ForegroundColor Yellow
        Write-Host "         Package created but not signed" -ForegroundColor Yellow
    }

    Remove-Item "Cert:\CurrentUser\My\$($cert.Thumbprint)" -Force -ErrorAction SilentlyContinue
    Write-Host ""
}

# ====================================================================================
# Final Summary
# ====================================================================================
Write-Host "========================================" -ForegroundColor Green
Write-Host "  BUILD COMPLETE!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

Write-Host "OUTPUT FILES:" -ForegroundColor Yellow
Write-Host "  MSIX Package: $msixPath" -ForegroundColor White
Write-Host "  Size: $([math]::Round((Get-Item $msixPath).Length/1MB, 2)) MB" -ForegroundColor Gray
Write-Host ""

if (Test-Path (Join-Path $OutputDir "TestCert.pfx")) {
    Write-Host "  Certificate:  $(Join-Path $OutputDir 'TestCert.pfx')" -ForegroundColor White
    Write-Host "  Password:     test123" -ForegroundColor White
    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  INSTALLATION INSTRUCTIONS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[PREREQUISITE] Windows App SDK Runtime" -ForegroundColor Yellow
Write-Host "  Target machine needs Windows App SDK 1.5+" -ForegroundColor White
Write-Host "  Download: https://aka.ms/windowsappsdk/1.5/latest/windowsappruntimeinstall-x64.exe" -ForegroundColor Gray
Write-Host ""

Write-Host "[STEP 1] Uninstall old version (if exists)" -ForegroundColor Yellow
Write-Host "  Get-AppxPackage *SwiftWinUI* | Remove-AppxPackage" -ForegroundColor White
Write-Host ""

if (Test-Path (Join-Path $OutputDir "TestCert.pfx")) {
    Write-Host "[STEP 2] Install Certificate (MANUAL)" -ForegroundColor Yellow
    Write-Host "  1. Double-click: $(Join-Path $OutputDir 'TestCert.pfx')" -ForegroundColor White
    Write-Host "  2. Store Location: Local Machine" -ForegroundColor White
    Write-Host "  3. Password: test123" -ForegroundColor White
    Write-Host "  4. Store: Trusted Root Certification Authorities" -ForegroundColor White
    Write-Host ""
}

Write-Host "[STEP $(if (Test-Path (Join-Path $OutputDir 'TestCert.pfx')) {'3'} else {'2'})] Install Application (MANUAL)" -ForegroundColor Yellow
Write-Host "  Double-click: $msixPath" -ForegroundColor White
Write-Host "  (Installation may take a while due to large size)" -ForegroundColor DarkGray
Write-Host ""

Write-Host "[STEP $(if (Test-Path (Join-Path $OutputDir 'TestCert.pfx')) {'4'} else {'3'})] Launch from Start Menu" -ForegroundColor Yellow
Write-Host "  Search: 'Swift WinUI 3 Gallery'" -ForegroundColor White
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  TECHNICAL NOTES" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "This script automatically detects:" -ForegroundColor Yellow
Write-Host "  - Swift installation location" -ForegroundColor White
Write-Host "  - Required runtime DLLs" -ForegroundColor White
Write-Host "  - Windows SDK tools" -ForegroundColor White
Write-Host ""
Write-Host "Works on any Windows machine with Swift installed." -ForegroundColor Green
Write-Host ""

Write-Host "Press Enter to exit..." -ForegroundColor DarkGray
Read-Host