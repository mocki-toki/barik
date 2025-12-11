//==============================================================================
//
//  Acknowledgement:
//  The private Core Graphics Services function signatures and type definitions
//  used in this file are based on the headers curated by the nuikit/cgsinternal
//  project.
//
//  GitHub: https://github.com/nuikit/cgsinternal/
//
//==============================================================================

import Foundation

// MARK: - CGS Types

typealias CGSConnectionID = Int
typealias CGSSpaceID = Int
typealias CGSWindowID = UInt32
typealias CGSDirectDisplayID = UInt32
typealias CGError = Int32

extension CGError {
    static let success: CGError = 0
}

// MARK: - CGSInternal Swift Wrapper

final class CGSInternal {
    
    // MARK: - Connection Functions
    
    @_silgen_name("CGSMainConnectionID")
    private static func _CGSMainConnectionID() -> CGSConnectionID
    
    @_silgen_name("CGSMainDisplayID")
    private static func _CGSMainDisplayID() -> CGSDirectDisplayID
    
    static let mainConnectionID = _CGSMainConnectionID
    static let mainDisplayID =  _CGSMainDisplayID
    
    // MARK: - Space Functions
    
    @_silgen_name("CGSGetActiveSpace")
    private static func _CGSGetActiveSpace(_ cid: CGSConnectionID) -> CGSSpaceID
    
    @_silgen_name("CGSCopyManagedDisplaySpaces")
    private static func _CGSCopyManagedDisplaySpaces(_ cid: CGSConnectionID) -> CFArray?
    
    static func getActiveSpace(connection: CGSConnectionID) -> CGSSpaceID { _CGSGetActiveSpace(connection) }
    
    static func copyManagedDisplaySpaces(connection: CGSConnectionID) -> [[String: Any]]? {
        return _CGSCopyManagedDisplaySpaces(connection) as? [[String: Any]]
    }
    
    // MARK: - Window Functions
    
    @_silgen_name("CGSCopyWindowsWithOptionsAndTags")
    private static func _CGSCopyWindowsWithOptionsAndTags(
        _ cid: CGSConnectionID,
        _ owner: Int,
        _ spaces: CFArray,
        _ options: Int,
        _ setTags: UnsafeMutablePointer<Int>,
        _ clearTags: UnsafeMutablePointer<Int>
    ) -> CFArray?
    
    static func copyWindows(connection: CGSConnectionID, spaces: [CGSSpaceID], options: Int = 2) -> [CGSWindowID]? {
        var setTags = 0
        var clearTags = 0
        
        return _CGSCopyWindowsWithOptionsAndTags(
            connection,
            0,
            spaces as CFArray,
            options,
            &setTags,
            &clearTags
        ) as? [CGSWindowID]
    }
}
