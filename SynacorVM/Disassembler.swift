//
//  Disassembler.swift
//  SynacorVM
//
//  Created by peter bohac on 12/27/19.
//  Copyright © 2019 peter bohac. All rights reserved.
//

import Foundation

struct Disassembler {
    let program: [Int]

    init(state: SynacorVM.State) {
        self.program = state["memory"]!
    }

    func disassemble(from: Int = 0, to: Int = 32767) {
        var idx = from
        repeat {
            let instruction = program[idx]
            let address = idx
            var values = ""
            var code = ""

            switch instruction {
            case 0: // halt
                values = "0"
                code = "HALT"
                idx += 1

            case 1: // set
                let a = decode(program[idx + 1])
                let b = decode(program[idx + 2])
                values = "1 \(program[idx + 1]) \(program[idx + 2])"
                code = "SET \(a) \(b); \(a) = \(b)"
                idx += 3

            case 2: // push
                let a = decode(program[idx + 1])
                values = "2 \(program[idx + 1])"
                code = "PUSH \(a); ToS = \(a)"
                idx += 2

            case 3: // pop
                let a = decode(program[idx + 1])
                values = "3 \(program[idx + 1])"
                code = "POP \(a); \(a) = ToS"
                idx += 2

            case 4: // eq
                let a = decode(program[idx + 1])
                let b = decode(program[idx + 2])
                let c = decode(program[idx + 3])
                values = "4 \(program[idx + 1]) \(program[idx + 2]) \(program[idx + 3])"
                code = "EQ \(a) \(b) \(c); \(a) = \(b) == \(c) ? 1 : 0"
                idx += 4

            case 5: // gt
                let a = decode(program[idx + 1])
                let b = decode(program[idx + 2])
                let c = decode(program[idx + 3])
                values = "5 \(program[idx + 1]) \(program[idx + 2]) \(program[idx + 3])"
                code = "GT \(a) \(b) \(c); \(a) = \(b) > \(c) ? 1 : 0"
                idx += 4

            case 6: // jmp
                let a = decode(program[idx + 1])
                values = "6 \(program[idx + 1])"
                code = "JMP \(a)"
                idx += 2

            case 7: // jt
                let a = decode(program[idx + 1])
                let b = decode(program[idx + 2])
                values = "7 \(program[idx + 1]) \(program[idx + 2])"
                code = "JT \(a) \(b); JMP \(b) if \(a) != 0"
                idx += 3

            case 8: // jf
                let a = decode(program[idx + 1])
                let b = decode(program[idx + 2])
                values = "8 \(program[idx + 1]) \(program[idx + 2])"
                code = "JF \(a) \(b); JMP \(b) if \(a) == 0"
                idx += 3

            case 9: // add
                let a = decode(program[idx + 1])
                let b = decode(program[idx + 2])
                let c = decode(program[idx + 3])
                values = "9 \(program[idx + 1]) \(program[idx + 2]) \(program[idx + 3])"
                code = "ADD \(a) \(b) \(c); \(a) = (\(b) + \(c)) % 32768"
                idx += 4

            case 10: // mult
                let a = decode(program[idx + 1])
                let b = decode(program[idx + 2])
                let c = decode(program[idx + 3])
                values = "10 \(program[idx + 1]) \(program[idx + 2]) \(program[idx + 3])"
                code = "MULT \(a) \(b) \(c); \(a) = (\(b) * \(c)) % 32768"
                idx += 4

            case 11: // mod
                let a = decode(program[idx + 1])
                let b = decode(program[idx + 2])
                let c = decode(program[idx + 3])
                values = "11 \(program[idx + 1]) \(program[idx + 2]) \(program[idx + 3])"
                code = "MOD \(a) \(b) \(c); \(a) = \(b) % \(c)"
                idx += 4

            case 12: // and
                let a = decode(program[idx + 1])
                let b = decode(program[idx + 2])
                let c = decode(program[idx + 3])
                values = "12 \(program[idx + 1]) \(program[idx + 2]) \(program[idx + 3])"
                code = "AND \(a) \(b) \(c); \(a) = \(b) & \(c)"
                idx += 4

            case 13: // or
                let a = decode(program[idx + 1])
                let b = decode(program[idx + 2])
                let c = decode(program[idx + 3])
                values = "13 \(program[idx + 1]) \(program[idx + 2]) \(program[idx + 3])"
                code = "OR \(a) \(b) \(c); \(a) = \(b) | \(c)"
                idx += 4

            case 14: // not
                let a = decode(program[idx + 1])
                let b = decode(program[idx + 2])
                values = "14 \(program[idx + 1]) \(program[idx + 2])"
                code = "NOT \(a) \(b); \(a) = ~\(b) & 0x7FFF"
                idx += 3

            case 15: // rmem
                let a = decode(program[idx + 1])
                let b = decode(program[idx + 2])
                values = "15 \(program[idx + 1]) \(program[idx + 2])"
                code = "RMEM \(a) \(b); \(a) = @\(b)"
                idx += 3

            case 16: // wmem
                let a = decode(program[idx + 1])
                let b = decode(program[idx + 2])
                values = "16 \(program[idx + 1]) \(program[idx + 2])"
                code = "WMEM \(a) \(b); @\(a) = \(b)"
                idx += 3

            case 17: // call
                let a = decode(program[idx + 1])
                values = "17 \(program[idx + 1])"
                code = "CALL \(a); JMP \(a); ToS = \(idx + 2)"
                idx += 2

            case 18: // ret
                values = "18"
                code = "RET; IP = ToS"
                idx += 1

            case 19: // out
                let a = decode(program[idx + 1])
                values = "19 \(program[idx + 1])"
                code = {
                    let value = program[idx + 1]
                    guard value < 0xFF else { return "OUT \(a)" }
                    if value == 10 { return "OUT \\n" }
                    else { return "OUT \(Character(UnicodeScalar(value)!))" }
                }()
                idx += 2

            case 20: // in
                let a = decode(program[idx + 1])
                values = "20 \(program[idx + 1])"
                code = "IN \(a)"
                idx += 2

            case 21: // no-op
                values = "21"
                code = "NOOP"
                idx += 1

            default:
                values = String(instruction)
                code = {
                    guard instruction < 0xFF else { return "???" }
                    if instruction == 10 { return "??? \\n" }
                    else { return "??? \(Character(UnicodeScalar(instruction)!))" }
                }()
                idx += 1
            }

            let prefix = "\(address): \(values)"
            let space = String(repeating: " ", count: 30 - prefix.count)
            print(prefix + space + code)
        } while idx <= to
    }

    private func decode(_ value: Int) -> String {
        guard value > 32767 else { return String(value) }
        return "R\(value - 32767)"
    }
}
