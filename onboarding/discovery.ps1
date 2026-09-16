# Shared read-only discovery. Never follow links into other trees.
function Test-DiscoveryPath {
    param([string]$Path)
    return $Path -notmatch '(^|[\\/])(\.git|node_modules|vendor|dist|build|coverage|\.astro|\.next|\.nuxt|\.cache|__pycache__|\.venv|venv|bin|obj)([\\/]|$)'
}

function Get-DiscoveryFiles {
    param([string]$Root)
    foreach ($entry in Get-ChildItem -LiteralPath $Root -Force -ErrorAction Stop) {
        if (($entry.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { continue }
        if (-not (Test-DiscoveryPath $entry.Name)) { continue }
        if ($entry.PSIsContainer) { Get-DiscoveryFiles $entry.FullName } else { $entry }
    }
}

function Test-DiscoveryFile {
    param([string]$Root, [string]$Path)
    if (-not (Test-DiscoveryPath $Path)) { return $false }
    $current = $Root
    foreach ($part in ($Path -split '[\\/]')) {
        if ($part -eq '..') { return $false }
        $current = Join-Path $current $part
        if (-not (Test-Path -LiteralPath $current)) { return $false }
        if (((Get-Item -LiteralPath $current -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { return $false }
    }
    return Test-Path -LiteralPath $current -PathType Leaf
}
