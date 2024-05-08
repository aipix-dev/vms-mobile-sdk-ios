#import "SDPInfo.h"

@implementation SDPInfo

+ (SDPInfo *)parseSDPInfoFromParams: (NSString *)params {
    SDPInfo *sdpInfo = [[SDPInfo alloc] init];

    VideoTrack *videoTrack = [self searchVideoTrackInfo: params];
    AudioTrack *audioTrack = [self searchAudioTrackInfo: params];

    if (audioTrack != NULL) {
        sdpInfo.audioTrack = audioTrack;
    }
    if (videoTrack != NULL) {
        sdpInfo.videoTrack = videoTrack;
    }
    
    sdpInfo.session = [self getSession:params];
    sdpInfo.sessionName = [self getSessionName: params];
    sdpInfo.sessionTimeout = [self getSessionTimeout: params];
    sdpInfo.time = [self getTime:params];
    
    return sdpInfo;
}

+ (NSTextCheckingResult *)getMatches: (NSString *)regex params: (NSString *)params {
    NSRegularExpression *regexExp = [NSRegularExpression regularExpressionWithPattern: regex options: 0 error: nil];
    return [regexExp firstMatchInString: params options: 0 range: NSMakeRange(0, params.length)];
}

+ (NSString *)getSessionName: (NSString *)params {
    NSTextCheckingResult *sessionNameMatch = [self getMatches: @"s=([^\\n]+)" params: params];
    NSString *sessionName = [params substringWithRange: [sessionNameMatch rangeAtIndex: 1]];
    NSLog(@"Session Name: %@", sessionName);
    return sessionName;
}

+ (int)getSessionTimeout: (NSString *)params {
    NSTextCheckingResult *timeoutMatch = [self getMatches: @"timeout=(\\d+)" params: params];
    NSString *timeout = [params substringWithRange: [timeoutMatch rangeAtIndex: 1]];
    NSLog(@"Timeout: %@", timeout);
    return [timeout intValue];
}

+ (NSString *)getSession: (NSString *)params {
    NSTextCheckingResult *sessionMatch = [self getMatches: @"Session: ([^;]+);" params: params];
    NSString *session = [params substringWithRange:[sessionMatch rangeAtIndex:1]];
    NSLog(@"Session: %@", session);
    return session;
}

+ (long)getTime: (NSString *)params {
    NSTextCheckingResult *timeMatch = [self getMatches: @"t=(\\d+) (\\d+)" params: params];
    NSString *timeStart = [params substringWithRange:[timeMatch rangeAtIndex:1]];
    NSString *timeEnd = [params substringWithRange:[timeMatch rangeAtIndex:2]];
    NSLog(@"Time Start: %@, Time End: %@", timeStart, timeEnd);
    long timeLong = [timeStart longLongValue];
    return timeLong;
}

+ (VideoTrack *)searchVideoTrackInfo: (NSString *)params {
    VideoTrack *videoTrack;
    
    if ([self sdpHasVideoTrack: params]) {
        videoTrack = [[VideoTrack alloc] init];
        videoTrack.payloadType = [self getVideoPayloadType: params];
        videoTrack.request = [self getVideoRequest: params];
        videoTrack.frameRate = [self getVideoFrameRate:params];
        [self setVideoSPSAndPPSAndVPS: videoTrack params: params];
        [self setVideoCodec: videoTrack params: params];
    }
    return videoTrack;
}

+ (AudioTrack *)searchAudioTrackInfo: (NSString *)params {
    AudioTrack *audioTrack;
    
    if ([self sdpHasAudioTrack: params]) {
        audioTrack = [[AudioTrack alloc] init];
        audioTrack.payloadType = [self getAudioPayloadType: params];
        audioTrack.request = [self getAudioRequest: params];
        [self setAudioModeAndConfig: audioTrack params: params];
        [self setAudioCodec: audioTrack params: params];
    }
    if (audioTrack.mode == NULL || audioTrack.audioCodec == AUDIO_CODEC_UNKNOWN) {
        return NULL;
    }
    return audioTrack;
}

+ (BOOL)sdpHasVideoTrack: (NSString *)params {
    NSTextCheckingResult *mediaMatch = [self getMatches: @"m=(video)" params: params];
    if (mediaMatch) {
        NSString *mediaType = [params substringWithRange: [mediaMatch rangeAtIndex: 1]];
        NSLog(@"Media Type: %@", mediaType);
        return TRUE;
    }
    return FALSE;
}

+ (BOOL)sdpHasAudioTrack: (NSString *)params {
    NSTextCheckingResult *mediaMatch = [self getMatches: @"m=(audio)" params: params];
    if (mediaMatch) {
        NSString *mediaType = [params substringWithRange: [mediaMatch rangeAtIndex: 1]];
        NSLog(@"Media Type: %@", mediaType);
        return TRUE;
    }
    return FALSE;
}

+ (int)getVideoPayloadType: (NSString *)params {
    NSTextCheckingResult *mediaMatch = [self getMatches: @"m=(video) \\d+ RTP/AVP (\\d+)" params: params];
    if (mediaMatch) {
        NSString *payloadType = [params substringWithRange:[mediaMatch rangeAtIndex:2]];
        NSLog(@"Payload Type: %@", payloadType);
        return [payloadType intValue];
    }
    return -1;
}

+ (int)getAudioPayloadType: (NSString *)params {
    NSTextCheckingResult *mediaMatch = [self getMatches: @"m=(audio) \\d+ RTP/AVP (\\d+)" params: params];
    if (mediaMatch) {
        NSString *payloadType = [params substringWithRange:[mediaMatch rangeAtIndex:2]];
        NSLog(@"Payload Type: %@", payloadType);
        return [payloadType intValue];
    }
    return -1;
}

+ (NSString *)getVideoRequest: (NSString *)params {
    NSRegularExpression *controlRegex = [NSRegularExpression regularExpressionWithPattern:@"a=control:trackID=(\\d+|video)" options:0 error:nil];
    NSArray<NSTextCheckingResult *> *controlMatches = [controlRegex matchesInString:params options:0 range:NSMakeRange(0, params.length)];
    
    for (NSTextCheckingResult *match in controlMatches) {
        NSString *trackID = [params substringWithRange:[match rangeAtIndex:1]];
        NSLog(@"Track ID: %@", trackID);
        return trackID;
    }
    return NULL;
}

+ (NSUInteger)getVideoFrameRate: (NSString *)params {
    NSRegularExpression *controlRegex = [NSRegularExpression regularExpressionWithPattern:@"a=framerate:(\\d+|)" options:0 error:nil];
    NSArray<NSTextCheckingResult *> *controlMatches = [controlRegex matchesInString:params options:0 range:NSMakeRange(0, params.length)];
    
    for (NSTextCheckingResult *match in controlMatches) {
        NSString *frameRate = [params substringWithRange:[match rangeAtIndex:1]];
        NSLog(@"FrameRate: %@", frameRate);
        double fRate = [frameRate doubleValue];
        NSUInteger roundedFrameRate = round(fRate);
        return roundedFrameRate;
    }
    return 0;
}

+ (NSString *)getAudioRequest: (NSString *)params {
    NSRegularExpression *controlRegex = [NSRegularExpression regularExpressionWithPattern:@"a=control:trackID=(\\d+|audio)" options:0 error:nil];
    NSArray<NSTextCheckingResult *> *controlMatches = [controlRegex matchesInString:params options:0 range:NSMakeRange(0, params.length)];
    
    for (NSTextCheckingResult *match in controlMatches) {
        NSString *trackID = [params substringWithRange:[match rangeAtIndex:1]];
        NSLog(@"Track ID: %@", trackID);
        return trackID;
    }
    return NULL;
}

+ (void)setVideoSPSAndPPSAndVPS: (VideoTrack *)videoTrack params: (NSString *)params {
    NSRegularExpression *fmtpRegex = [NSRegularExpression regularExpressionWithPattern:@"a=fmtp:\\d+ ([^\\n]+)" options:0 error:nil];
    NSArray<NSTextCheckingResult *> *fmtpMatches = [fmtpRegex matchesInString:params options:0 range:NSMakeRange(0, params.length)];
    
    for (NSTextCheckingResult *match in fmtpMatches) {
        NSString *fmtpValues = [params substringWithRange:[match rangeAtIndex:1]];
        
        NSArray *fmtpComponents = [fmtpValues componentsSeparatedByString:@";"];
        for (NSString *component in fmtpComponents) {
            if ([component containsString:@"sprop-parameter-sets="]) {
                NSString *spropParams = [component stringByReplacingOccurrencesOfString:@"sprop-parameter-sets=" withString:@""];
                NSArray *spropParameters = [spropParams componentsSeparatedByString:@","];
                if (spropParameters.count >= 2) {
                    NSString *spsString = spropParameters[0];
                    NSString *ppsString = spropParameters[1];
                    
                    NSLog(@"SPS: %@, PPS: %@", spsString, ppsString);
                    
                    NSData *spsData = [[NSData alloc] initWithBase64EncodedString: spsString options: NSDataBase64DecodingIgnoreUnknownCharacters];
                    NSData *ppsData = [[NSData alloc] initWithBase64EncodedString: ppsString options: NSDataBase64DecodingIgnoreUnknownCharacters];
                    uint8_t nalHeader[4] = {0, 0, 0, 1};

                    NSMutableData *nalSps = [NSMutableData dataWithBytes: nalHeader length: 4];
                    [nalSps appendData:spsData];
                    NSMutableData *nalPps = [NSMutableData dataWithBytes: nalHeader length: 4];
                    [nalPps appendData:ppsData];
                    
                    // Add 00 00 00 01 NAL unit header
                    
                    videoTrack.sps = nalSps;
                    videoTrack.spsSize = nalSps.length;
                    videoTrack.pps = nalPps;
                    videoTrack.ppsSize = nalPps.length;
                }
            }
            if ([component containsString:@"sprop-vps="]) {
                NSString *spropParams = [component stringByReplacingOccurrencesOfString:@"sprop-vps=" withString:@""];
                NSString *vpsString = [spropParams stringByReplacingOccurrencesOfString:@" " withString:@""];
                    
                    NSLog(@"VPS: %@", vpsString);
                    
                NSMutableData *vpsData = [[NSMutableData alloc] initWithBase64EncodedString: vpsString options: 0];
                    
                    videoTrack.vps = vpsData;
                    videoTrack.vpsSize = vpsData.length;
            }
            if ([component containsString:@"sprop-sps="]) {
                NSString *spropParams = [component stringByReplacingOccurrencesOfString:@"sprop-sps=" withString:@""];
                    NSString *spsString = spropParams;
                    
                    NSLog(@"SPS: %@", spsString);
                    
                NSMutableData *spsData = [[NSMutableData alloc] initWithBase64EncodedString: spsString options: 0];
                    
                    videoTrack.sps = spsData;
                    videoTrack.spsSize = spsData.length;
            }
            if ([component containsString:@"sprop-pps="]) {
                NSString *spropParams = [component stringByReplacingOccurrencesOfString:@"sprop-pps=" withString:@""];
                    NSString *ppsString = spropParams;
                    
                    NSLog(@"PPS: %@", ppsString);
                    
                NSMutableData *ppsData = [[NSMutableData alloc] initWithBase64EncodedString: ppsString options: 0];
                    
                    videoTrack.pps = ppsData;
                    videoTrack.ppsSize = ppsData.length;
            }
        }
    }
}

+ (void) setAudioModeAndConfig: (AudioTrack *)audioTrack params: (NSString *)params {
    NSRegularExpression *fmtpRegex = [NSRegularExpression regularExpressionWithPattern:@"a=fmtp:(\\d+) ([^\\n]+)" options:0 error:nil];
    NSArray<NSTextCheckingResult *> *fmtpMatches = [fmtpRegex matchesInString:params options:0 range:NSMakeRange(0, params.length)];
    if (fmtpMatches.count > 1) {
        NSString *fmtpValues = [params substringWithRange:[fmtpMatches[1] rangeAtIndex:2]];
        NSArray *fmtpComponents = [fmtpValues componentsSeparatedByString:@";"];
        for (NSString *component in fmtpComponents) {
            if ([component containsString:@"config="]) {
                NSString *configValue = [component stringByReplacingOccurrencesOfString:@"config=" withString:@""];
                audioTrack.config = [self getBytesFromConfixHexString: configValue];
                NSLog(@"Config Value: %@", configValue);
            } else if ([component containsString:@"mode="]) {
                NSString *modeValue = [component stringByReplacingOccurrencesOfString:@"mode=" withString:@""];
                audioTrack.mode = [[NSString alloc] initWithString:modeValue];
                NSLog(@"Mode Value: %@", modeValue);
            }
        }
    }
}

+ (NSData *)getBytesFromConfixHexString:(NSString *)config {
    unsigned int hexValue;
    NSScanner *scanner = [NSScanner scannerWithString:config];
    [scanner scanHexInt:&hexValue];
    NSMutableData *data = [NSMutableData data];
    while (hexValue > 0) {
        uint8_t byte = (uint8_t)(hexValue & 0xFF);
        [data appendBytes:&byte length:1];
        hexValue >>= 8;
    }
    // Reverse the data to get the correct byte order
    NSMutableData *reversedData = [NSMutableData dataWithCapacity:data.length];
    for (NSInteger i = data.length - 1; i >= 0; i--) {
        [reversedData appendBytes:data.bytes + i length:1];
    }
    return [reversedData copy];
}

+ (void)setVideoCodec: (VideoTrack *)videoTrack params: (NSString *)params {
    NSRegularExpression *rtpmapRegex = [NSRegularExpression regularExpressionWithPattern:@"a=rtpmap:(\\d+) (\\w+)/(\\d+)" options:0 error:nil];
    NSArray<NSTextCheckingResult *> *rtpmapMatches = [rtpmapRegex matchesInString:params options:0 range:NSMakeRange(0, params.length)];
    
    NSString *encoding = [params substringWithRange:[rtpmapMatches.firstObject rangeAtIndex:2]];
    if ([encoding caseInsensitiveCompare:@"h264"] == NSOrderedSame) {
        NSLog(@"Encoding is H264");
        videoTrack.videoCodec = VIDEO_CODEC_H264;
    } else if ([encoding caseInsensitiveCompare:@"h265"] == NSOrderedSame) {
        NSLog(@"Encoding is H265");
        videoTrack.videoCodec = VIDEO_CODEC_H265;
    }
    NSString *encodingRate = [params substringWithRange:[rtpmapMatches.firstObject rangeAtIndex:3]];
    NSLog(@"Encoding Rate %@", encodingRate);
    videoTrack.sampleRate = [encodingRate intValue];
}

+ (void)setAudioCodec: (AudioTrack *)audioTrack params: (NSString *)params {
    audioTrack.audioCodec = AUDIO_CODEC_UNKNOWN;
    NSRegularExpression *rtpmapRegex = [NSRegularExpression regularExpressionWithPattern:@"a=rtpmap:(\\d+) ([^\\n]+)" options:0 error:nil];
    NSArray<NSTextCheckingResult *> *rtpmapMatches = [rtpmapRegex matchesInString:params options:0 range:NSMakeRange(0, params.length)];
    for (NSTextCheckingResult *rtpmapMatch in rtpmapMatches) {
        NSString *encoding = [params substringWithRange:[rtpmapMatch rangeAtIndex:2]];
        NSRange sampleRateRange = [encoding rangeOfString:@"/(\\d+)/" options:NSRegularExpressionSearch];
        NSRange channelsRange = [encoding rangeOfString:@"(\\d+)(?!.*\\d)" options:NSRegularExpressionSearch];

        if ([encoding.lowercaseString containsString: @"mpeg4-generic"]) {
            NSLog(@"Encoding is mpeg4-generic");
            audioTrack.audioCodec = AUDIO_CODEC_AAC;
        }
        if (sampleRateRange.location != NSNotFound) {
            NSString *sampleRateString = [encoding substringWithRange:sampleRateRange];
            NSString *sampleRateClear = [sampleRateString stringByReplacingOccurrencesOfString:@"/" withString:@""];
            int sampleRate = [sampleRateClear intValue];
            NSLog(@"Sample Rate: %d", sampleRate);
            audioTrack.sampleRateHz = sampleRate;
        }
        if (channelsRange.location != NSNotFound) {
            NSString *channelsString = [encoding substringWithRange:channelsRange];
            NSString *channelsClear = [channelsString stringByReplacingOccurrencesOfString:@"/" withString:@""];
            int channels = [channelsClear intValue];
            NSLog(@"Channels: %d", channels);
            audioTrack.channels = channels;
        }
    }
}

@end
