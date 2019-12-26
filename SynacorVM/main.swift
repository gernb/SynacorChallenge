//
//  main.swift
//  SynacorVM
//
//  Created by peter bohac on 12/25/19.
//  Copyright © 2019 peter bohac. All rights reserved.
//

import Foundation

var program: [Int]!
var saveFileUrl: URL? = nil

struct SavedState: Codable {
    var name: String
    var state: SynacorVM.State
}

var savedStates: [SavedState?] = Array(repeating: nil, count: 5)

func loadProgram(file: String) -> [Int] {
    let pwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    let inputFileUrl = pwd.appendingPathComponent(file)
    let data = try! Data(contentsOf: inputFileUrl)
    var temp: [UInt16] = Array(repeating: 0, count: data.count / 2)
    _ = temp.withUnsafeMutableBytes { data.copyBytes(to: $0) }
    return temp.map { Int($0) }
}

if CommandLine.arguments.count == 3 && CommandLine.arguments[1] == "--raw" {
    let raw = CommandLine.arguments[2]
    program = raw.components(separatedBy: ",").map { Int($0.trimmingCharacters(in: .whitespaces))! }
} else if CommandLine.arguments.count == 3 {
    program = loadProgram(file: CommandLine.arguments[1])
    let pwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    saveFileUrl = pwd.appendingPathComponent(CommandLine.arguments[2])
    let decoder = PropertyListDecoder()
    if let data = try? Data(contentsOf: saveFileUrl!), let saved = try? decoder.decode([SavedState?].self, from: data) {
        savedStates = saved
    }
} else if CommandLine.arguments.count == 2 {
    program = loadProgram(file: CommandLine.arguments[1])
} else {
    print("Usage: <binary file> [<save file>] | --raw <comma separated integers>")
    exit(0)
}

var inputBuffer: [Character] = []
var outputBuffer: String = ""
var currentRoom: String = ""

let vm = SynacorVM(program: program, input: { return inputBuffer.popLast() }) { value in
    outputBuffer.append(value)
    if value == "\n" {
        print(outputBuffer, terminator: "")
        if outputBuffer.hasPrefix("==") && outputBuffer.hasSuffix("==\n") {
            currentRoom = String(outputBuffer.dropFirst(3).dropLast(4))
        }
        outputBuffer = ""
    }
    return true
}

var encoder = PropertyListEncoder()

func save(state: SynacorVM.State, name: String) {
    for idx in (1 ..< savedStates.count).reversed() {
        savedStates[idx] = savedStates[idx - 1]
    }
    savedStates[0] = SavedState(name: name, state: state)
    if let saveFileUrl = saveFileUrl {
        let data = try! encoder.encode(savedStates)
        try! data.write(to: saveFileUrl)
    }
}

func restore(index: Int) {
    guard let state = savedStates[index]?.state else {
        preconditionFailure()
    }
    vm.state = state
    inputBuffer = "look\n".map(Character.init).reversed()
}

enum Input: Equatable {
    case quit
    case restore(Int)
    case other(String)
}

func getInput(prompt: String? = nil) -> Input {
    if let prompt = prompt {
        print(prompt)
    }
    let line = readLine() ?? ""
    if line == "quit" {
        return .quit
    }
    if line.hasPrefix("restore") {
        let idx = Int(line.components(separatedBy: " ").last!)
        if let idx = idx, idx >= 0, idx < savedStates.count, savedStates[idx] != nil {
            return .restore(idx)
        }
        savedStates.enumerated().forEach { idx, state in
            if let state = state {
                print("\(idx) - \(state.name)")
            }
        }
        return getInput(prompt: prompt)
    }
    return .other(line)
}

if savedStates[0] != nil {
    restore(index: 0)
}

while true {
    let status = vm.run()
    switch status {
    case .halted:
        print("\nGame Over\n")
        var needsResponse = true
        repeat {
            let input = getInput(prompt: "Quit or Restore?")
            if input == .quit {
                exit(0)
            } else if case .restore(let idx) = input {
                needsResponse = false
                restore(index: idx)
            }
        } while needsResponse

    case .inputNeeded:
        let input = getInput()
        if input == .quit {
            save(state: vm.state, name: currentRoom)
            exit(0)
        } else if case .restore(let idx) = input {
            restore(index: idx)
        } else if case .other(let line) = input {
            if !(line == "help" || line == "inv" || line.hasPrefix("look")) {
                save(state: vm.state, name: currentRoom)
            }
            inputBuffer = (line + "\n").map(Character.init).reversed()
        } else {
            preconditionFailure()
        }

    case .stopRequested, .invalidInstruction:
        preconditionFailure()
    }
}
