//
//  helper.swift
//  User Mapping
//
//  Created by Richard Lowe on 04/10/2024.
//

import Foundation

// Helper method to format duration
func formatDuration(_ duration: TimeInterval) -> String {
    let hours = Int(duration) / 3600
    let minutes = (Int(duration) % 3600) / 60
    let seconds = Int(duration) % 60

    if hours > 0 {
        return String(format: "%dh %dm %ds", hours, minutes, seconds)
    } else if minutes > 0 {
        return String(format: "%dm %ds", minutes, seconds)
    } else {
        return String(format: "%ds", seconds)
    }
}

