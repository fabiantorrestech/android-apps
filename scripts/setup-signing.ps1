<#
.SYNOPSIS
    Puts every Android signing key on this PC from the 1Password vault "Android Signing" (ADR 5).

.DESCRIPTION
    For each key in apps.json -> keys that has an item in the vault:
      - downloads the keystore to ~/.android-signing/<KEY>.keystore
      - checks its certificate SHA-256 against apps.json (refuses a mismatch)
    DEBUG_SHARED is also installed as ~/.android/debug.keystore (ADR 6). If that file already holds a
    different key, it is backed up next to it first, never deleted.
    Finally writes ~/.android-signing/signing.env: keystore paths plus op:// references for the
    passwords and aliases. It holds no secrets; publish-local.ps1 passes it to `op run`, which
    resolves the references only for the Gradle process.

    Vault item layout (one item per key, titled with the key id, e.g. PERSONAL):
      password  the keystore password (the key password must be the same)
      alias     text field, the key alias
      keystore  file field, the keystore itself

    Needs the 1Password CLI with desktop-app integration on (1Password -> Settings -> Developer).

.EXAMPLE
    pwsh scripts/setup-signing.ps1
#>
param(
    [string]$Vault = 'Android Signing'
)

$ErrorActionPreference = 'Stop'
$hubRoot = Split-Path $PSScriptRoot -Parent
$config = Get-Content (Join-Path $hubRoot 'apps.json') -Raw | ConvertFrom-Json
$signingDir = Join-Path $env:USERPROFILE '.android-signing'
$debugKeystore = Join-Path $env:USERPROFILE '.android/debug.keystore'

# Keys whose password and alias Gradle reads as <KEY>_KEYSTORE_FILE/_PASSWORD/_ALIAS (ADR 2).
# DEBUG_SHARED needs none: Gradle finds ~/.android/debug.keystore by itself.
$gradleKeys = @('PERSONAL', 'MYCALENDARWIDGET')

function Find-Keytool {
    $candidates = @(
        (Join-Path $env:ProgramFiles 'Android/Android Studio/jbr/bin/keytool.exe'),
        $(if ($env:JAVA_HOME) { Join-Path $env:JAVA_HOME 'bin/keytool.exe' })
    ) | Where-Object { $_ -and (Test-Path $_) }
    if (-not $candidates) { throw 'keytool not found (install Android Studio or set JAVA_HOME).' }
    return @($candidates)[0]
}

function Get-KeystoreSha256($keytool, $path, $password) {
    $output = & $keytool -list -v -keystore $path -storepass $password 2>&1
    $line = $output | Where-Object { $_ -match 'SHA256:\s*([0-9A-F:]+)' } | Select-Object -First 1
    if (-not $line) { throw "Could not read the certificate in $path (wrong password?)." }
    return ($Matches[1] -replace ':', '').ToLower()
}

if (-not (Get-Command op -ErrorAction SilentlyContinue)) { throw 'The 1Password CLI (op) is not on PATH: winget install AgileBits.1Password.CLI' }
$keytool = Find-Keytool
New-Item -ItemType Directory -Force $signingDir | Out-Null

$itemTitles = (op item list --vault $Vault --format json | ConvertFrom-Json).title
if ($LASTEXITCODE -ne 0) { throw "Can't list vault '$Vault'. Is 1Password unlocked with CLI integration on?" }

$envLines = @('# Written by android-apps/scripts/setup-signing.ps1. No secrets: op run resolves the op:// references.')
foreach ($keyId in $config.keys.PSObject.Properties.Name) {
    if ($itemTitles -notcontains $keyId) {
        Write-Output "-- $keyId`: no item in '$Vault', skipped"
        continue
    }
    $target = Join-Path $signingDir "$keyId.keystore"
    op read --force --out-file $target "op://$Vault/$keyId/keystore" | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Could not download the keystore of $keyId." }

    $password = op read "op://$Vault/$keyId/password"
    $actual = Get-KeystoreSha256 $keytool $target $password
    $expected = $config.keys.$keyId
    if ($actual -ne $expected) {
        Remove-Item $target
        throw "$keyId in 1Password has certificate $actual, but apps.json expects $expected."
    }
    Write-Output "ok $keyId -> $target"

    if ($keyId -eq 'DEBUG_SHARED') {
        if (Test-Path $debugKeystore) {
            $current = Get-KeystoreSha256 $keytool $debugKeystore 'android'
            if ($current -ne $expected) {
                $backup = "$debugKeystore.backup-$($current.Substring(0, 8))-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
                Copy-Item $debugKeystore $backup
                Write-Output "   backed up this PC's own debug key ($($current.Substring(0, 8))...) to $backup"
            }
        }
        New-Item -ItemType Directory -Force (Split-Path $debugKeystore) | Out-Null
        Copy-Item $target $debugKeystore -Force
        Write-Output "   installed as $debugKeystore"
    }

    if ($gradleKeys -contains $keyId) {
        $envLines += "ORG_GRADLE_PROJECT_${keyId}_KEYSTORE_FILE=$target"
        $envLines += "ORG_GRADLE_PROJECT_${keyId}_KEYSTORE_PASSWORD=op://$Vault/$keyId/password"
        $envLines += "ORG_GRADLE_PROJECT_${keyId}_KEYSTORE_ALIAS=op://$Vault/$keyId/alias"
    }
}

$envFile = Join-Path $signingDir 'signing.env'
Set-Content -Path $envFile -Value $envLines -Encoding utf8NoBOM
Write-Output "wrote $envFile"
