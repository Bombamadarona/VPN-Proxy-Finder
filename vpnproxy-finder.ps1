
Write-Output "@@@@@@    @@@@@@      @@@       @@@@@@@@   @@@@@@   @@@@@@@   @@@  @@@     @@@  @@@@@@@  "
Write-Output "@@@@@@@   @@@@@@@      @@@       @@@@@@@@  @@@@@@@@  @@@@@@@@  @@@@ @@@     @@@  @@@@@@@  "
Write-Output "!@@       !@@          @@!       @@!       @@!  @@@  @@!  @@@  @@!@!@@@     @@!    @@!    "
Write-Output "!@!       !@!          !@!       !@!       !@!  @!@  !@!  @!@  !@!!@!@!     !@!    !@!    "
Write-Output "!!@@!!    !!@@!!       @!!       @!!!:!    @!@!@!@!  @!@!!@!   @!@ !!@!     !!@    @!!    "
Write-Output " !!@!!!    !!@!!!      !!!       !!!!!:    !!!@!!!!  !!@!@!    !@!  !!!     !!!    !!!    "
Write-Output "     !:!       !:!     !!:       !!:       !!:  !!!  !!: :!!   !!:  !!!     !!:    !!:    "
Write-Output "    !:!       !:!       :!:      :!:       :!:  !:!  :!:  !:!  :!:  !:!     :!:    :!:    "
Write-Output ":::: ::   :::: ::       :: ::::   :: ::::  ::   :::  ::   :::   ::   ::      ::     ::  "  
Write-Output ":: : :    :: : :       : :: : :  : :: ::    :   : :   :   : :  ::    :      :       :"    
Write-Output ""
Write-Output "https://discord.gg/UET6TdxFUk"
Write-Output "" 

$vpnProcessNames = @(
    "openvpn", "nordvpn", "protonvpn", "expressvpn", "windscribe",
    "psiphon", "openconnect", "anyconnect", "softether",
    "surfshark", "cyberghost", "forticlient", "tailscale",
    "outline", "tunnelbear", "openwebvpn", "vpnui", "vpnagent", "pia-client"
)

$allProcs = Get-Process -ErrorAction SilentlyContinue

$knownVpnProcs = $allProcs | Where-Object {
    $vpnProcessNames -contains $_.Name.ToLower()
}

$suspectKeywords = 'vpn','proxy','tunnel','bear','connect','secure','anonym','wireguard','openweb','psiphon','forti'
$suspectProcs = $allProcs | Where-Object {
    foreach ($word in $suspectKeywords) {
        if ($_.Name -match $word) { return $true }
    }
}

$adapters = Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq 'Up' }
$vpnAdapters = $adapters | Where-Object {
    $_.InterfaceDescription -match 'vpn|tun|tap|ppp|wireguard|wg|tunnelbear|virtual' -or
    $_.Name -match 'vpn|tun|tap|ppp|wireguard|wg|tunnelbear|virtual' -or
    ($_.InterfaceDescription -match 'adapter' -and $_.Virtual -eq $true)
}

$defRoutes = Get-NetRoute -DestinationPrefix '0.0.0.0/0' -ErrorAction SilentlyContinue |
    Where-Object { $_.NextHop -ne '0.0.0.0' }

$routeVpn = $false
if ($vpnAdapters) {
    $vpnIfIdx = $vpnAdapters | Select-Object -ExpandProperty InterfaceIndex -Unique
    foreach ($r in $defRoutes) {
        if ($vpnIfIdx -contains $r.InterfaceIndex) {
            $routeVpn = $true
            break
        }
    }
}

$proxyDetected = $false
try {
    $reg = Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -ErrorAction Stop
    if ($reg.ProxyEnable -eq 1 -and $reg.ProxyServer) {
        $proxyDetected = $true
    }
    if ($reg.AutoConfigURL) {
        $proxyDetected = $true
    }
} catch {}

if ((netsh winhttp show proxy) -match 'Proxy Server\s*:\s*(?!Direct access)') {
    $proxyDetected = $true
}

$vpnDetected = ($knownVpnProcs.Count -gt 0) -or ($vpnAdapters.Count -gt 0) -or $routeVpn
$suspectAppDetected = ($suspectProcs.Count -gt $knownVpnProcs.Count)  # App VPN/proxy sospette ma non note

Write-Host "`n------------------------------------------" -ForegroundColor DarkGray
Write-Host "     RILEVAMENTO STATO RETE: VPN / PROXY"
Write-Host "------------------------------------------`n" -ForegroundColor DarkGray

if ($vpnDetected -and $proxyDetected) {
    Write-Host "-  VPN e Proxy attivi" -ForegroundColor Yellow
} elseif ($vpnDetected) {
    Write-Host "- VPN attiva" -ForegroundColor Cyan
} elseif ($proxyDetected) {
    Write-Host "- Proxy attivo" -ForegroundColor Magenta
} else {
    Write-Host "- Nessuna connessione VPN o Proxy rilevata" -ForegroundColor Green
}

if ($suspectAppDetected) {
    Write-Host "`n Programmi sospetti rilevati (potenziali VPN/Proxy):" -ForegroundColor DarkYellow
    $suspectProcs | Sort-Object Name | Select-Object -ExpandProperty Name | Get-Unique | ForEach-Object {
        Write-Host "   → $_" -ForegroundColor DarkYellow
    }
}

Write-Host "`n------------------------------------------`n" -ForegroundColor DarkGray