//
//  KrispProcessingModule.h
//  KrispAudioProcessor
//
//  Created by Arthur Hayrapetyan on 26.01.23.
//  Copyright © 2023 Krisp Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Accelerate/Accelerate.h>
#import <KrispAudioSDK/krisp-audio-sdk.hpp>
#import <KrispAudioSDK/krisp-audio-sdk-nc-stats.hpp>
#import <KrispAudioSDK/krisp-audio-sdk-nc.hpp>
#import <KrispAudioSDK/krisp-audio-sdk-noise-db.hpp>
#import <KrispAudioSDK/krisp-audio-sdk-rt.hpp>
#import <KrispAudioSDK/krisp-audio-sdk-vad.hpp>

class KrispProcessingModule final
{
public:
    KrispAudioSessionID _Nullable m_session;
    std::string m_processorName;
    int m_sampleRateHz;
    int m_numChannels;
    bool m_isVad;

public:
    KrispProcessingModule (const char* __nullable weight, unsigned int blobSize, bool isVad);
    ~KrispProcessingModule( );

    void createSession(const int rate);
    void init();
    void reset();
    void resetSampleRate(const int newRate);
    void destroy();
    void initSession(const int sampleRateHz, const int numChannels);
    void frameProcess(const size_t channelNumber, const size_t num_bands, const size_t bufferSize, float * _Nonnull buffer);
};
