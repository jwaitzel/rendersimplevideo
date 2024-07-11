//
//  MainView.swift
//  RenderSimpleVideo
//
//  Created by javi www on 7/11/24.
//

import SwiftUI

struct MainView: View {
    
    @ObservedObject var appState: AppState = .shared
    
    var body: some View {
        
        NavigationStack(path: $appState.navPath) {
            RenderVideoEditorView()
                .environment(\.containerNavPath, $appState.navPath)
                .navigationDestination(for: Routes.self) { newRoute in
                    switch newRoute {
                    case .settings:
                        SettingsView()
                    default:
                        EmptyView();
                    }
                }
        }
        
    }
}

#Preview {
    MainView()
}
