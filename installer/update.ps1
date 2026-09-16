[CmdletBinding()]
param(
    [string]$ProjectRoot = (Get-Location).Path,
    [string]$SourceRoot,
    [switch]$Apply,
    [switch]$Force,
    [ValidateSet('Text', 'Json')]
    [string]$OutputFormat = 'Text'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$installScript = Join-Path $PSScriptRoot 'install.ps1'
$splat = @{
    ProjectRoot  = $ProjectRoot
    Update       = $true
    OutputFormat = $OutputFormat
}
if ($SourceRoot) { $splat['SourceRoot'] = $SourceRoot }
if ($Apply) { $splat['Apply'] = $true }
if ($Force) { $splat['Force'] = $true }

& $installScript @splat
exit $LASTEXITCODE
