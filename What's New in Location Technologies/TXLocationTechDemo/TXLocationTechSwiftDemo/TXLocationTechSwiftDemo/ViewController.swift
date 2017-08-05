//
//  ViewController.swift
//  TXLocationTechSwiftDemo
//
//  Created by tingxins on 05/08/2017.
//  Copyright © 2017 tingxins. All rights reserved.
//

import UIKit
import CoreLocation
import Contacts

class ViewController: UIViewController {
    
    @IBOutlet weak var locateResultLabel: UILabel!
    private lazy var manager: CLLocationManager = {
        let m = CLLocationManager()
        m.delegate = self
        return m
    }()
    
    private let geocoder: CLGeocoder = {
        return CLGeocoder()
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupLocationManager()
        
        addNotifications()
        
        postalAddressTest()
    }
    
    private func setupLocationManager() {
        manager.allowsBackgroundLocationUpdates = true
    }
}

// MARK: Custom
extension ViewController {
    
    /** Notes: App has not access privacy-sensitive data without a usage description. The app's Info.plist must contain an NSLocationXXXXXDescription key with a string value explaining to the user how the app uses this data */
    private func requestAuthorization() {
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedAlways:
            manager.requestLocation()
        case .authorizedWhenInUse:
            manager.requestAlwaysAuthorization()
        case .restricted:
            print("Restricted")
        case .denied:
            print("Denied")
        }
    }
    
    private func serial(with location: CLLocation?) {
        guard let loc = location else { return }
        print("longitude:\(loc.coordinate.longitude), latitude:\(loc.coordinate.latitude)")
        geocoder.reverseGeocodeLocation(loc) { (placemarks, error) in
            
            if (error != nil) { return }
            
            guard let pms = placemarks else { return }
            
            let placemark = pms.last!
            if #available(iOS 11.0, *) {
                print("\(placemark.name ?? "none")--\(placemark.postalAddress ?? CNPostalAddress())")
            }else {
                print("\(placemark.name ?? "none")")
            }
            
            self.locateResultLabel.text = placemark.name
        }
    }
    
    private func postalAddressTest() {
        let postalAddress = CNMutablePostalAddress()
        postalAddress.street = "Keyan Road No.9 Nanshan"
        postalAddress.city = "Shenzhen"
        postalAddress.state = "Guangdong"
        postalAddress.postalCode = "518000"
        postalAddress.country = "China"
        postalAddress.isoCountryCode = "CN"
        
        if #available(iOS 11.0, *) {
            let locale = Locale.init(identifier: "zh_Hans_CN")
            geocoder.geocodePostalAddress(postalAddress, preferredLocale: locale, completionHandler: { (placemarks, error) in
                
                if (error != nil) { return }
                
                guard let pms = placemarks else { return }
                
                let placemark = pms.last!
                
                print("\(placemark.name ?? "none")--\(placemark.postalAddress ?? CNPostalAddress())")
            })
        }
    }
}

// MARK: Background Notifications
extension ViewController {
    
    @objc func startingBackgroundLocation() {
        manager.startUpdatingLocation()
    }
    
    @objc func stoppingBackgroundLocation() {
        manager.stopUpdatingLocation()
    }
    
    private func addNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(startingBackgroundLocation), name: NSNotification.Name("BackgroundStartUpdatingLocation"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(startingBackgroundLocation), name: NSNotification.Name("BackgroundStopUpdatingLocation"), object: nil)
    }
}

// Target
extension ViewController {
    @IBAction func locating(_ sender: UIButton) {
        print(#function)
        manager.requestLocation()
    }
}

// MARK: CLLocationManagerDelegate
extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print(#function)
        requestAuthorization()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print(#function)
        let status = CLLocationManager.authorizationStatus()
        if status == .authorizedAlways ||
           status == .authorizedWhenInUse {
            serial(with: locations.last)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(#function)
    }
}
