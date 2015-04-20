//
//  APIGetToken.m
//  Respoke SDK
//
//  Copyright 2015, Digium, Inc.
//  All rights reserved.
//
//  This source code is licensed under The MIT License found in the
//  LICENSE file in the root directory of this source tree.
//
//  For all details and documentation:  https://www.respoke.io
//

#import "APIGetToken.h"

#define DEFAULT_TTL (60 * 60 * 6)


@implementation APIGetToken


- (instancetype)initWithBaseUrl:(NSString *)baseURL
{
    self = [super initWithBaseUrl:[baseURL stringByAppendingString:@"/v1/tokens"]];
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
