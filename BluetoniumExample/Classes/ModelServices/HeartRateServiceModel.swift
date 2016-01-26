//
//  HeartRateServiceModel.swift
//  BluetoniumExample
//
//  Created by Dick Verbunt on 04/01/16.
//  Copyright © 2016 E-sites. All rights reserved.
//

import Foundation
import Bluetonium


struct HeartRateServiceModelConstants {
    static let serviceUUID = "180D"
    static let heartRateUUID = "2A37"
    static let bodyLocationUUID = "2A38"
    static let controlPointUUID = "2A39"
}

/**
 HeartRateServiceModel represents the HeartRate CBService.
 */
class HeartRateServiceModel: ServiceModel {
    
    weak var delegate: HeartRateServiceModelDelegate?
    
    var heartRate = UInt16()
    var bodyLocation = NSData()
    var controlPoint = NSData()
    
    override func serviceUUID() -> String {
        return HeartRateServiceModelConstants.serviceUUID
    }
    
    override func mapping(map: Map) {
        heartRate <- (map[HeartRateServiceModelConstants.heartRateUUID], HeartRateDataTransformer())
        bodyLocation <- map[HeartRateServiceModelConstants.bodyLocationUUID]
        controlPoint <- map[HeartRateServiceModelConstants.controlPointUUID]
    }
    
    override func registerNotifyForCharacteristic(withUUID UUID: String) -> Bool {
        return UUID == HeartRateServiceModelConstants.heartRateUUID
    }
    
    override func characteristicBecameAvailable(withUUID UUID: String) {
        // Reset Energy Expended via ControlPoint if needed.
        if UUID == HeartRateServiceModelConstants.controlPointUUID {
            var rawArray:[UInt8] = [0x01];
            controlPoint = NSData(bytes: &rawArray, length: rawArray.count)
            writeValue(withUUID: UUID)
        }
    }
    
    override func characteristicDidUpdateValue(withUUID UUID: String) {
        if UUID == HeartRateServiceModelConstants.heartRateUUID {
            dispatch_async(dispatch_get_main_queue()) { () -> Void in
                self.delegate?.heartRateChanged(self.heartRate)
            }
        }
    }
    
}

/**
    HeartRateDataTransformer
    Transforms NSData to an actual HeartRate.
*/
class HeartRateDataTransformer: DataTransformer {
    
    func transform(dataToValue data: NSData?) -> MapValue {
        
        guard let data = data else {
            return UInt16()
        }
        
        var bpm = UInt16()
        let buffer = UnsafePointer<UInt8>(data.bytes)
        if (buffer[0] & 0x01 == 0){
            bpm = UInt16(buffer[1]);
        } else {
            bpm = CFSwapInt16LittleToHost(UInt16(buffer[1]))
        }
        return bpm
    }
    
    func transform(valueToData value: MapValue?) -> NSData {
        // Unused
        return NSData()
    }
    
}


protocol HeartRateServiceModelDelegate: class {
    func heartRateChanged(heartRate: UInt16)
}
