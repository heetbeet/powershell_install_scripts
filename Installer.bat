<#  echo ""  >NUL  2>NUL
@echo off
cp -f "%~dpnx0" "%temp%\%~n0.ps1"
@"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass "%temp%\%~n0.ps1" %*
echo 10 seconds till exit... && ping 127.0.0.1 -n 10 > nul && exit /B 
::-------------------------------------- #>

function Unzip-File($zipfile, $outdir){
    $shell = New-Object -COM Shell.Application;
    $target = $shell.NameSpace($outdir)
    New-Item $outdir -ItemType Directory -ea silentlycontinue
    $zip = $shell.NameSpace($zipfile)
    $target.CopyHere($zip.Items(), 16);
}

function Get-LatestWget(){
    $url = "https://eternallybored.org/misc/wget/"
    $r = (New-Object System.Net.WebClient).DownloadString($url)

    $href = '<a\s+(?:[^>]*?\s+)?href="([^"]*)"'
    $filt = $r    | select-string -Pattern $href -AllMatches | %{$_.Matches} | %{$_.groups[1].Value} | out-string
    $filt = $filt | select-string -Pattern '.*wget.*win32.*zip' -AllMatches | %{$_.Matches} | %{$_.groups[0].Value} | Out-String
    
    
    $filtarr = $filt -split '\r?\n' | %{
        if($_ -notlike '*/old/*'){
            $wgetName = ([uri]"$url$_").segments[-1] #-replace ".zip", ""
            $wgetDir = "$env:userprofile\Downloads\" + ($wgetName -replace ".zip", "")
            New-Item $wgetDir -ItemType Directory  -ea silentlycontinue
            $wgetPath = "$wgetDir\$wgetName"
            (New-Object System.Net.WebClient).DownloadFile("$url$_", "$wgetPath")
            Unzip-File $wgetPath $wgetDir
            break
        }
    }
}

function Test-Wget(){
    $wgetExe = (Get-ChildItem -Path "$env:userprofile\Downloads\wget*win32\wget.exe").FullName
    if([string]::IsNullOrEmpty($wgetExe)){
        return $false
    }
    return $true
}

function Download-FileWget($url, $targetFile){
    $wgetDir = (Get-ChildItem -Path "$env:userprofile\Downloads\wget*win32").FullName
    if($env:Path -notlike "*$wgetDir*"){
        $env:Path = "$wgetDir;$env:Path"
    }
    Invoke-Expression "wget '$url' -O '$targetFile'"
}

function Download-File {
    param([string]$url, [string]$targetFile)

    $uri = New-Object "System.Uri" "$url"
    $request = [System.Net.HttpWebRequest]::Create($uri)
    $request.set_Timeout(15000) #15 second timeout
    $response = $request.GetResponse()
    $totalLength = [System.Math]::Floor($response.get_ContentLength()/1024)
    try {
        $responseStream = $response.GetResponseStream()
        try {
            $targetStream = New-Object -TypeName System.IO.FileStream -ArgumentList $targetFile, Create
            $buffer = new-object byte[] 10KB
            $count = $responseStream.Read($buffer,0,$buffer.length)
            $downloadedBytes = $count

            while ($count -gt 0){
                $targetStream.Write($buffer, 0, $count)
                $count = $responseStream.Read($buffer,0,$buffer.length)
                $downloadedBytes = $downloadedBytes + $count
                Write-Progress -activity "Downloading file '$($url.split('/') | Select -Last 1)'" -status "Downloaded ($([System.Math]::Floor($downloadedBytes/1024))K of $($totalLength)K): " -PercentComplete ((([System.Math]::Floor($downloadedBytes/1024)) / $totalLength)  * 100)

            }
            Write-Progress -activity "Finished downloading file '$($url.split('/') | Select -Last 1)'"
        }
        catch {
            throw
        }
        finally {
            if($targetStream){
                $targetStream.Flush()
                $targetStream.Close()
                $targetStream.Dispose()
            }
        }
    }
    catch {
        throw
    }
    finally {
        $responseStream.Dispose()
    }
}

function Download-FileRobust($url, $targetFile){
    try{
        Download-File $url $targetFile -ev err -ea stop
    }
    catch{
        try{
        
            $wc=new-object system.net.webclient;
            $wc.UseDefaultCredentials = $true;
            $wc.DownloadFile("$url", "$targetfile");
            
        }catch{        
        
            write-host "Windows couldn't download file, trying wget..."
            if(Test-Wget){}else{
                Get-LatestWget
            }
            Download-FileWget $url $targetFile
        }
    }
}
Download-FileRobust "https://anaconda.org/anaconda/python/files" "$env:USERPROFILE\Downloads\temp643426.txt"

$PSVersionTable.PSVersion

Write-Host 'Anaconda Installer Setup for tmp project!'
$downdir = "$env:HOMEPATH\Downloads"


$wc=new-object system.net.webclient
$wc.UseDefaultCredentials = $true
$wc.Download-File("https://anaconda.org/anaconda/python/files", "$env:temp\anaconda_website.html")
$output_file = "$env:temp\hrefs.html"
$regex = 'href\s*=\s*(?:"(?<1>[^"]*)"|(?<1>\S+))'
select-string -Path "$env:temp\anaconda_website.html" -Pattern $regex -AllMatches | %{$_.Matches} | %{$_.groups[1].Captures} | %{$_.Value} > $output_file

$request = [System.Net.WebRequest]::Create("https://anaconda.org/anaconda/python/files")
$request.Method = "GET"
[System.Net.WebResponse]$response = $request.GetResponse()


#$downdir = "C:\download_routine\"
if ((gwmi win32_operatingsystem | select osarchitecture).osarchitecture -eq "64-bit"){
    Write-Host "Download 64 bit version of Miniconda"
    $AnacondaUrl = "https://repo.anaconda.com/miniconda/Miniconda3-latest-Windows-x86_64.exe"
    $AnacondaInstaller = "$downdir\Miniconda3-latest-Windows-x86_64.exe"
}
else{
	Write-Host "Download 32 bit version of Miniconda"
    $AnacondaUrl = "https://repo.anaconda.com/miniconda/Miniconda3-latest-Windows-x86.exe"
    $AnacondaInstaller = "$downdir\Miniconda3-latest-Windows-x86.exe"
}

Write-Host "-----------------------------------------------"
Write-Host "1) Download Miniconda to $AnacondaInstaller"
#Download-File "$AnacondaUrl" "$AnacondaInstaller"
Write-Host "-----------------------------------------------"

Write-Host "-----------------------------------------------"
Write-Host "2) Install Miniconda. Please use defaults parameters:"
#Start-Process -wait $AnacondaInstaller
Write-Host "-----------------------------------------------"

Write-Host "-----------------------------------------------"
Write-Host "3) Install Python packages:"
#All defaut hiding places for anaconda
#$env:Path = "C:\download_routine\Miniconda3;$env:UserProfile\Miniconda3;$env:ProgramData\Miniconda3;$env:UserProfile\Anaconda3;$env:ProgramData\Anaconda3;$env:Path"
#Invoke-Expression "python -m conda install -y numpy"
#Invoke-Expression "python -m conda install -y scipy"
#Invoke-Expression "python -m conda install -y matplotlib"
#Invoke-Expression "python -m conda install -y jupyter"
#Invoke-Expression "python -m conda install -c conda-forge -y gitpython"

Write-Host "-----------------------------------------------"
#>

<#
get-Alias ev
#>