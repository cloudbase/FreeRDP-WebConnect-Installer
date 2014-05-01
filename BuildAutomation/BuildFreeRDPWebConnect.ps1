$ErrorActionPreference = "Stop"

<#
Requirements:

VS 2013 (12.0) >= professional
http://downloads.sourceforge.net/project/boost/boost-binaries/1.55.0-build2/boost_1_55_0-msvc-12.0-32.exe
http://www.nasm.us/pub/nasm/releasebuilds/2.11.02/win32/nasm-2.11.02-installer.exe
http://www.activestate.com/activeperl/downloads/thank-you?dl=http://downloads.activestate.com/ActivePerl/releases/5.18.2.1802/ActivePerl-5.18.2.1802-MSWin32-x86-64int-298023.msi
http://www.cmake.org/files/v2.8/cmake-2.8.12.2-win32-x86.exe
http://downloads.sourceforge.net/sevenzip/7z920-x64.msi
http://git-scm.com/download/win

#>

$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
. "$scriptPath\BuildUtils.ps1"
. "$scriptPath\Dependencies.ps1"

$ENV:PATH += ";$ENV:ProgramFiles\7-Zip"
$ENV:PATH += ";${ENV:ProgramFiles(x86)}\Git\bin"
$ENV:PATH += ";${ENV:ProgramFiles(x86)}\CMake 2.8\bin"
$ENV:PATH += ";${ENV:ProgramFiles(x86)}\nasm"
$ENV:PATH += ";C:\Perl\bin"

$vsVersion = "12.0"

$zlibBase = "zlib-1.2.8"
$libpngBase = "lpng1610"
$pthreadsWin32Base = "pthreads-w32-2-9-1-release"
$cpprestsdkVersion = "2.0.1"
$cpprestsdkArch = "Win32"
$opensslVersion = "1.0.1g"

$ENV:BOOST_ROOT="C:\local\boost_1_55_0"
$ENV:BOOST_LIBRARYDIR="$ENV:BOOST_ROOT\lib32-msvc-$vsVersion"
$ENV:LIB += ";$ENV:BOOST_LIBRARYDIR"
$ENV:INCLUDE+= ";$ENV:BOOST_ROOT"

$cmakeGenerator = "Visual Studio $($vsVersion.Split(".")[0])"
SetVCVars $vsVersion

$buildDir = "$scriptPath\build"
$outputPath = "$buildDir\bin"

$ENV:OPENSSL_ROOT_DIR="$outputPath\OpenSSL"


pushd .
try
{
    CheckRemoveDir $buildDir
    mkdir $buildDir
    cd $buildDir
    mkdir $outputPath

    GetCPPRestSDK $vsVersion $buildDir $outputPath $cpprestsdkVersion $cpprestsdkArch
    CopyBoostDlls $vsVersion $outputPath @("date_time", "filesystem", "program_options", "regex", "system")
    BuildZLib $buildDir $outputPath $zlibBase $cmakeGenerator
    BuildLibPNG $buildDir $outputPath $libpngBase $cmakeGenerator
    BuildOpenSSL $buildDir $outputPath $opensslVersion $cmakeGenerator $true
    BuildFreeRDP $buildDir $outputPath $scriptPath $cmakeGenerator $false
    BuildPthreadsW32 $buildDir $outputPath $pthreadsWin32Base
    BuildEHS $buildDir $outputPath $cmakeGenerator $ENV:THREADS_PTHREADS_WIN32_LIBRARY
    BuildFreeRDPWebConnect $buildDir $outputPath $cmakeGenerator $ENV:THREADS_PTHREADS_WIN32_LIBRARY $ENV:EHS_ROOT_DIR
}
finally
{
    popd
}
