//
//  Converter.swift
//  UnitLensVer3
//
//  Created by 大内亮 on 2024/09/21.
//

class Converter {
    let length: [String] = ["mm", "cm", "m", "km", "inch", "foot", "yard", "mile"]
    let weight: [String] = ["mg", "g", "kg", "t"]
    let time: [String] = ["sec", "min", "hour", "day", "week", "year"]
    let unitTypeArray: [String] = ["length", "weight", "time"]

    struct ConversionEdge {
        let unit: String
        let factor: Double
    }

    private var conversionGraph: [String: [ConversionEdge]] = [:]

    init() {
        // Initialize conversion for length units
        addConversion(fromUnit: "mile", toUnit: "km", factor: 1.60934)
        addConversion(fromUnit: "km", toUnit: "m", factor: 1000)
        addConversion(fromUnit: "m", toUnit: "cm", factor: 100)
        addConversion(fromUnit: "cm", toUnit: "mm", factor: 10)
        addConversion(fromUnit: "inch", toUnit: "cm", factor: 2.54)
        addConversion(fromUnit: "foot", toUnit: "inch", factor: 12)
        addConversion(fromUnit: "yard", toUnit: "foot", factor: 3)
        addConversion(fromUnit: "mile", toUnit: "yard", factor: 1760)

        // Initialize conversion for weight units
        addConversion(fromUnit: "t", toUnit: "kg", factor: 1000)
        addConversion(fromUnit: "kg", toUnit: "g", factor: 1000)
        addConversion(fromUnit: "g", toUnit: "mg", factor: 1000)

        // Initialize conversion for time units
        addConversion(fromUnit: "year", toUnit: "week", factor: 52)
        addConversion(fromUnit: "week", toUnit: "day", factor: 7)
        addConversion(fromUnit: "day", toUnit: "hour", factor: 24)
        addConversion(fromUnit: "hour", toUnit: "min", factor: 60)
        addConversion(fromUnit: "min", toUnit: "sec", factor: 60)
    }

    private func addConversion(fromUnit: String, toUnit: String, factor: Double) {
        if conversionGraph[fromUnit] == nil {
            conversionGraph[fromUnit] = []
        }
        if conversionGraph[toUnit] == nil {
            conversionGraph[toUnit] = []
        }
        
        conversionGraph[fromUnit]?.append(ConversionEdge(unit: toUnit, factor: factor))
        conversionGraph[toUnit]?.append(ConversionEdge(unit: fromUnit, factor: 1 / factor))
    }

    //This function returns: value * toUnit/fromUnit
    func convert(value: Double, fromUnit: String, toUnit: String) -> Double? {
        if !areUnitsInSameCategory(unit1: fromUnit, unit2: toUnit) {
            print("Units are from different categories and cannot be converted.")
            return nil
        }
        
        guard fromUnit != toUnit else { return value }
        
        var queue: [(unit: String, currentFactor: Double)] = [(unit: fromUnit, currentFactor: 1)]
        var visited: Set<String> = [fromUnit]
        
        while !queue.isEmpty {
            let (currentUnit, currentFactor) = queue.removeFirst()
            
            if let edges = conversionGraph[currentUnit] {
                for edge in edges {
                    let newUnit = edge.unit
                    let newFactor = currentFactor * edge.factor
                    
                    if newUnit == toUnit {
                        return value * newFactor
                    }
                    
                    if !visited.contains(newUnit) {
                        visited.insert(newUnit)
                        queue.append((unit: newUnit, currentFactor: newFactor))
                    }
                }
            }
        }
        
        return nil
    }

    private func areUnitsInSameCategory(unit1: String, unit2: String) -> Bool {
        return (length.contains(unit1) && length.contains(unit2)) ||
               (weight.contains(unit1) && weight.contains(unit2)) ||
               (time.contains(unit1) && time.contains(unit2))
    }
    
    func convertToBaseUnit(input: Double, inputUnit: String, inputUnitType: String) -> Double {
        switch inputUnitType {
        case "length":
            return convert(value: input, fromUnit: inputUnit, toUnit: "m") ?? 0
        case "weight":
            return convert(value: input, fromUnit: inputUnit, toUnit: "kg") ?? 0
        case "time":
            return convert(value: input, fromUnit: inputUnit, toUnit: "sec") ?? 0
        default:
            return 0
        }
    }
    
    func convertToBaseString(inputUnitType: String) -> String {
        switch inputUnitType{
        case "length":
            return "m"
        case "weight":
            return "kg"
        case "time":
            return "s"
        default:
            return "nil"
        }
    }
    
    func getUnitCategory(for unit: String) -> String? {
            if length.contains(unit) {
                return "length"
            } else if weight.contains(unit) {
                return "weight"
            } else if time.contains(unit) {
                return "time"
            } else {
                return nil
            }
        }
    
    func conversionRateCalculator(inputUniqueValue: Double, inputOriginalValue: Double, originalUnitName: String) -> Double{
        let conversionRateNotBase: Double = inputUniqueValue/inputOriginalValue
        let originalUnitBase = convertToBaseString(inputUnitType: getUnitCategory(for: originalUnitName)!)
        let baseUnitConversion: Double = convert(value: 1, fromUnit: originalUnitBase, toUnit: originalUnitName) ?? 0
        let conversionRate: Double = baseUnitConversion * conversionRateNotBase
        
        return conversionRate
    }
    
    func convertToKey(originalUnitInput: String) -> String{
        return convertToBaseString(inputUnitType: getUnitCategory(for: originalUnitInput)!)
    }
    
    func baseUnitToOtherUnit(conversionRate: Double, baseUnit: String, otherUnit: String) -> Double{
        guard let unitConversionConstant = convert(value: 1, fromUnit: otherUnit, toUnit: baseUnit) else { return 0 }
        return conversionRate * unitConversionConstant
    }
}
