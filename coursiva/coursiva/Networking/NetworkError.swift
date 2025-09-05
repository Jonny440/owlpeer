//
//  NetworkError.swift
//  coursiva
//
//  Created by Z1 on 07.07.2025.
//

import Foundation

enum NetworkError: Error, LocalizedError, Equatable {
    case invalidURL
    case invalidResponse(statusCode: Int?)
    case decodingFailed
    case unauthorized
    case serverError(statusCode: Int)
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The URL is invalid."
        case .invalidResponse:
            return "Invalid response from the server."
        case .decodingFailed:
            return "Failed to decode the server response."
        case .unauthorized:
            return "Unauthorized. Please log in again."
        case .serverError(let code):
            return "Server returned an error (code \(code))."
        case .unknown(let error):
            return error.localizedDescription
        }
    }

    static func == (lhs: NetworkError, rhs: NetworkError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidURL, .invalidURL): return true
        case (.invalidResponse, .invalidResponse): return true
        case (.decodingFailed, .decodingFailed): return true
        case (.unauthorized, .unauthorized): return true
        case let (.serverError(a), .serverError(b)): return a == b
        case (.unknown, .unknown): return false // Cannot compare errors
        default: return false
        }
    }
}

struct EmptyResponse: Codable {}
