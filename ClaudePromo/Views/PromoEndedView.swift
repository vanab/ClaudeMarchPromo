//
//  PromoEndedView.swift
//  ClaudePromo
//

import SwiftUI

struct PromoEndedView: View {
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.badge.checkmark")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)
                .symbolEffect(.appear, isActive: appeared)
            Text("Promotion Has Ended")
                .font(.headline)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)
            Text("The x2 usage boost ran from March 13\u{2013}27, 2026.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
                appeared = true
            }
        }
    }
}

#Preview {
    PromoEndedView()
        .frame(width: 340, height: 200)
}
