//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class StringExtensions_Tests: XCTestCase {
    
    func test_stringExtensions_opusFirst() {
        // Given
        let mdp = """
        v=0
        
        t=0 0

        a=group:BUNDLE 0
        
        m=audio 43427 UDP/TLS/RTP/SAVPF 111 63 103 104 9 102 0 8 106 105 13 110 112 113 126
        
        a=rtpmap:111 opus/48000/2

        a=extmap-allow-mixed

        a=fmtp:111 minptime=10;useinbandfec=1;usedtx=1

        a=rtpmap:63 red/48000/2

        a=fmtp:63 111/111
        """
        .replacingOccurrences(of: "\n\n", with: "\r\n")
        
        let expected = """
        v=0
        
        t=0 0

        a=group:BUNDLE 0
        
        m=audio 43427 UDP/TLS/RTP/SAVPF 63 111 103 104 9 102 0 8 106 105 13 110 112 113 126
        
        a=rtpmap:111 opus/48000/2

        a=extmap-allow-mixed

        a=fmtp:111 minptime=10;useinbandfec=1;usedtx=1

        a=rtpmap:63 red/48000/2

        a=fmtp:63 111/111
        """
        .replacingOccurrences(of: "\n\n", with: "\r\n")
        
        // When
        let updatedSdp = mdp.preferredRedCodec
        
        // Then
        XCTAssert(updatedSdp == expected)
    }
    
    func test_stringExtensions_redFirst() {
        // Given
        let mdp = """
        v=0
        
        t=0 0

        a=group:BUNDLE 0
        
        m=audio 43427 UDP/TLS/RTP/SAVPF 63 111 103 104 9 102 0 8 106 105 13 110 112 113 126
        
        a=rtpmap:63 red/48000/2
        
        a=rtpmap:111 opus/48000/2

        a=extmap-allow-mixed

        a=fmtp:111 minptime=10;useinbandfec=1;usedtx=1

        a=fmtp:63 111/111
        """
        .replacingOccurrences(of: "\n\n", with: "\r\n")
        
        let expected = """
        v=0
        
        t=0 0

        a=group:BUNDLE 0
        
        m=audio 43427 UDP/TLS/RTP/SAVPF 63 111 103 104 9 102 0 8 106 105 13 110 112 113 126
        
        a=rtpmap:63 red/48000/2
        
        a=rtpmap:111 opus/48000/2

        a=extmap-allow-mixed

        a=fmtp:111 minptime=10;useinbandfec=1;usedtx=1

        a=fmtp:63 111/111
        """
        .replacingOccurrences(of: "\n\n", with: "\r\n")
        
        // When
        let updatedSdp = mdp.preferredRedCodec
        
        // Then
        XCTAssert(updatedSdp == expected)
    }
    
    func test_stringExtensions_redMissing() {
        // Given
        let mdp = """
        v=0
        
        t=0 0

        a=group:BUNDLE 0
                
        a=rtpmap:111 opus/48000/2
        
        m=audio 43427 UDP/TLS/RTP/SAVPF 111 103 104 9 102 0 8 106 105 13 110 112 113 126

        a=extmap-allow-mixed

        a=fmtp:111 minptime=10;useinbandfec=1;usedtx=1

        a=fmtp:63 111/111
        """
        .replacingOccurrences(of: "\n\n", with: "\r\n")
        
        let expected = """
        v=0
        
        t=0 0

        a=group:BUNDLE 0
                
        a=rtpmap:111 opus/48000/2
        
        m=audio 43427 UDP/TLS/RTP/SAVPF 111 103 104 9 102 0 8 106 105 13 110 112 113 126

        a=extmap-allow-mixed

        a=fmtp:111 minptime=10;useinbandfec=1;usedtx=1

        a=fmtp:63 111/111
        """
        .replacingOccurrences(of: "\n\n", with: "\r\n")
        
        // When
        let updatedSdp = mdp.preferredRedCodec

        // Then
        XCTAssert(updatedSdp == expected)
    }
    
    func test_stringExtensions_opusMissing() {
        // Given
        let mdp = """
        v=0
        
        t=0 0

        a=group:BUNDLE 0
        
        m=audio 43427 UDP/TLS/RTP/SAVPF 63 103 104 9 102 0 8 106 105 13 110 112 113 126
        
        a=extmap-allow-mixed

        a=fmtp:111 minptime=10;useinbandfec=1;usedtx=1
        
        a=rtpmap:63 red/48000/2

        a=fmtp:63 111/111
        """
        .replacingOccurrences(of: "\n\n", with: "\r\n")
        
        let expected = """
        v=0
        
        t=0 0

        a=group:BUNDLE 0
        
        m=audio 43427 UDP/TLS/RTP/SAVPF 63 103 104 9 102 0 8 106 105 13 110 112 113 126
        
        a=extmap-allow-mixed

        a=fmtp:111 minptime=10;useinbandfec=1;usedtx=1
        
        a=rtpmap:63 red/48000/2

        a=fmtp:63 111/111
        """
        .replacingOccurrences(of: "\n\n", with: "\r\n")
        
        // When
        let updatedSdp = mdp.preferredRedCodec

        // Then
        XCTAssert(updatedSdp == expected)
    }
    
    func test_stringExtensions_wrongFormat() {
        // Given
        let mdp = """
        v=0
        t=0 0
        a=group:BUNDLE 0
        a=extmap-allow-mixed
        a=fmtp:111 minptime=10;useinbandfec=1;usedtx=1
        a=rtpmap:63 red/48000/2
        a=fmtp:63 111/111
        """
        .replacingOccurrences(of: "\n\n", with: "\r\n")
        
        let expected = """
        v=0
        t=0 0
        a=group:BUNDLE 0
        a=extmap-allow-mixed
        a=fmtp:111 minptime=10;useinbandfec=1;usedtx=1
        a=rtpmap:63 red/48000/2
        a=fmtp:63 111/111
        """
        .replacingOccurrences(of: "\n\n", with: "\r\n")
        
        // When
        let updatedSdp = mdp.preferredRedCodec
        
        // Then
        XCTAssert(updatedSdp == expected)
    }
}
