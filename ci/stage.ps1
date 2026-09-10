param([string]$Subdir)
New-Item -ItemType Directory -Path native-results -Force | Out-Null
Get-ChildItem "C:\libxcb-local\$Subdir\*.conda", "C:\libxcb-local\$Subdir\sha256.json" -ErrorAction SilentlyContinue | Copy-Item -Destination native-results
# Preserve packages that built but failed consumer tests for diagnosis.
Get-ChildItem 'C:\libxcb-build\broken\*.conda' -ErrorAction SilentlyContinue | Copy-Item -Destination native-results

$root = 'C:\libxcb-build'
if (Test-Path $root) {
    Get-ChildItem $root -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -eq 'config.log' -or $_.Name -eq 'test-suite.log' -or $_.Extension -eq '.trs' } |
        ForEach-Object {
            $relative = $_.FullName.Substring($root.Length).TrimStart('\')
            $destination = Join-Path 'native-results\logs' $relative
            New-Item -ItemType Directory -Path (Split-Path $destination) -Force | Out-Null
            Copy-Item $_.FullName $destination
        }
}
