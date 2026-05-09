$ErrorActionPreference = "Stop"

Write-Host "Updating file contents..."
Get-ChildItem -Path . -File -Recurse | Where-Object { $_.FullName -notmatch '\.git\\' -and $_.FullName -notmatch 'refactor\.ps1' } | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    if ($content -match '(?i)spicetify') {
        $newContent = $content -creplace 'Spicetify', 'DT' -creplace 'spicetify', 'dt' -creplace 'SPICETIFY', 'DT' -ireplace 'spicetify', 'DT'
        Set-Content -Path $_.FullName -Value $newContent -NoNewline
    }
}
Write-Host "Done updating file contents."

Write-Host "Renaming files..."
Get-ChildItem -Path . -File -Recurse | Where-Object { $_.Name -match '(?i)spicetify' -and $_.FullName -notmatch '\.git\\' -and $_.FullName -notmatch 'refactor\.ps1' } | Rename-Item -NewName {
    $_.Name -creplace 'Spicetify', 'DT' -creplace 'spicetify', 'dt' -creplace 'SPICETIFY', 'DT' -ireplace 'spicetify', 'DT'
} -PassThru
Write-Host "Done renaming files."

Write-Host "Renaming directories..."
Get-ChildItem -Path . -Directory -Recurse | Where-Object { $_.Name -match '(?i)spicetify' -and $_.FullName -notmatch '\.git\\' } | Sort-Object -Property @{Expression={$_.FullName.Length}; Descending=$true} | Rename-Item -NewName {
    $_.Name -creplace 'Spicetify', 'DT' -creplace 'spicetify', 'dt' -creplace 'SPICETIFY', 'DT' -ireplace 'spicetify', 'DT'
} -PassThru
Write-Host "Done renaming directories."

Write-Host "Checking remaining instances..."
$remaining = (Get-ChildItem -Path . -File -Recurse | Where-Object { $_.FullName -notmatch '\.git\\' -and $_.FullName -notmatch 'refactor\.ps1' }).Where({(Get-Content $_.FullName -Raw) -match '(?i)spicetify'}).Count
Write-Host "Remaining instances in files: $remaining"
