# Automating web tests with Playwright

https://playwright.dev/

## Installation on ubuntu

```bash
sudo apt-get update
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
source ~/.bashrc
nvm list-remote
nvm install v18.20.1
 
sudo apt install npm

npm i -D @playwright/test
npm install js-yaml
npx playwright install
npx playwright install-deps
```

## Configure Windows 10 for WSL2
> Note : This is only required if you want to debug UI tests and see the browser window on your Windows 10 desktop.

- Download and install Windows X Server from https://sourceforge.net/projects/vcxsrv/
- Add a desktop shortcut with these options : `"C:\Program Files\VcXsrv\vcxsrv.exe" :0 -ac -terminate -lesspointer -multiwindow -clipboard -wgl -dpi auto` as explained in this [article](https://medium.com/javarevisited/using-wsl-2-with-x-server-linux-on-windows-a372263533c3)
- Identify your WSL2 Ip address by running `ipconfig` in a command prompt and look at the WSL adaptor

```
Ethernet adapter vEthernet (WSL):

   Connection-specific DNS Suffix  . :
   Link-local IPv6 Address . . . . . : fe80::5666:9e83:980c:76be%38
   IPv4 Address. . . . . . . . . . . : 172.26.48.1
   Subnet Mask . . . . . . . . . . . : 255.255.240.0
   Default Gateway . . . . . . . . . :
```
- In your WSL2 terminal, run `export DISPLAY=172.26.48.1:0.0`
- start X Server on Windows 10 by double clicking on the desktop shortcut you created earlier

## Record tests

See online documentation : https://playwright.dev/docs/codegen-intro

```bash
npx playwright codegen
```
