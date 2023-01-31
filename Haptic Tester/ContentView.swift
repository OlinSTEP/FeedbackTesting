//
//  ContentView.swift
//  Haptic Tester
//
//  Created by Paul Ruvolo on 1/30/23.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var firebase = FirebaseManager.shared
    let myDeviceID = UIDevice.current.identifierForVendor!.uuidString
    
    var body: some View {
        VStack {
            Text("Change Device Nickname")
            TextField("Nickname", text: $firebase.myNickname)
            Button("Submit") {
                firebase.changeNickname(deviceID: myDeviceID, newNickname: firebase.myNickname)
            }
            List(firebase.devices.sorted(by: <), id: \.key) { deviceID, name in
                Text(name).onTapGesture {
                    firebase.sendHaptic(deviceID: deviceID)
                }
            }
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
