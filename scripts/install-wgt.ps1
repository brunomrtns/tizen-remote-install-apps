# Conecta na TV via sdb e instala um .wgt (ja assinado, ou usa -SignFirst para assinar antes)
# Uso:
#   .\install-wgt.ps1 -Wgt App-signed.wgt
#   .\install-wgt.ps1 -Wgt App.wgt -SignFirst          (assina e instala)
#   .\install-wgt.ps1 -Wgt App.wgt -TvIp 192.168.1.30  (IP da TV mudou)
param(
    [Parameter(Mandatory = $true)][string]$Wgt,
    [string]$TvIp = "192.168.1.21",
    [int]$Port = 26101,
    [switch]$SignFirst,
    [string]$Profile = "tv",
    [string]$Sdb = "C:\tizen-studio\tools\sdb.exe",
    [string]$TizenCli = "C:\tizen-studio\tools\ide\bin\tizen.bat"
)

$ErrorActionPreference = "Stop"
$wgtPath = (Resolve-Path $Wgt).Path

if ($SignFirst) {
    & "$PSScriptRoot\sign-wgt.ps1" -Wgt $wgtPath -Profile $Profile
    $wgtPath = Join-Path (Split-Path $wgtPath) (([IO.Path]::GetFileNameWithoutExtension($wgtPath)) + "-signed.wgt")
}

# Conecta na TV
$serial = "{0}:{1}" -f $TvIp, $Port
Write-Host "Conectando em $serial ..."
& $Sdb connect $serial | Out-Null

# Confere se conectou e pega o modelo (target)
$line = (& $Sdb devices) | Select-String $TvIp
if (-not $line) {
    throw @"
TV nao conectou. Checklist (aconteceu com a gente 2x):
1. Na TV: Apps > digitar 12345 > Server IP tem que ser o IP ATUAL do PC
2. Depois de mudar o Server IP: desligar a TV NA TOMADA e ligar de novo
3. Rodar .\find-tv.ps1 para confirmar que a porta 26101 responde
"@
}
$parts = ($line.ToString().Trim() -split "\s+")
$model = $parts[2]
Write-Host "TV: $model ($serial). Instalando..."

& $TizenCli install -n $wgtPath -s $serial -t $model
Write-Host "Instalado. Abre em Apps na TV." -ForegroundColor Green
