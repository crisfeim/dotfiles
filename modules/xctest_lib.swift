import Foundation

public let defaultMessage = ""

var currentTestName: String = ""

@discardableResult public func XCTAssert(
    _ expression: @autoclosure () -> Bool,
    _ message: String = defaultMessage
    ) -> String {
    return returnTestResult(expression(), message: message)
}

@discardableResult public func XCTAssertEqual<T : Equatable>(
    _ expression1: @autoclosure () -> T?,
    _ expression2: @autoclosure () -> T?,
    _ message: String = defaultMessage
    ) -> String {
    return returnTestResult(
        expression1() == expression2(),
        message: "expected: \(expression2() as Optional), actual: \(expression1() as Optional)")
}

@discardableResult public func XCTAssertEqual<T : Equatable>(
    _ expression1: @autoclosure () -> ArraySlice<T>,
    _ expression2: @autoclosure () -> ArraySlice<T>,
    _ message: String = defaultMessage
    ) -> String {
    return returnTestResult(
        expression1() == expression2(),
        message: "expected: \(expression2()), actual: \(expression1())")
}

@discardableResult public func XCTAssertEqual<T : Equatable>(
    _ expression1: @autoclosure () -> ContiguousArray<T>,
    _ expression2: @autoclosure () -> ContiguousArray<T>,
    _ message: String = defaultMessage
    ) -> String {
    return returnTestResult(
        expression1() == expression2(),
        message: "expected: \(expression2()), actual: \(expression1())")
}

@discardableResult public func XCTAssertEqual<T : Equatable>(
    _ expression1: @autoclosure () -> [T],
    _ expression2: @autoclosure () -> [T],
    _ message: String = defaultMessage
    ) -> String {
    return returnTestResult(
        expression1() == expression2(),
        message: "expected: \(expression2()), actual: \(expression1())")
}

@discardableResult public func XCTAssertEqual<T, U : Equatable>(
    _ expression1: @autoclosure () -> [T : U],
    _ expression2: @autoclosure () -> [T : U],
    _ message: String = defaultMessage
    ) -> String {
    return returnTestResult(
        expression1() == expression2(),
        message: "expected: \(expression2()), actual: \(expression1())")
}

@discardableResult public func XCTAssertFalse(
    _ expression: @autoclosure () -> Bool,
    _ message: String = defaultMessage
    ) -> String {
    return returnTestResult(!expression(), message: message)
}

@discardableResult public func XCTAssertGreaterThan<T : Comparable>(
    _ expression1: @autoclosure () -> T,
    _ expression2: @autoclosure () -> T,
    _ message: String = defaultMessage
    ) -> String {
    return returnTestResult(
        expression1() > expression2(),
        message: "\(expression1()) is not greater than \(expression2())")
}

@discardableResult public func XCTAssertGreaterThanOrEqual<T : Comparable>(
    _ expression1: @autoclosure () -> T,
    _ expression2: @autoclosure () -> T,
    _ message: String = defaultMessage
    ) -> String {
    return returnTestResult(
        expression1() >= expression2(),
        message: "\(expression1()) is not greater than or equal to \(expression2())")
}

@discardableResult public func XCTAssertLessThan<T : Comparable>(
    _ expression1: @autoclosure () -> T,
    _ expression2: @autoclosure () -> T,
    _ message: String = defaultMessage
    ) -> String {
    return returnTestResult(
        expression1() < expression2(),
        message: "\(expression1()) is not less than \(expression2())")
}

@discardableResult public func XCTAssertLessThanOrEqual<T : Comparable>(
    _ expression1: @autoclosure () -> T,
    _ expression2: @autoclosure () -> T,
    _ message: String = defaultMessage
    ) -> String {
    return returnTestResult(
        expression1() <= expression2(),
        message: "\(expression1()) is not less than or equal to \(expression2())")
}

@discardableResult public func XCTAssertNil(
    _ expression: @autoclosure () -> Any?,
    _ message: String = ""
    ) -> String {
    var result = true
    if let _ = expression() { result = false }
    return returnTestResult(
        result,
        message: "expected nil, actual: \(expression() as Optional)")
}

@discardableResult public func XCTAssertNotEqual<T : Equatable>(
    _ expression1: @autoclosure () -> T?,
    _ expression2: @autoclosure () -> T?,
    _ message: String = defaultMessage
    ) -> String {
    return returnTestResult(
        expression1() != expression2(),
        message: "\(expression1() as Optional) is equal to \(expression2() as Optional)")
}

@discardableResult public func XCTAssertNotEqual<T : Equatable>(
    _ expression1: @autoclosure () -> ContiguousArray<T>,
    _ expression2: @autoclosure () -> ContiguousArray<T>,
    _ message: String = defaultMessage
    ) -> String {
    return returnTestResult(
        expression1() != expression2(),
        message: "\(expression1()) is equal to \(expression2())")
}

@discardableResult public func XCTAssertNotEqual<T : Equatable>(
    _ expression1: @autoclosure () -> ArraySlice<T>,
    _ expression2: @autoclosure () -> ArraySlice<T>,
    _ message: String = defaultMessage
    ) -> String {
    return returnTestResult(
        expression1() != expression2(),
        message: "\(expression1()) is equal to \(expression2())")
}

@discardableResult public func XCTAssertNotEqual<T : Equatable>(
    _ expression1: @autoclosure () -> [T],
    _ expression2: @autoclosure () -> [T],
    _ message: String = defaultMessage
    ) -> String {
    return returnTestResult(
        expression1() != expression2(),
        message: "\(expression1()) is equal to \(expression2())")
}

@discardableResult public func XCTAssertNotEqual<T, U : Equatable>(
    _ expression1: @autoclosure () -> [T : U],
    _ expression2: @autoclosure () -> [T : U],
    _ message: String = defaultMessage
    ) -> String {
    return returnTestResult(
        expression1() != expression2(),
        message: "\(expression1()) is equal to \(expression2())")
}

@discardableResult public func XCTAssertNotNil(
    _ expression: @autoclosure () -> Any?,
    _ message: String = ""
    ) -> String {
    var result = false
    if let _ = expression() { result = true }
    return returnTestResult(result, message: "expected non-nil, actual: nil")
}

@discardableResult public func XCTAssertTrue(
    _ expression: @autoclosure () -> Bool,
    _ message: String = defaultMessage
    ) -> String {
    return returnTestResult(expression(), message: message)
}

@discardableResult public func XCTFail(_ message: String = "") -> String {
    return returnTestResult(false, message: message)
}

func returnTestResult(_ result: Bool, message: String) -> String {
    let r: String
    if result {
        
        r = "\(ok())  \(currentTestName)()"
    } else {
        r = "\(fail())  \(currentTestName)(): \(message)"
    }
    print(r)
    return r
}

open class XCTestCase: NSObject {

    @discardableResult
    public override init() {
        super.init()
        self.runTestMethods()
    }

    open class func setUp() {}
    open func setUp() {}
    open class func tearDown() {}
    open func tearDown() {}

    override open var description: String { return "" }

    private func runTestMethods() {
        type(of: self).setUp()
        defer { type(of: self).tearDown() }
        var mc: CUnsignedInt = 0
        guard var mlist = class_copyMethodList(type(of: self).classForCoder(), &mc) else { return }
        (0 ..< mc).forEach { _ in
            let m = method_getName(mlist.pointee)
            let name = String(describing: m)
            if name.hasPrefix("test") {
                currentTestName = name
                self.setUp()
                self.performSelector(onMainThread: m, with: nil, waitUntilDone: true)
                self.tearDown()
            }
            mlist = mlist.successor()
        }
    }
}

func ok() -> String { "\u{001B}[92m􁁛\u{001B}[0m" }  
func fail() -> String { "\u{001B}[91m􀢄\u{001B}[0m" }