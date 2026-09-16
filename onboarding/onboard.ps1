[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$ProjectRoot,
    [Parameter(Mandatory)]
    [ValidateSet('New', 'Active', 'Legacy')]
    [string]$ProjectType,
    [switch]$Apply,
    [ValidateSet('Text', 'Json')]
    [string]$OutputFormat = 'Text'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function ConvertTo-RelativePathList {
    param(
        [System.IO.FileInfo[]]$Files,
        [string]$Root
    )

    @($Files | ForEach-Object {
        [System.IO.Path]::GetRelativePath($Root, $_.FullName).Replace('\', '/')
    } | Sort-Object -Unique)
}

function ConvertTo-MarkdownList {
    param([string[]]$Items)

    if ($Items.Count -eq 0) { return '- None detected.' }
    return (($Items | ForEach-Object { "- ``$($_.Replace('`', '``'))``" }) -join "`n")
}

function Write-OnboardingReport {
    param(
        [object]$Report,
        [string]$Format
    )

    if ($Format -eq 'Json') {
        $Report | ConvertTo-Json -Depth 7
        return
    }

    "RESULT: $($Report.result)"
    "PROJECT: $($Report.projectRoot)"
    "TYPE: $($Report.projectType)"
    "GIT: repository=$($Report.git.isRepository) clean=$($Report.git.clean) root=$($Report.git.root)"
    "DISCOVERED: instructions=$($Report.discovery.instructions.Count) context=$($Report.discovery.context.Count) conventions=$($Report.discovery.conventions.Count) checks=$($Report.discovery.checks.Count) docs=$($Report.discovery.documentation.Count)"
    "PROPOSAL: $($Report.proposal.action) $($Report.proposal.target)"
    foreach ($reason in $Report.proposal.reasons) {
        "  $reason"
    }
}

try {
    $resolvedRoot = [System.IO.Path]::GetFullPath($ProjectRoot)
    if (-not (Test-Path -LiteralPath $resolvedRoot -PathType Container)) {
        throw "Project root does not exist: $resolvedRoot"
    }

    $rootItem = Get-Item -LiteralPath $resolvedRoot -Force
    if (($rootItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw 'Project root cannot be a symbolic link or reparse point.'
    }

    $gitCommand = Get-Command git -ErrorAction SilentlyContinue
    $isGitRepository = $false
    $isProjectGitRoot = $false
    $gitRoot = $null
    $gitChanges = @()

    if ($null -ne $gitCommand) {
        $gitRootOutput = @(& $gitCommand.Source -C $resolvedRoot rev-parse --show-toplevel 2>$null)
        if ($LASTEXITCODE -eq 0 -and $gitRootOutput.Count -gt 0) {
            $isGitRepository = $true
            $gitRoot = [System.IO.Path]::GetFullPath([string]$gitRootOutput[0])
            $gitPrefixOutput = @(& $gitCommand.Source -C $resolvedRoot rev-parse --show-prefix 2>&1)
            if ($LASTEXITCODE -ne 0) {
                throw "Git root comparison failed: $($gitPrefixOutput -join ' ')"
            }
            $isProjectGitRoot = [string]::IsNullOrEmpty(($gitPrefixOutput -join ''))
            if ($isProjectGitRoot) {
                $resolvedRoot = $gitRoot
            }
            $gitChanges = @(& $gitCommand.Source -C $gitRoot status --porcelain=v1 --untracked-files=all -- 2>&1 | ForEach-Object { [string]$_ })
            if ($LASTEXITCODE -ne 0) {
                throw "Git status failed: $($gitChanges -join ' ')"
            }
        }
    }

    if ($isGitRepository) {
        $relativeFiles = @(& $gitCommand.Source -C $gitRoot ls-files --cached --others --exclude-standard 2>&1)
        if ($LASTEXITCODE -ne 0) {
            throw "Git file discovery failed: $($relativeFiles -join ' ')"
        }
        $projectFiles = @($relativeFiles |
            ForEach-Object { Join-Path $gitRoot ([string]$_) } |
            Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } |
            ForEach-Object { Get-Item -LiteralPath $_ -Force })
        $discoveryTruncated = $false
    } else {
        $projectFiles = @(Get-ChildItem -LiteralPath $resolvedRoot -Recurse -File -Force -ErrorAction Stop |
            Where-Object { $_.FullName -notmatch '[\\/]\.git(?:[\\/]|$)' } |
            Sort-Object FullName |
            Select-Object -First 10000)
        $discoveryTruncated = $projectFiles.Count -eq 10000
    }

    $relative = @{}
    foreach ($file in $projectFiles) {
        $relative[$file.FullName] = [System.IO.Path]::GetRelativePath($resolvedRoot, $file.FullName).Replace('\', '/')
    }

    $instructionFiles = @($projectFiles | Where-Object {
        $path = $relative[$_.FullName]
        $_.Name -match '^(AGENTS|CLAUDE)\.md$' -or
        $_.Name -match '^CONTRIBUTING(?:\..+)?$' -or
        $_.Name -eq '.cursorrules' -or
        $_.Name -eq 'copilot-instructions.md' -or
        $path -match '^\.cursor/rules/'
    })

    $contextFiles = @($projectFiles | Where-Object {
        $path = $relative[$_.FullName]
        $path -match '(^|/)(PROJECT_CONTEXT\.md|project-context\.md)$' -or
        $path -eq 'docs/context.md'
    })

    $conventionFiles = @($projectFiles | Where-Object {
        $path = $relative[$_.FullName]
        $_.Name -in @('.editorconfig', '.gitattributes', '.gitignore') -or
        $_.Name -match '(?i)(lint|format|style|prettier|eslint)' -or
        $path -match '^\.github/(?!workflows/)'
    })

    $checkFiles = @($projectFiles | Where-Object {
        $path = $relative[$_.FullName]
        $_.Name -in @('Makefile', 'justfile', 'package.json', 'pyproject.toml', 'Cargo.toml', 'go.mod', 'pom.xml', 'build.gradle', 'build.gradle.kts') -or
        $path -match '(^|/)(tests?|specs?)(/|$)' -or
        $path -match '^\.github/workflows/'
    })

    $documentationFiles = @($projectFiles | Where-Object {
        $path = $relative[$_.FullName]
        $_.Name -match '^(README|CHANGELOG|ARCHITECTURE|CONTRIBUTING)(\..+)?$' -or
        $path -match '^docs/'
    })

    $instructions = @(ConvertTo-RelativePathList -Files $instructionFiles -Root $resolvedRoot)
    $contexts = @(ConvertTo-RelativePathList -Files $contextFiles -Root $resolvedRoot)
    $conventions = @(ConvertTo-RelativePathList -Files $conventionFiles -Root $resolvedRoot)
    $checks = @(ConvertTo-RelativePathList -Files $checkFiles -Root $resolvedRoot)
    $documentation = @(ConvertTo-RelativePathList -Files $documentationFiles -Root $resolvedRoot)

    $contextDirectory = Join-Path $resolvedRoot '.ai-dev-system'
    $contextTarget = Join-Path $contextDirectory 'PROJECT_CONTEXT.md'
    $templatePath = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../templates/project-context.md'))
    $blockers = [System.Collections.Generic.List[string]]::new()

    if ($contexts.Count -gt 0 -or (Test-Path -LiteralPath $contextTarget)) {
        $blockers.Add('A recognized project-context file already exists; choose how to preserve it manually.')
    }
    if ($isGitRepository -and $gitChanges.Count -gt 0) {
        $blockers.Add('The Git work tree has uncommitted changes; onboarding apply is read-only until they are resolved.')
    }
    if ($isGitRepository -and -not $isProjectGitRoot) {
        $blockers.Add("ProjectRoot must be the detected Git root: $gitRoot")
    }
    if (-not $isGitRepository -and $ProjectType -in @('Active', 'Legacy')) {
        $blockers.Add('Active and legacy onboarding requires a Git work tree so existing changes can be verified.')
    }
    if (-not (Test-Path -LiteralPath $templatePath -PathType Leaf)) {
        $blockers.Add('The project-context template is unavailable.')
    }
    if (Test-Path -LiteralPath $contextDirectory) {
        $contextDirectoryItem = Get-Item -LiteralPath $contextDirectory -Force
        if (-not $contextDirectoryItem.PSIsContainer) {
            $blockers.Add('.ai-dev-system exists but is not a directory.')
        } elseif (($contextDirectoryItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
            $blockers.Add('.ai-dev-system cannot be a symbolic link or reparse point.')
        }
    }
    if ($discoveryTruncated) {
        $blockers.Add('File discovery reached the 10,000-file safety limit; narrow or version the project before apply.')
    }

    $proposalAction = if ($blockers.Count -eq 0) { 'CREATE' } else { 'BLOCKED' }
    $report = [pscustomobject][ordered]@{
        result      = 'PREVIEW'
        projectRoot = $resolvedRoot
        projectType = $ProjectType
        git          = [pscustomobject][ordered]@{
            isRepository = $isGitRepository
            root         = $gitRoot
            clean        = if ($isGitRepository) { $gitChanges.Count -eq 0 } else { $null }
            changes      = @($gitChanges)
        }
        discovery    = [pscustomobject][ordered]@{
            instructions = @($instructions)
            context      = @($contexts)
            conventions  = @($conventions)
            checks       = @($checks)
            documentation = @($documentation)
            truncated    = $discoveryTruncated
        }
        proposal     = [pscustomobject][ordered]@{
            action  = $proposalAction
            target  = $contextTarget
            reasons = @($blockers.ToArray())
        }
    }

    if (-not $Apply) {
        Write-OnboardingReport -Report $report -Format $OutputFormat
        exit 0
    }

    if ($blockers.Count -gt 0) {
        $report.result = 'BLOCKED'
        Write-OnboardingReport -Report $report -Format $OutputFormat
        exit 2
    }

    $typeGuidance = switch ($ProjectType) {
        'New' { '- Define intended users, boundaries, constraints, and success criteria before implementation.' }
        'Active' { '- Confirm established behavior, conventions, checks, and compatibility requirements before proposing changes.' }
        'Legacy' { '- Separate observed behavior from documentation claims; record drift, fragile boundaries, and modernization risks.' }
    }

    $gitState = if ($isGitRepository) { '- Clean Git work tree.' } else { '- Git repository not initialized.' }
    $template = [System.IO.File]::ReadAllText($templatePath)
    $content = $template.
        Replace('{{PROJECT_NAME}}', (Split-Path -Leaf $resolvedRoot)).
        Replace('{{PROJECT_TYPE}}', $ProjectType).
        Replace('{{DISCOVERY_DATE_UTC}}', [DateTime]::UtcNow.ToString('yyyy-MM-dd')).
        Replace('{{TYPE_GUIDANCE}}', $typeGuidance).
        Replace('{{INSTRUCTIONS}}', (ConvertTo-MarkdownList -Items $instructions)).
        Replace('{{CONTEXT_FILES}}', (ConvertTo-MarkdownList -Items $contexts)).
        Replace('{{CONVENTIONS}}', (ConvertTo-MarkdownList -Items $conventions)).
        Replace('{{CHECKS}}', (ConvertTo-MarkdownList -Items $checks)).
        Replace('{{DOCUMENTATION}}', (ConvertTo-MarkdownList -Items $documentation)).
        Replace('{{GIT_STATE}}', $gitState)

    if (-not (Test-Path -LiteralPath $contextDirectory)) {
        $null = New-Item -ItemType Directory -Path $contextDirectory
    }

    $temporaryPath = Join-Path $contextDirectory (".PROJECT_CONTEXT.$([Guid]::NewGuid().ToString('N')).tmp")
    try {
        [System.IO.File]::WriteAllText($temporaryPath, $content, [System.Text.UTF8Encoding]::new($false))
        [System.IO.File]::Move($temporaryPath, $contextTarget)
    } finally {
        if (Test-Path -LiteralPath $temporaryPath) {
            Remove-Item -LiteralPath $temporaryPath -Force
        }
    }

    $report.result = 'APPLIED'
    $report.proposal.action = 'CREATED'
    Write-OnboardingReport -Report $report -Format $OutputFormat
    exit 0
} catch {
    $failure = [pscustomobject][ordered]@{
        result      = 'ERROR'
        projectRoot = $ProjectRoot
        projectType = $ProjectType
        error       = $_.Exception.Message
    }
    if ($OutputFormat -eq 'Json') {
        $failure | ConvertTo-Json -Depth 4
    } else {
        "RESULT: ERROR"
        "ERROR: $($_.Exception.Message)"
    }
    exit 1
}
