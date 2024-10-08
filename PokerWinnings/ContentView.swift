import SwiftUI

struct Player: Identifiable {
    let id = UUID()
    var name: String
    var initialBuyIn: Int
    var finalScore: Int
}

struct SplitwiseEntry: Identifiable {
    let id = UUID()
    var payer: String
    var amountPaid: Double
    var amountOwed: Double
}

struct ContentView: View {
    @AppStorage("chipToDollarRate") private var chipToDollarRate: Double = 400.0 // Dollar value per chip
    @AppStorage("initialBuyIn") private var initialBuyIn: Int = 2000 // Initial buy-in amount

    @State private var players: [Player] = [Player(name: "Player 1", initialBuyIn: 2000, finalScore: 0)]
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
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Name:")
                                    .font(.headline)
                                TextField("Player Name", text: $player.name)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }

                            HStack {
                                Text("Initial Buy-In:")
                                    .font(.headline)
                                TextField("Initial Buy-In", value: $player.initialBuyIn, format: .number)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }

                            HStack {
                                Text("Final Score:")
                                    .font(.headline)
                                TextField("Final Score", value: $player.finalScore, format: .number)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                        }
                        .padding(.bottom)
                    }

                    Button("Add Player") {
                        let playerNumber = players.count + 1
                        players.append(Player(name: "Player \(playerNumber)", initialBuyIn: initialBuyIn, finalScore: 0))
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
                                let amountOwed = (entry.payer == firstEntry.payer) ? firstEntry.amountPaid : entry.amountOwed
                                let owedText = amountOwed > 0.0 ? " and owes $\(String(format: "%.2f", amountOwed))" : ""
                                Text("\(entry.payer) paid $\(String(format: "%.2f", entry.amountPaid))\(owedText)")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Poker Wins Calculator")
            .navigationBarItems(trailing: NavigationLink(destination: SettingsView(players: $players)) {
                Text("Settings")
            })
        }
    }

    func calculateSplitwiseEntries() {
        guard let specialPlayer = players.max(by: { $0.finalScore < $1.finalScore }) else { return }
        let totalFirstEntryPaid = players.reduce(0) { $0 + Double($1.initialBuyIn) / chipToDollarRate }
        firstEntry = SplitwiseEntry(payer: specialPlayer.name, amountPaid: totalFirstEntryPaid, amountOwed: 0.0)

        secondEntriesList = players.map { player in
            let amountPaid = Double(player.finalScore) / chipToDollarRate
            let amountOwed = 0.0
            return SplitwiseEntry(payer: player.name, amountPaid: amountPaid, amountOwed: amountOwed)
        }
    }
}

struct SettingsView: View {
    @AppStorage("chipToDollarRate") private var chipToDollarRate: Double = 400.0 // Dollar value per chip
    @AppStorage("initialBuyIn") private var initialBuyIn: Int = 2000 // Initial buy-in amount
    @Binding var players: [Player]

    var body: some View {
        Form {
            Section(header: Text("Game Settings").font(.headline).foregroundColor(.blue)) {
                VStack(alignment: .leading) {
                    Text("Chip to Dollar Rate")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text("This value defines how many chips equal one dollar.")
                    TextField("Chip to Dollar Rate", value: $chipToDollarRate, format: .number)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.top, 5)
                        .onChange(of: chipToDollarRate) { newValue in
                            repopulateInitialBuyIn()
                        }
                }
                .padding(.vertical)

                VStack(alignment: .leading) {
                    Text("Initial Buy-In")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text("This value sets the starting amount each player must buy in for.")
                    TextField("Initial Buy-In", value: $initialBuyIn, format: .number)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.top, 5)
                        .onChange(of: initialBuyIn) { newValue in
                            repopulateInitialBuyIn()
                        }
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("Settings")
    }

    private func repopulateInitialBuyIn() {
        for index in players.indices {
            players[index].initialBuyIn = initialBuyIn
        }
    }
}

