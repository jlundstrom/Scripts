$folder = 'E:\Work\Temp\'
$SitesFilter = '*' #'local.*'

$Sites = get-childitem -Path $folder -Directory -Filter $SitesFilter


$Sites | % {
    TakeOwn /F "$($_.FullName)"
    TakeOwn /F "$($_.FullName)\*"

    icacls "$($_.FullName)" /grant:r USER`':(F) /T /C /Q
    icacls "$($_.FullName)" /grant:r everyone:(RX) /T /C /Q
    icacls "$($_.FullName)\*" /grant:r USER`':(F) /T /C /Q
    icacls "$($_.FullName)\*" /grant:r everyone:(RX) /T /C /Q
}
