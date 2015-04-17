//
//  RespokeDirectConnection.m
//  RespokeSDKBuilder
//
//  Copyright 2015, Digium, Inc.
//  All rights reserved.
//
//  This source code is licensed under The MIT License found in the
//  LICENSE file in the root directory of this source tree.
//
//  For all details and documentation:  https://www.respoke.io
//

#import "RespokeDirectConnection+private.h"
#import "RespokeCall+private.h"
#import "RTCDataChannel.h"
#import "RTCPeerConnection.h"


@interface RespokeDirectConnection() <RTCDataChannelDelegate> {
    
}

@end


@implementation RespokeDirectConnection {
    RespokeCall __weak *call;
    RTCDataChannel *dataChannel;
}


- (instancetype)initWithCall:(RespokeCall*)newCall
{
    if (self = [super init])
    {
        call = newCall;
    }
    
    return self;
}


- (void)accept
{   
    [call directConnectionDidAccept:self];
}


- (BOOL)isActive
{
    return (dataChannel && (dataChannel.state == kRTCDataChannelStateOpen));
}


- (RespokeCall*)getCall
{
    return call;
}


- (void)sendMessage:(NSString*)message successHandler:(void (^)(void))successHandler errorHandler:(void (^)(NSString*))errorHandler
{
    if ([self isActive])
    {
        NSError *error;
        NSDictionary *messageDict = @{@"message": message};
        NSData *messageData = [NSJSONSerialization dataWithJSONObject:messageDict options:0 error:&error];

        if (!error)
        {
            RTCDataBuffer *data = [[RTCDataBuffer alloc] initWithData:messageData isBinary:NO];
            if ([dataChannel sendData:data])
            {
                successHandler();
            }
            else
            {
                errorHandler(@"Message failed to send");
            }
        }
        else
        {
            errorHandler(@"Unable to encode message to JSON");
        }
    }
    else
    {
        errorHandler(@"dataChannel not in an open state.");
    }
}


- (void)createDataChannel
{
    RTCPeerConnection *peerConnection = [call getPeerConnection];
    RTCDataChannelInit *initData = [[RTCDataChannelInit alloc] init];
    dataChannel = [peerConnection createDataChannelWithLabel:@"respokeDataChannel" config:initData];
    dataChannel.delegate = self;
}


- (void)peerConnectionDidOpenDataChannel:(RTCDataChannel *)newDataChannel
{
    if (dataChannel)
    {
        // Replacing the previous connection, so disable delegate messages from the old instance
        dataChannel.delegate = nil;
    }
    else
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate onStart:self];
        });
    }
    
    dataChannel = newDataChannel;
    dataChannel.delegate = self;
}


// RTCDataChannelDelegate methods


- (void)channelDidChangeState:(RTCDataChannel*)channel
{
    switch (channel.state)
    {
        case kRTCDataChannelStateConnecting:
            NSLog(@"Direct connection CONNECTING");
            break;
            
        case kRTCDataChannelStateOpen:
        {
            NSLog(@"Direct connection OPEN");
            [call directConnectionDidOpen:self];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate onOpen:self];
            });
        }
            break;
            
        case kRTCDataChannelStateClosing:
            NSLog(@"Direct connection CLOSING");
            break;
            
        case kRTCDataChannelStateClosed:
        {
            NSLog(@"Direct connection CLOSED");
            dataChannel = nil;
            [call directConnectionDidClose:self];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate onClose:self];
            });
        }
            break;
    }
}


- (void)channel:(RTCDataChannel*)channel didReceiveMessageWithBuffer:(RTCDataBuffer*)buffer
{
    id message = nil;
    NSError *error;

    id jsonResult = [NSJSONSerialization JSONObjectWithData:buffer.data options:0 error:&error];
    if (error)
    {
        // Could not parse JSON data, so just pass it as it is
        message = buffer.data;
        NSLog(@"Direct Message received (binary)");
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate onMessage:message sender:self];
        });
    }
    else
    {
        if (jsonResult && ([jsonResult isKindOfClass:[NSDictionary class]]))
        {
            NSDictionary *dict = (NSDictionary*)jsonResult;
            NSString *messageText = [dict objectForKey:@"message"];

            if (messageText)
            {
                NSLog(@"Direct Message received: [%@]", messageText);
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.delegate onMessage:messageText sender:self];
                });
            }
        }
    }
}


@end
