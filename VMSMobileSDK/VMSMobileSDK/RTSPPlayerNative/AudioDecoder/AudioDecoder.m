#import "AudioDecoder.h"

@interface AudioDecoder()

@property (strong, nonatomic) NSCondition *converterCond;
@property (nonatomic, strong) dispatch_queue_t decoderQueue;
@property (nonatomic, strong) dispatch_queue_t callbackQueue;

@property (nonatomic) AudioConverterRef audioConverter;
@property (nonatomic) char *aacBuffer;
@property (nonatomic) UInt32 aacBufferSize;
@property (nonatomic) AudioStreamPacketDescription *packetDesc;

@end

@implementation AudioDecoder

//Decoder callback function
static OSStatus AudioDecoderConverterComplexInputDataProc(AudioConverterRef inAudioConverter, UInt32 *ioNumberDataPackets, AudioBufferList *ioData, AudioStreamPacketDescription **outDataPacketDescription, void *inUserData) {
    AudioUserData *audioDecoder = (AudioUserData *)(inUserData);
    if (audioDecoder->size <= 0) {
        ioNumberDataPackets = 0;
        return -1;
    }
    //Data input
    *outDataPacketDescription = &audioDecoder->packetDesc;
    (*outDataPacketDescription)[0].mStartOffset = 0;
    (*outDataPacketDescription)[0].mDataByteSize = audioDecoder->size;
    (*outDataPacketDescription)[0].mVariableFramesInPacket = 1;
    
    ioData->mBuffers[0].mData = audioDecoder->data;
    ioData->mBuffers[0].mDataByteSize = audioDecoder->size;
    ioData->mBuffers[0].mNumberChannels = audioDecoder->channelCount;
    
    return noErr;
}


- (instancetype)initWithConfig: (SDPInfo *)sdpInfo {
    self = [super init];
    if (self) {
        _decoderQueue = dispatch_queue_create("aac.hard.decoder.queue", DISPATCH_QUEUE_SERIAL);
        _callbackQueue = dispatch_queue_create("aac.hard.decoder.callback.queue", DISPATCH_QUEUE_SERIAL);
        _audioConverter = NULL;
        _aacBufferSize = 0;
        _aacBuffer = NULL;
        _sdpInfo = sdpInfo;
        AudioStreamPacketDescription desc = {0};
        _packetDesc = &desc;
        [self setupEncoder];
    }
    return self;
}

- (void)decodeAudioData: (NSData *)aacData {
    if (!_audioConverter && _needStop) { return; }
    dispatch_async(_decoderQueue, ^{
        //Record AAC as a parameter to the decoding and destruction function
        AudioUserData userData = {0};
        userData.channelCount = (UInt32)self->_sdpInfo.audioTrack.channels;
        userData.data = (char *)[aacData bytes];
        userData.size = (UInt32)aacData.length;
        userData.packetDesc.mDataByteSize = (UInt32)aacData.length;
        userData.packetDesc.mStartOffset = 0;
        userData.packetDesc.mVariableFramesInPacket = 1;
        
        //Output size and number of packets
        UInt32 pcmBufferSize = (UInt32)(AUDIO_PLAYER_MIN_SIZE_PER_FRAME * self->_sdpInfo.audioTrack.channels);
        UInt32 pcmDataPacketSize = 1024;
        //Create temporary container pcm
        uint8_t *pcmBuffer = malloc(pcmBufferSize);
        memset(pcmBuffer, 0, pcmBufferSize);
        //output buffer
        AudioBufferList outAudioBufferList = {0};
        outAudioBufferList.mNumberBuffers = 1;
        outAudioBufferList.mBuffers[0].mNumberChannels = (uint32_t)self->_sdpInfo.audioTrack.channels;
        outAudioBufferList.mBuffers[0].mDataByteSize = (UInt32)pcmBufferSize;
        outAudioBufferList.mBuffers[0].mData = pcmBuffer;
        
        //Output description
        AudioStreamPacketDescription outputPacketDesc = {0};
        //Configure the fill function and obtain output data
        OSStatus status = AudioConverterFillComplexBuffer(self->_audioConverter,
                                                          &AudioDecoderConverterComplexInputDataProc,
                                                          &userData,
                                                          &pcmDataPacketSize,
                                                          &outAudioBufferList,
                                                          &outputPacketDesc);
        if (status != noErr) {
            NSLog(@"Error: AAC Decoder error, status=%d",(int)status);
            free(pcmBuffer);
            pcmBuffer = NULL;
            return;
        }
        if (outAudioBufferList.mBuffers[0].mDataByteSize > 0 && !self->_needStop) {
            NSData *rawData = [NSData dataWithBytes: outAudioBufferList.mBuffers[0].mData
                                             length: outAudioBufferList.mBuffers[0].mDataByteSize];
            dispatch_async(self->_callbackQueue, ^{
                [self->_delegate audioDecodeCallback:rawData];
            });
        }
        free(pcmBuffer);
    });
    
}

- (void)setupEncoder {
    //Output parameter pcm
    AudioStreamBasicDescription outputAudioDes = {0};
    
    //Sampling Rate
    outputAudioDes.mSampleRate = (Float64)_sdpInfo.audioTrack.sampleRateHz;
    
    //Number of output channels
    outputAudioDes.mChannelsPerFrame = (UInt32)_sdpInfo.audioTrack.channels;
    
    //Output format
    outputAudioDes.mFormatID = kAudioFormatLinearPCM;
    
    //Coding
    outputAudioDes.mFormatFlags = (kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked);
    
    //Number of frames per packet
    outputAudioDes.mFramesPerPacket = 1;
    
    //Number of sample bits per channel in the data frame
    outputAudioDes.mBitsPerChannel = 16;
    
    //Size of each frame (number of samples / 8 * number of channels)
    outputAudioDes.mBytesPerFrame = outputAudioDes.mBitsPerChannel / 8 *outputAudioDes.mChannelsPerFrame;
    
    //Each packet size (frame size * number of frames）
    outputAudioDes.mBytesPerPacket = outputAudioDes.mBytesPerFrame * outputAudioDes.mFramesPerPacket;
    
    //Alignment mode 0 (8-byte alignment)
    outputAudioDes.mReserved =  0;
    
    //Input parameter aac
    AudioStreamBasicDescription inputAduioDes = {0};
    inputAduioDes.mSampleRate = (Float64)_sdpInfo.audioTrack.sampleRateHz;
    inputAduioDes.mFormatID = kAudioFormatMPEG4AAC;
    inputAduioDes.mFormatFlags = kMPEG4Object_AAC_LC;
    inputAduioDes.mFramesPerPacket = 1024;
    inputAduioDes.mChannelsPerFrame = (UInt32)_sdpInfo.audioTrack.channels;
   
    //Fill in output related information
    UInt32 inDesSize = sizeof(inputAduioDes);
    AudioFormatGetProperty(kAudioFormatProperty_FormatInfo, 
                           0,
                           NULL,
                           &inDesSize,
                           &inputAduioDes);
    
    //Get the description information of the decoder (only software can be passed in)
    AudioClassDescription *audioClassDesc = [self getAudioCalssDescriptionWithType: outputAudioDes.mFormatID fromManufacture:kAppleSoftwareAudioCodecManufacturer];
    
    /** Create converter
     Parameter 1: Enter audio format description
     Parameter 2: Output audio format description
     Parameter 3: Number of class desc
     Parameter 4: class desc
     Parameter 5: The decoder created
     */
    OSStatus status = AudioConverterNewSpecific(&inputAduioDes, 
                                                &outputAudioDes,
                                                1,
                                                audioClassDesc,
                                                &_audioConverter);
    if (status != noErr) {
        NSLog(@"Error！：Hard decoding AAC creation failed, status= %d", (int)status);
        return;
    }
}

/**
 Get decoder type description
 Parameter 1: type
 */
- (AudioClassDescription *)getAudioCalssDescriptionWithType: (AudioFormatID)type 
                                            fromManufacture: (uint32_t)manufacture {
    
    static AudioClassDescription desc;
    UInt32 decoderSpecific = type;
    
    //Get the total size that satisfies the AAC decoder
    UInt32 size;
    
    /**
         Parameter 1: Encoder type (decoding)
         Parameter 2: Type description size
         Parameter 3: Type description
         Parameter 4: size
         */
    
    OSStatus status = AudioFormatGetPropertyInfo(kAudioFormatProperty_Decoders, 
                                                 sizeof(decoderSpecific),
                                                 &decoderSpecific,
                                                 &size);
    if (status != noErr) {
        NSLog(@"Error！：Hard decoding AAC get info failed, status= %d", (int)status);
        return nil;
    }
    
    //Calculate the number of aac decoders
    unsigned int count = size / sizeof(AudioClassDescription);
    //Create an array containing count decoders
    AudioClassDescription description[count];
    //Write the decoder information that satisfies aac decoding into the array
    status = AudioFormatGetProperty(kAudioFormatProperty_Encoders, 
                                    sizeof(decoderSpecific),
                                    &decoderSpecific,
                                    &size,
                                    &description);
    
    if (status != noErr) {
        NSLog(@"Error！：Hard decoding AAC get property failed, status= %d", (int)status);
        return nil;
    }
    
    for (unsigned int i = 0; i < count; i++) {
        if (type == description[i].mSubType && manufacture == description[i].mManufacturer) {
            desc = description[i];
            return &desc;
        }
    }
    return nil;
}

- (void)dealloc {
    if (_audioConverter) {
        AudioConverterDispose(_audioConverter);
        _audioConverter = NULL;
    }
}

@end
