$SourcePath = 'E:\Path\'
$SQLUser = 'Username'
$SQLPassword = 'Password'
$SQLServer = 'Server'
$SQLDB = 'DB'

$Query = @"
Update top(1) CC
Set Location = '03'
output inserted.Location as NewLOC, inserted.DBID, Deleted.Location as OldLOC
from tabl as CC
where DBID = `$(ID)
"@

#Invoke-Sqlcmd -Query $Query -ServerInstance $SQLServer -Database $SQLDB -username $SQLUser -Password $SQLPassword -Variable $VarArray
$arr = @()
Get-ChildItem $SourcePath -Filter V000*.pdf | % {
    $varArray = @("ID = $($_.Name -ireplace 'V000(\d+)\.pdf','$1')")
    $tmp = Invoke-Sqlcmd -Query $Query -ServerInstance $SQLServer -Database $SQLDB -username $SQLUser -Password $SQLPassword -Variable $VarArray 
    $MyObject = New-Object PSObject -Property @{
        SQLDBID = $tmp.DBID
        SQLOldLOS = $tmp.OldLOC
        SQLNewLOS = $tmp.NewLOC
        FileName = $_.Name
        RunDate = Get-Date
        }
    $arr += $MyObject
    Move-Item -Destination "$SourcePath\..\$($_.Name -ireplace 'V000(\d+\.pdf)','$1')" -Path $_.FullName
}
$arr|Export-Csv -Append "$SourcePath\log.txt" -Encoding UTF8