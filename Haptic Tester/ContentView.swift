//
//  ContentView.swift
//  Haptic Tester
//
//  Created by Paul Ruvolo on 1/30/23.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var firebase = FirebaseManager.shared
    @State private var nickname: String = ""
    
    var body: some View {
        VStack {
            Text("Change Device Nickname")
            TextField("Nickname", text: $nickname)
            Button("Submit") {
                firebase.changeNickname(deviceID: UIDevice.current.identifierForVendor!.uuidString, newNickname: nickname)
                print("pressed \(nickname)")
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
