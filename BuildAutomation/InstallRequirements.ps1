$ErrorActionPreference = "Stop"

$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
. "$scriptPath\BuildUtils.ps1"

iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))

ChocolateyInstall git.install
ChocolateyInstall ActivePerl
ChocolateyInstall 7zip

# Following packages either are not available / updated in Chocolatey or their Chocolatey packages have issues
DownloadInstall 'http://www.cmake.org/files/v2.8/cmake-2.8.12.2-win32-x86.exe' "exe" "/S"
DownloadInstall "https://sourceforge.net/projects/boost/files/boost-binaries/1.61.0/boost_1_61_0-msvc-12.0-64.exe/download" "exe" "/VERYSILENT /SUPPRESSMSGBOXES"
DownloadInstall 'http://download.microsoft.com/download/7/2/E/72E0F986-D247-4289-B9DC-C4FB07374894/wdexpress_full.exe' "exe" "/S /Q /Full"
DownloadInstall 'http://download.microsoft.com/download/8/2/6/826E264A-729E-414A-9E67-729923083310/VSU1/VS2013.1.exe' "exe" "/S /Q /Full"
# Note: nasm installs in a user location when executed withoud admin rights
DownloadInstall "http://www.nasm.us/pub/nasm/releasebuilds/2.11.02/win32/nasm-2.11.02-installer.exe" "exe" "/S"

# Install WiX after Visual Studio for integration
ChocolateyInstall wixtoolset

$ENV:PATH += ";${ENV:ProgramFiles}\Git\bin"
$ENV:PATH += ";${ENV:ProgramFiles(x86)}\Git\bin"

&git config --global user.name "Automated Build"
if ($LastExitCode) { throw "git config failed" }
&git config --global user.email "build@cloudbase"
if ($LastExitCode) { throw "git config failed" }

$toolsdir = "C:\Tools"
CheckDir $toolsdir

# TODO: Release AlexFTP 1.1.1 and replace the following beta
$path = "$ENV:TEMP\AlexFTPSBeta.zip" 
DownloadFile "https://www.cloudbase.it/downloads/AlexFTPSBeta.zip" $path
$ENV:PATH += ";$ENV:ProgramFiles\7-Zip"
Expand7z $path $toolsdir
del $path
Move "$toolsdir\Release" "$toolsdir\AlexFTPS-1.1.0"

$pfxPassword = "changeme"
$thumbprint = ImportCertificateUser "$ENV:USERPROFILE\Cloudbase_authenticode.p12" $pfxPassword
# TODO: write thumbrint to file and load it in teh build script(s) in place of the hardcoded value

# pypi mirror configuration
CheckDir "$ENV:USERPROFILE\pip"
$pipIni = @"
[global]
index-url = https://pypi.cloudbasesolutions.com/simple
cert = c:\openstack\pypi.cloudbasesolutions.com.crt
"@
Set-Content "$ENV:USERPROFILE\pip\pip.ini" $pipIni

# Add Pypi mirror host to hosts file:
Add-Content "$ENV:SYSTEMROOT\System32\Drivers\etc\hosts" "10.73.76.94 pypi.cloudbasesolutions.com"

# Get Pypi mirror certificate 
Invoke-Webrequest "https://dl.dropboxusercontent.com/u/9060190/pypi.cloudbasesolutions.com.crt" -OutFile "c:\openstack\pypi.cloudbasesolutions.com.crt"

#DownloadInstall "http://download-codeplex.sec.s-msft.com/Download/Release?ProjectName=wix&DownloadId=762937&FileTime=130301249344430000&Build=20885" "exe" "/quiet"
#DownloadInstall 'https://github.com/msysgit/msysgit/releases/download/Git-1.9.2-preview20140411/Git-1.9.2-preview20140411.exe' "exe" "/verysilent"
