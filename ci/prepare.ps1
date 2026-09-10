param([string]$Subdir)
$ErrorActionPreference = 'Stop'
$arch = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture
$expected = if ($Subdir -eq 'win-arm64') { 'Arm64' } else { 'X64' }
if ($arch -ne $expected) { throw "Expected $expected OS, got $arch" }
Write-Host "Native OS and target: $arch / $Subdir"
Invoke-WebRequest https://github.com/mamba-org/micromamba-releases/releases/download/1.5.10-0/micromamba-win-64 -OutFile "$env:RUNNER_TEMP\micromamba.exe"
New-Item -ItemType Directory -Path "C:\libxcb-local\$Subdir" -Force | Out-Null
if ($Subdir -eq 'win-arm64') {
    $items = Get-Content ci/prerequisites.json -Raw | ConvertFrom-Json
    foreach ($group in ($items | Group-Object artifact)) {
        $item = $group.Group[0]
        $zip = "$env:RUNNER_TEMP\$($item.artifact).zip"
        cmd /c "gh api repos/ClayWarren/$($item.repository)-feedstock/actions/artifacts/$($item.artifact)/zip > $zip"
        if ($LASTEXITCODE) { throw 'Prerequisite download failed' }
        Expand-Archive $zip "$env:RUNNER_TEMP\$($item.artifact)"
    }
    foreach ($item in $items) {
        $package = @(Get-ChildItem "$env:RUNNER_TEMP\$($item.artifact)" -Recurse -Filter $item.file)
        if ($package.Count -ne 1) { throw "Expected one $($item.file)" }
        $hash = (Get-FileHash $package[0].FullName -Algorithm SHA256).Hash.ToLower()
        if ($hash -ne $item.sha256) { throw "Wrong hash: $($item.file) $hash" }
        Write-Host "Verified $($item.file): $hash"
        Copy-Item $package[0].FullName C:\libxcb-local\win-arm64
    }
}
