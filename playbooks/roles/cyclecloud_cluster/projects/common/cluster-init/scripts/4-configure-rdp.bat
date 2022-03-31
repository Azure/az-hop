reg add "HKLM\System\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 0 /f
netsh advfirewall firewall add rule name="allow RemoteDesktop" dir=in protocol=TCP localport=3389 action=allow

Powershell.exe -executionpolicy remotesigned try { Add-LocalGroupMember -Group "Remote Desktop Users" -Member "HPC\Domain Users" } catch { exit 255 }

if %ERRORLEVEL% neq 0 ( 
   exit 1
)

