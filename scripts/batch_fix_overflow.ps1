# Batch fix overflow issues across all app files
# This script adds overflow handling to Text widgets that need it

param(
    [switch]$DryRun = $false,
    [switch]$Verbose = $false
)

Write-Host "🔧 Starting Comprehensive Overflow Fix..." -ForegroundColor Green
Write-Host ""

$totalFixed = 0
$filesModified = 0
$backupDir = "overflow_fix_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"

# Create backup directory
if (-not $DryRun) {
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    Write-Host "📁 Backup directory created: $backupDir" -ForegroundColor Yellow
    Write-Host ""
}

function Add-TextOverflow {
    param(
        [string]$FilePath,
        [string]$Content
    )
    
    $fixCount = 0
    $modified = $Content
    
    # Pattern 1: Text with only text content (no overflow)
    # Matches: Text('text') or Text("text") or Text(variable)
    $pattern1 = '(?<!overflow:\s)(?<!maxLines:\s)\bText\s*\(\s*([^,\)]+)\s*\)'
    $matches1 = [regex]::Matches($modified, $pattern1)
    
    foreach ($match in $matches1) {
        $fullMatch = $match.Value
        
        # Skip if already has overflow or maxLines
        if ($fullMatch -match 'overflow:' -or $fullMatch -match 'maxLines:') {
            continue
        }
        
        # Skip const Text with just simple string
        if ($fullMatch -match '^const\s+Text\s*\(\s*[''"]') {
            continue
        }
        
        # Skip very short static strings (< 10 chars)
        if ($fullMatch -match '^Text\s*\(\s*[''"](.{1,10})[''"]') {
            continue
        }
        
        $textContent = $match.Groups[1].Value
        $replacement = "Text($textContent, maxLines: 1, overflow: TextOverflow.ellipsis)"
        $modified = $modified.Replace($fullMatch, $replacement)
        $fixCount++
    }
    
    # Pattern 2: Text with style but no overflow
    # Matches: Text('text', style: TextStyle(...))
    $pattern2 = '(?<!overflow:\s)(?<!maxLines:\s)\bText\s*\(\s*([^,]+),\s*style:\s*([^,\)]+)\s*\)'
    $matches2 = [regex]::Matches($modified, $pattern2)
    
    foreach ($match in $matches2) {
        $fullMatch = $match.Value
        
        # Skip if already has overflow or maxLines
        if ($fullMatch -match 'overflow:' -or $fullMatch -match 'maxLines:') {
            continue
        }
        
        $textContent = $match.Groups[1].Value
        $styleContent = $match.Groups[2].Value
        $replacement = "Text($textContent, maxLines: 1, overflow: TextOverflow.ellipsis, style: $styleContent)"
        $modified = $modified.Replace($fullMatch, $replacement)
        $fixCount++
    }
    
    return @{
        Content = $modified
        FixCount = $fixCount
    }
}

# Get all Dart files
$dartFiles = Get-ChildItem -Path "lib" -Recurse -Filter "*.dart"

Write-Host "📊 Found $($dartFiles.Count) Dart files" -ForegroundColor Cyan
Write-Host ""

# Process files by category
$categories = @{
    "Buyer Screens" = "lib/features/buyer/screens"
    "Farmer Screens" = "lib/features/farmer/screens"
    "Auth Screens" = "lib/features/auth/screens"
    "Chat Screens" = "lib/features/chat/screens"
    "Admin Screens" = "lib/features/admin/screens"
    "Shared Widgets" = "lib/shared/widgets"
    "Other Files" = "lib"
}

foreach ($categoryName in $categories.Keys) {
    $categoryPath = $categories[$categoryName]
    $categoryFiles = $dartFiles | Where-Object { $_.FullName -like "*$categoryPath*" }
    
    if ($categoryFiles.Count -eq 0) {
        continue
    }
    
    Write-Host "📂 Processing $categoryName ($($categoryFiles.Count) files)..." -ForegroundColor Yellow
    
    foreach ($file in $categoryFiles) {
        $content = Get-Content -Path $file.FullName -Raw
        $result = Add-TextOverflow -FilePath $file.FullName -Content $content
        
        if ($result.FixCount -gt 0) {
            if ($DryRun) {
                Write-Host "  [DRY RUN] Would fix $($result.FixCount) Text widgets in $($file.Name)" -ForegroundColor Gray
            } else {
                # Backup original
                $backupPath = Join-Path $backupDir $file.Name
                Copy-Item -Path $file.FullName -Destination $backupPath -Force
                
                # Write fixed content
                Set-Content -Path $file.FullName -Value $result.Content -NoNewline
                Write-Host "  ✅ Fixed $($result.FixCount) Text widgets in $($file.Name)" -ForegroundColor Green
                $filesModified++
            }
            
            $totalFixed += $result.FixCount
            
            if ($Verbose) {
                Write-Host "     File: $($file.FullName)" -ForegroundColor DarkGray
            }
        }
    }
    
    Write-Host ""
}

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "📊 Summary:" -ForegroundColor Green
Write-Host "  Files modified: $filesModified" -ForegroundColor White
Write-Host "  Text widgets fixed: $totalFixed" -ForegroundColor White

if ($DryRun) {
    Write-Host ""
    Write-Host "ℹ️  This was a DRY RUN. No files were modified." -ForegroundColor Yellow
    Write-Host "   Run without -DryRun to apply changes." -ForegroundColor Yellow
} else {
    Write-Host "  Backup location: $backupDir" -ForegroundColor White
    Write-Host ""
    Write-Host "✨ Done! Run 'flutter analyze' to check for any issues." -ForegroundColor Green
}

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
