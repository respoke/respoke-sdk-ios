//
//  RespokeMediaStats.h
//  RespokeSDK
//
//  Created by Rob Crabtree on 1/15/15.
//  Copyright (c) 2015 Digium, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


/**
 *  ICE connection states
 */
typedef enum
{
    RespokeICEConnectionNew,
    RespokeICEConnectionChecking,
    RespokeICEConnectionConnected,
    RespokeICEConnectionCompleted,
    RespokeICEConnectionFailed,
    RespokeICEConnectionDisconnected,
    RespokeICEConnectionClosed,
} RespokeICEConnectionState;


/**
 *  ICE gathering states
 */
typedef enum
{
    RespokeICEGatheringNew,
    RespokeICEGatheringGathering,
    RespokeICEGatheringComplete,
} RespokeICEGatheringState;


/**
 *  Information about the connection.
 */
@interface RespokeConnectionStats : NSObject

/**
 *  A string which identifies this media stream (which may contain several
 *  media stream tracks) to the browser.
 */
@property (nonatomic, readonly) NSString *channelId;

/**
 *  Whether or not the ICE hole-punching process has found
 *  a suitable network path from this client to the remote party.
 */
@property (nonatomic, readonly) BOOL foundOutgoingNetworkPaths;

/**
 *  Whether or not the ICE hole-punching process has found
 *  a suitable network path from the remote party to this client.
 */
@property (nonatomic, readonly) BOOL foundIncomingNetworkPaths;

/**
 *  Whether the media is flowing via UDP or TCP
 */
@property (nonatomic, readonly) NSString *transport;

/**
 *  The type of network path the local media is taking to the remote
 *  party, one of "local", "srflx", "prflx", "relay".
 */
@property (nonatomic, readonly) NSString *localMediaPath;

/**
 *  The type of network path the local media is taking to the remote
 *  party, one of "local", "srflx", "prflx", "relay".
 */
@property (nonatomic, readonly) NSString *remoteMediaPath;

/**
 *  The remote IP and port number of the media connection.
 */
@property (nonatomic, readonly) NSString *remoteHost;

/**
 *  The local IP and port number of the media connection.
 */
@property (nonatomic, readonly) NSString *localHost;

/**
 *  How long it takes media packets to traverse the network path.
 */
@property (nonatomic, readonly) NSString *roundTripTime;
@end


/**
 *  Information about the local audio stream track.
 */
@interface RespokeLocalAudioStats : NSObject

/**
 *  Microphone volume.
 */
@property (nonatomic, readonly) NSString *audioInputLevel;

/**
 *  Audio codec in use.
 */
@property (nonatomic, readonly) NSString *codec;

/**
 *  Total number of bytes sent since media first began flowing.
 */
@property (nonatomic, readonly) NSInteger totalBytesSent;

/**
 *  Number of bytes sent since the last stats event.
 */
@property (nonatomic, readonly) NSInteger periodBytesSent;

/**
 *  Total number of packets sent since media first began flowing.
 */
@property (nonatomic, readonly) NSInteger totalPacketsSent;

/**
 *  Number of packets sent since the last stats event.
 */
@property (nonatomic, readonly) NSInteger periodPacketsSent;

/**
 *  The identifer of the media stream to which this media stream track belongs.
 */
@property (nonatomic, readonly) NSString *transportId;
@end


/**
 *  Information about the local video stream track.
 */
@interface RespokeLocalVideoStats : NSObject

/**
 *  Video codec in use.
 */
@property (nonatomic, readonly) NSString *codec;

/**
 *  Total number of bytes sent since media first began flowing.
 */
@property (nonatomic, readonly) NSInteger totalBytesSent;

/**
 *  Number of bytes sent since the last stats event.
 */
@property (nonatomic, readonly) NSInteger periodBytesSent;

/**
 *  Total number of packets sent since media first began flowing.
 */
@property (nonatomic, readonly) NSInteger totalPacketsSent;

/**
 *  Number of packets sent since the last stats event.
 */
@property (nonatomic, readonly) NSInteger periodPacketsSent;

/**
 *  The identifer of the media stream to which this media stream track belongs.
 */
@property (nonatomic, readonly) NSString *transportId;
@end


/**
 *  Information about the remote audio stream track.
 */
@interface RespokeRemoteAudioStats : NSObject

/**
 *  The speaker volume.
 */
@property (nonatomic, readonly) NSString *audioOutputLevel;

/**
 *  Total number of bytes received since media first began flowing.
 */
@property (nonatomic, readonly) NSInteger totalBytesReceived;

/**
 *  Number of bytes received since the last stats event.
 */
@property (nonatomic, readonly) NSInteger periodBytesReceived;

/**
 *  Total number of packets lost.
 */
@property (nonatomic, readonly) NSInteger packetsLost;

/**
 *  Total number of packets received since media first began flowing.
 */
@property (nonatomic, readonly) NSInteger totalPacketsReceived;

/**
 *  Number of packets received since the last stats event.
 */
@property (nonatomic, readonly) NSInteger periodPacketsReceived;

/**
 *  The identifer of the media stream to which this media stream track belongs.
 */
@property (nonatomic, readonly) NSString *transportId;
@end


/**
 *  Information about the remote video stream track.
 */
@interface RespokeRemoteVideoStats : NSObject

/**
 *  Total number of bytes received since media first began flowing.
 */
@property (nonatomic, readonly) NSInteger totalBytesReceived;

/**
 *  Number of bytes received since the last stats event.
 */
@property (nonatomic, readonly) NSInteger periodBytesReceived;

/**
 *  Total number of packets lost.
 */
@property (nonatomic, readonly) NSInteger packetsLost;

/**
 *  Total number of packets received since media first began flowing.
 */
@property (nonatomic, readonly) NSInteger totalPacketsReceived;

/**
 *  Number of packets received since the last stats event.
 */
@property (nonatomic, readonly) NSInteger periodPacketsReceived;

/**
 *  The identifer of the media stream to which this media stream track belongs.
 */
@property (nonatomic, readonly) NSString *transportId;
@end


/**
 *  A report containing statistical information about the flow of media with the
 *  latest live statistics.
 *
 *  RespokeMediaStatsDelegate must be implemented to utilize statistics.
 *
 *  To start gathering statistics invoke [RespokeCall getStats].
 *  To stop gathering statistics invoke [RespokeCall stopStats].
 */
@interface RespokeMediaStats : NSObject

/**
 *  The date and time at which this stats snapshot was taken.
 */
@property (nonatomic, readonly) NSDate *timestamp;

/**
 *  The time that has passed since the last stats snapshot was taken.
 */
@property (nonatomic, readonly) NSTimeInterval periodLength;

/**
 *  Local audio information.
 */
@property (nonatomic, readonly) RespokeLocalAudioStats *localAudio;

/**
 *  Local video information.
 */
@property (nonatomic, readonly) RespokeLocalVideoStats *localVideo;

/**
 *  Remote audio information.
 */
@property (nonatomic, readonly) RespokeRemoteAudioStats *remoteAudio;

/**
 *  Remote video information.
 */
@property (nonatomic, readonly) RespokeRemoteVideoStats *remoteVideo;

/**
 *  Connection information.
 */
@property (nonatomic, readonly) RespokeConnectionStats *connection;

/**
 *  Indicates where we are in terms of ICE network negotiation -- "hole
 *  punching."
 */
@property (nonatomic, readonly) RespokeICEConnectionState iceConnectionState;

/**
 *  Indicates whether we have started or finished gathering ICE
 *  candidates from the browser.
 */
@property (nonatomic, readonly) RespokeICEGatheringState iceGatheringState;
@end


/**
 * Protocol for delivering statistics
 */
@protocol RespokeMediaStatsDelegate <NSObject>


/**
 * Callback method for reporting statistics.
 *
 * @param stats The statistics report
 */
- (void) onStats:(RespokeMediaStats*)stats;
@end
