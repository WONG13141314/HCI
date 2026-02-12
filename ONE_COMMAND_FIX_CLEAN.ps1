# ONE_COMMAND_FIX.ps1 - Windows PowerShell Version
# WildTrack AR - Fix google_fonts errors on Windows

Write-Host "WildTrack AR - One Command Fix for google_fonts (Windows)" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green
Write-Host ""

# Check if we're in the right directory
if (-Not (Test-Path "pubspec.yaml")) {
    Write-Host "ERROR: pubspec.yaml not found!" -ForegroundColor Red
    Write-Host "Please run this script from your wildtrack_ar project root directory." -ForegroundColor Yellow
    exit 1
}

Write-Host "Found project root. Starting fix..." -ForegroundColor Cyan
Write-Host ""

# Create backup
Write-Host "Creating backup..." -ForegroundColor Cyan
New-Item -ItemType Directory -Force -Path ".backup_before_fix" | Out-Null
Copy-Item "pubspec.yaml" ".backup_before_fix\" -ErrorAction SilentlyContinue
Copy-Item "lib\main.dart" ".backup_before_fix\" -ErrorAction SilentlyContinue
Copy-Item "lib\screens\splash_screen.dart" ".backup_before_fix\" -ErrorAction SilentlyContinue
Copy-Item "lib\screens\permission_screen.dart" ".backup_before_fix\" -ErrorAction SilentlyContinue
Copy-Item "lib\screens\ar_game_screen.dart" ".backup_before_fix\" -ErrorAction SilentlyContinue
Copy-Item "lib\widgets\species_modal.dart" ".backup_before_fix\" -ErrorAction SilentlyContinue
Copy-Item "lib\widgets\wildlife_sprite.dart" ".backup_before_fix\" -ErrorAction SilentlyContinue
Write-Host "Backup created in .backup_before_fix\" -ForegroundColor Green
Write-Host ""

# Fix pubspec.yaml
Write-Host "Fixing pubspec.yaml..." -ForegroundColor Cyan
$pubspecContent = Get-Content "pubspec.yaml" -Raw
$pubspecContent = $pubspecContent -replace "(?m)^\s*google_fonts:.*\r?\n", ""
$pubspecContent | Set-Content "pubspec.yaml" -NoNewline
Write-Host "Removed google_fonts from pubspec.yaml" -ForegroundColor Green
Write-Host ""

# Function to fix Dart files
function Fix-DartFile {
    param($FilePath)
    
    if (Test-Path $FilePath) {
        Write-Host "  Processing: $FilePath" -ForegroundColor Yellow
        
        $content = Get-Content $FilePath -Raw
        
        # Remove import statement
        $content = $content -replace "import 'package:google_fonts/google_fonts\.dart';\r?\n", ""
        
        # Replace GoogleFonts.poppins with TextStyle
        $content = $content -replace "GoogleFonts\.poppins\(", "TextStyle(fontFamily: 'Roboto', "
        
        # Fix const keyword issues
        $content = $content -replace "const TextStyle\(fontFamily: 'Roboto', ", "TextStyle(fontFamily: 'Roboto', "
        
        # Save the file
        $content | Set-Content $FilePath -NoNewline
        
        Write-Host "  Fixed: $FilePath" -ForegroundColor Green
    } else {
        Write-Host "  Skipped (not found): $FilePath" -ForegroundColor Yellow
    }
}

# Fix all Dart files
Write-Host "Fixing Dart files..." -ForegroundColor Cyan
Fix-DartFile "lib\main.dart"
Fix-DartFile "lib\screens\splash_screen.dart"
Fix-DartFile "lib\screens\permission_screen.dart"
Fix-DartFile "lib\screens\ar_game_screen.dart"
Fix-DartFile "lib\widgets\species_modal.dart"
Fix-DartFile "lib\widgets\wildlife_sprite.dart"

Write-Host ""
Write-Host "Cleaning project..." -ForegroundColor Cyan
flutter clean | Out-Null
if (Test-Path "pubspec.lock") { Remove-Item "pubspec.lock" }
if (Test-Path ".dart_tool") { Remove-Item ".dart_tool" -Recurse -Force }

Write-Host ""
Write-Host "Getting dependencies..." -ForegroundColor Cyan
flutter pub get

Write-Host ""
Write-Host "FIX COMPLETE!" -ForegroundColor Green
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Check that red errors are gone in VS Code" -ForegroundColor White
Write-Host "  2. Run: flutter run" -ForegroundColor White
Write-Host ""
Write-Host "If you see any remaining errors:" -ForegroundColor Yellow
Write-Host "  - Look for any remaining 'GoogleFonts' text" -ForegroundColor White
Write-Host "  - Replace manually with TextStyle" -ForegroundColor White
Write-Host ""
Write-Host "Backup location: .backup_before_fix\" -ForegroundColor Cyan
Write-Host ""
