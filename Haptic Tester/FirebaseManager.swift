//
//  FirebaseManager.swift
//  Haptic Tester
//
//  Created by Paul Ruvolo on 1/30/23.
//

import Foundation
import FirebaseCore
import FirebaseDatabase
import UIKit

class FirebaseManager: ObservableObject {
    public static var shared = FirebaseManager()
    private var dbRef: DatabaseReference?
    private var generator = UIImpactFeedbackGenerator(style: .heavy)
    
    private let myDeviceID = UIDevice.current.identifierForVendor!.uuidString
    @Published private(set) var devices: [String: String] = [:]
    private var myServerTimestamp: Double?
    
    private init() {
        FirebaseApp.configure()
        generator.prepare()
        dbRef = Database.database().reference()
        setupFirebase()
    }
    
    /// Setup observers for Firebase and set timestamp and haptic flags
    private func setupFirebase() {
        dbRef?.child("devices").child(myDeviceID).updateChildValues(["haptic": false, "timestamp": ServerValue.timestamp()]) { (error, ref) -> Void in
            guard error == nil else {
                return
            }
            ref.observeSingleEvent(of: .value) {
                (snapshot) in
                guard let value = snapshot.value as? [String: Any] else {
                    return
                }
                guard let timestamp = value["timestamp"] as? Double else {
                    return
                }
                self.myServerTimestamp = timestamp
                self.setupListeners()
            }
        }
    }
    
    func setupListeners() {
        guard let myServerTimestamp = myServerTimestamp else {
            return
        }
        dbRef?.child("devices").observe(.childAdded) { (snapshot, error) in
            guard let value = snapshot.value as? [String: Any] else {
                return
            }
            guard let timestamp = value["timestamp"] as? Double else {
                return
            }
            let name = value["name"] as? String ?? snapshot.key
            guard abs(timestamp - myServerTimestamp)/1000.0 < 600 else {
                return
            }
            print("checking \(snapshot.key)")
            if self.devices[snapshot.key] != name {
                self.devices[snapshot.key] = name
            }
        }
        
        dbRef?.child("devices").observe(.childChanged) { (snapshot, error) in
            guard let value = snapshot.value as? [String: Any] else {
                return
            }
            guard let timestamp = value["timestamp"] as? Double else {
                return
            }
            guard abs(timestamp - myServerTimestamp)/1000.0 < 600 else {
                return
            }
            let name = value["name"] as? String ?? snapshot.key
            if self.devices[snapshot.key] != name {
                self.devices[snapshot.key] = name
            }
            if snapshot.key == self.myDeviceID {
                if value["haptic"] as? Bool == true {
                    self.generateHaptic()
                    self.dbRef?.child("devices").child(self.myDeviceID).child("haptic").setValue(false)
                }
            }
        }
    }
    
    func sendHaptic(deviceID: String) {
        dbRef?.child("devices").child(deviceID).child("haptic").setValue(true)
    }
    
    private func generateHaptic() {
        generator.impactOccurred()
    }
    
    func changeNickname(deviceID: String, newNickname: String) {
        self.dbRef?.child("devices").child(self.myDeviceID).child("name").setValue(newNickname)
    }
}
