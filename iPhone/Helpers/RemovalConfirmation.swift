// The dialog is iOS-only; the file compiles in the Watch target too (registered like FocusOverlay.swift).
// Al-Islam also extends the Quran and hadith stores here with "ask before removing" toggles - this app
// ships neither store, so only the shared pieces are here: the topmost view controller (which
// FocusOverlay.swift also uses) and the dialog itself.
#if os(iOS)
import SwiftUI
import UIKit

// MARK: - The topmost view controller

/// Where a UIKit presentation from SwiftUI lands: the key window's root, then down through whatever it
/// is presenting (a sheet, a share sheet, another alert), so the new controller sits on top of what
/// the user is looking at instead of failing underneath it.
@MainActor
func topmostViewController() -> UIViewController? {
    let scene = UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .first { $0.activationState == .foregroundActive }

    guard let window = scene?.windows.first(where: \.isKeyWindow) ?? scene?.windows.first,
          var top = window.rootViewController else { return nil }

    while let presented = top.presentedViewController { top = presented }
    return top
}

// MARK: - Removing a saved mark always asks first

/// The one question every unbookmark and unfavorite asks before it happens (Abu, 2026-09-07: "if you
/// ever want to unbookmark or unfavorite anything have it be a confirmation dialog"). Presented
/// UIKit-side on the topmost view controller, the `presentSystemShareSheet` route, so a context menu
/// item, a swipe action, a sheet's tile and a grid corner all reach the same dialog without each row
/// carrying its own `.confirmationDialog` state. Adding a mark never asks.
@MainActor
enum RemovalConfirmation {
    static func present(title: String, message: String, confirmTitle: String, onConfirm: @escaping () -> Void) {
        guard let top = topmostViewController() else {
            withAnimation(.easeInOut) { onConfirm() }
            return
        }

        let alert = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: confirmTitle, style: .destructive) { _ in
            Settings.shared.hapticFeedback()
            withAnimation(.easeInOut) { onConfirm() }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        // The app's accent on the sheet's buttons, the way SwiftUI's own confirmation dialogs get it.
        alert.view.tintColor = UIColor(Settings.shared.accentColor.color)
        // iPad requires an anchor or the popover asserts on presentation. iPhone gets none: the sheet
        // slides up from the bottom with its Cancel button, whereas an anchor made iOS 26 float it
        // mid-screen as a popover (verified on the iPhone 17 Pro simulator).
        if UIDevice.current.userInterfaceIdiom != .phone, let popover = alert.popoverPresentationController {
            popover.sourceView = top.view
            popover.sourceRect = CGRect(x: top.view.bounds.midX, y: top.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        top.present(alert, animated: true)
    }
}
#endif
