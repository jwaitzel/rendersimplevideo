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
