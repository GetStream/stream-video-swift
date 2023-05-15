# SDK Size Impact

When developing a mobile app, one crucial performance metric is app size. An app’s size can be difficult to accurately measure with multiple variants and device spreads. Once measured, it’s even more difficult to understand and identify what’s contributing to size bloat.

This document provides an analysis of the impact of adding StreamVideo and StreamVideoSwiftUI iOS SDKs to an existing mobile application. The analysis includes the size of the SDKs and the impact on the app's binary size.

## SDK Information

|                     | StreamVideo | StreamVideoSwiftUI |
|---------------------|:-:|:-:|
| **Download Size:**  | 4.20 MB | 2.85 MB |
| **Installed Size:** | 4.74 MB | 3.35 MB |

### Analysis

The following analysis was conducted using the `mdls -n kMDItemPhysicalSize` command in Terminal after building the app with and without the SDK.

1. **SwiftVideo**

    |                    | w/o framework | with framework | difference |
    |--------------------|:-:|:-:|:-:|
    | App Size (Release) | 13_463_552 | 18_440_192 | 4_976_640 |

2. **StreamVideoSwiftUI**

    |                    | w/o framework | with framework | difference |
    |--------------------|:-:|:-:|:-:|
    | App Size (Release)| 13_463_552 | 16_986_112 | 3_522_560 |

The tables above show the impact of integrating the SDKs on the app's binary size, in bytes.

## Conclusion

Based on the analysis conducted, both StreamVideo and StreamVideoSwiftUI SDKs are lightweight and optimized for optimal performance. We are confident that our Video SDKs will enhance the functionality of your app without compromising its performance or increasing its binary size significantly.

At Stream, the iOS SDK team rely on Emerge Tools’ size analysis service to analyze and monitor the binary size of our SDKs and prevent regressions in our SDK deployment size. As an integral part of our CI pipeline, Emerge Tools helps us ensure that we deliver the highest quality SDK to our customers.
