//
//  RespokeMediaStats.m
//  RespokeSDK
//
//  Created by Rob Crabtree on 1/15/15.
//  Copyright (c) 2015 Digium, Inc. All rights reserved.
//

#import "RespokeMediaStats+private.h"
#import "RTCStatsReport.h"
#import "RTCPair.h"


@implementation RespokeMediaStats


- (instancetype)initWithData:(NSArray*)stats iceGatheringState:(RTCICEGatheringState)gatheringState iceConnectionState:(RTCICEConnectionState)connectionState timestamp:(NSDate*)timestamp oldMediaStats:(RespokeMediaStats*)oldMediaStats
{
    if (self = [super init])
    {
        switch (gatheringState)
        {
            case RTCICEGatheringNew:
                _iceGatheringState = RespokeICEGatheringNew;
                break;
            case RTCICEGatheringGathering:
                _iceGatheringState = RespokeICEGatheringGathering;
                break;
            case RTCICEGatheringComplete:
                _iceGatheringState = RespokeICEGatheringComplete;
                break;
            default:
                break;
        }

        switch (connectionState)
        {
            case RTCICEConnectionChecking:
                _iceConnectionState = RespokeICEConnectionChecking;
                break;
            case RTCICEConnectionClosed:
                _iceConnectionState = RespokeICEConnectionClosed;
                break;
            case RTCICEConnectionCompleted:
                _iceConnectionState = RespokeICEConnectionCompleted;
                break;
            case RTCICEConnectionConnected:
                _iceConnectionState = RespokeICEConnectionConnected;
                break;
            case RTCICEConnectionDisconnected:
                _iceConnectionState = RespokeICEConnectionDisconnected;
                break;
            case RTCICEConnectionFailed:
                _iceConnectionState = RespokeICEConnectionFailed;
                break;
            case RTCICEConnectionNew:
                _iceConnectionState = RespokeICEConnectionNew;
                break;
            default:
                break;
        }

        _timestamp = timestamp;
        if (oldMediaStats)
        {
            _periodLength = [timestamp timeIntervalSince1970] - [oldMediaStats.timestamp timeIntervalSince1970];
        }
        else
        {
            _periodLength = 0.0;
        }

        for (RTCStatsReport *data in stats)
        {
            if ([data.type isEqualToString:@"googCandidatePair"])
            {
                [self createConnectionStats:data];
            }
            else if ([data.type isEqualToString:@"ssrc"])
            {
                [self createAudioVideoStats:data oldMediaStats:oldMediaStats];
            }
        }
    }
    return self;
}


- (void)createConnectionStats:(RTCStatsReport*)connectionData
{
    BOOL foundOutgoingNetworkPaths = NO;
    BOOL foundIncomingNetworkPaths = NO;
    NSString *transport = nil;
    NSString *localMediaPath = nil;
    NSString *remoteMediaPath = nil;
    NSString *remoteHost = nil;
    NSString *localHost = nil;
    NSString *roundTripTime = nil;
    NSString *channelId = nil;

    for (RTCPair *pair in connectionData.values)
    {
        if ([pair.key isEqualToString:@"googActiveConnection"])
        {
            // we are only interested in active connections
            if ([pair.value isEqualToString:@"false"])
            {
                return;
            }
        }
        else if ([pair.key isEqualToString:@"googWritable"])
        {
            foundOutgoingNetworkPaths = [pair.value isEqualToString:@"true"];
        }
        else if ([pair.key isEqualToString:@"googReadable"])
        {
            foundIncomingNetworkPaths = [pair.value isEqualToString:@"true"];
        }
        else if ([pair.key isEqualToString:@"googTransportType"])
        {
            transport = pair.value;
        }
        else if ([pair.key isEqualToString:@"googLocalCandidateType"])
        {
            localMediaPath = pair.value;
        }
        else if ([pair.key isEqualToString:@"googRemoteCandidateType"])
        {
            remoteMediaPath = pair.value;
        }
        else if ([pair.key isEqualToString:@"googRemoteAddress"])
        {
            remoteHost = pair.value;
        }
        else if ([pair.key isEqualToString:@"googLocalAddress"])
        {
            localHost = pair.value;
        }
        else if ([pair.key isEqualToString:@"googRtt"])
        {
            roundTripTime = pair.value;
        }
        else if ([pair.key isEqualToString:@"googChannelId"])
        {
            channelId = pair.value;
        }
    }
    _connection = [[RespokeConnectionStats alloc] initWithChannelId:channelId foundOutgoingNetworkPaths:foundOutgoingNetworkPaths foundIncomingNetworkPaths:foundIncomingNetworkPaths transport:transport localMediaPath:localMediaPath remoteMediaPath:remoteMediaPath remoteHost:remoteHost localHost:localHost roundTripTime:roundTripTime];
}


- (void)createAudioVideoStats:(RTCStatsReport*)ssrcData oldMediaStats:(RespokeMediaStats*)oldMediaStats
{
    NSString *audioInputLevel = nil;
    NSString *transportId = nil;
    NSString *audioOutputLevel = nil;
    NSString *codec = nil;
    NSInteger packetsReceived = -1;
    NSInteger packetsLost = -1;
    NSInteger bytesReceived = -1;
    NSInteger packetsSent = -1;
    NSInteger bytesSent = -1;

    // scan data for interesting values
    for (RTCPair *pair in ssrcData.values)
    {
        if ([pair.key isEqualToString:@"audioInputLevel"])
        {
            audioInputLevel = pair.value;
        }
        else if ([pair.key isEqualToString:@"packetsSent"])
        {
            packetsSent = [pair.value integerValue];
        }
        else if ([pair.key isEqualToString:@"bytesSent"])
        {
            bytesSent = [pair.value integerValue];
        }
        else if ([pair.key isEqualToString:@"transportId"])
        {
            transportId = pair.value;
        }
        else if ([pair.key isEqualToString:@"audioOutputLevel"])
        {
            audioOutputLevel = pair.value;
        }
        else if ([pair.key isEqualToString:@"packetsReceived"])
        {
            packetsReceived = [pair.value integerValue];
        }
        else if ([pair.key isEqualToString:@"packetsLost"])
        {
            packetsLost = [pair.value integerValue];
        }
        else if ([pair.key isEqualToString:@"bytesReceived"])
        {
            bytesReceived = [pair.value integerValue];
        }
        else if ([pair.key isEqualToString:@"googCodecName"])
        {
            codec = pair.value;
        }
    }

    // see if this is an audio or video report
    if (audioInputLevel || audioOutputLevel)
    {
        // see if this is local or remote audio data
        if (packetsSent != -1)
        {
            NSInteger totalBytesSent = bytesSent;
            NSInteger totalPacketsSent = packetsSent;
            if (oldMediaStats)
            {
                totalBytesSent += oldMediaStats.localAudio.totalBytesSent;
                totalPacketsSent += oldMediaStats.localAudio.totalPacketsSent;
            }
            _localAudio = [[RespokeLocalAudioStats alloc] initWithAudioInputLevel:audioInputLevel codec:codec totalBytesSent:totalBytesSent periodBytesSent:bytesSent totalPacketsSent:totalPacketsSent periodPacketsSent:packetsSent transportId:transportId];
        }
        else if (packetsReceived != -1)
        {
            NSInteger totalBytesReceived = bytesReceived;
            NSInteger totalPacketsReceived = packetsReceived;
            if (oldMediaStats)
            {
                totalBytesReceived += oldMediaStats.remoteAudio.totalBytesReceived;
                totalPacketsReceived += oldMediaStats.remoteAudio.totalPacketsReceived;
            }
            _remoteAudio = [[RespokeRemoteAudioStats alloc] initWithAudioOutputLevel:audioOutputLevel totalBytesReceived:totalBytesReceived periodBytesReceived:bytesReceived packetsLost:packetsLost totalPacketsReceived:totalPacketsReceived periodPacketsReceived:packetsReceived transportId:transportId];
        }
        else
        {
            NSLog(@"Error: unknown audio");
        }
    }
    else
    {
        // see if this is local or remote video data
        if (packetsSent != -1)
        {
            NSInteger totalBytesSent = bytesSent;
            NSInteger totalPacketsSent = packetsSent;
            if (oldMediaStats)
            {
                totalBytesSent += oldMediaStats.localVideo.totalBytesSent;
                totalPacketsSent += oldMediaStats.localVideo.totalPacketsSent;
            }
            _localVideo = [[RespokeLocalVideoStats alloc] initWithCodec:codec totalBytesSent:totalBytesSent periodBytesSent:bytesSent totalPacketsSent:totalPacketsSent periodPacketsSent:packetsSent transportId:transportId];
        }
        else if (packetsReceived != -1)
        {
            NSInteger totalBytesReceived = bytesReceived;
            NSInteger totalPacketsReceived = packetsReceived;
            if (oldMediaStats)
            {
                totalBytesReceived += oldMediaStats.remoteVideo.totalBytesReceived;
                totalPacketsReceived += oldMediaStats.remoteVideo.totalPacketsReceived;
            }
            _remoteVideo = [[RespokeRemoteVideoStats alloc] initWithTotalBytesReceived:totalBytesReceived periodBytesReceived:bytesReceived packetsLost:packetsLost totalPacketsReceived:totalPacketsReceived periodPacketsReceived:packetsReceived transportId:transportId];
        }
        else
        {
            NSLog(@"Error: unknown video");
        }
    }
}


@end


@implementation RespokeConnectionStats


-(instancetype)initWithChannelId:(NSString*)channelId foundOutgoingNetworkPaths:(BOOL)foundOutgoingNetworkPaths foundIncomingNetworkPaths:(BOOL)foundIncomingNetworkPaths transport:(NSString*)transport localMediaPath:(NSString*)localMediaPath remoteMediaPath:(NSString*)remoteMediaPath remoteHost:(NSString*)remoteHost localHost:(NSString*)localHost roundTripTime:(NSString*)roundTripTime
{
    if (self = [super init])
    {
        _channelId = channelId;
        _foundOutgoingNetworkPaths = foundOutgoingNetworkPaths;
        _foundIncomingNetworkPaths = foundIncomingNetworkPaths;
        _transport = transport;
        _localMediaPath = localMediaPath;
        _remoteMediaPath = remoteMediaPath;
        _remoteHost = remoteHost;
        _localHost = localHost;
        _roundTripTime = roundTripTime;
    }
    return self;
}


@end


@implementation RespokeLocalAudioStats


-(instancetype)initWithAudioInputLevel:(NSString*)audioInputLevel codec:(NSString*)codec totalBytesSent:(NSInteger)totalBytesSent periodBytesSent:(NSInteger)periodBytesSent totalPacketsSent:(NSInteger)totalPacketsSent periodPacketsSent:(NSInteger)periodPacketsSent transportId:(NSString*)transportId
{
    if (self = [super init])
    {
        _audioInputLevel = audioInputLevel;
        _codec = codec;
        _totalBytesSent = totalBytesSent;
        _periodBytesSent = periodBytesSent;
        _totalPacketsSent = totalPacketsSent;
        _periodPacketsSent = periodPacketsSent;
        _transportId = transportId;
    }
    return self;
}


@end


@implementation RespokeLocalVideoStats


-(instancetype)initWithCodec:(NSString*)codec totalBytesSent:(NSInteger)totalBytesSent periodBytesSent:(NSInteger)periodBytesSent totalPacketsSent:(NSInteger)totalPacketsSent periodPacketsSent:(NSInteger)periodPacketsSent transportId:(NSString*)transportId
{
    if (self = [super init])
    {
        _codec = codec;
        _totalBytesSent = totalBytesSent;
        _periodBytesSent = periodBytesSent;
        _totalPacketsSent = totalPacketsSent;
        _periodPacketsSent = periodPacketsSent;
        _transportId = transportId;
    }
    return self;
}


@end


@implementation RespokeRemoteAudioStats


-(instancetype)initWithAudioOutputLevel:(NSString*)audioOutputLevel totalBytesReceived:(NSInteger)totalBytesReceived periodBytesReceived:(NSInteger)periodBytesReceived packetsLost:(NSInteger)packetsLost totalPacketsReceived:(NSInteger)totalPacketsReceived periodPacketsReceived:(NSInteger)periodPacketsReceived transportId:(NSString*)transportId
{
    if (self = [super init])
    {
        _audioOutputLevel = audioOutputLevel;
        _totalBytesReceived = totalBytesReceived;
        _periodBytesReceived = periodBytesReceived;
        _packetsLost = packetsLost;
        _totalPacketsReceived = totalPacketsReceived;
        _periodPacketsReceived = periodPacketsReceived;
        _transportId = transportId;
    }
    return self;
}


@end


@implementation RespokeRemoteVideoStats


-(instancetype)initWithTotalBytesReceived:(NSInteger)totalBytesReceived periodBytesReceived:(NSInteger)periodBytesReceived packetsLost:(NSInteger)packetsLost totalPacketsReceived:(NSInteger)totalPacketsReceived periodPacketsReceived:(NSInteger)periodPacketsReceived transportId:(NSString*)transportId
{
    if (self = [super init])
    {
        _totalBytesReceived = totalBytesReceived;
        _periodBytesReceived = periodBytesReceived;
        _packetsLost = packetsLost;
        _totalPacketsReceived = totalPacketsReceived;
        _periodPacketsReceived = periodPacketsReceived;
        _transportId = transportId;
    }
    return self;
}


@end
