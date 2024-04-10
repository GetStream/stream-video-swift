//
//  KrispProcessingModule.m
//  KrispAudioProcessor
//
//  Created by Arthur Hayrapetyan on 26.01.23.
//  Copyright © 2023 Krisp Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KrispProcessingModule.h"
#include <vector>
#include <string>

inline std::wstring convertMBString2WString(const std::string& str)
{
    std::wstring w(str.begin(), str.end());
    return w;
}


static KrispAudioFrameDuration GetFrameDuration(size_t duration)
{
    switch (duration) {
        case 10:
            return KRISP_AUDIO_FRAME_DURATION_10MS;
        default:
            NSLog(@"Frame duration is not supported. Switching to default 10ms.");
            return KRISP_AUDIO_FRAME_DURATION_10MS;
    }
}

static KrispAudioSamplingRate GetSampleRate(size_t rate)
{
    switch (rate) {
        case 8000:
            return KRISP_AUDIO_SAMPLING_RATE_8000HZ;
        case 16000:
            return KRISP_AUDIO_SAMPLING_RATE_16000HZ;
        case 24000:
            return KRISP_AUDIO_SAMPLING_RATE_24000HZ;
        case 32000:
            return KRISP_AUDIO_SAMPLING_RATE_32000HZ;
        case 44100:
            return KRISP_AUDIO_SAMPLING_RATE_44100HZ;
        case 48000:
            return KRISP_AUDIO_SAMPLING_RATE_48000HZ;
        case 88200:
            return KRISP_AUDIO_SAMPLING_RATE_88200HZ;
        case 96000:
            return KRISP_AUDIO_SAMPLING_RATE_96000HZ;
        default:
            NSLog(@"The input sampling rate is not supported. Using default 48khz.");
            return KRISP_AUDIO_SAMPLING_RATE_48000HZ;
    }
}

KrispProcessingModule::KrispProcessingModule(const char* __nullable weight, unsigned int blobSize, bool isVad)
    : m_session(nullptr),
      m_processorName(weight),
      m_sampleRateHz(48000),
      m_numChannels(1),
      m_isVad(isVad)
{
   
}

KrispProcessingModule::~KrispProcessingModule()
{
    krispAudioNcCloseSession(m_session);
    krispAudioGlobalDestroy();
}

void KrispProcessingModule::init( )
{
    if (krispAudioGlobalInit(nullptr)) {
        NSLog(@"KrispProcessingModule: Failed to initialize Krisp globals");
        return;
    }

    if (krispAudioSetModel(convertMBString2WString(m_processorName.c_str()).c_str(), "default") != 0) {
        NSLog(@"KrispProcessingModule: Krisp failed to set wt file, weight = %s", m_processorName.c_str());
        return;
    }
}

void KrispProcessingModule::reset( ) {
    if (m_isVad) {
        krispAudioVadCloseSession(m_session);
    } else {
        krispAudioNcCloseSession(m_session);
    }
    m_session = nullptr;
}

void KrispProcessingModule::resetSampleRate(int newRate)
{
    if (m_isVad) {
        krispAudioVadCloseSession(m_session);
    } else {
        krispAudioNcCloseSession(m_session);
    }
    createSession(newRate);
    m_sampleRateHz = newRate;
}

void KrispProcessingModule::createSession(int rate) {
    auto krisp_rate = GetSampleRate(rate);
    auto krisp_duration = GetFrameDuration(10);
    if (m_isVad) {
        m_session = krispAudioVadCreateSession(
                                               krisp_rate,
                                               krisp_duration,
                                               "default"
                                               );
    } else {
        m_session = krispAudioNcCreateSession(
                                              krisp_rate,
                                              krisp_rate,
                                              krisp_duration,
                                              "default"
                                              );
    }
}

void KrispProcessingModule::destroy() {
    if (m_isVad) {
            krispAudioVadCloseSession(m_session);
        } else {
            krispAudioNcCloseSession(m_session);
        }
    krispAudioGlobalDestroy();
}

void KrispProcessingModule::initSession(const int sampleRateHz, const int numChannels)
{
    if (m_session == nullptr) {
        createSession(sampleRateHz);
        m_sampleRateHz = sampleRateHz;
    } else {
        if (sampleRateHz != m_sampleRateHz) {
            m_sampleRateHz = sampleRateHz;
            resetSampleRate(m_sampleRateHz);
        }
    }
    m_numChannels = numChannels;
}

void KrispProcessingModule::frameProcess(const size_t channelNumber, const size_t num_bands, const size_t bufferSize, float * _Nonnull  buffer) {
    
    if (m_session == nullptr) {
      NSLog(@"KrispProcessingModule: Session creation failed ");
      return;
    }

    int num_frames = (int)bufferSize;
    int rate = num_frames*100;

    if(rate != m_sampleRateHz) {
        resetSampleRate(rate);
    }

    std::vector<float> bufferIn;
    std::vector<float> bufferOut;
    bufferIn.resize(num_frames);
    bufferOut.resize(num_frames);

    for (int index = 0; index < num_frames; ++index) {
        bufferIn[index] = buffer[index] / 32768.f;
    }

    KrispAudioSessionID session = m_session;
    if (m_isVad) {
        const auto retValue = krispAudioVadFrameFloat(session, bufferIn.data(), num_frames);
        if (retValue >= 0.8 || retValue <= 0.2) {
            NSLog(@"KrispProcessingModule: Krisp VAD cleanup error:%f", retValue);
            return;
        } else {
            for (int index = 0; index < num_frames; ++index) {
                buffer[index] = bufferIn[index] * 32768.f;
            }
            return;
        }
    } else {
        const auto retValue = krispAudioNcCleanAmbientNoiseFloat(session, bufferIn.data(), num_frames, bufferOut.data(),num_frames);
        if (retValue != 0) {
            NSLog(@"KrispProcessingModule: Krisp noise cleanup error");
            return;
        }
    }

    for (int index = 0; index < num_frames; ++index) {
        buffer[index] = bufferOut[index] * 32768.f;
    }
}

