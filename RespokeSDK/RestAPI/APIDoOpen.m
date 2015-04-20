//
//  APIDoOpen.m
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

#import "APIDoOpen.h"

@implementation APIDoOpen


- (instancetype)initWithBaseUrl:(NSString *)baseURL
{
    self = [super initWithBaseUrl:[baseURL stringByAppendingString:@"/v1/session-tokens"]];
    return self;
}


- (void)goWithSuccessHandler:(void (^)())successHandler errorHandler:(void (^)(NSString*))errorHandler
{
    params = [NSString stringWithFormat:@"tokenId=%@", self.tokenID];

    [super goWithSuccessHandler:successHandler errorHandler:errorHandler];
}


- (void)transactionComplete
{
    [super transactionComplete];
    
    if (self.success)
    {
        if ([self.jsonResult isKindOfClass:[NSDictionary class]])
        {
            self.appToken = [self.jsonResult objectForKey:@"token"];
            
            if (!self.appToken)
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
