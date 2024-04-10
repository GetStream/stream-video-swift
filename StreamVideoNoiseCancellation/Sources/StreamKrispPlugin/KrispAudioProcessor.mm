//
//  KrispAudioProcessor.mm
//  KrispAudioProcessor
//
//  Created by Arthur Hayrapetyan on 26.01.23.
//  Copyright © 2023 Krisp Technologies. All rights reserved.
//

#import "KrispAudioProcessor.h"
#import <StreamWebRTC/RTCAudioCustomProcessingDelegate.h>
#import <StreamWebRTC/RTCAudioBuffer.h>
#import "KrispProcessingModule.h"

@interface KrispAudioProcessor()
@end

@implementation KrispAudioProcessor
{
    std::unique_ptr<KrispProcessingModule> _processingModule;
    NSString *_weightFile;
    unsigned int _size;
    BOOL _isVad;
}

- (instancetype)initWithParams:(NSString*)weightFile size:(unsigned int)size isVad:(BOOL)isVad {

    self = [super init];
    if (self != nil) {
        [self initProcessor: weightFile size: size isVad: isVad];
    }
    return self;
}

- (void)initProcessor:(NSString*)weightFile size:(unsigned int)size isVad:(BOOL)isVad {
    _weightFile = weightFile;
    _size = size;
    _isVad = isVad;
//    _processingModule = std::make_unique<KrispProcessingModule>([weightFile UTF8String], size);
//    _processingModule->init();
    NSLog(@"[%@ initProcessor:%@ size:%d isVad:%d] completed.", self, [weightFile lastPathComponent], size, isVad);
}

- (void)initializeSessionWithSampleRate:(size_t)sampleRateHz
                               channels:(size_t)channels {
    _processingModule = std::make_unique<KrispProcessingModule>([_weightFile UTF8String], _size, _isVad);
    _processingModule->init();
    _processingModule->initSession((int)sampleRateHz, (int)channels);
}

- (void)process:(RTCAudioBuffer *)audioBuffer {
    if (_processingModule->m_session == nullptr) {
        NSLog(@"KrispSession is nil!");
        return;
    }
    _processingModule->frameProcess(
                                    audioBuffer.channels,
                                    audioBuffer.bands,
                                    audioBuffer.frames,
                                    [audioBuffer rawBufferForChannel:0]
                                    );
}

- (void)destroy {
    if (_processingModule->m_session != nullptr) {
        _processingModule->destroy();
    }
}

- (BOOL)isValid {
    return _processingModule->m_session != nullptr;
}

@end
