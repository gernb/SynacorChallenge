//
//  main.swift
//  SynacorVM
//
//  Created by peter bohac on 12/25/19.
//  Copyright © 2019 peter bohac. All rights reserved.
//

import Foundation

var programFilename: String?
var checkpointsFilename: String?
var savedStateFilename: String?
var isExploringMaze = false
var isSolvingCoins = false
var disassemble = false
var isSolvingTeleporterCode = false
var isExploringVault = false
var unusedArgs: [String] = []
var arguments = CommandLine.arguments.dropFirst()
while arguments.isEmpty == false {
    let arg = arguments.removeFirst()
    if (arg == "--program" || arg == "-p") && arguments.count > 0 {
        programFilename = arguments.removeFirst()
    } else if (arg == "--checkpoints" || arg == "-c") && arguments.count > 0 {
        checkpointsFilename = arguments.removeFirst()
    } else if (arg == "--load" || arg == "-l") && arguments.count > 0 {
        savedStateFilename = arguments.removeFirst()
    } else if arg == "--exploreMaze" {
        isExploringMaze = true
    } else if arg == "--solveCoins" {
        isSolvingCoins = true
    } else if arg == "--disassemble" {
        disassemble = true
    } else if arg == "--solveTeleporter" {
        isSolvingTeleporterCode = true
    } else if arg == "--exploreVault" {
        isExploringVault = true
    } else {
        if programFilename == nil {
            programFilename = arg
        } else if checkpointsFilename == nil {
            checkpointsFilename = arg
        } else if savedStateFilename == nil {
            savedStateFilename = arg
        } else {
            unusedArgs.append(arg)
        }
    }
}

guard unusedArgs.isEmpty, let programFilename = programFilename else {
    print("Usage: [--program] <program filename> [[--checkpoints] <checkpoints filename>] [[--load] <saved state filename>]")
    exit(0)
}

let pwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let program: [Int] = {
    let inputFileUrl = pwd.appendingPathComponent(programFilename)
    let data = try! Data(contentsOf: inputFileUrl)
    var temp: [UInt16] = Array(repeating: 0, count: data.count / 2)
    _ = temp.withUnsafeMutableBytes { data.copyBytes(to: $0) }
    return temp.map { Int($0) }
}()

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

struct Checkpoint: Codable {
    var name: String
    var state: SynacorVM.State
}

let decoder = PropertyListDecoder()
var encoder = PropertyListEncoder()
var checkpointsFileUrl: URL? = nil
var checkpoints: [Checkpoint?] = Array(repeating: nil, count: 5)

func saveCheckpoint(state: SynacorVM.State, name: String) {
    for idx in (1 ..< checkpoints.count).reversed() {
        checkpoints[idx] = checkpoints[idx - 1]
    }
    checkpoints[0] = Checkpoint(name: name, state: state)
    if let saveFileUrl = checkpointsFileUrl {
        let data = try! encoder.encode(checkpoints)
        try! data.write(to: saveFileUrl)
    }
}

func restoreCheckpoint(index: Int) {
    guard let state = checkpoints[index]?.state else {
        preconditionFailure()
    }
    vm.state = state
    inputBuffer = "look\n".map(Character.init).reversed()
}

func saveGameState(to filename: String) {
    let fileUrl = pwd.appendingPathComponent(filename)
    if let data = try? encoder.encode(vm.state), (try? data.write(to: fileUrl)) != nil {
        print("\nSaved to \(filename)\n")
    }
}

func loadGameState(from filename: String) {
    let fileUrl = pwd.appendingPathComponent(filename)
    if let data = try? Data(contentsOf: fileUrl), let state = try? decoder.decode(SynacorVM.State.self, from: data) {
        vm.state = state
        inputBuffer = "look\n".map(Character.init).reversed()
        print("\nLoaded saved state from \(filename)\n")
    }
}

if let filename = checkpointsFilename {
    checkpointsFileUrl = pwd.appendingPathComponent(filename)
    if let data = try? Data(contentsOf: checkpointsFileUrl!), let savedCheckpoints = try? decoder.decode([Checkpoint?].self, from: data) {
        checkpoints = savedCheckpoints
    }
}

if let filename = savedStateFilename {
    loadGameState(from: filename)
} else if checkpoints[0] != nil {
    restoreCheckpoint(index: 0)
}

if isExploringMaze {
    exploreMaze(from: savedStateFilename!)
    exit(0)
}

if isSolvingCoins {
    solveCoins(from: savedStateFilename!)
    exit(0)
}

if disassemble {
    let disassembler = Disassembler(state: vm.state)
    disassembler.disassemble()
    exit(0)
}

if isSolvingTeleporterCode {
    findTeleporterCode()
    exit(0)
}

if isExploringVault {
    exploreVault(from: savedStateFilename!)
    exit(0)
}

var originalTeleportInstructions: [Int] = []

enum Input: Equatable {
    case quit
    case restore(Int)
    case save(String)
    case load(String)
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
        if let idx = idx, idx >= 0, idx < checkpoints.count, checkpoints[idx] != nil {
            return .restore(idx)
        }
        checkpoints.enumerated().forEach { idx, state in
            if let state = state {
                print("\(idx) - \(state.name)")
            }
        }
        return getInput(prompt: prompt)
    }
    if line.hasPrefix("save") {
        let file = String(line.dropFirst(5))
        if file.isEmpty {
            print("Usage: save <filename>")
            return getInput(prompt: prompt)
        }
        return .save(file)
    }
    if line.hasPrefix("load") {
        let file = String(line.dropFirst(5))
        if file.isEmpty {
            print("Usage: load <filename>")
            return getInput(prompt: prompt)
        }
        return .load(file)
    }
    if line == "patch teleporter" {
        if originalTeleportInstructions.isEmpty {
            originalTeleportInstructions = Array(vm.memory[6027 ... 6030])
            vm.setRegister(8, to: 25734)    // set register 8 to non-zero
            vm.memory[6027] = 1             // set register 1 to 6 and return
            vm.memory[6028] = 32768
            vm.memory[6029] = 6
            vm.memory[6030] = 18
            print("Patch in place")
        } else {
            print("Teleporter is already patched!")
        }
        return getInput(prompt: prompt)
    }
    if line == "unpatch teleporter" {
        if originalTeleportInstructions.isEmpty {
            print("Teleporter is not currently patched!")
        } else {
            vm.memory[6027] = originalTeleportInstructions[0]
            vm.memory[6028] = originalTeleportInstructions[1]
            vm.memory[6029] = originalTeleportInstructions[2]
            vm.memory[6030] = originalTeleportInstructions[3]
            originalTeleportInstructions = []
            print("Patch removed")
        }
        return getInput(prompt: prompt)
    }
    return .other(line)
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
                restoreCheckpoint(index: idx)
            }
        } while needsResponse

    case .inputNeeded:
        let input = getInput()
        if input == .quit {
            saveCheckpoint(state: vm.state, name: currentRoom)
            exit(0)
        } else if case .restore(let idx) = input {
            restoreCheckpoint(index: idx)
        } else if case .save(let filename) = input {
            saveGameState(to: filename)
        } else if case .load(let filename) = input {
            loadGameState(from: filename)
        } else if case .other(let line) = input {
            if !(line == "help" || line == "inv" || line.hasPrefix("look")) {
                saveCheckpoint(state: vm.state, name: currentRoom)
            }
            inputBuffer = (line + "\n").map(Character.init).reversed()
        } else {
            preconditionFailure()
        }

    case .stopRequested, .invalidInstruction, .timeExpired:
        preconditionFailure()
    }
}
