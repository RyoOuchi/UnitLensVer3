//
//  ResultViewController.swift
//  UnitLensVer3
//
//  Created by 大内亮 on 2024/09/21.
//

import UIKit
import RealmSwift

class ResultViewController: UIViewController {
    
    let realm = try! Realm()
    //ex. ぞう,キリン
    var uniqueUnitName: String = ""
    var inputFromVC: Double = 0
    //Data from VC
    
    var conversionData: ConversionData?
    let conversionAlgorithm = Converter()
    
    //Outlets
    @IBOutlet var unitTypeImage: UIImageView!
    @IBOutlet var layerLabel: UILabel!
    @IBOutlet var conversionRateLabel: UILabel!
    @IBOutlet var inputUniqueTextField: UITextField!
    @IBOutlet var inputOriginalTextField: UITextField!
    @IBOutlet var uniqueUnitNameLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("Input from View Controller: \(inputFromVC). Unique Unit Name: \(uniqueUnitName)")
        conversionData = fetchConversionData(for: uniqueUnitName)
        uniqueUnitNameLabel.text = uniqueUnitName
        conversionRateLabel.text = "\(conversionData!.conversionRate) \(uniqueUnitName)/\(conversionData!.convertToKey)"
        
        unitTypeImage.image = UIImage(named: conversionAlgorithm.getUnitCategory(for: conversionData!.convertToKey)!)
        roundEdges(view: inputUniqueTextField)
        roundEdges(view: inputOriginalTextField)
        roundEdges(view: conversionRateLabel)
        
    }
    
    func roundEdges<T: UIView>(view: T){
        view.layer.cornerRadius = 22.0
        view.clipsToBounds = true
    }
    
    
    //fetch functions
    func fetchConversionData(for uniqueUnitName: String) -> ConversionData? {
        return realm.objects(ConversionData.self).filter("unitKey == %@", uniqueUnitName).first
    }
}
