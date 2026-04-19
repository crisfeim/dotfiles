import Foundation

struct StandardError: TextOutputStream, Sendable {
    private static let handle = FileHandle.standardError

    public func write(_ string: String) {
        Self.handle.write(Data(string.utf8))
    }
}

private var stderr = StandardError()

private func printError(
    file: StaticString, line: UInt, message: String, to stderr: inout StandardError
) {
    print("\(file):\(line): \(message)", to: &stderr)
}

public func assertEqual<Type: Equatable>(
    _ a: Type, _ b: Type, _ message: String? = nil, file: StaticString = #file, line: UInt = #line
) {
    if a != b {
        printError(file: file, line: line, message: message ?? "Assert failed", to: &stderr)
        print("a:\n\(a)\nb:\n\(b)", to: &stderr)
    }
}

public func test(_ name: String, action: () -> Void) {
    action()
}
