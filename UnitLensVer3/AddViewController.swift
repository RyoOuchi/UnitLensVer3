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
        print("View Did Load")
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureButton(button: lengthButton, imageName: "length")
        configureButton(button: weightButton, imageName: "weight")
        configureButton(button: timeButton, imageName: "time")
    }
    
    private func configureButton(button: UIButton, imageName: String) {
        // Ensure the button is circular
        button.clipsToBounds = true

        // Add a constraint to ensure the button remains a circle (equal width and height)
        if button.constraints.first(where: { $0.firstAttribute == .width && $0.secondAttribute == .height }) == nil {
            button.widthAnchor.constraint(equalTo: button.heightAnchor).isActive = true
        }
        
        // Clear any existing subviews
        button.subviews.forEach { $0.removeFromSuperview() }

        // Create a UIImageView
        guard let image = UIImage(named: imageName)?.withRenderingMode(.alwaysOriginal) else {
            print("Image not found: \(imageName)")  // Debug log
            return
        }

        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = button.frame.size.width / 2
        imageView.clipsToBounds = true

        button.addSubview(imageView)

        // Set up Auto Layout constraints for the imageView
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            imageView.widthAnchor.constraint(equalTo: button.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: button.heightAnchor)
        ])

        // Apply corner radius again to ensure circular shape after layout
        button.layer.cornerRadius = button.frame.size.width / 2
        button.layoutIfNeeded()
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
    
    @IBAction func save() {
        guard let unitKey = unitName.text, !unitKey.isEmpty,
              let inputUniqueText = uniqueUnitValue.text,
              let inputUnique = Double(inputUniqueText),
              let inputOriginalText = originalUnitValue.text,
              let inputOriginal = Double(inputOriginalText) else {
            showAlert(message: "Please fill out all fields.")
            return
        }
        
        // Check if the unit already exists in the database
        if realm.objects(ConversionData.self).filter("unitKey == %@", unitKey).first != nil {
            showAlert(message: "There exists a unit that is already named \(unitKey).")
            return
        }
        
        // Resize the image before converting it to Data (if there is an image)
        let resizedImage = inputImage.image?.resized(to: CGSize(width: 200, height: 200))  // Adjust target size as needed
        let imageData: Data? = resizedImage?.pngData()
        
        // Create a new ConversionData object
        let newConversionData = ConversionData()
        let rate: Double = conversionAlgorithm.conversionRateCalculator(
            inputUniqueValue: inputUnique,
            inputOriginalValue: inputOriginal,
            originalUnitName: unitButton.titleLabel!.text!
        )
        
        let convertTo: String = conversionAlgorithm.convertToKey(
            originalUnitInput: unitButton.titleLabel!.text!
        )
        
        newConversionData.conInit(unitKey: unitKey, conversionRate: rate, unitImageData: imageData, convertToKey: convertTo)
        
        // Add the new object to the conversion data array
        conversionDataArray.append(newConversionData)
        
        // Save to Realm
        try! realm.write {
            realm.add(newConversionData)
        }
        
        self.navigationController?.popViewController(animated: true)
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
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension UIImage {
    func resized(to targetSize: CGSize) -> UIImage? {
        let size = self.size
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        let newSize = CGSize(width: size.width * min(widthRatio, heightRatio), height: size.height * min(widthRatio, heightRatio))
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        self.draw(in: CGRect(origin: .zero, size: newSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage
    }
}

