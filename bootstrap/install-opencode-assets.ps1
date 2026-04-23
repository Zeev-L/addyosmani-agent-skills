param(
  [Parameter(Mandatory = $true, Position = 0)]
  [string]$RepoUrl,

  [Parameter(Position = 1)]
  [string]$Ref = "main",

  [string]$TargetDir = (Get-Location).Path,

  [switch]$Force,
  [switch]$DryRun
)

$ErrorActionPreference = "Stop"

function Get-RepoPath {
  param([string]$Url)
  $path = $Url -replace '^https?://github.com/', ''
  $path = $path -replace '\.git$', ''
  $path = $path.TrimEnd('/')
  return $path
}

function Copy-Tree {
  param(
    [string]$Source,
    [string]$Destination
  )

  if ($DryRun) {
    Write-Host "Would copy $Source -> $Destination"
    return
  }

  New-Item -ItemType Directory -Path $Destination -Force | Out-Null
  Copy-Item (Join-Path $Source '*') $Destination -Recurse -Force
}

$repoPath = Get-RepoPath -Url $RepoUrl
$archiveUrl = "https://codeload.github.com/$repoPath/zip/$Ref"

$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().ToString())
New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null

try {
  $archivePath = Join-Path $tempRoot 'archive.zip'
  Write-Host "Downloading $repoPath at ref $Ref"
  Invoke-WebRequest $archiveUrl -OutFile $archivePath
  Expand-Archive -Path $archivePath -DestinationPath $tempRoot -Force

  $extractedRoot = Get-ChildItem $tempRoot -Directory | Where-Object { $_.FullName -ne $tempRoot } | Select-Object -First 1
  if (-not $extractedRoot) {
    throw 'Failed to locate extracted repository contents.'
  }

  $sourceRoot = $extractedRoot.FullName
  if (-not (Test-Path (Join-Path $sourceRoot '.opencode'))) {
    throw 'Extracted repository does not contain .opencode\'
  }

  Set-Location $TargetDir

  $targets = @(
    '.opencode/commands',
    '.opencode/skills',
    '.opencode/agents',
    '.opencode/references'
  )

  foreach ($target in $targets) {
    if ((Test-Path $target) -and -not $Force) {
      throw "Target path exists: $target. Use -Force to overwrite."
    }
    if ((Test-Path $target) -and $Force -and -not $DryRun) {
      Remove-Item $target -Recurse -Force
    }
  }

  Copy-Tree -Source (Join-Path $sourceRoot '.opencode/commands') -Destination '.opencode/commands'
  Copy-Tree -Source (Join-Path $sourceRoot '.opencode/skills') -Destination '.opencode/skills'
  Copy-Tree -Source (Join-Path $sourceRoot '.opencode/agents') -Destination '.opencode/agents'
  Copy-Tree -Source (Join-Path $sourceRoot '.opencode/references') -Destination '.opencode/references'

  $manifest = [ordered]@{
    source = $RepoUrl
    ref = $Ref
    installedAt = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
    paths = @(
      '.opencode/commands',
      '.opencode/skills',
      '.opencode/agents',
      '.opencode/references'
    )
  } | ConvertTo-Json -Depth 3

  if ($DryRun) {
    Write-Host 'Would write .opencode-vendor.json'
  } else {
    Set-Content -Path '.opencode-vendor.json' -Value $manifest
  }

  Write-Host ''
  Write-Host "Installed shared OpenCode assets into $TargetDir"
  Write-Host 'Review your local AGENTS.md and merge any project-specific instructions manually.'
  Write-Host 'Re-run this script with -Force to refresh the vendored assets.'
}
finally {
  if (Test-Path $tempRoot) {
    Remove-Item $tempRoot -Recurse -Force
  }
}
