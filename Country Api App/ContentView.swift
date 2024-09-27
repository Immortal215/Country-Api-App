import SwiftUI

struct ContentView: View {
    @State var countries = [Country]()
    @State var searchText = ""
    @State var names: [String] = []
    @State var screenWidth = UIScreen.main.bounds.width
    var body: some View {
        
        NavigationStack {
            
            List(searchResults, id: \.self) { country in
                VStack {
                    NavigationLink {
                        ScrollView {
                            AsyncImage(url: URL(string: "\(countries.first(where: { $0.name.common == country })?.flags.png ?? "N/A")")) { Image in
                                Image
                                    .border(.black, width: 3)
                                    .scaleEffect(0.3)
                                
                            } placeholder: { 
                                Text("Reload for Flag!")
                            }
                            .frame(width: 50, height: 50)
                            .padding()
                            .shadow(color: .gray, radius: 10)

                            
                            Box(text: "Official Name : \(countries.first(where: { $0.name.common == country })?.name.official ?? "N/A")")
                             
                        }
                        .navigationTitle(country)
                        
                        
                    } label: {
                        HStack {
                            AsyncImage(url: URL(string: "\(countries.first(where: { $0.name.common == country })?.flags.png ?? "N/A")")) { Image in
                                Image
                                    .border(.black, width: 3)
                                    .scaleEffect(0.3)
                                
                            } placeholder: { 
                                Text("Reload for Flag!")
                            }
                            .frame(width: 25, height: 0)
                            .padding()
                            
                            Text(country)
                                .padding()
                        }
                        .padding()
                    }
                }
                
            }
            .navigationTitle("Country Search")
            
        }
        .task {
            await fetchData()
        }
        .searchable(text: $searchText)
        .onChange(of: searchText) {
            if searchText != "" {
                searchText = "\(searchText.first!.uppercased())" + searchText.dropFirst().lowercased()
                
            }
        }
    }
    
    var searchResults: [String] {
        if searchText.isEmpty {
            return names
        } else {
            return names.filter { $0.contains(searchText) } 
        }
    }
    
    func fetchData() async {
        guard let url = URL(string: "https://restcountries.com/v3.1/all") else {
            print("Error forming URL")
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let decodedResponse = try? JSONDecoder().decode([Country].self, from: data) {
                countries = decodedResponse
                for i in countries {
                    names.append(i.name.common)
                }
            } else {
                print("Failed to decode response")
            }
        } catch {
            print("Error fetching data: \(error.localizedDescription)")
        }
    }
}


struct Country: Codable {
    var name: CountryName
    var flags: FlagImage 
    
    struct CountryName: Codable {
        var common: String
        var official: String
    }
    struct FlagImage: Codable {
        var png: String
    }
}

struct Box: View {
    @State var text = "" 
    @State var screenWidth = UIScreen.main.bounds.width
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15)
                .stroke(lineWidth: 2)
            
            Text(text)
                .padding()
            
        }
        .frame(maxWidth: screenWidth/1.2)
        .fixedSize(horizontal: false, vertical: true)
        .padding()
    }
}



#Preview {
    ContentView()
}
