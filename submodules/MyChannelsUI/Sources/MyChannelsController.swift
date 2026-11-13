import Foundation
import UIKit
import Display
import AsyncDisplayKit
import SwiftSignalKit
import TelegramCore
import TelegramPresentationData
import AccountContext
import AppBundle
import ItemListUI
import ItemListPeerItem
import ItemListPeerActionItem

private final class MyChannelsArguments {
    let context: AccountContext
    let create: (MyChannelsSection) -> Void
    let openPeer: (EnginePeer) -> Void

    init(context: AccountContext, create: @escaping (MyChannelsSection) -> Void, openPeer: @escaping (EnginePeer) -> Void) {
        self.context = context
        self.create = create
        self.openPeer = openPeer
    }
}

private enum MyChannelsEntryId: Hashable {
    case create
    case peer(EnginePeer.Id)
    case footer
}

private enum MyChannelsEntry: ItemListNodeEntry {
    case create(MyChannelsSection, String)
    case peer(Int, MyChannelsItem, String, String?)
    case footer(String)

    var section: ItemListSectionId {
        return 0
    }

    var stableId: MyChannelsEntryId {
        switch self {
        case .create:
            return .create
        case let .peer(_, item, _, _):
            return .peer(item.peer.id)
        case .footer:
            return .footer
        }
    }

    private var sortIndex: Int {
        switch self {
        case .create:
            return -1
        case let .peer(index, _, _, _):
            return index
        case .footer:
            return Int.max
        }
    }

    static func <(lhs: MyChannelsEntry, rhs: MyChannelsEntry) -> Bool {
        return lhs.sortIndex < rhs.sortIndex
    }

    static func ==(lhs: MyChannelsEntry, rhs: MyChannelsEntry) -> Bool {
        switch lhs {
        case let .create(section, title):
            if case .create(section, title) = rhs {
                return true
            }
            return false
        case let .peer(index, item, text, label):
            if case .peer(index, item, text, label) = rhs {
                return true
            }
            return false
        case let .footer(text):
            if case .footer(text) = rhs {
                return true
            }
            return false
        }
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! MyChannelsArguments
        switch self {
        case let .create(section, title):
            let icon = UIImage(bundleImageName: section == .channels ? "Contact List/CreateChannelActionIcon" : "Peer Info/BotSettings")
            return ItemListPeerActionItem(presentationData: presentationData, systemStyle: .glass, icon: icon.flatMap { generateTintedImage(image: $0, color: presentationData.theme.list.itemAccentColor) }, title: title, sectionId: self.section, height: .peerList, color: .accent, editing: false, action: {
                arguments.create(section)
            })
        case let .peer(_, item, text, label):
            let full = arguments.context.sharedContext.currentPresentationData.with { $0 }
            return ItemListPeerItem(presentationData: presentationData, systemStyle: .glass, dateTimeFormat: full.dateTimeFormat, nameDisplayOrder: full.nameDisplayOrder, context: arguments.context, peer: item.peer, presence: nil, text: .text(text, .secondary), label: label.flatMap { .text($0, .standard, nil, false) } ?? .none, editing: ItemListPeerItemEditing(editable: false, editing: false, revealed: false), switchValue: nil, enabled: true, selectable: true, sectionId: self.section, action: {
                arguments.openPeer(item.peer)
            }, setPeerIdWithRevealedOptions: { _, _ in }, removePeer: { _ in })
        case let .footer(text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        }
    }
}

private func myChannelsEntries(section: MyChannelsSection, state: MyChannelsState, strings: MyChannelsStrings) -> [MyChannelsEntry] {
    var entries: [MyChannelsEntry] = []
    switch section {
    case .channels:
        entries.append(.create(.channels, strings.createChannel))
        for (index, item) in state.channels.enumerated() {
            let text = item.count.flatMap { strings.subscribers($0) } ?? ""
            entries.append(.peer(index, item, text, item.isCreator ? strings.owner : strings.admin))
        }
        entries.append(.footer(strings.channelsFooter))
    case .bots:
        entries.append(.create(.bots, strings.createBot))
        for (index, item) in state.bots.enumerated() {
            var parts: [String] = []
            if let username = item.peer.addressName {
                parts.append("@\(username)")
            }
            if let count = item.count {
                parts.append(strings.monthlyUsers(count))
            }
            entries.append(.peer(index, item, parts.joined(separator: " · "), nil))
        }
        entries.append(.footer(strings.botsFooter))
    }
    return entries
}

/// «My Channels» / «My Bots»: one screen, two tabs in the title (`.textWithTabs`, as in channel statistics).
/// `createChannel` reuses New Channel from the compose screen; `createBot` opens @BotFather.
public func myChannelsController(context: AccountContext, initialSection: MyChannelsSection, openPeer: @escaping (EnginePeer) -> Void, createChannel: @escaping () -> Void) -> ViewController {
    let sectionPromise = ValuePromise<MyChannelsSection>(initialSection, ignoreRepeated: true)
    let actionsDisposable = DisposableSet()

    let arguments = MyChannelsArguments(context: context, create: { section in
        switch section {
        case .channels:
            createChannel()
        case .bots:
            actionsDisposable.add((context.engine.peers.resolvePeerByName(name: "BotFather", referrer: nil)
            |> deliverOnMainQueue).start(next: { result in
                if case let .result(peer) = result, let peer {
                    openPeer(peer)
                }
            }))
        }
    }, openPeer: openPeer)

    let signal = combineLatest(queue: .mainQueue(),
        context.sharedContext.presentationData,
        sectionPromise.get(),
        myChannelsState(context: context)
    )
    |> map { presentationData, section, state -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let strings = MyChannelsStrings(languageCode: presentationData.strings.baseLanguageCode)
        let title = section == .channels ? strings.myChannels : strings.myBots
        let controllerState = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .textWithTabs(title, ["\(strings.channelsTab) \(state.channels.count)", "\(strings.botsTab) \(state.bots.count)"], section.rawValue), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back), animateChanges: false)
        let listState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: state.isLoaded ? myChannelsEntries(section: section, state: state, strings: strings) : [], style: .blocks, crossfadeState: true, animateChanges: false)
        return (controllerState, (listState, arguments))
    }
    |> afterDisposed {
        actionsDisposable.dispose()
    }

    let controller = ItemListController(context: context, state: signal)
    controller.titleControlValueChanged = { index in
        sectionPromise.set(MyChannelsSection(rawValue: index) ?? .channels)
    }
    return controller
}
