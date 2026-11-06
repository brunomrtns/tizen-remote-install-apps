# Aplica o patch do player do Saimo TV (forca o player MSE/HLS do browser em vez do AVPlay nativo)
# Uso: .\patch-saimo.ps1 -Wgt C:\Users\Bruno\Downloads\SaimoTV-Samsung.wgt
# Gera <nome>-patched.wgt assinado com o perfil tv, pronto para o install-wgt.ps1
param(
    [Parameter(Mandatory = $true)][string]$Wgt,
    [string]$Profile = "tv",
    [string]$TizenCli = "C:\tizen-studio\tools\ide\bin\tizen.bat"
)

$ErrorActionPreference = "Stop"
$wgtPath = (Resolve-Path $Wgt).Path

# extrai
$work = Join-Path ([IO.Path]::GetTempPath()) ("saimo-patch-" + (Get-Date -Format "yyyyMMddHHmmss"))
New-Item -ItemType Directory -Path "$work\src" -Force | Out-Null
Copy-Item $wgtPath "$work\src\pkg.zip"
Expand-Archive "$work\src\pkg.zip" "$work\src" -Force
Remove-Item "$work\src\pkg.zip"

# patch: neutraliza a escolha do AVPlay no Tizen (nomes do build 2.6.7)
$jsPath = "$work\src\saimo-tv.js"
$js = [IO.File]::ReadAllText($jsPath)
$alvo = 'return De.isTizen&&((s=window.webapis)!=null&&s.avplay)?'
$troca = 'return !1&&((s=window.webapis)!=null&&s.avplay)?'
$n = [regex]::Matches($js, [regex]::Escape($alvo)).Count
if ($n -eq 0) {
    # build novo: tenta padrao generico
    if ($js -match 'isTizen&&\(\(s=window\.webapis\)!=null&&s\.avplay\)\?') {
        $js = $js -replace 'isTizen&&\(\(s=window\.webapis\)!=null&&s\.avplay\)\?', '!1&&((s=window.webapis)!=null&&s.avplay)?'
        $trocaNota = "padrao generico"
    } else {
        throw "Padrao do AVPlay nao encontrado. O build mudou - ver docs/case-saimo-player.md"
    }
} else {
    $js = $js.Replace($alvo, $troca)
    $trocaNota = "build 2.6.7"
}
# UTF-8 sem BOM (Set-Content no PS5.1 poe BOM)
[IO.File]::WriteAllText($jsPath, $js)
Write-Host "Patch aplicado ($trocaNota)."

# assina
& $TizenCli package -t wgt -s $Profile -- "$work\src"
$out = Get-ChildItem "$work\src" -Filter *.wgt | Select-Object -First 1
if (-not $out) { throw "Assinatura falhou" }
$dest = Join-Path (Split-Path $wgtPath) (([IO.Path]::GetFileNameWithoutExtension($wgtPath)) + "-patched.wgt")
Copy-Item $out.FullName $dest -Force
Remove-Item $work -Recurse -Force
Write-Host "Pronto: $dest" -ForegroundColor Green
Write-Host "Instalar com: .\install-wgt.ps1 -Wgt `"$dest`""
