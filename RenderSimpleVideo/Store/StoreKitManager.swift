//
//  StoreKit.swift
//  RenderSimpleVideo
//
//  Created by javi www on 7/20/24.
//

import SwiftUI
import StoreKit

@MainActor
final class StoreKitManager: ObservableObject {
    
    static var shared: StoreKitManager = .init()

    @Published private(set) var products: [Product] = []
    
//    @Published var productBasicRequest: Product?
    @Published var productPriorityRequest: Product?

    var updateListenerTask: Task<Void, Error>? = nil
    
    @Published var storeProducts: [Product] = []
    @Published var purchasedProducts: [Product] = []
    
    init() {
        
        updateListenerTask = listenForTransactions()
        
        Task {
            await requestProducts()
            await updateCustomerProductStatus()
        }

    }
    
    func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    await self.updateCustomerProductStatus()
                    await transaction.finish()
                } catch {
                    print("Transaction faled verification")
                }
            }
        }
    }
    
    @MainActor
    func updateCustomerProductStatus() async {
        
        var purchasedProducts: [Product] = []
        for await result in StoreKit.Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                print("Added \(transaction)")
                if let prod = storeProducts.first(where: {
                    $0.id  == transaction.productID
                }) {
                    purchasedProducts.append(prod)
                }
            } catch {
                print("erro \(error)")
            }
            
            self.purchasedProducts = purchasedProducts
        }
    }
    
    func requestProducts() async {
        
        do {
            
            products = try await Product.products(
                for: [
                    "request.priority.videomockup"
                ]
            )
            
            for prod in products {
                if prod.id == "request.priority.videomockup" {
                    productPriorityRequest = prod
                    print("Found priority request")
                }
            }

        } catch {
            products = []
            print("Error getting products")
        }
    }
    
    func pruchaseWithResult(_ product: Product) async throws -> StoreKit.Transaction? {
        
        let purchaseResult = try await product.purchase()
        switch purchaseResult {
        case .success(let verificationResult):
            let transaction = try checkVerified(verificationResult)
            await transaction.finish()
            print("transc \(transaction)")
            return transaction
        case .userCancelled, .pending:
            print(purchaseResult)
            return nil
        default:
            print(purchaseResult)
            return nil
        }
    }

    func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(let t, let verRes):
            print(t)
            print(verRes)
            print("Unverified \(verRes))")
            throw StoreKitError.failedVerification
        case .verified(let signedType):
            return signedType
        }
    }
}

public enum StoreKitError: Error {
    case failedVerification
}
