//
//  MainView.swift
//  RenderSimpleVideo
//
//  Created by javi www on 7/11/24.
//

import SwiftUI

struct MainView: View {
    
    @ObservedObject var appState: AppState = .shared
    
    @AppStorage("didShowWelcome") var didShowWelcome: Bool = false

    @State private var showWelcome: Bool = false
    
    var body: some View {
        
        NavigationStack(path: $appState.navPath) {
            RenderLiveWithOptionsView()
                .environment(\.containerNavPath, $appState.navPath)
                .navigationDestination(for: Routes.self) { newRoute in
                    switch newRoute {
                    case .settings:
                        SettingsView()
                            .environment(\.containerNavPath, $appState.navPath)
                    case .toSAndPP:
                        ToSAndPPView()
                    case .uelaAgree:
                        EULAAgreementView()
                    }
                }
        }
        .sheet(isPresented: $showWelcome, content: {
            WelcomeSimpleModalView()
        })

        
    }
}

#Preview {
    MainView()
}
