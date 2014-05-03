$ErrorActionPreference = "Stop"

$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
. "$scriptPath\BuildUtils.ps1"

iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))

ChocolateyInstall git.install

# Following packages either are not available / updated in Chocolatey or their Chocolatey packages have issues
DownloadInstall 'http://downloads.sourceforge.net/sevenzip/7z922-x64.msi' "msi"
DownloadInstall 'http://www.cmake.org/files/v2.8/cmake-2.8.12.2-win32-x86.exe' "exe" "/S"
DownloadInstall "http://downloads.sourceforge.net/project/boost/boost-binaries/1.55.0-build2/boost_1_55_0-msvc-12.0-32.exe" "exe" "/VERYSILENT /SUPPRESSMSGBOXES"
DownloadInstall 'http://downloads.activestate.com/ActivePerl/releases/5.18.2.1802/ActivePerl-5.18.2.1802-MSWin32-x86-64int-298023.msi' "msi"
DownloadInstall 'http://download.microsoft.com/download/7/2/E/72E0F986-D247-4289-B9DC-C4FB07374894/wdexpress_full.exe' "exe" "/S /Q /Full"
DownloadInstall 'http://download.microsoft.com/download/8/2/6/826E264A-729E-414A-9E67-729923083310/VSU1/VS2013.1.exe' "exe" "/S /Q /Full"
# Note: nasm installs in a user location when executed withoud admin rights
DownloadInstall "http://www.nasm.us/pub/nasm/releasebuilds/2.11.02/win32/nasm-2.11.02-installer.exe" "exe" "/S"

# Install WiX after Visual Studio for integration
ChocolateyInstall wixtoolset

$ENV:PATH += ";${ENV:ProgramFiles(x86)}\Git\bin"

&git config --global user.name "Automated Build"
if ($LastExitCode) { throw "git config failed" }
&git config --global user.email "build@cloudbase"
if ($LastExitCode) { throw "git config failed" }

$toolsdir = "C:\Tools"
CheckDir $toolsdir

$path = "$ENV:TEMP\AlexFTPS_bin_1.1.0.zip" 
DownloadFile "http://download-codeplex.sec.s-msft.com/Download/Release?ProjectName=ftps&DownloadId=271579&FileTime=129582362189170000&Build=20885" $path
$ENV:PATH += ";$ENV:ProgramFiles\7-Zip"
Expand7z $path $toolsdir
del $path

$pfxPassword = "changeme"
$thumbprint = ImportCertificateUser "$ENV:USERPROFILE\Cloudbase_authenticode.p12" $pfxPassword
# TODO: write thumbrint to file and load it in teh build script(s) in place of the hardcoded value

#DownloadInstall "http://download-codeplex.sec.s-msft.com/Download/Release?ProjectName=wix&DownloadId=762937&FileTime=130301249344430000&Build=20885" "exe" "/quiet"
#DownloadInstall 'https://github.com/msysgit/msysgit/releases/download/Git-1.9.2-preview20140411/Git-1.9.2-preview20140411.exe' "exe" "/verysilent"
