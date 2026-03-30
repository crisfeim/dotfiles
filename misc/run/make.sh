#!/usr/bin/env bash

# create_hellos.sh — genera un hello world por cada lenguaje

cat > hello.swift   <<'EOF'
print("Hello, World from Swift!")
EOF

cat > hello.js      <<'EOF'
console.log("Hello, World from JavaScript!")
EOF

cat > hello.ts      <<'EOF'
console.log("Hello, World from TypeScript!")
EOF

cat > hello.py      <<'EOF'
print("Hello, World from Python!")
EOF

cat > hello.rb      <<'EOF'
puts "Hello, World from Ruby!"
EOF

cat > hello.lua     <<'EOF'
print("Hello, World from Lua!")
EOF

cat > hello.tcl     <<'EOF'
puts "Hello, World from Tcl!"
EOF

cat > hello.php     <<'EOF'
<?php echo "Hello, World from PHP!\n";
EOF

cat > hello.sh      <<'EOF'
echo "Hello, World from Bash!"
EOF

cat > hello.zsh     <<'EOF'
echo "Hello, World from Zsh!"
EOF

cat > hello.pl      <<'EOF'
print "Hello, World from Perl!\n";
EOF

cat > hello.exs     <<'EOF'
IO.puts "Hello, World from Elixir!"
EOF

cat > hello.erl     <<'EOF'
-module(hello).
main(_) -> io:format("Hello, World from Erlang!~n").
EOF

cat > hello.hs      <<'EOF'
main :: IO ()
main = putStrLn "Hello, World from Haskell!"
EOF

cat > hello.go      <<'EOF'
package main
import "fmt"
func main() { fmt.Println("Hello, World from Go!") }
EOF

cat > hello.c       <<'EOF'
#include <stdio.h>
int main() { printf("Hello, World from C!\n"); return 0; }
EOF

cat > hello.cpp     <<'EOF'
#include <iostream>
int main() { std::cout << "Hello, World from C++!" << std::endl; return 0; }
EOF

cat > hello.m       <<'EOF'
#import <Foundation/Foundation.h>
int main() { NSLog(@"Hello, World from Objective-C!"); return 0; }
EOF

cat > hello.java    <<'EOF'
public class hello {
    public static void main(String[] args) {
        System.out.println("Hello, World from Java!");
    }
}
EOF

cat > hello.rs      <<'EOF'
fn main() { println!("Hello, World from Rust!"); }
EOF

echo "✅ hello world files created"