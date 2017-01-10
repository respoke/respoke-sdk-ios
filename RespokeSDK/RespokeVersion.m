//
//  RespokeVersion.h
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

#import "RespokeVersion.h"

static NSString* const sdk_version = @"1.3.1";

const NSString *getSDKVersion(void)
{
    return sdk_version;
}
