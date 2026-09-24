#import <XCTest/XCTest.h>

extern void stream_video_test_configure_logging(void);

@interface StreamVideoTestLogObserver : NSObject <XCTestObservation>
@end

@implementation StreamVideoTestLogObserver

+ (void)load {
    [[XCTestObservationCenter sharedTestObservationCenter]
        addTestObserver:[self new]];
}

- (void)testBundleWillStart:(NSBundle *)testBundle {
    stream_video_test_configure_logging();
}

@end
