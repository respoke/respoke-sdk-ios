//
//  Respoke.m
//  Respoke SDK
//
//  Created by Jason Adams on 7/7/14.
//  Copyright (c) 2014 Digium, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Respoke.h"
#import "RTCPeerConnectionFactory.h"
#import "RespokeClient+private.h"
#import "APIRegisterPushToken.h"


@interface Respoke () {
    NSMutableArray *instances;
    NSData *pushToken;
}


@end


@implementation Respoke 


+ (Respoke *)sharedInstance
{
    // The Respoke SDK class is a singleton that should be accessed through this share instance method
    static Respoke *sharedInstance = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        sharedInstance = [[Respoke alloc] init];
    });
    
    return sharedInstance;
}


+ (NSString*)makeGUID
{
    NSString *uuid = @"";
    NSString *chars = @"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
    NSInteger rnd = 0;
    NSInteger r;

    for (NSInteger i = 0; i < 36; i += 1) 
    {
        if (i == 8 || i == 13 ||  i == 18 || i == 23) 
        {
            uuid = [uuid stringByAppendingString:@"-"];
        } 
        else if (i == 14) 
        {
            uuid = [uuid stringByAppendingString:@"4"];
        } 
        else 
        {
            if (rnd <= 0x02) 
            {
                rnd = 0x2000000 + (arc4random() % 0x1000000) | 0;
            }
            r = rnd & 0xf;
            rnd = rnd >> 4;

            if (i == 19)
            {
                uuid = [uuid stringByAppendingString:[chars substringWithRange:NSMakeRange((r & 0x3) | 0x8, 1)]];
            }
            else
            {
                uuid = [uuid stringByAppendingString:[chars substringWithRange:NSMakeRange(r, 1)]];
            }
        }
    }

    return uuid;
}


- (instancetype)init 
{
    if (self = [super init])
    {
        instances = [[NSMutableArray alloc] init];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate) name:UIApplicationWillTerminateNotification object:nil];
    }

    return self;
}


- (RespokeClient*)createClient
{
    RespokeClient *newClient = [[RespokeClient alloc] init];
    [instances addObject:newClient];
    return newClient;
}


- (void)unregisterClient:(RespokeClient*)client
{
    [instances removeObject:client];
}


- (void)client:(RespokeClient*)client connectedWithEndpoint:(NSString*)endpointID
{
    if (pushToken)
    {
        // A push notification token has already been recorded, so notify the Respoke servers that this device is eligible to receive notifications directed at the specified endpointID
        [self registerPushServicesForEndpointID:endpointID];
    }
}


- (void)registerPushToken:(NSData*)token
{
    pushToken = token;

    if ([instances count])
    {
        // If there are already client instances running, check if any of them have already connected
        for (RespokeClient *eachInstance in instances)
        {
            if ([eachInstance isConnected])
            {
                // This client has already connected, so notify the Respoke servers that this device is eligible to receive notifications directed at this endpointID
                [self registerPushServicesForEndpointID:[eachInstance getEndpointID]];
            }
        }
    }
}


- (void)applicationWillTerminate
{
    [RTCPeerConnectionFactory deinitializeSSL];
}


- (void)registerPushServicesForEndpointID:(NSString*)endpointID
{
    NSLog(@"Registering Endpoint ID %@ for notifications", endpointID);
    APIRegisterPushToken *transaction = [[APIRegisterPushToken alloc] init];
    transaction.token = pushToken;
    transaction.endpointID = endpointID;
    [transaction goWithSuccessHandler:^(){
        NSLog(@"Successfully registered push token");
    } errorHandler:^(NSString *error){
        NSLog(@"Push register failed: %@", error);
    }];
}


@end
