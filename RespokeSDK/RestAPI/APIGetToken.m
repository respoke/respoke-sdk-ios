//
//  APIGetToken.m
//  Respoke SDK
//
//  Created by Jason Adams on 7/11/14.
//  Copyright (c) 2014 Digium, Inc. All rights reserved.
//

#import "APIGetToken.h"

#define DEFAULT_TTL (60 * 60 * 6)


@implementation APIGetToken


- (instancetype)init
{
    if (self = [super init])
    {
        urlEndpoint = @"/v1/tokens";
    }

    return self;
}


- (void)goWithSuccessHandler:(void (^)())successHandler errorHandler:(void (^)(NSString*))errorHandler
{
    params = [NSString stringWithFormat:@"appId=%@&endpointId=%@&ttl=%d", self.appID, self.endpointID, DEFAULT_TTL];

    [super goWithSuccessHandler:successHandler errorHandler:errorHandler];
}


- (void)transactionComplete
{
    [super transactionComplete];
    
    if (self.success)
    {
        if ([self.jsonResult isKindOfClass:[NSDictionary class]])
        {
            self.token = [self.jsonResult objectForKey:@"tokenId"];
            
            if (!self.token)
            {
                self.errorMessage = @"Unexpected response from server";
                self.success = NO;
            }
        }
        else
        {
            self.errorMessage = @"Unexpected response from server";
            self.success = NO;
        }
    }

    if (self.success)
    {
        self.successHandler();
    }
    else
    {
        self.errorHandler(self.errorMessage);
    }
}


@end
