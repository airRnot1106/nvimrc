export interface Transformer<T> {
  transform(value: string): T;
}

/**
 * 入力をそのまま出力する Transformer
 */
export function passThrough(): Transformer<string> {
  return { transform: (v) => v };
}

/**
 * Boolean 文字列をパースしてそのまま返す Transformer
 */
export function toBoolean(): Transformer<boolean> {
  return { transform: (v) => v === "true" };
}

/**
 * `function(...) ... end` リテラルからボディだけを取り出す Transformer
 */
export function extractFunctionBody(): Transformer<string> {
  return {
    transform(v: string): string {
      const afterArgs = v.indexOf(")") + 1;
      const withoutEnd = v.replace(/\s*\bend\b\s*,?\s*$/, "");
      return withoutEnd.slice(afterArgs).trim();
    },
  };
}

/**
 * JSON 文字列をパースしてそのまま返す Transformer
 */
export function toJsonValue<T>(): Transformer<T> {
  return {
    transform(v: string): T {
      try {
        return JSON.parse(v) as T;
      } catch {
        return v as unknown as T;
      }
    },
  };
}

/**
 * JSON 文字列を string[] に変換する Transformer
 */
export function toStringArray(): Transformer<string[]> {
  return {
    transform(v: string): string[] {
      try {
        const parsed = JSON.parse(v);
        return Array.isArray(parsed)
          ? parsed.filter((x): x is string => typeof x === "string")
          : [v];
      } catch {
        return [v];
      }
    },
  };
}
