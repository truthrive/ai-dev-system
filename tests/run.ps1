[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repositoryRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..')).TrimEnd('\', '/')
$gateRunner = Join-Path $repositoryRoot 'gates/run.ps1'
$onboardingRunner = Join-Path $repositoryRoot 'onboarding/onboard.ps1'
$installerRunner = Join-Path $repositoryRoot 'installer/install.ps1'
$updaterRunner = Join-Path $repositoryRoot 'installer/update.ps1'
$powerShell = (Get-Process -Id $PID).Path
$temporaryBase = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath()).TrimEnd('\', '/')
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

    $previousEAP = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $output = @(& $powerShell -NoProfile -File $ScriptPath @Arguments 2>&1 | ForEach-Object { [string]$_ })
        $code = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previousEAP
    }
    [pscustomobject]@{
        ExitCode = $code
        Output   = ($output -join "`n")
    }
}

function Initialize-FixtureRepository {
    param(
        [string]$Path,
        [string[]]$Files
    )

    $trimmedPath = $Path.TrimEnd('\', '/')
    & git -C $trimmedPath init --quiet
    if ($LASTEXITCODE -ne 0) { throw 'git init failed for fixture.' }
    & git -C $trimmedPath config user.email 'fixture@example.invalid'
    & git -C $trimmedPath config user.name 'M2 Fixture'
    & git -C $trimmedPath add -- @Files
    if ($LASTEXITCODE -ne 0) { throw 'git add failed for fixture.' }
    & git -C $trimmedPath commit --quiet -m 'fixture baseline'
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

    $invalidGitProject = Join-Path $testRoot 'gate-invalid-git'
    Write-FixtureFile -Path (Join-Path $invalidGitProject 'README.md') -Content "# Invalid Git metadata`n"
    $null = New-Item -ItemType Directory -Path (Join-Path $invalidGitProject '.git')
    $invalidGitBefore = Get-FileHashValue -Path (Join-Path $invalidGitProject 'README.md')
    $invalidGitGate = Invoke-Tool -ScriptPath $gateRunner -Arguments @('-ProjectRoot', $invalidGitProject, '-OutputFormat', 'Json')
    Assert-True ($invalidGitGate.ExitCode -eq 2) 'Invalid Git metadata should block the gate runner.'
    $invalidGitReport = $invalidGitGate.Output | ConvertFrom-Json
    Assert-True ($invalidGitReport.result -eq 'BLOCKED') 'Invalid Git metadata should report an overall BLOCKED result.'
    Assert-True (($invalidGitReport.gates | Where-Object id -eq 'git.diff-check').status -eq 'BLOCKED') 'git.diff-check must be BLOCKED when Git metadata cannot be detected as a repository.'
    Assert-True ((Get-FileHashValue -Path (Join-Path $invalidGitProject 'README.md')) -eq $invalidGitBefore) 'Invalid-metadata handling modified a checked file.'
    $passed.Add('invalid Git metadata regression')

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

    $discoveryProject = Join-Path $testRoot 'discovery-project'
    Write-FixtureFile (Join-Path $discoveryProject '.gitignore') ".agent/`nprivate/`nnode_modules/`ndist/`n"
    Write-FixtureFile (Join-Path $discoveryProject 'README.md') "# Discovery`n"
    Write-FixtureFile (Join-Path $discoveryProject 'WEBSITE_CONTEXT_PACK.md') "# Existing context`n"
    Write-FixtureFile (Join-Path $discoveryProject 'package.json') '{"scripts":{"test":"DO_NOT_EXECUTE"}}'
    Initialize-FixtureRepository $discoveryProject @('.gitignore', 'README.md', 'WEBSITE_CONTEXT_PACK.md', 'package.json')
    Write-FixtureFile (Join-Path $discoveryProject '.agent/skills/project/SKILL.md') '# Local instructions'
    Write-FixtureFile (Join-Path $discoveryProject '.agent/private.md') '# Not an instruction'
    Write-FixtureFile (Join-Path $discoveryProject 'private/AGENTS.md') '# Private'
    Write-FixtureFile (Join-Path $discoveryProject 'node_modules/vendor/AGENTS.md') '# Vendor'
    Write-FixtureFile (Join-Path $discoveryProject 'dist/README.md') '[Broken](missing.md)'
    $contextBefore = Get-FileHashValue (Join-Path $discoveryProject 'WEBSITE_CONTEXT_PACK.md')
    Push-Location $testRoot
    try {
        $discoveryPreview = Invoke-Tool $onboardingRunner @('-ProjectRoot', $discoveryProject, '-ProjectType', 'Active', '-OutputFormat', 'Json')
    } finally { Pop-Location }
    Assert-True ($discoveryPreview.ExitCode -eq 0) 'Preview from unrelated directory failed.'
    $discoveryReport = $discoveryPreview.Output | ConvertFrom-Json
    Assert-True ($discoveryReport.discovery.instructions.Count -eq 1) 'Unexpected ignored or vendor instructions.'
    Assert-True ($discoveryReport.discovery.instructions -contains '.agent/skills/project/SKILL.md') 'Ignored instruction missing.'
    Assert-True ($discoveryReport.discovery.context -contains 'WEBSITE_CONTEXT_PACK.md') 'Existing context missed.'
    Assert-True ($discoveryReport.discovery.checkCandidates -contains 'package.json') 'Check candidate missing.'
    Assert-True ($discoveryReport.discovery.verifiedCommands.Count -eq 0) 'Candidates became verified commands.'
    Assert-True ($discoveryReport.discovery.prerequisites.Count -eq 0) 'Prerequisites were inferred.'
    Assert-True ($discoveryReport.evidence.documentationClaims -contains 'WEBSITE_CONTEXT_PACK.md') 'Documentation not marked unverified.'
    $duplicateApply = Invoke-Tool $onboardingRunner @('-ProjectRoot', $discoveryProject, '-ProjectType', 'Active', '-Apply', '-OutputFormat', 'Json')
    Assert-True ($duplicateApply.ExitCode -eq 2) 'Existing context must block duplicate creation.'
    Assert-True (-not (Test-Path (Join-Path $discoveryProject '.ai-dev-system'))) 'Duplicate context created.'
    Assert-True ((Get-FileHashValue (Join-Path $discoveryProject 'WEBSITE_CONTEXT_PACK.md')) -eq $contextBefore) 'Existing context changed.'
    $passed.Add('ignored instructions, context, candidate evidence, unrelated working directory')

    # Git's own test switch forces the ownership check, without safe.directory changes.
    $previousOwnerSetting = [Environment]::GetEnvironmentVariable('GIT_TEST_ASSUME_DIFFERENT_OWNER')
    try {
        $env:GIT_TEST_ASSUME_DIFFERENT_OWNER = '1'
        $ownershipPreview = Invoke-Tool $onboardingRunner @('-ProjectRoot', $discoveryProject, '-ProjectType', 'Active', '-OutputFormat', 'Json')
        $ownershipApply = Invoke-Tool $onboardingRunner @('-ProjectRoot', $discoveryProject, '-ProjectType', 'Active', '-Apply', '-OutputFormat', 'Json')
        $ownershipGate = Invoke-Tool $gateRunner @('-ProjectRoot', $discoveryProject, '-OutputFormat', 'Json')
    } finally {
        [Environment]::SetEnvironmentVariable('GIT_TEST_ASSUME_DIFFERENT_OWNER', $previousOwnerSetting)
    }
    Assert-True ($ownershipPreview.ExitCode -eq 2 -and $ownershipApply.ExitCode -eq 2) 'Ownership rejection must block preview and apply.'
    $ownershipReport = $ownershipPreview.Output | ConvertFrom-Json
    Assert-True ($ownershipReport.result -eq 'BLOCKED' -and $ownershipReport.error -match 'dubious ownership') 'Original ownership diagnostic missing.'
    Assert-True ($ownershipGate.ExitCode -eq 2) 'Ownership failure must block gates.'
    $ownershipGateReport = $ownershipGate.Output | ConvertFrom-Json
    Assert-True (@($ownershipGateReport.gates | Where-Object status -ne 'BLOCKED').Count -eq 0) 'Gate fell back after ownership rejection.'
    Assert-True (-not (Test-Path (Join-Path $discoveryProject '.ai-dev-system'))) 'Ownership failure wrote context.'
    $passed.Add('Git ownership rejection with preserved diagnostic and no fallback')

    $excludedProject = Join-Path $testRoot 'excluded-project'
    Write-FixtureFile (Join-Path $excludedProject 'README.md') '# New'
    foreach ($directory in @('node_modules', 'dist', '.astro', 'build', 'vendor', 'coverage')) {
        Write-FixtureFile (Join-Path $excludedProject "$directory/AGENTS.md") '[Missing](absent.md)'
        Write-FixtureFile (Join-Path $excludedProject "$directory/package.json") '{}'
    }
    $excludedPreview = Invoke-Tool $onboardingRunner @('-ProjectRoot', $excludedProject, '-ProjectType', 'New', '-OutputFormat', 'Json')
    $excludedReport = $excludedPreview.Output | ConvertFrom-Json
    Assert-True ($excludedReport.discovery.instructions.Count -eq 0 -and $excludedReport.discovery.checkCandidates.Count -eq 0) 'Excluded trees polluted discovery.'
    $excludedGate = Invoke-Tool $gateRunner @('-ProjectRoot', $excludedProject, '-OutputFormat', 'Json')
    Assert-True ($excludedGate.ExitCode -eq 0) 'Excluded generated links were scanned.'
    $passed.Add('non-Git dependency and generated directory exclusions')

    $parentProject = Join-Path $testRoot 'project-container'
    $nestedProject = Join-Path $parentProject 'nested-project'
    Write-FixtureFile (Join-Path $parentProject 'README.md') '# Project container'
    Write-FixtureFile (Join-Path $nestedProject 'README.md') '# Nested project'
    Write-FixtureFile (Join-Path $nestedProject 'package.json') '{"scripts":{"lint":"fixture-lint","test":"fixture-test"}}'
    Write-FixtureFile (Join-Path $nestedProject 'package-lock.json') '{"lockfileVersion":3}'
    Write-FixtureFile (Join-Path $nestedProject 'eslint.config.mjs') 'export default [];'
    Write-FixtureFile (Join-Path $nestedProject 'src/test/setup.ts') 'export {};'
    Write-FixtureFile (Join-Path $nestedProject 'src/components/setup-information-panel.tsx') 'export {};'
    Initialize-FixtureRepository $nestedProject @('README.md', 'package.json', 'package-lock.json', 'eslint.config.mjs', 'src/test/setup.ts', 'src/components/setup-information-panel.tsx')
    $parentPreview = Invoke-Tool $onboardingRunner @('-ProjectRoot', $parentProject, '-ProjectType', 'Active', '-OutputFormat', 'Json')
    Assert-True ($parentPreview.ExitCode -eq 0) 'Parent preview with immediate Git child failed.'
    $parentReport = $parentPreview.Output | ConvertFrom-Json
    Assert-True ((@($parentReport.discovery.childGitRepositories | ForEach-Object { $_.path }) -contains 'nested-project')) 'Immediate child Git root was not reported.'
    Assert-True ($parentReport.proposal.action -eq 'BLOCKED' -and $parentReport.proposal.reasons -match 'select one Git root explicitly') 'Parent did not require explicit child selection.'
    Assert-True ($parentReport.discovery.instructions.Count -eq 0) 'Parent discovery entered the nested repository.'
    $parentApply = Invoke-Tool $onboardingRunner @('-ProjectRoot', $parentProject, '-ProjectType', 'Active', '-Apply', '-OutputFormat', 'Json')
    Assert-True ($parentApply.ExitCode -eq 2 -and -not (Test-Path (Join-Path $parentProject '.ai-dev-system'))) 'Nested Git parent apply was not safely blocked.'
    $nestedPreview = Invoke-Tool $onboardingRunner @('-ProjectRoot', $nestedProject, '-ProjectType', 'Active', '-OutputFormat', 'Json')
    Assert-True ($nestedPreview.ExitCode -eq 0) 'Nested Git project preview failed.'
    $nestedReport = $nestedPreview.Output | ConvertFrom-Json
    Assert-True ($nestedReport.discovery.conventions -contains 'eslint.config.mjs') 'Declared lint configuration was not a convention.'
    Assert-True (-not ($nestedReport.discovery.conventions -contains 'src/components/setup-information-panel.tsx')) 'UI component was classified as a convention.'
    Assert-True ($nestedReport.discovery.testSetupFiles -contains 'src/test/setup.ts') 'Test setup was not reported separately.'
    Assert-True (-not ($nestedReport.discovery.checkCandidates -contains 'src/test/setup.ts')) 'Test setup was classified as a check entrypoint.'
    Assert-True ($nestedReport.discovery.declarations.packageScripts[0].scripts -contains 'test') 'Package script declaration was not reported.'
    Assert-True ($nestedReport.discovery.declarations.lockfiles.packageManager -contains 'npm') 'Lockfile indicator was not reported.'
    Assert-True ($nestedReport.discovery.verifiedCommands.Count -eq 0 -and $nestedReport.discovery.prerequisites.Count -eq 0) 'Declarations became verified execution evidence.'
    $passed.Add('nested Git selection, declaration evidence, and classification boundaries')

    $noScriptsProject = Join-Path $testRoot 'package-without-scripts'
    Write-FixtureFile (Join-Path $noScriptsProject 'package.json') '{"name":"no-scripts"}'
    $noScriptsPreview = Invoke-Tool $onboardingRunner @('-ProjectRoot', $noScriptsProject, '-ProjectType', 'New', '-OutputFormat', 'Json')
    Assert-True ($noScriptsPreview.ExitCode -eq 0) 'Valid package without scripts should not block preview.'
    $noScriptsDeclaration = ($noScriptsPreview.Output | ConvertFrom-Json).discovery.declarations.packageScripts[0]
    Assert-True ((@($noScriptsDeclaration.scripts).Count -eq 0)) 'Package without scripts must report no declared scripts.'
    Assert-True ($null -eq $noScriptsDeclaration.PSObject.Properties['parseError']) 'Package without scripts was reported as invalid JSON.'

    $invalidPackageProject = Join-Path $testRoot 'invalid-package-json'
    Write-FixtureFile (Join-Path $invalidPackageProject 'package.json') '{invalid json'
    $invalidPackagePreview = Invoke-Tool $onboardingRunner @('-ProjectRoot', $invalidPackageProject, '-ProjectType', 'New', '-OutputFormat', 'Json')
    Assert-True ($invalidPackagePreview.ExitCode -eq 0) 'Invalid package JSON should remain a non-fatal declaration error.'
    $invalidPackageDeclaration = ($invalidPackagePreview.Output | ConvertFrom-Json).discovery.declarations.packageScripts[0]
    Assert-True ($invalidPackageDeclaration.PSObject.Properties['parseError'].Value.Length -gt 0) 'Invalid package JSON must retain a parse error.'
    $passed.Add('package declaration StrictMode and invalid JSON handling')

    # M4 Installer & Updater fixtures
    $installerPreviewProject = Join-Path $testRoot 'installer-preview'
    Write-FixtureFile -Path (Join-Path $installerPreviewProject 'README.md') -Content "# Target Project`n"
    $installPreview = Invoke-Tool -ScriptPath $installerRunner -Arguments @('-ProjectRoot', $installerPreviewProject, '-OutputFormat', 'Json')
    Assert-True ($installPreview.ExitCode -eq 0) 'Installer preview should succeed.'
    $installPreviewReport = $installPreview.Output | ConvertFrom-Json
    Assert-True ($installPreviewReport.proposal.action -eq 'INSTALL') 'Installer preview should propose INSTALL.'
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $installerPreviewProject '.ai-dev-system'))) 'Installer preview created files.'
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $installerPreviewProject 'AGENTS.md'))) 'Installer preview created AGENTS.md.'
    $passed.Add('installer preview behavior')

    $installerApplyProject = Join-Path $testRoot 'installer-apply'
    Write-FixtureFile -Path (Join-Path $installerApplyProject 'README.md') -Content "# Fresh Project`n"
    $installApply = Invoke-Tool -ScriptPath $installerRunner -Arguments @('-ProjectRoot', $installerApplyProject, '-Apply', '-OutputFormat', 'Json')
    Assert-True ($installApply.ExitCode -eq 0) 'Installer apply should succeed.'
    $installApplyReport = $installApply.Output | ConvertFrom-Json
    Assert-True ($installApplyReport.proposal.action -eq 'INSTALLED') 'Installer apply should report INSTALLED.'
    $targetSysDir = Join-Path $installerApplyProject '.ai-dev-system'
    Assert-True (Test-Path -LiteralPath (Join-Path $targetSysDir 'VERSION') -PathType Leaf) 'VERSION file was not installed.'
    Assert-True (Test-Path -LiteralPath (Join-Path $targetSysDir 'manifest.json') -PathType Leaf) 'manifest.json was not installed.'
    Assert-True (Test-Path -LiteralPath (Join-Path $targetSysDir 'core/constitution/default.md') -PathType Leaf) 'Core constitution was not installed.'
    Assert-True (Test-Path -LiteralPath (Join-Path $installerApplyProject 'AGENTS.md') -PathType Leaf) 'AGENTS.md was not created.'
    $agentsText = [System.IO.File]::ReadAllText((Join-Path $installerApplyProject 'AGENTS.md'))
    Assert-True ($agentsText.Contains('<!-- AI-DEV-SYSTEM:START -->') -and $agentsText.Contains('<!-- AI-DEV-SYSTEM:END -->')) 'Delimited block missing from AGENTS.md.'
    $manifestData = Get-Content -LiteralPath (Join-Path $targetSysDir 'manifest.json') -Raw | ConvertFrom-Json
    Assert-True ($manifestData.version.Length -gt 0) 'Manifest version missing.'
    Assert-True ((@($manifestData.files.PSObject.Properties)).Count -gt 15) 'Manifest files count too low.'
    $passed.Add('installer apply and structure generation')

    $installerExistingProject = Join-Path $testRoot 'installer-existing'
    $customInstructions = "# Custom Project Header`nDo not modify these existing rules.`n"
    Write-FixtureFile -Path (Join-Path $installerExistingProject 'AGENTS.md') -Content $customInstructions
    Write-FixtureFile -Path (Join-Path $installerExistingProject 'README.md') -Content "# Existing Project`n"
    $existingInstall = Invoke-Tool -ScriptPath $installerRunner -Arguments @('-ProjectRoot', $installerExistingProject, '-Apply', '-OutputFormat', 'Json')
    Assert-True ($existingInstall.ExitCode -eq 0) 'Installer apply on existing AGENTS.md should succeed.'
    $existingAgentsText = [System.IO.File]::ReadAllText((Join-Path $installerExistingProject 'AGENTS.md'))
    Assert-True ($existingAgentsText.StartsWith($customInstructions)) 'Existing custom instructions were overwritten or lost.'
    Assert-True ($existingAgentsText.Contains('<!-- AI-DEV-SYSTEM:START -->')) 'Delimited block not appended to existing AGENTS.md.'
    $passed.Add('installer non-destructive AGENTS.md preservation')

    $updaterProject = Join-Path $testRoot 'updater-project'
    Write-FixtureFile -Path (Join-Path $updaterProject 'README.md') -Content "# Project to Update`n"
    $null = Invoke-Tool -ScriptPath $installerRunner -Arguments @('-ProjectRoot', $updaterProject, '-Apply')
    $customContext = "# Custom Project Context`nManaged by team.`n"
    Write-FixtureFile -Path (Join-Path $updaterProject '.ai-dev-system/PROJECT_CONTEXT.md') -Content $customContext
    $contextHashBefore = Get-FileHashValue -Path (Join-Path $updaterProject '.ai-dev-system/PROJECT_CONTEXT.md')
    $updateRun = Invoke-Tool -ScriptPath $updaterRunner -Arguments @('-ProjectRoot', $updaterProject, '-Apply', '-OutputFormat', 'Json')
    Assert-True ($updateRun.ExitCode -eq 0) 'Updater should succeed.'
    $contextHashAfter = Get-FileHashValue -Path (Join-Path $updaterProject '.ai-dev-system/PROJECT_CONTEXT.md')
    Assert-True ($contextHashBefore -eq $contextHashAfter) 'PROJECT_CONTEXT.md was modified by update.'
    $updateReport = $updateRun.Output | ConvertFrom-Json
    Assert-True ($updateReport.changes.preserved -contains 'PROJECT_CONTEXT.md') 'PROJECT_CONTEXT.md was not reported as preserved.'
    $passed.Add('updater project-context preservation')

    $dirtyTargetProject = Join-Path $testRoot 'installer-dirty'
    Write-FixtureFile -Path (Join-Path $dirtyTargetProject 'README.md') -Content "# Initial`n"
    Initialize-FixtureRepository -Path $dirtyTargetProject -Files @('README.md')
    Write-FixtureFile -Path (Join-Path $dirtyTargetProject 'README.md') -Content "# Uncommitted change`n"
    $dirtyInstall = Invoke-Tool -ScriptPath $installerRunner -Arguments @('-ProjectRoot', $dirtyTargetProject, '-Apply', '-OutputFormat', 'Json')
    Assert-True ($dirtyInstall.ExitCode -eq 2) 'Installer should block on dirty Git repository.'
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $dirtyTargetProject '.ai-dev-system'))) 'Dirty project install created state.'
    $passed.Add('installer dirty-tree safety blocking')

    $modifiedSystemProject = Join-Path $testRoot 'installer-modified'
    Write-FixtureFile -Path (Join-Path $modifiedSystemProject 'README.md') -Content "# Target`n"
    $null = Invoke-Tool -ScriptPath $installerRunner -Arguments @('-ProjectRoot', $modifiedSystemProject, '-Apply')
    $tamperedFile = Join-Path $modifiedSystemProject '.ai-dev-system/core/constitution/default.md'
    Write-FixtureFile -Path $tamperedFile -Content '# Tampered constitution'
    $tamperedUpdate = Invoke-Tool -ScriptPath $updaterRunner -Arguments @('-ProjectRoot', $modifiedSystemProject, '-Apply', '-OutputFormat', 'Json')
    Assert-True ($tamperedUpdate.ExitCode -eq 2) 'Updater without force should block on modified system file.'
    $tamperedReport = $tamperedUpdate.Output | ConvertFrom-Json
    Assert-True ($tamperedReport.result -eq 'BLOCKED') 'Tampered system file should report BLOCKED.'
    $forcedUpdate = Invoke-Tool -ScriptPath $updaterRunner -Arguments @('-ProjectRoot', $modifiedSystemProject, '-Apply', '-Force', '-OutputFormat', 'Json')
    Assert-True ($forcedUpdate.ExitCode -eq 0) 'Updater with -Force should succeed.'
    $passed.Add('updater modified-system-file detection and force override')

    $selfInstall = Invoke-Tool -ScriptPath $installerRunner -Arguments @('-ProjectRoot', $repositoryRoot, '-OutputFormat', 'Json')
    Assert-True ($selfInstall.ExitCode -ne 0) 'Installer should refuse self-installation into source repository.'
    $passed.Add('installer self-installation rejection')

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
