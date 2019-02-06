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


function  get-hrefs($inputStr){
    $href = '<a\s+(?:[^>]*?\s+)?href="([^"]*)"'
    return $inputStr | select-string -Pattern $href -AllMatches | %{$_.Matches} | %{$_.groups[1].Value}
}


function Get-LatestWget(){
    $url = "https://eternallybored.org/misc/wget/"
    $r = (New-Object System.Net.WebClient).DownloadString($url)

    $filt = get-hrefs $r  | out-string
    $filt = $filt | select-string -Pattern '.*wget.*win32.*zip' -AllMatches | %{$_.Matches} | %{$_.groups[0].Value} | Out-String
    
    
    $filtarr = $filt -split '\r?\n' | %{
        if($_ -notlike '*/old/*'){
            $wgetName = ([uri]"$url$_").segments[-1] #-replace ".zip", ""
            $wgetDir = "$env:userprofile\Downloads\" + ($wgetName -replace ".zip", "")
            New-Item $wgetDir -ItemType Directory  -ea silentlycontinue
            $wgetPath = "$wgetDir\$wgetName"
            Write-Host "Download $url$_ as $wgetPath"
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

function Test-ValidUrl($url){
    #https://stackoverflow.com/questions/161738/what-is-the-best-regular-expression-to-check-if-a-string-is-a-valid-url
    $url -match '(http[s]?|[s]?ftp[s]?)(:\/\/)([^\s,]+)'
}

function Fetch-UrlContent($url){
    $fileName = "$env:temp\"+([uri]"$url").segments[-1]
    $fileName = $fileName -replace "/", ""
    $fileName = $fileName +".temp"
    Write-Host $fileName 
    Download-FileRobust $url $fileName
    Get-Content -Path $fileName    
}

function Fetch-Links($url){
    $dump = Fetch-UrlContent $url 
    $hrefs = get-hrefs $dump
    $hrefs | %{if(Test-ValidUrl $_){$_}else{"$url$_"}}
}

function Fetch-LinksBare($url){
    $dump = Fetch-UrlContent $url 
    get-hrefs $dump
}

function get-FullUrl($url, $path){
    if(Test-ValidUrl $path){
        $path
    }else{
        "$url/$path"
    }
}

function Download-LatestPythonZip(){
    $pyurl = "https://www.python.org/downloads/windows/"
    $pywinhtml = Fetch-UrlContent $pyurl
    $dlpagelink = $pywinhtml -split "`n" | %{if($_ -like "*Latest*Python*3*"){get-FullUrl $pyurl (get-hrefs $_)}}
    $link =get-hrefs (Fetch-UrlContent $dlpagelink) | %{if($_ -like "*embed*64*zip" ){$_}}
    
    $pyName = ([uri]"$link").segments[-1]
    $pyDir = "$env:userprofile\Applications\UntitledApp\" + ($pyName -replace ".zip", "")
    New-Item $pyDir -ItemType Directory -ea silentlycontinue
    $pyPath = "$pyDir\$pyName"
    Write-Host "Download $link as $pyPath"
    
    #Download-FileRobust "$link" "$pyPath"
    #Unzip-File $pyPath $pyDir
    
    New-Item "$pyDir\Lib" -ItemType Directory -ea silentlycontinue
    #Unzip-File (Get-ChildItem -Path "$pyDir/python3*.zip").FullName "$pyDir\Lib"
    
    
    #"https://github.com/heetbeet/powershell_install_scripts/blob/master/anaconda_dlls_64bit/api-ms-win-crt-utility-l1-1-0.dll?raw=true"
    $githubdlls = Fetch-LinksBare "https://github.com/heetbeet/powershell_install_scripts/tree/master/anaconda_dlls_64bit" | %{if($_ -like "*.dll"){$_}}
    $githubdlls | %{
        $dllname = (([uri]"https://github.com/$_").segments[-1])
        
        Get-ChildItem -Path "$pyDir\$dllname" -ev err -ea silentlycontinue | out-null
        if($err.count -gt 0){  #if not packaged with python
            Download-FileRobust "https://github.com/$_`?raw=true" "$pyDir\$dllname"
        }
    }       
}


Download-LatestPythonZip



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