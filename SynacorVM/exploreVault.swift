//
//  exploreVault.swift
//  SynacorVM
//
//  Created by peter bohac on 12/27/19.
//  Copyright © 2019 peter bohac. All rights reserved.
//

import Foundation

func exploreVault(from savedStateFile: String) {
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
        if room.name == "== Tropical Cave ==" {
            continue
        } else if room.name == "== Vault Antechamber ==" {
            guard commands.count == 1 else { continue }
            for exit in room.exits {
                queue.append((commands + [exit], vm.state))
            }
        } else if room.name == "== Vault Lock ==" {
            for exit in room.exits {
                queue.append((commands + [exit], vm.state))
            }
        } else {
            let vault = executeCommand("vault", from: vm.state)
            if vault.description.count > 3 {
                print(commands.joined(separator: "\n"))
                return
            }
        }
    }

    preconditionFailure()
}
