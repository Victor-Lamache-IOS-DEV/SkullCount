import XCTest
@testable import SkullCount

final class ScoringEngineTests: XCTestCase {
    
    // MARK: - Required Test Suite Cases
    
    /// pari 3, plis 3 -> +60
    func testSuccessfulBid3() {
        let result = ScoringEngine.calculateScore(bid: 3, tricks: 3, cardsDealt: 5)
        XCTAssertEqual(result.points, 60)
        XCTAssertTrue(result.isSuccess)
    }
    
    /// pari 2, plis 4 -> -20
    func testFailedBid2Tricks4() {
        let result = ScoringEngine.calculateScore(bid: 2, tricks: 4, cardsDealt: 5)
        XCTAssertEqual(result.points, -20)
        XCTAssertFalse(result.isSuccess)
    }
    
    /// pari 1, plis 0 -> -10
    func testFailedBid1Tricks0() {
        let result = ScoringEngine.calculateScore(bid: 1, tricks: 0, cardsDealt: 3)
        XCTAssertEqual(result.points, -10)
        XCTAssertFalse(result.isSuccess)
    }
    
    /// pari 0, plis 0, 7 cartes -> +70
    func testSuccessfulZeroBid7Cards() {
        let result = ScoringEngine.calculateScore(bid: 0, tricks: 0, cardsDealt: 7)
        XCTAssertEqual(result.points, 70)
        XCTAssertTrue(result.isSuccess)
    }
    
    /// pari 0, plis 2, 9 cartes -> -90
    func testFailedZeroBid9Cards() {
        let result = ScoringEngine.calculateScore(bid: 0, tricks: 2, cardsDealt: 9)
        XCTAssertEqual(result.points, -90)
        XCTAssertFalse(result.isSuccess)
    }
    
    /// pari 2, plis 2, Sirène capture SK -> +90 (+40 + 50)
    func testSuccessfulBid2MermaidCapturesSK() {
        let result = ScoringEngine.calculateScore(
            bid: 2,
            tricks: 2,
            cardsDealt: 5,
            bonusEnabled: true,
            skCapturedByMermaid: true
        )
        XCTAssertEqual(result.points, 90)
        XCTAssertEqual(result.bonusPoints, 50)
        XCTAssertTrue(result.isSuccess)
    }
    
    /// pari 2, plis 1, Sirène capture SK -> -10 (bonus perdu)
    func testFailedBid2MermaidBonusLost() {
        let result = ScoringEngine.calculateScore(
            bid: 2,
            tricks: 1,
            cardsDealt: 5,
            bonusEnabled: true,
            skCapturedByMermaid: true
        )
        XCTAssertEqual(result.points, -10)
        XCTAssertEqual(result.bonusPoints, 0)
        XCTAssertFalse(result.isSuccess)
    }
    
    /// pari 1, plis 1, SK capture 2 Pirates -> +80 (+20 + 2 * 30)
    func testSuccessfulBid1SKCaptures2Pirates() {
        let result = ScoringEngine.calculateScore(
            bid: 1,
            tricks: 1,
            cardsDealt: 4,
            bonusEnabled: true,
            piratesCapturedBySK: 2
        )
        XCTAssertEqual(result.points, 80)
        XCTAssertEqual(result.bonusPoints, 60)
        XCTAssertTrue(result.isSuccess)
    }
    
    /// 8 joueurs, 66 cartes, mode réduit -> 8 manches
    func testEightPlayersReducedModeRoundsCount() {
        let rounds = ScoringEngine.plannedRoundsCount(
            playerCount: 8,
            roundMode: .reducedRounds,
            deckSize: 66
        )
        XCTAssertEqual(rounds, 8)
    }
    
    /// 8 joueurs, mode plafonné -> manches 9 et 10 à 8 cartes
    func testEightPlayersCappedModeCardsDealt() {
        let rounds = ScoringEngine.plannedRoundsCount(
            playerCount: 8,
            roundMode: .cappedTenRounds,
            deckSize: 66
        )
        XCTAssertEqual(rounds, 10)
        
        let cardsM9 = ScoringEngine.cardsDealt(forRound: 9, playerCount: 8, roundMode: .cappedTenRounds, deckSize: 66)
        let cardsM10 = ScoringEngine.cardsDealt(forRound: 10, playerCount: 8, roundMode: .cappedTenRounds, deckSize: 66)
        
        XCTAssertEqual(cardsM9, 8)
        XCTAssertEqual(cardsM10, 8)
    }
    
    // MARK: - Starting Player Rotation Tests
    
    func testFirstPlayerRotation() {
        XCTAssertEqual(ScoringEngine.firstPlayerSeatIndex(roundNumber: 1, startingPlayerSeatIndex: 2, playerCount: 4), 2)
        XCTAssertEqual(ScoringEngine.firstPlayerSeatIndex(roundNumber: 2, startingPlayerSeatIndex: 2, playerCount: 4), 3)
        XCTAssertEqual(ScoringEngine.firstPlayerSeatIndex(roundNumber: 3, startingPlayerSeatIndex: 2, playerCount: 4), 0)
        XCTAssertEqual(ScoringEngine.firstPlayerSeatIndex(roundNumber: 4, startingPlayerSeatIndex: 2, playerCount: 4), 1)
    }
    
    func testSeatOrder() {
        let order = ScoringEngine.seatOrder(forRound: 3, startingPlayerSeatIndex: 2, playerCount: 4)
        XCTAssertEqual(order, [0, 1, 2, 3])
    }
}
