# Code Server
Code Server is Visual Studio Code running in a browser. You can request to start a session, which will queue a job and provision a VM for your session thru the `Interactive Apps / Code Server` menu.

<img src="../images/code_server_request_menu.png" width="100%">

Set the `Maximum duration` for your session, `slot_type` and `Working Directory` then click on the `Launch` button.

<img src="../images/code_server_request.png" width="100%">

If no machine are available, your request will be queued and a new VM will be provisioned.

<img src="../images/code_server_queued.png" width="100%">

Once ready the session can be launched by clicking on the `Connect to VS Code` button.

<img src="../images/code_server_session_ready.png" width="100%">

This will open a new tab in your browser with `Visual Studio Code` open in your home directory. Your session will always be running even if you close the tab, as long as the request is not terminated. You can retrieve your running session thru the `My Interactive Sessions` menu.

