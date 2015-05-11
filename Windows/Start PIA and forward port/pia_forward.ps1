$USERNAME = (Get-Content pia.cred | Select -Index 0)
$PASSWORD = (Get-Content pia.cred | Select -Index 1)
$ID = (Get-Content pia.cred | Select -Index 2)
$LOCAL_IP = Get-NetAdapter -InterfaceDescription *TAP* | Get-NetIPAddress -AddressFamily IPv4

$postParams = @{user=$USERNAME; pass=$PASSWORD; client_id=$ID; local_ip=$LOCAL_IP}
$PORT = (Invoke-WebRequest -Uri https://www.privateinternetaccess.com/vpninfo/port_forward_assignment -Method POST -Body $postParams)

(ConvertFrom-Json $PORT).port | Out-File C:/temp/forwarded_port
