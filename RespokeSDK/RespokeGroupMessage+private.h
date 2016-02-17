//
//  RespokeGroupMessage+private.h
//  Respoke SDK
//
//  Copyright 2016, Digium, Inc.
//  All rights reserved.
//
//  This source code is licensed under The MIT License found in the
//  LICENSE file in the root directory of this source tree.
//
//  For all details and documentation:  https://www.respoke.io
//

#import "RespokeGroupMessage.h"

@interface RespokeGroupMessage (private)

- (instancetype) initWithMessage:(NSString*) message group:(RespokeGroup*)group
    endpoint:(RespokeEndpoint*)endpoint timestamp:(NSDate*)timestamp;

@end
