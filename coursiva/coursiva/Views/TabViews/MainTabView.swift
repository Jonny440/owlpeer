//
//  MainTabView.swift
//  coursiva
//
//  Created by Z1 on 15.06.2025.
//

import SwiftUI

struct MainTabView: View {
    @State var selectedTab: Int = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView(selectedTab: $selectedTab)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            GradientTitle(
                                text: "owlpeer"
                            )
                            .frame(height: 40)
                        }
                    }
            }
            .tabItem {
                Text(localized: "Home")
                Image("housepdf3")
            }
            .tag(0)

            NavigationStack {
                MyCoursesView()
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            GradientTitle(
                                text: "my courses".localized
                            )
                            .frame(height: 40)
                        }
                        
                    }
                    .navigationBarTitleDisplayMode(.inline)
            }
            .tabItem {
                Text(localized: "My Courses")
                Image("book-open")
                    .foregroundStyle(.white)
            }
            .tag(1)

            NavigationStack {
                ProfileView()
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            GradientTitle(
                                text: "profile".localized
                            )
                            .frame(height: 40)
                        }
                    }
                    .navigationBarTitleDisplayMode(.inline)
            }
            .tabItem {
                Text(localized: "Profile")
                Image("user")
                    .foregroundStyle(.white)
            }
            .tag(2)
        }
        .tint(Color.text)
    }

}
