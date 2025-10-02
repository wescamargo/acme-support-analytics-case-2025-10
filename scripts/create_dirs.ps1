# Creates repo folder structure with .gitkeep files
$dirs = @(
  "data","data/outputs",
  "models/staging","models/intermediate","models/marts",
  "analyses","reports","scripts","tests"
)
foreach ($d in $dirs) {
  New-Item -ItemType Directory -Force -Path $d | Out-Null
  New-Item -ItemType File -Force -Path (Join-Path $d ".gitkeep") | Out-Null
}
Write-Host "Folders created."
