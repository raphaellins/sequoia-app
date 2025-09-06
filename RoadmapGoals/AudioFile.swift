import Foundation
import AVFoundation

struct AudioFile: Identifiable, Codable {
    var id = UUID()
    var name: String
    var fileName: String
    var fileURL: URL?
    var duration: TimeInterval = 0
    var fileSize: Int64 = 0
    var createdAt: Date = Date()
    var scheduledTime: Date?
    var targetDevice: AudioDevice?
    var isPlaying: Bool = false
    var isScheduled: Bool = false
    var recurringType: RecurringType = .none
    var volumeFadeIn: Bool = true
    var fadeInDuration: TimeInterval = 5.0 // seconds
    
    enum AudioDevice: Codable {
        case homeKitSpeaker(HomeKitSpeakerInfo)
        case airPlayDevice(AirPlayDeviceInfo)
        case airPods
        case phone
        case bluetooth
        
        struct HomeKitSpeakerInfo: Codable {
            let id: String
            let name: String
            let model: String
            let isReachable: Bool
        }
        
        struct AirPlayDeviceInfo: Codable {
            let id: String
            let name: String
            let type: String
            let isConnected: Bool
        }
        
        var displayName: String {
            switch self {
            case .homeKitSpeaker(let info): return info.name
            case .airPlayDevice(let info): return info.name
            case .airPods: return "AirPods"
            case .phone: return "iPhone"
            case .bluetooth: return "Bluetooth Speaker"
            }
        }
        
        var icon: String {
            switch self {
            case .homeKitSpeaker(let info):
                let name = info.name.lowercased()
                if name.contains("homepod") {
                    return "homepod"
                } else if name.contains("mini") {
                    return "homepod.mini"
                } else {
                    return "speaker.wave.2"
                }
            case .airPlayDevice(let info):
                let type = info.type.lowercased()
                if type.contains("airplay") {
                    return "airplayvideo"
                } else if type.contains("bluetooth") {
                    return "bluetooth"
                } else {
                    return "speaker.wave.2"
                }
            case .airPods: return "airpods"
            case .phone: return "iphone"
            case .bluetooth: return "speaker.wave.2"
            }
        }
        
        var isHomeKitDevice: Bool {
            if case .homeKitSpeaker = self {
                return true
            }
            return false
        }
        
        var isAirPlayDevice: Bool {
            if case .airPlayDevice = self {
                return true
            }
            return false
        }
        
        var homeKitInfo: HomeKitSpeakerInfo? {
            if case .homeKitSpeaker(let info) = self {
                return info
            }
            return nil
        }
        
        var airPlayInfo: AirPlayDeviceInfo? {
            if case .airPlayDevice(let info) = self {
                return info
            }
            return nil
        }
    }
    
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var formattedFileSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }
    
    var isReadyToPlay: Bool {
        return fileURL != nil && FileManager.default.fileExists(atPath: fileURL?.path ?? "")
    }
    
    var timeUntilPlay: TimeInterval? {
        guard let scheduledTime = scheduledTime else { return nil }
        return scheduledTime.timeIntervalSinceNow
    }
    
    var formattedTimeUntilPlay: String? {
        guard let timeUntil = timeUntilPlay, timeUntil > 0 else { return nil }
        
        let totalSeconds = Int(timeUntil)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

enum RecurringType: String, Codable, CaseIterable {
    case none = "none"
    case daily = "daily"
    case weekdays = "weekdays"
    
    var displayName: String {
        switch self {
        case .none: return "Once"
        case .daily: return "Every Day"
        case .weekdays: return "Weekdays Only"
        }
    }
    
    var icon: String {
        switch self {
        case .none: return "calendar"
        case .daily: return "calendar.badge.clock"
        case .weekdays: return "calendar.badge.clock"
        }
    }
}
