var exec = require('cordova/exec');

exports.start = function (arg0, success, error) {
    exec(success, error, 'CordovaPluginRsLogman', 'start', [arg0]);
};

exports.stop = function (arg0, success, error) {
    exec(success, error, 'CordovaPluginRsLogman', 'stop', [arg0]);
};

exports.setMedian = function (arg0, success, error) {
    exec(success, error, 'CordovaPluginRsLogman', 'set-median', [arg0]);
};

exports.startCollect = function (arg0, success, error) {
    exec(success, error, 'CordovaPluginRsLogman', 'start-collect', [arg0]);
};

exports.stopCollect = function (arg0, success, error) {
    exec(success, error, 'CordovaPluginRsLogman', 'stop-collect', [arg0]);
};

exports.incrementLogEntryIndex = function (arg0, success, error) {
    exec(success, error, 'CordovaPluginRsLogman', 'increment-log-entry-index', [arg0]);
};

exports.setLogEntryCategoryKey = function (arg0, success, error) {
    exec(success, error, 'CordovaPluginRsLogman', 'set-log-entry-category-key', [arg0]);
};

exports.setLogEntryStimulKey = function (arg0, success, error) {
    exec(success, error, 'CordovaPluginRsLogman', 'set-log-entry-stimul-key', [arg0]);
};

exports.setModuleStage = function (arg0, success, error) {
    exec(success, error, 'CordovaPluginRsLogman', 'set-module-stage', [arg0]);
};

exports.setModuleNumber = function (arg0, success, error) {
    exec(success, error, 'CordovaPluginRsLogman', 'set-module-number', [arg0]);
};

exports.result = function (arg0, success, error) {
    exec(success, error, 'CordovaPluginRsLogman', 'result', [arg0]);
};