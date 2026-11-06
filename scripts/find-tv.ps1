# Varre a subnet procurando a porta 26101 (sdb da TV, so abre com Developer mode ligado)
# Uso: .\find-tv.ps1 [-Subnet 192.168.1]
param(
    [string]$Subnet = "192.168.1",
    [int]$Port = 26101,
    [int]$TimeoutMs = 200
)

Write-Host "Procurando porta $Port em $Subnet.0/24 ..."
$found = @()
1..254 | ForEach-Object {
    $ip = "$Subnet.$_"
    $t = New-Object System.Net.Sockets.TcpClient
    $r = $t.BeginConnect($ip, $Port, $null, $null)
    if ($r.AsyncWaitHandle.WaitOne($TimeoutMs) -and $t.Connected) { $found += $ip }
    $t.Close()
}

if ($found) {
    foreach ($ip in $found) {
        Write-Host "TV provivel: $ip (porta $Port aberta = Developer mode ativo)" -ForegroundColor Green
    }
} else {
    Write-Host "Nada na porta $Port. Dev mode desligado ou TV em outra rede." -ForegroundColor Yellow
}
