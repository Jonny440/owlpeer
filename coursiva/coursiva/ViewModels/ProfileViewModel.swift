//
//  ProfileViewModel.swift
//  coursiva
//
//  Created by Z1 on 14.07.2025.
//

import SwiftUI
import RevenueCat

@MainActor
class ProfileViewModel: ObservableObject {
    
    // MARK: - Public Properties
    @Published var user: User?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""
    @Published var isEditing: Bool = false
    @Published var isSaving: Bool = false
    @Published var firstName: String = ""
    @Published var lastName: String = ""
    @Published var isPro: Bool = false
    @Published var localizedPrice: String = "$14.99"
    @Published var hasActivePurchase: Bool = false
    // MARK: - Init
    init() {}

    // MARK: - Public Methods
    func loadProfile() async {
        isLoading = true
        errorMessage = ""
        
        defer { isLoading = false }
        
        do {
            let user = try await UserService.fetchUser()
            self.user = user
            self.firstName = user.firstName ?? ""
            self.lastName = user.lastName ?? ""
            self.isPro = user.isPremium
            // Also refresh purchase state
            await refreshPurchaseState()
        } catch {
            errorMessage = "Failed to load profile"
        }
    }

    func saveProfile() async {
        isSaving = true
        errorMessage = ""
        
        defer { isSaving = false }
        
        do {
            try await UserService.updateUser(firstName: firstName, lastName: lastName)
            APIClient.shared.invalidateCache(for: .getProfile())
            await loadProfile()
            isEditing = false
        } catch {
            errorMessage = "Failed to save profile"
        }
    }
    
    func startEditing() {
        withAnimation {
            isEditing = true
        }
    }

    func cancelEdit() {
        withAnimation {
            firstName = user?.firstName ?? ""
            lastName = user?.lastName ?? ""
            isEditing = false
        }
    }
    
    func purchaseSubscription() async throws {
            let products = await Purchases.shared.products(["owlpeer_1499_1m_1c0"])
            guard let product = products.first else {
                throw NSError(
                    domain: "Purchase",
                    code: 404,
                    userInfo: [NSLocalizedDescriptionKey: "Could not find product"]
                )
            }
            
            let result = try await Purchases.shared.purchase(product: product)
            
            if result.customerInfo.entitlements.active.contains(where: { $0.value.isActive }) {
                guard let email = user?.email else {
                    throw NSError(
                        domain: "Purchase",
                        code: 404,
                        userInfo: [NSLocalizedDescriptionKey: "User not found"]
                    )
                }
                
                APIClient.shared.invalidateAllCache()
                
                let requestBody: [String: Any] = [
                    "email": email
                ]
                
                guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
                    throw NSError(
                        domain: "Purchase",
                        code: 400,
                        userInfo: [NSLocalizedDescriptionKey: "Failed to convert request body to JSON"]
                    )
                }
                
                let _: EmptyResponse = try await APIClient.shared.request(
                    endpoint: .upgradeUser(),
                    method: .post,
                    body: jsonData
                )
            }
            
            // Reload profile to reflect changes
            await loadProfile()
            await refreshPurchaseState()
        }

    func loadPrice() {
        Task {
            let products = await Purchases.shared.products(["owlpeer_1499_1m_1c0"])
            if let product = products.first {
                await MainActor.run {
                    localizedPrice = product.sk2Product?.displayPrice ?? "$14.99"
                }
            }
        }
    }

    /// Refreshes RevenueCat purchase state for current app user
    func refreshPurchaseState() async {
        do {
            let info = try await Purchases.shared.customerInfo()
            // Consider there is an active purchase if any entitlement is active
            let hasActive = info.entitlements.active.contains { _, entitlement in
                entitlement.isActive
            }
            self.hasActivePurchase = hasActive
        } catch {
            // If we fail to fetch, keep previous value and optionally log
            #if DEBUG
            print("Failed to refresh purchase state: \(error)")
            #endif
        }
    }
}
