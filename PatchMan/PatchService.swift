//
//  NetworkService.swift
//  PatchMan
//
//  Created by Corey Oliphant on 6/15/23.
//

import Foundation

class PatchService: ObservableObject {
    @Published var isFetching: Bool = false
    @Published var pendingPatches: [PatchData] = []
    @Published var error: Error?

    private var jpsUrl: String = ""
    private var username: String = ""
    private var password: String = ""

    private let authEndpoint = "/api/auth/tokens"
    private let patchTitleConfigEndpoint = "/api/v2/patch-software-title-configurations"
    private let patchDefinitionEndpoint = "/api/v2/patch-software-title-configurations/{id}/definitions"
    private let patchPolicyEndpoint = "/api/v2/patch-policies"

    private var jpsToken: AuthToken?

    private var patchTitles: [PatchTitle] = []
    private var patchDefinitions: [PatchDefinition] = []
    private var patchPolicies: [PatchPolicy] = []


    enum FetchError: Error {
        case badCredentials(errorMessage: String)
        case badRequest(errorMessage: String)
        case badJSON(errorMessage: String)
        
        func get() -> String {
            switch self {
            case .badCredentials(let message):
                return message
            case .badRequest(let message):
                return message
            case .badJSON(let message):
                return message
            }
        }
    }

    init(patchData: [PatchData] = []) {
        self.pendingPatches = patchData
        URLSession.shared.configuration.httpAdditionalHeaders = ["Accept": "application/json"]
    }
    
    func setJpsUrl(_ url: String) {
        self.jpsUrl = url
    }
    
    func setJpsUsername(_ user: String) {
        self.username = user
    }
    
    func setJpsPassword(_ password: String) {
        self.password = password
    }

    func getPendingPatches() async throws {
        await MainActor.run{
            isFetching = true
            pendingPatches.removeAll(keepingCapacity: true)
        }

        do {
            try await authenticate()
            try await fetchPatchTitleConfigs()

            if !patchTitles.isEmpty {
                async let fetchPolicies: () = fetchPatchPolicies()
                async let fetchDefinitions: () = fetchPatchDefinitions()
                
                _ = try await [
                    fetchPolicies,
                    fetchDefinitions
                ]
            }

        } catch {
            await MainActor.run {
                isFetching = false
            }
            
            throw error
        }

        await calculatePendingPatches()
        
        await MainActor.run {
            isFetching = false
        }
    }

    private func authenticate() async throws {
        print("Authentication endpoint called")
        guard let url = URL(string: "\(jpsUrl)\(authEndpoint)") else { return }
        guard let authString = getBasicAuthString(username: username, password: password) else { return }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue("Basic \(authString)", forHTTPHeaderField: "authorization")

        let (data, response) = try await URLSession.shared.data(for: req)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            if (response as? HTTPURLResponse)?.statusCode == 401 {
                throw FetchError.badCredentials(errorMessage: "Unable to authenticate with the JPS, invalid credentials provided")
            } else {
                throw FetchError.badRequest(errorMessage: "Error \((response as? HTTPURLResponse)!.statusCode), Unable to authenticate with the JPS")
            }
        }

        jpsToken = try JSONDecoder().decode(AuthToken.self, from: data)
    }

    private func fetchPatchTitleConfigs() async throws {
        print("Patch title endpoint called")
        patchTitles.removeAll(keepingCapacity: true)
        guard let url = URL(string: "\(jpsUrl)\(patchTitleConfigEndpoint)"), let token = jpsToken?.token else { return }

        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.addValue("Bearer \(token)", forHTTPHeaderField: "authorization")

        let (data, response) = try await URLSession.shared.data(for: req)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw FetchError.badRequest(errorMessage: "Error \((response as? HTTPURLResponse)!.statusCode), Unable to retrieve patch title configurations from the JPS")
        }

        patchTitles = try JSONDecoder().decode([PatchTitle].self, from: data)
    }

    private func fetchPatchDefinitions() async throws {
        print("Patch definitions endpoint called")
        guard let token = jpsToken?.token else { return }
        
        patchDefinitions.removeAll(keepingCapacity: true)
        patchDefinitions = try await withThrowingTaskGroup(of: (String, Data).self, returning: [PatchDefinition].self ) { group in
            for title in patchTitles {
                var urlQueries: [URLQueryItem] = []
                urlQueries.append(URLQueryItem(name: "page", value: "0"))
                urlQueries.append(URLQueryItem(name: "page-size", value: "1"))
                urlQueries.append(URLQueryItem(name: "sort", value: "absoluteOrderId:asc"))
                
                var url = URL(string: "\(jpsUrl)\(patchDefinitionEndpoint.replacingOccurrences(of: "{id}", with: title.softwareTitleId))")!
                url.append(queryItems: urlQueries)
                let taskUrl = url
                
                group.addTask {
                    var req = URLRequest(url: taskUrl)
                    req.httpMethod = "GET"
                    req.addValue("Bearer \(token)", forHTTPHeaderField: "authorization")
                    
                    let (data, response) = try await URLSession.shared.data(for: req)
                    guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                        throw FetchError.badRequest(errorMessage: "Error \((response as? HTTPURLResponse)!.statusCode), Unable to retrieve patch definitions for \(title.displayName) from the JPS")
                    }
                    
                    return (title.softwareTitleId, data)
                }
            }
            
            return try await group.reduce(into: [PatchDefinition]()) { result, data in
                let json = try JSONDecoder().decode(PatchDefinitionsResults.self, from: data.1)
                if var policy = json.results.first {
                    policy.softwareTitleId = data.0
                    result.append(policy)
                }
            }
        }
        
        print("Finished fetching patch definitions")

    }

    private func fetchPatchPolicies() async throws {
        print("Patch policy endpoint called")
        guard let token = jpsToken?.token else { return }
        
        patchPolicies.removeAll(keepingCapacity: true)
        patchPolicies = try await withThrowingTaskGroup(of: Data.self, returning: [PatchPolicy].self ) { group in
            for title in patchTitles {
                var urlQueries: [URLQueryItem] = []
                urlQueries.append(URLQueryItem(name: "page", value: "0"))
                urlQueries.append(URLQueryItem(name: "page-size", value: "1"))
                urlQueries.append(URLQueryItem(name: "sort", value: "id:desc"))
                urlQueries.append(URLQueryItem(name: "filter", value: "softwareTitleConfigurationId==\"{id}\"".replacingOccurrences(of: "{id}", with: title.softwareTitleId)))
                
                var url = URL(string: "\(jpsUrl)\(patchPolicyEndpoint)")!
                url.append(queryItems: urlQueries)
                let taskUrl = url
                
                group.addTask {
                    var req = URLRequest(url: taskUrl)
                    req.httpMethod = "GET"
                    req.addValue("Bearer \(token)", forHTTPHeaderField: "authorization")
                    
                    let (data, response) = try await URLSession.shared.data(for: req)
                    guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                        throw FetchError.badRequest(errorMessage: "Error \((response as? HTTPURLResponse)!.statusCode), Unable to retrieve patch policies for \(title.displayName) from the JPS")
                    }
                    
                    return data
                }
            }
            
            return try await group.reduce(into: [PatchPolicy]()) { result, data in
                let json = try JSONDecoder().decode(PatchPolicyResults.self, from: data)
                if let policy = json.results.first {
                    result.append(policy)
                }
            }
        }
        
        print("Finished fetching patch policies")
    }

    @MainActor private func calculatePendingPatches() async {
        for title in patchTitles {
            let definition = patchDefinitions.first { definition in
                definition.softwareTitleId == title.softwareTitleId
            }
            
            let policy = patchPolicies.first { policy in
                policy.softwareTitleConfigurationId == title.softwareTitleId
            }
            
            guard let definition = definition, let policy = policy else { continue }
            
            if (definition.version != policy.policyTargetVersion) {                
                pendingPatches.append(PatchData(name: title.displayName, policyTargetVersion: policy.policyTargetVersion, availableVersion: definition.version, availableDate: definition.releaseDate, enabled: policy.policyEnabled))
            }
        }
    }

    private func getBasicAuthString(username: String, password: String) -> String? {
        return "\(username):\(password)".data(using: .utf8)?.base64EncodedString()
    }

    private func handleError(error: Error) {

    }
}
