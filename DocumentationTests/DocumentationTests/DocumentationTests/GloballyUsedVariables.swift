import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

var apiKey = ""
var user = User(id: "")
var token = UserToken(stringLiteral: "")
var callId = ""
var tokenProvider: UserTokenProvider = { _ in }
var streamVideo = StreamVideo(apiKey: apiKey, user: user, token: token)
var streamVideoUI = StreamVideoUI(streamVideo: streamVideo)
var call = streamVideo.call(callType: "default", callId: UUID().uuidString)
var utils = Utils()
@MainActor var viewModel = CallViewModel()
@MainActor var viewFactory = DefaultViewFactory.shared
var availableFrame = CGRect.zero
var availableSize = CGSize.zero
var videoSize = CGSize.zero
var participant = CallParticipant(
    id: "",
    userId: "",
    roles: [],
    name: "",
    profileImageURL: nil,
    trackLookupPrefix: nil,
    hasVideo: false,
    hasAudio: false,
    isScreenSharing: false,
    showTrack: false,
    isDominantSpeaker: false,
    sessionId: "",
    connectionQuality: .unknown,
    joinedAt: .init(),
    audioLevel: 0,
    audioLevels: [],
    pin: nil
)
var contentMode = UIView.ContentMode.scaleAspectFit
var id = ""
var customData = [String: RawJSON]()
var ratio: CGFloat = 0
var onChangeTrackVisibility: @MainActor(CallParticipant, Bool) -> Void = { _, _ in }
var orientation: UIInterfaceOrientation = .unknown
var localParticipant = participant
var reader: GeometryProxy!
var participants = [participant]
var imageURL: URL!
var members: [MemberRequest] = []

func container(_ content: () -> Void) {}
func asyncContainer(_ content: () async throws -> Void) {}
func viewContainer(@ViewBuilder _ content: () -> some View) {}
func classContainer<V: AnyObject>(_ content: (V) -> Void) {}

struct UserCredentials {
    let user: User
    let token: UserToken
}

extension UserCredentials {
    static let demoUser = UserCredentials(
        user: User(
            id: "testuser",
            name: "Test User",
            imageURL: URL(string: "")!,
            customData: [:]
        ),
        token: UserToken(rawValue: "")
    )
}

class CustomType {
    // your custom logic here
}
struct CustomInjectionKey: InjectionKey {
    static var currentValue: CustomType = CustomType()
}
extension InjectedValues {
    /// Provides access to the `CustomType` instance in the views and view models.
    var customType: CustomType {
        get {
            Self[CustomInjectionKey.self]
        }
        set {
            Self[CustomInjectionKey.self] = newValue
        }
    }
}

final class CustomViewFactory: ViewFactory {}
final class VideoWithChatViewFactory: ViewFactory {
    static let shared = VideoWithChatViewFactory()
}
struct YourRootView: View { @ViewBuilder var body: some View { EmptyView() } }
var outgoingCallMembers = [Member]()
@MainActor var callControls = CallControlsView(viewModel: viewModel)
@MainActor var callTopView = CallTopView(viewModel: viewModel)
struct CustomOutgoingCallView: View {
    var viewModel: CallViewModel
    var body: some View { EmptyView() }
}

struct CustomIncomingCallView: View {
    var viewModel: CallViewModel
    var callInfo: IncomingCall
    var body: some View { EmptyView() }
}

struct CustomCallView<Factory: ViewFactory>: View {
    var viewFactory: Factory
    var viewModel: CallViewModel
    var body: some View { EmptyView() }
}

struct CustomCallControlsView: View {
    var viewModel: CallViewModel
    var body: some View { EmptyView() }
}

struct ChatCallControls: View {
    var viewModel: CallViewModel
    var body: some View { EmptyView() }
}

struct CustomCallTopView: View {
    var viewModel: CallViewModel
    var body: some View { EmptyView() }
}

struct HomeView: View {
    var viewModel: CallViewModel
    var body: some View { EmptyView() }
}

struct CustomScreenSharingView: View {
    var viewModel: CallViewModel
    var screenSharing: ScreenSharingSession
    var availableFrame: CGRect
    var body: some View { EmptyView() }
}

struct CustomVideoParticipantsView<Factory: ViewFactory>: View {
    var viewFactory: Factory
    var viewModel: CallViewModel
    var availableFrame: CGRect
    var onChangeTrackVisibility: (CallParticipant, Bool) -> Void
    var body: some View { EmptyView() }
}

struct CustomCallParticipantsInfoView: View {
    var callViewModel: CallViewModel
    var availableFrame: CGRect
    var body: some View { EmptyView() }
}

final class MockUserListProvider: UserListProvider {
    func loadNextUsers(pagination: StreamVideoSwiftUI.Pagination) async throws -> [User] {
        []
    }
}

struct SomeOtherView: View { var body: some View { EmptyView() } }
struct YourView: View { var body: some View { EmptyView() } }
struct YourHostingView: View { var body: some View { EmptyView() } }
struct YourHostView: View { var body: some View { EmptyView() } }
struct ViewThatHostsCall: View { var body: some View { EmptyView() } }
struct ViewThatHostsCall: View { var body: some View { EmptyView() } }

struct LongPressToFocusViewModifier: ViewModifier {

    var availableFrame: CGRect

    var handler: (CGPoint) -> Void

    func body(content: Content) -> some View {
        content
            .gesture(
                LongPressGesture(minimumDuration: 0.5)
                    .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .local))
                    .onEnded { value in
                        switch value {
                        case .second(true, let drag):
                            if let location = drag?.location {
                                handler(convertToPointOfInterest(location))
                            }
                        default:
                            break
                        }
                    }
            )
    }

    func convertToPointOfInterest(_ point: CGPoint) -> CGPoint {
        CGPoint(
            x: point.y / availableFrame.height,
            y: 1.0 - point.x / availableFrame.width
        )
    }
}

extension View {
    @ViewBuilder
    func longPressToFocus(
        availableFrame: CGRect,
        handler: @escaping (CGPoint) -> Void
    ) -> some View {
        modifier(
            LongPressToFocusViewModifier(
                availableFrame: availableFrame,
                handler: handler
            )
        )
    }
}

struct DeeplinkInfo: Equatable {
    var url: URL?
    var callId: String
    var callType: String

    static let empty = DeeplinkInfo(callId: "", callType: "")
}

final class AppState: ObservableObject {

    enum UserState { case notLoggedIn, loggedIn }

    var apiKey: String = ""
    var userState: UserState = .notLoggedIn
    @Published var deeplinkInfo: DeeplinkInfo = .empty
    var currentUser: User?
    var loading = false
    var activeCall: Call?
    var activeAnonymousCallId: String = ""
    var voIPPushToken: String?
    var pushToken: String?

    let unsecureRepository = UnsecureRepository()

    static var shared = AppState()
}

final class UnsecureRepository: VoIPTokenHandler {
    func save(voIPPushToken: String?) {

    }
    
    func currentVoIPPushToken() -> String? {
        nil
    }
}

var appState = AppState()

extension URL {

    var queryParameters: [String: String] {
        guard
            let components = URLComponents(url: self, resolvingAgainstBaseURL: true),
            let queryItems = components.queryItems else { return [:] }
        return queryItems.reduce(into: [String: String]()) { (result, item) in
            result[item.name] = item.value
        }
    }
}

protocol VoIPTokenHandler {

    func save(voIPPushToken: String?)

    func currentVoIPPushToken() -> String?

}

final class CallKitService {
    
    func reportIncomingCall(
        callCid: String,
        displayName: String,
        callerId: String,
        completion: @escaping (Error?) -> Void
    ) {}
}
