//
//  main.swift
//  SynacorVM
//
//  Created by peter bohac on 12/25/19.
//  Copyright © 2019 peter bohac. All rights reserved.
//

import Foundation

var program: [Int]!

if CommandLine.arguments.count == 3 && CommandLine.arguments[1] == "--raw" {
    let raw = CommandLine.arguments[2]
    program = raw.components(separatedBy: ",").map { Int($0.trimmingCharacters(in: .whitespaces))! }
} else if CommandLine.arguments.count == 2 {
    let filename = CommandLine.arguments[1]
    let pwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    let inputFileUrl = pwd.appendingPathComponent(filename)
    let data = try! Data(contentsOf: inputFileUrl)
    var temp: [UInt16] = Array(repeating: 0, count: data.count / 2)
    _ = temp.withUnsafeMutableBytes { data.copyBytes(to: $0) }
    program = temp.map { Int($0) }
} else {
    print("Usage: <binary file> | --raw <comma separated integers>")
    exit(0)
}

var inputBuffer: [Character] = []
let vm = SynacorVM(program: program, input: {
    if inputBuffer.isEmpty {
        let line = (readLine() ?? "") + "\n"
        inputBuffer = line.map(Character.init)
    }
    return inputBuffer.removeFirst()
}, output: { value in
    print(value, terminator: "")
    return true
})

vm.run()
print("")
