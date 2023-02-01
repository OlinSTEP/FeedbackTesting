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
    let hapticManager = HapticManager()
    private var dbRef: DatabaseReference?
    private var generator = UIImpactFeedbackGenerator(style: .heavy)
    
    private let myDeviceID = UIDevice.current.identifierForVendor!.uuidString
    @Published private(set) var devices: [String: String] = [:]
    @Published var myNickname: String = ""
    private var myServerTimestamp: Double?
    
    private init() {
        FirebaseApp.configure()
        generator.prepare()
        dbRef = Database.database().reference()
        setupFirebase()
    }
    
    /// Setup observers for Firebase and set timestamp and haptic flags
    private func setupFirebase() {
        dbRef?.child("devices").child(myDeviceID).updateChildValues(["haptic": ["doHaptic": false], "timestamp": ServerValue.timestamp()]) { (error, ref) -> Void in
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
        dbRef?.child("devices").observe(.childAdded) { (snapshot, error) in
            self.handleDBUpdate(snapshot)
        }
        
        dbRef?.child("devices").observe(.childChanged) { (snapshot, error) in
            self.handleDBUpdate(snapshot)
        }
    }
    
    func handleDBUpdate(_ snapshot: DataSnapshot) {
        guard let myServerTimestamp = myServerTimestamp else {
            return
        }
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
        if snapshot.key == self.myDeviceID, let haptic = value["haptic"] as? [String: Any] {
            if haptic["doHaptic"] as? Bool == true, let intensity = haptic["intensity"] as? Float, let sharpness = haptic["sharpness"] as? Float, let attackTime = haptic["attackTime"] as? Float, let releaseTime = haptic["releaseTime"] as? Float, let decayTime = haptic["decayTime"] as? Float {
                self.generateHaptic(description: HapticDescription(intensity: intensity, sharpness: sharpness, attackTime: attackTime, releaseTime: releaseTime, decayTime: decayTime))
                self.dbRef?.child("devices").child(self.myDeviceID).child("haptic").child("doHaptic").setValue(false)
            }
            if let myName = value["name"] as? String {
                self.myNickname = myName
            }
        }
    }
    
    func sendHaptic(deviceID: String, description: HapticDescription) {
        dbRef?.child("devices").child(deviceID).child("haptic").updateChildValues(["doHaptic": true, "intensity": description.intensity, "sharpness": description.sharpness, "attackTime": description.attackTime, "releaseTime": description.releaseTime, "decayTime": description.decayTime])
    }
    
    private func generateHaptic(description: HapticDescription) {
        hapticManager.adjustHaptics(description: description)
        hapticManager.unpauseHaptics()
    }
    
    func changeNickname(deviceID: String, newNickname: String) {
        self.dbRef?.child("devices").child(self.myDeviceID).child("name").setValue(newNickname)
    }
}
