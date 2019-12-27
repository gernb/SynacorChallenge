//
//  Room.swift
//  SynacorVM
//
//  Created by peter bohac on 12/26/19.
//  Copyright © 2019 peter bohac. All rights reserved.
//

struct Room: Hashable {
    let description: [String]
    let exits: [String]
    let items: [String]

    var name: String { description[0] }

    init(_ description: String) {
        self.description = description.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: "\n")

        var isParsingExits = false
        var isParsingItems = false
        var exits: [String] = []
        var items: [String] = []

        for line in self.description {
            if line.hasPrefix("There are ") && line.hasSuffix(" exits:") { isParsingExits = true }
            else if line == "Things of interest here:" { isParsingItems = true }
            else if isParsingExits {
                if line.isEmpty { isParsingExits = false }
                else {
                    exits.append(String(line.dropFirst(2)))
                }
            }
            else if isParsingItems {
                if line.isEmpty { isParsingItems = false }
                else {
                    items.append(String(line.dropFirst(2)))
                }
            }
//            else if line.hasPrefix("You take the ") {
//                let item = String(line.dropFirst("You take the ".count).dropLast())
//                items.removeFirst(item)
//            }
        }

        self.exits = exits
        self.items = items
    }
}
