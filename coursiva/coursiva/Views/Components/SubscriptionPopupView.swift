//
//  WebsitePopupView.swift
//  coursiva
//
//  Created by Z1 on 30.07.2025.
//
import SwiftUI

struct SubscriptionPopupView: View {
    @StateObject private var viewModel = ProfileViewModel()
    let onDismiss: () -> Void
    let onSubscribe: () -> Void
    var price: String
    var isPro: Bool
    var hasActivePurchase: Bool = false
    
    var body: some View {
        ZStack {
        if viewModel.isLoading {
            VStack {
                Spacer()
                ProgressView()
                    .scaleEffect(1.5)
                    .padding()
                Spacer()
            }
        } else  {
            GeometryReader { geometry in
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture { onDismiss() }
                    
                    VStack(spacing: 0) {
                        VStack(spacing: 20) {
                            HeaderView(geometry: geometry, onDismiss: onDismiss, price: price)
                            
                            FeaturesView(geometry: geometry)
                            
                            SubscribeButton(
                                isPremium: isPro,
                                geometry: geometry,
                                onSubscribe: onSubscribe,
                                title: subscribeButtonTitle,
                                disabled: subscribeButtonDisabled,
                                helperMessage: subscribeHelperMessage
                            )
                            
                            FooterView(geometry: geometry)
                        }
                        .padding(min(28, geometry.size.width * 0.07))
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color("surfaceColor"))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24)
                                        .stroke(
                                            LinearGradient.defaulGradient,
                                            lineWidth: 1
                                        )
                                )
                        )
                        .frame(maxWidth: min(340, geometry.size.width * 0.88))
                        .shadow(color: .black.opacity(0.25), radius: 30, x: 0, y: 15)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
    }
        .task { await viewModel.loadProfile() }
    }
}

// MARK: - Popup helpers
extension SubscriptionPopupView {
    var subscribeButtonTitle: String {
        if isPro && hasActivePurchase { return "Manage subscription".localized }
        if isPro && !hasActivePurchase { return "Subscription managed on website".localized }
        if !isPro && hasActivePurchase { return "Use the purchase account".localized }
        return "Become Pro".localized
    }
    
    var subscribeButtonDisabled: Bool {
        return (isPro && !hasActivePurchase) || (!isPro && hasActivePurchase)
    }
    
    var subscribeHelperMessage: String? {
        if isPro && hasActivePurchase { return nil }
        if isPro && !hasActivePurchase { return "Your subscription is managed on the website" }
        if !isPro && hasActivePurchase { return "Please sign in with the account used to purchase the subscription" }
        return nil
    }
}

struct ProFeatureRow: View {
    let icon: String
    let text: String
    let color: Color
    let geometry: GeometryProxy
    
    var body: some View {
        HStack(spacing: min(16, geometry.size.width * 0.04)) {
            // Feature icon with background
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: min(16, geometry.size.width * 0.04)))
                .foregroundColor(.green)
            
            Text(localized: text)
                .font(.system(size: min(15, geometry.size.width * 0.038), weight: .medium))
                .foregroundColor(Color("textColor"))
            
            Spacer()
        }
        .padding(.vertical, 2)
    }
}

struct HeaderView: View {
    let geometry: GeometryProxy
    let onDismiss: () -> Void
    var price: String
    var body: some View {
        HStack {
            Spacer()
            VStack(spacing: 4) {
                Text(localized: "Owlpeer Pro")
                    .font(.custom("Futura-Bold", size: min(28, geometry.size.width * 0.07)))
                    .foregroundColor(Color("textColor"))
                
                Text(String.localizedStringWithFormat(NSLocalizedString("%@/month", comment: ""), price))
                    .font(.system(size: min(20, geometry.size.width * 0.05), weight: .semibold))
                    .foregroundColor(Color("appPrimaryColor"))
            }
            Spacer()
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: min(24, geometry.size.width * 0.06)))
                    .foregroundColor(Color("textColor").opacity(0.6))
            }
        }
    }
}

struct FeaturesView: View {
    let geometry: GeometryProxy
    
    var body: some View {
        VStack(spacing: min(12, geometry.size.height * 0.015)) {
            ProFeatureRow(icon: "infinity", text: "Unlimited Courses", color: Color("appPrimaryColor"), geometry: geometry)
            ProFeatureRow(icon: "brain.head.profile", text: "AI Summary", color: Color("appSecondaryColor"), geometry: geometry)
            ProFeatureRow(icon: "rectangle.stack.fill", text: "Smart Flashcards", color: Color("appThirdColor"), geometry: geometry)
            ProFeatureRow(icon: "questionmark.circle.fill", text: "Interactive Quizzes", color: Color("gradientColor1"), geometry: geometry)
            ProFeatureRow(icon: "graduationcap.fill", text: "AI Tutor", color: Color("gradientColor2"), geometry: geometry)
        }
    }
}

struct SubscribeButton: View {
    let isPremium: Bool
    let geometry: GeometryProxy
    let onSubscribe: () -> Void
    let title: String
    let disabled: Bool
    let helperMessage: String?
    
    var body: some View {
        Button(action: onSubscribe) {
            HStack(spacing: min(8, geometry.size.width * 0.02)) {
                Image(systemName: "crown.fill")
                    .font(.system(size: min(16, geometry.size.width * 0.04), weight: .semibold))
                
                Text(localized: title)
                    .font(.system(size: min(18, geometry.size.width * 0.045), weight: .bold))
            }
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(disabled)
        
        if let helper = helperMessage {
            Text(localized: helper)
                .font(.footnote)
                .foregroundColor(Color("textColor").opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.top, 6)
        }
    }
}

struct FooterView: View {
    let geometry: GeometryProxy
    
    var body: some View {
        VStack(spacing: 4) {
            Text(localized: "Join thousands of learners worldwide")
                .font(.system(size: min(11, geometry.size.width * 0.028), weight: .regular))
                .foregroundColor(Color("textColor").opacity(0.5))
        }
        .multilineTextAlignment(.center)
    }
}

