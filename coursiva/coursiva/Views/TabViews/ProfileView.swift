//
//  Profile.swift
//  coursiva
//
//  Created by Z1 on 15.06.2025.
//

import SwiftUI
import Clerk
import RevenueCat

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @Environment(Clerk.self) private var clerk
    @State private var showSettingsSheet = false
    @State private var showSubscriptionPopup: Bool = false
    @State private var showErrorAlert = false
    @State private var alertErrorMessage: String = ""
    
    var body: some View {
        ZStack {
            VStack(spacing: 24) {
                if viewModel.isLoading {
                    VStack {
                        Spacer()
                        ProgressView()
                            .scaleEffect(1.5)
                            .padding()
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let user = viewModel.user {
                    ProfileHeaderView(user: user, onSettingsTapped: { showSettingsSheet = true })
                    ProfilePersonalInfoView(
                        user: user,
                        isEditing: $viewModel.isEditing,
                        firstName: $viewModel.firstName,
                        lastName: $viewModel.lastName,
                        onSave: {
                            Task { await viewModel.saveProfile() }
                        },
                        onCancel: viewModel.cancelEdit,
                        onEdit: viewModel.startEditing,
                        isSaving: viewModel.isSaving,
                        isPro: viewModel.isPro
                    )
                    
                    // Subscription button + contextual message
                    VStack(spacing: 6) {
                        Button(subscriptionButtonTitle) {
                            showSubscriptionPopup.toggle()
                        }
                        .bold()
                        .padding(.horizontal)
                        .padding(.vertical, 4)
                        .background(Color(red: 23/255, green: 21/255, blue: 50/255))
                        .foregroundColor(Color.appThird)
                        .cornerRadius(20)
                        .disabled(subscriptionButtonDisabled)

                        if let message = subscriptionHelperMessage {
                            Text(localized: message)
                                .font(.footnote)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                    
                    // Error message
                    if !viewModel.errorMessage.isEmpty {
                        ProfileErrorView(errorMessage: viewModel.errorMessage)
                    }
                } else if !viewModel.errorMessage.isEmpty {
                    ProfileErrorView(errorMessage: viewModel.errorMessage, fullScreen: true)
                }
                Spacer()
                ProfileSignOutButton(signOutAction: { Task { await signOut() } })
                
            }
            .padding(.top)
            .background(Color.background)
            .task {
                await viewModel.loadProfile()
            }
            .sheet(isPresented: $showSettingsSheet) {
                SettingsSheet()
            }
            .alert("Purchase Error", isPresented: $showErrorAlert) {
                Button("OK") { }
            } message: {
                Text(alertErrorMessage)
            }
            
            if showSubscriptionPopup {
                SubscriptionPopupView(
                    onDismiss: {
                        showSubscriptionPopup = false
                    },
                    onSubscribe: {
                        Task {
                            do {
                                try await viewModel.purchaseSubscription()
                                showSubscriptionPopup = false
                            } catch {
                                // Show error alert
                                await MainActor.run {
                                    alertErrorMessage = error.localizedDescription
                                    showErrorAlert = true
                                    showSubscriptionPopup = false
                                }
                                print("Purchase failed: \(error)")
                            }
                        }
                    },
                    price: viewModel.localizedPrice, isPro: viewModel.isPro, hasActivePurchase: viewModel.hasActivePurchase
                )
                .transition(.opacity.combined(with: .scale))
                .animation(.easeInOut(duration: 0.3), value: showSubscriptionPopup)
            }
        }
    }
    
    // MARK: - Subscription UI helpers
    private var subscriptionButtonTitle: String {
        if viewModel.isPro && viewModel.hasActivePurchase { return "Manage subscription".localized }
        if viewModel.isPro && !viewModel.hasActivePurchase { return "Subscription managed on website".localized }
        if !viewModel.isPro && viewModel.hasActivePurchase { return "Use the account used for purchase".localized }
        return "Buy a subscription".localized
    }
    
    private var subscriptionButtonDisabled: Bool {
        // Disable if: hasActivePurchase without Pro (account mismatch), or Pro without purchase (managed elsewhere)
        return (viewModel.isPro && !viewModel.hasActivePurchase) || (!viewModel.isPro && viewModel.hasActivePurchase)
    }
    
    private var subscriptionHelperMessage: String? {
        if viewModel.isPro && viewModel.hasActivePurchase { return nil }
        if viewModel.isPro && !viewModel.hasActivePurchase { return "Your subscription is managed on the website" }
        if !viewModel.isPro && viewModel.hasActivePurchase { return "Please sign in with the account you used to purchase the subscription" }
        return nil
    }
    
    private func signOut() async {
        do {
            APIClient.shared.invalidateAllCache()
            try await clerk.signOut()
        } catch {
            print("Sign out error: \(error)")
        }
    }
}

struct ProfileHeaderView: View {
    let user: User
    var onSettingsTapped: (() -> Void)? = nil
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .frame(width: 64, height: 64)
                .foregroundColor(Color.appSecondary)
            VStack(alignment: .leading) {
                Text(localized: user.fullName ?? "")
                    .font(.title3)
                    .foregroundColor(Color.text)
                if let email = user.email as String? {
                    Text(localized: email)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            Spacer()
            if let onSettingsTapped = onSettingsTapped {
                Button(action: { onSettingsTapped() }) {
                    Image(systemName: "gearshape")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.horizontal)
    }
}

struct ProfilePersonalInfoView: View {
    let user: User
    @Binding var isEditing: Bool
    @Binding var firstName: String
    @Binding var lastName: String
    var onSave: (() -> Void)?
    var onCancel: (() -> Void)?
    var onEdit: (() -> Void)?
    var isSaving: Bool = false
    var isPro: Bool = false
    
    var body: some View {
        HStack(spacing: 16) {
            ForEach(0..<2) { index in
                HStack {
                    // Icon
                    Image(index == 0 ? "flame" : "award")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .foregroundStyle(.appThird)
                    // Texts
                    VStack(alignment: .leading, spacing: 4) {
                        Text(localized: index == 0 ? "Current Streak" : "Best Streak")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(localized: index == 0 ? "\(user.currentStreak ?? 0)" : "\(user.maxStreak ?? 0)")
                            .font(.title2)
                            .foregroundColor(Color.text)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.appSurface)
                .overlay(content: {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.gray, lineWidth: 0.4)
                })
                .cornerRadius(16)
            }
        }
        .padding(.horizontal)
        
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(localized: "Personal Info")
                    .font(.headline)
                    .foregroundColor(Color.text)
                Spacer()
                
                if isEditing {
                    // Cancel button
                    Button(action: {
                        onCancel?()
                    }) {
                        Text(localized: "Cancel")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.trailing, 8)
                    .disabled(isSaving)
                    
                    // Save button
                    Button(action: {
                        onSave?()
                    }) {
                        if isSaving {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "checkmark")
                                .font(.headline)
                            Text(localized: "Save")
                                .font(.subheadline)
                        }
                    }
                    .disabled(firstName.isEmpty || lastName.isEmpty || isSaving)
                } else {
                    // Edit button
                    Button(action: {
                        onEdit?()
                    }) {
                        Image(systemName: "pencil")
                            .font(.headline)
                    }
                }
            }
            
            if isEditing {
                VStack(alignment: .leading, spacing: 8) {
                    Text(localized: "First Name")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    CustomTextField(
                        text: $firstName,
                        keyboardType: .default,
                    )
                    .disabled(isSaving)
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray, lineWidth: 0.5)
                    }
                    
                    Text(localized: "Last Name")
                        .font(.caption)
                        .foregroundColor(.gray)
                    CustomTextField(
                        text: $lastName,
                        keyboardType: .default,
                    )
                    .disabled(isSaving)
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray, lineWidth: 0.5)
                    }
                }
            } else {
                PersonalInfo(header: "Name:".localized, text: "\(firstName) \(lastName)")
            }
            PersonalInfo(header: "Email:", text: user.email)
            PersonalInfo(header: "Member since:", text: formatISODate(user.createdAt))
            PersonalInfo(header: "Subscription:", text: isPro ? "Pro" : "Free")
        }
        .padding()
        .background(Color("surfaceColor"))
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    func formatISODate(_ isoString: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        guard let date = isoFormatter.date(from: isoString) else {
            return ""
        }

        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "MM/dd/yyyy"
        return displayFormatter.string(from: date)
    }
}

struct PersonalInfo: View {
    var header: String
    var text: String
    var body: some View {
        HStack {
            Text(localized: header)
                .foregroundColor(.gray)
            Spacer()
            Text(text)
                .foregroundColor(Color.text)
        }
    }
}

struct ProfileErrorView: View {
    let errorMessage: String
    var fullScreen: Bool = false
    var body: some View {
        Group {
            if fullScreen {
                ZStack {
                    Color.background
                        .ignoresSafeArea()
                    VStack {
                        Spacer()
                        Text(localized: errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else {
                Text(localized: errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
    }
}

struct ProfileSignOutButton: View {
    let signOutAction: () -> Void
    var body: some View {
        Button {
            signOutAction()
        } label: {
            Text(localized: "Sign Out")
        }
        .buttonStyle(PrimaryButtonStyle(isLoading: false))
        .padding()
    }
}
