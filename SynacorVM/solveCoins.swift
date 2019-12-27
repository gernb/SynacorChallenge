//
//  solveCoins.swift
//  SynacorVM
//
//  Created by peter bohac on 12/26/19.
//  Copyright © 2019 peter bohac. All rights reserved.
//

import Foundation

extension Array {
    var permutations: [[Element]] {
        guard self.count > 1 else { return [self] }
        return self.enumerated().flatMap { item in
            return self.removing(elementAt: item.offset).permutations.map { [item.element] + $0 }
        }
    }

    func removing(elementAt index: Int) -> [Element] {
        var result = self
        result.remove(at: index)
        return result
    }
}

func solveCoins(from savedStateFile: String) {
    var inputBuffer: [Character] = []
    var outputBuffer = ""
    let vm = SynacorVM(program: [], input: { return inputBuffer.popLast() }) { value in
        outputBuffer.append(value)
        return true
    }
    @discardableResult func executeCommands(_ commands: [String], from state: SynacorVM.State) -> String {
        inputBuffer = (commands.joined(separator: "\n") + "\n").map(Character.init).reversed()
        outputBuffer = ""
        vm.state = state
        vm.run()
        return outputBuffer
    }
    let fileUrl = pwd.appendingPathComponent(savedStateFile)
    guard let data = try? Data(contentsOf: fileUrl), let start = try? decoder.decode(SynacorVM.State.self, from: data) else {
        print("Failed to load initial state")
        exit(0)
    }

    let commands = [
        "use red coin",
        "use corroded coin",
        "use shiny coin",
        "use concave coin",
        "use blue coin"
    ]

    for seq in Array(0 ..< commands.count).permutations {
        let result = executeCommands(seq.map { commands[$0] }, from: start)
        if result.contains("As you place the last coin, they are all released onto the floor.") == false {
            print(seq.map { commands[$0] }.joined(separator: "\n"))
            print(result)
            break
        }
    }
}
