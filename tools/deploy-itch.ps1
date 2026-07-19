<#
.SYNOPSIS
  Export the Sprout Valley web build and upload it to itch.io via butler.

.DESCRIPTION
  One command = export + upload:
    1. Headless-export the Godot "Web" preset to sprout-valley/build/web/.
    2. Push that folder to itch.io with butler (tools/butler/butler.exe,
       auto-downloaded if missing).

  Success of the export is judged by ARTIFACTS (index.html/.wasm/.pck), not the
  exit code — Godot headless web export on Windows has a history of crashing on
  shutdown AFTER writing a valid build (seen on 4.6; we keep the guard on 4.7).

  ONE-TIME SETUP (butler cannot do these for you):
    1. Create the game page: https://itch.io/game/new
       - Title: Sprout Valley (URL slug: sprout-valley)
       - Kind of project: HTML
       - Save as Draft is fine.
    2. Authenticate butler (either):
       - Interactive:  tools\butler\butler.exe login
       - Or set BUTLER_API_KEY (from https://itch.io/user/settings/api-keys).
    3. After the FIRST push, on the itch.io Edit Game page check
       "This file will be played in the browser" on the html5 channel.
  Every later deploy is just: ./tools/deploy-itch.ps1

.EXAMPLE
  ./tools/deploy-itch.ps1                     # export + push as <user>/sprout-valley:html5
  ./tools/deploy-itch.ps1 -SkipExport        # re-push the existing build
  ./tools/deploy-itch.ps1 -UserVersion 0.2.0 # tag the build with a version string
#>
[CmdletBinding()]
param(
  [string]$ItchUser,            # itch.io username; falls back to tools/itch-deploy.config.json
  [string]$Game = 'sprout-valley',
  [string]$Channel = 'html5',
  [string]$UserVersion,         # optional --userversion for butler
  [switch]$SkipExport
)
$ErrorActionPreference = 'Stop'
$root    = Split-Path -Parent $PSScriptRoot
$proj    = Join-Path $root 'sprout-valley'
$outDir  = Join-Path $proj 'build\web'
$butler  = Join-Path $PSScriptRoot 'butler\butler.exe'
$cfgFile = Join-Path $PSScriptRoot 'itch-deploy.config.json'
$godot   = 'C:\Program Files\Godot\godot.exe'

function Write-Note($m, $c = 'Cyan') { Write-Host "[deploy-itch] $m" -ForegroundColor $c }

# --- resolve itch user -------------------------------------------------------
if (-not $ItchUser -and (Test-Path $cfgFile)) {
  $cfg = Get-Content -Raw $cfgFile | ConvertFrom-Json
  $ItchUser = $cfg.user
  if ($cfg.game) { $Game = $cfg.game }
}
if (-not $ItchUser) {
  Write-Note "No itch.io username. Pass -ItchUser <name> or create $cfgFile with: { `"user`": `"<name>`" }" 'Red'
  exit 1
}
$target = "$ItchUser/${Game}:$Channel"

# --- butler bootstrap --------------------------------------------------------
if (-not (Test-Path $butler)) {
  Write-Note 'butler not found — downloading latest windows-amd64 build ...'
  $zip = Join-Path $env:TEMP 'butler-download.zip'
  curl.exe -L -o $zip 'https://broth.itch.zone/butler/windows-amd64/LATEST/archive/default' --silent --show-error
  New-Item -ItemType Directory -Force (Split-Path $butler -Parent) | Out-Null
  Expand-Archive $zip -DestinationPath (Split-Path $butler -Parent) -Force
  Remove-Item $zip -Force
}

# --- auth preflight ----------------------------------------------------------
$credsFile = Join-Path $env:USERPROFILE '.config\itch\butler_creds'
if (-not $env:BUTLER_API_KEY -and -not (Test-Path $credsFile)) {
  Write-Note "butler is not authenticated. Run:  $butler login" 'Red'
  Write-Note 'Or set BUTLER_API_KEY (https://itch.io/user/settings/api-keys).' 'Red'
  exit 1
}

# --- export ------------------------------------------------------------------
if ($SkipExport) {
  Write-Note 'SkipExport set — pushing the existing build.' 'Yellow'
} else {
  if (-not (Test-Path $godot)) { Write-Note "Godot not found at $godot" 'Red'; exit 1 }
  New-Item -ItemType Directory -Force $outDir | Out-Null
  Write-Note "exporting Web build -> $outDir"
  $log = & $godot --headless --path $proj --export-release 'Web' (Join-Path $outDir 'index.html') 2>&1
  $ok = (Test-Path (Join-Path $outDir 'index.html')) -and
        (Test-Path (Join-Path $outDir 'index.wasm')) -and
        (Test-Path (Join-Path $outDir 'index.pck'))
  if (-not $ok) {
    Write-Note 'export produced no usable build — check the Web preset / export templates:' 'Red'
    $log | Select-Object -Last 20 | Out-Host
    exit 1
  }
  Write-Note 'export OK (artifacts present; any shutdown crash ignored).' 'Green'
}
if (-not (Test-Path (Join-Path $outDir 'index.html'))) {
  Write-Note "no build at $outDir — run without -SkipExport first." 'Red'; exit 1
}

# --- push --------------------------------------------------------------------
Write-Note "pushing $outDir -> $target"
$pushArgs = @('push', $outDir, $target)
if ($UserVersion) { $pushArgs += @('--userversion', $UserVersion) }
& $butler @pushArgs
if ($LASTEXITCODE -ne 0) {
  Write-Note "butler push failed (exit $LASTEXITCODE)." 'Red'
  Write-Note "If the error says the game does not exist: create it once at https://itch.io/game/new (URL slug '$Game', kind: HTML), then re-run." 'Yellow'
  exit $LASTEXITCODE
}
Write-Note "pushed. Check status:  $butler status $target" 'Green'
Write-Note "First deploy only: on itch.io Edit Game, mark the '$Channel' file as 'played in the browser'." 'Yellow'
