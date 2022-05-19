:: C:\cycle\jetpack\bin\jetpack log "Update RDP configuration" --level info --priority low

:: C:\cycle\jetpack\bin\jetpack log "Update registry" --level info --priority low
:: reg add "HKLM\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v PortNumber /t REG_DWORD /d 3390 /f
reg add "HKLM\System\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 0 /f
:: netsh advfirewall firewall add rule name="allow RemoteDesktop" dir=in protocol=TCP localport=3389 action=allow

net localgroup "Remote Desktop Users" "HPC\Domain Users" /add
net localgroup "Remote Desktop Users"
:: C:\cycle\jetpack\bin\jetpack log "End of configure rdp script" --level info --priority low