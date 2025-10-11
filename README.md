# 🔍 VPN-Proxy-Finder (PowerShell)

Questo script PowerShell è progettato per rilevare connessioni VPN, proxy attivi e software sospetti che potrebbero ricondurre ad un utilizzo di Vpn/proxy da parte dell'utente.

Questo script è stato realizzato dal server discord SS LEARN IT (https://discord.gg/UET6TdxFUk).

## 🔍 Funzionalità

- Rivela VPN.
- Rivela proxy.
- Segnala eventuali programmi riconducibili a quest'ultimi.
- Riporta tutto direttamente sul powershell.

## 📂 Servizi e processi analizzati

- Processi noti di VPN.
- Processi sospetti che contengono parole chiave come vpn, proxy, tunnel ecc..
- Adattatori di rete virtuali o riconducibili a VPN.
- Routing del traffico attraverso interfacce VPN.
- Proxy di sistema, sia configurati manualmente che tramite script di configurazione automatica (PAC)
- Proxy a livello di sistema WinHTTP

## ▶️ Utilizzo

1. Apri PowerShell (amministratore).
2. Copia e incolla lo script nel terminale oppure salvalo in un file, ad esempio `vpnproxy-finder.ps1`.
3. Esegui lo script:
`.\vpnproxy-finder.ps1`

Oppure puoi semplicemente eseguire lo script tramite un comando senza scaricare il file:

1. Apri PowerShell (amministratore).
2. `iex (iwr -useb "https://raw.githubusercontent.com/Bombamadarona/VPN-Proxy-Finder/main/vpnproxy-finder.ps1")`

## 📎 Note aggiuntive

- Lo script non salva informazioni sensibili
