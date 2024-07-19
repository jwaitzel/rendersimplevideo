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
    
    var body: some View {
        NavigationStack {
            VStack {
                
                TextField("Title (optional)", text: $requestTitle)
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
                
                Button {
                    
                } label: {
                    Text("Request Feature")
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
        }
        
    }
}

#Preview {
    SendRequestFormView()
}
