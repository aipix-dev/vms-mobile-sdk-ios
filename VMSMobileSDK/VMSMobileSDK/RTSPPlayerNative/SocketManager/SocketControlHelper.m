#import "SocketControlHelper.h"

@implementation SocketControlHelper

+ (int)getResponseStatusCode: (NSData* )payloadData {
    NSString *dataString = [SocketControlHelper getStringFromData: payloadData];
    NSRange spaceRange = [dataString rangeOfString:@" "];
    
    if ([dataString containsString: RTSP_OK_STATUS]) {
        return 200;
    }
    
    if (spaceRange.location != NSNotFound) {
        NSString *code = [[dataString substringFromIndex:spaceRange.location + 1] substringToIndex:3];
        int statusCode = [code intValue];
        return statusCode;
    }
    return 0;
}

+ (NSMutableDictionary<NSString *, NSString *> *)getResponseHeaders: (NSData* )payloadData {
    NSString *dataString = [SocketControlHelper getStringFromData: payloadData];
    NSMutableDictionary<NSString *, NSString *> *headers = [NSMutableDictionary dictionary];
    NSArray<NSString *> *lines = [dataString componentsSeparatedByString: @"\r\n"];
    for (NSString *line in lines) {
            NSArray<NSString *> *keyValue = [line componentsSeparatedByString: @":"];
            if (keyValue.count >= 2) {
                NSString *key = [keyValue[0] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
                NSString *value = [keyValue[1] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
                headers[[key lowercaseString]] = value;
            }
        }
    return headers;
}

+ (NSString *)getResponseLocation: (NSData* )payloadData {
    NSString *dataString = [SocketControlHelper getStringFromData: payloadData];
    
    NSArray<NSString *> *lines = [dataString componentsSeparatedByString: @"\r\n"];
    
    for (NSString *line in lines) {
        if ([line containsString: @"Location: "]) {
            NSString *locationLine = [line stringByReplacingOccurrencesOfString: @"Location:" withString: @""];
            NSString *value = [locationLine stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
            return value;
        }
    }
    return NULL;
}

+ (NSString *)getStringFromData: (NSData* )payloadData {
    return [[NSString alloc] initWithData: payloadData 
                                 encoding: NSUTF8StringEncoding];
}

+ (NSInteger)getHeaderContentLength: (NSMutableDictionary<NSString *, NSString *> *)headers {
    NSString *header = [self getHeader: @"content-length"
                               headers: headers];
    if (header != NULL) {
        return [header integerValue];
    }
    return 0;
}

+ (NSMutableDictionary<NSString *, NSString *> *)getDescribeParams: (NSData *)payloadData {
    NSString *dataString = [SocketControlHelper getStringFromData: payloadData];
    
    NSMutableDictionary<NSString *, NSString *> *dictionary = [NSMutableDictionary dictionary];
    BOOL containsCRLF = [dataString containsString: @"r\n"];
    NSArray<NSString *> *params = [dataString componentsSeparatedByString:(containsCRLF ? @"\r\n" : @"\n")];
    
    for (NSString *line in params) {
        if ([line containsString: @":"]) {
            NSArray<NSString *> *lineArray = [line componentsSeparatedByString: @":"];
            if (lineArray.count == 2) {
                NSString *key = lineArray[0];
                NSString *value = lineArray[1];
                [dictionary setValue: value forKey: key];
            }
        }
        if ([line containsString: @"="]) {
            NSArray<NSString *> *lineArray = [line componentsSeparatedByString: @"="];
            if (lineArray.count == 2) {
                NSString *key = lineArray[0];
                NSString *value = lineArray[1];
                [dictionary setValue: value forKey: key];
            }
        }
    }
    return dictionary;
}

+ (NSString *)getHeader: (NSString *)header
                headers: (NSMutableDictionary<NSString *, NSString *> *)headers {
    return [headers valueForKey: header];
}

+ (NSMutableString *)getMessageForState: (SocketState)state
                                    url: (NSString *)url
                                    seq: (NSInteger)seq
                              sessionID: (NSString *)sessionID
                              authToken: (NSString *)authToken {
    switch (state) {
        case SocketStateDoOption:
            return [self getDoOptionsMessage: url seq:seq];
        case SocketStateDoDescribe:
            return [self getDoDescribeMessage: url seq: seq];
        case SocketStateDoSetupVideo:
            return [self getDoSetupVideoMessage: url seq: seq];
        case SocketStateDoSetupAudio:
            return [self getDoSetupAudioMessage: url seq: seq];
        case SocketStateDoPlay:
            return [self getDoPlayMessage: url
                                      seq: seq
                                sessionID: sessionID
                                authToken: authToken];
        case SocketStateDoTeardown:
            return [self getDoTeardownMessage: url
                                      seq: seq
                                sessionID: sessionID
                                authToken: authToken];
        default:
            return NULL;
    }
}

+ (NSMutableString *)getDoOptionsMessage: (NSString *)url seq: (NSInteger)seq {
    NSMutableString *options = [[NSMutableString alloc] initWithString: @"OPTIONS "];
    [options appendString: url];
    [options appendString: @" "];
    [options appendString: RTSP_VERSION];
    [options appendString: @" "];
    [options appendString: [[self class] endStringNumber: 1]];
    [options appendString: @"Cseq: "];
    [options appendFormat: @"%ld", seq];
    [options appendString: [[self class] endStringNumber: 1]];
    [options appendString: @"User-Agent: iOS_RTSP_Client"];
    [options appendString: [[self class] endStringNumber: 2]];
    return options;
}

+ (NSMutableString *)getDoDescribeMessage: (NSString *)url seq: (NSInteger)seq {
    NSMutableString *options = [[NSMutableString alloc] initWithString: @"DESCRIBE "];
    [options appendString: url];
    [options appendString: @" "];
    [options appendString: RTSP_VERSION];
    [options appendString: [[self class] endStringNumber: 1]];
    [options appendString: @"Accept: application/sdp"];
    [options appendString: [[self class] endStringNumber: 1]];
    [options appendString: @"Cseq: "];
    [options appendFormat: @"%ld", seq];
    [options appendString: [[self class] endStringNumber: 1]];
    [options appendString: @"User-Agent: iOS_RTSP_Client"];
    [options appendString: [[self class] endStringNumber:2]];
    return options;
}

+ (NSMutableString *)getDoSetupVideoMessage: (NSString *)url seq: (NSInteger)seq {
    NSMutableString *options = [[NSMutableString alloc] initWithString: @"SETUP "];
    [options appendString: url];
    [options appendString: @"/trackID=video"];
    [options appendString: @" "];
    [options appendString: RTSP_VERSION];
    [options appendString: [[self class] endStringNumber: 1]];
    [options appendString: @"Transport: RTP/AVP/TCP;unicast;interleaved=0-1"];
    [options appendString: [[self class] endStringNumber: 1]];
    [options appendString: @"Cseq: "];
    [options appendFormat: @"%ld", seq];
    [options appendString: [[self class] endStringNumber: 1]];
    [options appendString: @"User-Agent: iOS_RTSP_Client"];
    [options appendString: [[self class] endStringNumber: 2]];
    return options;
}

+ (NSMutableString *)getDoSetupAudioMessage: (NSString *)url seq: (NSInteger)seq {
    NSMutableString *options = [[NSMutableString alloc] initWithString: @"SETUP "];
    [options appendString: url];
    [options appendString: @"/trackID=audio"];
    [options appendString: @" "];
    [options appendString: RTSP_VERSION];
    [options appendString: [[self class] endStringNumber: 1]];
    [options appendString: @"Transport: RTP/AVP/TCP;unicast;interleaved=2-3"];
    [options appendString: [[self class] endStringNumber: 1]];
    [options appendString: @"Cseq: "];
    [options appendFormat: @"%ld", seq];
    [options appendString: [[self class] endStringNumber: 1]];
    [options appendString: @"User-Agent: iOS_RTSP_Client"];
    [options appendString: [[self class] endStringNumber: 2]];
    return options;
}

+ (NSMutableString *)getDoPlayMessage: (NSString *)url 
                                  seq: (NSInteger)seq
                            sessionID: (NSString *)sessionID
                            authToken: (NSString *)authToken {
    NSMutableString *options = [[NSMutableString alloc] initWithString: @"PLAY "];
    [options appendString: url];
    [options appendString: @" "];
    [options appendString: RTSP_VERSION];
    [options appendString: @" "];
    [options appendString: [[self class] endStringNumber: 1]];
    [options appendString: @"Range: npt=0.000-"];
    [options appendString: [[self class] endStringNumber: 1]];
    if (authToken != nil) {
        [options appendString: @"Authorization: "];
        [options appendString: authToken];
        [options appendString: [[self class] endStringNumber: 1]];
    }
    [options appendString: @"Cseq: "];
    [options appendFormat: @"%ld", seq];
    [options appendString: [[self class] endStringNumber: 1]];
    [options appendString: @"User-Agent: iOS_RTSP_Client"];
    if (sessionID != nil) {
        [options appendString: [[self class] endStringNumber: 1]];
        [options appendString: @"Session: "];
        [options appendString: sessionID];
        [options appendString: [[self class] endStringNumber: 2]];
        return options;
    }
    [options appendString:[[self class] endStringNumber: 2]];
    return options;
}

+ (NSMutableString *)getDoTeardownMessage: (NSString *)url
                                  seq: (NSInteger)seq
                            sessionID: (NSString *)sessionID
                            authToken: (NSString *)authToken {
    NSMutableString *options = [[NSMutableString alloc] initWithString: @"TEARDOWN "];
    [options appendString: url];
    [options appendString: @" "];
    [options appendString: RTSP_VERSION];
    [options appendString: @" "];
    [options appendString: [[self class] endStringNumber: 1]];
    if (authToken != nil) {
        [options appendString: @"Authorization: "];
        [options appendString: authToken];
        [options appendString: [[self class] endStringNumber: 1]];
    }
    [options appendString: @"Cseq: "];
    [options appendFormat: @"%ld", seq];
    [options appendString: [[self class] endStringNumber: 1]];
    [options appendString: @"User-Agent: iOS_RTSP_Client"];
    if (sessionID != nil) {
        [options appendString: [[self class] endStringNumber: 1]];
        [options appendString: @"Session: "];
        [options appendString: sessionID];
        [options appendString: [[self class] endStringNumber: 2]];
        return options;
    }
    [options appendString: [[self class] endStringNumber: 2]];
    return options;
}

+ (NSString *)endStringNumber:(NSInteger)number {
    if(number < 1) {
        return @"";
    }
    NSMutableString *options = [[NSMutableString alloc]initWithString:@""];
    for (int i = 0; i < number; i++) {
        [options appendString:@"\r\n"];
    }
    return options;
}

+ (NSString *)getCurrentStepName: (SocketState)state {
    switch (state) {
        case SocketStateNotConnected:
            return @"Not connected";
        case SocketStateConnecting:
            return @"Connecting";
        case SocketStateConnected:
            return @"Connected";
        case SocketStateDoOption:
            return @"Do option";
        case SocketStateDoDescribe:
            return @"Do describe";
        case SocketStateDoSetupVideo:
            return @"Do setup video";
        case SocketStateDoSetupAudio:
            return @"Do setup audio";
        case SocketStateDoPlay:
            return @"Do play";
        case SocketStateDoTeardown:
            return @"Do teardown";
        case SocketStatePlaying:
            return @"Do playing";
        case SocketStateDisconnected:
            return @"Socket is disconnected";
    }
}

@end
