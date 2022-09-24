# tabletool

[![test](https://github.com/nonanonno/tabletool/actions/workflows/test.yml/badge.svg)](https://github.com/nonanonno/tabletool/actions/workflows/test.yml)

A table generator library inspired by Python's tabulate  compatible with east-asian character.

```d
import std.stdio;
import tabletool;

const data = [
    ["D-man", "Programming Language"],
    ["D言語くん", "プログラミング言語"],
];
const header = ["マスコットキャラクタ", "about"];
writeln(tabulate(arrayData, header));
/* Output:
マスコットキャラクタ        about        
-------------------- --------------------
       D-man         Programming Language
     D言語くん        プログラミング言語 
*/

// Also works with struct
struct Data {
    @DisplayName("マスコットキャラクタ")
    string name;
    string about;
}
const structData = [
    Data("D-man", "Programming Language"),
    Data("D言語くん", "プログラミング言語"),
];
writeln(tabulate(structData));
/* Output: ditto */

writeln(tabulate(structData, Config(Justify.Center, Style.Markdown, true)));
/* Output:
|マスコットキャラクタ|       about        |
|--------------------|--------------------|
|       D-man        |Programming Language|
|     D言語くん      | プログラミング言語 |
*/
```

## Features

- Compatible with east-asian characters (Thank to [east_asian_width](https://code.dlang.org/packages/east_asian_width))
- Generate a table from 2-D array of any element which can be converted to string
- Generate a table from 1-D array of a struct (Can override display name by UDA `@DisplayName("<name>")`)
- Select styles (simple, markdown and grid)
- Select text alignment (left, center and right)
- Turn on/off header