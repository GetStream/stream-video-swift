//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct DemoFeedbackView: View {

    @Environment(\.openURL) private var openURL
    @Injected(\.videoAppearance) private var videoAppearance

    @State private var email: String = ""
    @State private var comment: String = ""
    @State private var rating: Int = 5
    @State private var isSubmitting = false
    @State private var toast: Toast?

    private weak var call: Call?
    private var dismiss: () -> Void
    private var isSubmitEnabled: Bool { !email.isEmpty && !isSubmitting }

    init(_ call: Call, dismiss: @escaping () -> Void) {
        self.call = call
        self.dismiss = dismiss
    }

    var body: some View {
        ScrollView {
            VStack(spacing: tokens.layout.spacing2xl) {
                Image("feedbackLogo")

                VStack(spacing: tokens.layout.spacingXs) {
                    Text("How is your call going?")
                        .font(tokens.fonts.headline)
                        .foregroundColor(Color(tokens.colors.textPrimary))
                        .lineLimit(1)

                    Text("All feedback is celebrated!")
                        .font(tokens.fonts.subheadline)
                        .foregroundColor(Color(tokens.colors.textSecondary))
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .multilineTextAlignment(.center)

                VStack(spacing: tokens.layout.spacingXl) {
                    VStack(spacing: tokens.layout.spacingMd) {
                        TextField(
                            "Email Address *",
                            text: $email
                        )
                        .textFieldStyle(DemoTextfieldStyle())

                        DemoTextEditor(text: $comment, placeholder: "Message")
                    }

                    HStack(spacing: tokens.layout.spacingXs) {
                        Text("Rate Quality")
                            .font(tokens.fonts.body)
                            .foregroundColor(Color(tokens.colors.textSecondary))
                            .frame(maxWidth: .infinity, alignment: .leading)

                        DemoStarRatingView(rating: $rating)
                    }
                }

                HStack(spacing: tokens.layout.spacingXs) {
                    Button {
                        resignFirstResponder()
                        openURL(.init(string: "https://getstream.io/video/#contact")!)
                    } label: {
                        Text("Contact Us")
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(Color(tokens.colors.buttonSecondaryText))
                    .padding(.vertical, tokens.layout.spacingXxs)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color(tokens.colors.buttonSecondaryBorder), lineWidth: 1))

                    Button {
                        resignFirstResponder()
                        isSubmitting = true
                        Task {
                            do {
                                try await call?.collectUserFeedback(
                                    rating: rating,
                                    reason: """
                                    \(email)
                                    \(comment)
                                    """
                                )
                                Task { @MainActor in
                                    dismiss()
                                }
                                isSubmitting = false
                            } catch {
                                log.error(error)
                                dismiss()
                                isSubmitting = false
                            }
                        }
                    } label: {
                        if isSubmitting {
                            ProgressView()
                        } else {
                            Text("Submit")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(
                        Color(isSubmitEnabled ? tokens.colors.buttonPrimaryTextOnAccent : tokens.colors.textDisabled)
                    )
                    .padding(.vertical, tokens.layout.spacingXxs)
                    .background(
                        Color(isSubmitEnabled ? tokens.colors.buttonPrimaryBackground : tokens.colors.backgroundUtilityDisabled)
                    )
                    .disabled(!isSubmitEnabled)
                    .clipShape(Capsule())
                }

                Spacer()
            }
            .padding(.horizontal, tokens.layout.spacingMd)
        }
        .withModalNavigationBar(title: "", closeAction: dismiss)
        .toastView(toast: $toast)
        .onAppear { checkIfDisconnectionErrorIsAvailable() }
    }

    // MARK: - Private helpers

    private var tokens: DesignSystemTokens { videoAppearance.tokens }

    @MainActor
    func checkIfDisconnectionErrorIsAvailable() {
        if call?.state.disconnectionError is ClientError.NetworkNotAvailable {
            toast = .init(
                style: .error,
                message: "Your call was ended because it seems your internet connection is down."
            )
        }
    }
}

struct DemoStarRatingView: View {
    @Injected(\.videoAppearance) private var videoAppearance

    var rating: Binding<Int>

    private var range: ClosedRange<Int>

    init(
        rating: Binding<Int>,
        minRating: Int = 1,
        maxRating: Int = 5
    ) {
        self.rating = rating
        range = minRating...maxRating
    }

    var body: some View {
        HStack(spacing: tokens.layout.spacingXs) {
            ForEach(range, id: \.self) { index in
                Image(systemName: index <= rating.wrappedValue ? "star.fill" : "star")
                    .resizable()
                    .frame(width: tokens.layout.iconSizeLg, height: tokens.layout.iconSizeLg)
                    .foregroundColor(Color(tokens.colors.accentWarning))
                    .onTapGesture {
                        rating.wrappedValue = index
                    }
            }
        }
    }

    private var tokens: DesignSystemTokens { videoAppearance.tokens }
}
