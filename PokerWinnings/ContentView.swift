import SwiftUI

struct Player: Identifiable {
    let id = UUID()
    var name: String
    var initialBuyIn: Int = 2000
    var finalScore: Int
}

struct SplitwiseEntry: Identifiable {
    let id = UUID()
    var payer: String
    var amountPaid: Double
    var amountOwed: Double
}

struct ContentView: View {
    @State private var chipToDollarRate: Double = 400.0 // Dollar value per chip
    @State private var players: [Player] = [Player(name: "Player 1", finalScore: 0)]
    @State private var firstEntry: SplitwiseEntry?
    @State private var secondEntriesList: [SplitwiseEntry] = []
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Chip Value")) {
                    TextField("Chips per $1", value: $chipToDollarRate, format: .number)
                        .keyboardType(.decimalPad)
                }
                
                Section(header: Text("Players")) {
                    ForEach($players) { $player in
                        VStack(alignment: .leading) {
                            TextField("Final Score", value: $player.finalScore, format: .number)
                                .keyboardType(.numberPad)
                            TextField("Name", text: $player.name)
                            TextField("Initial Buy-In", value: $player.initialBuyIn, format: .number)
                                .keyboardType(.numberPad)
                        }
                        .padding(.bottom)
                    }
                    
                    Button("Add Player") {
                        let playerNumber = players.count + 1
                        players.append(Player(name: "Player \(playerNumber)", finalScore: 0))
                    }
                }
                
                Section {
                    Button("Calculate Splitwise Entries") {
                        calculateSplitwiseEntries()
                    }
                }
                
                if let firstEntry = firstEntry {
                    Section(header: Text("First Splitwise Entry")) {
                        Text("\(firstEntry.payer) paid: $\(String(format: "%.2f", firstEntry.amountPaid))")
                        ForEach(players) { player in
                            Text("\(player.name): owes $\(String(format: "%.2f", Double(player.initialBuyIn) / chipToDollarRate))")
                        }
                    }
                    
                    if !secondEntriesList.isEmpty {
                        Section(header: Text("Second Splitwise Entry")) {
                            ForEach(secondEntriesList, id: \.payer) { entry in
                                // Determine the amount owed for each player
                                let amountOwed = (entry.payer == firstEntry.payer) ? firstEntry.amountPaid : entry.amountOwed;

                                // Construct the text conditionally
                                let owedText = amountOwed > 0.0 ? " and owes $\(String(format: "%.2f", amountOwed))" : ""
                                
                                Text("\(entry.payer) paid $\(String(format: "%.2f", entry.amountPaid))\(owedText)")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Poker Wins Calculator")
        }
    }
    
    func calculateSplitwiseEntries() {
        // Find the player with the highest final score
        guard let specialPlayer = players.max(by: { $0.finalScore < $1.finalScore }) else { return }
        
        // Calculate the first entry
        let totalFirstEntryPaid = players.reduce(0) { $0 + Double($1.initialBuyIn) / chipToDollarRate }
        firstEntry = SplitwiseEntry(payer: specialPlayer.name, amountPaid: totalFirstEntryPaid, amountOwed: 0.0)

        // Calculate the second entries
        secondEntriesList = players.map { player in
            let amountPaid = Double(player.finalScore) / chipToDollarRate
            let amountOwed = 0.0
            return SplitwiseEntry(payer: player.name, amountPaid: amountPaid, amountOwed: amountOwed)
        }
    }
}

