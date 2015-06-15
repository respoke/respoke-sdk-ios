//
//  Respoke.h
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


@class RespokeClient;


/**
 *  A global static class which provides access to the Respoke functionality.
 */
@interface Respoke : NSObject


/**
 *  Retrieve the globally shared instance of the Respoke SDK
 *
 *  @return Respoke SDK instance
 */
+ (Respoke *)sharedInstance;


/**
 *  This is one of two possible entry points for interating with the library. This method creates a new Client object
 *  which represence your app's connection to the cloud infrastructure.  This method does NOT automatically call the
 *  client.connect() method after the client is created, so your app will need to call it when it is ready to
 *  connect.
 *
 *  @return A Respoke Client instance
 */
- (RespokeClient*)createClient;


/**
 *  Unregister a client that is no longer active so that it's resources can be
 *  deallocated
 *
 *  @param client  The client to unregister
 */
- (void)unregisterClient:(RespokeClient*)client;


/**
 *  Notify the Respoke SDK that this device should register itself for push notifications
 *
 *  @param token  The token that identifies the device to APS.
 */
- (void)registerPushToken:(NSData*)token;


/**
 *  Unregister this device from the Respoke push notification service and stop any future notifications until it is re-registered
 *
 *  @param successHandler A block to call upon success
 *  @param errorHandler   A block to call upon an error, passing the error message
 */
- (void)unregisterPushServicesWithSuccessHandler:(void (^)(void))successHandler errorHandler:(void (^)(NSString*))errorHandler;


@end
