//==============================================================================
//
//  Acknowledgement:
//  The private `_AXUIElementGetWindow` function signature used in this file
//  is based on the `extern.h` header file from the yabai window manager
//  project by koekeishiya.
//
//  Source Link: https://github.com/koekeishiya/yabai/blob/1d9eaa5dbea3d1deb29facb499a5c32bd6536d7a/src/misc/extern.h
//
//==============================================================================

import Foundation
import ApplicationServices

final class AXSInternal {
    
    @_silgen_name("_AXUIElementGetWindow")
    private static func _AXUIElementGetWindow(_ element: AXUIElement, _ wid: UnsafeMutablePointer<CGSWindowID>) -> AXError
    
    static func getWindowID(for element: AXUIElement) -> CGSWindowID? {
        var windowID: CGSWindowID = 0
        let error = _AXUIElementGetWindow(element, &windowID)
        
        guard error == .success else {
            return nil
        }
        
        return windowID
    }
}
