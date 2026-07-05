Set-Location D:\CS_Ariel_Project
if (Test-Path "D:\CS_Ariel_Project\build25") {
    Write-Host "Deleting build25..." -ForegroundColor Yellow
    Remove-Item -Recurse -Force "D:\CS_Ariel_Project\build25"
    Write-Host "Deleted." -ForegroundColor Yellow
} else {
    Write-Host "build25 does not exist, skipping delete." -ForegroundColor Yellow
}
cmake --preset default -S D:\CS_Ariel_Project
cmake --build build25 --config Release 2>&1 | Select-String -Pattern "error|fatal|CMake" -CaseSensitive:$false
try {
    Copy-Item "D:\CS_Ariel_Project\build25\bin\AudioLabCM.mexw64" "D:\CS_Ariel_Project\MATLAB_Files\AudioLabCM.mexw64" -Force -ErrorAction Stop
    Write-Host "Done! MEX file copied." -ForegroundColor Green
} catch {
    Write-Host "ERROR: Failed to copy MEX file." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}
