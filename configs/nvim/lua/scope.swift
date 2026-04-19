import Foundation

struct Movie {
    let id: UUID
}
enum Scope {

}

protocol EmptyScope {

}

func hello() {

}

enum Scope1 {
    class Scope2 {
        struct Scope3 {
            protocol Some {

            }

            struct NewScope {
                func some() {
                    print("hello world")
                }
            }


            func scope() {
                hello()
            }

        }
    }


    func some() {
        let some = "some var"
    }
}


protocol SomeProtocol {

}

extension SomeProtocol {
    func someScope() {

    }
}
