//
//  ContentView.swift
//  coursiva
//
//  Created by Z1 on 15.06.2025.
//

import SwiftUI
import Clerk

struct ContentView: View {
    @Environment(Clerk.self) private var clerk

    var body: some View {
        VStack {
            if clerk.user != nil {
                // User is signed in, show main app
                MainTabView()
            } else {
                // User is not signed in, show auth flow
                ClerkAuthView()
            }
        }
        
    }
} 
