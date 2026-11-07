// Writes the order of the candidates ddc-fuzzy gives for corpus.txt.
// Usage: deno run -A --cached-only gen_golden.ts <ddc-fuzzy> <corpus> <golden>
const [root, corpus, golden] = Deno.args;
const { Filter: Matcher } = await import(
  `${root}/denops/@ddc-filters/matcher_fuzzy.ts`
);
const { Filter: Sorter } = await import(
  `${root}/denops/@ddc-filters/sorter_fuzzy.ts`
);

const patterns = [
  "",
  "a",
  "e",
  "_",
  "fi",
  "fn",
  "ab",
  "aaa",
  "bab",
  "fil",
  "str",
  "get",
  "lsp",
  "xyz",
  "conf",
  "func",
  "comp",
  "nvim",
  "gcb",
  "eee",
  "e_e",
  "Conf",
  "FILE",
  "fName",
  "tion",
  "strng",
  "configuration",
  "の",
  "日本",
  "テスト",
  "😀",
  "s😀",
];

const words = Deno.readTextFileSync(corpus).split("\n").filter((w) => w !== "");
const rows: string[] = [];
for (const pattern of patterns) {
  for (const ignoreCase of [false, true]) {
    for (const splitMode of ["character", "word"]) {
      const args = {
        completeStr: pattern,
        sourceOptions: { ignoreCase },
        filterParams: { splitMode },
      };
      const items = words.map((word, index) => ({ word, index }));
      const matched = await new Matcher().filter({ ...args, items });
      const sorted = await new Sorter().filter({ ...args, items: matched });
      const order = sorted.map((item: { index: number }) => item.index);
      rows.push(
        [pattern, ignoreCase, splitMode, order.join(" ")].join("\t") + "\n",
      );
    }
  }
}
Deno.writeTextFileSync(golden, rows.join(""));
