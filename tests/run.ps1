[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repositoryRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$gateRunner = Join-Path $repositoryRoot 'gates/run.ps1'
$onboardingRunner = Join-Path $repositoryRoot 'onboarding/onboard.ps1'
$powerShell = (Get-Process -Id $PID).Path
$temporaryBase = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath())
$testRoot = [System.IO.Path]::GetFullPath((Join-Path $temporaryBase "ai-dev-system-m2-$([Guid]::NewGuid().ToString('N'))"))

if (-not $testRoot.StartsWith($temporaryBase, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw 'Refusing to create fixtures outside the system temporary directory.'
}

function Assert-True {
    param(
        [bool]$Condition,
        [string]$Message
    )

    if (-not $Condition) { throw $Message }
}

function Write-FixtureFile {
    param(
        [string]$Path,
        [string]$Content
    )

    $parent = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $parent)) {
        $null = New-Item -ItemType Directory -Path $parent
    }
    [System.IO.File]::WriteAllText($Path, $Content, [System.Text.UTF8Encoding]::new($false))
}

function Invoke-Tool {
    param(
        [string]$ScriptPath,
        [string[]]$Arguments
    )

    $output = @(& $powerShell -NoProfile -File $ScriptPath @Arguments 2>&1 | ForEach-Object { [string]$_ })
    [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        Output   = ($output -join "`n")
    }
}

function Initialize-FixtureRepository {
    param(
        [string]$Path,
        [string[]]$Files
    )

    & git -C $Path init --quiet
    if ($LASTEXITCODE -ne 0) { throw 'git init failed for fixture.' }
    & git -C $Path config user.email 'fixture@example.invalid'
    & git -C $Path config user.name 'M2 Fixture'
    & git -C $Path add -- @Files
    if ($LASTEXITCODE -ne 0) { throw 'git add failed for fixture.' }
    & git -C $Path commit --quiet -m 'fixture baseline'
    if ($LASTEXITCODE -ne 0) { throw 'git commit failed for fixture.' }
}

function Get-FileHashValue {
    param([string]$Path)
    (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
}

$passed = [System.Collections.Generic.List[string]]::new()

try {
    $null = New-Item -ItemType Directory -Path $testRoot

    $validGateProject = Join-Path $testRoot 'gate-valid'
    Write-FixtureFile -Path (Join-Path $validGateProject 'README.md') -Content "[Guide](docs/guide.md)`n"
    Write-FixtureFile -Path (Join-Path $validGateProject 'docs/guide.md') -Content "# Guide`n"
    $validBefore = Get-FileHashValue -Path (Join-Path $validGateProject 'README.md')
    $validGate = Invoke-Tool -ScriptPath $gateRunner -Arguments @('-ProjectRoot', $validGateProject, '-OutputFormat', 'Json')
    Assert-True ($validGate.ExitCode -eq 0) 'Valid local links should pass.'
    $validGateReport = $validGate.Output | ConvertFrom-Json
    Assert-True ($validGateReport.result -eq 'PASS') 'Valid gate fixture should report PASS.'
    Assert-True ((Get-FileHashValue -Path (Join-Path $validGateProject 'README.md')) -eq $validBefore) 'Gate runner modified a checked file.'
    $passed.Add('gate pass and read-only behavior')

    $brokenGateProject = Join-Path $testRoot 'gate-broken-link'
    Write-FixtureFile -Path (Join-Path $brokenGateProject 'README.md') -Content "[Missing](docs/missing.md)`n"
    $brokenBefore = Get-FileHashValue -Path (Join-Path $brokenGateProject 'README.md')
    $brokenGate = Invoke-Tool -ScriptPath $gateRunner -Arguments @('-ProjectRoot', $brokenGateProject, '-OutputFormat', 'Json')
    Assert-True ($brokenGate.ExitCode -eq 1) 'Broken local links should fail.'
    $brokenGateReport = $brokenGate.Output | ConvertFrom-Json
    Assert-True ($brokenGateReport.result -eq 'FAIL') 'Broken-link fixture should report FAIL.'
    Assert-True ((Get-FileHashValue -Path (Join-Path $brokenGateProject 'README.md')) -eq $brokenBefore) 'Failing gate modified a checked file.'
    $passed.Add('gate failure handling')

    $whitespaceProject = Join-Path $testRoot 'gate-whitespace'
    Write-FixtureFile -Path (Join-Path $whitespaceProject 'sample.txt') -Content "baseline`n"
    Initialize-FixtureRepository -Path $whitespaceProject -Files @('sample.txt')
    Write-FixtureFile -Path (Join-Path $whitespaceProject 'sample.txt') -Content "baseline`ntrailing  `n"
    $whitespaceGate = Invoke-Tool -ScriptPath $gateRunner -Arguments @('-ProjectRoot', $whitespaceProject, '-OutputFormat', 'Json')
    Assert-True ($whitespaceGate.ExitCode -eq 1) 'Git whitespace errors should fail.'
    $whitespaceReport = $whitespaceGate.Output | ConvertFrom-Json
    Assert-True (($whitespaceReport.gates | Where-Object id -eq 'git.diff-check').status -eq 'FAIL') 'git.diff-check should report FAIL.'
    $passed.Add('git diff gate')

    $missingGate = Invoke-Tool -ScriptPath $gateRunner -Arguments @('-ProjectRoot', (Join-Path $testRoot 'missing'), '-OutputFormat', 'Json')
    Assert-True ($missingGate.ExitCode -eq 2) 'Missing gate target should be blocked.'
    $passed.Add('gate blocked handling')

    $newProject = Join-Path $testRoot 'new-project'
    Write-FixtureFile -Path (Join-Path $newProject 'README.md') -Content "# New project`n"
    $newPreview = Invoke-Tool -ScriptPath $onboardingRunner -Arguments @('-ProjectRoot', $newProject, '-ProjectType', 'New', '-OutputFormat', 'Json')
    Assert-True ($newPreview.ExitCode -eq 0) 'New-project preview should succeed.'
    $newPreviewReport = $newPreview.Output | ConvertFrom-Json
    Assert-True ($newPreviewReport.proposal.action -eq 'CREATE') 'New-project preview should propose creation.'
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $newProject '.ai-dev-system'))) 'Preview created project state.'
    $newApply = Invoke-Tool -ScriptPath $onboardingRunner -Arguments @('-ProjectRoot', $newProject, '-ProjectType', 'New', '-Apply', '-OutputFormat', 'Json')
    Assert-True ($newApply.ExitCode -eq 0) 'New-project apply should succeed.'
    $newContext = Join-Path $newProject '.ai-dev-system/PROJECT_CONTEXT.md'
    Assert-True (Test-Path -LiteralPath $newContext -PathType Leaf) 'New-project context was not created.'
    Assert-True (([System.IO.File]::ReadAllText($newContext)) -match 'Project type: New') 'New-project type was not recorded.'
    $newContextHash = Get-FileHashValue -Path $newContext
    $newSecondApply = Invoke-Tool -ScriptPath $onboardingRunner -Arguments @('-ProjectRoot', $newProject, '-ProjectType', 'New', '-Apply', '-OutputFormat', 'Json')
    Assert-True ($newSecondApply.ExitCode -eq 2) 'Existing context should block a second apply.'
    Assert-True ((Get-FileHashValue -Path $newContext) -eq $newContextHash) 'Second apply overwrote existing context.'
    $passed.Add('new-project preview, apply, and no-overwrite behavior')

    $activeProject = Join-Path $testRoot 'active-project'
    Write-FixtureFile -Path (Join-Path $activeProject 'AGENTS.md') -Content "# Existing instructions`n"
    Write-FixtureFile -Path (Join-Path $activeProject 'README.md') -Content "# Active project`n"
    Write-FixtureFile -Path (Join-Path $activeProject '.editorconfig') -Content "root = true`n"
    Write-FixtureFile -Path (Join-Path $activeProject 'package.json') -Content "{}`n"
    Write-FixtureFile -Path (Join-Path $activeProject 'tests/check.txt') -Content "fixture`n"
    Initialize-FixtureRepository -Path $activeProject -Files @('AGENTS.md', 'README.md', '.editorconfig', 'package.json', 'tests/check.txt')
    $protectedPaths = @('AGENTS.md', 'README.md', '.editorconfig', 'package.json', 'tests/check.txt')
    $protectedHashes = @{}
    foreach ($path in $protectedPaths) {
        $protectedHashes[$path] = Get-FileHashValue -Path (Join-Path $activeProject $path)
    }
    $activePreview = Invoke-Tool -ScriptPath $onboardingRunner -Arguments @('-ProjectRoot', $activeProject, '-ProjectType', 'Active', '-OutputFormat', 'Json')
    Assert-True ($activePreview.ExitCode -eq 0) 'Active-project preview should succeed.'
    $activeReport = $activePreview.Output | ConvertFrom-Json
    Assert-True ($activeReport.discovery.instructions -contains 'AGENTS.md') 'Existing instructions were not detected.'
    Assert-True ($activeReport.discovery.conventions -contains '.editorconfig') 'Existing conventions were not detected.'
    Assert-True ($activeReport.discovery.checks -contains 'package.json') 'Existing check definitions were not detected.'
    Assert-True ($activeReport.discovery.documentation -contains 'README.md') 'Existing documentation was not detected.'
    $activeApply = Invoke-Tool -ScriptPath $onboardingRunner -Arguments @('-ProjectRoot', $activeProject, '-ProjectType', 'Active', '-Apply', '-OutputFormat', 'Json')
    Assert-True ($activeApply.ExitCode -eq 0) 'Clean active-project apply should succeed.'
    foreach ($path in $protectedPaths) {
        Assert-True ((Get-FileHashValue -Path (Join-Path $activeProject $path)) -eq $protectedHashes[$path]) "Onboarding modified existing active-project file: $path"
    }
    $passed.Add('active-project discovery and preservation')

    $dirtyProject = Join-Path $testRoot 'dirty-project'
    Write-FixtureFile -Path (Join-Path $dirtyProject 'README.md') -Content "# Baseline`n"
    Initialize-FixtureRepository -Path $dirtyProject -Files @('README.md')
    Write-FixtureFile -Path (Join-Path $dirtyProject 'README.md') -Content "# User change`n"
    $dirtyHash = Get-FileHashValue -Path (Join-Path $dirtyProject 'README.md')
    $dirtyApply = Invoke-Tool -ScriptPath $onboardingRunner -Arguments @('-ProjectRoot', $dirtyProject, '-ProjectType', 'Active', '-Apply', '-OutputFormat', 'Json')
    Assert-True ($dirtyApply.ExitCode -eq 2) 'Dirty active project should block apply.'
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $dirtyProject '.ai-dev-system'))) 'Dirty-project apply created onboarding state.'
    Assert-True ((Get-FileHashValue -Path (Join-Path $dirtyProject 'README.md')) -eq $dirtyHash) 'Dirty-project apply modified user work.'
    $passed.Add('dirty-worktree blocking and preservation')

    $legacyProject = Join-Path $testRoot 'legacy-project'
    Write-FixtureFile -Path (Join-Path $legacyProject 'README.md') -Content "# Legacy project`n"
    Write-FixtureFile -Path (Join-Path $legacyProject 'src/app.txt') -Content "legacy behavior`n"
    Initialize-FixtureRepository -Path $legacyProject -Files @('README.md', 'src/app.txt')
    $legacyHash = Get-FileHashValue -Path (Join-Path $legacyProject 'src/app.txt')
    $legacyApply = Invoke-Tool -ScriptPath $onboardingRunner -Arguments @('-ProjectRoot', $legacyProject, '-ProjectType', 'Legacy', '-Apply', '-OutputFormat', 'Json')
    Assert-True ($legacyApply.ExitCode -eq 0) 'Clean legacy-project apply should succeed.'
    $legacyContext = Join-Path $legacyProject '.ai-dev-system/PROJECT_CONTEXT.md'
    Assert-True (([System.IO.File]::ReadAllText($legacyContext)) -match 'Project type: Legacy') 'Legacy-project type was not recorded.'
    Assert-True ((Get-FileHashValue -Path (Join-Path $legacyProject 'src/app.txt')) -eq $legacyHash) 'Legacy onboarding modified source.'
    $passed.Add('legacy-project onboarding and preservation')

    $unversionedActive = Join-Path $testRoot 'unversioned-active'
    Write-FixtureFile -Path (Join-Path $unversionedActive 'README.md') -Content "# Active without Git`n"
    $unversionedApply = Invoke-Tool -ScriptPath $onboardingRunner -Arguments @('-ProjectRoot', $unversionedActive, '-ProjectType', 'Active', '-Apply', '-OutputFormat', 'Json')
    Assert-True ($unversionedApply.ExitCode -eq 2) 'Unversioned active project should block apply.'
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $unversionedActive '.ai-dev-system'))) 'Blocked unversioned apply created state.'
    $passed.Add('unverifiable-project blocking')

    foreach ($name in $passed) {
        "[PASS] $name"
    }
    "RESULT: PASS ($($passed.Count) checks)"
} finally {
    if (Test-Path -LiteralPath $testRoot) {
        $resolvedTestRoot = [System.IO.Path]::GetFullPath($testRoot)
        if (-not $resolvedTestRoot.StartsWith($temporaryBase, [System.StringComparison]::OrdinalIgnoreCase) -or
            $resolvedTestRoot -eq $temporaryBase) {
            throw 'Refusing to remove a fixture path outside the intended temporary directory.'
        }
        Remove-Item -LiteralPath $resolvedTestRoot -Recurse -Force
    }
}
