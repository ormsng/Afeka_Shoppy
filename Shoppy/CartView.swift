import SwiftUI
import Foundation

class CartViewModel: ObservableObject {
    @Published var cartItems: [Product: Int] = [:]
    @Published var couponCode: String = ""
    @Published var couponMessage: String = ""
    @Published var discountPercentage: Double = 0
    
    init() {
        loadCart()
    }
    
    var subtotal: Double {
        cartItems.reduce(0) { $0 + ($1.key.price * Double($1.value)) }
    }
    
    var total: Double {
        subtotal * (1 - discountPercentage)
    }
    
    var itemCount: Int {
        cartItems.values.reduce(0, +)
    }
    
    func addToCart(_ product: Product) {
        cartItems[product, default: 0] += 1
        saveCart()
    }
    
    func removeFromCart(_ product: Product) {
        guard let quantity = cartItems[product], quantity > 0 else { return }
        if quantity == 1 {
            cartItems.removeValue(forKey: product)
        } else {
            cartItems[product] = quantity - 1
        }
        saveCart()
    }
    
    func quantityInCart(for product: Product) -> Int {
        cartItems[product] ?? 0
    }
    
    func applyCoupon() {
        if couponCode.uppercased() == "SUMMER2024" {
            discountPercentage = 0.2
            couponMessage = "20% discount applied!"
        } else {
            discountPercentage = 0
            couponMessage = "Invalid coupon code."
        }
    }
    
    func checkout() {
        print("Proceeding to checkout with total: $\(String(format: "%.2f", total))")
        
        // Increment order count for each product in the cart
        for (product, quantity) in cartItems {
            FirebaseDatabaseService.shared.incrementOrderCount(for: product.id, by: quantity)
        }
        
        // Clear the cart after successful checkout
        cartItems.removeAll()
        couponCode = ""
        couponMessage = ""
        discountPercentage = 0
        saveCart()
    }
    
    public func saveCart() {
        do {
            let encoder = JSONEncoder()
            let cartData = try encoder.encode(cartItems.map { CartItem(product: $0.key, quantity: $0.value) })
            UserDefaults.standard.set(cartData, forKey: "savedCart")
        } catch {
            print("Failed to save cart: \(error)")
        }
    }
    
    private func loadCart() {
        guard let savedCartData = UserDefaults.standard.data(forKey: "savedCart") else { return }
        
        do {
            let decoder = JSONDecoder()
            let savedCartItems = try decoder.decode([CartItem].self, from: savedCartData)
            cartItems = Dictionary(uniqueKeysWithValues: savedCartItems.map { ($0.product, $0.quantity) })
        } catch {
            print("Failed to load cart: \(error)")
        }
    }
}

struct CartItem: Codable {
    let product: Product
    let quantity: Int
}

struct CartView: View {
    @EnvironmentObject var viewModel: CartViewModel
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(Array(viewModel.cartItems.keys), id: \.id) { item in
                        CartItemRow(item: item)
                            .listRowInsets(EdgeInsets())
                            .background(Color.clear)
                    }
                }
                .listStyle(PlainListStyle())
                
                VStack {
                    HStack {
                        TextField("Enter coupon code", text: $viewModel.couponCode)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        Button("Apply") {
                            viewModel.applyCoupon()
                        }
                        .disabled(viewModel.couponCode.isEmpty)
                    }
                    .padding(.horizontal)
                    
                    if !viewModel.couponMessage.isEmpty {
                        Text(viewModel.couponMessage)
                            .foregroundColor(viewModel.discountPercentage > 0 ? .green : .red)
                    }
                    
                    HStack {
                        Text("Subtotal:")
                        Spacer()
                        Text("$\(String(format: "%.2f", viewModel.subtotal))")
                    }
                    .padding(.horizontal)
                    
                    if viewModel.discountPercentage > 0 {
                        HStack {
                            Text("Discount:")
                            Spacer()
                            Text("-$\(String(format: "%.2f", viewModel.subtotal * viewModel.discountPercentage))")
                        }
                        .padding(.horizontal)
                    }
                    
                    HStack {
                        Text("Total:")
                            .fontWeight(.bold)
                        Spacer()
                        Text("$\(String(format: "%.2f", viewModel.total))")
                            .fontWeight(.bold)
                    }
                    .padding(.horizontal)
                    
                    Button(action: {
                        viewModel.checkout()
                    }) {
                        Text("Checkout")
                            .frame(minWidth: 0, maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding()
                    .disabled(viewModel.cartItems.isEmpty)
                }
            }
            .navigationTitle("Cart")
            .overlay(
                Group {
                    if viewModel.cartItems.isEmpty {
                        Text("Your cart is empty")
                            .foregroundColor(.secondary)
                    }
                }
            )
        }
    }
}

struct CartItemRow: View {
    let item: Product
    @EnvironmentObject var viewModel: CartViewModel
    
    var body: some View {
        HStack {
            AsyncImage(url: URL(string: item.image)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                ProgressView()
            }
            .frame(width: 50, height: 50)
            
            VStack(alignment: .leading) {
                Text(item.title)
                    .lineLimit(1)
                Text("$\(String(format: "%.2f", item.price))")
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack {
                Button(action: {
                    viewModel.removeFromCart(item)
                }) {
                    Image(systemName: "minus.circle")
                        .foregroundColor(.blue)
                }
                .buttonStyle(PlainButtonStyle())
                
                Text("\(viewModel.quantityInCart(for: item))")
                    .frame(width: 30)
                
                Button(action: {
                    viewModel.addToCart(item)
                }) {
                    Image(systemName: "plus.circle")
                        .foregroundColor(.blue)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Button(action: {
                viewModel.cartItems.removeValue(forKey: item)
                viewModel.saveCart()
            }) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .background(Color.clear)
    }
}
