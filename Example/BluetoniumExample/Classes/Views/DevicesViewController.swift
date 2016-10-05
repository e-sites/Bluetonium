//
//  DevicesViewController.swift
//  BluetoniumExample
//
//  Created by Dominggus Salampessy on 23/12/15.
//  Copyright © 2015 E-sites. All rights reserved.
//

import UIKit
import Bluetonium

class DevicesViewController: UITableViewController, ManagerDelegate {

    lazy var btManager: Manager = {
        let manager = Manager(background: true)
        manager.delegate = self
        return manager
    }()
    let batteryServiceModel = BatteryServiceModel()
    let heartRateServiceModel = HeartRateServiceModel()
    
    var scanButton:UIBarButtonItem?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scanButton = UIBarButtonItem(title: "Start", style: .plain, target: self, action: #selector(DevicesViewController.toggleScan))
        
        title = "Devices"
        navigationItem.rightBarButtonItem = scanButton
        tableView.register(UITableViewCell.classForCoder(), forCellReuseIdentifier: "DeviceCell")
    }

    override func viewDidDisappear(_ animated: Bool) {
        scanButtonTitle("Start")
        btManager.stopScanForDevices()
    }
    
    
    // MARK: BTManagerDelegate
    
    func manager(_ manager: Manager, didFindDevice device: Device) {
        tableView!.reloadData()
    }
    
    func manager(_ manager: Manager, willConnectToDevice device: Device) {
        presentConnectedViewWithDevice(device)
    }
    
    func manager(_ manager: Manager, connectedToDevice device: Device) {
    }
    
    
    func manager(_ manager: Manager, disconnectedFromDevice device: Device, retry: Bool) {
    }
    
    // MARK: UITableViewDatasource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return btManager.foundDevices.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "DeviceCell")!
        let device = btManager.foundDevices[indexPath.row]
        
        var text = "⛄️ No name"
        if let name = device.peripheral.name {
            text = name
        }
        cell.textLabel!.text = text
        cell.textLabel?.font = (device.peripheral.state == .connected) ? UIFont.boldSystemFont(ofSize: 14) : UIFont.systemFont(ofSize: 14)
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let device = btManager.foundDevices[indexPath.row]
        presentConnectedViewWithDevice(device)
        btManager.connectWithDevice(device)
    }
    
    // MARK: Private functions
    
    func toggleScan() {
        if btManager.scanning {
            btManager.stopScanForDevices()
            scanButtonTitle("Start")
        } else {
            btManager.startScanForDevices()
            scanButtonTitle("Stop")
        }
    }
    
    func scanButtonTitle(_ title: String) {
        scanButton?.title = title
    }
    
    func presentConnectedViewWithDevice(_ device: Device) {
        device.registerServiceModel(batteryServiceModel)
        device.registerServiceModel(heartRateServiceModel)
        
        let vc = ConnectedViewController(nibName: "ConnectedViewController", bundle: Bundle.main)
        vc.btManager = btManager
        present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
    }
    
}
