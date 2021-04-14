Param(
  [string]$SignX509Thumbprint,
  [ValidateSet("x86", "x64")]
  [string]$Platform = "x64",
  [switch]$SkipCloningInstallerRepo,
  [string]$SignTimestampUrl = "http://timestamp.digicert.com?alg=sha256"
)

$ErrorActionPreference = "Stop"

<#
Install requirements first, see: Installrequirements.ps1
#>

$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
. "$scriptPath\BuildUtils.ps1"

$basePath = "C:\Build\FreeRDP-WebConnect"
$msiRepoUrl = "git@github.com:/cloudbase/FreeRDP-WebConnect-Installer.git"
$msiBranch = "master"

CheckDir $basePath
pushd .
try
{
    cd $basePath

    $ENV:PATH += ";$ENV:ProgramFiles\7-zip\"
    $ENV:PATH += ";$ENV:ProgramFiles (x86)\Git\bin\"
    # Needed for SSH
    $ENV:HOME = $ENV:USERPROFILE

    SetVCVars

    if (!($SkipCloningInstallerRepo)) {
        $solution_dir = join-Path $basePath "FreeRDP-WebConnect-Installer"
        ExecRetry {
            # Make sure to have a private key that matches a github deployer
            # key in $ENV:HOME\.ssh\id_rsa
            GitClonePull $solution_dir $msiRepoUrl $msiBranch
        }
    }
    else {
        $solution_dir = Join-Path -Path $PSScriptRoot -ChildPath ..\ -Resolve
    }

    $msm_project_dir = "$solution_dir\FreeRDP-WebConnect-SetupModule"
    $msi_project_dir = "$solution_dir\FreeRDP-WebConnect-Installer"
    $msm_binaries_dir = "$msm_project_dir\Binaries"
    $webroot_dir = "$msm_project_dir\WebRoot"

    $buildDir = "$basePath\Build"

    CheckRemoveDir "$msm_binaries_dir"
    mkdir "$msm_binaries_dir"

    cp -recurse "$buildDir\bin\pdb" $msm_binaries_dir
    copy "$buildDir\bin\*.dll" $msm_binaries_dir
    copy "$buildDir\bin\wsgate.exe" $msm_binaries_dir
    copy "$buildDir\bin\openssl.exe" $msm_binaries_dir


    pushd $solution_dir
    try
    {
        &msbuild.exe FreeRDP-WebConnect-Installer.sln /p:Platform=$Platform /p:Configuration=Release /p:DefineConstants=`"BinariesPath=Binaries`;WebRootPath=WebRoot`"
        if ($LastExitCode) { throw "MSBuild failed" }
    }
    finally
    {
        popd
    }


    $release_dir = "$msi_project_dir\bin\${Platform}\Release"
    $msi_path = "$release_dir\FreeRDP-WebConnect-Installer.msi"

    if($SignX509Thumbprint)
    {
        ExecRetry {
            &signtool.exe sign /sha1 $SignX509Thumbprint /tr $SignTimestampUrl /td SHA256 /v $msi_path
            if ($LastExitCode) { throw "signtool failed" }
        }
    }
    else
    {
        Write-Warning "MSI not signed"
    }

    $zip_path = "$release_dir\FreeRDP-WebConnect-Installer.zip"
    if (Test-Path $zip_path) {
        del $zip_path
    }

    pushd $msm_project_dir
    try
    {
        CreateZip $zip_path Binaries WebRoot
    }
    finally
    {
        popd
    }
}
finally
{
    popd
}
