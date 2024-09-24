//
//  AddViewController.swift
//  UnitLensVer3
//
//  Created by 大内亮 on 2024/09/21.
//

import UIKit
import RealmSwift
import PhotosUI

class AddViewController: UIViewController, PHPickerViewControllerDelegate, UITextFieldDelegate {
    
    let realm = try! Realm()
    @IBOutlet var uniqueUnitValue: UITextField!
    @IBOutlet var unitName: UITextField!
    var conversionDataArray: [ConversionData] = []
    
    @IBOutlet var originalUnitValue: UITextField!
    @IBOutlet var lengthButton: UIButton!
    @IBOutlet var weightButton: UIButton!
    @IBOutlet var timeButton: UIButton!
    @IBOutlet var label1: UILabel!
    @IBOutlet var label2: UILabel!
    @IBOutlet var label: UILabel!
    @IBOutlet var inputImage: UIImageView!
    @IBOutlet var imageUploadButton: UIButton!
    @IBOutlet var conversionRateLabel: UILabel!
    @IBOutlet var unitButton: UIButton!
    let conversionAlgorithm = Converter()
    
    var unitType: String = "length"
    var units: [String] = []
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        uniqueUnitValue.delegate = self
        unitName.delegate = self
        originalUnitValue.delegate = self
        
        // Add target to text fields for real-time conversion rate update
        uniqueUnitValue.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        originalUnitValue.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        unitName.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        // Setup other UI elements
        units = fetchUnits(unitType: unitType)
        unitButtonSetTitle()
        setupUnitButtonMenu()
        conversionDataArray = fetchConversionData()
        
        // Round labels and buttons
        label1.layer.cornerRadius = 22.0
        label1.clipsToBounds = true
        label2.layer.cornerRadius = 22.0
        label2.clipsToBounds = true
        conversionRateLabel.layer.cornerRadius = 22.0
        conversionRateLabel.clipsToBounds = true
        label.layer.cornerRadius = 22.0
        label.clipsToBounds = true
        imageUploadButton.layer.cornerRadius = 22.0
        imageUploadButton.clipsToBounds = true
        uniqueUnitValue.layer.cornerRadius = 20.0
        originalUnitValue.layer.cornerRadius = 20.0
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        print("Length button frame: \(lengthButton.frame)")  // Check the button size
        print("Weight button frame: \(weightButton.frame)")
        print("Time button frame: \(timeButton.frame)")
        
        // Ensure buttons are circular
        configureButton(button: lengthButton, imageName: "length")
        configureButton(button: weightButton, imageName: "weight")
        configureButton(button: timeButton, imageName: "time")
    }
    
    private func configureButton(button: UIButton, imageName: String) {
        // Ensure the button is circular
        button.layer.cornerRadius = button.frame.size.width / 2
        button.clipsToBounds = true
        
        // Clear any existing images
        button.setImage(nil, for: .normal)
        
        // Create a UIImageView
        guard let image = UIImage(named: imageName)?.withRenderingMode(.alwaysOriginal) else {
            print("Image not found: \(imageName)")  // Debug log
            return
        }
        
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFill
        let imageSize = button.frame.size.width
        
        imageView.frame = CGRect(x: (button.frame.size.width - imageSize) / 2,
                                 y: (button.frame.size.height - imageSize) / 2,
                                 width: imageSize,
                                 height: imageSize)
        
        imageView.layer.cornerRadius = imageSize / 2
        imageView.clipsToBounds = true
        
        button.addSubview(imageView)
    }
    
    @IBAction func uploadImages(){
        var configuration = PHPickerConfiguration()
        let filter = PHPickerFilter.images
        configuration.filter = filter
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        let itemProvider = results.first?.itemProvider
        if let itemProvider, itemProvider.canLoadObject(ofClass: UIImage.self) {
            itemProvider.loadObject(ofClass: UIImage.self) { image , error in
                DispatchQueue.main.async {
                    self.inputImage.image = image as? UIImage
                }
            }
        }
        
        dismiss(animated: true)
    }
    
    @IBAction func pressLengthButton(){
        unitType = "length"
        print("pressed \(unitType)")
        unitButtonSetTitle()
        units = fetchUnits(unitType: unitType)
    }
    
    @IBAction func pressWeightButton(){
        unitType = "weight"
        print("pressed \(unitType)")
        unitButtonSetTitle()
        units = fetchUnits(unitType: unitType)
    }
    
    @IBAction func pressTimeButton(){
        unitType = "time"
        print("pressed \(unitType)")
        unitButtonSetTitle()
        units = fetchUnits(unitType: unitType)
    }
    
    func showAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func save(){
        guard let unitKey = unitName.text, !unitKey.isEmpty,
              let inputUniqueText = uniqueUnitValue.text,
              let inputUnique = Double(inputUniqueText),
              let inputOriginalText = originalUnitValue.text,
              let inputOriginal = Double(inputOriginalText) else {
            showAlert(message: "Please fill out all fields.")
            return
        }
        
        if realm.objects(ConversionData.self).filter("unitKey == %@", unitKey).first != nil {
            showAlert(message: "There exists a unit that is already named \(unitKey).")
            return
        }
        
        let newConversionData = ConversionData()
        let rate: Double = conversionAlgorithm.conversionRateCalculator(inputUniqueValue: inputUnique, inputOriginalValue: inputOriginal, originalUnitName: unitButton.titleLabel!.text!)
        let convertTo: String = conversionAlgorithm.convertToKey(originalUnitInput: unitButton.titleLabel!.text!)
        newConversionData.conInit(unitKey: unitKey, conversionRate: rate, convertToKey: convertTo)
        //TODO fill convertToKey
        
        conversionDataArray.append(newConversionData)
        
        try! realm.write {
            realm.add(conversionDataArray)
        }
        
        dismiss(animated: true)
    }
    
    func fetchConversionData() -> [ConversionData] {
        return Array(realm.objects(ConversionData.self))
    }
    
    func unitButtonSetTitle() {
        unitButton.setTitle(conversionAlgorithm.convertToBaseString(inputUnitType: unitType), for: .normal)
    }
    
    @IBAction func pressUnitButton() {
        print("pressed unit button")
    }
    
    func setupUnitButtonMenu() {
        let actions = units.map { unit in
            UIAction(title: unit, image: nil) { _ in
                self.unitButton.setTitle(unit, for: .normal)  // First update the button title
                self.updateConversionRateLabel(selectedUnit: unit)  // Pass selected unit directly
                print("\(unit) selected")
            }
        }
        
        let menu = UIMenu(title: "Select Unit", children: actions)
        
        unitButton.menu = menu
        unitButton.showsMenuAsPrimaryAction = true
    }
    
    func fetchUnits(unitType: String) -> [String] {
        var stringArray: [String] = []
        switch unitType{
        case "length":
            stringArray = conversionAlgorithm.length
        case "weight":
            stringArray = conversionAlgorithm.weight
        case "time":
            stringArray = conversionAlgorithm.time
        default:
            break
        }
        return stringArray
    }
    
    func updateConversionRateLabel(selectedUnit: String? = nil) {
        guard let unitKey = unitName.text, !unitKey.isEmpty,
              let inputUniqueText = uniqueUnitValue.text, let inputUnique = Double(inputUniqueText),
              let inputOriginalText = originalUnitValue.text, let inputOriginal = Double(inputOriginalText) else {
            conversionRateLabel.text = "Please fill out all fields"
            return
        }
        
        // Use the selected unit if provided, else fallback to the button title
        let originalUnitTitle = selectedUnit ?? unitButton.titleLabel?.text ?? ""
        
        let conversionRate = conversionAlgorithm.conversionRateCalculator(inputUniqueValue: inputUnique, inputOriginalValue: inputOriginal, originalUnitName: originalUnitTitle)
        let convertToBase = conversionAlgorithm.convertToBaseString(inputUnitType: unitType)
        conversionRateLabel.text = "\(conversionRate) \(unitKey)/\(convertToBase)"
    }
    
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        updateConversionRateLabel()
    }
    
}
