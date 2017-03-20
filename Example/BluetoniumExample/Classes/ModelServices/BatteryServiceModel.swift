//
//  BatteryServiceModel.swift
//  BluetoniumExample
//
//  Created by Dick Verbunt on 24/12/15.
//  Copyright © 2015 E-sites. All rights reserved.
//

import Foundation
import Bluetonium


struct BatteryServiceModelConstants {
    static let serviceUUID = "180F"
    static let batteryLevelUUID = "2A19"
}

/**
 BatteryServiceModel represents the Battery CBService.
 */
class BatteryServiceModel: ServiceModel {
    
    weak var delegate: BatteryServiceModelDelegate?
    
    var batteryLevel: UInt8 = 0
    
    override func serviceUUID() -> String {
        return BatteryServiceModelConstants.serviceUUID
    }
    
    override func mapping(_ map: Map) {
        batteryLevel <- map[BatteryServiceModelConstants.batteryLevelUUID]
    }
    
    override func registerNotifyForCharacteristic(withUUID UUID: String) -> Bool {
        return true
    }
    
    override func characteristicBecameAvailable(withUUID UUID: String) {
        readValue(withUUID: UUID)
    }
    
    override func characteristicDidUpdateValue(withUUID UUID: String) {
        if UUID == BatteryServiceModelConstants.batteryLevelUUID {
            DispatchQueue.main.async {
                self.delegate?.batteryLevelChanged(self.batteryLevel)
            }
        }
    }
}


protocol BatteryServiceModelDelegate: class {
    func batteryLevelChanged(_ batteryLevel: UInt8)
}
