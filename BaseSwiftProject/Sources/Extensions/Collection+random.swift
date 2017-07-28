public extension Array {
    /// Return a random element of the array
    public var random: Element {
        return self[Random.int(to: self.count)]
    }

}

public extension MutableCollection where Indices.Iterator.Element == Index {
    /// Shuffles the contents of this collection.
    public mutating func shuffle() {
        let c = count
        guard c > 1 else { return }

        for (firstUnshuffled , unshuffledCount) in zip(indices, stride(from: c, to: 1, by: -1)) {
            let d: IndexDistance = numericCast(Random.int(to: numericCast(unshuffledCount)))
            guard d != 0 else { continue }
            let i = index(firstUnshuffled, offsetBy: d)
            swap(&self[firstUnshuffled], &self[i])
        }
    }
}

public extension Sequence {
    /// Returns an array with the contents of this sequence, shuffled.
    public func shuffled() -> [Iterator.Element] {
        var result = Array(self)
        result.shuffle()
        return result
    }
}
