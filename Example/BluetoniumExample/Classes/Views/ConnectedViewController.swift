//
//  HeartRateViewController.swift
//  BluetoniumExample
//
//  Created by Dominggus Salampessy on 04/01/16.
//  Copyright © 2016 E-sites. All rights reserved.
//

import UIKit
import Bluetonium

class ConnectedViewController :  UIViewController, ManagerDelegate, HeartRateServiceModelDelegate, BatteryServiceModelDelegate {
    @IBOutlet weak var uuidLabel:UILabel!
    @IBOutlet weak var nameLabel:UILabel!
    @IBOutlet weak var batteryLabel:UILabel!
    @IBOutlet weak var heartRateLabel:UILabel!
    
    weak var btManager:Manager? {
        didSet {
            btManager?.delegate = self
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Connecting..."
        
        guard let connectedDevice = btManager?.connectedDevice else {
            return
        }
        
        for model in connectedDevice.registedServiceModels {
            if let heartRateServiceModel = model as? HeartRateServiceModel {
                heartRateServiceModel.delegate = self
            }
            if let batteryServiceModel = model as? BatteryServiceModel {
                batteryServiceModel.delegate = self
            }
        }
        
        self.uuidLabel.text = connectedDevice.peripheral.identifier.uuidString
        if connectedDevice.peripheral.state == .connected {
            title = "Connected"
        }
        if let name = connectedDevice.peripheral.name {
            nameLabel.text = name
        }
    }
    
    @IBAction func didPressDisconnect(sender:UIButton?) {
        btManager?.disconnectFromDevice()
        
        self.dismiss(animated: true, completion: nil)
    }    
    
    // MARK: Manager delegate
    
    func manager(_ manager: Manager, willConnectToDevice device: Device) {
        
    }
    
    func manager(_ manager: Manager, didFindDevice device: Device) {
        
    }
    
    func manager(_ manager: Manager, connectedToDevice device: Device) {
        self.title = "Connected!"
    }
    
    func manager(_ manager: Manager, disconnectedFromDevice device: Device, willRetry retry: Bool) {
        if !retry {
            self.dismiss(animated: true, completion: nil)
        } else {
            self.title = "Connecting..."
        }
    }
    
    // MARK: ServiceModel delegates
    
    func heartRateChanged(_ heartRate: UInt16) {
        heartRateLabel.text = "\(heartRate) bpm"
    }
    
    func batteryLevelChanged(_ batteryLevel: UInt8) {
        batteryLabel.text = "\(batteryLevel) %"
    }
}
