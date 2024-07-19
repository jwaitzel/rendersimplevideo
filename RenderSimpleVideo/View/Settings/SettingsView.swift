//
//  SettingsView.swift
//  RenderSampleVideo
//
//  Created by javi www on 7/1/24.
//
import SwiftUI

struct SettingsView: View {
    
    @Environment(\.containerNavPath) var navPath
    
    @State private var showRequestFeatureForm: Bool = false

    var body: some View {
        List {
            Label("Contact support", systemImage: "questionmark.circle")
                .onTapGesture {
                    print("Creates link to email")
                    openMail(emailTo: "jrwappdev@gmail.com", subject: "Help", body: "")
                }
            
            
            
            Label("Request Feature", systemImage: "star.bubble")
                .onTapGesture {
                    showRequestFeatureForm = true
                }
            
            Label("Terms of Service & Privacy Policy", systemImage: "info.circle")
                .onTapGesture {
                    navPath.wrappedValue.append(Routes.toSAndPP)
                }
            
            Label("End User License Agreement", systemImage: "text.badge.checkmark")
                .onTapGesture {
                    navPath.wrappedValue.append(Routes.uelaAgree)
                }

        }
        .navigationTitle("Settings")
        .overlay(alignment: .bottom) {
            HStack(spacing: 0) {
                Text("Made with")
                Text(" 💙 ")
                    .font(.system(size: 9))
                Text("for the ")
                Text("iOS Community")
                    .fontWeight(.semibold)
                
            }
            .font(.caption)
            .frame(maxWidth: .infinity, alignment: .center)
            .offset(y: 0)
            .padding(.bottom, 8)
            
        }
        .sheet(isPresented: $showRequestFeatureForm, content: {
            SendRequestFormView()
        })

    }
        
    func openMail(emailTo:String, subject: String, body: String) {
        
        let subject = "Need help with the app"
        let body = ""
        let coded = "mailto:\(emailTo)?subject=\(subject)&body=\(body)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)

        if let emailURL: NSURL = NSURL(string: coded!) {
            if UIApplication.shared.canOpenURL(emailURL as URL) {
                UIApplication.shared.open(emailURL as URL, options: [:], completionHandler: nil)
            }
        }  else {
            print("Cannot open url")
        }
    }

}

#Preview {
    TabView {
        SettingsView()
//            .tabItem {
//                Label(
//                    title: { Text("Label") },
//                    icon: { Image(systemName: "42.circle") }
//                )
//            }
    }
    
}
