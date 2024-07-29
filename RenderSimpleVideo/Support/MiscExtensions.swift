//
//  MiscExtensions.swift
//  RenderSimpleVideo
//
//  Created by javi www on 7/11/24.
//

import SwiftUI

private struct ContainerNavigationPathKey: EnvironmentKey {
    static let defaultValue: Binding<NavigationPath> = .constant(NavigationPath())
}

extension EnvironmentValues {
    var containerNavPath: Binding<NavigationPath> {
        get { self[ContainerNavigationPathKey.self] }
        set { self[ContainerNavigationPathKey.self] = newValue }
    }
}

private struct SafeAreaInsetsKey: EnvironmentKey {
    static var defaultValue: EdgeInsets {
        (UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.safeAreaInsets ?? .zero).insets
    }
}

extension EnvironmentValues {
    
    var safeAreaInsets: EdgeInsets {
        self[SafeAreaInsetsKey.self]
    }
}

private extension UIEdgeInsets {
    
    var insets: EdgeInsets {
        EdgeInsets(top: top, leading: left, bottom: bottom, trailing: right)
    }
}

extension View {
    func addGrid(_ colums: Int = 4) -> some View {
        self
            .overlay {
                let spacingHor = 16.0
                HStack(alignment: .top, spacing: spacingHor) {
                    ForEach(0..<colums, id: \.self) { idx in
                        Rectangle()
                            .foregroundColor(.red.opacity(0.2))
                            .frame(height: UIScreen.main.bounds.height * 1)

                    }
                }
                .ignoresSafeArea()
                .padding(.horizontal, spacingHor)
                .allowsHitTesting(false)
            }
    }
}

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}


extension View {
    /// - Current phone screen size
    var safeArea: UIEdgeInsets {
        guard let safeArea = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.safeAreaInsets else {
            return .zero
        }
        return safeArea
    }
}

