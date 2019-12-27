//
//  teleporterCode.swift
//  SynacorVM
//
//  Created by peter bohac on 12/26/19.
//  Copyright © 2019 peter bohac. All rights reserved.
//

import Foundation

// See: https://rosettacode.org/wiki/Ackermann_function#Efficient_Version
// And: https://en.wikipedia.org/wiki/Ackermann_function
fileprivate func ackermann(_ m: Int, _ n: Int, _ r: Int) -> Int {
    var stack: [Int] = [m]
    stack.reserveCapacity(100_000)
    var n = n
    while var m = stack.popLast() {
        while true {
            if m == 0 {
                n = (n + 1) % 32768
                break
            } else if m == 1 {
                n = (n + r + 1) % 32768
                break
            } else if m == 2 {
                n = (n * (2 + r - 1) + (2 * r + 1)) % 32768
                break
            } else if n == 0 {
                m -= 1
                n = r
            } else {
                stack.append(m - 1)
                n -= 1
            }
        }
    }

    return n;
}

func findTeleporterCode() {
    for r8 in (1 ... 32767).reversed() {
        let value = ackermann(4, 1, r8)
        if value == 6 {
            print("Found: \(r8)")
            return
        }
    }

    print("Did not find a suitable value of register 8!")
}
