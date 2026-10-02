<# : batch portion
@echo off
:: ============================================================
::  Sua loi Steam bao "Khong co internet" do DNS router chan Steam
::  Cach dung: double-click file nay, bam Yes khi Windows hoi quyen Admin
:: ============================================================
set "SELF=%~f0"
title Sua loi Steam DNS

fltmc >nul 2>&1 || (
  if /i "%~1"=="--elevated" (
    echo [!] Khong lay duoc quyen Administrator.
    pause
    exit /b 1
  )
  echo Dang yeu cau quyen Administrator, hay bam Yes...
  powershell -NoProfile -Command "try { Start-Process -FilePath $env:SELF -ArgumentList '--elevated' -Verb RunAs -ErrorAction Stop } catch { Write-Host '[!] Ban da tu choi quyen Administrator.'; Read-Host 'Nhan Enter de thoat' }"
  exit /b
)

powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ([IO.File]::ReadAllText($env:SELF))"
exit /b
#>

# ============================================================
#  Phan PowerShell (duoc phan .bat o tren goi lai)
# ============================================================

$SteamHosts = @(
    'store.steampowered.com'
    'api.steampowered.com'
    'steamcommunity.com'
    'client-update.steamstatic.com'
    'cmp1-sgp1.steamserver.net'
)

$DnsPresets = @{
    '1' = @{ Name = 'Google';     V4 = @('8.8.8.8', '8.8.4.4'); V6 = @('2001:4860:4860::8888', '2001:4860:4860::8844') }
    '2' = @{ Name = 'Cloudflare'; V4 = @('1.1.1.1', '1.0.0.1'); V6 = @('2606:4700:4700::1111', '2606:4700:4700::1001') }
}

$HostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"

function Get-TargetAdapters {
    $list = @(Get-NetAdapter -Physical -ErrorAction SilentlyContinue | Where-Object Status -eq 'Up')
    if (-not $list) {
        $list = @(Get-NetIPConfiguration | Where-Object IPv4DefaultGateway | ForEach-Object NetAdapter)
    }
    $list
}

function Show-DnsStatus {
    Write-Host "`n--- Card mang & DNS hien tai ---" -ForegroundColor Cyan
    $adapters = Get-TargetAdapters
    if (-not $adapters) {
        Write-Host '  Khong tim thay card mang nao dang ket noi.' -ForegroundColor Red
        return
    }
    foreach ($a in $adapters) {
        $v4 = (Get-DnsClientServerAddress -InterfaceIndex $a.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue).ServerAddresses -join ', '
        $v6 = (Get-DnsClientServerAddress -InterfaceIndex $a.ifIndex -AddressFamily IPv6 -ErrorAction SilentlyContinue).ServerAddresses -join ', '
        Write-Host "  $($a.Name)"
        Write-Host "    IPv4: $(if ($v4) { $v4 } else { '(trong)' })"
        Write-Host "    IPv6: $(if ($v6) { $v6 } else { '(trong)' })"
    }
}

function Test-SteamConnection {
    Write-Host "`n--- Kiem tra ket noi Steam ---" -ForegroundColor Cyan
    try { Clear-DnsClientCache -ErrorAction Stop } catch { ipconfig /flushdns | Out-Null }

    $blocked = 0
    foreach ($h in $SteamHosts) {
        try {
            $ips = [System.Net.Dns]::GetHostAddresses($h)
            $bad = $ips | Where-Object {
                [System.Net.IPAddress]::IsLoopback($_) -or
                $_.Equals([System.Net.IPAddress]::Any) -or
                $_.Equals([System.Net.IPAddress]::IPv6Any)
            }
            if ($bad) {
                $blocked++
                Write-Host ("  [BI CHAN] {0,-32} -> {1}" -f $h, ($ips -join ', ')) -ForegroundColor Red
            } else {
                Write-Host ("  [OK]      {0,-32} -> {1}" -f $h, (($ips | Select-Object -First 2) -join ', ')) -ForegroundColor Green
            }
        } catch {
            $blocked++
            Write-Host ("  [LOI]     {0,-32} -> khong phan giai duoc" -f $h) -ForegroundColor Red
        }
    }

    $tcpOk = $false
    $client = New-Object System.Net.Sockets.TcpClient
    try { $tcpOk = $client.ConnectAsync('api.steampowered.com', 443).Wait(5000) -and $client.Connected } catch { } finally { $client.Close() }
    if ($tcpOk) { Write-Host '  [OK]      Ket noi toi api.steampowered.com:443' -ForegroundColor Green }
    else        { Write-Host '  [LOI]     Khong ket noi duoc toi api.steampowered.com:443' -ForegroundColor Red }

    $ok = ($blocked -eq 0) -and $tcpOk
    if ($ok) {
        Write-Host "`n  => Steam ket noi binh thuong." -ForegroundColor Green
    } elseif ($blocked -gt 0) {
        Write-Host "`n  => Domain Steam dang bi chan bang DNS. Chon [1] hoac [2] de sua." -ForegroundColor Yellow
    } else {
        Write-Host "`n  => DNS binh thuong nhung khong ket noi duoc toi Steam (kiem tra tuong lua / mang)." -ForegroundColor Yellow
    }
    return $ok
}

function Repair-HostsFile {
    $lines = @(Get-Content $HostsPath -ErrorAction SilentlyContinue)
    $hits = @($lines | Where-Object { $_ -notmatch '^\s*#' -and $_ -match 'steam|valve' })
    if (-not $hits) { return }

    Write-Host "`n[!] File hosts dang chua dong chan/chuyen huong Steam:" -ForegroundColor Yellow
    $hits | ForEach-Object { Write-Host "    $_" -ForegroundColor Yellow }
    $ans = Read-Host 'Vo hieu hoa cac dong nay (co sao luu file hosts)? (Y/N)'
    if ($ans -notmatch '^[yYcC]') { return }

    $backup = "$HostsPath.bak-$(Get-Date -Format yyyyMMdd-HHmmss)"
    try {
        Copy-Item $HostsPath $backup -ErrorAction Stop
        $new = $lines | ForEach-Object { if ($_ -notmatch '^\s*#' -and $_ -match 'steam|valve') { "# $_" } else { $_ } }
        [System.IO.File]::WriteAllLines($HostsPath, [string[]]$new)
        Write-Host "  [OK] Da vo hieu hoa. Ban sao luu: $backup" -ForegroundColor Green
    } catch {
        Write-Host "  [LOI] Khong sua duoc file hosts (co the bi phan mem diet virus chan): $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Set-SteamDns($preset) {
    Write-Host "`n--- Doi DNS sang $($preset.Name) ---" -ForegroundColor Cyan
    foreach ($a in Get-TargetAdapters) {
        $servers = @($preset.V4)
        $v6 = Get-NetAdapterBinding -Name $a.Name -ComponentID ms_tcpip6 -ErrorAction SilentlyContinue
        if ($v6.Enabled) { $servers += $preset.V6 }
        try {
            Set-DnsClientServerAddress -InterfaceIndex $a.ifIndex -ServerAddresses $servers -ErrorAction Stop
            Write-Host "  [OK]  $($a.Name): $($servers -join ', ')" -ForegroundColor Green
        } catch {
            Write-Host "  [LOI] $($a.Name): $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

function Reset-SteamDns {
    Write-Host "`n--- Khoi phuc DNS tu dong (theo router) ---" -ForegroundColor Cyan
    foreach ($a in Get-TargetAdapters) {
        try {
            Set-DnsClientServerAddress -InterfaceIndex $a.ifIndex -ResetServerAddresses -ErrorAction Stop
            Write-Host "  [OK]  $($a.Name)" -ForegroundColor Green
        } catch {
            Write-Host "  [LOI] $($a.Name): $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

function Restart-Steam {
    $proc = Get-Process steam -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $proc) {
        Write-Host "`n  Bay gio ban co the mo Steam." -ForegroundColor Cyan
        return
    }
    $ans = Read-Host "`nSteam dang chay, can khoi dong lai de nhan DNS moi. Khoi dong lai ngay? (Y/N)"
    $steamExe = $proc.Path
    if ($ans -notmatch '^[yYcC]' -or -not $steamExe) {
        Write-Host '  Nho thoat han Steam (chuot phai icon Steam o khay he thong > Exit) roi mo lai.' -ForegroundColor Yellow
        return
    }

    Write-Host '  Dang tat Steam...'
    Start-Process $steamExe -ArgumentList '-shutdown'
    $deadline = (Get-Date).AddSeconds(30)
    while ((Get-Process steam -ErrorAction SilentlyContinue) -and (Get-Date) -lt $deadline) { Start-Sleep -Milliseconds 500 }
    Get-Process steam, steamwebhelper -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2

    # Mo qua explorer de Steam chay bang quyen user thuong, khong phai Admin
    Write-Host '  Dang mo lai Steam...'
    Start-Process explorer.exe -ArgumentList "`"$steamExe`""
    Write-Host '  [OK] Da khoi dong lai Steam.' -ForegroundColor Green
}

function Show-Menu {
    Write-Host ''
    Write-Host '==================== MENU ====================' -ForegroundColor Cyan
    Write-Host '  [1] Sua loi: doi DNS sang Google   (khuyen dung)'
    Write-Host '  [2] Sua loi: doi DNS sang Cloudflare'
    Write-Host '  [3] Khoi phuc DNS tu dong nhu ban dau'
    Write-Host '  [4] Kiem tra lai'
    Write-Host '  [0] Thoat'
    Read-Host 'Chon'
}

try {
    Clear-Host
    Write-Host '=== SUA LOI STEAM "KHONG CO INTERNET" (DNS BI CHAN) ===' -ForegroundColor Cyan
    Show-DnsStatus
    Repair-HostsFile
    $null = Test-SteamConnection

    :menu while ($true) {
        switch ((Show-Menu).Trim()) {
            { $_ -in '1', '2' } {
                Set-SteamDns $DnsPresets[$_]
                Show-DnsStatus
                if (Test-SteamConnection) { Restart-Steam }
            }
            '3' { Reset-SteamDns; Show-DnsStatus; $null = Test-SteamConnection }
            '4' { Show-DnsStatus; $null = Test-SteamConnection }
            '0' { break menu }
            default { Write-Host 'Lua chon khong hop le.' -ForegroundColor Yellow }
        }
    }
} catch {
    Write-Host "`n[LOI] $($_.Exception.Message)" -ForegroundColor Red
    Read-Host 'Nhan Enter de thoat'
}
