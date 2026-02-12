//
//  MediaControlService.swift
//  NothingHere
//

import CoreAudio
import OSLog

private let logger = Logger(subsystem: "boli.NothingHere", category: "MediaControl")

protocol MediaControlServiceProtocol {
    func pauseAllMedia()
}

final class MediaControlService: MediaControlServiceProtocol {

    // MARK: - Public

    func pauseAllMedia() {
        logger.info("Pausing all media playback")

        // Layer 1: MediaRemote — pause the current "Now Playing" source
        MediaRemoteBridge.sendPause()

        // Layer 2: Mute system audio as safety net
        muteSystemAudio()
    }

    // MARK: - System audio mute

    private func muteSystemAudio() {
        var defaultOutputDeviceID = AudioDeviceID(0)
        var propertySize = UInt32(MemoryLayout<AudioDeviceID>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address, 0, nil, &propertySize, &defaultOutputDeviceID
        )

        guard status == noErr else {
            logger.error("Failed to get default audio output device: \(status)")
            return
        }

        address.mSelector = kAudioDevicePropertyMute
        address.mScope = kAudioDevicePropertyScopeOutput

        var muteValue: UInt32 = 1
        let muteStatus = AudioObjectSetPropertyData(
            defaultOutputDeviceID,
            &address, 0, nil,
            UInt32(MemoryLayout<UInt32>.size),
            &muteValue
        )

        if muteStatus == noErr {
            logger.info("System audio muted")
        } else {
            logger.warning("Failed to mute system audio: \(muteStatus)")
        }
    }

}
