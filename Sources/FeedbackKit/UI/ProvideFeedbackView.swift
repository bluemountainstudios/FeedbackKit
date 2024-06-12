//
//  ProvideFeedbackView.swift
//
//
//  Created by Will Taylor on 6/3/24.
//

import SwiftUI

public enum FeedbackType: String, Codable {
    case featureRequest = "feature_request"
    case generalFeedback = "general_feedback"
    case issue
}

@MainActor
public struct ProvideFeedbackView: View {

    @State private var model = ProvideFeedbackViewModel()

    @FocusState var isTextEditorFocused: Bool

    private let copy: ProvideFeedbackViewCopy?
    private let showTextOnInitialPrompt: Bool

    public init(
        feedbackType: FeedbackType,
        copy: ProvideFeedbackViewCopy? = nil,
        showText: Bool = true,
        userID: String? = nil,
        isUserSubscribed: Bool? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        self.showTextOnInitialPrompt = showText
        self.copy = copy
        model.feedbackType = feedbackType
        model.userID = userID
        model.onDismiss = onDismiss
        model.isUserSubscribed = isUserSubscribed
    }

    internal enum ViewState {
        case notConfigured
        case enterFeedback
        case successfullyPostedFeedback
        case failedToPostFeedback
    }

    public var body: some View {
        ZStack {
            switch self.model.state {
            case .enterFeedback:
                EnterFeedbackView()
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            case .notConfigured:
                NotConfiguredView()
            case .successfullyPostedFeedback:
                SuccessView()
                    .padding(.top, 32)
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            case .failedToPostFeedback:
                FailureView()
                    .padding(.top, 32)
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            }
        }
        .padding(.horizontal)
        .navigationTitle(self.navigationTitle)
        .animation(.default, value: model.state)
    }

    @ViewBuilder
    private func NotConfiguredView() -> some View {
        Text("Not configured!")
    }

    @ViewBuilder
    private func EnterFeedbackView() -> some View {
        VStack(alignment: .leading) {

            if showTextOnInitialPrompt {
                Text(instructionsText)
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }


            Spacing()

            ScrollView(.vertical) {
                VStack(alignment: .leading) {
                    if showTextOnInitialPrompt {
                        Heading(text: self.navigationTitle)
                    }

                    TextEditor(text: $model.feedbackMessage)
                        .keyboardType(.default)
                        .focused($isTextEditorFocused)
                        .multilineTextAlignment(.leading)
                        .frame(minHeight: 256)
                        .overlay {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.secondary, lineWidth: 1.0)
                        }
                        .padding(2)
#if os(visionOS)
                        .background()
#else
                        .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                Spacer()
                                Button("Done") {
                                    self.isTextEditorFocused = false
                                }

                                Divider()

                                Button {
                                    self.isTextEditorFocused = false
                                    Task(priority: .userInitiated) {
                                        await self.model.submitFeedback()
                                    }
                                } label: {
                                    Text("Submit")
                                        .padding(.horizontal)
                                }
                                .buttonStyle(.borderedProminent)
                                .disabled(model.feedbackMessage.isEmpty)
                            }
                        }
#endif

                    Spacing()

                    Heading(text: "Email")
                    VStack(alignment: .leading, spacing: 0) {
                        TextField("Email", text: $model.replyEmail, prompt: Text("johnsmith@email.com"))
                            .keyboardType(.emailAddress)
                            .textCase(.lowercase)
                            .textContentType(.emailAddress)
                            .accessibilityLabel("Email")
                            .accessibilityHint("An email address for us to contact you at.")
                        Divider()
                    }

                    Text("Optional. By providing an email address, you consent to us storing your email address and contacting you.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.trailing)
                }

                HStack {
                    Spacer()
                    Button {
                        self.isTextEditorFocused = false
                        Task(priority: .userInitiated) {
                            await self.model.submitFeedback()
                        }
                    } label: {
                        Text("Submit")
                            .padding(.horizontal)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(model.feedbackMessage.isEmpty)
                    Spacer()
                }
            }
        }
    }

    @ViewBuilder
    private func Heading(text: String) -> some View {
        Text(text)
            .foregroundStyle(.secondary)
            .font(.caption)
    }

    @ViewBuilder
    private func SuccessView() -> some View {
        VStack(alignment: .leading) {
            Label {
                Text("Got It!")
            } icon: {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(Color.accentColor)
            }
            .font(.title)
            .padding(.bottom)

            Text("We've received your feedback. Thank you for sharing, we read through and appreciate each and every feedback. 😄")
                .multilineTextAlignment(.leading)
                .font(.callout)
                .foregroundStyle(.secondary)

            Spacer()

            HStack {
                Spacer()
                Button {
                    self.model.dismiss()
                } label: {
                    Text("Done")
                        .padding(.horizontal)
                }
                .buttonStyle(.borderedProminent)
                Spacer()
            }
        }
    }

    @ViewBuilder
    private func FailureView() -> some View {
        VStack(alignment: .leading) {
            Label {
                Text("Something Went Wrong")
            } icon: {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.yellow)
            }
            .font(.title)
            .padding(.bottom)

            HStack {
                Image(systemName: "pc")
                    .font(.title)
                    .opacity(0)
                    .accessibilityHidden(true)
                VStack {
                    Text("We weren't able to upload your feedback. Please try again later!")
                        .multilineTextAlignment(.leading)
                        .font(.callout)
                        .foregroundStyle(.secondary)

                    Spacing()

                    if let supportEmail = FeedbackKit.shared.config?.fallbackSupportEmailAddress {
                        VStack(alignment: .leading) {
                            Text("If the issue persists, please let us know at ")
                                .foregroundStyle(.secondary)
                            Link(destination: URL(string: "mailto://\(supportEmail)")!, label: {
                                Text(supportEmail)
                            })
                        }
                        .font(.callout)
                    }
                }
            }

            Spacer()

            HStack {
                Spacer()

                Button {
                    self.model.dismiss()
                } label: {
                    Text("Try Again Later")
                }

                Spacer()
                    .frame(width: 16)

                Button {
                    self.model.retry()
                } label: {
                    Text("Retry")
                        .padding(.horizontal)
                }
                .buttonStyle(.borderedProminent)
                Spacer()
            }
        }
    }

    @ViewBuilder
    private func Spacing() -> some View {
        Spacer()
            .frame(height: 16)
    }

    private var navigationTitle: String {
        switch model.feedbackType {
        case .featureRequest:
            return copy?.navigationTitle.featureRequest ?? "Feature Request"
        case .generalFeedback:
            return copy?.navigationTitle.generalFeedback ?? "Feedback"
        case .issue:
            return copy?.navigationTitle.reportAnIssue ?? "Report an Issue"
        case .none:
            return ""
        }
    }

    private var instructionsText: String {
        switch model.feedbackType {
        case .featureRequest:
            return copy?.instructionsText.featureRequest ?? "Got an idea for a new feature? We're all ears!"
        case .generalFeedback:
            return copy?.instructionsText.generalFeedback ?? """
        Love something in the app or have a suggestion? Let us know what's on your mind!
        """
        case .issue:
            return copy?.instructionsText.reportAnIssue ?? """
        Found an issue in the app? Let us know and we'll get it fixed!
        """
        case .none:
            return ""
        }
    }
}

public struct ProvideFeedbackViewCopy {

    let navigationTitle: ProvideFeedbackViewText
    let instructionsText: ProvideFeedbackViewText
    let submitButtonText: ProvideFeedbackViewText

    public struct ProvideFeedbackViewText {
        let generalFeedback: String?
        let reportAnIssue: String?
        let featureRequest: String?
    }
}

@Observable
@MainActor
class ProvideFeedbackViewModel {

    var feedbackType: FeedbackType?
    var onDismiss: (() -> Void)?
    var state: ProvideFeedbackView.ViewState

    var feedbackMessage: String = ""
    var replyEmail: String = ""
    var userID: String?
    var isUserSubscribed: Bool?

    init() {
        self.state = Self.determineInitialState()
    }

    func submitFeedback() async {
        do {
            let feedback = Feedback(
                feedback: self.feedbackMessage,
                replyEmail: self.replyEmail.isEmpty ? nil : self.replyEmail,
                userID: self.userID,
                appName: FeedbackKit.shared.config?.appName,
                appVersion: getAppVersion(),
                osVersion: getOSVersion(),
                timestamp: Date.now,
                locale: Locale.current.identifier,
                isUserSubscribed: self.isUserSubscribed,
                feedbackType: self.feedbackType
            )
            try await FeedbackKitBackend.post(feedback: feedback)
            self.state = .successfullyPostedFeedback
        } catch {
            self.state = .failedToPostFeedback
        }
    }

    func retry() {
        self.state = .enterFeedback
    }

    func dismiss() {
        self.onDismiss?()
    }

    private static func determineInitialState() -> ProvideFeedbackView.ViewState {
        if FeedbackKit.shared.hasCalledConfigure {
            return .enterFeedback
        } else {
            return .notConfigured
        }
    }

    private func getAppVersion() -> String? {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    }

    private func getOSVersion() -> String {
        return "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)"
    }
}

#Preview {
    ProvideFeedbackView(feedbackType: .featureRequest)
}
