import SwiftUI

struct MainTabView: View {
    @StateObject private var cartViewModel = CartViewModel()
    
    var body: some View {
        TabView {
            StoreView(cartViewModel: cartViewModel)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
            
            CartView()
                .environmentObject(cartViewModel)
                .tabItem {
                    Image(systemName: "cart")
                    Text("Cart")
                }
                .badge(cartItemCount)
        }
    }
    
    private var cartItemCount: Int {
        cartViewModel.cartItems.values.reduce(0, +)
    }
}
