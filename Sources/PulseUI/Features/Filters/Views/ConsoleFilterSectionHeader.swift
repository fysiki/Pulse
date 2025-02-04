// The MIT License (MIT)
//
// Copyright (c) 2020–2023 Alexander Grebenyuk (github.com/kean).

import SwiftUI

struct ConsoleFilterSectionHeader: View {
    let icon: String
    let title: String
    let color: Color
    let reset: () -> Void
    let isDefault: Bool
    @Binding var isEnabled: Bool

#if os(macOS)
    var body: some View {
        HStack {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.accentColor)
                Text(title)
            }
            Spacer()
            Button(action: reset) {
                Image(systemName: "arrow.uturn.left")
            }
            .foregroundColor(.secondary)
            .disabled(isDefault)
            Button(action: { isEnabled.toggle() }) {
                Image(systemName: isEnabled ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isDefault ? .secondary : .accentColor)
            }
            .disabled(isDefault)
        }.buttonStyle(PlainButtonStyle())
    }
#elseif os(iOS)
    var body: some View {
        HStack {
            Text(title)
            if !isDefault {
                Button(action: reset) {
                    Image(systemName: "arrow.uturn.left")
                }
                .padding(.bottom, 3)
            } else {
                Button(action: {}) {
                    Image(systemName: "arrow.uturn.left")
                }
                .padding(.bottom, 3)
                .hidden()
                .backport.hideAccessibility()
            }
        }
    }
#else
    var body: some View {
        Text(title)
    }
#endif
}
