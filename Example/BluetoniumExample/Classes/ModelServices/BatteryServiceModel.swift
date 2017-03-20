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
    
    override open var serviceUUID:String {
        return BatteryServiceModelConstants.serviceUUID
    }
    
    override func mapping(_ map: Map) {
        batteryLevel <- map[BatteryServiceModelConstants.batteryLevelUUID]
    }
    
    override func registerNotifyForCharacteristic(withUUID uuid: String) -> Bool {
        return true
    }
    
    override func characteristicBecameAvailable(withUUID uuid: String) {
        readValue(withUUID: uuid)
    }
    
    override func characteristicDidUpdateValue(withUUID uuid: String) {
        guard uuid == BatteryServiceModelConstants.batteryLevelUUID else {
            return
        }
        
        DispatchQueue.main.async {
            self.delegate?.batteryLevelChanged(self.batteryLevel)
        }
    }
}


protocol BatteryServiceModelDelegate: class {
    func batteryLevelChanged(_ batteryLevel: UInt8)
}
