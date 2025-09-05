//
//  Rercource.swift
//  coursiva
//
//  Created by Z1 on 29.08.2025.
//

import Foundation

struct Resources: Codable {
    let title: String?
    let summary: String?
    let recourcesMarkdown: String?
    let updatedAt: String?
    let error: String?
    
    enum CodingKeys: String, CodingKey {
        case title
        case summary
        case recourcesMarkdown = "resources_markdown"
        case updatedAt = "updated_at"
        case error
    }
}
