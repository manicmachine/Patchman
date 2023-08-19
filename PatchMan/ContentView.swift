//
//  ContentView.swift
//  PatchMan
//
//  Created by Corey Oliphant on 5/26/23.
//
import KeychainAccess
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var patchService: PatchService
    @State private var sortOrder = [KeyPathComparator(\PatchData.name)]
    @State private var selectedPatches = Set<PatchData.ID>()
    @State private var showAlert = false
    @State private var alertText: String = ""
    @State private var savePassword: Bool = false
    
    @State private var jpsUrl = ""
    @State private var username: String = ""
    @State private var password: String = ""
    
    private var defaults = UserDefaults.standard
    private var keychain = Keychain(service: "edu.uwec.patchman")

    var body: some View {
        VStack {
            VStack {
                TextField("Jamf Pro URL", text: $jpsUrl)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: jpsUrl) { newValue in
                        patchService.setJpsUrl(newValue)
                        defaults.set(jpsUrl, forKey: "jpsUrl")
                    }
                HStack{
                    TextField("Username", text: $username)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: username) { newValue in
                            patchService.setJpsUsername(newValue)
                            defaults.set(username, forKey: "username")
                        }
                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: password) { newValue in
                            patchService.setJpsPassword(newValue)
                        }
                }

                HStack {
                    Button(action: {
                        if savePassword {
                            DispatchQueue.global(qos: .background).async {
                                keychain[username] = password
                            }
                        }

                        Task {
                            do {
                                try await patchService.getPendingPatches()
                            } catch {
                                if let fetchError = error as? PatchService.FetchError {
                                    self.alertText = fetchError.get()
                                } else {
                                    self.alertText = error.localizedDescription
                                }
                                
                                self.showAlert = true
                            }
                        }
                    }, label: {
                        if patchService.isFetching {
                            ProgressView()
                                .progressViewStyle(LinearProgressViewStyle())
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Get Patches!")
                                .frame(maxWidth: .infinity)
                        }
                    })
                    .alert(Text("Error"), isPresented: $showAlert, actions: {
                        Button(action: {
                            showAlert = false
                        }, label: {
                            Text("OK")
                        })
                    }, message: {
                        Text(alertText)
                    })
                    .disabled(jpsUrl.isEmpty || username.isEmpty || password.isEmpty || patchService.isFetching)

                    Toggle("Save Password", isOn: $savePassword)
                    .onChange(of: savePassword) { newValue in
                        defaults.set(savePassword, forKey: "savePassword")
                        if newValue {
                            DispatchQueue.global(qos: .background).async {
                                keychain[username] = password
                            }
                        } else {
                            DispatchQueue.global(qos: .background).async {
                                keychain[username] = ""
                            }
                        }
                    }
                }
            }

            Divider()

            Table(patchService.pendingPatches, selection: $selectedPatches, sortOrder: $sortOrder) {
                TableColumn("Name", value: \.name)
                TableColumn("Current Version", value: \.policyTargetVersion)
                TableColumn("Available Version", value: \.availableVersion)
                TableColumn("Enabled", value: \.enabledString)
            }
            .onChange(of: sortOrder, perform: {
                patchService.pendingPatches.sort(using: $0)
            })
            .scrollIndicators(.visible)

            Divider()

            Button(action: {
                patchService.pendingPatches = patchService.pendingPatches.filter{
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
        .onAppear {
            jpsUrl = defaults.string(forKey: "jpsUrl") ?? ""
            username = defaults.string(forKey: "username") ?? ""
            savePassword = defaults.bool(forKey: "savePassword")
            
            if savePassword {
                password = Keychain(service: "edu.uwec.patchman")[username] ?? ""
            }
        }
    }
}

//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        let testPatches = [
//            PatchData(name: "Chrome", policyTargetVersion: "65.1.2", availableVersion: "66.2.1"),
//            PatchData(name: "Firefox", policyTargetVersion: "23.4.32", availableVersion: "43.5.3"),
//            PatchData(name: "Opera", policyTargetVersion: "1.2.3", availableVersion: "4.5.6"),
//            PatchData(name: "Brave", policyTargetVersion: "4.5.6", availableVersion: "7.8.9"),
//            PatchData(name: "Vivaldi", policyTargetVersion: "10.2.1", availableVersion: "10.2.2"),
//            PatchData(name: "Edge", policyTargetVersion: "65.4.3", availableVersion: "82.3.1")
//        ]
//
//        let patchService = PatchService(patchData: testPatches)
//
//        ContentView()
//            .environmentObject(patchService)
//    }
//}
