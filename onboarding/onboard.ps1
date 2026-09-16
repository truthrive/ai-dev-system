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
. (Join-Path $PSScriptRoot 'discovery.ps1')
$gitAccessFailed = $false

function ConvertTo-RelativePathList {
    param(
        [System.IO.FileInfo[]]$Files,
        [string]$Root
    )

    @($Files | ForEach-Object {
        (Get-RelativePathCompat $Root $_.FullName).Replace('\', '/')
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
    $resolvedRoot = [System.IO.Path]::GetFullPath($ProjectRoot).TrimEnd('\', '/')
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
    $childGitRepositories = @()
    $childGitDiscoveryIssues = @()
    $childGitDirectories = @()

    if ($null -ne $gitCommand) {
        $previousEAP = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        try {
            $gitRootOutput = @(& $gitCommand.Source -C $resolvedRoot rev-parse --show-toplevel 2>&1 | ForEach-Object { [string]$_ })
            $rootExit = $LASTEXITCODE
        } finally {
            $ErrorActionPreference = $previousEAP
        }
        if ($rootExit -eq 0 -and $gitRootOutput.Count -gt 0) {
            $isGitRepository = $true
            $gitRoot = [System.IO.Path]::GetFullPath([string]$gitRootOutput[0]).TrimEnd('\', '/')
            $ErrorActionPreference = 'Continue'
            try {
                $gitPrefixOutput = @(& $gitCommand.Source -C $resolvedRoot rev-parse --show-prefix 2>&1 | ForEach-Object { [string]$_ })
                $prefixExit = $LASTEXITCODE
            } finally {
                $ErrorActionPreference = $previousEAP
            }
            if ($prefixExit -ne 0) {
                $gitAccessFailed = $true
                throw "Git root comparison failed: $($gitPrefixOutput -join "`n")"
            }
            $isProjectGitRoot = [string]::IsNullOrEmpty(($gitPrefixOutput -join ''))
            if ($isProjectGitRoot) {
                $resolvedRoot = $gitRoot
            }
            $ErrorActionPreference = 'Continue'
            try {
                $gitChanges = @(& $gitCommand.Source -C $gitRoot status --porcelain=v1 --untracked-files=all -- 2>&1 | ForEach-Object { [string]$_ })
                $statusExit = $LASTEXITCODE
            } finally {
                $ErrorActionPreference = $previousEAP
            }
            if ($statusExit -ne 0) {
                $gitAccessFailed = $true
                throw "Git status failed: $($gitChanges -join "`n")"
            }
        } elseif ((Test-Path -LiteralPath (Join-Path $resolvedRoot '.git')) -or
            ($gitRootOutput -join ' ') -notmatch 'not a git repository') {
            $gitAccessFailed = $true
            throw ($gitRootOutput -join "`n")
        }
    } elseif (Test-Path -LiteralPath (Join-Path $resolvedRoot '.git')) {
        $gitAccessFailed = $true
        throw 'Git metadata exists but Git is unavailable.'
    }

    if (-not $isGitRepository -and $null -ne $gitCommand) {
        foreach ($child in Get-ChildItem -LiteralPath $resolvedRoot -Directory -Force) {
            if (($child.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0 -or
                -not (Test-DiscoveryPath $child.Name)) { continue }
            if (-not (Test-Path -LiteralPath (Join-Path $child.FullName '.git'))) { continue }
            $childGitDirectories += [System.IO.Path]::GetFullPath($child.FullName)

            $childPath = [System.IO.Path]::GetFullPath($child.FullName).TrimEnd('\', '/')
            $previousEAP = $ErrorActionPreference
            $ErrorActionPreference = 'Continue'
            try {
                $childRootOutput = @(& $gitCommand.Source -C $childPath rev-parse --show-toplevel 2>&1 | ForEach-Object { [string]$_ })
                $childRootExit = $LASTEXITCODE
            } finally {
                $ErrorActionPreference = $previousEAP
            }
            if ($childRootExit -eq 0 -and $childRootOutput.Count -gt 0) {
                $childRoot = [System.IO.Path]::GetFullPath([string]$childRootOutput[0]).TrimEnd('\', '/')
                $ErrorActionPreference = 'Continue'
                try {
                    $childPrefixOutput = @(& $gitCommand.Source -C $childPath rev-parse --show-prefix 2>&1 | ForEach-Object { [string]$_ })
                    $childPrefixExit = $LASTEXITCODE
                } finally {
                    $ErrorActionPreference = $previousEAP
                }
                if ($childPrefixExit -eq 0 -and [string]::IsNullOrEmpty(($childPrefixOutput -join ''))) {
                    $childGitRepositories += [pscustomobject][ordered]@{
                        path = (Get-RelativePathCompat $resolvedRoot $child.FullName).Replace('\', '/')
                        root = $childRoot
                    }
                } elseif ($childPrefixExit -ne 0) {
                    $childGitDiscoveryIssues += [pscustomobject][ordered]@{
                        path  = (Get-RelativePathCompat $resolvedRoot $child.FullName).Replace('\', '/')
                        error = $childPrefixOutput -join "`n"
                    }
                }
            } else {
                $childGitDiscoveryIssues += [pscustomobject][ordered]@{
                    path  = (Get-RelativePathCompat $resolvedRoot $child.FullName).Replace('\', '/')
                    error = $childRootOutput -join "`n"
                }
            }
        }
    }

    if ($isGitRepository) {
        $previousEAP = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        try {
            $relativeFiles = @(& $gitCommand.Source -c core.quotePath=false -C $gitRoot ls-files --cached --others --exclude-standard 2>&1 | ForEach-Object { [string]$_ })
            $lsExit = $LASTEXITCODE
        } finally {
            $ErrorActionPreference = $previousEAP
        }
        if ($lsExit -ne 0) {
            $gitAccessFailed = $true
            throw "Git file discovery failed: $($relativeFiles -join ' ')"
        }
        $projectFiles = @($relativeFiles |
            Where-Object { Test-DiscoveryFile $gitRoot ([string]$_) } |
            ForEach-Object { Join-Path $gitRoot ([string]$_) } |
            Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } |
            ForEach-Object { Get-Item -LiteralPath $_ -Force })
        $discoveryTruncated = $false
    } else {
        $projectFiles = @(Get-DiscoveryFiles -Root $resolvedRoot -SkipDirectories $childGitDirectories |
            Select-Object -First 10000)
        $discoveryTruncated = $projectFiles.Count -eq 10000
    }

    # Probe only named ignored instruction files, never arbitrary ignored trees.
    $knownInstructions = @('AGENTS.md', 'CLAUDE.md', 'GEMINI.md', '.cursorrules', '.github/copilot-instructions.md')
    foreach ($skillsPath in @('.agent/skills', '.agents/skills', '.codex/skills')) {
        $skillsDirectory = Join-Path $resolvedRoot $skillsPath
        $safeParents = $true
        $parentPath = $resolvedRoot
        foreach ($part in ($skillsPath -split '/')) {
            $parentPath = Join-Path $parentPath $part
            if (-not (Test-Path -LiteralPath $parentPath -PathType Container) -or
                ((Get-Item -LiteralPath $parentPath -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)) {
                $safeParents = $false
                break
            }
        }
        if ($safeParents) {
            foreach ($folder in Get-ChildItem -LiteralPath $skillsDirectory -Directory -Force -ErrorAction SilentlyContinue) {
                $knownInstructions += "$skillsPath/$($folder.Name)/SKILL.md"
            }
        }
    }
    foreach ($rulesPath in @('.agents/rules', '.agent/rules', '.cursor/rules')) {
        $rulesDirectory = Join-Path $resolvedRoot $rulesPath
        $safeParents = $true
        $parentPath = $resolvedRoot
        foreach ($part in ($rulesPath -split '/')) {
            $parentPath = Join-Path $parentPath $part
            if (-not (Test-Path -LiteralPath $parentPath -PathType Container) -or
                ((Get-Item -LiteralPath $parentPath -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)) {
                $safeParents = $false
                break
            }
        }
        if ($safeParents) {
            foreach ($ruleFile in Get-ChildItem -LiteralPath $rulesDirectory -Filter '*.md' -Force -ErrorAction SilentlyContinue) {
                $knownInstructions += "$rulesPath/$($ruleFile.Name)"
            }
        }
    }
    foreach ($path in $knownInstructions) {
        if (Test-DiscoveryFile $resolvedRoot $path) {
            $projectFiles += Get-Item -LiteralPath (Join-Path $resolvedRoot $path) -Force
        }
    }
    $projectFiles = @($projectFiles | Sort-Object FullName -Unique)
    $relative = @{}
    foreach ($file in $projectFiles) {
        $relative[$file.FullName] = (Get-RelativePathCompat $resolvedRoot $file.FullName).Replace('\', '/')
    }

    $instructionFiles = @($projectFiles | Where-Object {
        $path = $relative[$_.FullName]
        $_.Name -match '^(AGENTS|CLAUDE|GEMINI)\.md$' -or
        $_.Name -match '^CONTRIBUTING(?:\..+)?$' -or
        $_.Name -eq '.cursorrules' -or
        $_.Name -eq 'copilot-instructions.md' -or
        $path -match '^\.(agent|agents|codex)/skills/[^/]+/SKILL\.md$' -or
        $path -match '^\.(cursor|agents|agent)/rules/'
    })

    $contextFiles = @($projectFiles | Where-Object {
        $path = $relative[$_.FullName]
        $path -match '(^|/)(PROJECT_CONTEXT\.md|project-context\.md|WEBSITE_CONTEXT_PACK\.md)$' -or
        $path -eq 'docs/context.md'
    })

    $conventionFiles = @($projectFiles | Where-Object {
        $path = $relative[$_.FullName]
        $_.Name -in @('.editorconfig', '.gitattributes', '.gitignore') -or
        $_.Name -match '^(?i)(eslint|prettier|stylelint|biome|tailwind)(?:\.config)?\.' -or
        $_.Name -match '^(?i)\.(prettierrc|stylelintrc|eslintrc)(?:\..+)?$' -or
        $path -match '^\.github/(?!workflows/)'
    })

    $checkFiles = @($projectFiles | Where-Object {
        $path = $relative[$_.FullName]
        $_.Name -in @('Makefile', 'justfile', 'package.json', 'pyproject.toml', 'Cargo.toml', 'go.mod', 'pom.xml', 'build.gradle', 'build.gradle.kts') -or
        $path -match '^\.github/workflows/'
    })

    $testSetupFiles = @($projectFiles | Where-Object {
        $path = $relative[$_.FullName]
        $path -match '(^|/)(tests?|specs?)/(setup|server-only)\.[^/]+$' -or
        $_.Name -match '^(?i)(vitest|jest|playwright|cypress)\.config\.'
    })

    $packageScriptDeclarations = [System.Collections.Generic.List[object]]::new()
    foreach ($packageFile in @($projectFiles | Where-Object { $_.Name -eq 'package.json' })) {
        $packagePath = $relative[$packageFile.FullName]
        try {
            $package = [System.IO.File]::ReadAllText($packageFile.FullName) | ConvertFrom-Json
            $scriptsProperty = $package.PSObject.Properties['scripts']
            $scripts = if ($null -eq $scriptsProperty -or $null -eq $scriptsProperty.Value) {
                @()
            } else {
                @($scriptsProperty.Value.PSObject.Properties.Name | Sort-Object)
            }
            $packageScriptDeclarations.Add([pscustomobject][ordered]@{ path = $packagePath; scripts = [string[]]@($scripts) })
        } catch {
            $packageScriptDeclarations.Add([pscustomobject][ordered]@{ path = $packagePath; scripts = [string[]]@(); parseError = $_.Exception.Message })
        }
    }
    $lockfileDeclarations = @($projectFiles | Where-Object {
        $_.Name -in @('package-lock.json', 'npm-shrinkwrap.json', 'yarn.lock', 'pnpm-lock.yaml', 'bun.lockb', 'bun.lock')
    } | ForEach-Object {
        [pscustomobject][ordered]@{
            path = $relative[$_.FullName]
            packageManager = switch ($_.Name) {
                'package-lock.json' { 'npm' }
                'npm-shrinkwrap.json' { 'npm' }
                'yarn.lock' { 'yarn' }
                'pnpm-lock.yaml' { 'pnpm' }
                default { 'bun' }
            }
        }
    })

    $documentationFiles = @($projectFiles | Where-Object {
        $path = $relative[$_.FullName]
        $_.Name -match '^(README|CHANGELOG|ARCHITECTURE|CONTRIBUTING)(\..+)?$' -or
        $path -match '^docs/' -or $_.Name -eq 'WEBSITE_CONTEXT_PACK.md'
    })

    $instructions = @(ConvertTo-RelativePathList -Files $instructionFiles -Root $resolvedRoot)
    $contexts = @(ConvertTo-RelativePathList -Files $contextFiles -Root $resolvedRoot)
    $conventions = @(ConvertTo-RelativePathList -Files $conventionFiles -Root $resolvedRoot)
    $checks = @(ConvertTo-RelativePathList -Files $checkFiles -Root $resolvedRoot)
    $testSetup = @(ConvertTo-RelativePathList -Files $testSetupFiles -Root $resolvedRoot)
    $declarationPaths = @($packageScriptDeclarations | ForEach-Object { $_.path }) + @($lockfileDeclarations | ForEach-Object { $_.path })
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
    if ($childGitRepositories.Count -gt 0) {
        $blockers.Add('Target contains immediate child Git repositories; select one Git root explicitly before onboarding.')
    }
    if ($childGitDiscoveryIssues.Count -gt 0) {
        $blockers.Add('Git metadata in an immediate child could not be verified; inspect the reported diagnostic before onboarding.')
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
            checkCandidates = @($checks)
            testSetupFiles = @($testSetup)
            childGitRepositories = @($childGitRepositories)
            childGitDiscoveryIssues = @($childGitDiscoveryIssues)
            declarations = [pscustomobject][ordered]@{
                packageScripts = @($packageScriptDeclarations.ToArray())
                lockfiles = @($lockfileDeclarations)
            }
            verifiedCommands = @()
            prerequisites = @()
            checkVerification = 'Not performed. Check candidates, test setup files, package scripts, and lockfiles are declarations only; no commands executed.'
            documentation = @($documentation)
            truncated    = $discoveryTruncated
        }
        evidence = [pscustomobject]@{
            verifiedFacts = @('Listed paths exist; Git state is observed when available. Project type is user-supplied.')
            documentationClaims = @($documentation + $contexts | Sort-Object -Unique)
            unknowns = @('Runtime behavior', 'Documentation accuracy', 'Verified check commands and prerequisites')
            sourceReferences = @($instructions + $contexts + $conventions + $checks + $testSetup + $documentation + $declarationPaths | Sort-Object -Unique)
            childGitRepositories = @($childGitRepositories)
            childGitDiscoveryIssues = @($childGitDiscoveryIssues)
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
        result      = if ($gitAccessFailed) { 'BLOCKED' } else { 'ERROR' }
        projectRoot = $ProjectRoot
        projectType = $ProjectType
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
