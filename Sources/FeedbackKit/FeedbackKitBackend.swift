//
//  Backend.swift
//
//
//  Created by Will Taylor on 6/3/24.
//

import Foundation
import os

internal struct FeedbackKitBackend {

    /// Posts the feedback to the URL provided in FeedbackKit's config.
    static func post(feedback: Feedback) async throws {
        guard await FeedbackKit.shared.hasCalledConfigure else { throw BackendError.notConfigured }
        guard let postFeedbackURL = await FeedbackKit.shared.config?.postFeedbackURL else { throw BackendError.missingPostFeedbackURL }
        guard let urlSession = await FeedbackKit.shared.config?.urlSession else { throw BackendError.invalidConfig }

        let jsonEncoder = JSONEncoder()
        jsonEncoder.dateEncodingStrategy = .iso8601

        var urlRequest = URLRequest(url: postFeedbackURL, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData)
        urlRequest.httpBody = try jsonEncoder.encode(feedback)
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpMethod = "POST"

        let (responseBody, urlResponse) = try await urlSession.data(for: urlRequest)

        if let httpResponse = urlResponse as? HTTPURLResponse {
            let statusCode = httpResponse.statusCode

            if statusCode != 200 {
                let message = String(data: responseBody, encoding: .utf8)
                os_log("Failed to POST feedback! Status Code: \(statusCode), message: \(message ?? "")")
                throw BackendError.invalidResponse(statusCode: statusCode, message: message)
            } else {
                os_log("Successfully posted feedback!")
            }
        }
    }

    public enum BackendError: Error {
        case notConfigured
        case missingPostFeedbackURL
        case invalidConfig
        case invalidResponse(statusCode: Int, message: String?)
    }
}
