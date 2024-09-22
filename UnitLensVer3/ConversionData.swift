//
//  ConversionData.swift
//  UnitLensVer3
//
//  Created by 大内亮 on 2024/09/21.
//

import Foundation
import RealmSwift
import UIKit

class ConversionData: Object {
    @Persisted var unitKey: String = ""
    @Persisted var conversionRate: Double = 0
    @Persisted var unitImageData: Data?
    @Persisted var convertToKey: String = ""
    
    func conInit(unitKey: String, conversionRate: Double, unitImageData: Data? = nil, convertToKey: String) {
        self.unitKey = unitKey
        self.conversionRate = conversionRate
        self.unitImageData = unitImageData
        self.convertToKey = convertToKey
    }
    
    var unitImage: UIImage? {
        get {
            if let data = unitImageData {
                return UIImage(data: data)
            }
            return nil
        }
        set {
            unitImageData = newValue?.jpegData(compressionQuality: 1.0)
        }
    }
}
