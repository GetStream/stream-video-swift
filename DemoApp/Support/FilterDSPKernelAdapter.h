/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The adapter object that provides a Swift-accessible interface to the filter's underlying DSP code.
*/

#import <AudioToolbox/AudioToolbox.h>

@class AUv3FilterDemoViewController;

NS_ASSUME_NONNULL_BEGIN

@interface FilterDSPKernelAdapter : NSObject

@property (nonatomic) AUAudioFrameCount maximumFramesToRender;
@property (nonatomic, readonly) AUAudioUnitBus *inputBus;
@property (nonatomic, readonly) AUAudioUnitBus *outputBus;

- (void)setParameter:(AUParameter *)parameter value:(AUValue)value;
- (AUValue)valueForParameter:(AUParameter *)parameter;

- (void)allocateRenderResources;
- (void)deallocateRenderResources;
- (AUInternalRenderBlock)internalRenderBlock;

- (NSArray<NSNumber *> *)magnitudesForFrequencies:(NSArray<NSNumber *> *)frequencies;

@end

NS_ASSUME_NONNULL_END
