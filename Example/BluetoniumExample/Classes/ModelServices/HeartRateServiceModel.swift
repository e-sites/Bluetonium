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
    var bodyLocation = Data()
    var controlPoint = Data()
    
    override var serviceUUID:String {
        return HeartRateServiceModelConstants.serviceUUID
    }
    
    override func mapping(_ map: Map) {
        heartRate       <- (map[HeartRateServiceModelConstants.heartRateUUID], HeartRateDataTransformer())
        bodyLocation    <- map[HeartRateServiceModelConstants.bodyLocationUUID]
        controlPoint    <- map[HeartRateServiceModelConstants.controlPointUUID]
    }
    
    override func registerNotifyForCharacteristic(withUUID uuid: String) -> Bool {
        return uuid == HeartRateServiceModelConstants.heartRateUUID
    }
    
    override func characteristicBecameAvailable(withUUID uuid: String) {
        // Reset Energy Expended via ControlPoint if needed.
        if uuid != HeartRateServiceModelConstants.controlPointUUID {
            return
        }
        
        var rawArray:[UInt8] = [0x01]
        controlPoint = Data(bytes: &rawArray, count: rawArray.count)
        writeValue(withUUID: uuid)
    }
    
    override func characteristicDidUpdateValue(withUUID uuid: String) {
        if (uuid != HeartRateServiceModelConstants.heartRateUUID) {
            return
        }
        DispatchQueue.main.async {
            self.delegate?.heartRateChanged(self.heartRate)
        }
    }
}

/**
 HeartRateDataTransformer
 Transforms Data to an actual HeartRate.
 */
class HeartRateDataTransformer: DataTransformer {
    
    func transform(dataToValue data: Data?) -> MapValue {
        
        guard let data = data else {
            return UInt16()
        }
        
        return data.withUnsafeBytes { (buffer: UnsafePointer<UInt16>) in
            if (buffer[0] & 0x01 == 0) {
                return UInt16(buffer[1]) as UInt16
            } else {
                return CFSwapInt16LittleToHost(UInt16(buffer[1])) as UInt16
            }
        }
    }
    
    func transform(valueToData value: MapValue?) -> Data {
        // Unused
        return Data()
    }
}


protocol HeartRateServiceModelDelegate: class {
    func heartRateChanged(_ heartRate: UInt16)
}
