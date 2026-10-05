//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct DemoFeedbackView: View {

    @Environment(\.openURL) private var openURL
    @Injected(\.colors) private var colors
    @Injected(\.images) private var images
    @Injected(\.fonts) private var fonts
    @Injected(\.layout) private var layout

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
                .background(Color(colors.backgroundCoreElevation1).edgesIgnoringSafeArea(.all))
                .modifier(DemoSheetBackgroundModifier(color: colors.backgroundCoreElevation1))
        }
        .navigationViewStyle(.stack)
        .toastView(toast: $toast)
        .onAppear { checkIfDisconnectionErrorIsAvailable() }
    }

    private var closeButton: some View {
        Button(action: dismiss) {
            images.xmark
                .resizable()
                .renderingMode(.template)
                .aspectRatio(contentMode: .fit)
                .padding(layout.spacingXxs)
                .frame(width: layout.iconSizeMd, height: layout.iconSizeMd)
                .foregroundColor(Color(colors.textPrimary))
        }
        .accessibility(identifier: "Close")
    }

    private var contentView: some View {
        ScrollView {
            VStack(spacing: layout.spacingXl) {
                Image("feedbackLogo")

                VStack(spacing: layout.spacingXs) {
                    Text("How is your call going?")
                        .font(fonts.title3.bold())
                        .foregroundColor(Color(colors.textPrimary))
                        .lineLimit(1)

                    Text("All feedback is celebrated!")
                        .font(fonts.body)
                        .foregroundColor(Color(colors.textSecondary))
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .multilineTextAlignment(.center)

                VStack(spacing: layout.spacingMd) {
                    TextField(
                        "Email Address *",
                        text: $email
                    )
                    .textFieldStyle(DemoTextfieldStyle())

                    DemoTextEditor(text: $comment, placeholder: "Message")

                    HStack(spacing: layout.spacingXs) {
                        Text("Rate Quality")
                            .font(fonts.bodyBold)
                            .foregroundColor(Color(colors.textPrimary))
                            .frame(maxWidth: .infinity, alignment: .leading)

                        DemoStarRatingView(rating: $rating)
                    }
                }

                HStack(spacing: layout.spacingMd) {
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
            .padding(layout.spacingMd)
        }
    }

    // MARK: - Private helpers

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

    @Injected(\.colors) private var colors
    @Injected(\.fonts) private var fonts
    @Injected(\.layout) private var layout

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
                        .font(fonts.bodyBold)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: layout.buttonVisualHeightLg)
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
            return Color(isEnabled ? colors.textOnAccent : colors.textDisabled)
        case .secondary:
            return Color(colors.buttonSecondaryText)
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .primary:
            return Color(isEnabled ? colors.accentPrimary : colors.backgroundUtilityDisabled)
        case .secondary:
            return Color(colors.buttonSecondaryBackground)
        }
    }

    private var borderColor: Color {
        switch style {
        case .primary:
            return backgroundColor
        case .secondary:
            return Color(colors.buttonSecondaryBorder)
        }
    }
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
    @Injected(\.colors) private var colors
    @Injected(\.layout) private var layout

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
        HStack(spacing: layout.spacingXs) {
            ForEach(range, id: \.self) { index in
                Image(systemName: index <= rating.wrappedValue ? "star.fill" : "star")
                    .resizable()
                    .frame(width: layout.iconSizeLg, height: layout.iconSizeLg)
                    .foregroundColor(Color(colors.accentWarning))
                    .onTapGesture {
                        rating.wrappedValue = index
                    }
            }
        }
    }
}
