//
//  FeedbackPromptView.swift
//
//
//  Created by Will Taylor on 6/3/24.
//

import SwiftUI
import os

@MainActor
public struct FeedbackPromptView: View {

    private enum ViewState: Equatable {
        case initialPrompt(showEntirePrompt: Bool)
        case feedbackResponseGreat
        case feedbackResponseGood
        case feedbackResponseOkay
        case feedbackResponseBad
        case collectFeedback
        case noAppID
    }

    @State private var title: String?
    @State private var appName: String = ""
    @State private var appReviewURL: URL!
    @State private var state: ViewState = .initialPrompt(showEntirePrompt: false)

    private let userID: String?
    private let isUserSubscribed: Bool?
    private let displayCloseButton: Bool

    @Environment(\.openURL) var openURL

    let onDismiss: () -> Void

    public init(
        userID: String? = nil,
        isUserSubscribed: Bool? = nil,
        displayCloseButton: Bool,
        onDismiss: @escaping () -> Void
    ) {
        self.userID = userID
        self.isUserSubscribed = isUserSubscribed
        self.displayCloseButton = displayCloseButton
        self.onDismiss = onDismiss
    }

    public var body: some View {
        VStack {
            if self.displayCloseButton {
                HStack {
                    Spacer()
                    Button {
                        self.onDismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                    }
                    .tint(Color.secondary)
                    .accessibilityLabel(Text("Close"))
                }
            }
            
            switch self.state {
            case .initialPrompt(let showEntirePrompt):
                InitialPromptView(showEntirePrompt: showEntirePrompt)
                    .transition(.slide)
            case .collectFeedback:
                CollectFeedbackView()
                    .transition(.scale)
            case .feedbackResponseGreat:
                FeedbackResponseView(
                    title: "✨ Awesome!",
                    responseBody:
                        """
                        We’re thrilled that you're having a great time with \(self.appName)! Your support means the world to us.

                        If you have a moment, would you mind leaving us a 5-star review? It helps us out a ton and helps other people discover \(self.appName)!

                        Thank you so much for being a part of our community!

                        Best,
                        The \(self.appName) Team
                        """,
                    affirmativeButtonText: "Leave a Review",
                    affirmativeButtonIcon: "star.bubble",
                    affirmativeButtonAction: { self.openURL(appReviewURL) }
                )
                    .transition(.scale)
            case .feedbackResponseGood:
                FeedbackResponseView(
                    title: "😎 Cool!",
                    responseBody:
                        """
                        We're glad you're enjoying \(self.appName)!

                        What are your favorite parts of the app, and what do you think we could do better? We'd love your feedback!
                        """,
                    affirmativeButtonText: "Provide Feedback",
                    affirmativeButtonIcon: "captions.bubble",
                    affirmativeButtonAction: { self.state = .collectFeedback }
                )
                    .transition(.scale)
            case .feedbackResponseOkay:
                FeedbackResponseView(
                    title: "🙂 Nice!",
                    responseBody:
                        """
                        Thanks for trying out \(self.appName)!

                        Have any suggestions for things that we could make better? We'd appreciate your feedback so we can improve the app!
                        """,
                    affirmativeButtonText: "Provide Feedback",
                    affirmativeButtonIcon: "captions.bubble",
                    affirmativeButtonAction: { self.state = .collectFeedback }
                )
                    .transition(.scale)
            case .feedbackResponseBad:
                FeedbackResponseView(
                    title: "😕 Sorry to Hear That!",
                    responseBody:
                        """
                        Would you mind letting us know what we can improve to make the experience better?
                        """,
                    affirmativeButtonText: "Provide Feedback",
                    affirmativeButtonIcon: "captions.bubble",
                    affirmativeButtonAction: { self.state = .collectFeedback }
                )
                    .transition(.scale)
            case .noAppID:
                NoAppIDView()
            }
        }
        .padding(.horizontal)
        .task {
            guard let appReviewURL = FeedbackKit.shared.appReviewURL else {
                FeedbackKit.shared.logNoAppIDMessage()
                return
            }
            self.appReviewURL = appReviewURL
            self.calculateInitialPromptStrings()

            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 sec
            self.state = .initialPrompt(showEntirePrompt: true)
        }
        .animation(.easeInOut(duration: 0.5), value: self.state)
    }
}

// MARK: - InitialPromptView
extension FeedbackPromptView {

    @ViewBuilder
    func InitialPromptView(showEntirePrompt: Bool) -> some View {
        VStack(alignment: .leading) {
            if let title = self.title {
                HStack(alignment: .top) {
                    Text("🥳")
                        .font(.largeTitle)
                    Text(title)
                        .font(.headline)
                        .padding(.trailing)
                    if showEntirePrompt {
                        Spacer()
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top)
            }

            Spacer()
                .frame(maxHeight: 32)

            if showEntirePrompt {
                Group {
                    Text("Thanks for giving \(self.appName) a shot! How's everything been so far?")
                        .padding(.bottom)

                    VStack(alignment: .center, spacing: 16) {
                        Button {
                            withAnimation {
                                self.state = .feedbackResponseGreat
                            }
                        } label: {
                            Text("🤩 Great!")
                                .padding(.vertical, 8)
                                .frame(minWidth: 150)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                        .shadow(radius: 8)

                        Button {
                            self.state = .feedbackResponseGood
                        } label: {
                            Text("😄 Good")
                                .padding(.vertical, 8)
                                .frame(minWidth: 150)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                        .shadow(radius: 8)

                        Button {
                            self.state = .feedbackResponseOkay
                        } label: {
                            Text("🤷‍♂️ Okay")
                                .padding(.vertical, 8)
                                .frame(minWidth: 150)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.gray)
                        .shadow(radius: 8)

                        Button {
                            self.state = .feedbackResponseBad
                        } label: {
                            Text("😢 Bad")
                                .padding(.vertical, 8)
                                .frame(minWidth: 150)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        .shadow(radius: 8)
                    }
                    .frame(maxWidth: .infinity)

                    Spacer()
                }
            }
        }

    }

    private func calculateInitialPromptStrings() {
        let config = FeedbackKit.shared.config
        self.appName = config?.appName ?? "the app"
        self.title = "Thanks for using \(config?.appName ?? "the app")!"
    }
}

// MARK: - FeedbackResponseView
extension FeedbackPromptView {

    @ViewBuilder
    func FeedbackResponseView(
        title: String,
        responseBody: String,
        affirmativeButtonText: String,
        affirmativeButtonIcon: String,
        affirmativeButtonAction: @escaping () -> Void
    ) -> some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading) {
                Text(title)
                    .font(.title)
                    .padding(.top)

                Text(responseBody)
                .lineLimit(nil)
                .multilineTextAlignment(.leading)
                .padding([.bottom, .top])

                Spacer()
                    .frame(height: 32)


                HStack {
                    Spacer()
                    Button {
                        self.onDismiss()
                    } label: {
                        Text("No Thanks")
                    }

                    Divider()
                        .frame(maxHeight: 16)

                    Button {
                        affirmativeButtonAction()
                    } label: {
                        Label(
                            title: { Text(affirmativeButtonText) },
                            icon: { Image(systemName: affirmativeButtonIcon) }
                        )
                    }
                    .buttonStyle(BorderedProminentButtonStyle())
                    Spacer()
                }
            }
        }
    }
}

// MARK: - CollectFeedbackView
extension FeedbackPromptView {

    @ViewBuilder
    func CollectFeedbackView() -> some View {
        ProvideFeedbackView(
            feedbackType: .generalFeedback,
            showText: false,
            userID: userID,
            isUserSubscribed: self.isUserSubscribed,
            onDismiss: { self.onDismiss() }
        )
    }
}

// MARK: - NoAppIDView
extension FeedbackPromptView {

    @ViewBuilder
    func NoAppIDView() -> some View {
        ZStack {
            Color.red
                .ignoresSafeArea()
            VStack {
                Text("ERROR")
                    .font(.largeTitle)
                    .padding(.bottom)

                Text("No App ID was provided to FeedbackKit.\n\nWithout this, we are unable to prompt the user to provide a review. Please provide an App ID with configuring FeedbackKit.")
                    .lineLimit(nil)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    FeedbackPromptView(
        displayCloseButton: true,
        onDismiss: {}
    )
}
