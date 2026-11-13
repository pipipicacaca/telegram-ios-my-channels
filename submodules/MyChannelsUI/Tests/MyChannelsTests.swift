import XCTest
import TelegramCore
@testable import MyChannelsUI

final class MyChannelsTests: XCTestCase {
    private func id(_ value: Int64) -> EnginePeer.Id {
        return EnginePeer.Id(namespace: Namespaces.Peer.CloudChannel, id: EnginePeer.Id.Id._internalFromInt64Value(value))
    }

    func testSortedLargestFirstUnknownLast() {
        let items: [(String, Int?)] = [("a", 689), ("b", nil), ("c", 12_480), ("d", 2_034), ("e", nil)]
        XCTAssertEqual(myChannelsSorted(items, count: { $0.1 }).map(\.0), ["c", "d", "a", "b", "e"])
    }

    func testUniqueKeepsFirstSeen() {
        let items: [(EnginePeer.Id, String)] = [(self.id(1), "public"), (self.id(2), "private"), (self.id(1), "story")]
        XCTAssertEqual(myChannelsUnique(items, id: { $0.0 }).map(\.1), ["public", "private"])
    }

    func testCompactCount() {
        XCTAssertEqual(myChannelsCompactCount(689), "689")
        XCTAssertEqual(myChannelsCompactCount(21_418), "21.4K")
        XCTAssertEqual(myChannelsCompactCount(8_000), "8K")
        XCTAssertEqual(myChannelsCompactCount(1_250_000), "1.2M")
    }

    func testGroupedCount() {
        XCTAssertEqual(myChannelsGroupedCount(12_480, separator: ","), "12,480")
        XCTAssertEqual(myChannelsGroupedCount(402, separator: ","), "402")
        XCTAssertEqual(myChannelsGroupedCount(1_000_000, separator: ","), "1,000,000")
    }

    func testSummaries() {
        let en = MyChannelsStrings(languageCode: "en")
        XCTAssertEqual(en.channelsSummary(count: 4, subscribers: 21_418), "4 channels · 21.4K subscribers")
        XCTAssertEqual(en.botsSummary(count: 1, users: 8_633), "1 bot · 8.6K monthly users")
        XCTAssertEqual(en.subscribers(1), "1 subscriber")

        let ru = MyChannelsStrings(languageCode: "ru")
        XCTAssertEqual(ru.channelsSummary(count: 4, subscribers: 21_418), "4 канала · 21.4K подписчиков")
        XCTAssertEqual(ru.subscribers(21), "21 подписчик")
        XCTAssertEqual(ru.subscribers(12), "12 подписчиков")
    }

    func testRussianPlural() {
        XCTAssertEqual(myChannelsRussianPlural(1, one: "o", few: "f", many: "m"), "o")
        XCTAssertEqual(myChannelsRussianPlural(3, one: "o", few: "f", many: "m"), "f")
        XCTAssertEqual(myChannelsRussianPlural(11, one: "o", few: "f", many: "m"), "m")
        XCTAssertEqual(myChannelsRussianPlural(22, one: "o", few: "f", many: "m"), "f")
        XCTAssertEqual(myChannelsRussianPlural(111, one: "o", few: "f", many: "m"), "m")
    }
}
