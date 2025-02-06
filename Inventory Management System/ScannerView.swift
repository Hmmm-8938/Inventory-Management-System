//
//  ScannerView.swift
//  Inventory Management System
//
//  Created by Benjamin Mellott on 2025-02-06.
//

import SwiftUI
import CodeScanner

struct ScannerView: View
{
    @Environment(\.presentationMode) private var
        presentationMode: Binding<PresentationMode>
    
    var body: some View
    {
        VStack
        {
            Spacer()
                .navigationBarBackButtonHidden(true)
                .toolbar(content:
                                {
                                    ToolbarItem (placement: .navigationBarLeading)
                                    {
                                        HStack
                                        {
                                            Button(action: {
                                                presentationMode.wrappedValue
                                                    .dismiss()
                                            }, label: {
                                                Image(systemName: "house")
                                                    .foregroundColor(.blue)
                                                Text("Home")
                                                    .foregroundColor(.blue)
                                            })
                                            Spacer()
                                            Text("Scan Code")
                                        }
                                    }
                                })
            CodeScannerView(codeTypes: [.code128, .qr], simulatedData: "000")
            {
                response in switch response
                {
                    case .success(let result):
                        print("Found code: \(result.string)")
                    case .failure(let error):
                        print(error.localizedDescription)
                }
            }
        }
    }
}
