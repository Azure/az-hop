# see https://github.com/Azure/azvmimagebuilder/blob/main/solutions/14_Building_Images_WVD/1_Optimize_OS_for_WVD.ps1
mkdir c:\optimize
cd c:\optimize
git clone https://github.com/The-Virtual-Desktop-Team/Virtual-Desktop-Optimization-Tool.git
cd Virtual-Desktop-Optimization-Tool

# Patch: overide the Windows_VDOT.ps1 - setting 'Set-NetAdapterAdvancedProperty'as it breaks the network connection
Write-Host 'Patch: Disabling Set-NetAdapterAdvancedProperty'
$updatePath= "C:\optimize\Virtual-Desktop-Optimization-Tool\Windows_VDOT.ps1"
((Get-Content -path $updatePath -Raw) -replace 'Set-NetAdapterAdvancedProperty -DisplayName "Send Buffer Size" -DisplayValue 4MB','#Set-NetAdapterAdvancedProperty -DisplayName "Send Buffer Size" -DisplayValue 4MB') | Set-Content -Path $updatePath

# Patch: override the REG UNLOAD, needs GC before, otherwise will Access Deny unload
[System.Collections.ArrayList]$file = Get-Content $updatePath
 $insert = @()
 for ($i=0; $i -lt $file.count; $i++) {
   if ($file[$i] -like "*& REG UNLOAD HKLM\DEFAULT*") {
     $insert += $i-1 
   }
 }

#add gc and sleep
$insert | ForEach-Object { $file.insert($_,"                 Write-Host 'Patch closing handles and runnng GC before reg unload' `n              `$newKey.Handle.close()` `n              [gc]::collect() `n                Start-Sleep -Seconds 15 ") }
Set-Content $updatePath $file 

.\Windows_VDOT.ps1 -Verbose -AcceptEULA
