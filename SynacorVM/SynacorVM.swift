//
//  SynacorVM.swift
//  SynacorVM
//
//  Created by peter bohac on 12/25/19.
//  Copyright © 2019 peter bohac. All rights reserved.
//

final class SynacorVM {
    private let inputProvider: (() -> Character?)
    private let outputHandler: ((Character) -> Bool)

    private var memory: [Int]
    private var ip: Int
    private var stack: [Int]

    enum State {
        case halted
        case inputNeeded
        case stopRequested
        case invalidInstruction
    }

    init(program: [Int], input: @escaping (() -> Character?), output: @escaping ((Character) -> Bool)) {
        self.inputProvider = input
        self.outputHandler = output
        self.memory = Array(repeating: 0, count: 32776)
        self.ip = 0
        self.stack = []
        program.enumerated().forEach { offset, value in memory[offset] = value }
    }

    @discardableResult
    func run() -> State {
        repeat {
            let instruction = memory[ip]

            switch instruction {
            case 0: // halt
                return .halted

            case 1: // set
                let a = memory[ip + 1]
                let b = decode(memory[ip + 2])
                memory[a] = b
                ip += 3

            case 2: // push
                let a = decode(memory[ip + 1])
                stack.append(a)
                ip += 2

            case 3: // pop
                let a = memory[ip + 1]
                guard let value = stack.popLast() else {
                    return .invalidInstruction
                }
                memory[a] = value
                ip += 2

            case 4: // eq
                let a = memory[ip + 1]
                let b = decode(memory[ip + 2])
                let c = decode(memory[ip + 3])
                memory[a] = b == c ? 1 : 0
                ip += 4

            case 5: // gt
                let a = memory[ip + 1]
                let b = decode(memory[ip + 2])
                let c = decode(memory[ip + 3])
                memory[a] = b > c ? 1 : 0
                ip += 4

            case 6: // jmp
                let a = decode(memory[ip + 1])
                ip = a

            case 7: // jt
                let a = decode(memory[ip + 1])
                let b = decode(memory[ip + 2])
                ip = a != 0 ? b : ip + 3

            case 8: // jf
                let a = decode(memory[ip + 1])
                let b = decode(memory[ip + 2])
                ip = a == 0 ? b : ip + 3

            case 9: // add
                let a = memory[ip + 1]
                let b = decode(memory[ip + 2])
                let c = decode(memory[ip + 3])
                memory[a] = (b + c) % 32768
                ip += 4

            case 10: // mult
                let a = memory[ip + 1]
                let b = decode(memory[ip + 2])
                let c = decode(memory[ip + 3])
                memory[a] = (b * c) % 32768
                ip += 4

            case 11: // mod
                let a = memory[ip + 1]
                let b = decode(memory[ip + 2])
                let c = decode(memory[ip + 3])
                memory[a] = b % c
                ip += 4

            case 12: // and
                let a = memory[ip + 1]
                let b = decode(memory[ip + 2])
                let c = decode(memory[ip + 3])
                memory[a] = b & c
                ip += 4

            case 13: // or
                let a = memory[ip + 1]
                let b = decode(memory[ip + 2])
                let c = decode(memory[ip + 3])
                memory[a] = b | c
                ip += 4

            case 14: // not
                let a = memory[ip + 1]
                let b = decode(memory[ip + 2])
                memory[a] = ~b & 0x7FFF
                ip += 3

            case 15: // rmem
                let a = memory[ip + 1]
                let b = decode(memory[ip + 2])
                memory[a] = memory[b]
                ip += 3

            case 16: // wmem
                let a = decode(memory[ip + 1])
                let b = decode(memory[ip + 2])
                memory[a] = b
                ip += 3

            case 17: // call
                let a = decode(memory[ip + 1])
                stack.append(ip + 2)
                ip = a

            case 18: // ret
                guard let value = stack.popLast() else {
                    return .halted
                }
                ip = value

            case 19: // out
                let a = decode(memory[ip + 1])
                let char = Character(UnicodeScalar(a)!)
                let `continue` = outputHandler(char)
                ip += 2
                if `continue` == false {
                    return .stopRequested
                }

            case 20: // in
                let a = memory[ip + 1]
                guard let input = inputProvider() else {
                    return .inputNeeded
                }
                memory[a] = Int(input.utf8.first!)
                ip += 2

            case 21: // no-op
                ip += 1

            default:
                return .invalidInstruction
            }
        } while true
    }

    func decode(_ value: Int) -> Int {
        return value > 32767 ? memory[value] : value
    }
}
