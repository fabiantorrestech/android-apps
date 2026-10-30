<#
.SYNOPSIS
    Builds signed release APKs on this PC and publishes them to the app hub's releases.

.DESCRIPTION
    For each app in apps.json that has a "local" entry: checks its clone (next to this repo) is clean, on the
    expected branch and pushed; runs the Gradle release task with a JDK 21; checks the APK is signed with the
    expected key (so it installs over the copy on the phone); then uploads it to the app's rolling release in
    the hub repo, replacing the previous APK. Signing passwords come from ~/.gradle/gradle.properties.
    Needs gh auth login and the Android SDK build-tools.

.EXAMPLE
    pwsh scripts/publish-local.ps1 -All
    pwsh scripts/publish-local.ps1 -App sleepyguy,grayscalerplus     # no spaces: pwsh -File drops the rest
    pwsh scripts/publish-local.ps1 -App mycalendarwidget -NoUpload     # build and check only
#>
param(
    [string[]]$App,
    [switch]$All,
    [switch]$NoUpload,
    [switch]$AllowDirty
)

$ErrorActionPreference = 'Stop'
$hubRoot = Split-Path $PSScriptRoot -Parent
$reposRoot = Split-Path $hubRoot -Parent
$config = Get-Content (Join-Path $hubRoot 'apps.json') -Raw | ConvertFrom-Json

function Find-Jdk21 {
    $candidates = Get-ChildItem (Join-Path $env:USERPROFILE '.gradle/jdks') -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match '21' -and (Test-Path (Join-Path $_.FullName 'bin/java.exe')) }
    if (-not $candidates) { throw 'No JDK 21 found in ~/.gradle/jdks (Gradle 8.x cannot run on the JDK 25 bundled with Android Studio).' }
    return ($candidates | Select-Object -First 1).FullName
}

function Find-BuildTools {
    $root = Join-Path $env:LOCALAPPDATA 'Android/Sdk/build-tools'
    $latest = Get-ChildItem $root -Directory | Sort-Object { [version]$_.Name } | Select-Object -Last 1
    if (-not $latest) { throw "No Android build-tools in $root." }
    return $latest.FullName
}

function Assert-RepoReady($dir, $branch) {
    $current = git -C $dir branch --show-current
    if ($current -ne $branch) { throw "$dir is on '$current', expected '$branch'." }
    if ($AllowDirty) { return }
    if (git -C $dir status --porcelain) { throw "$dir has uncommitted changes (use -AllowDirty to build anyway)." }
    git -C $dir fetch --quiet origin $branch
    $unpushed = git -C $dir rev-list --count "origin/$branch..HEAD"
    $behind = git -C $dir rev-list --count "HEAD..origin/$branch"
    if ($unpushed -ne '0' -or $behind -ne '0') { throw "$dir is $unpushed ahead / $behind behind origin/${branch}: push or pull first." }
}

function Get-SignerSha256($apksigner, $apk) {
    $output = & $apksigner verify --print-certs $apk 2>&1
    $line = $output | Where-Object { $_ -match 'Signer #1 certificate SHA-256 digest: ([0-9a-f]+)' } | Select-Object -First 1
    if (-not $line) { throw "APK is not signed or failed verification: $apk`n$output" }
    return $Matches[1]
}

function Get-ApkVersion($aapt2, $apk) {
    $badging = (& $aapt2 dump badging $apk | Select-Object -First 1)
    if ($badging -notmatch "versionCode='(\d+)' versionName='([^']*)'") { throw "No version found in $apk." }
    return @{ Code = $Matches[1]; Name = $Matches[2] }
}

function Publish-Apks($entry, [string[]]$apkPaths, $version, $sha) {
    $repo = $config.hubRepo
    $title = "$($entry.name) $($version.Name) ($($version.Code))"
    $notes = "Built on the PC from $($entry.sourceRepo)@$sha ($($entry.local.branch)) on $(Get-Date -Format 'yyyy-MM-dd HH:mm')."

    gh release view $entry.tag --repo $repo --json tagName 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        gh release upload $entry.tag @apkPaths --repo $repo --clobber
        gh release edit $entry.tag --repo $repo --title $title --notes $notes | Out-Null
    } else {
        gh release create $entry.tag @apkPaths --repo $repo --target main --title $title --notes $notes --latest=false | Out-Null
    }
    if ($LASTEXITCODE -ne 0) { throw "Upload of $($entry.name) failed." }
}

# An app builds one APK (local.task / output / apk) or several (local.apks: [{task, output, apk}],
# e.g. a phone and a watch app published on the same release).
function Get-ApkSpecs($entry) {
    if ($entry.local.apks) { return @($entry.local.apks) }
    return @([pscustomobject]@{ task = $entry.local.task; output = $entry.local.output; apk = $entry.local.apk })
}

# pwsh -File passes "-App a,b" as one string, so split and trim.
$requested = $App | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim() } | Where-Object { $_ }
$selected = $config.apps | Where-Object { $_.local -and ($All -or $requested -contains $_.id) }
if (-not $selected) { throw "Nothing to build. Use -All or -App with one of: $(($config.apps | Where-Object local).id -join ', ')." }

$env:JAVA_HOME = Find-Jdk21
# Clones never opened in Android Studio have no local.properties, so point Gradle at the SDK.
if (-not $env:ANDROID_HOME) { $env:ANDROID_HOME = Join-Path $env:LOCALAPPDATA 'Android/Sdk' }
$buildTools = Find-BuildTools
$apksigner = Join-Path $buildTools 'apksigner.bat'
$aapt2 = Join-Path $buildTools 'aapt2.exe'
$staging = Join-Path ([IO.Path]::GetTempPath()) 'android-apps-publish'
New-Item -ItemType Directory -Force $staging | Out-Null

foreach ($entry in $selected) {
    Write-Output "== $($entry.name)"
    $dir = Join-Path $reposRoot $entry.local.dir
    Assert-RepoReady $dir $entry.local.branch

    $specs = Get-ApkSpecs $entry
    $tasks = @($specs | ForEach-Object { $_.task } | Select-Object -Unique)
    Push-Location $dir
    try {
        & .\gradlew.bat @tasks --console=plain --quiet
        if ($LASTEXITCODE -ne 0) { throw "Gradle build failed for $($entry.name)." }
    } finally { Pop-Location }

    $expectedKey = $config.keys.($entry.key)
    $apkPaths = @()
    $version = $null
    foreach ($spec in $specs) {
        $built = Get-ChildItem (Join-Path $dir $spec.output) -Filter *.apk | Sort-Object LastWriteTime | Select-Object -Last 1
        if (-not $built) { throw "No APK in $($spec.output)." }

        $actualKey = Get-SignerSha256 $apksigner $built.FullName
        if ($actualKey -ne $expectedKey) { throw "$($spec.apk) is signed with $actualKey, expected the $($entry.key) key $expectedKey. Check ~/.gradle/gradle.properties." }

        $apkVersion = Get-ApkVersion $aapt2 $built.FullName
        if (-not $version) { $version = $apkVersion }
        $apkPath = Join-Path $staging $spec.apk
        Copy-Item $built.FullName $apkPath -Force
        $apkPaths += $apkPath
        Write-Output "   $($spec.apk): $($apkVersion.Name) ($($apkVersion.Code)), $($entry.key) key OK -> $apkPath"
    }

    if (-not $NoUpload) {
        $sha = git -C $dir rev-parse --short HEAD
        Publish-Apks $entry $apkPaths $version $sha
        Write-Output "   published to $($config.hubRepo) release '$($entry.tag)'"
    }
}
