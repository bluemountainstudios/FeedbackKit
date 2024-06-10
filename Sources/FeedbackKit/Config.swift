//
//  Configuration.swift
//
//
//  Created by Will Taylor on 6/3/24.
//

import Foundation

extension FeedbackKit {
    public class Config {
        /// The URL that FeedbackKit POSTs feedback to.
        let postFeedbackURL: URL

        /// The URLSession instance used by FeedbackKit
        let urlSession: URLSession

        /// The UserDefaults suite used by FeedbackKit
        let userDefaults: UserDefaults

        /// The UserDefaults key that FeedbackKit uses to store whether or not a user has gone through the review prompt
        let hasRequestedFeedbackUserDefaultsKey: String

        /// An email address that users can email in the event that uploading feedback fails.
        let fallbackSupportEmailAddress: String?

        /// The name of the app. Will be uploaded with the feedback.
        let appName: String?

        /// The app's App Store ID> You can find the App Store ID in your app's App Store product URL.
        /// Will be in the format `##########` (10 digits).
        let appID: String?

        /// How many days post-install that FeedbackKit will wait before requesting feedback. Defaults to 3 days.
        let daysAfterInstallToWaitUntilPromptingForFeedback: Int

        internal init(with builder: Builder) {
            self.postFeedbackURL = builder.postFeedbackURL
            self.urlSession = builder.urlSession ?? .shared
            self.userDefaults = builder.userDefaults ?? .standard
            self.fallbackSupportEmailAddress = builder.fallbackSupportEmailAddress
            self.appName = builder.appName
            self.appID = builder.appID
            self.hasRequestedFeedbackUserDefaultsKey = builder.hasRequestedFeedbackUserDefaultsKey ?? "HAS_REQUESTED_FEEDBACK"
            self.daysAfterInstallToWaitUntilPromptingForFeedback = builder.daysAfterInstallToWaitUntilPromptingForFeedback ?? 3
        }

        public class Builder: NSObject {
            private(set) var postFeedbackURL: URL
            private(set) var fallbackSupportEmailAddress: String?
            private(set) var appName: String?
            private(set) var appID: String?

            private(set) var urlSession: URLSession?
            private(set) var userDefaults: UserDefaults?
            private(set) var hasRequestedFeedbackUserDefaultsKey: String?
            private(set) var daysAfterInstallToWaitUntilPromptingForFeedback: Int?

            public init(postFeedbackURL: URL) {
                self.postFeedbackURL = postFeedbackURL
            }

            public func with(urlSession: URLSession) -> Builder {
                self.urlSession = urlSession
                return self
            }

            public func with(userDefaults: UserDefaults) -> Builder {
                self.userDefaults = userDefaults
                return self
            }

            public func with(hasRequestedFeedbackUserDefaultsKey: String) -> Builder {
                self.hasRequestedFeedbackUserDefaultsKey = hasRequestedFeedbackUserDefaultsKey
                return self
            }

            public func with(fallbackSupportEmailAddress: String) -> Builder {
                self.fallbackSupportEmailAddress = fallbackSupportEmailAddress
                return self
            }

            public func with(appName: String) -> Builder {
                self.appName = appName
                return self
            }

            public func with(appID: String) -> Builder {
                self.appID = appID
                return self
            }

            public func with(daysAfterInstallToWaitUntilPromptingForFeedback: Int) -> Builder {
                self.daysAfterInstallToWaitUntilPromptingForFeedback = daysAfterInstallToWaitUntilPromptingForFeedback
                return self
            }
        }
    }
}
