import Foundation
import SwiftUI
import AppKit


class NativeSpaceProvider: SpacesProvider {
    typealias SpaceType = NativeSpace
    
    init() {
        NativeControl.requestAccess()
    }
    
    func getSpacesWithWindows() -> [NativeSpace]? {
        let spaces = NativeControl.Display.main().getSpaces()
        let active = NativeControl.Space.active()
        
        let focused = NativeControl.Window.focused()
        
        return spaces.enumerated().map { (i, s) in
            let (windows, isFullscreen) = getWindows(for: s, focused)
            
            return NativeSpace(
                id: s.id,
                label: isFullscreen ? "↖" : String(i + 1),
                isFocused: s.id == active.id,
                windows: windows.map { w in
                    NativeSpaceWindow(
                        id: Int(w.id),
                        title: w.title ?? "",
                        appName: w.app?.localizedName,
                        isFocused: w.id == focused?.id,
                    )
                }
            )
        }.filter { !$0.windows.isEmpty }
    }
    
    private func getWindows(
        for space: NativeControl.Space,
        _ focused: NativeControl.Window? = NativeControl.Window.focused(),
    ) -> ([NativeControl.Window], isFullscreen: Bool) {
        let (base, full) = space.getWindows()
            .reduce(into: (
                base: [NativeControl.Window](),
                full: [NativeControl.Window]()
            )) { result, w in
                switch true {
                case w.isFullscreen == true:
                    result.full.append(w)
                case w.cgInfo?.layer == .base:
                    result.base.append(w)
                default:
                    /// filter out any window that is neither fullscreen nor a base one
                    break
                }
            }
         
        return !full.isEmpty
            ? (full, isFullscreen: true)
            : (base, isFullscreen: false)
    }
}
