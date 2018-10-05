// Copyright (c) 2014 Cloudbase Solutions Srl. All rights reserved.

// Begin common utils (as there's no practival way to include a separate script)

// Awful workaround to include common js features
var commonIncludeFileName = "D254E4EB-10BB-45B2-A340-0900B7E59820.js";
function loadCommonIncludeFile(fileName) {
    var shell = new ActiveXObject("WScript.Shell");
    var windir = shell.ExpandEnvironmentStrings("%WINDIR%");
    var path = windir + "\\Temp\\" + fileName;
    var fso = new ActiveXObject("Scripting.FileSystemObject");
    return fso.OpenTextFile(path, 1).ReadAll();
}
eval(loadCommonIncludeFile(commonIncludeFileName));
// End workaround

function writeWSGateConfFileAction() {
    try {
        logMessage("Writing wsgate.ini file");

        var data = Session.Property("CustomActionData").split('|');

        var i = 0;
        var wsgateConfFolder = data[i++];
        var webRootFolder = data[i++];
        var httpListeningAddress = data[i++];
        var httpPort = data[i++];
        var redirectHttps = checkBoxValueToBool(data[i++]);
        var httpsListeningAddress = data[i++];
        var httpsPort = data[i++];
        var httpsCertFile = data[i++];
        var openstackAuthUrl = data[i++];
        var openstackTenantName = data[i++];
        var openstackUserName = data[i++];
        var openstackPassword = data[i++];
        var openstackProjectDomainName = data[i++];
        var openstackUserDomainName = data[i++];
        var hypervHostUserName = data[i++];
        var hypervHostPassword = data[i++];

        var keyStoneVersion = "v2.0";
        if (openstackProjectDomainName.length > 0 && openstackUserDomainName.length > 0) {
            keyStoneVersion = "v3";
        }

        var wsgateConfFileName = wsgateConfFolder + "wsgate.ini";

        var configGlobal = {
            "debug": false,
            "redirect": redirectHttps,
            "port": httpPort,
            "bindaddr": httpListeningAddress
        };

        var configHttp = {
            "documentroot": webRootFolder
        };

        var configHttps = {
            "port": httpsPort,
            "bindaddr": httpsListeningAddress,
            "certfile": httpsCertFile
        };

        var rdpOverrideConfig = {
            "nofullwindowdrag": true
        };

        var configOpenStack = {
            "keystoneversion": keyStoneVersion,
            "authurl": openstackAuthUrl,
            "username": openstackUserName,
            "password": openstackPassword
        };

        if (keyStoneVersion == "v3") {
            configOpenStack["projectname"] = openstackTenantName;
            configOpenStack["projectdomainname"] = openstackProjectDomainName;
            configOpenStack["userdomainname"] = openstackUserDomainName;
        } else {
            configOpenStack["tenantname"] = openstackTenantName;
        }

        var configHyperV = {
            "hostusername": hypervHostUserName,
            "hostpassword": hypervHostPassword
        };

        configSections = {
            "global": configGlobal,
            "http": configHttp,
            "ssl": configHttps,
            "rdpoverride": rdpOverrideConfig,
            "openstack": configOpenStack,
            "hyperv": configHyperV
        };

        writeConfigFile(wsgateConfFileName, configSections);

        return MsiActionStatus.Ok;
    }
    catch (ex) {
        logException(ex);
        return MsiActionStatus.Abort;
    }
}