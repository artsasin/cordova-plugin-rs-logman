var exec = require('cordova/exec');

exports.start = function (arg0, success, error) {
    exec(success, error, 'CordovaPluginRsLogman', 'start', [arg0]);
};

exports.stop = function (arg0, success, error) {
    exec(success, error, 'CordovaPluginRsLogman', 'stop', [arg0]);
};

exports.setMedian = function (arg0, success, error) {
    exec(success, error, 'CordovaPluginRsLogman', 'setMedian', [arg0]);
};

exports.startCollect = function (arg0, success, error) {
    exec(success, error, 'CordovaPluginRsLogman', 'startCollect', [arg0]);
};

exports.stopCollect = function (arg0, success, error) {
    exec(success, error, 'CordovaPluginRsLogman', 'stopCollect', [arg0]);
};

exports.result = function (arg0, success, error) {
    exec(success, error, 'CordovaPluginRsLogman', 'result', [arg0]);
};

exports.setLogentryProps = function(arg0, success, error) {
    exec(success, error, 'CordovaPluginRsLogman', 'setLogentryProps', [arg0]);
};