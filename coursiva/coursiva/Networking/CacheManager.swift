//
//  CacheManager.swift
//  coursiva
//
//  Created by Z1 on 07.07.2025.
//

import Foundation
import Cache

// MARK: - Cache Manager
class CacheManager {
    static let shared = CacheManager()
    
    private let storage: Storage<String, Data>
    
    // Default cache expiration times (in seconds)
    private let defaultExpiration: TimeInterval = 300 // 5 minutes
    private let courseExpiration: TimeInterval = 600 // 10 minutes
    private let profileExpiration: TimeInterval = 43200 // 30 minutes
    
    private init() {
        let diskConfig = DiskConfig(name: "CoursivaDiskCache")
        let memoryConfig = MemoryConfig(
            expiry: .never,
            countLimit: 100,
            totalCostLimit: 50 * 1024 * 1024 // 50 MB
        )
        
        do {
            storage = try Storage<String, Data>(
                diskConfig: diskConfig,
                memoryConfig: memoryConfig,
                fileManager: FileManager.default,
                transformer: TransformerFactory.forData()
            )
        } catch {
            fatalError("Failed to initialize cache storage: \(error)")
        }
        
        // Start cache cleanup timer
        startCacheCleanupTimer()
    }
    
    // MARK: - Cache Operations
    
    func setCache<T: Codable>(_ data: T, for key: String, expirationInterval: TimeInterval? = nil) {
        let expiry = Expiry.date(Date().addingTimeInterval(expirationInterval ?? defaultExpiration))
        
        do {
            let encodedData = try JSONEncoder().encode(data)
            try storage.setObject(encodedData, forKey: key, expiry: expiry)
        } catch {
            print("Failed to cache data for key \(key): \(error)")
        }
    }
    
    func getCache<T: Codable>(for key: String, type: T.Type) -> T? {
        do {
            let data = try storage.object(forKey: key)
            return try JSONDecoder().decode(type, from: data)
        } catch {
            // Object doesn't exist or has expired
            return nil
        }
    }
    
    func removeCache(for key: String) {
        do {
            try storage.removeObject(forKey: key)
        } catch {
            print("Failed to remove cache for key \(key): \(error)")
        }
    }
    
    func clearAllCache() {
        do {
            try storage.removeAll()
        } catch {
            print("Failed to clear all cache: \(error)")
        }
    }
    
    // MARK: - Endpoint-specific Cache Keys
    
    func cacheKey(for endpoint: Endpoint) -> String {
        return "cache_\(endpoint.fullPath)"
    }
    
    func getExpirationInterval(for endpoint: Endpoint) -> TimeInterval {
        let path = endpoint.path
        if path.contains("auth/profile") {
            return profileExpiration
        }
        return defaultExpiration
    }
    
    // MARK: - Cache Cleanup
    
    private func startCacheCleanupTimer() {
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            self.cleanupExpiredCache()
        }
    }
    
    private func cleanupExpiredCache() {
        do {
            try storage.removeExpiredObjects()
        } catch {
            print("Failed to cleanup expired cache: \(error)")
        }
    }
    
    // MARK: - Additional Utility Methods
    
    func isExpired(for key: String) -> Bool {
        do {
            _ = try storage.object(forKey: key)
            return false // If we can retrieve it, it's not expired
        } catch StorageError.notFound {
            return true
        } catch StorageError.deallocated {
            return true
        } catch {
            return true
        }
    }
    
    func cacheExists(for key: String) -> Bool {
        return !isExpired(for: key)
    }
}
