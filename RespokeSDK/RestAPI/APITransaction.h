//
//  ApiTransaction.h
//  Respoke SDK
//
//  Created by Jason Adams on 7/12/14.
//  Copyright (c) 2014 Digium, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#define RESPOKE_BASE_URL @"api-int.respoke.io"

#define BODY_SIZE_LIMIT 20000


/**
 *  An abstract base class for performing asynchronous REST transactions to the cloud infrastructure over HTTP
 */
@interface APITransaction : NSObject <NSURLConnectionDataDelegate> {
    NSURLConnection *connection;  ///< The NSURLConnection handling the transaction
    NSString *httpMethod;  ///< The HTTP method to use
    NSString *params;  ///< The parameter data to send
    NSData *jsonParams;  ///< The parameter data to send, encoded in json
    NSString *urlEndpoint;  ///< The URL of the remote endpoint
    BOOL abort;  ///< Indicates any asynchronous response should be ignored
}


/**
 *  The base URL of the remote server
 */
@property NSString *baseURL;


/**
 *  Indicates if the transaction was successful
 */
@property BOOL success;


/**
 *  The data returned from the transaction, if any
 */
@property NSMutableData *receivedData;


/**
 *  The decoded json data returned from the transaction, if any
 */
@property id jsonResult;


/**
 *  A block to call upon success
 */
@property (copy) void (^successHandler)();


/**
 *  A block to call if an error occurs, passing a string describing the error
 */
@property (copy) void (^errorHandler)(NSString*);


/**
 *  The most recent error message for this transaction
 */
@property NSString *errorMessage;


/**
 *  Start the REST transaction
 *
 *  @param successHandler A block to call upon success
 *  @param errorHandler   A block to call if an error occurs, passing a string describing the error
 */
- (void)goWithSuccessHandler:(void (^)())successHandler errorHandler:(void (^)(NSString*))errorHandler;


/**
 *  A method called when the transaction has completed (overridden by child classes)
 */
- (void)transactionComplete;


/**
 *  Cancel any transaction in progress
 */
- (void)cancel;


@end
