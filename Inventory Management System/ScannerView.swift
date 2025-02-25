import SwiftUI
import CodeScanner
import Foundation
import SwiftData

struct ScannerView: View
{
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.modelContext) private var context
    @Query private var items: [ApplicationData]
    
    var body: some View
    {
        VStack
        {
            Spacer()
                .navigationBarBackButtonHidden(true)
                .toolbar {
                    ToolbarItem (placement: .navigationBarLeading) {
                        HStack {
                            Button(action: {
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                Image(systemName: "house")
                                    .foregroundColor(.blue)
                                Text("Home")
                                    .foregroundColor(.blue)
                            }
                            Spacer()
                            Text("Scan Code")
                        }
                    }
                }
            
            CodeScannerView(codeTypes: [.code128, .qr, .ean8, .code39, .code93, .ean13], simulatedData: "000")
            { response in
                switch response {
                case .success(let result):
                    print("Found code: \(result.string)")
                    addItem()
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    func addItem()
    {
        fetchTitlesFromAPI { titles in
            guard let titles = titles else {
                print("Failed to fetch titles, items not saved.")
                return
            }
            for title in titles {
                let item = ApplicationData(name: title)
                context.insert(item)
            }
        }
    }

    func fetchTitlesFromAPI(completion: @escaping ([String]?) -> Void)
    {
        let url = URL(string: "http://127.0.0.1:5000/scrape")!
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("Error: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
                return
            }
            
            do {
                let json = try JSONDecoder().decode([String: [String]].self, from: data)
                if let titles = json["titles"] {
                    print("Fetched Titles: \(titles)")
                    completion(titles)
                } else {
                    completion(nil)
                }
            } catch {
                print("Error decoding JSON: \(error)")
                completion(nil)
            }
        }
        
        task.resume()
    }
    
    func saveFile()
    {
        fetchTitlesFromAPI { titles in
            guard let titles = titles else {
                print("Failed to fetch titles, file not saved.")
                return
            }
                
            let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fileURL = directory.appendingPathComponent("BiofactManagementSystemSavedData.txt")
                
            print("Saving file to: \(fileURL.path)")
                
            let content = titles.joined(separator: "\n") // Convert array to a string
                
            do {
                try content.write(to: fileURL, atomically: true, encoding: .utf8)
                print("File saved successfully!")
            } catch {
                print("Error saving file: \(error)")
            }
        }
    }
}
