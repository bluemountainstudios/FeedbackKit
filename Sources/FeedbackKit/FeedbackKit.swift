import Foundation
import StoreKit
import os

@MainActor
public class FeedbackKit {
    private init() {}

    internal var hasCalledConfigure = false
    internal var config: Config?

    internal var appReviewURL: URL? {
        guard let appID = config?.appID else { return nil }
        let appIDString = appID.hasPrefix("id") ? appID : "id\(appID)"
        return URL(string: "https://apps.apple.com/app/\(appIDString)?action=write-review")
    }

    public func configure(
        with configuration: Config
    ) {
        self.hasCalledConfigure = true
        self.config = configuration
    }

    public func configure(
        with builder: Config.Builder
    ) {
        self.hasCalledConfigure = true
        self.config = Config(with: builder)
    }

    public func shouldAskForFeedback() async -> Bool {
        guard let config = config else { return false }

        if config.appID == nil {
            self.logNoAppIDMessage()
            return false
        }

        let hasRequestedFeedback = config.userDefaults.bool(forKey: config.hasRequestedFeedbackUserDefaultsKey)
        if hasRequestedFeedback { return false }

        guard let daysSinceOriginalPurchaseDate = await self.calculateNumberOfDaysUsingTheApp() else {
            return false
        }

        let shouldAskForFeedback = daysSinceOriginalPurchaseDate >= config.daysAfterInstallToWaitUntilPromptingForFeedback
        if shouldAskForFeedback {
            config.userDefaults.set(true, forKey: config.hasRequestedFeedbackUserDefaultsKey)
        }

        return shouldAskForFeedback
    }

    internal func calculateNumberOfDaysUsingTheApp() async -> Int? {
        guard let originalPurchaseDate = await self.fetchOriginalPurchaseDate() else {
            return nil
        }

        return Calendar.autoupdatingCurrent.dateComponents(
            [.day],
            from: originalPurchaseDate,
            to: .now
        ).day
    }

    internal func fetchOriginalPurchaseDate() async -> Date? {
        guard let appTransaction = try? await AppTransaction.shared else { return nil }

        switch appTransaction {
        case .unverified(let signedType, _):
            return signedType.originalPurchaseDate
        case .verified(let signedType):
            return signedType.originalPurchaseDate
        }
    }

    internal func logNoAppIDMessage() {
        os_log(
            .error,
"""
Cannot ask for feedback because the app's appID has not been provided.
Please provide the appID when configuring FeedbackKit.
"""
        )
    }
}

// MARK: - Singleton
extension FeedbackKit {
    public static let shared = FeedbackKit()
}
