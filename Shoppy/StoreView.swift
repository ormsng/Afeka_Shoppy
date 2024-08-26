import SwiftUI

class StoreViewModel: ObservableObject {
    @Published var products: [Product] = []
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    
    func fetchProducts() {
        guard let url = URL(string: "https://fakestoreapi.com/products") else {
            self.errorMessage = "Invalid URL"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = "Error fetching products: \(error.localizedDescription)"
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    self.errorMessage = "Server error"
                    return
                }
                
                guard let data = data else {
                    self.errorMessage = "No data received from the server"
                    return
                }
                
                // Print received data for debugging
                if let dataString = String(data: data, encoding: .utf8) {
                    print("Received data: \(dataString)")
                }
                
                do {
                    let decodedProducts = try JSONDecoder().decode([Product].self, from: data)
                    self.products = decodedProducts
                } catch {
                    self.errorMessage = "Error decoding products: \(error.localizedDescription)"
                    print("Error decoding products: \(error)")
                }
            }
        }.resume()
    }
}

struct StoreView: View {
    @StateObject private var viewModel = StoreViewModel()
    @ObservedObject var cartViewModel: CartViewModel
    
    let columns = [GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        NavigationView {
            ScrollView {
                if viewModel.isLoading {
                    ProgressView("Loading products...")
                        .padding()
                } else if let errorMessage = viewModel.errorMessage {
                    VStack {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding()
                        
                        Button("Try Again") {
                            viewModel.fetchProducts()
                        }
                        .padding()
                    }
                } else if viewModel.products.isEmpty {
                    Text("No products available")
                        .padding()
                } else {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(viewModel.products) { product in
                            ProductCard(product: product, cartViewModel: cartViewModel)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Shoppy Store")
        }
        .onAppear {
            if viewModel.products.isEmpty {
                viewModel.fetchProducts()
            }
        }
    }
}

struct ProductCard: View {
    let product: Product
    @ObservedObject var cartViewModel: CartViewModel
    
    var body: some View {
        VStack {
            AsyncImage(url: URL(string: product.image)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                ProgressView()
            }
            .frame(height: 150)
            .cornerRadius(10)
            
            Text(product.title)
                .font(.headline)
                .lineLimit(2)
                .multilineTextAlignment(.center)
            
            Text("$\(String(format: "%.2f", product.price))")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                Button(action: {
                    cartViewModel.removeFromCart(product)
                }) {
                    Image(systemName: "minus.circle")
                        .foregroundColor(.blue)
                }
                
                Text("\(cartViewModel.quantityInCart(for: product))")
                    .frame(width: 30)
                
                Button(action: {
                    cartViewModel.addToCart(product)
                }) {
                    Image(systemName: "plus.circle")
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                NavigationLink(destination: ProductDetailView(product: product)) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                }
            }
            .padding(.top, 5)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(radius: 5)
    }
}
