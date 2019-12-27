//
//  ExploreMaze.swift
//  SynacorVM
//
//  Created by peter bohac on 12/26/19.
//  Copyright © 2019 peter bohac. All rights reserved.
//

import Foundation

func exploreMaze(from savedStateFile: String) {
    var inputBuffer: [Character] = []
    var outputBuffer = ""
    let vm = SynacorVM(program: [], input: { return inputBuffer.popLast() }) { value in
        outputBuffer.append(value)
        return true
    }
    @discardableResult func executeCommand(_ command: String, from state: SynacorVM.State) -> Room {
        inputBuffer = "\(command)\n".map(Character.init).reversed()
        outputBuffer = ""
        vm.state = state
        vm.run()
        return Room(outputBuffer)
    }
    let fileUrl = pwd.appendingPathComponent(savedStateFile)
    guard let data = try? Data(contentsOf: fileUrl), let start = try? decoder.decode(SynacorVM.State.self, from: data) else {
        print("Failed to load initial state")
        exit(0)
    }

    var queue: [(commands: [String], state: SynacorVM.State)] = [(["look"], start)]

    while queue.isEmpty == false {
        let (commands, state) = queue.removeFirst()
        let room = executeCommand(commands.last!, from: state)
        if room.items.isEmpty == false {
            print("*** Found a room with an uncollected item:")
            print(room.description.joined(separator: "\n"))
            print("Directions:", commands.dropFirst().joined(separator: ", "))
            return
        } else {
            if room.name == "== Twisty passages ==" {
                if room.exits.contains("ladder") {
                    if room.exits.count != 5 {
                        print("*** Found a 'Twisty passages' room with a ladder:")
                        print(room.description.joined(separator: "\n"))
                        print("Directions:", commands.dropFirst().joined(separator: ", "))
                        return
                    }
                    if commands.count == 1 {
                        for exit in room.exits.filter({ $0 != "ladder" }) {
                            queue.append((commands + [exit], vm.state))
                        }
                    }
                } else {
                    for exit in room.exits {
                        queue.append((commands + [exit], vm.state))
                    }
                }
            } else {
                if room.name != "== Fumbling around in the darkness ==" {
                    print("*** Found an interesting 'leaf' room:")
                    print(room.description.joined(separator: "\n"))
                    print("Directions:", commands.dropFirst().joined(separator: ", "))
                    return
                }
            }
        }
    }

    preconditionFailure()
}
