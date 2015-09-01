Write-Host 'Generating Config'

$File = (Get-ChildItem -Recurse -File|? {$_.Name -like "*.bat"}|select -Last 1)
$Title = $File.name -replace ".bat",""
$DirPath = $File.Directory.FullName

';!@Install@!UTF-8!'|Out-File 'config' -Encoding utf8
("Title=""$Title""")|out-file 'config' -Append -Encoding utf8
("BeginPrompt=""Do you want to run $Title?""")|out-file 'config' -Append -Encoding utf8
("ExecuteFile=""$Title.bat""")|out-file 'config' -Append -Encoding utf8
';!@InstallEnd@!'|Out-File 'config' -Append -Encoding utf8

Write-Host "Generating Archive"
.\7zr.exe a -t7z """$Title.7z""" """$DirPath\*""" -m0=BCJ2 -m1=LZMA:d25:fb255 -m2=LZMA:d19 -m3=LZMA:d19 -mb0:1 -mb0s1:2 -mb0s2:3 -mx
Write-Host "Generating SFX"
cmd /c copy /b  "7zS.sfx" + "config" + """$Title.7z""" """.\Output\$Title.exe"""
Write-Host "Cleaning up"
Get-ChildItem -File "$Title.7z" |Remove-Item
Get-ChildItem -File 'config' |Remove-Item