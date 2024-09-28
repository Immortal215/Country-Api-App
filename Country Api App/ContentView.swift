import SwiftUI
import WebKit

struct ContentView: View {
    @State var countries = [Country]()
    @State var searchText = ""
    @State var names: [String] = []
    @State var screenWidth = UIScreen.main.bounds.width
    @State var screenHeight = UIScreen.main.bounds.height
    @State var isLoading = true
    var body: some View {
        
        NavigationStack {
        
            List {
                
                // goes through a-z
                ForEach(groupedCountries.keys.sorted(), id: \.self) { letter in
                    Section(letter) {
                        // goes through all the countries in each letter
                        ForEach(groupedCountries[letter] ?? [], id: \.self) { country in
                            let countryIndex = countries.first(where: { $0.name.common == country })

                            VStack {
                                NavigationLink {
                                    ScrollView {
                                        AsyncImage(url: URL(string: "\(countryIndex?.flags.png ?? "N/A")")) { Image in
                                            Image
                                                .border(.black, width: 5)
                                                .scaleEffect(0.4)
                                            
                                        } placeholder: { 
                                            ProgressView("Loading Image...")
                                        }
                                        .frame(width: 200, height: 50)
                                        .padding()
                                        .shadow(color: .gray, radius: 10)
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 15)
                                                .stroke(lineWidth: 3)
                                            
                                            DisclosureGroup("Official Name : \(countryIndex?.name.official ?? "N/A")") {
                                                Box(text: "Region : \(countryIndex?.region ?? "N/A")")
                                                
                                                Box(text: "Population : \(countryIndex?.population ?? 0) People")
                                            }
                                            .foregroundStyle(.black)
                                            .padding()
                                        }
                                        .padding()

                                        ZStack {
                                            RoundedRectangle(cornerRadius: 15)
                                                .stroke(lineWidth: 3)
                                            
                                            VStack {   
                                                Box(text :("Area : \(Int(countryIndex?.area ?? 0.0)) km²"))
                                                    .padding()
                                                    .padding(.bottom, -40)
                                                
                                                if let mapURLString = countryIndex?.maps.googleMaps {
                                                    ZStack {
                                                        WebView(url: URL(string: mapURLString)!, isLoading: $isLoading)
                                                            .frame(height: screenHeight/2)
                                                            .padding()
                                                        
                                                        if isLoading {
                                                            ProgressView("Loading Map...")
                                                        }
                                                    }
                                                } else {
                                                    Text("Map not available")
                                                        .foregroundColor(.red)
                                                        .padding()
                                                }
                                                
                                            }
                                        }
                                        .padding()
                                    }
                                    .navigationTitle(country)
                                    
                                    
                                } label: {
                                    HStack {
                                        AsyncImage(url: URL(string: "\(countryIndex?.flags.png ?? "N/A")")) { Image in
                                            Image
                                                .border(.black, width: 5)
                                                .scaleEffect(0.3)
                                            
                                        } placeholder: { 
                                            ProgressView("")
                                        }
                                        .frame(width: 50, height: 0)
                                        
                                        .padding()
                                        
                                        Text(country)
                                            .padding()
                                    }
                                    .padding()
                                }
                            }
                        }
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
    
    var groupedCountries: [String: [String]] {
        // filter names by if it contains the search txt
        let filteredNames = searchText.isEmpty ? names : names.filter { $0.contains(searchText) }
        
        var groups = [String: [String]]()
        
        // in those names that are in it, append any names to their letter 
        for name in filteredNames {
            let firstLetter = String(name.prefix(1)).uppercased()
            
            // default makes it so if the letter does not exist in the array, add that letter with an array
            groups[firstLetter, default: []].append(name)
        }
        
        return groups
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
                names.sort()
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
    var region: String
    var maps: Maps 
    var area: Double
    var population : Int
    
    struct CountryName: Codable {
        var common: String
        var official: String
    }
    struct FlagImage: Codable {
        var png: String
    }
    struct Maps: Codable {
        var googleMaps: String
    }
    
}

struct Box: View {
    @State var text = "" 
    @State var screenWidth = UIScreen.main.bounds.width
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15)
                .stroke(lineWidth: 3)
            
            Text(text)
                .padding()
            
        }
        .frame(maxWidth: screenWidth/1.2)
        .fixedSize(horizontal: false, vertical: true)
        .padding()
        .padding(.vertical, -10)
    }
}

struct WebView: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        uiView.load(request)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView
        var first = true 
        
        init(_ parent: WebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            if first { 
                parent.isLoading = true
                first = false
            }
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
        }
        
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.light)
}
