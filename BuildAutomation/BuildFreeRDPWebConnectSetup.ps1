$ErrorActionPreference = "Stop"

<#
Install requirements first, see: Installrequirements.ps1
#>

$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
. "$scriptPath\BuildUtils.ps1"

$basePath = "C:\OpenStack\build\FreeRDP-WebConnect"

CheckDir $basePath
pushd .
try
{
    cd $basePath

    $ENV:PATH += ";$ENV:ProgramFiles (x86)\Git\bin\"
    $ENV:PATH += ";C:\Tools\AlexFTPS-1.1.0"

    # Needed for SSH
    $ENV:HOME = $ENV:USERPROFILE

    $sign_cert_thumbprint = "65c29b06eb665ce202676332e8129ac48d613c61"
    $ftpsCredentials = GetCredentialsFromFile "$ENV:UserProfile\ftps.txt"

    SetVCVars

    ExecRetry {
        # Make sure to have a private key that matches a github deployer key in $ENV:HOME\.ssh\id_rsa
        GitClonePull "FreeRDP-WebConnect-Installer" "git@github.com:/cloudbase/FreeRDP-WebConnect-Installer.git"
    }

    $solution_dir = "FreeRDP-WebConnect-Installer"
    $msm_project_dir = "$solution_dir\FreeRDP-WebConnect-SetupModule"
    $msi_project_dir = "$solution_dir\FreeRDP-WebConnect-Installer"
    $msm_binaries_dir = "$msm_project_dir\Binaries"
    $webroot_dir = "$msm_project_dir\WebRoot"

    $buildDir = "$basePath\Build"

    del -Force -Recurse "$msm_binaries_dir\*"
    copy "$buildDir\bin\*.dll" $msm_binaries_dir
    copy "$buildDir\bin\wsgate.exe" $msm_binaries_dir
    copy "$buildDir\bin\openssl.exe" $msm_binaries_dir

    # Keep the Cloudbase images
    del -Force -Recurse "$webroot_dir\*" -Exclude favicon.ico,FreeRDP_Logo.png
    $webroot_source_dir = "$buildDir\FreeRDP-WebConnect\wsgate\webroot"
    copy "$webroot_source_dir\index.html" $webroot_dir
    copy "$webroot_source_dir\*.png" -Exclude FreeRDP_Logo.png $webroot_dir
    copy -Recurse "$webroot_source_dir\js" $webroot_dir
    copy -Recurse "$webroot_source_dir\css" $webroot_dir
    copy -Recurse "$webroot_source_dir\images" $webroot_dir

    pushd .
    try
    {
        cd $msm_project_dir
        &msbuild FreeRDPWebConnectSetupModule.wixproj /p:Platform=x86 /p:Configuration=Release /p:DefineConstants=`"BinariesPath=Binaries`;WebRootPath=WebRoot`"
        if ($LastExitCode) { throw "MSBuild failed" }
    }
    finally
    {
        popd
    }

    pushd .
    try
    {
        cd $msi_project_dir
        &msbuild FreeRDPWebConnectInstaller.wixproj /p:Platform=x86 /p:Configuration=Release
        if ($LastExitCode) { throw "MSBuild failed" }
    }
    finally
    {
        popd
    }

    $msi_path = "$msi_project_dir\bin\Release\FreeRDP-WebConnect-Installer.msi"

    ExecRetry {
        &signtool.exe sign /sha1 $sign_cert_thumbprint /t http://timestamp.verisign.com/scripts/timstamp.dll /v $msi_path
        if ($LastExitCode) { throw "signtool failed" }
    }

    $ftpsUsername = $ftpsCredentials.UserName
    $ftpsPassword = $ftpsCredentials.GetNetworkCredential().Password

    ExecRetry {
        &ftps -h www.cloudbase.it -ssl All -U $ftpsUsername -P $ftpsPassword -sslInvalidServerCertHandling Accept -p $msi_path /cloudbase.it/main/downloads/FreeRDPWebConnect_Beta.msi
        if ($LastExitCode) { throw "ftps failed" }
    }
}
finally
{
    popd
}
