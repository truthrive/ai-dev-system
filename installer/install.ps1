[CmdletBinding()]
param(
    [string]$ProjectRoot = (Get-Location).Path,
    [string]$SourceRoot,
    [switch]$Apply,
    [switch]$Update,
    [switch]$Force,
    [ValidateSet('Text', 'Json')]
    [string]$OutputFormat = 'Text'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot '../onboarding/discovery.ps1')

function Get-FileHashValue {
    param([string]$Path)
    (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
}

function Write-InstallReport {
    param(
        [object]$Report,
        [string]$Format
    )

    if ($Format -eq 'Json') {
        $Report | ConvertTo-Json -Depth 6
        return
    }

    "RESULT: $($Report.result)"
    "MODE: $($Report.mode)"
    "PROJECT: $($Report.projectRoot)"
    "VERSION: target=$($Report.version.target) source=$($Report.version.source)"
    "ACTION: $($Report.proposal.action)"
    if ($Report.changes.added.Count -gt 0) {
        "ADDED ($($Report.changes.added.Count)):"
        foreach ($item in $Report.changes.added) { "  + $item" }
    }
    if ($Report.changes.updated.Count -gt 0) {
        "UPDATED ($($Report.changes.updated.Count)):"
        foreach ($item in $Report.changes.updated) { "  ~ $item" }
    }
    if ($Report.changes.removed.Count -gt 0) {
        "REMOVED ($($Report.changes.removed.Count)):"
        foreach ($item in $Report.changes.removed) { "  - $item" }
    }
    if ($Report.changes.preserved.Count -gt 0) {
        "PRESERVED ($($Report.changes.preserved.Count)):"
        foreach ($item in $Report.changes.preserved) { "  = $item" }
    }
    if ($Report.instructions.status) {
        "INSTRUCTIONS: $($Report.instructions.file) ($($Report.instructions.status))"
    }
    if ($Report.reasons.Count -gt 0) {
        "REASONS:"
        foreach ($reason in $Report.reasons) { "  $reason" }
    }
}

try {
    $resolvedTarget = [System.IO.Path]::GetFullPath($ProjectRoot).TrimEnd('\', '/')
    if (-not (Test-Path -LiteralPath $resolvedTarget -PathType Container)) {
        throw "Project root does not exist: $resolvedTarget"
    }
    $targetItem = Get-Item -LiteralPath $resolvedTarget -Force
    if (($targetItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw 'Project root cannot be a symbolic link or reparse point.'
    }

    $resolvedSource = if ($SourceRoot) {
        [System.IO.Path]::GetFullPath($SourceRoot).TrimEnd('\', '/')
    } else {
        [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..')).TrimEnd('\', '/')
    }
    if (-not (Test-Path -LiteralPath $resolvedSource -PathType Container)) {
        throw "Source root does not exist: $resolvedSource"
    }
    if ($resolvedTarget -eq $resolvedSource) {
        throw 'Project root cannot be the AI Dev System source repository itself.'
    }

    $sourceVersionFile = Join-Path $resolvedSource 'VERSION'
    if (-not (Test-Path -LiteralPath $sourceVersionFile -PathType Leaf)) {
        throw "Source VERSION file missing at: $sourceVersionFile"
    }
    $sourceVersion = (Get-Content -LiteralPath $sourceVersionFile -Raw).Trim()

    $targetSystemDir = Join-Path $resolvedTarget '.ai-dev-system'
    $isInstalled = Test-Path -LiteralPath $targetSystemDir -PathType Container
    $targetVersionFile = Join-Path $targetSystemDir 'VERSION'
    $targetManifestFile = Join-Path $targetSystemDir 'manifest.json'
    $targetContextFile = Join-Path $targetSystemDir 'PROJECT_CONTEXT.md'

    $targetVersion = if ($isInstalled -and (Test-Path -LiteralPath $targetVersionFile -PathType Leaf)) {
        (Get-Content -LiteralPath $targetVersionFile -Raw).Trim()
    } else {
        $null
    }

    $gitCommand = Get-Command git -ErrorAction SilentlyContinue
    $isGitRepository = $false
    $gitClean = $true
    $gitChanges = @()
    $gitAccessFailed = $false

    if ($null -ne $gitCommand) {
        $previousEAP = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        try {
            $gitRootOutput = @(& $gitCommand.Source -C $resolvedTarget rev-parse --show-toplevel 2>&1 | ForEach-Object { [string]$_ })
            $rootExit = $LASTEXITCODE
        } finally {
            $ErrorActionPreference = $previousEAP
        }
        if ($rootExit -eq 0 -and $gitRootOutput.Count -gt 0) {
            $isGitRepository = $true
            $targetGitRoot = [System.IO.Path]::GetFullPath([string]$gitRootOutput[0]).TrimEnd('\', '/')
            $ErrorActionPreference = 'Continue'
            try {
                $gitChanges = @(& $gitCommand.Source -C $targetGitRoot status --porcelain=v1 --untracked-files=all -- 2>&1 | ForEach-Object { [string]$_ })
                $statusExit = $LASTEXITCODE
            } finally {
                $ErrorActionPreference = $previousEAP
            }
            if ($statusExit -ne 0) {
                $gitAccessFailed = $true
                throw "Git status failed: $($gitChanges -join "`n")"
            }
            $gitClean = ($gitChanges.Count -eq 0)
        } elseif ((Test-Path -LiteralPath (Join-Path $resolvedTarget '.git')) -or
            ($gitRootOutput -join ' ') -notmatch 'not a git repository') {
            $gitAccessFailed = $true
            throw ($gitRootOutput -join "`n")
        }
    } elseif (Test-Path -LiteralPath (Join-Path $resolvedTarget '.git')) {
        $gitAccessFailed = $true
        throw 'Git metadata exists but Git is unavailable.'
    }

    $reasons = [System.Collections.Generic.List[string]]::new()
    $actionBlocked = $false

    if ($isGitRepository -and -not $gitClean) {
        $reasons.Add('Target Git work tree has uncommitted changes.')
        if ($Apply) { $actionBlocked = $true }
    }

    if ($Update -and -not $isInstalled) {
        $reasons.Add('AI Dev System is not installed in the target project; run install first.')
        $actionBlocked = $true
    }

    # Discover source managed files
    $managedComponents = @('core', 'docs', 'gates', 'onboarding', 'templates', 'installer')
    $sourceFiles = [System.Collections.Generic.Dictionary[string, string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    $sourceFiles['VERSION'] = Get-FileHashValue -Path $sourceVersionFile

    foreach ($comp in $managedComponents) {
        $compDir = Join-Path $resolvedSource $comp
        if (Test-Path -LiteralPath $compDir -PathType Container) {
            foreach ($file in Get-DiscoveryFiles -Root $compDir) {
                if ($file.Name -eq '.gitkeep') { continue }
                $relPath = (Get-RelativePathCompat $resolvedSource $file.FullName).Replace('\', '/')
                $sourceFiles[$relPath] = Get-FileHashValue -Path $file.FullName
            }
        }
    }

    # Inspect target manifest and check for local modifications
    $targetManifest = $null
    $modifiedFiles = [System.Collections.Generic.List[string]]::new()

    if ($isInstalled -and (Test-Path -LiteralPath $targetManifestFile -PathType Leaf)) {
        try {
            $targetManifest = Get-Content -LiteralPath $targetManifestFile -Raw | ConvertFrom-Json
            if ($null -ne $targetManifest -and $null -ne $targetManifest.files) {
                foreach ($prop in $targetManifest.files.PSObject.Properties) {
                    $rel = $prop.Name
                    $recordedHash = $prop.Value
                    $targetPath = Join-Path $targetSystemDir $rel
                    if (Test-Path -LiteralPath $targetPath -PathType Leaf) {
                        $currentHash = Get-FileHashValue -Path $targetPath
                        if ($currentHash -ne $recordedHash) {
                            $modifiedFiles.Add($rel)
                        }
                    }
                }
            }
        } catch {
            $reasons.Add("Failed to parse existing manifest: $($_.Exception.Message)")
        }
    }

    if ($modifiedFiles.Count -gt 0 -and -not $Force) {
        $reasons.Add("System-managed file(s) contain local modifications: $($modifiedFiles -join ', '). Use -Force to overwrite.")
        if ($Apply) { $actionBlocked = $true }
    }

    # Compute delta
    $added = [System.Collections.Generic.List[string]]::new()
    $updated = [System.Collections.Generic.List[string]]::new()
    $removed = [System.Collections.Generic.List[string]]::new()
    $preserved = [System.Collections.Generic.List[string]]::new()

    foreach ($rel in $sourceFiles.Keys) {
        $sourceHash = $sourceFiles[$rel]
        $targetPath = Join-Path $targetSystemDir $rel
        if (-not (Test-Path -LiteralPath $targetPath -PathType Leaf)) {
            $added.Add($rel)
        } else {
            $targetHash = Get-FileHashValue -Path $targetPath
            if ($targetHash -ne $sourceHash) {
                $updated.Add($rel)
            }
        }
    }

    if ($Update -and $null -ne $targetManifest -and $null -ne $targetManifest.files) {
        foreach ($prop in $targetManifest.files.PSObject.Properties) {
            $rel = $prop.Name
            if (-not $sourceFiles.ContainsKey($rel)) {
                $removed.Add($rel)
            }
        }
    }

    if (Test-Path -LiteralPath $targetContextFile -PathType Leaf) {
        $preserved.Add('PROJECT_CONTEXT.md')
    }

    # Instructions handling (AGENTS.md)
    $targetAgentsPath = Join-Path $resolvedTarget 'AGENTS.md'
    $agentsBlockStart = '<!-- AI-DEV-SYSTEM:START -->'
    $agentsBlockEnd = '<!-- AI-DEV-SYSTEM:END -->'
    $agentsBlockContent = @"
$agentsBlockStart
# Agent entrypoint

1. Read [.ai-dev-system/docs/INDEX.md](.ai-dev-system/docs/INDEX.md).
2. Read the [constitution](.ai-dev-system/core/constitution/default.md).
3. Inspect the current branch, working tree, source, and relevant runtime behavior before relying on documentation.
4. For first-time project adoption, use the preview-first [onboarding procedure](.ai-dev-system/docs/onboarding.md) before proposing changes.
5. Route new behavior to the [feature workflow](.ai-dev-system/core/workflows/feature.md), defects to the [bugfix workflow](.ai-dev-system/core/workflows/bugfix.md), and behavior-preserving structural work to the [refactor workflow](.ai-dev-system/core/workflows/refactor.md).
6. For documentation or investigation, load only the relevant rules and skills; use the read-only Context skill when project reality is uncertain.
7. Load only the selected workflow and the rules and skills it requires. Prefer the smallest necessary change and never modify unrelated files.
8. Verify against success criteria using project-native checks and applicable [gates](.ai-dev-system/gates/CONTRACT.md).
9. Record results under the [evidence contract](.ai-dev-system/docs/verification-evidence.md), then converge before claiming completion.

Unimplemented areas listed in the index do not supply additional instructions.
$agentsBlockEnd
"@.Trim()

    $instructionsStatus = $null
    $newAgentsContent = $null

    if (-not (Test-Path -LiteralPath $targetAgentsPath -PathType Leaf)) {
        $instructionsStatus = 'CREATE'
        $newAgentsContent = $agentsBlockContent + "`n"
    } else {
        $existingAgentsContent = [System.IO.File]::ReadAllText($targetAgentsPath, [System.Text.UTF8Encoding]::new($false))
        if ($existingAgentsContent.Contains($agentsBlockStart) -and $existingAgentsContent.Contains($agentsBlockEnd)) {
            $pattern = "(?s)" + [regex]::Escape($agentsBlockStart) + ".*?" + [regex]::Escape($agentsBlockEnd)
            $newAgentsContent = [regex]::Replace($existingAgentsContent, $pattern, [System.Text.RegularExpressions.MatchEvaluator] { $agentsBlockContent })
            if ($newAgentsContent -ne $existingAgentsContent) {
                $instructionsStatus = 'UPDATE_SECTION'
            } else {
                $instructionsStatus = 'UNCHANGED'
            }
        } else {
            $instructionsStatus = 'APPEND_SECTION'
            $newAgentsContent = $existingAgentsContent.TrimEnd() + "`n`n" + $agentsBlockContent + "`n"
        }
    }

    $mode = if ($Update) { 'UPDATE' } else { 'INSTALL' }
    $proposedAction = if ($actionBlocked) {
        'BLOCKED'
    } elseif ($Apply) {
        if ($Update) { 'UPDATED' } else { 'INSTALLED' }
    } else {
        if ($Update) { 'UPDATE' } else { 'INSTALL' }
    }

    $report = [pscustomobject][ordered]@{
        result       = if ($actionBlocked) { 'BLOCKED' } elseif ($Apply) { 'APPLIED' } else { 'PREVIEW' }
        mode         = $mode
        projectRoot  = $resolvedTarget
        version      = [pscustomobject][ordered]@{
            target = $targetVersion
            source = $sourceVersion
        }
        git          = [pscustomobject][ordered]@{
            isRepository = $isGitRepository
            clean        = $gitClean
        }
        proposal     = [pscustomobject][ordered]@{
            action = $proposedAction
        }
        changes      = [pscustomobject][ordered]@{
            added     = @($added)
            updated   = @($updated)
            removed   = @($removed)
            preserved = @($preserved)
        }
        instructions = [pscustomobject][ordered]@{
            file   = 'AGENTS.md'
            status = $instructionsStatus
        }
        reasons      = @($reasons)
    }

    if ($actionBlocked) {
        Write-InstallReport -Report $report -Format $OutputFormat
        exit 2
    }

    if (-not $Apply) {
        Write-InstallReport -Report $report -Format $OutputFormat
        exit 0
    }

    # Execute Apply
    if (-not (Test-Path -LiteralPath $targetSystemDir)) {
        $null = New-Item -ItemType Directory -Path $targetSystemDir
    }

    foreach ($rel in $sourceFiles.Keys) {
        $srcPath = if ($rel -eq 'VERSION') { $sourceVersionFile } else { Join-Path $resolvedSource $rel }
        $dstPath = Join-Path $targetSystemDir $rel
        $dstDir = Split-Path -Parent $dstPath
        if (-not (Test-Path -LiteralPath $dstDir)) {
            $null = New-Item -ItemType Directory -Path $dstDir
        }
        Copy-Item -LiteralPath $srcPath -Destination $dstPath -Force
    }

    foreach ($rel in $removed) {
        $dstPath = Join-Path $targetSystemDir $rel
        if (Test-Path -LiteralPath $dstPath -PathType Leaf) {
            Remove-Item -LiteralPath $dstPath -Force
        }
    }

    $manifestFilesObj = [pscustomobject][ordered]@{}
    foreach ($k in ($sourceFiles.Keys | Sort-Object)) {
        $manifestFilesObj | Add-Member -NotePropertyName $k -NotePropertyValue $sourceFiles[$k]
    }

    $manifestObj = [pscustomobject][ordered]@{
        version        = $sourceVersion
        installedAtUtc = [System.DateTime]::UtcNow.ToString('o')
        files          = $manifestFilesObj
    }
    $manifestJson = $manifestObj | ConvertTo-Json -Depth 6
    [System.IO.File]::WriteAllText($targetManifestFile, $manifestJson, [System.Text.UTF8Encoding]::new($false))

    if ($instructionsStatus -in @('CREATE', 'UPDATE_SECTION', 'APPEND_SECTION')) {
        [System.IO.File]::WriteAllText($targetAgentsPath, $newAgentsContent, [System.Text.UTF8Encoding]::new($false))
    }

    Write-InstallReport -Report $report -Format $OutputFormat
    exit 0

} catch {
    $failure = [pscustomobject][ordered]@{
        result      = if ($gitAccessFailed) { 'BLOCKED' } else { 'ERROR' }
        projectRoot = $ProjectRoot
        error       = $_.Exception.Message
    }
    if ($OutputFormat -eq 'Json') {
        $failure | ConvertTo-Json -Depth 4
    } else {
        "RESULT: $($failure.result)"
        "ERROR: $($_.Exception.Message)"
    }
    if ($gitAccessFailed) { exit 2 }
    exit 1
}
