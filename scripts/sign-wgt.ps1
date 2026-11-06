# Assina um .wgt com o perfil de certificado Samsung da TV (perfil "tv")
# Uso: .\sign-wgt.ps1 -Wgt C:\Users\Bruno\Downloads\App.wgt
# Gera App-signed.wgt ao lado do original.
param(
    [Parameter(Mandatory = $true)][string]$Wgt,
    [string]$Profile = "tv",
    [string]$TizenCli = "C:\tizen-studio\tools\ide\bin\tizen.bat"
)

$ErrorActionPreference = "Stop"
$wgtPath = (Resolve-Path $Wgt).Path
if (-not (Test-Path $TizenCli)) { throw "tizen.bat nao encontrado em $TizenCli" }

# Extrai o wgt (e um zip) numa pasta de trabalho
$work = Join-Path ([IO.Path]::GetTempPath()) ("wgt-sign-" + [IO.Path]::GetFileNameWithoutExtension($wgtPath))
if (Test-Path $work) { Remove-Item $work -Recurse -Force }
New-Item -ItemType Directory -Path "$work\src" -Force | Out-Null
Copy-Item $wgtPath "$work\src\pkg.zip"
Expand-Archive "$work\src\pkg.zip" "$work\src" -Force
Remove-Item "$work\src\pkg.zip"

# Assina com o perfil tv (usa C:\Users\Bruno\SamsungCertificate\tv\ via profiles.xml)
Write-Host "Assinando com perfil '$Profile'..."
& $TizenCli package -t wgt -s $Profile -- "$work\src"

# Pega o wgt gerado e joga ao lado do original
$out = Get-ChildItem "$work\src" -Filter *.wgt | Select-Object -First 1
if (-not $out) { throw "Assinatura falhou: nenhum .wgt gerado em $work\src" }
$dest = Join-Path (Split-Path $wgtPath) (([IO.Path]::GetFileNameWithoutExtension($wgtPath)) + "-signed.wgt")
Copy-Item $out.FullName $dest -Force
Remove-Item $work -Recurse -Force
Write-Host "Pronto: $dest" -ForegroundColor Green
