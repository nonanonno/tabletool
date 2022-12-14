# tabletool

[![test](https://github.com/nonanonno/tabletool/actions/workflows/test.yml/badge.svg)](https://github.com/nonanonno/tabletool/actions/workflows/test.yml)
[![DUB](https://img.shields.io/dub/v/tabletool)](https://code.dlang.org/packages/tabletool)

A table generator library inspired by Python's tabulate  compatible with east-asian character.

```d
import std.stdio;
import tabletool;

const data = [
    ["D-man", "Programming Language"],
    ["D言語くん", "プログラミング言語"],
];
const header = ["マスコットキャラクタ", "about"];
writeln(tabulate(data, header));
/* Output:
 マスコットキャラクタ          about         
---------------------- ----------------------
        D-man           Programming Language 
      D言語くん          プログラミング言語  
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

writeln(tabulate(structData, Config(Style.grid, Align.left, true)));
/* Output:
┌──────────────────────┬──────────────────────┐
│ マスコットキャラクタ │ about                │
├──────────────────────┼──────────────────────┤
│ D-man                │ Programming Language │
├──────────────────────┼──────────────────────┤
│ D言語くん            │ プログラミング言語   │
└──────────────────────┴──────────────────────┘
*/
```

## Features

- Compatible with east-asian characters (Thank to [east_asian_width](https://code.dlang.org/packages/east_asian_width))
- Generate a table from 2-D array of any element which can be converted to string
- Generate a table from 1-D array of a struct (Can override display name by UDA `@DisplayName("<name>")`)
- Generate a table from 1-D array of an associated array whose key and value can be converted to string
- Configure table appearance (style, alginment
- Turn on/off header