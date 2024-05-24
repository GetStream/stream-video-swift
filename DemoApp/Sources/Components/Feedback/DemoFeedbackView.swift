//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct DemoFeedbackView: View {

    @Environment(\.openURL) private var openURL
    @Injected(\.appearance) private var appearance

    @State private var email: String = ""
    @State private var comment: String = ""
    @State private var rating: Int = 5
    @State private var isSubmitting = false

    private weak var call: Call?
    private var dismiss: () -> Void
    private var isSubmitEnabled: Bool { !email.isEmpty && !isSubmitting }

    init(_ call: Call, dismiss: @escaping () -> Void) {
        self.call = call
        self.dismiss = dismiss
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Image("feedbackLogo")

                VStack(spacing: 8) {
                    Text("How is your call going?")
                        .font(appearance.fonts.headline)
                        .foregroundColor(appearance.colors.text)
                        .lineLimit(1)

                    Text("All feedback is celebrated!")
                        .font(appearance.fonts.subheadline)
                        .foregroundColor(.init(appearance.colors.textLowEmphasis))
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .multilineTextAlignment(.center)

                VStack(spacing: 27) {
                    VStack(spacing: 16) {
                        TextField(
                            "Email Address *",
                            text: $email
                        )
                        .textFieldStyle(DemoTextfieldStyle())

                        DemoTextEditor(text: $comment, placeholder: "Message")
                    }

                    HStack {
                        Text("Rate Quality")
                            .font(appearance.fonts.body)
                            .foregroundColor(.init(appearance.colors.textLowEmphasis))
                            .frame(maxWidth: .infinity, alignment: .leading)

                        DemoStarRatingView(rating: $rating)
                    }
                }

                HStack {
                    Button {
                        resignFirstResponder()
                        openURL(.init(string: "https://getstream.io/video/#contact")!)
                    } label: {
                        Text("Contact Us")
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(appearance.colors.text)
                    .padding(.vertical, 4)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color(appearance.colors.textLowEmphasis), lineWidth: 1))

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
                    .foregroundColor(appearance.colors.text)
                    .padding(.vertical, 4)
                    .background(isSubmitEnabled ? appearance.colors.accentBlue : appearance.colors.lightGray)
                    .disabled(!isSubmitEnabled)
                    .clipShape(Capsule())
                }

                Spacer()
            }
            .padding(.horizontal)
        }
        .withModalNavigationBar(title: "", closeAction: dismiss)
    }
}

struct DemoStarRatingView: View {
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
        HStack {
            ForEach(range, id: \.self) { index in
                Image(systemName: index <= rating.wrappedValue ? "star.fill" : "star")
                    .resizable()
                    .frame(width: 30, height: 30)
                    .foregroundColor(.yellow)
                    .onTapGesture {
                        rating.wrappedValue = index
                    }
            }
        }
    }
}
