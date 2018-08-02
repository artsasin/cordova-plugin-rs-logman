#import <CoreMotion/CoreMotion.h>
#import "ResearchSurveySensorLogman.h"



@interface ResearchSurveySensorLogman () {}
@property (readwrite, assign) BOOL collectData;
@property (readwrite, assign) BOOL haveReturnedResult;
@property (readwrite, strong) CMMotionManager* motionManager;
@property (readwrite, assign) double median;
@property (readwrite, assign) int moduleNumber;
@property (readwrite, assign) int moduleStage;
@property (readwrite, assign) int logEntryIndex;
@property (readwrite, assign) NSString* logEntryCategoryKey;
@property (readwrite, retain) NSString* logEntryStimulKey;
@property (readwrite, copy) NSString* stype;
@property (nonatomic, strong) NSMutableArray* logItems;
@end

@implementation ResearchSurveySensorLogman

@synthesize callbackId, collectData,logEntryIndex, stype, moduleNumber, logEntryStimulKey;

// defaults to 10 msec
#define kAccelerometerInterval 1
// g constant: -9.81 m/s^2
#define kGravitationalConstant -9.81

- (ResearchSurveySensorLogman*)init
{
    self = [super init];
    if (self) {
        self.callbackId = nil;
        self.collectData = NO;
        self.haveReturnedResult = YES;
        self.motionManager = nil;
        self.moduleNumber = 0;

    }
    return self;
}

- (NSMutableArray *) logItems
{
    if (!_logItems) {
        _logItems = [NSMutableArray new];
    }
    return _logItems;
}

- (void)dealloc
{
    [self stop:nil];
}

- (void)start:(CDVInvokedUrlCommand*)command
{
    self.haveReturnedResult = NO;
//    self.callbackId = command.callbackId;

    if (!self.motionManager)
    {
        self.motionManager = [[CMMotionManager alloc] init];
    }

//    if (YES) {
    if ([self.motionManager isAccelerometerAvailable] == YES) {
        // Assign the update interval to the motion manager and start updates
        [self.motionManager setAccelerometerUpdateInterval:kAccelerometerInterval];  // expected in seconds
        __weak ResearchSurveySensorLogman* weakSelf = self;
        [self.motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {
            [weakSelf win:accelerometerData];
        }];
    }
    else {

        NSLog(@"Running in Simulator? All gyro tests will fail.");
        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_INVALID_ACTION messageAsString:@"Error. Accelerometer Not Available."];
        
        [self.commandDelegate sendPluginResult:result callbackId:self.callbackId];
    }
    CDVPluginResult* result = nil;
    result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

- (void)startCollect:(CDVInvokedUrlCommand*)command
{
//	NSLog(@"in startCollect");
    self.collectData = YES;
    CDVPluginResult* result = nil;
    result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

- (void)setMedian:(double)median:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* result = nil;
    result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

- (void)stopCollect:(CDVInvokedUrlCommand*)command
{
    //	NSLog(@"in startCollect");
    self.collectData = NO;
    CDVPluginResult* result = nil;
    result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

- (void)setLogentryProps:(CDVInvokedUrlCommand*)command
{

    NSDictionary* props = [command.arguments objectAtIndex:0];

//    NSLog(@"This is my arguments: %@", [command.arguments class]);

    if (((props[@"stmkey"] != (id)[NSNull null])  )  && ([[props objectForKey:@"stmkey" ]boolValue])) {
        NSLog(@"inrease logEntryIndex ");
        self.logEntryIndex++;
    }
    
    if ((props[@"stype"] != (id)[NSNull null])  )  {
        NSLog(@"change stype to  %@", [props[@"stype"] description]);
        self.stype = [props valueForKey:@"stype"];
    }
    


   if ((props[@"sindex"] != (id)[NSNull null]) &&  [props[@"sindex"] isKindOfClass:[NSNumber class]] ){
        NSLog(@"change sindex to  %@", [props[@"sindex"] description]);
        int sindex = [[props valueForKey:@"sindex"] integerValue ];
        self.moduleNumber = sindex;
    }else{
        NSLog(@"sindex is null or not number  ");
    }

   if ((props[@"state"] != (id)[NSNull null]) &&  [props[@"state"] isKindOfClass:[NSNumber class]] ){
        NSLog(@"change state to  %@", [props[@"state"] description]);
        self.moduleStage = [[props objectForKey:@"state"] integerValue ];
    }else{
        NSLog(@"state is null or not number  ");
    }

   if ((props[@"cat"] != (id)[NSNull null]) &&  [props[@"cat"] isKindOfClass:[NSString class]] ){
        NSLog(@"change cat to  %@", [props[@"cat"] description]);
      // NSMutableString *cat = (NSString*)[props objectforkey@"cat"];
       self.logEntryCategoryKey = [props valueForKey:@"cat"] ;
       
    }else{
        NSLog(@"cat is null or not number  ");
    }


   if ((props[@"stm"] != (id)[NSNull null]) &&  [props[@"stm"] isKindOfClass:[NSString class]] ){
        NSLog(@"change stm to  %@", [props[@"stm"] description]);
        self.logEntryStimulKey =[props valueForKey:@"stm"] ;
    }else{
        NSLog(@"stm is null or not number  ");
    }

        NSLog(@"logEntryIndex: %d, stype %@, m= %d, stage= %d, cat= %@, key= %@", self.logEntryIndex, self.stype, self.moduleNumber, self.moduleStage, self.logEntryCategoryKey, self.logEntryStimulKey);

    CDVPluginResult* result = nil;
    result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}


- (void)result:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* result = nil;
    
    // Check command.arguments here.
    if (YES) {
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:(self.logItems)];
    } else {
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Echo Argument was null"];
    }
       NSLog(@"in result222 %@", [self.logItems description]);
    
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
//    NSLog([@"aftre send result" ];
    [self.logItems removeAllObjects];

//    NSLog([NSString stringWithFormat:@"%.20lf", self.x]);
//    if ([self.motionManager isAccelerometerAvailable] == YES) {
//        [self returnAccelInfo];
//        if (self.haveReturnedResult == NO){
//            NSLog(@"in result3");
//            // block has not fired before stop was called, return whatever result we currently have
//            [self returnAccelInfo];
//        }
//        [self.motionManager stopAccelerometerUpdates];
//    }
}

- (void)onReset
{
    [self stop:nil];
}

- (void)stop:(CDVInvokedUrlCommand*)command
{
    if ([self.motionManager isAccelerometerAvailable] == YES) {
        if (self.haveReturnedResult == NO){
            // block has not fired before stop was called, return whatever result we currently have
            [self returnAccelInfo];
        }
        [self.motionManager stopAccelerometerUpdates];
    }
    self.collectData = NO;
    CDVPluginResult* result = nil;
    result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

- (void)win:(CMAccelerometerData*)data
{
//    NSLog([data description]);
    if (self.collectData){
        NSArray* row = [NSArray arrayWithObjects:
                        [NSNumber numberWithFloat:(data.timestamp)],
                        self.stype,
                        [NSNumber numberWithFloat:self.moduleNumber],
                        [NSNumber numberWithFloat:self.moduleStage],
                        self.logEntryCategoryKey,
                        self.logEntryStimulKey,
                        [NSNumber numberWithInteger:self.logEntryIndex],
                        [NSNumber numberWithFloat:(data.acceleration.x * kGravitationalConstant)],
                        [NSNumber numberWithFloat:(data.acceleration.y * kGravitationalConstant)],
                        [NSNumber numberWithFloat:(data.acceleration.z * kGravitationalConstant)],
                        nil];
        [self.logItems addObject:row];

    }
}

- (void)returnAccelInfo
{
    NSLog(@"rAI");
    // Create an acceleration object
    NSMutableDictionary* accelProps = [NSMutableDictionary dictionaryWithCapacity:4];

//    [accelProps setValue:[NSNumber numberWithDouble:self.x * kGravitationalConstant] forKey:@"x"];
//    [accelProps setValue:[NSNumber numberWithDouble:self.y * kGravitationalConstant] forKey:@"y"];
//    [accelProps setValue:[NSNumber numberWithDouble:self.z * kGravitationalConstant] forKey:@"z"];
//    [accelProps setValue:[NSNumber numberWithDouble:self.timestamp] forKey:@"timestamp"];
//
//    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:accelProps];
//    [result setKeepCallback:[NSNumber numberWithBool:YES]];
//    [self.commandDelegate sendPluginResult:result callbackId:self.callbackId];
    self.haveReturnedResult = YES;
}

// TODO: Consider using filtering to isolate instantaneous data vs. gravity data -jm

/*
 #define kFilteringFactor 0.1
 // Use a basic low-pass filter to keep only the gravity component of each axis.
 grav_accelX = (acceleration.x * kFilteringFactor) + ( grav_accelX * (1.0 - kFilteringFactor));
 grav_accelY = (acceleration.y * kFilteringFactor) + ( grav_accelY * (1.0 - kFilteringFactor));
 grav_accelZ = (acceleration.z * kFilteringFactor) + ( grav_accelZ * (1.0 - kFilteringFactor));
 // Subtract the low-pass value from the current value to get a simplified high-pass filter
 instant_accelX = acceleration.x - ( (acceleration.x * kFilteringFactor) + (instant_accelX * (1.0 - kFilteringFactor)) );
 instant_accelY = acceleration.y - ( (acceleration.y * kFilteringFactor) + (instant_accelY * (1.0 - kFilteringFactor)) );
 instant_accelZ = acceleration.z - ( (acceleration.z * kFilteringFactor) + (instant_accelZ * (1.0 - kFilteringFactor)) );
 */
@end
