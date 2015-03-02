//
//  Respoke.m
//  Respoke SDK
//
//  Created by Jason Adams on 7/7/14.
//  Copyright (c) 2014 Digium, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Respoke+private.h"
#import "RTCPeerConnectionFactory.h"
#import "RespokeClient+private.h"


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

    for (NSInteger i = 0; i < GUID_STRING_LENGTH; i += 1) 
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
        [self registerPushServices];
    }
}


- (void)registerPushToken:(NSData*)token
{
    pushToken = token;
    [self registerPushServices];
}


- (void)applicationWillTerminate
{
    [RTCPeerConnectionFactory deinitializeSSL];
}


- (void)registerPushServices
{
    if ([instances count] && pushToken) {
        for (RespokeClient *eachInstance in instances)
        {
            if ([eachInstance isConnected])
            {
                [eachInstance registerPushServicesWithToken:pushToken];
            }
        }
    }
}


@end
