//
//  Manager.swift
//  Bluetonium
//
//  Created by Dominggus Salampessy on 23/12/15.
//  Copyright © 2015 E-sites. All rights reserved.
//

import Foundation
import CoreBluetooth

open class Manager: NSObject, CBCentralManagerDelegate {
    
    open var bluetoothEnabled: Bool {
        get {
            return centralManager?.state == .poweredOn
        }
    }
    fileprivate(set) open var scanning = false
    fileprivate(set) open var connectedDevice: Device?
    fileprivate(set) open var foundDevices: [Device]!
    open weak var delegate: ManagerDelegate?
    
    fileprivate var centralManager: CBCentralManager?
    fileprivate var disconnecting = false
    fileprivate let dispatchQueue = DispatchQueue(label: ManagerConstants.dispatchQueueLabel, attributes: [])
    
    // MARK: Initializers
    
    public init(background: Bool = false) {
        super.init()
        
        let options: [String: String]? = background ? [CBCentralManagerOptionRestoreIdentifierKey: ManagerConstants.restoreIdentifier] : nil
        foundDevices = []
        centralManager = CBCentralManager(delegate: self, queue: dispatchQueue, options: options)
    }
    
    // MARK: Public functions
    
    /**
     Start scanning for devices advertising with a specific service.
     The services can also be nil this will return all found devices.
     Found devices will be returned in the foundDevices array.
    
     - parameter services: The UUID of the service the device is advertising with, can be nil.
    */
    open func startScanForDevices(advertisingWithServices services: [String]? = nil) {
        if scanning == true {
            return
        }
        scanning = true
        
        foundDevices.removeAll()
        centralManager?.scanForPeripherals(withServices: services?.CBUUIDs(), options: nil)
    }
    
    /**
     Stop scanning for devices.
     Only possible when it's scanning.
     */
    open func stopScanForDevices() {
        scanning = false
        
        centralManager?.stopScan()
    }
    
    /**
     Connect with a device. This device is returned from the foundDevices list.
    
     - parameter device: The device to connect with.
     */
    open func connectWithDevice(_ device: Device) {
        // Only allow connecting when it's not yet connected to another device.
        if connectedDevice != nil || disconnecting {
            return
        }
        
        connectedDevice = device
        connectToDevice()
    }
    
    /**
     Disconnect from the connected device.
     Only possible when not connected to a device.
     */
    open func disconnectFromDevice() {
        // Reset stored UUID.
        storeConnectedUUID(nil)
        
        guard let peripheral = connectedDevice?.peripheral else {
            return
        }
        
        if peripheral.state != .connected {
            connectedDevice = nil
        } else {
            disconnecting = true
            centralManager?.cancelPeripheralConnection(peripheral)
        }
    }
    
    // MARK: Private functions
    
    fileprivate func connectToDevice() {
        if let peripheral = connectedDevice?.peripheral {
            // Store connected UUID, to enable later connection to the same peripheral.
            storeConnectedUUID(peripheral.identifier.uuidString)
            
            if peripheral.state == .disconnected {
                
                DispatchQueue.main.async { () -> Void in
                    // Send callback to delegate.
                    self.delegate?.manager(self, willConnectToDevice: self.connectedDevice!)
                }
                
                centralManager?.connect(peripheral, options: [CBConnectPeripheralOptionNotifyOnDisconnectionKey: NSNumber(value: true as Bool)])
            }
        }
    }
    
    /**
     Store the connectedUUID in the UserDefaults.
     This is to restore the connection after the app restarts or runs in the background.
     */
    fileprivate func storeConnectedUUID(_ UUID: String?) {
        let defaults = UserDefaults.standard
        defaults.set(UUID, forKey: ManagerConstants.UUIDStoreKey)
        defaults.synchronize()
    }
    
    /**
     Returns the stored UUID if there is one.
     */
    fileprivate func storedConnectedUUID() -> String? {
        let defaults = UserDefaults.standard
        return defaults.object(forKey: ManagerConstants.UUIDStoreKey) as? String
    }
    
    // MARK: CBCentralManagerDelegate
    
    @objc open func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        print("willRestoreState: \(dict[CBCentralManagerRestoredStatePeripheralsKey])")
    }
    
    @objc open func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        if central.state == .poweredOn {
            
            if connectedDevice != nil {
                
                connectToDevice()
                
            } else if let storedUUID = storedConnectedUUID() {
                
                if let peripheral = central.retrievePeripherals(withIdentifiers: [UUID(uuidString: storedUUID)!]).first {
                    dispatchQueue.asyncAfter(deadline: DispatchTime.now() + Double(Int64(0.2 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)) {
                        let device = Device(peripheral: peripheral)
                        device.registerServiceManager()
                        self.connectWithDevice(device)
                    }
                }
                
            }
            
        } else if central.state == .poweredOff {
            
            DispatchQueue.main.async { () -> Void in
                self.connectedDevice?.serviceModelManager.resetServices()
                
                if let connectedDevice = self.connectedDevice {
                    self.delegate?.manager(self, disconnectedFromDevice: connectedDevice, retry: true)
                }
            }
            
        }
    }
    
    @objc open func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let device = Device(peripheral: peripheral);
        if !foundDevices.contains(device) {
            foundDevices.append(device)
            
            // Only after adding it to the list to prevent issues reregistering the delegate.
            device.registerServiceManager()
            
            DispatchQueue.main.async { () -> Void in
                self.delegate?.manager(self, didFindDevice: device)
            }
        }
    }
    
    @objc open func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if let connectedDevice = connectedDevice {
            DispatchQueue.main.async { () -> Void in
                // Send callback to delegate.
                self.delegate?.manager(self, connectedToDevice: connectedDevice)
                
                // Start discovering services process after connecting to peripheral.
                connectedDevice.serviceModelManager.discoverRegisteredServices()
            }
        }
    }
    
    @objc open func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("didFailToConnect \(peripheral)")
    }
    
    @objc open func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if peripheral.identifier.uuidString == connectedDevice?.peripheral.identifier.uuidString {
            let device = connectedDevice!
            device.serviceModelManager.resetServices()
            
            if disconnecting {
                // Disconnect initated by user.
                connectedDevice = nil
                disconnecting = false
            } else {
                // Send reconnect command after peripheral disconnected.
                // It will connect again when it became available.
                central.connect(peripheral, options: nil)
            }
            
            DispatchQueue.main.async { () -> Void in
                self.delegate?.manager(self, disconnectedFromDevice: device, retry: self.connectedDevice != nil)
            }
        }
    }
    
}


public protocol ManagerDelegate: class {
    
    /**
     Called when the `Manager` did find a peripheral and did add it to the foundDevices array.
     */
    func manager(_ manager: Manager, didFindDevice device: Device)
    
    /**
     Called when the `Manager` is trying to connect to device
     */
    func manager(_ manager: Manager, willConnectToDevice device: Device)
    
    /**
     Called when the `Manager` did connect to the device.
     */
    func manager(_ manager: Manager, connectedToDevice device: Device)
    
    /**
     Called when the `Manager` did disconnect from the device.
     Retry will indicate if the Manager will retry to connect when it becomes available.
     */
    func manager(_ manager: Manager, disconnectedFromDevice device: Device, retry: Bool)
    
}


private struct ManagerConstants {
    static let dispatchQueueLabel = "nl.e-sites.bluetooth-kit"
    static let restoreIdentifier = "nl.e-sites.bluetooth-kit.restoreIdentifier"
    static let UUIDStoreKey = "nl.e-sites.bluetooth-kit.UUID"
}


internal extension Collection where Iterator.Element == String {
    
    func CBUUIDs() -> [CBUUID] {
        return self.map({ (UUID) -> CBUUID in
            return CBUUID(string: UUID)
        })
    }
    
}
