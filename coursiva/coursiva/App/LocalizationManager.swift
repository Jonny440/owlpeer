//
//  LocalizationManager.swift
//  coursiva
//
//  Created by Z1 on 31.08.2025.
//

import SwiftUI
import Foundation

// MARK: - Bundle Extension
extension Bundle {
    
    static var bundleKey: UInt8 = 0
    
    // Store the current language bundle
    static func setLanguage(_ language: String) {
        defer {
            object_setClass(Bundle.main, PrivateBundle.self)
        }
        objc_setAssociatedObject(Bundle.main, &bundleKey, language, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    // Get the current language bundle
    static var currentLanguage: String? {
        return objc_getAssociatedObject(Bundle.main, &bundleKey) as? String
    }
}

// Private bundle class that overrides localized string lookup
private class PrivateBundle: Bundle, @unchecked Sendable {
    
    override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        // Try to get the associated language
        guard let language = objc_getAssociatedObject(self, &Bundle.bundleKey) as? String else {
            return super.localizedString(forKey: key, value: value, table: tableName)
        }
        
        // Try to find the .lproj path for the given language
        guard let path = Bundle.main.path(forResource: language, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            // Fallback to the default implementation if any step fails
            return super.localizedString(forKey: key, value: value, table: tableName)
        }
        
        // Return the localized string from the specified bundle
        return bundle.localizedString(forKey: key, value: value, table: tableName)
    }
}

// MARK: - Localization Manager
class LocalizationManager: ObservableObject {
    
    // Published property that triggers UI updates
    @Published var currentLanguage: String = "en" {
        didSet {
            setLanguage(currentLanguage)
        }
    }
    
    // App Storage for persistence
    @AppStorage("selectedLanguage") private var storedLanguage: String = "en"
    
    // Available languages (English and Russian only)
    let availableLanguages = [
        "en": "English",
        "ru": "Русский"
    ]
    
    // Language codes for easier access
    enum Language: String, CaseIterable {
        case english = "en"
        case russian = "ru"
        
        var displayName: String {
            switch self {
            case .english: return "English"
            case .russian: return "Русский"
            }
        }
    }
    
    // Singleton instance
    static let shared = LocalizationManager()
    
    private init() {
        // Initialize with stored language
        currentLanguage = storedLanguage
        setLanguage(currentLanguage)
        
        // Listen to app storage changes
        setupAppStorageObserver()
    }
    
    // MARK: - Private Methods
    
    private func setLanguage(_ language: String) {
        // Validate language
        guard availableLanguages.keys.contains(language) else {
            print("Unsupported language: \(language). Falling back to English.")
            currentLanguage = "en"
            return
        }
        
        // Update the bundle
        Bundle.setLanguage(language)
        
        // Update stored language
        storedLanguage = language
        
        // Set system language for immediate effect
        UserDefaults.standard.set([language], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
        
        // Force complete UI refresh
        DispatchQueue.main.async {
            // Trigger object will change for all views
            self.objectWillChange.send()
            
            // Force window refresh for immediate language change
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {
                    // This forces a complete view hierarchy refresh
                    window.rootViewController?.view.setNeedsLayout()
                    window.rootViewController?.view.layoutIfNeeded()
                }, completion: nil)
            }
        }
        
        // Post notification for any non-SwiftUI observers
        NotificationCenter.default.post(
            name: .languageChanged,
            object: nil,
            userInfo: ["language": language]
        )
        
        print("Language changed to: \(language)")
    }
    
    private func setupAppStorageObserver() {
        // Monitor UserDefaults changes
        NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            let newLanguage = UserDefaults.standard.string(forKey: "selectedLanguage") ?? "en"
            if newLanguage != self.currentLanguage {
                self.currentLanguage = newLanguage
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// Change the app language
    func changeLanguage(to language: String) {
        guard availableLanguages.keys.contains(language) else {
            print("Language '\(language)' is not supported. Available: \(Array(availableLanguages.keys))")
            return
        }
        
        currentLanguage = language
    }
    
    /// Change language using enum
    func changeLanguage(to language: Language) {
        changeLanguage(to: language.rawValue)
    }
    
    /// Toggle between English and Russian
    func toggleLanguage() {
        let newLanguage = currentLanguage == "en" ? "ru" : "en"
        changeLanguage(to: newLanguage)
    }
    
    /// Get the display name for current language
    var currentLanguageDisplayName: String {
        return availableLanguages[currentLanguage] ?? currentLanguage
    }
    
    /// Check if current language is Russian (RTL not needed for Russian, but useful for future)
    var isRussian: Bool {
        return currentLanguage == "ru"
    }
    
    /// Check if current language is English
    var isEnglish: Bool {
        return currentLanguage == "en"
    }
}

// MARK: - Notification Extension
extension Notification.Name {
    static let languageChanged = Notification.Name("LanguageChanged")
}

// MARK: - Environment Key
struct LocalizationManagerKey: EnvironmentKey {
    static let defaultValue = LocalizationManager.shared
}

extension EnvironmentValues {
    var localizationManager: LocalizationManager {
        get { self[LocalizationManagerKey.self] }
        set { self[LocalizationManagerKey.self] = newValue }
    }
}

// MARK: - Your Existing Extensions (keeping them as-is)
extension Text {
    /// Initialize Text with localized string
    init(localized key: String) {
        self.init(NSLocalizedString(key, comment: ""))
    }
    
    /// Initialize Text with localized string and arguments
    init(localized key: String, _ arguments: CVarArg...) {
        let localizedString = String(format: NSLocalizedString(key, comment: ""), arguments: arguments)
        self.init(localizedString)
    }
}

extension String {
    /// Returns a localized string using the legacy .strings files
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
    
    /// Returns a localized string with arguments
    func localized(_ arguments: CVarArg...) -> String {
        return String(format: NSLocalizedString(self, comment: ""), arguments: arguments)
    }
}
