//
//  MediaRemoteBridge.swift
//  NothingHere
//

import Foundation
import OSLog

private let logger = Logger(subsystem: "boli.NothingHere", category: "MediaRemoteBridge")

enum MediaRemoteBridge {

    private typealias MRMediaRemoteSendCommandFunc = @convention(c) (UInt32, AnyObject?) -> Bool
    private typealias MRNowPlayingGetInfoCallback = @convention(block) (CFDictionary?) -> Void
    private typealias MRMediaRemoteGetNowPlayingInfoFunc =
        @convention(c) (DispatchQueue, @escaping MRNowPlayingGetInfoCallback) -> Void

    private static let kMRPause: UInt32 = 1

    private static var frameworkHandle: UnsafeMutableRawPointer? = {
        dlopen("/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote", RTLD_NOW)
    }()

    /// Send a single pause command to the current "Now Playing" source.
    @discardableResult
    static func sendPause() -> Bool {
        guard let handle = frameworkHandle else {
            logger.error("Failed to load MediaRemote.framework")
            return false
        }

        guard let sym = dlsym(handle, "MRMediaRemoteSendCommand") else {
            logger.error("Failed to find MRMediaRemoteSendCommand symbol")
            return false
        }

        let sendCommand = unsafeBitCast(sym, to: MRMediaRemoteSendCommandFunc.self)
        let result = sendCommand(kMRPause, nil)
        logger.info("MediaRemote pause sent, result: \(result)")
        return result
    }

    /// Send pause commands multiple times to catch multiple media sources.
    /// After pausing one source, macOS may switch "Now Playing" to the next active source.
    static func sendPauseToAll(rounds: Int = 5, interval: TimeInterval = 0.3) {
        sendPause()
        for i in 1..<rounds {
            DispatchQueue.main.asyncAfter(deadline: .now() + interval * Double(i)) {
                sendPause()
            }
        }
    }
}
