:: reg add "HKLM\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v PortNumber /t REG_DWORD /d 3390 /f
reg add "HKLM\System\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 0 /f
:: netsh advfirewall firewall add rule name="allow RemoteDesktop" dir=in protocol=TCP localport=3389 action=allow

:: Allow paste of password on UAC windows
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v PromptOnSecureDesktop /t REG_DWORD /d 0 /f 

net localgroup "Administrators" "HPC\az-hop-localadmins" /add

net localgroup "Remote Desktop Users" "HPC\Domain Users" /add
net localgroup "Remote Desktop Users"
call C:\cycle\jetpack\bin\jetpack log "End of configure rdp script" --level info