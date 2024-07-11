//
//  AppState.swift
//  RenderSimpleVideo
//
//  Created by javi www on 7/11/24.
//

import SwiftUI

enum Routes {
    case settings
    case toSAndPP
    case uelaAgree
}

class AppState: ObservableObject {
    static let shared: AppState = .init()
    
    @Published var navPath: NavigationPath = .init()

}
