module tabletool;

import std.algorithm : canFind, max, map;
import std.array : array;
import std.conv : to;
import std.format : format;
import std.range : join, repeat, zip;
import std.traits : getUDAs, hasUDA;

import eastasianwidth : displayWidth;

/// Option to specify the position of element in the table.
enum Justify
{
    Center,
    Left,
    Right,
}

/// Option to specify the table style.
enum Style
{
    Simple,
    Markdown, /// Github
    Grid,
}

/// UDA to set display name of the struct member.
struct DisplayName
{
    string name;
}

/// Configurations for tabulate function.
struct Config
{
    Justify justify = Justify.Center;
    Style style = Style.Simple;
    bool showHeader = true;
}

string tabulate(T)(in T[][] data, in string[] header, in Config config = Config())
{
    const ruler = Ruler(config.style);

    const justify = (string text, size_t width) {
        with (Justify) final switch (config.justify)
        {
        case Center:
            return eacenter(text, width);
        case Left:
            return ealeft(text, width);
        case Right:
            return earight(text, width);
        }
    };

    if (data.length == 0)
    {
        return null;
    }
    auto widthes = new size_t[data[0].length];

    if (config.showHeader && header.length > 0)
    {
        assert(header.length == widthes.length);
        foreach (i; 0 .. header.length)
        {
            widthes[i] = max(widthes[i], displayWidth(header[i]));
        }
    }

    foreach (line; data)
    {
        assert(line.length == widthes.length);
        foreach (i; 0 .. line.length)
            widthes[i] = max(widthes[i], displayWidth(line[i].to!string));
        {
        }
    }

    string[] lines;

    if (auto top = ruler.top(widthes))
    {
        lines ~= top;
    }

    if (config.showHeader && header.length > 0)
    {
        lines ~= makeItemLine(header, widthes, ruler, justify);
        if (auto sep = ruler.headerItemSeperator(widthes))
        {
            lines ~= sep;
        }
    }

    foreach (i, line; data)
    {
        lines ~= makeItemLine(line, widthes, ruler, justify);

        if ((i + 1) != data.length)
        {
            if (auto sep = ruler.horizontalItemSeperator(widthes))
            {
                lines ~= sep;
            }
        }
    }

    if (auto bottom = ruler.bottom(widthes))
    {
        lines ~= bottom;
    }
    return lines.join("\n");
}

@("Check if the tabulate generates expected text for each configurations.")
unittest
{
    import dshould;

    const testdata = [
        ["D-man", "Programming Language"],
        ["D言語くん", "プログラミング言語"],
    ];
    const header = ["マスコットキャラクタ", "about"];

    tabulate(testdata, header, Config(Justify.Center, Style.Simple, true))
        .should.be(import("center_simple_header.txt"));
    tabulate(testdata, header, Config(Justify.Center, Style.Markdown, true))
        .should.be(import("center_markdown_header.txt"));
    tabulate(testdata, header, Config(Justify.Center, Style.Grid, true))
        .should.be(import("center_grid_header.txt"));

    tabulate(testdata, header, Config(Justify.Center, Style.Simple, false))
        .should.be(import("center_simple_no_header.txt"));
    tabulate(testdata, header, Config(Justify.Center, Style.Markdown, false))
        .should.be(import("center_markdown_no_header.txt"));
    tabulate(testdata, header, Config(Justify.Center, Style.Grid, false))
        .should.be(import("center_grid_no_header.txt"));

    tabulate(testdata, [], Config(Justify.Center, Style.Simple, true))
        .should.be(import("center_simple_no_header.txt"));
    tabulate(testdata, [], Config(Justify.Center, Style.Markdown, true))
        .should.be(import("center_markdown_no_header.txt"));
    tabulate(testdata, [], Config(Justify.Center, Style.Grid, true))
        .should.be(import("center_grid_no_header.txt"));

    tabulate(testdata, header, Config(Justify.Left, Style.Simple, true))
        .should.be(import("left_simple_header.txt"));
    tabulate(testdata, header, Config(Justify.Left, Style.Markdown, true))
        .should.be(import("left_markdown_header.txt"));
    tabulate(testdata, header, Config(Justify.Left, Style.Grid, true))
        .should.be(import("left_grid_header.txt"));

    tabulate(testdata, header, Config(Justify.Left, Style.Simple, false))
        .should.be(import("left_simple_no_header.txt"));
    tabulate(testdata, header, Config(Justify.Left, Style.Markdown, false))
        .should.be(import("left_markdown_no_header.txt"));
    tabulate(testdata, header, Config(Justify.Left, Style.Grid, false))
        .should.be(import("left_grid_no_header.txt"));

    tabulate(testdata, header, Config(Justify.Right, Style.Simple, true))
        .should.be(import("right_simple_header.txt"));
    tabulate(testdata, header, Config(Justify.Right, Style.Markdown, true))
        .should.be(import("right_markdown_header.txt"));
    tabulate(testdata, header, Config(Justify.Right, Style.Grid, true))
        .should.be(import("right_grid_header.txt"));

    tabulate(testdata, header, Config(Justify.Right, Style.Simple, false))
        .should.be(import("right_simple_no_header.txt"));
    tabulate(testdata, header, Config(Justify.Right, Style.Markdown, false))
        .should.be(import("right_markdown_no_header.txt"));
    tabulate(testdata, header, Config(Justify.Right, Style.Grid, false))
        .should.be(import("right_grid_no_header.txt"));

}

string tabulate(T)(in T[][] data, in Config config = Config())
{
    return tabulate(data, [], config);
}

string tabulate(T)(in T[] data, in Config config = Config()) if (is(T == struct))
{
    string[][] stringData;
    string[] header;
    foreach (member; __traits(allMembers, T))
    {
        static if (hasUDA!(__traits(getMember, T, member), DisplayName))
        {
            enum displayName = getUDAs!(__traits(getMember, T, member), DisplayName)[0];
            header ~= displayName.name;
        }
        else
        {
            header ~= member;

        }
    }
    foreach (d; data)
    {
        string[] line;
        foreach (member; __traits(allMembers, T))
        {
            line ~= __traits(getMember, d, member).to!string;
        }
        stringData ~= line;
    }
    return tabulate(stringData, header, config);
}

@("Check if the tabulate works for struct with DisplayName attribute.")
unittest
{
    import dshould;

    struct TestData
    {
        @DisplayName("マスコットキャラクタ")
        string name;
        string about;
    }

    const testdata = [
        TestData("D-man", "Programming Language"),
        TestData("D言語くん", "プログラミング言語"),
    ];

    tabulate(testdata, Config(Justify.Center, Style.Simple, true))
        .should.be(import("center_simple_header.txt"));
}

string tabulate(TKey, TValue)(in TValue[TKey][] data, in Config config = Config())
{
    string[][] stringData;
    string[] stringHeader;
    foreach (line; data)
    {
        foreach (key, _; line)
        {
            if (!stringHeader.canFind(key.to!string))
            {
                stringHeader ~= key.to!string;
            }
        }
    }

    foreach (line; data)
    {
        string[] lineData;
        foreach (h; stringHeader)
        {
            if (h in line)
            {
                lineData ~= line[h].to!string;
            }
            else
            {
                lineData ~= "";
            }
        }
        stringData ~= lineData;
    }
    return tabulate(stringData, stringHeader, config);
}

@("Check if the tabulate works for associated array.")
unittest
{
    import dshould;

    const testdata = [
        [
            "マスコットキャラクタ": "D-man",
            "about": "Programming Language"
        ],
        [
            "マスコットキャラクタ": "D言語くん",
            "about": "プログラミング言語"
        ],
    ];
    tabulate(testdata, Config(Justify.Center, Style.Simple, true))
        .should.be(import("center_simple_header.txt"));
}

@("Check if the tabulate works for associated array which has lacked data.")
unittest
{
    import dshould;

    const testdata = [
        ["foo": 0.1, "bar": 0.2],
        ["foo": 0.123, "baz": 0.3],
    ];

    tabulate(testdata, Config(Justify.Center, Style.Simple, true))
        .should.be(import("lacked_data_center_simple_header.txt"));
}

private string eacenter(string text, size_t width, char fillChar = ' ')
{
    const textWidth = displayWidth(text);
    if (textWidth >= width)
    {
        return text;
    }
    const rest = width - textWidth;
    const left = rest / 2;
    const right = rest / 2 + rest % 2;
    return format!"%-s%-s%-s"(fillChar.repeat(left), text, fillChar.repeat(right));
}

private string ealeft(string text, size_t width, char fillChar = ' ')
{
    const textWidth = displayWidth(text);
    if (textWidth >= width)
    {
        return text;
    }
    const rest = width - textWidth;
    return format!"%-s%-s"(text, fillChar.repeat(rest));
}

private string earight(string text, size_t width, char fillChar = ' ')
{
    const textWidth = displayWidth(text);
    if (textWidth >= width)
    {
        return text;
    }
    const rest = width - textWidth;
    return format!"%-s%-s"(fillChar.repeat(rest), text);
}

private string makeItemLine(T)(
    in T[] line,
    in size_t[] widthes,
    in Ruler ruler,
    string delegate(string, size_t) justify)
{
    return ruler.left()
        ~ zip(line, widthes)
        .map!(tup => justify(tup[0].to!string, tup[1])).join(ruler.vertical())
        ~ ruler.right();
}

/// Nethack(vi) style function naming
private struct Ruler
{
    Style style;

    enum Index
    {
        HL, // ─
        JK, // │
        JL, // ┌
        HJ, // ┐
        HK, // ┘
        KL, // └
        JKL, // ├
        HJL, // ┬
        HJK, // ┤
        HKL, // ┴
        HJKL, // ┼
    }

    private static immutable string[] simple = [
        "-", " ", "", "", "", "", "", "", "", "", " "
    ];
    private static immutable string[] markdown = [
        "-", "|", "", "", "", "", "|", "", "|", "", "|"
    ];
    private static immutable string[] grid = [
        "─", "│", "┌", "┐", "┘", "└", "├", "┬", "┤", "┴",
        "┼"
    ];

    private immutable(string)[] select() const @nogc nothrow pure
    {
        with (Style) final switch (style)
        {
        case Simple:
            return simple;
        case Markdown:
            return markdown;
        case Grid:
            return grid;
        }
    }

    string get(Index index) const
    {
        const target = select();
        return target[index.to!int];
    }

    string horizontalItemSeperator(const size_t[] widthes) const
    {
        with (Style) final switch (style)
        {
        case Simple, Markdown:
            return null;
        case Grid:
            return makeHorizontal(widthes, get(Index.HL), get(Index.HJKL), get(Index.JKL), get(
                    Index.HJK));
        }
    }

    string headerItemSeperator(const size_t[] widthes) const
    {
        return makeHorizontal(widthes, get(Index.HL), get(Index.HJKL), get(Index.JKL), get(
                Index.HJK));
    }

    string left() const
    {
        with (Style) final switch (style)
        {
        case Simple:
            return "";
        case Markdown, Grid:
            return get(Index.JK);
        }
    }

    string right() const
    {
        with (Style) final switch (style)
        {
        case Simple:
            return "";
        case Markdown, Grid:
            return get(Index.JK);
        }
    }

    string vertical() const
    {
        return get(Index.JK);
    }

    string top(const size_t[] widthes) const
    {
        with (Style) final switch (style)
        {
        case Simple, Markdown:
            return null;
        case Grid:
            return makeHorizontal(widthes, get(Index.HL), get(Index.HJL), get(Index.JL), get(
                    Index.HJ));
        }
    }

    string bottom(const size_t[] widthes) const
    {
        with (Style) final switch (style)
        {
        case Simple, Markdown:
            return null;
        case Grid:
            return makeHorizontal(widthes, get(Index.HL), get(Index.HKL), get(Index.KL), get(
                    Index.HK));
        }
    }

    private static string makeHorizontal(const size_t[] widthes, string h, string p, string l, string r)
    {
        return format!"%-s%-s%-s"(l, widthes.map!(w => h.repeat(w).join()).join(p), r);
    }
}

@("Check if the simple ruler works.")
unittest
{
    import dshould;

    const ruler = Ruler(Style.Simple);
    size_t[] widthes = [1, 2, 3];

    ruler.horizontalItemSeperator(widthes).should.be(null);
    ruler.headerItemSeperator(widthes).should.be("- -- ---");
    ruler.top(widthes).should.be(null);
    ruler.bottom(widthes).should.be(null);
    ruler.left().should.be("");
    ruler.right().should.be("");
    ruler.vertical().should.be(" ");
}

@("Check if the markdown ruler works.")
unittest
{
    import dshould;

    const ruler = Ruler(Style.Markdown);
    size_t[] widthes = [1, 2, 3];

    ruler.horizontalItemSeperator(widthes).should.be(null);
    ruler.headerItemSeperator(widthes).should.be("|-|--|---|");
    ruler.top(widthes).should.be(null);
    ruler.bottom(widthes).should.be(null);
    ruler.left().should.be("|");
    ruler.right().should.be("|");
    ruler.vertical().should.be("|");
}

@("Check if the grid ruler works.")
unittest
{
    import dshould;

    const ruler = Ruler(Style.Grid);
    size_t[] widthes = [1, 2, 3];

    ruler.horizontalItemSeperator(widthes).should.be("├─┼──┼───┤");
    ruler.headerItemSeperator(widthes).should.be("├─┼──┼───┤");
    ruler.top(widthes).should.be("┌─┬──┬───┐");
    ruler.bottom(widthes).should.be("└─┴──┴───┘");
    ruler.left().should.be("│");
    ruler.right().should.be("│");
    ruler.vertical().should.be("│");
}
