import SwiftUI

struct ContentView: View {
    @State var countries = [Country]()
    @State var searchText = ""
    @State var names: [String] = []
    @State var screenWidth = UIScreen.main.bounds.width
    var body: some View {
        
        NavigationStack {
            
            // .prefix limits to 10
            List(searchResults, id: \.self) { country in
                VStack {
                    //                    Text(country.name.official)
                    //                    Text(country.name.common)
                    NavigationLink {
                        ScrollView {
                            ZStack {
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(lineWidth: 2)
                                
                                Text("Official Name : \(countries[0].name.official)")
                                    .font(.title2)
                                    .padding()
                            }
                            .fixedSize()
                            .frame(width: screenWidth/1.2)
                        }
                        .navigationTitle(country)
                        
                        
                    } label: {
                        Text(country)
                    }
                }
                
            }
            .navigationTitle("Countries")
            
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
    
    struct CountryName: Codable {
        var common: String
        var official: String
    }
}
#Preview {
    ContentView()
}
