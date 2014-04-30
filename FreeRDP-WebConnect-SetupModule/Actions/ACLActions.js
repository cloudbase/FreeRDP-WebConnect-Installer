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

function removeUsersACEFromPathAction() {
    try {
        var data = Session.Property("CustomActionData").split('|');

        var i = 0;
        var path = data[i++];

        if (path.endsWith("\\")) {
            // icacls does not like a trailing backslash
            path = path.substring(0, path.length - 1);
        }

        logMessage("Removing Users permissions from folder: " + path);

        removeUsersACEFromPath(path);

        return MsiActionStatus.Ok;
    }
    catch (ex) {
        logException(ex);
        return MsiActionStatus.Abort;
    }
}