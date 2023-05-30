//
//  ContentView.swift
//  PatchMan
//
//  Created by Corey Oliphant on 5/26/23.
//

import SwiftUI

struct PatchData: Identifiable {
    var id = UUID()

    let name: String
    let policyTargetVersion: String
    let availableVersion: String
}

struct ContentView: View {
    @State private var jamfUrl: String = ""
    @State private var jamfUser: String = ""
    @State private var jamfPass: String = ""
    @State private var selectedPatches = Set<PatchData.ID>()
    @State private var patchesPending: Array<PatchData> = [
        PatchData(name: "Chrome", policyTargetVersion: "65.1.2", availableVersion: "66.2.1"),
        PatchData(name: "Firefox", policyTargetVersion: "23.4.32", availableVersion: "43.5.3"),
        PatchData(name: "Opera", policyTargetVersion: "1.2.3", availableVersion: "4.5.6"),
        PatchData(name: "Brave", policyTargetVersion: "4.5.6", availableVersion: "7.8.9"),
        PatchData(name: "Vivaldi", policyTargetVersion: "10.2.1", availableVersion: "10.2.2"),
        PatchData(name: "Edge", policyTargetVersion: "65.4.3", availableVersion: "82.3.1")
    ] // Mock Data
    @State private var showAlert = false

    var body: some View {
        VStack {
            VStack {
                TextField("Jamf Pro URL", text: $jamfUrl)
                HStack{
                    TextField("Username", text: $jamfUser)
                    TextField("Password", text: $jamfPass)
                }

                Button(action: {
                    showAlert = true
                }, label: {
                    Text("Get Patches!")
                        .frame(maxWidth: .infinity)
                })
                .alert(Text("Error"), isPresented: $showAlert, actions: {
                    Button(action: {
                        showAlert = false
                    }, label: {
                        Text("OK")
                    })
                }, message: {
                    Text("Invalid credentials provided")
                })
                .disabled(jamfUrl.isEmpty || jamfUser.isEmpty || jamfPass.isEmpty)
            }

            Divider()

            Table(patchesPending, selection: $selectedPatches) {
                TableColumn("Name", value: \.name)
                TableColumn("Current Target Version", value: \.policyTargetVersion)
                TableColumn("Available Version", value: \.availableVersion)
            }
            .scrollIndicators(.visible)

            Divider()

            Button(action: {
                patchesPending = patchesPending.filter{
                    !selectedPatches.contains($0.id)
                }
                selectedPatches.removeAll()
            }) {
                Text("Remove Patches")
                    .frame(maxWidth: .infinity)
            }
            .disabled(selectedPatches.isEmpty)
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
