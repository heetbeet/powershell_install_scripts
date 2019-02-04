<#  echo ""  >NUL  2>NUL
@echo off
cp -f "%~dpnx0" "%temp%\%~n0.ps1"
@"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass "%temp%\%~n0.ps1" %*
echo 10 seconds till exit... && ping 127.0.0.1 -n 10 > nul && exit /B 
::-------------------------------------- #>
#$scriptPath = split-path -parent $MyInvocation.MyCommand.Definitio

function DownloadFile($url, $targetFile){
   $uri = New-Object "System.Uri" "$url"
   $request = [System.Net.HttpWebRequest]::Create($uri)
   $request.set_Timeout(15000) #15 second timeout
   $response = $request.GetResponse()
   $totalLength = [System.Math]::Floor($response.get_ContentLength()/1024)
   $responseStream = $response.GetResponseStream()
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
   $targetStream.Flush()
   $targetStream.Close()
   $targetStream.Dispose()
   $responseStream.Dispose()
}

Write-Host 'Anaconda Installer Setup for tmp project!'
#Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
$downdir = "$env:HOMEPATH\Downloads"
$input_path = ‘c:\ps\emails.txt’
$output_file = ‘c:\ps\extracted_addresses.txt’
$regex = 'href\\s*=\\s*(?:\"(?<1>[^\"]*)\"|(?<1>\\S+))'
select-string -Path $input_path -Pattern $regex -AllMatches | % { $_.Matches } | % { $_.Value } > $output_file


$wc=new-object system.net.webclient
$wc.UseDefaultCredentials = $true
$wc.downloadfile("https://anaconda.org/anaconda/python/files", "$env:temp\anaconda_website.html")


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
#DownloadFile "$AnacondaUrl" "$AnacondaInstaller"
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