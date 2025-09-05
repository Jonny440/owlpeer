//
//  MyCOursesViewModel.swift
//  coursiva
//
//  Created by Z1 on 07.07.2025.
//

import Foundation

@MainActor
class MyCoursesViewModel: ObservableObject {
    //MARK: - Public Properties
    @Published var courses: [MyCoursesResponse] = []
    @Published var videos: [MyVideoResponse] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    //MARK: - Init
    init() {}

    //MARK: - Public Methods
    func fetchCourses(forceRefresh: Bool) async {
        isLoading = true
        errorMessage = nil
        do {
            let wrapper = try await CourseService.fetchMyCourses(forceRefresh: forceRefresh)
            courses = wrapper.playlists
            videos = wrapper.single_videos
        } catch {
            errorMessage = error.localizedDescription //"Failed to load courses"
        }
        isLoading = false
    }
}
