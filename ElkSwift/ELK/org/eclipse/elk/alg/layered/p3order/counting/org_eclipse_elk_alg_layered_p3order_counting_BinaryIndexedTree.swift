// Ported from elk-source/plugins/org.eclipse.elk.alg.layered/src/org/eclipse/elk/alg/layered/p3order/counting/BinaryIndexedTree.java
import Foundation

internal class org_eclipse_elk_alg_layered_p3order_counting_BinaryIndexedTree {
    internal var binarySums: [Int]
    internal var numsPerIndex: [Int]
    internal var sizeValue: Int
    internal let maxNum: Int

    internal init(_ maxNum: Int) {
        self.maxNum = maxNum
        self.binarySums = Array(repeating: 0, count: maxNum + 1)
        self.numsPerIndex = Array(repeating: 0, count: maxNum)
        self.sizeValue = 0
    }

    internal func add(_ index: Int) {
        sizeValue += 1
        numsPerIndex[index] += 1
        var i = index + 1
        while i < binarySums.count {
            binarySums[i] += 1
            i += i & -i
        }
    }

    internal func rank(_ index: Int) -> Int {
        var i = index
        var sum = 0
        while i > 0 {
            sum += binarySums[i]
            i -= i & -i
        }
        return sum
    }

    internal func size() -> Int {
        sizeValue
    }

    internal func removeAll(_ index: Int) {
        let numEntries = numsPerIndex[index]
        if numEntries == 0 { return }
        numsPerIndex[index] = 0
        sizeValue -= numEntries

        var i = index + 1
        while i < binarySums.count {
            binarySums[i] -= numEntries
            i += i & -i
        }
    }

    internal func clear() {
        binarySums = Array(repeating: 0, count: maxNum + 1)
        numsPerIndex = Array(repeating: 0, count: maxNum)
        sizeValue = 0
    }

    internal func isEmpty() -> Bool {
        sizeValue == 0
    }
}
