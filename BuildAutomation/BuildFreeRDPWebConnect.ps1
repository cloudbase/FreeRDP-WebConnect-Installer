$ErrorActionPreference = "Stop"

<#
Install requirements first, see: Installrequirements.ps1
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
