//
//  APIClient.swift
//  coursiva
//
//  Created by Z1 on 07.07.2025.
//

import Foundation
import Get
import Clerk

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}

struct APIClient {
    static let shared = APIClient()
    private let baseURL = URL(string: "https://owlpeer.com/api/")
    
    func request<T: Codable>(
        endpoint: Endpoint,
        method: HTTPMethod = .get,
        body: Data? = nil,
        token: String? = nil,
        forceRefresh: Bool = false
    ) async throws -> T {
        
        let fullURL = URL(string: endpoint.fullPath, relativeTo: baseURL)!
        
        var request = URLRequest(url: fullURL)
        request.httpMethod = method.rawValue
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            #if DEBUG
            if let stringData = String(data: data, encoding: .utf8) {
                print("🔵 APIClient: Response data: \(stringData)")
            }
            #endif
            
            guard let httpResponse = response as? HTTPURLResponse,
                  200..<300 ~= httpResponse.statusCode else {
                throw NetworkError.invalidResponse(statusCode: (response as? HTTPURLResponse)?.statusCode ?? -1)
            }
            
            let decoded = try JSONDecoder().decode(T.self, from: data)
            return decoded
        } catch {
            throw error
        }
    }
    
    func getJWTToken() async throws -> String {
        guard let token = try await Clerk.shared.session?.getToken()?.jwt else {
            throw NetworkError.unauthorized
        }
        return token
    }
}

extension APIClient {
    func requestRaw(
        endpoint: Endpoint,
        method: HTTPMethod = .get,
        body: Data? = nil,
        token: String? = nil
    ) async throws -> String {
        let fullURL = URL(string: endpoint.fullPath, relativeTo: baseURL)!
        var request = URLRequest(url: fullURL)
        request.httpMethod = method.rawValue
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  200..<300 ~= httpResponse.statusCode else {

                throw NetworkError.invalidResponse(statusCode: 0)
            }
            guard let rawString = String(data: data, encoding: .utf8) else {

                throw NetworkError.decodingFailed
            }
            return rawString
        } catch {
            throw error
        }
    }
}

// MARK: - APIClient Cache Extension
extension APIClient {
    
    func cachedRequest<T: Codable>(
        endpoint: Endpoint,
        method: HTTPMethod = .get,
        body: Data? = nil,
        token: String? = nil,
        forceRefresh: Bool = false
    ) async throws -> T {
        
        
        // Only cache GET requests for specific endpoints
        guard method == .get else {
            return try await request(endpoint: endpoint, method: method, body: body, token: token)
        }
        
        let cacheKey = CacheManager.shared.cacheKey(for: endpoint)
        
        // Check cache first (unless force refresh)
        if !forceRefresh {
            if let cachedData: T = CacheManager.shared.getCache(for: cacheKey, type: T.self) {
                #if DEBUG
                print(cachedData)
                #endif
                return cachedData
            }
        }
        
        
        // Make network request
        let data: T = try await request(endpoint: endpoint, method: method, body: body, token: token)
        
        // Cache the response
        let expirationInterval = CacheManager.shared.getExpirationInterval(for: endpoint)
        CacheManager.shared.setCache(data, for: cacheKey, expirationInterval: expirationInterval)
        
        return data
    }
    
    // MARK: - Cache Invalidation Methods
    
    func invalidateCache(for endpoint: Endpoint) {
        let cacheKey = CacheManager.shared.cacheKey(for: endpoint)
        CacheManager.shared.removeCache(for: cacheKey)
    }
    
    func invalidateAllCache() {
        CacheManager.shared.clearAllCache()
    }
}
