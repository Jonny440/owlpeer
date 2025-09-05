//
//  User.swift
//  coursiva
//
//  Created by Z1 on 15.06.2025.
//
import Foundation

struct User: Identifiable, Codable {
    let uuid: String
    let email: String
    let firstName: String?
    let lastName: String?
    let fullName: String?
    let isActive: Bool
    let createdAt: String
    let updatedAt: String
    let lastActive: String?
    let currentStreak: Int?
    let maxStreak: Int?
    let isPremium: Bool
    var id: String { uuid }

    enum CodingKeys: String, CodingKey {
        case uuid
        case email
        case firstName = "first_name"
        case lastName = "last_name"
        case fullName = "full_name"
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case lastActive = "last_active"
        case currentStreak = "current_streak"
        case maxStreak = "max_streak"
        case isPremium = "is_premium"
    }
}

enum SubscriptionLevel: String, Codable {
    case free
    case premium
    case pro
}
