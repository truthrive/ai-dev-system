# Shared read-only discovery. Never follow links into other trees.
function Test-DiscoveryPath {
    param([string]$Path)
    return $Path -notmatch '(^|[\\/])(\.git|node_modules|vendor|dist|build|coverage|\.astro|\.next|\.nuxt|\.cache|__pycache__|\.venv|venv|bin|obj)([\\/]|$)'
}

function Get-DiscoveryFiles {
    param(
        [string]$Root,
        [string[]]$SkipDirectories = @()
    )
    foreach ($entry in Get-ChildItem -LiteralPath $Root -Force -ErrorAction Stop) {
        if (($entry.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { continue }
        if (-not (Test-DiscoveryPath $entry.Name)) { continue }
        if ($entry.PSIsContainer) {
            if ($SkipDirectories -contains [System.IO.Path]::GetFullPath($entry.FullName)) { continue }
            Get-DiscoveryFiles -Root $entry.FullName -SkipDirectories $SkipDirectories
        } else { $entry }
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

function Get-RelativePathCompat {
    param(
        [string]$RelativeTo,
        [string]$Path
    )

    $method = [type]::GetType('System.IO.Path').GetMethod('GetRelativePath', [type[]]@([string], [string]))
    if ($null -ne $method) {
        return [System.IO.Path]::GetRelativePath($RelativeTo, $Path)
    }

    $fromPath = [System.IO.Path]::GetFullPath($RelativeTo).TrimEnd('\', '/')
    $toPath = [System.IO.Path]::GetFullPath($Path).TrimEnd('\', '/')
    if ($fromPath -eq $toPath) { return '.' }

    $fromUri = [System.Uri]::new($fromPath + '/')
    $toUri = [System.Uri]::new($toPath)
    $relativeUri = $fromUri.MakeRelativeUri($toUri)
    $relativeString = [System.Uri]::UnescapeDataString($relativeUri.ToString())
    return $relativeString.Replace('/', [System.IO.Path]::DirectorySeparatorChar)
}
