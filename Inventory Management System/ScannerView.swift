//
//  ScannerView.swift
//  Inventory Management System
//
//  Created by Benjamin Mellott on 2025-02-06.
//

import SwiftUI
import CodeScanner
import Foundation

func fetchTitlesFromAPI() {
    let url = URL(string: "http://127.0.0.1:5000/scrape")!
    
    let task = URLSession.shared.dataTask(with: url) { data, response, error in
        guard let data = data, error == nil else {
            print("Error: \(error?.localizedDescription ?? "Unknown error")")
            return
        }
        
        do {
            let json = try JSONDecoder().decode([String: [String]].self, from: data)
            if let titles = json["titles"] {
                print("Scraped Titles: \(titles)")
            }
        } catch {
            print("Error decoding JSON: \(error)")
        }
    }
    
    task.resume()
}


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
            CodeScannerView(codeTypes: [.code128, .qr, .ean8, .code39, .code93, .ean13], simulatedData: "000")
            {
                response in switch response
                {
                    case .success(let result):
                        print("Found code: \(result.string)")
                        fetchTitlesFromAPI()
                    case .failure(let error):
                        print(error.localizedDescription)
                }
            }
        }
    }
}
