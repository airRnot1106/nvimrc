import type { Denops } from "@denops/std";

export interface Parser {
  parse(
    source: string,
  ): Record<string, string> | Promise<Record<string, string>>;
}

/**
 * Neovim の luaeval + dofile で Lua テーブルを評価し、
 * 関数値を除いた全フィールドを文字列にシリアライズして返す Parser
 */
export function flexibleParser(denops: Denops, filePath: string): Parser {
  return {
    async parse() {
      const r = await denops.call(
        "luaeval",
        `(function()
            local ok, t = pcall(dofile, [[${filePath}]])
            if not ok or type(t) ~= "table" then return {} end
            for k, v in pairs(t) do
              if type(v) == "function" then t[k] = nil end
            end
            return t
          end)()`,
      );
      const table = (r ?? {}) as Record<string, unknown>;
      const result: Record<string, string> = {};
      for (const [k, v] of Object.entries(table)) {
        if (v === null || v === undefined) continue;
        result[k] = typeof v === "string" ? v : JSON.stringify(v);
      }
      return result;
    },
  };
}

/**
 * `key = function(...) ... end` のリテラルを抽出する Parser
 */
export function functionParser(): Parser {
  function extractLiteral(source: string, key: string): string | undefined {
    const lines = source.split("\n");

    let startLine = -1;
    let funcStart = -1;
    for (let i = 0; i < lines.length; i++) {
      const m = new RegExp(`\\b${key}\\s*=\\s*(function)`).exec(lines[i]);
      if (m) {
        startLine = i;
        funcStart = m.index + m[0].length - "function".length;
        break;
      }
    }
    if (startLine < 0) return undefined;

    // `end` で閉じる Lua ブロックの開始キーワードを数える
    // for/while はそれぞれの `do` で開くため、function/if/do を見る
    const openers = /\b(?:function|if|do)\b/g;
    let depth = 0;
    const parts: string[] = [];
    for (let i = startLine; i < lines.length; i++) {
      const line = i === startLine ? lines[i].slice(funcStart) : lines[i];
      depth += (line.match(openers) ?? []).length;
      depth -= (line.match(/\bend\b/g) ?? []).length;
      parts.push(line);
      if (depth === 0) break;
    }

    return parts.join("\n").trim() || undefined;
  }

  return {
    parse(source: string) {
      const result: Record<string, string> = {};
      for (const key of ["lua_add", "lua_source"] as const) {
        const literal = extractLiteral(source, key);
        if (literal !== undefined) result[key] = literal;
      }
      return result;
    },
  };
}
