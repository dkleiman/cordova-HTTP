/*
 * An HTTP Cordova Plugin to receive large get request data in chunks.
 */

var exec = require('cordova/exec');

function mergeHeaders(globalHeaders, localHeaders) {
    var globalKeys = Object.keys(globalHeaders);
    var key;
    for (var i = 0; i < globalKeys.length; i++) {
        key = globalKeys[i];
        if (!localHeaders.hasOwnProperty(key)) {
            localHeaders[key] = globalHeaders[key];
        }
    }
    return localHeaders;
}

var http = {
    getChunked: function(url, params, headers, success, failure) {
        headers = mergeHeaders(this.headers, headers);
        return exec(success, failure, "CordovaHttpPluginChunks", "getChunked", [url, params, headers]);
    },
};

module.exports = http;

window.cordovaHTTP = http;
