import Foundation
import FirebaseDatabase

class FirebaseDatabaseService {
    static let shared = FirebaseDatabaseService()
    private let ref: DatabaseReference
    
    private init() {
        ref = Database.database(url: "https://shoppy-7c23b-default-rtdb.firebaseio.com/").reference()
    }
    
    func getOrderCount(for productId: Int, completion: @escaping (Int) -> Void) {
        ref.child("products").child(String(productId)).child("orderCount").observeSingleEvent(of: .value) { snapshot in
            if let count = snapshot.value as? Int {
                completion(count)
            } else {
                completion(0)
            }
        }
    }
    
    func incrementOrderCount(for productId: Int, by amount: Int = 1) {
        let productRef = ref.child("products").child(String(productId)).child("orderCount")
        productRef.runTransactionBlock { (currentData: MutableData) -> TransactionResult in
            var count = currentData.value as? Int ?? 0
            count += amount
            currentData.value = count
            return TransactionResult.success(withValue: currentData)
        } andCompletionBlock: { error, _, _ in
            if let error = error {
                print("Error updating order count: \(error.localizedDescription)")
            }
        }
    }
}
