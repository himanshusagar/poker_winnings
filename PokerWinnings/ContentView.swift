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
    
    @State private var players: [Player] = []
    @State private var firstEntry: SplitwiseEntry?
    @State private var secondEntriesList: [SplitwiseEntry] = []
    
    @State private var isValidationSuccess: Bool = true
    @State private var validationMessage: String = ""

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
                        players.append(Player(name: "Player \(players.count + 1)", initialBuyIn: initialBuyIn, finalScore: 0))
                    }

                    Button("Remove Last Player") {
                        if !players.isEmpty {
                            players.removeLast()
                        }
                    }
                }

                Section {
                    Button("Calculate Splitwise Entries") {
                        calculateSplitwiseEntries()
                    }
                    .alert(isPresented: Binding<Bool>(
                        get: { !isValidationSuccess },
                        set: { if !$0 { isValidationSuccess = true } }
                    )) {
                        Alert(
                            title: Text("Validation Error"),
                            message: Text(validationMessage),
                            dismissButton: .default(Text("OK"))
                        )
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
            .onAppear {
                loadSavedPlayers()
            }
        }
    }

    func loadSavedPlayers() {
        if let savedPlayers = UserDefaults.standard.stringArray(forKey: "savedPlayerNames") {
            players = savedPlayers.map { Player(name: $0, initialBuyIn: initialBuyIn, finalScore: 0) }
        }
    }

    func calculateSplitwiseEntries() {
        let totalInitialBuyIn = players.reduce(0) { $0 + $1.initialBuyIn }
        let totalFinalScore = players.reduce(0) { $0 + $1.finalScore }

        if totalInitialBuyIn != totalFinalScore {
            isValidationSuccess = false
            validationMessage = "Total Initial Buy-In (\(totalInitialBuyIn)) must equal Total Final Score (\(totalFinalScore))."
            firstEntry = nil
            secondEntriesList = []
            return
        } else {
            isValidationSuccess = true
            validationMessage = ""
        }

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
    
    @State private var savedPlayerNames: [String] = []
    @State private var newPlayerName: String = ""

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
                }
                .padding(.vertical)

                Section(header: Text("Saved Players")) {
                    List {
                        ForEach(savedPlayerNames.sorted(), id: \.self) { name in
                            HStack {
                                Text(name)
                                Spacer()
                                Button(action: {
                                    removePlayer(name: name)
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .onDelete(perform: removePlayers)
                    }
                    
                    HStack {
                        TextField("New Player Name", text: $newPlayerName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        Button("Add") {
                            if !newPlayerName.isEmpty {
                                addSavedPlayer()
                            }
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                }
            }
        }
        .navigationTitle("Settings")
        .onAppear {
            loadSavedPlayers()
        }
    }

    private func loadSavedPlayers() {
        if let savedPlayers = UserDefaults.standard.stringArray(forKey: "savedPlayerNames") {
            savedPlayerNames = savedPlayers
        }
    }

    private func saveSavedPlayers() {
        UserDefaults.standard.set(savedPlayerNames, forKey: "savedPlayerNames")
    }

    private func addSavedPlayer() {
        savedPlayerNames.append(newPlayerName)
        saveSavedPlayers()
        newPlayerName = ""
    }

    private func removePlayer(name: String) {
        savedPlayerNames.removeAll { $0 == name }
        saveSavedPlayers()
    }

    private func removePlayers(at offsets: IndexSet) {
        savedPlayerNames.remove(atOffsets: offsets)
        saveSavedPlayers()
    }
}
