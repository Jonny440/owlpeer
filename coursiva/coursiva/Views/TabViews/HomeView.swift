//
//  HomeView.swift
//  coursiva
//
//  Created by Z1 on 15.06.2025.
//

import SwiftUI
import Clerk
import RevenueCat

struct HomeView: View {
    @Binding var selectedTab: Int
    
    @State private var playlistURL: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String = ""
    @State private var successMessage: String = ""
    @State private var showErrorAlert = false
    @State private var alertErrorMessage: String = ""
    
    @State private var showSuccessFeedback: Bool = false
    @State private var showErrorFeedback: Bool = false
    @State private var showSubscriptionPopup: Bool = false
    @State private var price: String = "$14.99"
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            VStack {
                Spacer()
                VStack(spacing: 20) {
                    // Gradient bold title
                    Text(localized: "Paste YouTube link")
                        .font(.custom("Futura-Bold", size: 22))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .foregroundStyle(Color.appText)

                    CustomTextField(text: $playlistURL, placeholder: "https://www.youtube.com/watch?v=...", icon: "link")
                        .padding(.horizontal)

                    Button(action: {
                        Task {
                            await createCourse()
                        }
                    }) {
                        Text(localized: "Generate Course")
                            .font(.headline.bold())
                            .foregroundColor(.appText)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .padding(.horizontal)
                    .buttonStyle(PrimaryButtonStyle(isLoading: isLoading))
                    .disabled(playlistURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    

                    // Error message
                    if !errorMessage.isEmpty {
                        Text(localized: errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    // Success message
                    if !successMessage.isEmpty {
                        Text(localized: successMessage)
                            .foregroundColor(.green)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
                Spacer()
            }
            .allowsHitTesting(!showSubscriptionPopup)
            
            // Website popup overlay
            if showSubscriptionPopup {
                SubscriptionPopupView(
                    onDismiss: {
                        showSubscriptionPopup = false
                    },
                    onSubscribe: {
                        Task {
                            do {
                                let products = await Purchases.shared.products(["owlpeer_1499_1m_1c0"])
                                guard let product = products.first else {
                                    print("could not find a product")
                                    return
                                }
                                let result = try await Purchases.shared.purchase(product: product)
                                if result.customerInfo.entitlements.active.contains(where: { $0.value.isActive }) {
                                    guard let email = CacheManager.shared.getCache(for: "cache_auth/profile/", type: User.self)?.email else {
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
                                        fatalError("Failed to convert request body to JSON")
                                    }
                                    
                                    let _: EmptyResponse = try await APIClient.shared.request(
                                        endpoint: .upgradeUser(),
                                        method: .post,
                                        body: jsonData
                                    )
                                }
                            }  catch {
                                // Show error alert
                                await MainActor.run {
                                    alertErrorMessage = error.localizedDescription
                                    showErrorAlert = true
                                }
                                print("Purchase failed: \(error)")
                            }
                        }
                        showSubscriptionPopup = false
                    },
                    price: price, isPro: false
                )
                .onAppear{ loadPrice() }
                .transition(.opacity.combined(with: .scale))
                .animation(.easeInOut(duration: 0.3), value: showSubscriptionPopup)
            }
        }
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .gesture(
            DragGesture().onChanged { _ in
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        )
        .sensoryFeedback(.success, trigger: showSuccessFeedback)
        .sensoryFeedback(.error, trigger: showErrorFeedback)
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK") { }
        } message: {
            Text(localized: alertErrorMessage)
        }
    }
    
    private func loadPrice() {
        Task {
            let products = await Purchases.shared.products(["owlpeer_1499_1m_1c0"])
            if let product = products.first {
                await MainActor.run {
                    price = product.sk2Product?.displayPrice ?? "$14.99"
                }
            }
        }
    }
    
    private func createCourse() async {
        isLoading = true
        errorMessage = ""
        successMessage = ""
        let urlString = playlistURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !urlString.isEmpty else {
            errorMessage = "Please enter a YouTube URL"
            isLoading = false
            return
        }
        do {
            let response = try await CourseService.createCourse(from: urlString)
            if response.type == "single_video", let video = response.video {
                successMessage = "Video course created: \(video.title)"
            } else if response.type == "playlist", let playlist = response.playlist {
                successMessage = "Сourse created: \(playlist.title)"
            } else {
                successMessage = "Course created successfully!"
            }
            APIClient.shared.invalidateCache(for: Endpoint.myCourses())
            selectedTab = 1
            showSuccessFeedback.toggle()
            removeMessages()
            playlistURL = ""
        } catch {
            // Try to parse error message from response body if available
            if let urlError = error as? NetworkError, urlError == .invalidResponse(statusCode: nil) {
                if let apiError = await parseAPIError(urlString: urlString) {
                    // Check if it's a limit error
//                    if apiError.lowercased().contains("limit") {
//                        showWebsitePopup = true
//                    } else {
                        errorMessage = apiError
//                    }
                } else {
                    errorMessage = error.localizedDescription
                }
            } else {
                // Check if the error message contains "limit"
//                if error.localizedDescription.lowercased().contains("limit") {
//                    showWebsitePopup = true
//                } else {
                    errorMessage = error.localizedDescription
//                }
            }
            showErrorFeedback.toggle()
            removeMessages()
        }
        isLoading = false
    }
    
    private func removeMessages() {
        Task {
            try await Task.sleep(nanoseconds: 8_000_000_000) // 8 seconds
            await MainActor.run {
                successMessage = ""
                errorMessage = ""
            }
        }
    }

    // Helper to try to fetch the error message from the API (by repeating the request and parsing the error)
    private func parseAPIError(urlString: String) async -> String? {
        let endpoint = Endpoint.createCourse()
        guard let body = try? JSONEncoder().encode(["url": urlString]) else { return nil }
        
        do {
            let fullURL = URL(string: endpoint.fullPath, relativeTo: URL(string: "https://owlpeer.com/api/"))!
            var request = URLRequest(url: fullURL)
            request.httpMethod = "POST"
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            if let token = try? await Clerk.shared.session?.getToken()?.jwt {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Check for any error status code (4xx or 5xx)
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode >= 400 {
                
                // Try to parse JSON error message
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let errorMsg = json["error"] as? String {
                    return errorMsg
                }
                
                // Fallback: try to parse as plain text if JSON parsing fails
                if let errorString = String(data: data, encoding: .utf8), !errorString.isEmpty {
                    return errorString
                }
            }
        } catch {
            // Don't set errorMessage here as it can cause issues
            print("Error in parseAPIError: \(error)")
        }
        
        return nil
    }
}

