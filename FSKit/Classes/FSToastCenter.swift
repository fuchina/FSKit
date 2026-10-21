//
//  FSToastCenter.swift
//  FSKit
//

import SwiftUI

public struct FSToastMessage: Equatable {

    public var text: String

    public var duration: Double

    public init(text: String, duration: Double) {
        self.text = text
        self.duration = duration
    }
}

public final class FSToastCenter: ObservableObject, @unchecked Sendable {

    public static let shared = FSToastCenter()

    @Published public private(set) var current: FSToastMessage?

    private var seq: Int = 0

    private init() {}

    public func show(_ text: String, duration: Double) {
        guard !text.isEmpty else { return }
        if Thread.isMainThread {
            MainActor.assumeIsolated { self.showOnMain(text, duration: duration) }
        } else {
            DispatchQueue.main.async {
                MainActor.assumeIsolated { self.showOnMain(text, duration: duration) }
            }
        }
    }

    @MainActor
    private func showOnMain(_ text: String, duration: Double) {
        seq += 1
        let mine = seq

        withAnimation(.easeIn(duration: 0.1)) {
            current = FSToastMessage(text: text, duration: duration)
        }

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(duration))
            guard mine == self.seq else { return }
            withAnimation(.easeOut(duration: 0.25)) {
                self.current = nil
            }
        }
    }
}

public struct FSToastOverlay: View {

    @ObservedObject private var center = FSToastCenter.shared

    private var maxWidth: CGFloat { WIDTHFC - 50 }

    public init() {}

    public var body: some View {
        if let msg = center.current {
            Text(msg.text)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 10)
                .frame(minHeight: 40)
                .fixedSize(horizontal: false, vertical: true)
                .background(Color(red: 73.0 / 255, green: 80.0 / 255, blue: 86.0 / 255).opacity(0.9))
                .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
                .frame(maxWidth: maxWidth)
                .allowsHitTesting(false)
        }
    }
}
