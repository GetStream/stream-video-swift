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

    init(_ call: Call, dismiss: @escaping () -> Void) {
        self.call = call
        self.dismiss = dismiss
    }

    var body: some View {
        NavigationView {
            contentView
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        closeButton
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .background(Color(tokens.colors.backgroundCoreElevation1).edgesIgnoringSafeArea(.all))
                .modifier(DemoSheetBackgroundModifier(color: tokens.colors.backgroundCoreElevation1))
        }
        .navigationViewStyle(.stack)
        .toastView(toast: $toast)
        .onAppear { checkIfDisconnectionErrorIsAvailable() }
    }

    private var closeButton: some View {
        Button(action: dismiss) {
            videoAppearance.images.xmark
                .resizable()
                .renderingMode(.template)
                .aspectRatio(contentMode: .fit)
                .padding(tokens.layout.spacingXxs)
                .frame(width: tokens.layout.iconSizeMd, height: tokens.layout.iconSizeMd)
                .foregroundColor(Color(tokens.colors.textPrimary))
        }
        .accessibility(identifier: "Close")
    }

    private var contentView: some View {
        ScrollView {
            VStack(spacing: tokens.layout.spacingXl) {
                Image("feedbackLogo")

                VStack(spacing: tokens.layout.spacingXs) {
                    Text("How is your call going?")
                        .font(tokens.fonts.title3.bold())
                        .foregroundColor(Color(tokens.colors.textPrimary))
                        .lineLimit(1)

                    Text("All feedback is celebrated!")
                        .font(tokens.fonts.body)
                        .foregroundColor(Color(tokens.colors.textSecondary))
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .multilineTextAlignment(.center)

                VStack(spacing: tokens.layout.spacingMd) {
                    TextField(
                        "Email Address *",
                        text: $email
                    )
                    .textFieldStyle(DemoTextfieldStyle())

                    DemoTextEditor(text: $comment, placeholder: "Message")

                    HStack(spacing: tokens.layout.spacingXs) {
                        Text("Rate Quality")
                            .font(tokens.fonts.bodyBold)
                            .foregroundColor(Color(tokens.colors.textPrimary))
                            .frame(maxWidth: .infinity, alignment: .leading)

                        DemoStarRatingView(rating: $rating)
                    }
                }

                HStack(spacing: tokens.layout.spacingMd) {
                    DemoFeedbackButton(title: "Contact Us", style: .secondary) {
                        resignFirstResponder()
                        openURL(.init(string: "https://getstream.io/video/#contact")!)
                    }

                    DemoFeedbackButton(
                        title: "Submit",
                        style: .primary,
                        isEnabled: !email.isEmpty,
                        isLoading: isSubmitting,
                        action: submit
                    )
                }
            }
            .padding(tokens.layout.spacingMd)
        }
    }

    // MARK: - Private helpers

    private var tokens: DesignSystemTokens { videoAppearance.tokens }

    private func submit() {
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
    }

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

private struct DemoFeedbackButton: View {

    enum Style { case primary, secondary }

    @Injected(\.videoAppearance) private var videoAppearance

    var title: String
    var style: Style
    var isEnabled = true
    var isLoading = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: foregroundColor))
                } else {
                    Text(title)
                        .font(tokens.fonts.bodyBold)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: tokens.layout.buttonVisualHeightLg)
            .foregroundColor(foregroundColor)
            .background(Capsule().fill(backgroundColor))
            .overlay(Capsule().stroke(borderColor, lineWidth: 1))
            .contentShape(Capsule())
        }
        .buttonStyle(DemoFeedbackButtonStyle())
        .disabled(!isEnabled || isLoading)
    }

    private var foregroundColor: Color {
        switch style {
        case .primary:
            return Color(isEnabled ? tokens.colors.textOnAccent : tokens.colors.textDisabled)
        case .secondary:
            return Color(tokens.colors.buttonSecondaryText)
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .primary:
            return Color(isEnabled ? tokens.colors.accentPrimary : tokens.colors.backgroundUtilityDisabled)
        case .secondary:
            return Color(tokens.colors.buttonSecondaryBackground)
        }
    }

    private var borderColor: Color {
        switch style {
        case .primary:
            return backgroundColor
        case .secondary:
            return Color(tokens.colors.buttonSecondaryBorder)
        }
    }

    private var tokens: DesignSystemTokens { videoAppearance.tokens }
}

private struct DemoFeedbackButtonStyle: ButtonStyle {

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

private struct DemoSheetBackgroundModifier: ViewModifier {

    var color: UIColor

    func body(content: Content) -> some View {
        if #available(iOS 16.4, *) {
            content
                .toolbarBackground(Color(color), for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .presentationBackground(Color(color))
        } else if #available(iOS 16.0, *) {
            content
                .toolbarBackground(Color(color), for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
        } else {
            content
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
