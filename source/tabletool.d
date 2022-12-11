module tabletool;

import std.algorithm : canFind, max, min, map;
import std.array : array;
import std.conv : to;
import std.format : format;
import std.range : join, repeat, zip;
import std.traits : getUDAs, hasUDA;
import std.utf;

import eastasianwidth : displayWidth;

/// Option to specify the table style.
enum Style
{
    simple,
    markdown,
    grid,
}

/// Option to specify the position of element in the cell.
enum Align
{
    center,
    left,
    right,
}

/// Configurations for tabulate.
struct Config
{
    Style style = Style.simple;
    Align align_ = Align.center;
    bool showHeader = true;
}

/// UDA to set display name of the struct member.
struct DisplayName
{
    string name;
}

/// Detailed configurations to set table-wide appearance.
struct TableConfig
{
    Style style = Style.simple;
    string leftPadding = " ";
    string rightPadding = " ";
    bool showHeader = true;
}

/// Detailed configurations to set each column appearance.
struct ColumnConfig
{
    size_t width;
    string header = "";
    Align align_ = Align.center;
}

/**
 * Tabulate array of array data.
 * Params:
 *      data = An array of array of string compatible data
 *      headers = Headers for each columns
 *      config = A configuration to set appearance
 * Returns: The table string
 */
string tabulate(T)(in T[][] data, in string[] headers, in Config config = Config())
{
    assert(data.length > 0);
    assert(headers.length == 0 || data[0].length == headers.length);

    auto actualHeaders = headers.length > 0 ? headers : "".repeat(data[0].length).array();
    auto widthes = calcWidthes(data, actualHeaders);

    auto tableConfig = TableConfig();
    tableConfig.style = config.style;
    tableConfig.showHeader = config.showHeader && headers.length > 0;

    auto columnConfigs = zip(widthes, actualHeaders).map!(tup => ColumnConfig(tup[0], tup[1], config
            .align_)).array();

    return tabulate(data, tableConfig, columnConfigs);
}

///
unittest
{
    const testdata = [
        ["D-man", "Programming Language"],
        ["D言語くん", "プログラミング言語"],
    ];
    const headers = ["マスコットキャラクタ", "about"];
    const reference =
        " マスコットキャラクタ          about         \n" ~
        "---------------------- ----------------------\n" ~
        "        D-man           Programming Language \n" ~
        "      D言語くん          プログラミング言語  ";
    assert(tabulate(testdata, headers, Config(Style.simple, Align.center, true)) == reference);
}

/**
 * Tabulate array of array data (headerless version).
 *
 * In this version, config.showHeader will be ignored and header section of the
 * table will be invisible.
 * 
 * Params:
 *      data =  An array of array of string compatible data
 *      config = A configuration to set appearance
 * Returns: The table string
 */
string tabulate(T)(in T[][] data, in Config config = Config())
{
    return tabulate(data, [], config);
}

/// 
unittest
{
    const testdata = [
        ["D-man", "Programming Language"],
        ["D言語くん", "プログラミング言語"],
    ];
    const reference =
        "   D-man     Programming Language \n" ~
        " D言語くん    プログラミング言語  ";
    assert(tabulate(testdata, Config(Style.simple, Align.center, true)) == reference);
}

/**
 * Tabulate array of strut data.
 *
 * This version consume an array of struct. The headers will be extrated from
 * members' name and each member should be able to convert to string. If some
 * of members need to be re-named, an UDA DisplayName can be used.
 * 
 * Params:
 *      data = An array of struct data
 *      config = A configuration to set appearance
 * Returns: The table string
 */
string tabulate(T)(in T[] data, in Config config = Config()) if (is(T == struct))
{
    string[][] stringData;
    string[] headers;

    foreach (member; __traits(allMembers, T))
    {
        static if (hasUDA!(__traits(getMember, T, member), DisplayName))
        {
            enum displayName = getUDAs!(__traits(getMember, T, member), DisplayName)[0];
            headers ~= displayName.name;
        }
        else
        {
            headers ~= member;
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
    return tabulate(stringData, headers, config);
}

///
unittest
{
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
    const reference =
        " マスコットキャラクタ          about         \n" ~
        "---------------------- ----------------------\n" ~
        "        D-man           Programming Language \n" ~
        "      D言語くん          プログラミング言語  ";

    assert(tabulate(testdata, Config(Style.simple, Align.center, true)) == reference);
}

/**
 * Tabulate an array of associative array.
 *
 * This version tabulates an array of associative array. The keys will be used
 * as headers and there is no need to align each keys of each array elements.
 * If some missing key exists in the one line, that cell will be empty.
 *
 * Params:
 *      data = An array of associative array data
 *      config = A configuration to set appearance
 * Returns: The table string
 */
string tabulate(Key, Value)(in Value[Key][] data, in Config config = Config())
{
    string[][] stringData;
    Key[] headers;
    foreach (line; data)
    {
        foreach (key; line.byKey())
        {
            if (!headers.canFind(key))
            {
                headers ~= key;
            }
        }
    }
    foreach (line; data)
    {
        string toStr(Key h)
        {
            if (h in line)
            {
                return line[h].to!string;
            }
            else
            {
                return "";
            }
        }

        stringData ~= headers.map!(h => toStr(h)).array();
    }
    string[] stringHeaders = headers.map!(h => h.to!string).array();
    return tabulate(stringData, stringHeaders, config);
}

///
unittest
{
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
    const reference =
        " マスコットキャラクタ          about         \n" ~
        "---------------------- ----------------------\n" ~
        "        D-man           Programming Language \n" ~
        "      D言語くん          プログラミング言語  ";
    assert(tabulate(testdata, Config(Style.simple, Align.center, true)) == reference);
}

/**
 * Tabulate an array of array data with detailed configurations.
 * 
 * This version uses TableConfig and an array of ColumnConfig instead of Config.
 * TableConfig affects the whole table appearance and ColumnConfigs affect each
 * columns' appearance. This can be used if you want to configure (e.g.)
 * columns one-by-one.
 * 
 * Params:
 *      data = An array of array data
 *      tableConfig = A table-wide configuration
 *      columnConfigs = Configurations for each columns (The length should match with data)
 * Returns: The table string
 */
string tabulate(T)(in T[][] data, in TableConfig tableConfig, in ColumnConfig[] columnConfigs)
{
    assert(data.length > 0);
    assert(data[0].length == columnConfigs.length);

    const ruler = Ruler(tableConfig.style);
    const widthes = columnConfigs.map!(c => c.width).array();
    const aligns = columnConfigs.map!(c => c.align_).array();
    const widthForRuler = widthes.map!(w => w + displayWidth(
            tableConfig.leftPadding) + displayWidth(tableConfig.rightPadding)).array();

    string[] lines;

    if (auto top = ruler.top(widthForRuler))
    {
        lines ~= top;
    }

    if (tableConfig.showHeader)
    {
        const headers = columnConfigs.map!(c => c.header).array();
        lines ~= makeItemLine(
            headers,
            widthes,
            aligns,
            ruler,
            tableConfig.leftPadding,
            tableConfig.rightPadding
        );
        if (auto sep = ruler.headerItemSeperator(widthForRuler))
        {
            lines ~= sep;
        }
    }
    foreach (i, line; data)
    {
        lines ~= makeItemLine(
            line,
            widthes,
            aligns,
            ruler,
            tableConfig.leftPadding,
            tableConfig.rightPadding,
        );
        if ((i + 1) != data.length)
        {
            if (auto sep = ruler.horizontalItemSeperator(widthForRuler))
            {
                lines ~= sep;
            }
        }
    }
    if (auto bottom = ruler.bottom(widthForRuler))
    {
        lines ~= bottom;
    }

    return lines.join("\n");
}

///
unittest
{
    const testdata = [
        ["D-man", "Programming Language"],
        ["D言語くん", "プログラミング言語"],
    ];
    const tableConfig = TableConfig(Style.simple, " ", " ", true);
    const columnConfigs = [
        ColumnConfig(20, "マスコットキャラクタ", Align.center),
        ColumnConfig(10, "about", Align.center)
    ];
    const reference =
        " マスコットキャラクタ     about    \n" ~
        "---------------------- ------------\n" ~
        "        D-man           ..ming L.. \n" ~
        "      D言語くん         ..ラミン.. ";
    assert(tabulate(testdata, tableConfig, columnConfigs) == reference);
}

private string alignment(string text, Align align_, size_t width)
{
    static immutable dotTable = ["", ".", ".."];
    if (width == 0)
    {
        return "";
    }
    const textWidth = displayWidth(text);
    if (textWidth > width)
    {
        with (Align) final switch (align_)
        {
        case left:
            return cutRight(text, width.to!int - 2) ~ dotTable[min(width, 2)];
        case right:
            return dotTable[min(width, 2)] ~ cutLeft(text, width.to!int - 2);
        case center:
            const c = cutBoth(text, width.to!int - 4);
            const l = min(width / 2, 2);
            const r = min(width / 2 + width % 2, 2);
            return dotTable[l] ~ c ~ dotTable[r];
        }
    }
    else
    {
        with (Align) final switch (align_)
        {
        case left:
            return format!"%-s%-s"(text, ' '.repeat(width - textWidth));
        case right:
            return format!"%-s%-s"(' '.repeat(width - textWidth), text);
        case center:
            const l = (width - textWidth) / 2;
            const r = (width - textWidth) / 2 + (width - textWidth) % 2;
            return format!"%-s%-s%-s"(' '.repeat(l), text, ' '.repeat(r));
        }
    }
}

private string cutRight(string text, int width)
{
    if (width <= 0)
    {
        return "";
    }
    for (int c = count(text).to!int - 1; displayWidth(text) > width; c--)
    {
        text = text[0 .. toUTFindex(text, c)];
    }
    return width > displayWidth(text) ? text ~ "." : text;
}

private string cutLeft(string text, int width)
{
    if (width <= 0)
    {
        return "";
    }
    while (displayWidth(text) > width)
    {
        text = text[toUTFindex(text, 1) .. $];
    }
    return width > displayWidth(text) ? "." ~ text : text;
}

private string cutBoth(string text, int width)
{
    if (width <= 0)
    {
        return "";
    }
    bool cutLeftSide = false;
    while (displayWidth(text) > width)
    {
        if (cutLeftSide)
        {
            text = text[toUTFindex(text, 1) .. $];
        }
        else
        {
            text = text[0 .. toUTFindex(text, count(text).to!int - 1)];
        }
        cutLeftSide = !cutLeftSide;
    }
    return width > displayWidth(text) ? text ~ "." : text;
}

unittest
{
    string a = "こんにちは";

    assert(alignment(a, Align.left, 12) == "こんにちは  ");
    assert(alignment(a, Align.left, 11) == "こんにちは ");
    assert(alignment(a, Align.left, 10) == "こんにちは");
    assert(alignment(a, Align.left, 9) == "こんに...");
    assert(alignment(a, Align.left, 8) == "こんに..");
    assert(alignment(a, Align.left, 3) == "...");
    assert(alignment(a, Align.left, 2) == "..");
    assert(alignment(a, Align.left, 1) == ".");
    assert(alignment(a, Align.left, 0) == "");

    assert(alignment(a, Align.center, 12) == " こんにちは ");
    assert(alignment(a, Align.center, 11) == "こんにちは ");
    assert(alignment(a, Align.center, 10) == "こんにちは");
    assert(alignment(a, Align.center, 9) == "..んに...");
    assert(alignment(a, Align.center, 8) == "..んに..");
    assert(alignment(a, Align.center, 5) == ".....");
    assert(alignment(a, Align.center, 4) == "....");
    assert(alignment(a, Align.center, 3) == "...");
    assert(alignment(a, Align.center, 2) == "..");
    assert(alignment(a, Align.center, 1) == ".");
    assert(alignment(a, Align.center, 0) == "");

    assert(alignment(a, Align.right, 12) == "  こんにちは");
    assert(alignment(a, Align.right, 11) == " こんにちは");
    assert(alignment(a, Align.right, 10) == "こんにちは");
    assert(alignment(a, Align.right, 9) == "...にちは");
    assert(alignment(a, Align.right, 8) == "..にちは");
    assert(alignment(a, Align.right, 3) == "...");
    assert(alignment(a, Align.right, 2) == "..");
    assert(alignment(a, Align.right, 1) == ".");
    assert(alignment(a, Align.right, 0) == "");
}

private string makeItemLine(T)(
    in T[] line,
    in size_t[] widthes,
    in Align[] aligns,
    in Ruler ruler,
    in string leftPadding,
    in string rightPadding,
)
{
    return ruler.left()
        ~ zip(line, aligns, widthes)
        .map!(tup => leftPadding ~ alignment(tup[0].to!string, tup[1], tup[2]) ~ rightPadding)
        .join(ruler.vertical())
        ~ ruler.right();
}

unittest
{
    string[] line = ["a", "ab", "abc", "abcd", "abcde"];
    size_t[] widthes = [6, 5, 4, 3, 2];
    Ruler ruler = Ruler(Style.markdown);
    string leftPadding = "*";
    string rightPadding = "^^";
    Align[] aligns = [
        Align.left, Align.right, Align.center, Align.left, Align.right
    ];
    assert(makeItemLine(line, widthes, aligns, ruler, leftPadding, rightPadding)
            == "|*a     ^^|*   ab^^|*abc ^^|*a..^^|*..^^|");
}

private size_t[] calcWidthes(T)(in T[][] data, in string[] headers)
{
    assert(data.length > 0);
    assert(data[0].length == headers.length);

    auto widthes = headers.map!(h => displayWidth(h)).array();

    foreach (line; data)
    {
        assert(line.length == widthes.length);
        foreach (i; 0 .. widthes.length)
        {
            widthes[i] = max(widthes[i], displayWidth(line[i]));
        }
    }
    return widthes;
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

    private static immutable string[] simpleLiterals = [
        "-", " ", "", "", "", "", "", "", "", "", " "
    ];
    private static immutable string[] markdownLiterals = [
        "-", "|", "", "", "", "", "|", "", "|", "", "|"
    ];
    private static immutable string[] gridLiterals = [
        "─", "│", "┌", "┐", "┘", "└", "├", "┬", "┤", "┴",
        "┼"
    ];

    private immutable(string)[] select() const @nogc nothrow pure
    {
        with (Style) final switch (style)
        {
        case simple:
            return simpleLiterals;
        case markdown:
            return markdownLiterals;
        case grid:
            return gridLiterals;
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
        case simple, markdown:
            return null;
        case grid:
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
        case simple:
            return "";
        case markdown, grid:
            return get(Index.JK);
        }
    }

    string right() const
    {
        with (Style) final switch (style)
        {
        case simple:
            return "";
        case markdown, grid:
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
        case simple, markdown:
            return null;
        case grid:
            return makeHorizontal(widthes, get(Index.HL), get(Index.HJL), get(Index.JL), get(
                    Index.HJ));
        }
    }

    string bottom(const size_t[] widthes) const
    {
        with (Style) final switch (style)
        {
        case simple, markdown:
            return null;
        case grid:
            return makeHorizontal(widthes, get(Index.HL), get(Index.HKL), get(Index.KL), get(
                    Index.HK));
        }
    }

    private static string makeHorizontal(const size_t[] widthes, string h, string p, string l, string r)
    {
        return format!"%-s%-s%-s"(l, widthes.map!(w => h.repeat(w).join()).join(p), r);
    }
}

unittest
{
    const ruler = Ruler(Style.simple);
    size_t[] widthes = [1, 2, 3];

    assert(ruler.horizontalItemSeperator(widthes) is null);
    assert(ruler.headerItemSeperator(widthes) == "- -- ---");
    assert(ruler.top(widthes) is null);
    assert(ruler.bottom(widthes) is null);
    assert(ruler.left() == "");
    assert(ruler.right() == "");
    assert(ruler.vertical() == " ");
}

unittest
{
    const ruler = Ruler(Style.markdown);
    size_t[] widthes = [1, 2, 3];

    assert(ruler.horizontalItemSeperator(widthes) is null);
    assert(ruler.headerItemSeperator(widthes) == "|-|--|---|");
    assert(ruler.top(widthes) is null);
    assert(ruler.bottom(widthes) is null);
    assert(ruler.left() == "|");
    assert(ruler.right() == "|");
    assert(ruler.vertical() == "|");
}

unittest
{
    const ruler = Ruler(Style.grid);
    size_t[] widthes = [1, 2, 3];

    assert(ruler.horizontalItemSeperator(widthes) == "├─┼──┼───┤");
    assert(ruler.headerItemSeperator(widthes) == "├─┼──┼───┤");
    assert(ruler.top(widthes) == "┌─┬──┬───┐");
    assert(ruler.bottom(widthes) == "└─┴──┴───┘");
    assert(ruler.left() == "│");
    assert(ruler.right() == "│");
    assert(ruler.vertical() == "│");
}
