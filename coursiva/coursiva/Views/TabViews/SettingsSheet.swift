//
//  SettingsSheet.swift
//  coursiva
//
//  Created by Z1 on 18.07.2025.
//

import SwiftUI
import Clerk

struct SettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(Clerk.self) private var clerk
    @StateObject private var localizationManager = LocalizationManager.shared
    @State private var showingDeleteConfirmation = false
    @State private var isDeleting = false
    @State private var deleteError: String? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            navigationBar
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    languageSection
                    legalSection
                    socialSection
                    accountSection
                    Spacer(minLength: 20)
                    appVersionInfo
                }
                .padding(.top, 20)
                .padding(.horizontal, 20)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
        .alert("Delete Account".localized, isPresented: $showingDeleteConfirmation) {
            Button("Cancel".localized, role: .cancel) { }
            Button("Delete".localized, role: .destructive) {
                Task { await deleteAccount() }
            }
        } message: {
            Text(localized: "Your account will be permanently deleted in 24 hours. This action cannot be undone.")
        }
        .overlay(
            Group {
                if isDeleting {
                    ZStack {
                        Color.black.opacity(0.2).ignoresSafeArea()
                        ProgressView("Deleting account...".localized)
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                    }
                }
            }
        )
        .alert("Delete Error".localized, isPresented: Binding<Bool>(
            get: { deleteError != nil },
            set: { if !$0 { deleteError = nil } }
        )) {
            Button("OK".localized, role: .cancel) { deleteError = nil }
        } message: {
            Text(deleteError?.localized ?? "Unknown error".localized)
        }
    }
}

// MARK: - View Components
extension SettingsSheet {
    
    private var navigationBar: some View {
        HStack {
            Text(localized: "Settings")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 10)
    }
    
    private var languageSection: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "globe")
                    .foregroundColor(.primary)
                Text(localized: "Language")
                    .foregroundColor(.primary)
                    .font(.body)
                Spacer()
                
                Menu {
                    Button("English") {
                        localizationManager.changeLanguage(to: "en")
                    }
                    Button("Русский") {
                        localizationManager.changeLanguage(to: "ru")
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text(localizationManager.currentLanguage == "en" ? "English" : "Русский")
                            .foregroundColor(.secondary)
                            .font(.body)
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.system(size: 14, weight: .medium))
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.surface)
            .contentShape(Rectangle())
        }
        .cornerRadius(14)
    }
    
    private var legalSection: some View {
        VStack(spacing: 0) {
            SettingsButton(
                title: "Terms of Service",
                icon: "file-text",
                action: {
                    if let url = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/") {
                        UIApplication.shared.open(url)
                    }
                }
            )
            Divider()
            SettingsButton(
                title: "Privacy Policy",
                icon: "lock",
                action: {
                    if let url = URL(string: "https://owlpeer.com/privacy-policy") {
                        UIApplication.shared.open(url)
                    }
                }
            )
        }
        .background(Color(.systemGray6))
        .cornerRadius(14)
    }
    
    private var socialSection: some View {
        VStack(spacing: 0) {
            SettingsButton(
                title: "Website",
                icon: "laptop",
                action: {
                    if let url = URL(string: "https://owlpeer.com") {
                        UIApplication.shared.open(url)
                    }
                }
            )
            Divider()
            SettingsButton(
                title: "Instagram",
                icon: "instagram",
                action: {
                    if let url = URL(string: "https://www.instagram.com/owlpeer/") {
                        UIApplication.shared.open(url)
                    }
                }
            )
            Divider()
            SettingsButton(
                title: "Telegram",
                icon: "send",
                action: {
                    if let url = URL(string: "https://t.me/a1masssss") {
                        UIApplication.shared.open(url)
                    }
                }
            )
        }
        .background(Color(.systemGray6))
        .cornerRadius(14)
    }
    
    private var accountSection: some View {
        VStack(spacing: 0) {
            SettingsButton(
                title: "Delete Account",
                icon: "trash",
                titleColor: .red,
                action: {
                    showingDeleteConfirmation = true
                }
            )
        }
        .background(Color.appBackground)
        .cornerRadius(14)
    }
    
    private var appVersionInfo: some View {
        HStack {
            Spacer()
            VStack(alignment: .center) {
                Text(localized: "Owlpeer")
                    .foregroundColor(.secondary)
                Text("v.\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] ?? "")")
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
    }
}

// MARK: - Functions
extension SettingsSheet {
    
    private func deleteAccount() async {
        isDeleting = true
        deleteError = nil
        do {
            let jwt = try await APIClient.shared.getJWTToken()
            struct DeleteResponse: Codable {
                let message: String?
                let error: String?
                let deleted_user_id: Int?
                let deleted_clerk_id: String?
                let deleted_email: String?
            }
            let response: DeleteResponse = try await APIClient.shared.request(
                endpoint: Endpoint.deleteUser(),
                method: .post,
                token: jwt
            )
            if let error = response.error {
                deleteError = error
            } else {
                APIClient.shared.invalidateAllCache()
                try await clerk.signOut()
                dismiss()
            }
        } catch {
            deleteError = error.localizedDescription
            print(error)
        }
        isDeleting = false
    }
}

struct SettingsButton: View {
    let title: String
    let titleColor: Color
    let icon: String?
    let action: () -> Void
    
    init(title: String, icon: String? = nil, titleColor: Color = .primary, action: @escaping () -> Void) {
        self.title = title.localized
        self.titleColor = titleColor
        self.action = action
        self.icon = icon
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                if let image = icon {
                    Image(image)
                        .foregroundStyle(titleColor)
                }
                Text(title.localized)
                    .foregroundColor(titleColor)
                    .font(.body)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.system(size: 14, weight: .medium))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.surface)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}
