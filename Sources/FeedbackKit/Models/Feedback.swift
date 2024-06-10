//
//  Feedback.swift
//
//
//  Created by Will Taylor on 6/3/24.
//

import Foundation

internal struct Feedback: Encodable {
    let feedback: String
    let replyEmail: String?
    let userID: String?
    let appName: String?
    let appVersion: String?
    let osVersion: String
    let timestamp: Date
    let locale: String
    let isUserSubscribed: Bool?

    let feedbackType: FeedbackType?

    enum CodingKeys: String, CodingKey {
        case feedback
        case replyEmail = "reply_email"
        case userID = "user_id"
        case appName = "app_name"
        case appVersion = "app_version"
        case osVersion = "os_version"
        case timestamp
        case locale
        case isUserSubscribed = "is_user_subscribed"
        case feedbackType = "feedback_type"
    }
}
