/*
 * An HTTP Cordova Plugin to receive large get request data in chunks.
 */

var exec = require('cordova/exec');

var http = {
    getChunked: function(url, params, headers, success, failure) {
        return exec(success, failure, "CordovaHttpPluginChunks", "getChunked", [url, params, headers]);
    },
};

module.exports = http;

window.cordovaHTTP = http;
