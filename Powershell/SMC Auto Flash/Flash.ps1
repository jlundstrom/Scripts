$port= new-Object System.IO.Ports.SerialPort COM1,9600,None,8,one
$port.Open()
do {
    $LastLine = $port.ReadLine()
    Write-Host "$LastLine"
} until ($LastLine -like "Boot Code version*")
start-sleep -s 1
$port.Write([char]27)

start-sleep -s 1
$port.Write([char]13)
$LastLine = $port.readexisting()
Write-Host "$LastLine"

Write-Host "Opening Config"
$port.Write("c")
$port.Write([char]13)

do {
    $LastLine = $port.readexisting()
    Write-Host "$LastLine" -NoNewline
    if ($LastLine -like "*file name*" ) {
        $port.writeLine("/fl/zz-img")
    }elseif ( $LastLine -like "*inet on ethernet*") {
        $port.writeLine("192.168.1.20:0xffffff00")
    }elseif ( $LastLine -like "*host inet*") {
        $port.writeLine("192.168.1.123")
    }elseif ( $LastLine -like "*flags*") {
        $port.writeLine("0x0")
    }else{
        $port.Write([char]13)
    }
    start-sleep -Milliseconds 300
} until ($LastLine -like "*other*")

start-sleep -s 1
$port.WriteLine('@')
do {
    $LastLine = $port.readexisting()
    Write-Host "$LastLine" -NoNewline
    start-sleep -Milliseconds 300
} until ($LastLine -like "*Boot web up*")

start-sleep -Seconds 2
Write-Host "Reformating..."
$Output = .\curl.exe "http://192.168.1.20/upgrade_firm" -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8" -H "Referer: http://192.168.1.20/" -H "Origin: http://192.168.1.20" -H "User-Agent: Mozilla/5.0 (Windows NT 6.3; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/42.0.2311.135 Safari/537.36" -H "Content-Type: application/x-www-form-urlencoded" --data "szDownloadMethod=1&szFwFileName=&szFwIpAddress=&szFwUsername=&szFwPassword=&FORMAT=Format" --compressed 2>&1
if ($Output -like "*Format TFFS file system successful*") 
{
    Write-Host "PASS Format"
    Write-Host "Sending Firmware..."
    $Output = .\curl.exe "http://192.168.1.20/upgrade_firm" -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8" -H "Referer: http://192.168.1.20/" -H "Origin: http://192.168.1.20" -H "User-Agent: Mozilla/5.0 (Windows NT 6.3; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/42.0.2311.135 Safari/537.36" -H "Content-Type: application/x-www-form-urlencoded" --data "szDownloadMethod=1&szFwFileName=zz-img.bin&szFwIpAddress=192.168.1.123&szFwUsername=&szFwPassword=&UPGRADE=Start+Upgrade" --compressed 2>&1
    if ($Output -like "*Updating firmware is successful*") 
    {
        Write-Host "PASS Format"
        .\curl.exe "http://192.168.1.20/upgrade_firm" -H "Origin: http://192.168.1.20" -H "Accept-Encoding: gzip, deflate" -H "Accept-Language: en-US,en;q=0.8,sv;q=0.6" -H "User-Agent: Mozilla/5.0 (Windows NT 6.3; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/42.0.2311.135 Safari/537.36" -H "Content-Type: application/x-www-form-urlencoded" -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8" -H "Cache-Control: max-age=0" -H "Referer: http://192.168.1.20/" -H "Connection: keep-alive" -H "DNT: 1" --data "szDownloadMethod=1&szFwFileName=zz-img.bin&szFwIpAddress=192.168.1.123&szFwUsername=&szFwPassword=&RESET=Reset" --compressed -m 1 2>&1 | out-null
        do {
            $LastLine = $port.ReadLine()
            Write-Host "$LastLine"
        } until ($LastLine -like "Boot Code version*")
        start-sleep -s 1
        $port.Write([char]27)

        start-sleep -s 1
        $port.Write([char]13)
        $LastLine = $port.readexisting()
        Write-Host "$LastLine"

        Write-Host "Opening Config"
        $port.Write("c")
        $port.Write([char]13)

        do {
            $LastLine = $port.readexisting()
            Write-Host "$LastLine" -NoNewline
            if ($LastLine -like "*file name*" ) {
                $port.writeLine("/fl/zz-img.bin")
            }else{
                $port.Write([char]13)
            }
            start-sleep -Milliseconds 300
        } until ($LastLine -like "*other*")

        start-sleep -s 1
        $port.WriteLine('@')
        Write-Host "DONE"
    }
}else{
    Write-Host "Failed to Format"
}

$port.Close()