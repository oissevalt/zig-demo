# Zig Demo

> [!IMPORTANT]
> Zig has not reached version 1.0 and many APIs are subject to change. There is no intention to actively maintain this repository so as to keep things up to date. Also, some code are platform-specific. Therefore, you might find some code broken.
> 
> Specifics are listed below:
>
> - Zig version:  0.13.0 (release)
> - System:       macOS 14.4.1
> - Architecture: M2 (aarch64)

Building things in [Zig](https://ziglang.org).

## Run the tests

1. Ensure you have Zig installed. Refer to [ziglang.org](https://ziglang.org) for installation guide.

2. Clone this repository.

   ```shell
   git clone https://github.com/oissevalt/zig-demo
   ```

3. In the root folder, run tests.

   ```shell
   # All the tests
   zig test src/main.zig

   # Test one module, e.g. the BF interpreter
   zig test src/brainfuck/Interpreter.zig
   ```

   Refer to the help message of `zig` command for more information.