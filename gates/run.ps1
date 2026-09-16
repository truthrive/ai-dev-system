[CmdletBinding()]
param(
    [string]$ProjectRoot = (Get-Location).Path,
    [ValidateSet('Text', 'Json')]
    [string]$OutputFormat = 'Text'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function New-GateResult {
    param(
        [string]$Id,
        [ValidateSet('PASS', 'FAIL', 'BLOCKED', 'SKIP')]
        [string]$Status,
        [string]$Summary,
        [string[]]$Details = @()
    )

    [pscustomobject][ordered]@{
        id      = $Id
        status  = $Status
        summary = $Summary
        details = @($Details)
    }
}

function Write-GateReport {
    param(
        [object[]]$Results,
        [string]$Format
    )

    $overall = if ($Results.Status -contains 'FAIL') {
        'FAIL'
    } elseif ($Results.Status -contains 'BLOCKED') {
        'BLOCKED'
    } else {
        'PASS'
    }

    if ($Format -eq 'Json') {
        [pscustomobject][ordered]@{
            result = $overall
            gates  = @($Results)
        } | ConvertTo-Json -Depth 5
    } else {
        foreach ($result in $Results) {
            "[$($result.status)] $($result.id) - $($result.summary)"
            foreach ($detail in $result.details) {
                "  $detail"
            }
        }
        "RESULT: $overall"
    }

}

function Get-GateExitCode {
    param([object[]]$Results)

    if ($Results.Status -contains 'FAIL') { return 1 }
    if ($Results.Status -contains 'BLOCKED') { return 2 }
    return 0
}

$results = [System.Collections.Generic.List[object]]::new()

try {
    $resolvedRoot = [System.IO.Path]::GetFullPath($ProjectRoot)
} catch {
    $results.Add((New-GateResult -Id 'input.project-root' -Status 'BLOCKED' -Summary 'Project root is invalid.' -Details @($_.Exception.Message)))
    Write-GateReport -Results $results.ToArray() -Format $OutputFormat
    exit (Get-GateExitCode -Results $results.ToArray())
}

if (-not (Test-Path -LiteralPath $resolvedRoot -PathType Container)) {
    $results.Add((New-GateResult -Id 'input.project-root' -Status 'BLOCKED' -Summary 'Project root does not exist.' -Details @($resolvedRoot)))
    Write-GateReport -Results $results.ToArray() -Format $OutputFormat
    exit (Get-GateExitCode -Results $results.ToArray())
}

$git = Get-Command git -ErrorAction SilentlyContinue
$isGitWorkTree = $false
$gitRoot = $null

if ($null -ne $git) {
    $gitRootOutput = @(& $git.Source -C $resolvedRoot rev-parse --show-toplevel 2>$null)
    if ($LASTEXITCODE -eq 0 -and $gitRootOutput.Count -gt 0) {
        $isGitWorkTree = $true
        $gitRoot = [System.IO.Path]::GetFullPath([string]$gitRootOutput[0])
    }
}

if ($isGitWorkTree) {
    $unstagedOutput = @(& $git.Source -C $gitRoot diff --check -- 2>&1)
    $unstagedExit = $LASTEXITCODE
    $stagedOutput = @(& $git.Source -C $gitRoot diff --cached --check -- 2>&1)
    $stagedExit = $LASTEXITCODE
    $details = @($unstagedOutput + $stagedOutput | ForEach-Object { [string]$_ } | Where-Object { $_.Length -gt 0 })

    if ($unstagedExit -eq 0 -and $stagedExit -eq 0) {
        $results.Add((New-GateResult -Id 'git.diff-check' -Status 'PASS' -Summary 'Tracked staged and unstaged changes contain no whitespace errors.'))
    } else {
        $results.Add((New-GateResult -Id 'git.diff-check' -Status 'FAIL' -Summary 'Git reported whitespace errors.' -Details $details))
    }
} elseif ($null -eq $git -and (Test-Path -LiteralPath (Join-Path $resolvedRoot '.git'))) {
    $results.Add((New-GateResult -Id 'git.diff-check' -Status 'BLOCKED' -Summary 'Git metadata exists but Git is unavailable.'))
} else {
    $results.Add((New-GateResult -Id 'git.diff-check' -Status 'SKIP' -Summary 'Target is not a Git work tree.'))
}

$markdownFiles = @()
$discoveryBlocked = $null

try {
    if ($isGitWorkTree) {
        $relativeMarkdown = @(& $git.Source -C $gitRoot ls-files --cached --others --exclude-standard -- '*.md' 2>&1)
        if ($LASTEXITCODE -ne 0) {
            throw "Git could not enumerate Markdown files: $($relativeMarkdown -join ' ')"
        }
        $markdownFiles = @($relativeMarkdown | ForEach-Object { Join-Path $gitRoot ([string]$_) } | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf })
    } else {
        $markdownFiles = @(Get-ChildItem -LiteralPath $resolvedRoot -Recurse -File -Filter '*.md' -ErrorAction Stop |
            Where-Object { $_.FullName -notmatch '[\\/]\.git(?:[\\/]|$)' } |
            Select-Object -ExpandProperty FullName)
    }
} catch {
    $discoveryBlocked = $_.Exception.Message
}

if ($null -ne $discoveryBlocked) {
    $results.Add((New-GateResult -Id 'docs.local-links' -Status 'BLOCKED' -Summary 'Markdown files could not be enumerated.' -Details @($discoveryBlocked)))
} else {
    $brokenLinks = [System.Collections.Generic.List[string]]::new()
    $readErrors = [System.Collections.Generic.List[string]]::new()
    $linkPattern = '\[[^\]]*\]\(([^)]+)\)'

    foreach ($markdownFile in $markdownFiles) {
        try {
            $content = [System.IO.File]::ReadAllText($markdownFile)
            foreach ($match in [regex]::Matches($content, $linkPattern)) {
                $rawTarget = $match.Groups[1].Value.Trim()
                if ($rawTarget.StartsWith('<') -and $rawTarget.Contains('>')) {
                    $rawTarget = $rawTarget.Substring(1, $rawTarget.IndexOf('>') - 1)
                } else {
                    $rawTarget = ($rawTarget -split '\s+', 2)[0]
                }

                if ([string]::IsNullOrWhiteSpace($rawTarget) -or
                    $rawTarget.StartsWith('#') -or
                    $rawTarget.StartsWith('/') -or
                    $rawTarget.StartsWith('//') -or
                    $rawTarget -match '^[A-Za-z][A-Za-z0-9+.-]*:') {
                    continue
                }

                $pathOnly = ($rawTarget -split '[#?]', 2)[0]
                if ([string]::IsNullOrWhiteSpace($pathOnly)) { continue }

                $decodedPath = [System.Uri]::UnescapeDataString($pathOnly)
                $candidate = [System.IO.Path]::GetFullPath((Join-Path (Split-Path -Parent $markdownFile) $decodedPath))
                if (-not (Test-Path -LiteralPath $candidate)) {
                    $displayFile = [System.IO.Path]::GetRelativePath($resolvedRoot, $markdownFile)
                    $brokenLinks.Add("$displayFile -> $rawTarget")
                }
            }
        } catch {
            $readErrors.Add("${markdownFile}: $($_.Exception.Message)")
        }
    }

    if ($readErrors.Count -gt 0) {
        $results.Add((New-GateResult -Id 'docs.local-links' -Status 'BLOCKED' -Summary 'One or more Markdown files could not be inspected.' -Details $readErrors.ToArray()))
    } elseif ($brokenLinks.Count -gt 0) {
        $results.Add((New-GateResult -Id 'docs.local-links' -Status 'FAIL' -Summary 'One or more relative local links do not resolve.' -Details $brokenLinks.ToArray()))
    } else {
        $results.Add((New-GateResult -Id 'docs.local-links' -Status 'PASS' -Summary "Validated relative local links in $($markdownFiles.Count) Markdown file(s)."))
    }
}

Write-GateReport -Results $results.ToArray() -Format $OutputFormat
exit (Get-GateExitCode -Results $results.ToArray())
