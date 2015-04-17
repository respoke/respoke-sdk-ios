//
//  RespokeDirectConnection.h+private.h
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

#import "RespokeDirectConnection.h"
#import "RespokeSignalingChannel.h"


@class RespokeCall;
@class RTCPeerConnection;
@class RTCDataChannel;


@interface RespokeDirectConnection (private)


/**
 *  Initialize a new direct connection instance
 *
 *  @param call The call implementing the direct connection
 *
 *  @return The newly initialized instance
 */
- (instancetype)initWithCall:(RespokeCall*)call;


/**
 *  Notify the direct connection instance that the peer connection has opened the specified data channel
 *
 *  @param dataChannel    The dataChannel that has opened
 */
- (void)peerConnectionDidOpenDataChannel:(RTCDataChannel *)dataChannel;


/**
 *  Establish a new direct connection instance with the peer connection for the call
 */
- (void)createDataChannel;


@end