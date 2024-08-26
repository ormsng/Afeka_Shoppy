import SwiftUI
import FirebaseDatabase

class ProductDetailViewModel: ObservableObject {
    @Published var orderCount: Int = 0
    private var databaseRef: DatabaseReference?
    private let product: Product
    
    init(product: Product) {
        self.product = product
        setupDatabaseListener()
    }
    
    deinit {
        removeDatabaseListener()
    }
    
    private func setupDatabaseListener() {
        let ref = Database.database(url: "https://shoppy-7c23b-default-rtdb.firebaseio.com/").reference()
        databaseRef = ref.child("products").child(String(product.id)).child("orderCount")
        
        databaseRef?.observe(.value) { [weak self] snapshot in
            if let count = snapshot.value as? Int {
                DispatchQueue.main.async {
                    self?.orderCount = count
                }
            }
        }
    }
    
    private func removeDatabaseListener() {
        databaseRef?.removeAllObservers()
    }
}

struct ProductDetailView: View {
    let product: Product
    @StateObject private var viewModel: ProductDetailViewModel
    
    init(product: Product) {
        self.product = product
        _viewModel = StateObject(wrappedValue: ProductDetailViewModel(product: product))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                AsyncImage(url: URL(string: product.image)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    ProgressView()
                }
                .frame(height: 300)
                .frame(maxWidth: .infinity)
                .cornerRadius(10)
                
                Text(product.title)
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Price: $\(String(format: "%.2f", product.price))")
                    .font(.headline)
                
                Text("Category: \(product.category)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("Description:")
                    .font(.headline)
                
                Text(product.description)
                    .font(.body)
                
                Text("Number of Orders: \(viewModel.orderCount)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
        .navigationTitle("Product Details")
    }
}

struct ProductDetailView_Previews: PreviewProvider {
    static var previews: some View {
        ProductDetailView(product: Product(id: 1, title: "Sample Product", price: 19.99, description: "This is a sample product description.", category: "Sample Category", image: "https://fakestoreapi.com/img/81fPKd-2AYL._AC_SL1500_.jpg"))
    }
}
