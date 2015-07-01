//
//  RespokeCall.m
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

#import "RespokeCall+private.h"
#import "RespokeMediaStats+private.h"
#import "RespokeEndpoint+private.h"
#import "Respoke+private.h"
#import "RespokeDirectConnection+private.h"
#import <AVFoundation/AVFoundation.h>
#import "RTCICECandidate.h"
#import "RTCICEServer.h"
#import "RTCMediaConstraints.h"
#import "RTCMediaStream.h"
#import "RTCPair.h"
#import "RTCPeerConnection.h"
#import "RTCPeerConnectionDelegate.h"
#import "RTCPeerConnectionFactory.h"
#import "RTCSessionDescription.h"
#import "RTCSessionDescriptionDelegate.h"
#import "RTCStatsDelegate.h"
#import "RTCVideoCapturer.h"
#import "RTCVideoSource.h"
#import "RTCVideoTrack.h"
#import "RTCAudioTrack.h"
#import "RTCEAGLVideoView.h"
#import "RTCMediaStreamTrack.h"
#import "RTCStatsReport.h"


#define USE_FRONT_FACING_CAMERA_BY_DEFAULT YES


@interface RespokeCall () <RTCPeerConnectionDelegate, RTCSessionDescriptionDelegate, RTCStatsDelegate, RTCEAGLVideoViewDelegate> {
    BOOL isConnected; ///< Whether or not we have a connection established
    RespokeSignalingChannel *signalingChannel;  ///< The signaling channel to use
    NSMutableArray *iceServers;  ///< The ICE servers to evaluate
    RTCPeerConnection* peerConnection;  ///< The WebRTC peer connection to use
    NSMutableArray* queuedRemoteCandidates;  ///< Remote ICE candidates that need to be evaluated
    NSMutableArray *queuedLocalCandidates;  ///< Local ICE candidates that need to be evaluated
    RTCEAGLVideoView* localVideoView;  ///< The WebRTC extension for displaying the local video stream
    RTCEAGLVideoView* remoteVideoView;  ///< The WebRTC extension for displaying the remote video stream
    CGSize _localVideoSize;  ///< The local video dimensions
    CGSize _remoteVideoSize;  ///< The remote video dimensions
    BOOL caller;  ///< Indicates that the call was initiated locally
    BOOL waitingForAnswer;  ///< Indicates that the call is currently waiting for the remote endpoint to answer
    NSDictionary *incomingSDP;  ///< The SDP data received from the remote endpoint
    NSString *sessionID;  ///< The session ID of the call
    NSString *toConnection;  ///< The connectionID with which the call is taking place
    RespokeEndpoint __weak *endpoint;  ///< The endpoint with which the call is taking place
    NSString *toEndpointID; ///< The endpointID used as the signaling destination
    NSString *toType; ///< The destination type used as the signaling destination
    BOOL audioOnly;  ///< Indicates that the call only supports audio
    BOOL directConnectionOnly;  ///< Indicates that this call is only for a direct connection
    RespokeDirectConnection *directConnection;  ///< The direct connection associated with this call
    RTCVideoTrack* localVideoTrack; ///< Set when call is started or answered
    RTCVideoTrack* remoteVideoTrack; ///< Set when a remote stream is added
    BOOL audioIsMuted;  ///< Indicates if the local audio has been muted
    NSMutableArray *remoteMediaStreams; ///< Array of remote media streams, set when remote streams are added

    // Data members for statistics
    RTCICEGatheringState iceGatheringState; ///< Updated with the ICE gather state changes
    RTCICEConnectionState iceConnectionState; ///< Updated when the ICE connection state changes
    RespokeMediaStats *oldMediaStats; ///< Needed to calculate time differences and accumulate stats
    id <RespokeMediaStatsDelegate> __weak statsDelegate; ///< The delegate for stats
    NSTimeInterval statsInterval; ///< The stats interval in seconds (floating point)
    NSTimer *statsTimer; ///< The timer used to kick off statistics

}

@end


@implementation RespokeCall

static RTCPeerConnectionFactory* peerConnectionFactory = nil;  ///< The WebRTC peer connection factory to use

@synthesize audioOnly;


- (instancetype)initWithSignalingChannel:(RespokeSignalingChannel*)channel incomingCallSDP:(NSDictionary*)sdp sessionID:(NSString*)newID connectionID:(NSString*)newConnectionID endpoint:(RespokeEndpoint*)newEndpoint endpointID:(NSString*)endpointID type:(NSString*)type audioOnly:(BOOL)newAudioOnly directConnectionOnly:(BOOL)dcOnly timestamp:(NSDate*)timestamp isCaller:(BOOL)isCaller
{
    if (self = [super init])
    {
        isConnected = NO;
        caller = isCaller;
        signalingChannel = channel;
        iceServers = [[NSMutableArray alloc] init];
        queuedLocalCandidates = [[NSMutableArray alloc] init];
        queuedRemoteCandidates = [[NSMutableArray alloc] init];
        
        if (peerConnectionFactory == nil) {
            [RTCPeerConnectionFactory initializeSSL];
            peerConnectionFactory = [[RTCPeerConnectionFactory alloc] init];
        }
        
        sessionID = [Respoke makeGUID];
        [signalingChannel.delegate callCreated:self];

        audioOnly = newAudioOnly;
        incomingSDP = sdp;
        sessionID = newID;
        endpoint = newEndpoint;
        toEndpointID = (endpointID != nil) ? endpointID : endpoint.endpointID;
        toType = (type != nil) ? type : @"web";
        toConnection = newConnectionID;
        directConnectionOnly = dcOnly;
        _timestamp = timestamp;
        remoteMediaStreams = [[NSMutableArray alloc] init];

        if (directConnectionOnly)
        {
            [self actuallyAddDirectConnection];
        }

        statsTimer = nil;
        statsInterval = 1.0; // initialize to one second

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive) name:UIApplicationWillResignActiveNotification object:nil];
    }

    return self;
}


- (instancetype)initWithSignalingChannel:(RespokeSignalingChannel*)channel endpoint:(RespokeEndpoint*)newEndpoint audioOnly:(BOOL)newAudioOnly directConnectionOnly:(BOOL)dcOnly
{
    return [self initWithSignalingChannel:channel incomingCallSDP:nil sessionID:[Respoke makeGUID] connectionID:nil endpoint:newEndpoint endpointID:nil type:nil audioOnly:newAudioOnly directConnectionOnly:dcOnly timestamp:[NSDate date] isCaller:YES];
}


- (instancetype)initWithSignalingChannel:(RespokeSignalingChannel*)channel incomingCallSDP:(NSDictionary*)sdp sessionID:(NSString*)newID connectionID:(NSString*)newConnectionID endpoint:(RespokeEndpoint*)newEndpoint directConnectionOnly:(BOOL)dcOnly timestamp:(NSDate*)timestamp
{
    BOOL newAudioOnly = sdp && ![RespokeCall sdpHasVideo:[sdp objectForKey:@"sdp"]];
    return [self initWithSignalingChannel:channel incomingCallSDP:sdp sessionID:newID connectionID:newConnectionID endpoint:newEndpoint endpointID:nil type:nil audioOnly:newAudioOnly directConnectionOnly:dcOnly timestamp:timestamp isCaller:NO];
}


- (NSString*)getSessionID
{
    return sessionID;
}


- (RespokeEndpoint*)getRemoteEndpoint
{
    return endpoint;
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];   
}


- (void)applicationWillResignActive
{
    if (peerConnection)
    {
        NSLog(@"Application lost focus, connection broken.");
        [self disconnect];
        [self.delegate onHangup:self];
    }
}


- (void)disconnect 
{
    isConnected = NO;
    [self tryStopStats];

    [peerConnection close];
    peerConnection = nil;
    queuedRemoteCandidates = nil;
    directConnection = nil;

    if (localVideoTrack) {
        [localVideoTrack removeRenderer:localVideoView];
        localVideoTrack = nil;
        [localVideoView renderFrame:nil];
   }

   if (remoteVideoTrack) {
        [remoteVideoTrack removeRenderer:remoteVideoView];
        remoteVideoTrack = nil;
        [remoteVideoView renderFrame:nil];
    }

    [remoteVideoView removeFromSuperview];
    [localVideoView removeFromSuperview];
    remoteVideoView = nil;
    localVideoView = nil;
    self.remoteView = nil;
    self.localView = nil;
    [signalingChannel.delegate callTerminated:self];
}


- (void)startCall
{
    waitingForAnswer = YES;

    if (directConnectionOnly)
    {
        [self directConnectionDidAccept:directConnection];
    }
    else
    {
        [self getTurnServerCredentialsWithSuccessHandler:^(void){
            [self initializePeerConnection];
            [self addLocalStreams:USE_FRONT_FACING_CAMERA_BY_DEFAULT];
            [self createOffer];
        } errorHandler:^(NSString *errorMessage){
            [self.delegate onError:errorMessage sender:self];
        }];
    }
}


- (void)answer
{
    if (!caller)
    {
        [self getTurnServerCredentialsWithSuccessHandler:^(void){
            [self initializePeerConnection];
            [self addLocalStreams:USE_FRONT_FACING_CAMERA_BY_DEFAULT];
            [self processRemoteSDP];
        } errorHandler:^(NSString *errorMessage){
            [self.delegate onError:errorMessage sender:self];
        }];
    }
}


- (void)hangup:(BOOL)shouldSendHangupSignal
{
    if (shouldSendHangupSignal)
    {
        NSDictionary *signalData = @{@"signalType": @"bye", @"target": directConnectionOnly ? @"directConnection" : @"call", @"sessionId": sessionID, @"signalId": [Respoke makeGUID], @"version": @"1.0"};
        
        [signalingChannel sendSignalMessage:signalData toEndpointID:toEndpointID toConnectionID:nil toType:toType successHandler:^(){
            [self.delegate onHangup:self];
        } errorHandler:^(NSString *errorMessage) {
            [self.delegate onError:errorMessage sender:self];
        }];
    }

    [self disconnect];
}


- (BOOL)hasAudio:(NSArray*)mediaStreams
{
    for (RTCMediaStream *eachStream in mediaStreams)
    {
        for (RTCAudioTrack *eachTrack in eachStream.audioTracks)
        {
            if (eachTrack.state ==  RTCSourceStateLive)
            {
                return YES;
            }
        }
    }
    return NO;
}


- (BOOL)hasVideo:(NSArray*)mediaStreams
{
    for (RTCMediaStream *eachStream in mediaStreams)
    {
        for (RTCVideoTrack *eachTrack in eachStream.videoTracks)
        {
            if (eachTrack.state ==  RTCSourceStateLive)
            {
                return YES;
            }
        }
    }
    return NO;
}


- (BOOL)hasMedia
{
    return [self hasAudio] || [self hasVideo];
}


- (BOOL)hasAudio
{
    return [self hasAudio:peerConnection.localStreams] || [self hasAudio:remoteMediaStreams];
}


- (BOOL)hasVideo
{
    return [self hasVideo:peerConnection.localStreams] || [self hasVideo:remoteMediaStreams];
}


- (void)muteVideo:(BOOL)mute
{
    if (!self.audioOnly)
    {
        for (RTCMediaStream *eachStream in peerConnection.localStreams)
        {
            for (RTCMediaStreamTrack *eachTrack in eachStream.videoTracks)
            {
                [eachTrack setEnabled:!mute];
            }
        }
    }
}


- (BOOL)videoIsMuted
{
    BOOL isMuted = YES;

    if (!self.audioOnly)
    {
        for (RTCMediaStream *eachStream in peerConnection.localStreams)
        {
            for (RTCMediaStreamTrack *eachTrack in eachStream.videoTracks)
            {
                if ([eachTrack isEnabled])
                {
                    isMuted = NO;
                }
            }
        }
    }

    return isMuted;
}


- (void)muteAudio:(BOOL)mute
{
    audioIsMuted = mute;

    for (RTCMediaStream *eachStream in peerConnection.localStreams)
    {
        for (RTCMediaStreamTrack *eachTrack in eachStream.audioTracks)
        {
            [eachTrack setEnabled:!mute];
        }
    }
}


- (BOOL)audioIsMuted
{
    BOOL isMuted = YES;

    for (RTCMediaStream *eachStream in peerConnection.localStreams)
    {
        for (RTCMediaStreamTrack *eachTrack in eachStream.audioTracks)
        {
            if ([eachTrack isEnabled])
            {
                isMuted = NO;
            }
        }
    }

    return isMuted;
}


- (void)switchVideoSource:(BOOL)useFrontFacingCamera
{
#if !TARGET_IPHONE_SIMULATOR && TARGET_OS_IPHONE
    if (!self.audioOnly)
    {
        // Find the existing local media stream
        RTCMediaStream *localMediaStream = [peerConnection.localStreams firstObject];

        if (localMediaStream)
        {
            // Stop rendering the local video
            [localVideoTrack removeRenderer:localVideoView];
            [localVideoView renderFrame:nil];

            [peerConnection removeStream:localMediaStream];

            // Recreate the local video and audio streams. This will trigger an SDP renegotiation although it's not necessary since the resulting streams have the same properties so it will be ignored.
            [self addLocalStreams:useFrontFacingCamera];
        }
    }
#endif
}


- (void)hangupReceived
{
    [self disconnect];
    [self.delegate onHangup:self];
}


- (void)answerReceived:(NSDictionary*)remoteSDP fromConnection:(NSString*)remoteConnection
{
    incomingSDP = remoteSDP;
    toConnection = remoteConnection;

    NSDictionary *signalData = @{@"signalType": @"connected", @"target": directConnectionOnly ? @"directConnection" : @"call", @"connectionId": toConnection, @"sessionId": sessionID, @"signalId": [Respoke makeGUID], @"version": @"1.0"};

    [signalingChannel sendSignalMessage:signalData toEndpointID:toEndpointID toConnectionID:nil toType:toType successHandler:^(){
        [self processRemoteSDP];
        [self.delegate onConnected:self];
        isConnected = YES;
        [self tryStartStats];
    } errorHandler:^(NSString *errorMessage) {
        [self.delegate onError:errorMessage sender:self];
    }];
}


- (void)connectedReceived
{
    [self.delegate onConnected:self];
    isConnected = YES;
    [self tryStartStats];
}


- (void)iceCandidatesReceived:(NSArray*)candidates
{
    for (NSDictionary *eachCandidate in candidates)
    {
        NSString* mid = [eachCandidate objectForKey:@"sdpMid"];
        NSNumber* sdpLineIndex = [eachCandidate objectForKey:@"sdpMLineIndex"];
        NSString* sdp = [eachCandidate objectForKey:@"candidate"];

        RTCICECandidate* rtcCandidate = [[RTCICECandidate alloc] initWithMid:mid index:sdpLineIndex.intValue sdp:sdp];

        if (queuedRemoteCandidates)
        {
            [queuedRemoteCandidates addObject:rtcCandidate];
        }
        else
        {
            [peerConnection addICECandidate:rtcCandidate];
        }
    }
}


- (BOOL)isCaller
{
    return caller;
}


- (void)getStatsWithDelegate:(id <RespokeMediaStatsDelegate>)delegate atInterval:(NSTimeInterval)interval
{
    statsDelegate = delegate;
    statsInterval = interval;
    [self tryStartStats];
}


- (void)stopStats
{
    statsDelegate = nil;
    [self tryStopStats];
}


- (RTCPeerConnection*)getPeerConnection
{
    return peerConnection;
}


- (void)processRemoteSDP
{
    NSString *type = [incomingSDP objectForKey:@"type"];
    NSString *sdpString = [incomingSDP objectForKey:@"sdp"];

    if (type && sdpString)
    {
        RTCSessionDescription *sdp = [[RTCSessionDescription alloc] initWithType:type sdp:[[self class] preferISAC:sdpString]];
        [peerConnection setRemoteDescriptionWithDelegate:self sessionDescription:sdp];
    }
    else
    {
        [self.delegate onError:@"Invalid call sdp" sender:self];
    }
}


- (void)getTurnServerCredentialsWithSuccessHandler:(void (^)(void))successHandler errorHandler:(void (^)(NSString*))errorHandler
{
    // get TURN server credentials
    [signalingChannel sendRESTMessage:@"get" url:@"/v1/turn" data:nil responseHandler:^(id response, NSString *errorMessage) {
        if (errorMessage)
        {
            errorHandler(errorMessage);
        }
        else
        {
            if ([response isKindOfClass:[NSDictionary class]])
            {
                NSString *username = [response objectForKey:@"username"];
                NSString *password = [response objectForKey:@"password"];
                NSArray *uris = [response objectForKey:@"uris"];

                for (NSString *eachUri in uris)
                {
                    RTCICEServer* server = [[RTCICEServer alloc] initWithURI:[NSURL URLWithString:eachUri] username:username password:password];
                    [iceServers addObject:server];
                }

                if ([iceServers count] > 0)
                {
                    successHandler();
                }
                else
                {
                    errorHandler(@"No ICE servers were found");
                }
            }
            else
            {
                errorHandler(@"Unexpected response from server");
            }
        }
    }];
}


- (void)initializePeerConnection
{
    RTCMediaConstraints* constraints = nil;
    
    constraints = [[RTCMediaConstraints alloc]
                    initWithMandatoryConstraints:@[[[RTCPair alloc] initWithKey:@"OfferToReceiveAudio" value:directConnectionOnly ? @"false" : @"true"],
                                                   [[RTCPair alloc] initWithKey:@"OfferToReceiveVideo" value:(directConnectionOnly || self.audioOnly) ? @"false" : @"true"]]
                    optionalConstraints:@[[[RTCPair alloc] initWithKey:@"internalSctpDataChannels" value:@"true"],
                                          [[RTCPair alloc] initWithKey:@"DtlsSrtpKeyAgreement" value:@"true"]]];
    
    peerConnection = [peerConnectionFactory peerConnectionWithICEServers:iceServers constraints:constraints delegate:self];
}


- (void)addLocalStreams:(BOOL)useFrontFacingCamera
{
    RTCMediaStream* lms = [peerConnectionFactory mediaStreamWithLabel:@"ARDAMS"];

    if (!self.audioOnly)
    {
        // If they don't already exist, fill the remote and local video views with special OpenGL views to render the video streams
        if (!remoteVideoView)
        {
            remoteVideoView = [[RTCEAGLVideoView alloc] initWithFrame:self.remoteView.bounds];
            remoteVideoView.delegate = self;
            [self.remoteView addSubview:remoteVideoView];
        }

        if (!localVideoView)
        {
            localVideoView = [[RTCEAGLVideoView alloc] initWithFrame:self.localView.bounds];
            localVideoView.delegate = self;
            [self.localView addSubview:localVideoView];

            [self updateVideoViewLayout];
        }
        
        // The iOS simulator doesn't provide any sort of camera capture
        // support or emulation (http://goo.gl/rHAnC1) so don't bother
        // trying to open a local stream.

        // TODO(tkchin): local video capture for OSX. See
        // https://code.google.com/p/webrtc/issues/detail?id=3417.
#if !TARGET_IPHONE_SIMULATOR && TARGET_OS_IPHONE
        NSString* cameraID = nil;

        for (AVCaptureDevice* captureDevice in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) 
        {
            if (useFrontFacingCamera && (captureDevice.position == AVCaptureDevicePositionFront))
            {
                cameraID = [captureDevice localizedName];
                break;
            }
            else if (!useFrontFacingCamera && (captureDevice.position != AVCaptureDevicePositionFront))
            {
                cameraID = [captureDevice localizedName];
                break;   
            }
        }

        NSAssert(cameraID, @"Unable to get the front camera id");

        RTCVideoCapturer* capturer = [RTCVideoCapturer capturerWithDeviceName:cameraID];
        RTCVideoSource* videoSource = [peerConnectionFactory videoSourceWithCapturer:capturer constraints:nil];
        localVideoTrack = [peerConnectionFactory videoTrackWithID:@"ARDAMSv0" source:videoSource];

        if (localVideoTrack) 
        {
            [lms addVideoTrack:localVideoTrack];
        }

        [localVideoTrack addRenderer:localVideoView];
#endif
    }

    RTCAudioTrack* audioTrack = [peerConnectionFactory audioTrackWithID:@"ARDAMSa0"];

    if (audioIsMuted)
    {
        // If the user has already commanded that the audio be muted, do so now
        [audioTrack setEnabled:!audioIsMuted];
    }

    [lms addAudioTrack:audioTrack];
    [peerConnection addStream:lms];
}


- (void)createOffer
{
    RTCPair* audio = [[RTCPair alloc] initWithKey:@"OfferToReceiveAudio" value:directConnectionOnly ? @"false" : @"true"];
    RTCPair* video = [[RTCPair alloc] initWithKey:@"OfferToReceiveVideo" value:(directConnectionOnly || self.audioOnly) ? @"false" : @"true"];
    NSArray* mandatory = @[ audio, video ];
    RTCMediaConstraints* constraints = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:mandatory optionalConstraints:nil];
    
    [peerConnection createOfferWithDelegate:self constraints:constraints];
}


- (void)updateVideoViewLayout
{
    CGSize defaultAspectRatio = CGSizeMake(4, 3);
    CGSize localAspectRatio = CGSizeEqualToSize(_localVideoSize, CGSizeZero) ? defaultAspectRatio : _localVideoSize;
    CGSize remoteAspectRatio = CGSizeEqualToSize(_remoteVideoSize, CGSizeZero) ? defaultAspectRatio : _remoteVideoSize;

    CGRect remoteVideoFrame = AVMakeRectWithAspectRatioInsideRect(remoteAspectRatio, self.remoteView.bounds);
    remoteVideoView.frame = remoteVideoFrame;

    CGRect localVideoFrame = AVMakeRectWithAspectRatioInsideRect(localAspectRatio, self.localView.bounds);
    localVideoView.frame = localVideoFrame;
}


- (void)actuallyAddDirectConnection
{
    if ((directConnection) && ([directConnection isActive]))
    {
        NSLog(@"Not creating a new direct connection.");
    }
    else
    {
        directConnection = [[RespokeDirectConnection alloc] initWithCall:self];
        [endpoint setDirectConnection:directConnection];
        
        [self.delegate directConnectionAvailable:directConnection endpoint:endpoint];
        
        if (directConnectionOnly && !caller)
        {
            // Inform the client that a remote endpoint is attempting to open a direct connection
            [signalingChannel.delegate directConnectionAvailable:directConnection endpoint:endpoint];
        }
    }
}


- (void)directConnectionDidAccept:(RespokeDirectConnection*)sender
{
    [self getTurnServerCredentialsWithSuccessHandler:^(void){
        [self initializePeerConnection];

        if (caller)
        {
            [directConnection createDataChannel];
            [self createOffer];
        }
        else
        {
            [self processRemoteSDP];
        }
    } errorHandler:^(NSString *errorMessage){
        [self.delegate onError:errorMessage sender:self];
    }];
}


- (void)directConnectionDidOpen:(RespokeDirectConnection*)sender
{
    
}


- (void)directConnectionDidClose:(RespokeDirectConnection*)sender
{
    if (sender == directConnection)
    {
        directConnection = nil;
        [endpoint setDirectConnection:nil];
    }
}


- (void)tryStartStats
{
    // ensure we start/stop timer on the same thread
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!statsTimer && statsDelegate && isConnected)
        {
            statsTimer = [NSTimer scheduledTimerWithTimeInterval:statsInterval target:self selector:@selector(requestStats:) userInfo:nil repeats:YES];
        }
    });
}


- (void)tryStopStats
{
    // ensure we start/stop timer on the same thread
    dispatch_async(dispatch_get_main_queue(), ^{
        if (statsTimer)
        {
            [statsTimer invalidate];
            statsTimer = nil;
        }
    });
}


- (void)requestStats:(NSTimer*)timer
{
    RTCMediaStreamTrack *track = (RTCMediaStreamTrack*)timer.userInfo;
    [peerConnection getStatsWithDelegate:self mediaStreamTrack:track statsOutputLevel:RTCStatsOutputLevelDebug];
}


#pragma mark - RTCEAGLVideoViewDelegate


- (void)videoView:(RTCEAGLVideoView*)videoView didChangeVideoSize:(CGSize)size 
{
    if (videoView == localVideoView) 
    {
        _localVideoSize = size;
    } 
    else if (videoView == remoteVideoView) 
    {
        _remoteVideoSize = size;
    } 
    else 
    {
        NSLog(@"Could not update video view layout because the view references have not been added to the call in time");
    }

    [self updateVideoViewLayout];
}


#pragma mark - RTCPeerConnectionDelegate


- (void)peerConnection:(RTCPeerConnection*)peerConnection signalingStateChanged:(RTCSignalingState)stateChanged 
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"PCO onSignalingStateChange: %d", stateChanged);
    });
}


- (void)peerConnection:(RTCPeerConnection*)peerConnection addedStream:(RTCMediaStream*)stream 
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"PCO onAddStream.");
        NSAssert([stream.audioTracks count] == 1 || [stream.videoTracks count] == 1, @"Expected audio or video track");
        NSAssert([stream.audioTracks count] <= 1, @"Expected at most 1 audio stream");
        NSAssert([stream.videoTracks count] <= 1, @"Expected at most 1 video stream");

        if ([stream.videoTracks count] != 0) 
        {
            //remoteVideoView.videoTrack = stream.videoTracks[0];
            remoteVideoTrack = stream.videoTracks[0];
            [remoteVideoTrack addRenderer:remoteVideoView];
        }
        [remoteMediaStreams addObject:stream];
    });
}


- (void)peerConnection:(RTCPeerConnection*)peerConnection removedStream:(RTCMediaStream*)stream 
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"PCO onRemoveStream.");
        [remoteMediaStreams removeObject:stream];
    });
}


- (void)peerConnectionOnRenegotiationNeeded:(RTCPeerConnection*)peerConnection 
{
    //dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"PCO onRenegotiationNeeded");
    //});
}


- (void)peerConnection:(RTCPeerConnection*)peerConnection gotICECandidate:(RTCICECandidate*)candidate 
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"PCO onICECandidate.\n  Mid[%@] Index[%li] Sdp[%@]", candidate.sdpMid, (long)candidate.sdpMLineIndex, candidate.sdp);

        if (caller && waitingForAnswer)
        {
            [queuedLocalCandidates addObject:candidate];
        }
        else
        {
            [self sendLocalCandidate:candidate];
        }
    });
}


- (void)peerConnection:(RTCPeerConnection*)peerConnection iceGatheringChanged:(RTCICEGatheringState)newState 
{
    dispatch_async(dispatch_get_main_queue(), ^{ 
        NSLog(@"PCO onIceGatheringChange. %d", newState);
        iceGatheringState = newState;
    });
}


- (void)peerConnection:(RTCPeerConnection*)peerConnection iceConnectionChanged:(RTCICEConnectionState)newState 
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"PCO onIceConnectionChange. %d", newState);

        iceConnectionState = newState;
        if (newState == RTCICEConnectionConnected)
        {
            NSLog(@"ICE Connection Connected.");
        }
        else if (newState == RTCICEConnectionFailed)
        {
            [self.delegate onError:@"ICE Connection failed!" sender:self];
            [self disconnect];
            [self.delegate onHangup:self];
            self.delegate = nil;
        }
    });
}


- (void)peerConnection:(RTCPeerConnection*)peerConnection didOpenDataChannel:(RTCDataChannel*)dataChannel 
{
    if (directConnection)
    {
        [directConnection peerConnectionDidOpenDataChannel:dataChannel];
    }
    else
    {
        NSLog(@"Direct connection opened, but no object to handle it!");
    }
}


#pragma mark - RTCSessionDescriptionDelegate


- (void)peerConnection:(RTCPeerConnection*)thePeerConnection didCreateSessionDescription:(RTCSessionDescription*)origSdp error:(NSError*)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (error) 
        {
            [self.delegate onError:@"SDP didCreateSessionDescription onFailure." sender:self];
        }
        else
        {
            NSLog(@"SDP onSuccess(SDP) - set local description.");
            RTCSessionDescription* sdp = [[RTCSessionDescription alloc] initWithType:origSdp.type sdp:[[self class] preferISAC:origSdp.description]];
            [thePeerConnection setLocalDescriptionWithDelegate:self sessionDescription:sdp];
            NSLog(@"PC setLocalDescription.");

            NSDictionary *signalData = @{@"signalType": sdp.type, @"target": directConnectionOnly ? @"directConnection" : @"call", @"sessionId": sessionID, @"sessionDescription": @{@"sdp": sdp.description, @"type": sdp.type}, @"signalId": [Respoke makeGUID], @"version": @"1.0"};
    
            [signalingChannel sendSignalMessage:signalData toEndpointID:toEndpointID toConnectionID:nil toType:toType successHandler:^(){
                // Do nothing
            } errorHandler:^(NSString *errorMessage) {
                [self.delegate onError:errorMessage sender:self];
            }];
        }
    });
}


- (void)peerConnection:(RTCPeerConnection*)thePeerConnection didSetSessionDescriptionWithError:(NSError*)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (error) 
        {
            [self.delegate onError:[error localizedDescription] sender:self];
        }
        else
        {
            NSLog(@"SDP onSuccess() - possibly drain candidates");

            if (caller) 
            {
                if (peerConnection.remoteDescription) 
                {
                    NSLog(@"SDP onSuccess - drain candidates");
                    waitingForAnswer = NO;
                    [self drainRemoteCandidates];
                    [self drainLocalCandidates];
                }
            }
            else
            {
                if (thePeerConnection.remoteDescription && !thePeerConnection.localDescription)
                {
                    NSLog(@"Callee, setRemoteDescription succeeded");
                    RTCPair* audio = [[RTCPair alloc] initWithKey:@"OfferToReceiveAudio" value:@"true"];
                    RTCPair* video = [[RTCPair alloc] initWithKey:@"OfferToReceiveVideo" value:audioOnly ? @"false" : @"true"];
                    NSArray* mandatory = @[ audio, video ];
                    RTCMediaConstraints* constraints = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:mandatory optionalConstraints:nil];
                    [thePeerConnection createAnswerWithDelegate:self constraints:constraints];
                    NSLog(@"PC - createAnswer.");
                } 
                else
                {
                    NSLog(@"SDP onSuccess - drain candidates");
                    [self drainRemoteCandidates];
                }
            } 
        }
    });
}


- (void)drainRemoteCandidates 
{
    for (RTCICECandidate* candidate in queuedRemoteCandidates) 
    {
        [peerConnection addICECandidate:candidate];
    }

    queuedRemoteCandidates = nil;
}


- (void)drainLocalCandidates
{
    for (RTCICECandidate* candidate in queuedLocalCandidates) 
    {
        [self sendLocalCandidate:candidate];
    }   
}


- (void)sendLocalCandidate:(RTCICECandidate*)candidate
{
    NSDictionary *candidateDict = @{@"sdpMLineIndex": [NSNumber numberWithInteger:candidate.sdpMLineIndex], @"sdpMid": candidate.sdpMid, @"candidate": candidate.sdp};
    NSDictionary *signalData = @{@"signalType": @"iceCandidates", @"target": directConnectionOnly ? @"directConnection" : @"call", @"iceCandidates": @[candidateDict], @"sessionId": sessionID, @"signalId": [Respoke makeGUID], @"version": @"1.0"};
    
    [signalingChannel sendSignalMessage:signalData toEndpointID:toEndpointID toConnectionID:nil toType:toType successHandler:^(){
        // Do nothing
    } errorHandler:^(NSString *errorMessage) {
        [self.delegate onError:errorMessage sender:self];
    }];
}


#pragma mark - RTCStatsDelegate methods


- (void)peerConnection:(RTCPeerConnection*)peerConnection didGetStats:(NSArray*)stats
{
    if (statsDelegate)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            RespokeMediaStats *mediaStats = [[RespokeMediaStats alloc] initWithData:stats iceGatheringState:iceGatheringState iceConnectionState:iceConnectionState timestamp:[NSDate date] oldMediaStats:oldMediaStats];
            [statsDelegate onStats:mediaStats];
            oldMediaStats = mediaStats;
        });
    }
}


#pragma mark - misc


// Mangle |origSDP| to prefer the ISAC/16k audio codec.
+ (NSString*)preferISAC:(NSString*)origSDP 
{
    int mLineIndex = -1;
    NSString* isac16kRtpMap = nil;
    NSArray* lines = [origSDP componentsSeparatedByString:@"\n"];
    NSRegularExpression* isac16kRegex = [NSRegularExpression regularExpressionWithPattern:@"^a=rtpmap:(\\d+) ISAC/16000[\r]?$" options:0 error:nil];

    for (int i = 0; (i < [lines count]) && (mLineIndex == -1 || isac16kRtpMap == nil); ++i) 
    {
        NSString* line = [lines objectAtIndex:i];

        if ([line hasPrefix:@"m=audio "]) 
        {
            mLineIndex = i;
            continue;
        }

        isac16kRtpMap = [self firstMatch:isac16kRegex withString:line];
    }
    
    if (mLineIndex == -1) 
    {
        NSLog(@"No m=audio line, so can't prefer iSAC");
        return origSDP;
    }
    
    if (isac16kRtpMap == nil) 
    {
        NSLog(@"No ISAC/16000 line, so can't prefer iSAC");
        return origSDP;
    }

    NSArray* origMLineParts = [[lines objectAtIndex:mLineIndex] componentsSeparatedByString:@" "];
    NSMutableArray* newMLine = [NSMutableArray arrayWithCapacity:[origMLineParts count]];
    int origPartIndex = 0;

    // Format is: m=<media> <port> <proto> <fmt> ...
    [newMLine addObject:[origMLineParts objectAtIndex:origPartIndex++]];
    [newMLine addObject:[origMLineParts objectAtIndex:origPartIndex++]];
    [newMLine addObject:[origMLineParts objectAtIndex:origPartIndex++]];
    [newMLine addObject:isac16kRtpMap];

    for (; origPartIndex < [origMLineParts count]; ++origPartIndex) 
    {
        if (![isac16kRtpMap isEqualToString:[origMLineParts objectAtIndex:origPartIndex]]) 
        {
            [newMLine addObject:[origMLineParts objectAtIndex:origPartIndex]];
        }
    }

    NSMutableArray* newLines = [NSMutableArray arrayWithCapacity:[lines count]];
    [newLines addObjectsFromArray:lines];
    [newLines replaceObjectAtIndex:mLineIndex withObject:[newMLine componentsJoinedByString:@" "]];
    return [newLines componentsJoinedByString:@"\n"];
}


// Match |pattern| to |string| and return the first group of the first
// match, or nil if no match was found.
+ (NSString*)firstMatch:(NSRegularExpression*)pattern withString:(NSString*)string 
{
    NSTextCheckingResult* result = [pattern firstMatchInString:string options:0 range:NSMakeRange(0, [string length])];
    
    if (!result)
        return nil;

    return [string substringWithRange:[result rangeAtIndex:1]];
}


+ (BOOL)sdpHasVideo:(NSString*)sdp
{
    return sdp && [sdp rangeOfString:@"m=video"].location != NSNotFound;
}


@end
