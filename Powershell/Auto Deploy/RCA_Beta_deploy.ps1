param(
    [string]$target,
    [string]$BinName = "RCA",
    [string]$Branch
    )
#Set-PSDebug -Trace 1
#$target = "C:\Builds\1\EGO Git\RCA Beta\bin"
#$BinName = "RCA"

$UserName = '[Username]'
$secPasswd = ConvertTo-SecureString -AsPlainText '[Password]' -Force
$Cred = New-Object System.Management.Automation.PSCredential ($UserName + "@[Domain]"),$secPasswd
$DateSuffix = get-date -Format yyyyMMdd.HHmm
$InstallDir = 'C:\Program Files\EDS\RCA.Net.2015'
$UNCDir = 'C$\Program Files\EDS\RCA.Net.2015'
$Computers = @('[List of Servers]')

Write-Host "Target: $target"
write-host "BinName: $BinName"
Write-Host "DateSuffix: $DateSuffix"

out-file -append "C:\Shares\Scripts\rca.$Branch.log" -inputobject "Target: $target"        
out-file -append "C:\Shares\Scripts\rca.$Branch.log" -inputobject "BinName: $BinName"      
out-file -append "C:\Shares\Scripts\rca.$Branch.log" -inputobject "DateSuffix: $DateSuffix"
#Get-ChildItem -Path "$target"           |out-file -append C:\Shares\Scripts\rca.beta.log

#C:\Shares\Scripts\iLMerge.exe /wildcards /out:RCA.Beta.Merge.exe $BinName EDS.*.dll Telerik*.dll PureComponents.*.dll ComponentFactory.*.dll

$MergeJob = Start-Job -ScriptBlock { 
    $BinName = $using:BinName
    $Branch = $using:Branch
    Set-Location $using:target
    C:\Shares\Scripts\iLMerge.exe /wildcards /out:"RCA.$Branch.Merge.exe" "$BinName.exe" EDS.*.dll Telerik*.dll PureComponents.*.dll 
    C:\Shares\Scripts\symstore.exe add /f "rca.$Branch.merge.pdb" /s '\\eds-tfs.edsdc.com\Symbols' /c "RCA $Branch Merge" /t "RCA $Branch Merge"
}

Invoke-Command -ComputerName $Computers -Credential $Cred -ScriptBlock {
    $DateSuffix = $using:DateSuffix
    $InstallDir = $using:InstallDir
    $Computers  = $using:Computers
    $Branch     = $using:Branch

    New-Item -ItemType directory -Path ("$InstallDir\$Branch.$DateSuffix")

    cmd /c mklink /J "$InstallDir\$Branch.$DateSuffix\bin" "$InstallDir"
    cmd /c mklink /J "$InstallDir\$Branch.$DateSuffix\License" "$InstallDir\License"

    new-item -ItemType directory -Name "TestDB" -Path "$InstallDir\$Branch.$DateSuffix"
    cmd /c mklink /J "$InstallDir\$Branch.$DateSuffix\TestDB\bin" "$InstallDir"
    cmd /c mklink /J "$InstallDir\$Branch.$DateSuffix\TestDB\Edits File" "$InstallDir\Edits File"
    cmd /c mklink /J "$InstallDir\$Branch.$DateSuffix\TestDB\License" "$InstallDir\License"

    New-Item -ItemType File -Path ("$InstallDir\$Branch.$DateSuffix\Log.txt")
    New-Item -ItemType File -Path ("$InstallDir\$Branch.$DateSuffix\TestDB\Log.txt")
    cacls "$InstallDir\$Branch.$DateSuffix\Log.txt" /e /p everyone:f
    cacls "$InstallDir\$Branch.$DateSuffix\TestDB\Log.txt" /e /p everyone:f
}

$MergeJob|Wait-Job
$MergeJob|Remove-Job

$Computers|ForEach-Object -Process {
    $Computer = $_
    $job = Start-Job -ScriptBlock { 
        $BinName = $using:BinName
        $Branch = $using:Branch
        New-PSDrive -Name "RCA" -scope Script -PSProvider FileSystem -Root "\\$using:Computer\$using:UNCDir\$Branch.$using:DateSuffix" -Credential $using:Cred
        Copy-Item -Path "$using:target\RCA.$Branch.Merge.exe"  -Destination "RCA:\$BinName.exe"
        Copy-Item -Path "$using:target\RCA.$Branch.Merge.pdb"  -Destination "RCA:\$BinName.pdb"
        Copy-Item -Path "$using:target\RCA.exe.config" -Destination "RCA:\$BinName.exe.config"
        Copy-Item -Path 'C:\Shares\Scripts\EDS.SQLManager.Overrides.xml' -Destination "RCA:\TestDB\EDS.SQLManager.Overrides.xml"
        Remove-PSDrive -Name "RCA"
    }
}

#$Computers|ForEach-Object -Process {
#    New-PSDrive -Name "RCA" -scope Script -PSProvider FileSystem -Root "\\$_\$UNCDir\Beta.$DateSuffix" -Credential $Cred
#    Copy-Item -Path "$target\RCA.Beta.Merge.exe" -Destination 'RCA:\RCA.Beta.exe'
#    Copy-Item -Path "$target\RCA.Beta.Merge.pdb" -Destination 'RCA:\RCA.Beta.pdb'
#    Copy-Item -Path "$target\RCA.Beta.exe.config" -Destination 'RCA:\RCA.Beta.exe.config'
#    Remove-PSDrive -Name "RCA"
#}

Get-Job|Wait-Job
get-job|Remove-Job

Invoke-Command -ComputerName $Computers -Credential $Cred -ScriptBlock {
    $DateSuffix = $using:DateSuffix
    $InstallDir = $using:InstallDir
    $BinName = $using:BinName
    $Branch = $using:Branch
    #Set-PSDebug -Trace 1

    cmd /c mklink /H "$InstallDir\$Branch.$DateSuffix\TestDB\$BinName.exe"        "$InstallDir\$Branch.$DateSuffix\$BinName.exe"        
    cmd /c mklink /H "$InstallDir\$Branch.$DateSuffix\TestDB\$BinName.pdb"        "$InstallDir\$Branch.$DateSuffix\$BinName.pdb"        
    cmd /c mklink /H "$InstallDir\$Branch.$DateSuffix\TestDB\$BinName.exe.config" "$InstallDir\$Branch.$DateSuffix\$BinName.exe.config" 

    xxmklink "`"$InstallDir\RCA.TestDB.$Branch.lnk`"" "`"$InstallDir\$Branch.$DateSuffix\TestDB\$BinName.exe`"" "`"`"" "`"$InstallDir\$Branch.$DateSuffix\TestDB\\`""
    cacls "$InstallDir\RCA.TestDB.$Branch.lnk" /e /p everyone:r

    xxmklink "`"$InstallDir\RCA.$Branch.lnk`"" "`"$InstallDir\$Branch.$DateSuffix\$BinName.exe`"" "`"`"" "`"$InstallDir\$Branch.$DateSuffix\\`""
    cacls "$InstallDir\RCA.$Branch.lnk" /e /p everyone:r

    xxmklink "`"$InstallDir\RCA.TRN.$Branch.lnk`"" "`"$InstallDir\$Branch.$DateSuffix\$BinName.exe`"" "`"TRN`"" "`"$InstallDir\$Branch.$DateSuffix\\`""
    cacls "$InstallDir\RCA.TRN.$Branch.lnk" /e /p everyone:r

    Get-ChildItem -Path "$InstallDir\$Branch.20*"|select -last 2
}
exit(0)