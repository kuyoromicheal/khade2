# One-command Khade launch setup (Windows)
# Run from repo root:  .\launch-setup.ps1

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot
Set-Location backend
npm run launch:setup
