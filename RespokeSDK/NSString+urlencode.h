//
//  NSString+urlencode.h
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

#import <Foundation/Foundation.h>

@interface NSString (NSString_Extended)

/**
 *  Url-encodes a string, suitable for placing into a url as a portion of the query string. 
 *  Source taken from http://stackoverflow.com/a/8088484/355743
 *
 * @return The url-encoded version of the string
 */
- (NSString *)urlencode;

@end
