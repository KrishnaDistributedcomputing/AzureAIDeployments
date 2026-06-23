#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Populate VM and Azure file share with sample data for backup demonstration.
.DESCRIPTION
    Creates demo files on Windows VM (C:\DemoData\) and Azure file share (demo-share/reports/)
    to provide realistic backup targets with measurable data size.
.PARAMETER ResourceGroupName
    Resource group containing the VM and storage account.
.PARAMETER StorageAccountName
    Storage account name containing the file share.
.PARAMETER FileShareName
    Name of the file share to populate.
.EXAMPLE
    ./seed-demo-data.ps1 -ResourceGroupName rg-backup-demo-core -StorageAccountName stbackupdemo1234 -FileShareName demo-share
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory = $true)]
    [string]$StorageAccountName,
    
    [Parameter(Mandatory = $true)]
    [string]$FileShareName
)

function Write-Section { Write-Host "`n► $args " -ForegroundColor Cyan -BackgroundColor DarkBlue }
function Write-Success { Write-Host "✓ $args" -ForegroundColor Green }
function Write-Info { Write-Host "  → $args" -ForegroundColor White }

Write-Section "Seeding Demo Data for Azure Backup Pattern A"

# Step 1: Get VM and storage account details
Write-Info "Retrieving deployment details..."
$vm = az vm list --resource-group $ResourceGroupName --query "[0]" -o json | ConvertFrom-Json
$vmName = $vm.name
$vmId = $vm.id

Write-Success "Found VM: $vmName"

# Step 2: Populate VM with demo data via script extension
Write-Section "Step 1: Creating sample data on VM ($vmName)"
Write-Info "Uploading data creation script..."

$vmDataScript = @'
# Create demo directory
New-Item -ItemType Directory -Force -Path C:\DemoData | Out-Null

# Generate sample files (mix of small and large)
@(
    @{ Name = "Q2-Budget.txt"; Size = 500KB },
    @{ Name = "Employee-Records.csv"; Size = 2MB },
    @{ Name = "Financial-Report.xlsx"; Size = 5MB },
    @{ Name = "Project-Archive.zip"; Size = 15MB },
    @{ Name = "Database-Backup.bak"; Size = 50MB }
) | ForEach-Object {
    $path = "C:\DemoData\$($_.Name)"
    $size = $_.Size
    
    # Create file with random data
    $bytes = New-Object byte[] $size
    ([System.Random]::new()).NextBytes($bytes)
    [System.IO.File]::WriteAllBytes($path, $bytes)
    
    Write-Host "✓ Created: $($_.Name) ($([math]::Round($size/1MB,1)) MB)"
}

Write-Host "✓ Demo data seeded on VM"
'@

# Execute on VM using run command
Write-Info "Executing data creation script on VM..."
az vm run-command invoke --resource-group $ResourceGroupName --name $vmName `
    --command-id RunPowerShellScript `
    --scripts @('powershell -Command', $vmDataScript) `
    --no-wait

Write-Success "VM data seeding initiated"

# Step 3: Get storage account key
Write-Section "Step 2: Creating sample data in Azure file share"
Write-Info "Retrieving storage account credentials..."

$storageKey = az storage account keys list --resource-group $ResourceGroupName `
    --account-name $StorageAccountName --query "[0].value" -o tsv
$ctx = New-AzStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $storageKey

# Create file share directories and sample files
Write-Info "Creating file share structure..."
$fileShareShare = Get-AzStorageShare -Name $FileShareName -Context $ctx

# Create reports directory
New-AzStorageDirectory -Share $fileShareShare -Path "reports" -ErrorAction SilentlyContinue | Out-Null
Write-Info "Created directory: reports"

# Upload sample files
$sampleFiles = @(
    @{ Name = "Q1-Summary.pdf"; Content = "Quarterly report - Q1 performance metrics" },
    @{ Name = "Q2-Summary.pdf"; Content = "Quarterly report - Q2 performance metrics" },
    @{ Name = "Budget-2026.xlsx"; Content = "Annual budget forecast 2026" },
    @{ Name = "Audit-Log.csv"; Content = "System audit log entries" },
    @{ Name = "Meeting-Notes.docx"; Content = "Executive meeting notes - Confidential" }
)

$tempDir = $env:TEMP
foreach ($file in $sampleFiles) {
    $tempPath = Join-Path $tempDir $file.Name
    
    # Create sample file
    Set-Content -Path $tempPath -Value $file.Content -ErrorAction SilentlyContinue
    
    # Upload to file share
    Set-AzStorageFileContent -Share $fileShareShare -Source $tempPath -Path "reports/$($file.Name)" -Force | Out-Null
    Write-Info "Uploaded: $($file.Name)"
    
    Remove-Item $tempPath -Force -ErrorAction SilentlyContinue
}

Write-Success "File share seeded with sample data"

# Step 4: Summary
Write-Section "Seeding Complete"
Write-Info "VM local data: ~70 MB in C:\DemoData\"
Write-Info "File share data: ~50 KB across 5 files in demo-share/reports/"
Write-Info ""
Write-Host "Next step: ./scripts/trigger-backup.ps1" -ForegroundColor Yellow
