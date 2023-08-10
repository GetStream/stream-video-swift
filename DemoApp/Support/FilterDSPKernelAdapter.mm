/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The adapter object that provides a Swift-accessible interface to the filter's underlying DSP code.
*/

#import <AVFoundation/AVFoundation.h>
#import <CoreAudioKit/AUViewController.h>
#import "FilterDSPKernel.hpp"
#import "BufferedAudioBus.hpp"
#import "FilterDSPKernelAdapter.h"

@implementation FilterDSPKernelAdapter {
    // C++ members need to be ivars; they would be copied on access if they were properties.
    FilterDSPKernel  _kernel;
    BufferedInputBus _inputBus;
}

- (instancetype)init {

    if (self = [super init]) {
        AVAudioFormat *format = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:44100 channels:2];
        // Create a DSP kernel to handle the signal processing.
        _kernel.init(format.channelCount, format.sampleRate);
        _kernel.setParameter(FilterParamCutoff, 0);
        _kernel.setParameter(FilterParamResonance, 0);

        // Create the input and output busses.
        _inputBus.init(format, 8);
        _outputBus = [[AUAudioUnitBus alloc] initWithFormat:format error:nil];
    }
    return self;
}

- (AUAudioUnitBus *)inputBus {
    return _inputBus.bus;
}

- (NSArray<NSNumber *> *)magnitudesForFrequencies:(NSArray<NSNumber *> *)frequencies {
    FilterDSPKernel::BiquadCoefficients coefficients;

    double inverseNyquist = 2.0 / self.outputBus.format.sampleRate;

    coefficients.calculateLopassParams(_kernel.cutoffRamper.getUIValue(), _kernel.resonanceRamper.getUIValue());

    NSMutableArray<NSNumber *> *magnitudes = [NSMutableArray arrayWithCapacity:frequencies.count];

    for (NSNumber *number in frequencies) {
        double frequency = [number doubleValue];
        double magnitude = coefficients.magnitudeForFrequency(frequency * inverseNyquist);

        [magnitudes addObject:@(magnitude)];
    }

    return [NSArray arrayWithArray:magnitudes];
}

- (void)setParameter:(AUParameter *)parameter value:(AUValue)value {
    _kernel.setParameter(parameter.address, value);
}

- (AUValue)valueForParameter:(AUParameter *)parameter {
    return _kernel.getParameter(parameter.address);
}

- (AUAudioFrameCount)maximumFramesToRender {
    return _kernel.maximumFramesToRender();
}

- (void)setMaximumFramesToRender:(AUAudioFrameCount)maximumFramesToRender {
    _kernel.setMaximumFramesToRender(maximumFramesToRender);
}

- (BOOL)shouldBypassEffect {
    return _kernel.isBypassed();
}

- (void)setShouldBypassEffect:(BOOL)bypass {
    _kernel.setBypass(bypass);
}

- (void)allocateRenderResources {
    _inputBus.allocateRenderResources(self.maximumFramesToRender);
    _kernel.init(self.outputBus.format.channelCount, self.outputBus.format.sampleRate);
    _kernel.reset();
}

- (void)deallocateRenderResources {
    _inputBus.deallocateRenderResources();
}

#pragma mark - AUAudioUnit (AUAudioUnitImplementation)

// Subclasses must provide an AUInternalRenderBlock (via a getter) to implement rendering.
- (AUInternalRenderBlock)internalRenderBlock {
    /*
     Capture in locals to avoid ObjC member lookups. Don't capture "self" in render.
     */
    // Specify that captured objects are mutable.
    __block FilterDSPKernel *state = &_kernel;
    __block BufferedInputBus *input = &_inputBus;

    return ^AUAudioUnitStatus(AudioUnitRenderActionFlags *actionFlags,
                              const AudioTimeStamp       *timestamp,
                              AVAudioFrameCount           frameCount,
                              NSInteger                   outputBusNumber,
                              AudioBufferList            *outputData,
                              const AURenderEvent        *realtimeEventListHead,
                              AURenderPullInputBlock      pullInputBlock) {

        AudioUnitRenderActionFlags pullFlags = 0;

        if (frameCount > state->maximumFramesToRender()) {
            return kAudioUnitErr_TooManyFramesToProcess;
        }

        AUAudioUnitStatus err = input->pullInput(&pullFlags, timestamp, frameCount, 0, pullInputBlock);

        if (err != 0) { return err; }

        AudioBufferList *inAudioBufferList = input->mutableAudioBufferList;

        /*
         Important:
         If the caller passes non-null output pointers (outputData->mBuffers[x].mData),
         use those.

         If the caller passed null output buffer pointers, process them in memory the
         audio unit owns and modify the (outputData->mBuffers[x].mData) pointers to
         point to this owned memory. The audio unit is responsible for preserving the
         validity of this memory until the next call to render, or you call
         deallocateRenderResources.

         If your algorithm can't process in-place, you need to preallocate an
         output buffer and use it here.

         See the description of the canProcessInPlace property.
         */

        // If you receive null output buffer pointers, process them in-place in the
        // input buffer.
        AudioBufferList *outAudioBufferList = outputData;
        if (outAudioBufferList->mBuffers[0].mData == nullptr) {
            for (UInt32 i = 0; i < outAudioBufferList->mNumberBuffers; ++i) {
                outAudioBufferList->mBuffers[i].mData = inAudioBufferList->mBuffers[i].mData;
            }
        }

        state->setBuffers(inAudioBufferList, outAudioBufferList);
        state->processWithEvents(timestamp, frameCount, realtimeEventListHead, nil /* MIDIOutEventBlock */);

        return noErr;
    };
}

@end
