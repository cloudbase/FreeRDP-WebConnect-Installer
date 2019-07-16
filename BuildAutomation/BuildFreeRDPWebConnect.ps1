Param(
  [ValidateSet("x86", "amd64", "x86_amd64")]
  [string]$Platform = "x86_amd64",
  [ValidateSet(12, 14)]
  [UInt16]$VSVersionNumber = 12
)

$ErrorActionPreference = "Stop"

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

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
$ENV:PATH += ";${ENV:ProgramFiles(x86)}\CMake\bin"
$ENV:PATH += ";${ENV:ProgramFiles(x86)}\nasm"

$vsVersion = "${VSVersionNumber}.0"

$cmakePlatformMap = @{"x86"=""; "amd64"=" Win64"; "x86_amd64"=" Win64"}
$cmakeGenerator = "Visual Studio $($vsVersion.Split(".")[0])$($cmakePlatformMap[$Platform])"
$platformToolset = "v$($vsVersion.Replace('.', ''))"

$vsPlatformMap = @{"x86"="Win32"; "amd64"="x64"; "x86_amd64"="x64"}
$vsPlatform = $vsPlatformMap[$Platform]

$zlibBase = "zlib-1.2.11"
$zlibSHA256 = "c3e5e9fdd5004dcb542feda5ee4f0ff0744628baf8ed2dd5d66f8ca1197cb1a1"
$libpngBase = "lpng1610"
$libpngSHA1 = "d44d11ad12c27936254c529288d6d044978f3f38"
$pthreadsWin32Base = "pthreads-w32-2-9-1-release"
$pthreadsWin32MD5 = "a3cb284ba0914c9d26e0954f60341354"
$cpprestsdkVersion = "2.0.1"
$opensslVersion = "1.0.2h"
$opensslSha1 = "577585f5f5d299c44dd3c993d3c0ac7a219e4949"


$boostLibMap = @{"x86"="32"; "amd64"="64"; "x86_amd64"="64"}
$ENV:BOOST_ROOT="C:\local\boost_1_61_0"
$ENV:BOOST_LIBRARYDIR="$ENV:BOOST_ROOT\lib$($boostLibMap[$Platform])-msvc-$vsVersion"
$ENV:LIB += ";$ENV:BOOST_LIBRARYDIR"
$ENV:INCLUDE+= ";$ENV:BOOST_ROOT"

SetVCVars $vsVersion $Platform

$basePath = "C:\Build\FreeRDP-WebConnect"
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

    GetCPPRestSDK $vsVersion $buildDir $outputPath $cpprestsdkVersion $vsPlatform
    CopyBoostDlls $vsVersion $outputPath @("date_time", "filesystem", "program_options", "regex", "system")
    BuildZLib $buildDir $outputPath $zlibBase $cmakeGenerator $platformToolset $true $zlibSHA256 $vsPlatform
    BuildLibPNG $buildDir $outputPath $libpngBase $cmakeGenerator $platformToolset $true $libpngSHA1 $vsPlatform
    BuildOpenSSL $buildDir $outputPath $opensslVersion $Platform $cmakeGenerator $platformToolset $true $true $opensslSha1
    BuildFreeRDP $buildDir $outputPath $scriptPath $cmakeGenerator $platformToolset $true $true $false $true $vsPlatform $freerdpBranch
    BuildPthreadsW32 $buildDir $outputPath $pthreadsWin32Base $pthreadsWin32MD5
    BuildEHS $buildDir $outputPath $cmakeGenerator $platformToolset $ENV:THREADS_PTHREADS_WIN32_LIBRARY $true $vsPlatform
    BuildFreeRDPWebConnect $buildDir $outputPath $cmakeGenerator $platformToolset $ENV:THREADS_PTHREADS_WIN32_LIBRARY $ENV:EHS_ROOT_DIR $vsPlatform
}
finally
{
    popd
}
