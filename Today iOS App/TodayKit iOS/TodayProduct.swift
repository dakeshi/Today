//
//  TodayProduct.swift
//  Today
//
//  Created by UetaMasamichi on 9/11/16.
//  Copyright © 2016 Masamichi Ueta. All rights reserved.
//

import Foundation
import StoreKit

struct TodayProduct {
    private static let Prefix = "com.uetamasamichi.Today."
    private static let Beer = Prefix + "Beer"
    
    static let productIdentifiers: Set = [TodayProduct.Beer]
    
    static func resourceNameForProductIdentifier(productIdentifier: String) -> String? {
        return productIdentifier.components(separatedBy: ".").last
    }
    
    static let store = IAPManager(productIds: TodayProduct.productIdentifiers)
    static var products: [SKProduct] = []
}
