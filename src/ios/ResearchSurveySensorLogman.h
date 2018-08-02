#import <UIKit/UIKit.h>
#import <Cordova/CDVPlugin.h>

@interface ResearchSurveySensorLogman : CDVPlugin
{
    double x;
    double y;
    double z;
    NSTimeInterval timestamp;
}

@property (readonly, assign) BOOL isRunning;
@property (nonatomic, strong) NSString* callbackId;

- (ResearchSurveySensorLogman*)init;

- (void)start:(CDVInvokedUrlCommand*)command;
- (void)stop:(CDVInvokedUrlCommand*)command;
- (void)startCollect:(CDVInvokedUrlCommand*)command;
- (void)result:(CDVInvokedUrlCommand*)command;
- (void)setLogentryProps:(CDVInvokedUrlCommand*)command;

@end
