//
//  coursivaApp.swift
//  coursiva
//
//  Created by Z1 on 15.06.2025.
//

import SwiftUI
import Clerk
import UIKit
import RevenueCat

@main
struct coursivaApp: App {
    @State private var clerk = Clerk.shared
    @State private var clerkLoadError: String? = nil
    @State private var isLoading: Bool = false
    @StateObject private var localizationManager = LocalizationManager.shared
    
    init() {
        let navBar = UINavigationBarAppearance()
            navBar.configureWithOpaqueBackground()
            navBar.backgroundColor = UIColor(Color.appBackground)
            navBar.titleTextAttributes = [.foregroundColor: UIColor(Color.appText)]
            navBar.largeTitleTextAttributes = [.foregroundColor: UIColor(Color.appText)]
        
        UINavigationBar.appearance().standardAppearance = navBar
        UINavigationBar.appearance().scrollEdgeAppearance = navBar
    
        UITabBar.appearance().barTintColor = UIColor(Color.appSurface)
        UITabBar.appearance().backgroundColor = UIColor(Color.appSurface)
        UITabBar.appearance().unselectedItemTintColor = .gray
        UITabBar.appearance().standardAppearance.backgroundEffect = nil
        UITabBar.appearance().scrollEdgeAppearance?.backgroundEffect = nil
        
        let segmentedControlAppearance = UISegmentedControl.appearance()
        segmentedControlAppearance.backgroundColor = UIColor(named: "surfaceColor")
        segmentedControlAppearance.selectedSegmentTintColor = UIColor(Color.appSecondary)
        segmentedControlAppearance.focusEffect = .none
        let selectedAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 13),
            .foregroundColor: UIColor.white
        ]
        segmentedControlAppearance.setTitleTextAttributes(selectedAttributes, for: .selected)
        
        if let revenueKey = Bundle.main.object(forInfoDictionaryKey: "REVENUECAT_API_KEY") as? String {
            Purchases.configure(withAPIKey: revenueKey)
        }
        
        if let clerkKey = Bundle.main.object(forInfoDictionaryKey: "CLERK_PUBLISHABLE_KEY") as? String {
            clerk.configure(publishableKey: clerkKey)
        }
    }
    
    private func loadClerk() async {
        isLoading = true
        clerkLoadError = nil
        do {
            try await clerk.load()
        } catch {
            clerkLoadError = error.localizedDescription
        }
        isLoading = false
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if clerk.isLoaded {
                    ContentView()
                        .id(localizationManager.currentLanguage)
                        .environmentObject(localizationManager)
                } else if let error = clerkLoadError {
                    ZStack {
                        Color.appBackground
                            .ignoresSafeArea()
                        VStack(spacing: 24) {
                            Image("logo_icon_text")
                                .resizable()
                                .scaledToFit()
                                .frame(width: UIScreen.main.bounds.width * 0.65)
                                .padding()
                            Text(localized: "Failed to load Clerk: \(error)")
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            Button(action: {
                                Task { await loadClerk() }
                            }) {
                                Text(localized: isLoading ? "Trying Again..." : "Try Again")
                                    .padding()
                                    .background(Color.appPrimary)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                            .disabled(isLoading)
                        }
                    }
                } else {
                    ZStack {
                        Color.appBackground
                            .ignoresSafeArea()
                        VStack {
                            Image("logo_icon_text")
                                .resizable()
                                .scaledToFit()
                                .frame(width: UIScreen.main.bounds.width * 0.65)
                                .padding()
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(1.5)
                                .tint(Color.appPrimary)
                                .padding()
                        }
                    }
                }
            }
            .environment(clerk)
            .task {
                await loadClerk()
            }
            .preferredColorScheme(.dark)
        }
    }
}
