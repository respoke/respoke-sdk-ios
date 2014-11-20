//
//  APIRegisterPushToken.m
//  RespokeSDKBuilder
//
//  Created by Jason Adams on 11/13/14.
//  Copyright (c) 2014 Digium, Inc. All rights reserved.
//

#import "APIRegisterPushToken.h"

#define RESPOKE_PUSH_SERVER_URL @"http://192.168.1.65:3000"
#define LAST_VALID_PUSH_TOKEN_KEY @"LAST_VALID_PUSH_TOKEN_KEY"


@implementation APIRegisterPushToken {
    NSString *tokenHexString;
}


- (NSString*)hexifyData:(NSData *)data
{
    const unsigned char *dataBuffer = (const unsigned char *)[data bytes];
    if (!dataBuffer)
    {
        return [NSString string];
    }

    NSUInteger dataLength = [data length];
    NSMutableString *hex = [NSMutableString stringWithCapacity:(dataLength * 2)];
    for (int i = 0; i < dataLength; ++i)
    {
        [hex appendString:[NSString stringWithFormat:@"%02lx", (unsigned long)dataBuffer[i]]];
    }

    return [NSString stringWithString:hex];
}


- (void)goWithSuccessHandler:(void (^)())successHandler errorHandler:(void (^)(NSString*))errorHandler
{
    self.baseURL = RESPOKE_PUSH_SERVER_URL;
    urlEndpoint = @"/v1/register";
    tokenHexString = [self hexifyData:self.token];
    
    if (tokenHexString.length > 0)
    {
        NSError *error;
        NSString *lastKnownPushToken = [[NSUserDefaults standardUserDefaults] objectForKey:LAST_VALID_PUSH_TOKEN_KEY];
            
        NSMutableDictionary *messageDict = [NSMutableDictionary dictionary];
        [messageDict setObject:[NSNumber numberWithInteger:1] forKey:@"app_id"];
        [messageDict setObject:self.endpointIDArray forKey:@"names"];
        [messageDict setObject:[NSNumber numberWithInteger:1] forKey:@"service"];
        [messageDict setObject:tokenHexString forKey:@"token"];

        if (lastKnownPushToken && ![lastKnownPushToken isEqualToString:tokenHexString])
        {
            // If the push token for this device has changed since the last valid token was retrieved, also send the old one to the registration API so that it can clean up unused tokens from it's database
            [messageDict setObject:lastKnownPushToken forKey:@"old_token"];
        }

        if ([NSJSONSerialization isValidJSONObject:messageDict])
        {
            jsonParams = [NSJSONSerialization dataWithJSONObject:messageDict options:0 error:&error];

            if (error)
            {
                self.errorHandler(@"Unable to encode message to json");
            }
            else
            {
                [super goWithSuccessHandler:successHandler errorHandler:errorHandler];
            }
        }
        else
        {
            self.errorHandler(@"Unable to encode message to json");
        }
    }
    else
    {
        self.errorHandler(@"Unable to convert data to hex");
    }
}


- (void)transactionComplete
{
    // There is no response to parse, so don't call the super class here

    if (self.success)
    {
        [[NSUserDefaults standardUserDefaults] setObject:tokenHexString forKey:LAST_VALID_PUSH_TOKEN_KEY];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        self.successHandler();
    }
    else
    {
        self.errorHandler(self.errorMessage);
    }
}


@end
