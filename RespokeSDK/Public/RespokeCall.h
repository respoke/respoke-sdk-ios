//
//  RespokeCall.h
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

#import <UIKit/UIKit.h>


@protocol RespokeCallDelegate;
@protocol RespokeMediaStatsDelegate;
@class RespokeEndpoint;
@class RespokeDirectConnection;


/**
 *  WebRTC Call including getUserMedia, path and codec negotation, and call state.
 */
@interface RespokeCall : NSObject


/**
 *  The delegate that should receive notifications from the RespokeCallDelegate protocol
 */
@property (weak) id <RespokeCallDelegate> delegate;


/**
 *  The UIView on which to display the local video for the call
 */
@property (weak) UIView *localView;


/**
 *  The UIView on which to display the remote video for the call
 */
@property (weak) UIView *remoteView;


/**
 *  Indicates that the call only supports audio
 */
@property (readonly) BOOL audioOnly;


/**
 *  The call timestamp
 */
@property (readonly) NSDate *timestamp;


/**
 *  Answer the call and start the process of obtaining media. This method is called automatically on the caller's
 *  side. This method must be called on the callee's side to indicate that the endpoint does wish to accept the
 *  call. The app will have a later opportunity, by passing a callback named previewLocalMedia, to approve or
 *  reject the call based on whether audio and/or video is working and is working at an acceptable level.
 */
- (void)answer;


/**
 *  Tear down the call, release user media.
 *
 *  @param shouldSendHangupSignal Send a hangup signal to the remote party if signal is not false and we have not received a hangup signal from the remote party.
 */
- (void)hangup:(BOOL)shouldSendHangupSignal;


/**
 *  Indicate whether the call has media flowing.
 *
 *  @return YES if call has audio or video flowing.
 */
- (BOOL)hasMedia;


/**
 *  Indicate whether the call has audio flowing.
 *
 *  @return YES if call has audio flowing.
 */
- (BOOL)hasAudio;


/**
 *  Indicate whether the call has video flowing.
 *
 *  @return YES if call has video flowing.
 */
- (BOOL)hasVideo;


/**
 *  Mute or unmute the local video
 *
 *  @param mute If true, mute the video. If false, unmute the video
 */
- (void)muteVideo:(BOOL)mute;


/**
 *  Indicates if the local video stream is muted
 *
 *  @return returns true if the local video stream is currently muted
 */
- (BOOL)videoIsMuted;


/**
 *  Mute or unmute the local audio
 *
 *  @param mute If true, mute the audio. If false, unmute the audio
 */
- (void)muteAudio:(BOOL)mute;


/**
 *  Indicates if the local audio stream is muted
 *
 *  @return returns true if the local audio stream is currently muted
 */
- (BOOL)audioIsMuted;


/**
 *  Change which physical camera is used as the video source for the call
 *
 *  @param useFrontFacingCamera Uses the front-facing camera when true, back-facing camera when false
 */
- (void)switchVideoSource:(BOOL)useFrontFacingCamera;


/**
 *  Get the remote endpoint with which the call is taking place
 */
- (RespokeEndpoint*)getRemoteEndpoint;


/**
 *  Indicates if the local client initiated the call
 */
- (BOOL)isCaller;


/**
 *  Start gathering statistics. Statistics will be delivered to the delegate
 *  once a connection is established.
 *
 *  Call stopStats to stop gathering statistics.
 *
 *  @param delegate The stats delegate
 *  @param interval The interval at which to deliver stats in seconds
 */
- (void)getStatsWithDelegate:(id <RespokeMediaStatsDelegate>)delegate atInterval:(NSTimeInterval)interval;


/**
 *  Stop gathering statistics.
 */
- (void)stopStats;


@end


/**
 *  A delegate protocol to notify the receiver of events occurring with the call
 */
@protocol RespokeCallDelegate <NSObject>


/**
 *  Receive a notification that an error has occurred while on a call
 *
 *  @param errorMessage A human-readable description of the error.
 *  @param sender       The RespokeCall that experienced the error
 */
- (void)onError:(NSString*)errorMessage sender:(RespokeCall*)sender;


/**
 *  When on a call, receive notification the call has been hung up
 *
 *  @param sender The RespokeCall that has hung up
 */
- (void)onHangup:(RespokeCall*)sender;


/**
 *  When on a call, receive remote media when it becomes available. This is what you will need to provide if you want
 *  to show the user the other party's video during a call.
 *
 *  @param sender The RespokeCall that has connected
 */
- (void)onConnected:(RespokeCall*)sender;


/**
 *  This event is fired when the local end of the directConnection is available. It still will not be
 *  ready to send and receive messages until the 'open' event fires.
 *
 *  @param directConnection The direct connection object
 *  @param endpoint         The remote endpoint
 *
 */
- (void)directConnectionAvailable:(RespokeDirectConnection*)directConnection endpoint:(RespokeEndpoint*)endpoint;


@end
