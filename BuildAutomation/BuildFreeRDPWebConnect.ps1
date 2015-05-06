$ErrorActionPreference = "Stop"

<#
Install requirements first, see: Installrequirements.ps1
#>

$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
. "$scriptPath\BuildUtils.ps1"
. "$scriptPath\Dependencies.ps1"

# Make sure ActivePerl comes before MSYS Perl, otherwise
# the OpenSSL build will fail
$ENV:PATH = "C:\Perl\bin;$ENV:PATH"
$ENV:PATH += ";$ENV:ProgramFiles\7-Zip"
$ENV:PATH += ";${ENV:ProgramFiles(x86)}\Git\bin"
$ENV:PATH += ";${ENV:ProgramFiles(x86)}\CMake 2.8\bin"
$ENV:PATH += ";${ENV:ProgramFiles(x86)}\nasm"

$vsVersion = "12.0"
$platform = "Win32"
$platformToolset = "v$($vsVersion.Replace('.', ''))"

$zlibBase = "zlib-1.2.8"
$zlibMD5 = "44d667c142d7cda120332623eab69f40"
$libpngBase = "lpng1610"
$libpngSHA1 = "d44d11ad12c27936254c529288d6d044978f3f38"
$pthreadsWin32Base = "pthreads-w32-2-9-1-release"
$pthreadsWin32MD5 = "a3cb284ba0914c9d26e0954f60341354"
$cpprestsdkVersion = "2.0.1"
$opensslVersion = "1.0.1h"
$opensslSha1 = "b2239599c8bf8f7fc48590a55205c26abe560bf8"

$ENV:BOOST_ROOT="C:\local\boost_1_55_0"
$ENV:BOOST_LIBRARYDIR="$ENV:BOOST_ROOT\lib32-msvc-$vsVersion"
$ENV:LIB += ";$ENV:BOOST_LIBRARYDIR"
$ENV:INCLUDE+= ";$ENV:BOOST_ROOT"

$cmakeGenerator = "Visual Studio $($vsVersion.Split(".")[0])"
SetVCVars $vsVersion

$basePath = "C:\OpenStack\build\FreeRDP-WebConnect"
$buildDir = "$basePath\Build"
$outputPath = "$buildDir\bin"

$ENV:OPENSSL_ROOT_DIR="$outputPath\OpenSSL"

$freerdpBranch = "stable-1.1"

pushd .
try
{
    CheckRemoveDir $buildDir
    mkdir $buildDir
    cd $buildDir
    mkdir $outputPath

    GetCPPRestSDK $vsVersion $buildDir $outputPath $cpprestsdkVersion $platform
    CopyBoostDlls $vsVersion $outputPath @("date_time", "filesystem", "program_options", "regex", "system")
    BuildZLib $buildDir $outputPath $zlibBase $cmakeGenerator $platformToolset $true $zlibMD5 $platform
    BuildLibPNG $buildDir $outputPath $libpngBase $cmakeGenerator $platformToolset $true $libpngSHA1 $platform
    BuildOpenSSL $buildDir $outputPath $opensslVersion $cmakeGenerator $platformToolset $true $true $opensslSha1
    BuildFreeRDP $buildDir $outputPath $scriptPath $cmakeGenerator $platformToolset $true $true $false $true $platform $freerdpBranch
    BuildPthreadsW32 $buildDir $outputPath $pthreadsWin32Base $pthreadsWin32MD5
    BuildEHS $buildDir $outputPath $cmakeGenerator $platformToolset $ENV:THREADS_PTHREADS_WIN32_LIBRARY $true $platform
    BuildFreeRDPWebConnect $buildDir $outputPath $cmakeGenerator $platformToolset $ENV:THREADS_PTHREADS_WIN32_LIBRARY $ENV:EHS_ROOT_DIR $platform
}
finally
{
    popd
}
