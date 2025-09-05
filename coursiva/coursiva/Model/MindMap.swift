//
//  MindMap.swift
//  coursiva
//
//  Created by Z1 on 07.07.2025.
//

import Foundation

// MARK: - Full Response
struct MindMapResponse: Codable {
    let message: String
    let mindmap: MindMapRootWrapper
    let video_title: String
}

// MARK: - MindMap Wrapper with "root"
struct MindMapRootWrapper: Codable {
    let root: MindMapNode
    let title: String
}

// MARK: - Recursive MindMap Node
struct MindMapNode: Codable, Identifiable {
    let id = UUID()  // Auto-generated ID for SwiftUI use
    let message: String
    let description: String?
    let children: [MindMapNode]?

    // Coding keys in case server uses snake_case or different names
    enum CodingKeys: String, CodingKey {
        case message
        case description
        case children
    }
}

// MARK: - Optional Error Response
struct MindMapErrorResponse: Codable {
    let error: String
}
