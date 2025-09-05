//
//  MyCoursesView.swift
//  coursiva
//
//  Created by Z1 on 15.06.2025.
//

import SwiftUI

struct MyCoursesView: View {
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible())
    ]

    @StateObject private var viewModel = MyCoursesViewModel()
    @State private var selectedContentType: ContentType = .singleVideos
    
    enum ContentType: String, CaseIterable {
        case singleVideos = "Videos"
        case playlists = "Playlists"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Toggle at the top
            Picker("Content Type", selection: $selectedContentType) {
                ForEach(ContentType.allCases, id: \.self) { type in
                    Text(localized:  type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 6)
            
            ScrollView {
                if viewModel.isLoading {
                    VStack {
                        Spacer()
                        ProgressView()
                            .scaleEffect(1.5)
                        Text(localized: "Loading courses...")
                            .foregroundColor(.gray)
                            .padding(.top)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = viewModel.errorMessage {
                    Text(localized: error)
                        .foregroundColor(.red)
                        .padding()
                } else {
                    // Show content based on selected type
                    if selectedContentType == .playlists {
                        if viewModel.courses.isEmpty {
                            VStack {
                                Spacer()
                                Text(localized: "There is nothing yet")
                                    .foregroundColor(.gray)
                                    .font(.title3)
                                    .multilineTextAlignment(.center)
                                Spacer()
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(viewModel.courses) { course in
                                    CourseCardView(id: course.id, title: course.title, thumbnailURL: course.playlistThumbnail, onDelete: { await viewModel.fetchCourses(forceRefresh: true) })
                                }
                            }
                            .padding()
                        }
                    } else {
                        if viewModel.videos.isEmpty {
                            VStack {
                                Spacer()
                                Text(localized: "There is nothing yet")
                                    .foregroundColor(.gray)
                                    .font(.title3)
                                    .multilineTextAlignment(.center)
                                Spacer()
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(viewModel.videos) { video in
                                    VideoCardView(id: video.id, title: video.title, thumbnailURL: video.thumbnail, onDelete: { await viewModel.fetchCourses(forceRefresh: true) })
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .refreshable {
                Task {
                    await viewModel.fetchCourses(forceRefresh: true)
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.fetchCourses(forceRefresh: false)
            }
        }
        .background(Color.appBackground)
    }
}

#Preview {
    MyCoursesView()
        .preferredColorScheme(.dark)
}

