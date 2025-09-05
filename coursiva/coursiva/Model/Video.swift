//
//  Video.swift
//  coursiva
//
//  Created by Z1 on 15.06.2025.
//
import Foundation

// Used in: VideoService.fetchVideoDetails()
struct Video: Identifiable, Codable {
    let id: Int
    let uuid: String
    let videoID: String
    let title: String
    let url: String
    let thumbnail: String?
    let durationSec: Int?
    let summary: String
    let timecodeTranscript: [TranscriptSegment]?
    let playlistID: Int?
    let userID: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case uuid = "uuid_video"
        case videoID = "video_id"
        case title
        case url
        case thumbnail
        case durationSec = "duration_sec"
        case summary
        case timecodeTranscript = "timecode_transcript"
        case playlistID = "playlist"
        case userID = "user"
    }
}

// Used in: Video.timecodeTranscript, transcript parsing
struct TranscriptSegment: Codable {
    let text: String
    let start: String
    let duration: String
}

// Used in: VideoService.fetchLightweightVideos()
struct VideoList: Identifiable, Codable {
    let id: UUID
    let title: String
    let playlistThumbnail: URL?
    let videos: [VideoListItem]

    enum CodingKeys: String, CodingKey {
        case id = "uuid_playlist"
        case title
        case playlistThumbnail = "playlist_thumbnail"
        case videos
    }
}

// Used in: VideoList.videos
struct VideoListItem: Identifiable, Codable {
    let id: UUID
    let title: String
    let thumbnail: URL
    let durationSec: Int
    let url: URL

    enum CodingKeys: String, CodingKey {
        case id = "uuid_video"
        case title
        case thumbnail
        case durationSec = "duration_sec"
        case url
    }
}
