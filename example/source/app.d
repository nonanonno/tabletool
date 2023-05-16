void main()
{
    import std.stdio;
    import tabletool;

    const data = [
        ["D-man", "Programming Language"],
        ["D言語くん", "プログラミング言語"],
    ];
    const header = ["マスコットキャラクタ", "about"];
    writeln(tabulate(data, header));
    writeln();

    // Also works with struct
    struct Data
    {
        @DisplayName("マスコットキャラクタ")
        string name;
        string about;
    }

    const structData = [
        Data("\033[31mD-man\033[0m", "Programming Language"),
        Data("D言語くん", "\033[33m\033[3mプログラミング言語\033[0m"),
    ];
    writeln(tabulate(structData));
    writeln();

    writeln(tabulate(structData, Config(Style.grid, Align.left, true)));
}
