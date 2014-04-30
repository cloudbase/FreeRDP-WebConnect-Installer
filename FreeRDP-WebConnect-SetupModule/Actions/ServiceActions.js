// Copyright (c) 2012 Cloudbase Solutions Srl. All rights reserved.

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

function changeServiceAction() {
    try {
        var data = Session.Property("CustomActionData").split('|');
        var serviceName = data[0];
        var startMode = data[1];
        var startAction = data[2];

        logMessage("Changing service " + serviceName + ", startMode: " + startMode + ", startAction: " + startAction);

        changeService(serviceName, startMode, startAction);

        return MsiActionStatus.Ok;
    }
    catch (ex) {
        logMessage(ex.message);
        return MsiActionStatus.Abort;
    }
}