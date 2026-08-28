// Copyright 2026 Phinomenon Inc.
//
// Use of this source code is governed by an Apache license that can be
// found in the LICENSE file.

import Foundation
import AppKit

/// Presents the system share picker (`NSSharingServicePicker`) for a tab's
/// page URL. Single owner for every share entry point — the File menu item,
/// the address bar button, and the keyboard shortcut all route through here.
@MainActor
final class PageSharingPresenter: NSObject {
    /// AppKit does not retain the picker while it is on screen; dropping the
    /// reference before the user chooses a service dismisses the menu. The
    /// active presenter therefore holds itself here until the picker reports
    /// a choice (or dismissal) through its delegate.
    private static var activePresenter: PageSharingPresenter?

    private let picker: NSSharingServicePicker

    private init(items: [Any]) {
        picker = NSSharingServicePicker(items: items)
        super.init()
        picker.delegate = self
    }

    /// The URL a tab shares: Reader pages resolve to their source page, and
    /// the result carries the same branding as Copy URL.
    static func shareableURL(for tab: Tab?) -> URL? {
        guard var urlString = tab?.url, !urlString.isEmpty else { return nil }
        urlString = ReaderExtensionBridge.sourceURLString(fromReaderPageURL: urlString) ?? urlString
        return URL(string: URLProcessor.phiBrandEnsuredUrlString(urlString))
    }

    static func canShare(tab: Tab?) -> Bool {
        shareableURL(for: tab) != nil
    }

    static func share(url: URL, anchorView: NSView) {
        let presenter = PageSharingPresenter(items: [url])
        activePresenter = presenter
        presenter.picker.show(relativeTo: .zero, of: anchorView, preferredEdge: .minY)
    }
}

extension PageSharingPresenter: NSSharingServicePickerDelegate {
    nonisolated func sharingServicePicker(
        _ sharingServicePicker: NSSharingServicePicker,
        didChoose service: NSSharingService?
    ) {
        // `service` is nil when the picker is dismissed without a choice;
        // either way the picker is off screen and can be released.
        MainActor.assumeIsolated {
            PageSharingPresenter.activePresenter = nil
        }
    }
}
