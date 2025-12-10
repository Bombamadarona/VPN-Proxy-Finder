
Write-Host "@@@@@@    @@@@@@      @@@       @@@@@@@@   @@@@@@   @@@@@@@   @@@  @@@     @@@  @@@@@@@  "        -ForegroundColor Red
Write-Host "@@@@@@@   @@@@@@@      @@@       @@@@@@@@  @@@@@@@@  @@@@@@@@  @@@@ @@@     @@@  @@@@@@@  "       -ForegroundColor Red
Write-Host "!@@       !@@          @@!       @@!       @@!  @@@  @@!  @@@  @@!@!@@@     @@!    @@!    "       -ForegroundColor Red
Write-Host "!@!       !@!          !@!       !@!       !@!  @!@  !@!  @!@  !@!!@!@!     !@!    !@!    "       -ForegroundColor Red
Write-Host "!!@@!!    !!@@!!       @!!       @!!!:!    @!@!@!@!  @!@!!@!   @!@ !!@!     !!@    @!!    "       -ForegroundColor Red
Write-Host " !!@!!!    !!@!!!      !!!       !!!!!:    !!!@!!!!  !!@!@!    !@!  !!!     !!!    !!!    "       -ForegroundColor Red
Write-Host "     !:!       !:!     !!:       !!:       !!:  !!!  !!: :!!   !!:  !!!     !!:    !!:    "       -ForegroundColor Red
Write-Host "    !:!       !:!       :!:      :!:       :!:  !:!  :!:  !:!  :!:  !:!     :!:    :!:    "       -ForegroundColor Red
Write-Host ":::: ::   :::: ::       :: ::::   :: ::::  ::   :::  ::   :::   ::   ::      ::     ::  "         -ForegroundColor Red
Write-Host ":: : :    :: : :       : :: : :  : :: ::    :   : :   :   : :  ::    :      :       :"            -ForegroundColor Red
Write-Host ""
Write-Host "Discord: https://discord.gg/UET6TdxFUk"
Write-Host ""


# --- PROCESSI VPN CONOSCIUTI ---
$vpnProcessNames = @(
    "openvpn","nordvpn","protonvpn","expressvpn","windscribe",
    "psiphon","openconnect","anyconnect","softether",
    "surfshark","cyberghost","forticlient","tailscale",
    "outline","tunnelbear","openwebvpn","vpnui","vpnagent","pia-client"
)

$allProcs = Get-Process -ErrorAction SilentlyContinue
$knownVpnProcs = $allProcs | Where-Object { $vpnProcessNames -contains $_.Name.ToLower() }

# --- PROCESSI SOSPETTI ---
$suspectKeywords = 'vpn','proxy','tunnel','bear','connect','secure','anonym','wireguard','openweb','psiphon','forti'
$suspectProcs = $allProcs | Where-Object {
    foreach ($word in $suspectKeywords) { if ($_.Name -match $word) { return $true } }
}

# --- ADAPTER VPN ---
$adapters = Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq 'Up' }
$vpnAdapters = $adapters | Where-Object {
    $_.InterfaceDescription -match 'vpn|tun|tap|ppp|wireguard|wg|tunnelbear|virtual' -or
    $_.Name -match 'vpn|tun|tap|ppp|wireguard|wg|tunnelbear|virtual' -or
    ($_.InterfaceDescription -match 'adapter' -and $_.Virtual -eq $true)
}

$defRoutes = Get-NetRoute -DestinationPrefix '0.0.0.0/0' -ErrorAction SilentlyContinue | Where-Object { $_.NextHop -ne '0.0.0.0' }
$routeVpn = $false
if ($vpnAdapters) {
    $vpnIfIdx = $vpnAdapters | Select-Object -ExpandProperty InterfaceIndex -Unique
    foreach ($r in $defRoutes) { if ($vpnIfIdx -contains $r.InterfaceIndex) { $routeVpn = $true; break } }
}

# --- PROXY LOCALE ---
$proxyDetected = $false
try {
    $reg = Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -ErrorAction Stop
    if ($reg.ProxyEnable -eq 1 -and $reg.ProxyServer) { $proxyDetected = $true }
    if ($reg.AutoConfigURL) { $proxyDetected = $true }
} catch {}
if ((netsh winhttp show proxy) -match 'Proxy Server\s*:\s*(?!Direct access)') { $proxyDetected = $true }

# --- VPN/PROXY ONLINE (proxycheck.io) ---
$proxyOnline = $false
try {
    $ip = (Invoke-WebRequest -Uri "https://ifconfig.me/ip" -UseBasicParsing).Content.Trim()
    $json = Invoke-WebRequest -Uri "https://proxycheck.io/v2/$ip?vpn=1&asn=1" -UseBasicParsing | ConvertFrom-Json
    if ($json.$ip.proxy -eq "yes") { $proxyOnline = $true }
} catch {
    Write-Host "[!] Impossibile controllare lo stato VPN/Proxy online" -ForegroundColor Red
}

# --- RISULTATI ---
$vpnDetected = ($knownVpnProcs.Count -gt 0) -or ($vpnAdapters.Count -gt 0) -or $routeVpn
$suspectAppDetected = ($suspectProcs.Count -gt $knownVpnProcs.Count)

$totalWidth = 60
$headerText = "RILEVAMENTO RETE: VPN / PROXY"
$padding = [math]::Floor(($totalWidth - $headerText.Length) / 2)
Write-Host ("-" + ("=" * ($totalWidth - 2)) + "-") -ForegroundColor DarkGray
Write-Host ("|" + (" " * $padding) + $headerText + (" " * ($totalWidth - 2 - $padding - $headerText.Length)) + "|") -ForegroundColor DarkGray
Write-Host ("-" + ("=" * ($totalWidth - 2)) + "-") -ForegroundColor DarkGray
Write-Host ""

# --- OUTPUT STATO LOCALE ---
if ($vpnDetected -and $proxyDetected) {
    Write-Host "[!] VPN e Proxy attivi localmente" -ForegroundColor Red
} elseif ($vpnDetected) {
    Write-Host "[!] VPN attiva localmente" -ForegroundColor Red
} elseif ($proxyDetected) {
    Write-Host "[!] Proxy attivo localmente" -ForegroundColor Red
} else {
    Write-Host "[X] Nessuna connessione VPN o Proxy locale rilevata" -ForegroundColor Green
}

# --- OUTPUT ONLINE ---
if ($proxyOnline) {
    Write-Host "[!] VPN o Proxy rilevata online" -ForegroundColor Red
} else {
    Write-Host "[X] Nessuna VPN/Proxy rilevata online" -ForegroundColor Green
}

# --- APPLICAZIONI SOSPETTE MIGLIORATE ---
if ($suspectAppDetected) {
    Write-Host "`nProgrammi sospetti rilevati (potenziali VPN/Proxy):" -ForegroundColor DarkYellow
    
    $knownVpnNames = $knownVpnProcs | Select-Object -ExpandProperty Name | Get-Unique
    $suspectOnly = $suspectProcs | Where-Object { $knownVpnNames -notcontains $_.Name } | Select-Object -ExpandProperty Name | Get-Unique

    if ($knownVpnNames.Count -gt 0) {
        $knownVpnNames | ForEach-Object { Write-Host "- $_" -ForegroundColor Cyan }
    }

    if ($suspectOnly.Count -gt 0) {
        $suspectOnly | ForEach-Object { Write-Host "- $_" -ForegroundColor Cyan }
    }
}

# --- FOOTER ---
$footerText = "OPERAZIONE COMPLETATA"
$padding = [math]::Floor(($totalWidth - $footerText.Length) / 2)
Write-Host ""
Write-Host ("-" + ("=" * ($totalWidth - 2)) + "-") -ForegroundColor DarkGray
Write-Host ("|" + (" " * $padding) + $footerText + (" " * ($totalWidth - 2 - $padding - $footerText.Length)) + "|") -ForegroundColor DarkGray
Write-Host ("-" + ("=" * ($totalWidth - 2)) + "-") -ForegroundColor DarkGray
Write-Host ""

