//
//  SendRequestFormView.swift
//  RenderSimpleVideo
//
//  Created by javi www on 7/20/24.
//

import SwiftUI

struct SendRequestFormView: View {
    
    @State private var requestTitle: String = ""
    @State private var requestText: String = ""
    
    @ObservedObject var storeKit: StoreKitManager = .shared
    
    @State private var emptyState: Bool = false

    enum RequestSendState {
        case sending
        case sent
        case error
    }
    @State private var requestSendState: RequestSendState?
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                
                TextField("Title", text: $requestTitle)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background {
                        RoundedRectangle(cornerRadius: 10.0, style: .continuous)
                            .foregroundStyle(Color(uiColor: .systemGray6))
                    }
                
                TextEditor(text: $requestText)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
                    .scrollContentBackground(.hidden)
                    .background {
                        RoundedRectangle(cornerRadius: 10.0, style: .continuous)
                            .foregroundStyle(Color(uiColor: .systemGray6))
                    }
                    .overlay {
                        if requestText.isEmpty {
                            Text("Description")
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                .padding(.top, 16)
                                .padding(.leading, 12)
                                .foregroundStyle(Color(uiColor: .systemGray2).opacity(0.8))
                        }
                    }
                    .overlay {
                        if emptyState {
                            RoundedRectangle(cornerRadius: 10.0, style: .continuous)
                                .stroke(.red)
                        }
                    }
                    .onChange(of: requestText, perform: { value in
                        if emptyState {
                            if !requestText.isEmpty {
                                emptyState = false
                            }
                        }
                    })
                
                Button {
                    if requestText.isEmpty {
                        self.emptyState = true
                        return
                    }
                    sendPostRequest()
                } label: {
                    Text("Send Request")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                          RoundedRectangle(cornerRadius: 8)
                            .stroke(.blue, lineWidth: 1)
                        )
                        .padding(.vertical, 4)
                        .fontWeight(.semibold)
                }
                
                
                Button {
                    if requestText.isEmpty {
                        self.emptyState = true
                        return
                    }
                    buyAndSendRequest()
                } label: {
                    Text("Priority Request - $2.99")
                        .padding(.vertical, 2)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                        .fontWeight(.semibold)
                }
                .buttonStyle(.borderedProminent)
                
            }
            .padding(.horizontal, 16)
            .padding(.top, 24)
            .toolbar {
                ToolbarItem(placement: .keyboard) {
                    Button("Done") {
                        UIApplication.shared.endEditing()
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.trailing, 16)
                }
            }
            .navigationTitle("Request Feature")
            .overlay {
                if requestSendState != nil {
                    ZStack {
                        Rectangle()
                            .foregroundStyle(.black.opacity(0.2))
                            .ignoresSafeArea()
                        
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .foregroundStyle(.ultraThinMaterial)
                            .frame(width: 100, height: 100)
                            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                            .overlay {
                                VStack(spacing: 16) {
                                    
                                    if requestSendState == .error {

                                        Image(systemName: "xmark.circle")
                                            .font(.system(size: 44))
                                            .fontWeight(.light)
                                            .foregroundStyle(.red)
                                        
                                    } else if requestSendState == .sent {
                                        
                                        Image(systemName: "checkmark.circle")
                                            .font(.system(size: 44))
                                            .fontWeight(.light)
                                            .foregroundStyle(.green)
                                        
                                    } else if requestSendState == .sending {
                                        ProgressView()
                                    }
                                    
                                }
                            }
                            .offset(y: -60)
                    }
                }
                
            }
        }
        
    }
    
    func sendPostRequest(priorityTransaction: UInt64? = nil, purchaserID: String? = nil) {
        
        /*
         curl -L \
           -X POST \
           -H "Accept: application/vnd.github+json" \
           -H "Authorization: Bearer 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" \
           -H "X-GitHub-Api-Version: 2022-11-28" \
           https://api.github.com/repos/jwaitzel/rendersimplevideo/issues \
           -d '{"title":"Suggestion Title","body":"App suggestion description","labels":["enhancement"]}'
         */
        
        DispatchQueue.main.async {
            requestSendState = .sending
        }
        
        Task {
            let gitPostURL = URL(string: "https://api.github.com/repos/jwaitzel/rendersimplevideo/issues")!
            var urlRequest = URLRequest(url: gitPostURL)
            urlRequest.httpMethod = "POST"
            urlRequest.addValue("Bearer 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", forHTTPHeaderField: "Authorization")
//            urlRequest.addValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
            
            var suggestTitle = requestTitle.isEmpty ? "no title" : requestTitle
            var requestTextWithInfo = requestText
            if let priorityTransaction {
                suggestTitle.append(" (Priority)")
                requestTextWithInfo.append("\n \(priorityTransaction) - \(purchaserID ?? "")")
            }
            let httpBodyDic: [String: Any] = ["title" : suggestTitle, "body" : requestTextWithInfo, "labels" : ["enhancement"]]
            guard let bodyData = try? JSONSerialization.data(withJSONObject: httpBodyDic, options: []) else { print("Set data error"); return }
            urlRequest.httpBody = bodyData
            
            let (_, urlResp) = try await URLSession.shared.data(for: urlRequest)
//            let stringData = String(data: data, encoding: .utf8)
//            print("data received \(data)\n\(stringData)")
            if let httpResponse = urlResp as? HTTPURLResponse {
                print("statusCode: \(httpResponse.statusCode)")
                if httpResponse.statusCode == 201 {
                    print("Success")
                    DispatchQueue.main.async {
                        requestSendState = .sent
                    }
                } else {
                    DispatchQueue.main.async {
                        requestSendState = .error
                    }
                }
                
                DispatchQueue.main.asyncAfter(wallDeadline: .now() + 1.4) {
                    dismiss()
                }
            }

        }
    }
    
    func buyAndSendRequest() {
        
        guard let priorityRequestProduct = self.storeKit.productPriorityRequest else {
            return
        }
        
        Task {
            do {
                let transaction = try await storeKit.pruchaseWithResult(priorityRequestProduct)
                if transaction != nil { /// if != nil bc succedd
                    let purchedAccount = transaction!.appAccountToken
                    self.sendPostRequest(priorityTransaction: transaction!.id, purchaserID: purchedAccount?.uuidString)
                }
            } catch {
                print("error \(error)")
            }
        }
    }
    
}

#Preview {
    SendRequestFormView()
}
