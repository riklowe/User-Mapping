//
//  DataManager.swift
//  User Mapping
//
//  Created by Richard Lowe on 03/10/2024.
//

import Foundation

class DataManager {
    static let shared = DataManager()

    private init() {}

    let fileURL: URL = {
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError("Unable to access document directory")
        }
        return documentsURL.appendingPathComponent("walks").appendingPathExtension("json")
    }()

    func loadWalks() -> [Walk] {
        if let data = try? Data(contentsOf: fileURL),
           let walks = try? JSONDecoder().decode([Walk].self, from: data) {
            return walks
        }
        return []
    }

    func saveWalks(_ walks: [Walk]) {
        do {
            let data = try JSONEncoder().encode(walks)
            try data.write(to: fileURL)
        } catch {
            print("Error saving walks: \(error)")
        }
    }
}
