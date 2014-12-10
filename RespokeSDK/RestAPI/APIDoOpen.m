//
//  APIDoOpen.m
//  Respoke SDK
//
//  Created by Jason Adams on 7/13/14.
//  Copyright (c) 2014 Digium, Inc. All rights reserved.
//

#import "APIDoOpen.h"

@implementation APIDoOpen


- (instancetype)init
{
    if (self = [super init])
    {
        urlEndpoint = @"/v1/appauthsessions";
    }

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
