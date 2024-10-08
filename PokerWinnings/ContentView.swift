import SwiftUI

struct Player: Identifiable {
    let id = UUID()
    var initialBuyIn: Int
    var finalScore: Int
}

struct SplitwiseEntry: Identifiable {
    let id = UUID()
    let payer: Int
    let payee: Int
    let amount: Double
}

struct ContentView: View {
    @State private var chipToDollarRate = ""
    @State private var players: [Player] = [Player(initialBuyIn: 0, finalScore: 0)]
    @State private var results: [Double] = []
    @State private var splitwiseEntries: [SplitwiseEntry] = []
    
    var body: some View {
        NavigationView {
            VStack {
                Form {
                    Section(header: Text("Game Settings")) {
                        TextField("Chips per $1", text: $chipToDollarRate)
                            .keyboardType(.decimalPad)
                    }
                    
                    Section(header: Text("Players")) {
                        ForEach($players) { $player in
                            VStack(alignment: .leading) {
                                TextField("Initial Buy-In (chips)", value: $player.initialBuyIn, format: .number)
                                    .keyboardType(.numberPad)
                                TextField("Final Score (chips)", value: $player.finalScore, format: .number)
                                    .keyboardType(.numberPad)
                            }
                            .padding(.bottom)
                        }
                        
                        Button("Add Player") {
                            players.append(Player(initialBuyIn: 0, finalScore: 0))
                        }
                    }
                    
                    Section {
                        Button("Calculate Winnings") {
                            calculateWinnings()
                            calculateSplitwiseEntries()
                        }
                    }
                    
                    if !results.isEmpty {
                        Section(header: Text("Results")) {
                            ForEach(results.indices, id: \.self) { index in
                                Text("Player \(index + 1): $\(String(format: "%.2f", results[index]))")
                            }
                        }
                    }
                    
                    if !splitwiseEntries.isEmpty {
                        Section(header: Text("Splitwise Entries")) {
                            ForEach(splitwiseEntries) { entry in
                                Text("Player \(entry.payer + 1) pays Player \(entry.payee + 1): $\(String(format: "%.2f", entry.amount))")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Poker Wins Calculator")
        }
    }
    
    func calculateWinnings() {
        guard let chipRate = Double(chipToDollarRate), chipRate > 0 else {
            return
        }
        
        let totalBuyIn = players.reduce(0) { $0 + $1.initialBuyIn }
        let totalMoney = Double(totalBuyIn) / chipRate
        
        var finalMoneyPerPlayer: [Double] = []
        
        for player in players {
            let finalChips = player.finalScore
            finalMoneyPerPlayer.append(Double(finalChips) / chipRate)
        }
        
        let winnings = finalMoneyPerPlayer.map { max($0 - totalMoney / Double(players.count), 0) }
        results = winnings
    }
    
    func calculateSplitwiseEntries() {
        splitwiseEntries = []
        let adjustedResults = results.map { $0 - (results.reduce(0, +) / Double(players.count)) }
        
        var debts = adjustedResults.enumerated().filter { $0.element < 0 }.sorted { $0.element < $1.element }
        var credits = adjustedResults.enumerated().filter { $0.element > 0 }.sorted { $0.element > $1.element }
        
        while !debts.isEmpty && !credits.isEmpty {
            let debtIndex = debts[0].offset
            let creditIndex = credits[0].offset
            let debtAmount = abs(debts[0].element)
            let creditAmount = credits[0].element
            
            let amountToSettle = min(debtAmount, creditAmount)
            splitwiseEntries.append(SplitwiseEntry(payer: debtIndex, payee: creditIndex, amount: amountToSettle))
            
            debts[0].element += amountToSettle
            credits[0].element -= amountToSettle
            
            if debts[0].element == 0 {
                debts.remove(at: 0)
            }
            
            if credits[0].element == 0 {
                credits.remove(at: 0)
            }
        }
    }
}
