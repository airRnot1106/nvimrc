import { Plugin } from "@shougo/dpp-vim/types";
import type { Parser } from "./parser.ts";
import type { Transformer } from "./transformer.ts";

type Fields = {
  [K in keyof Plugin]: Transformer<Plugin[K]>;
};

export interface Builder<T> {
  build(source: string): T | Promise<T>;
}

export function createPluginBuilder(
  parsers: Parser[],
  fields: Fields,
): Builder<Plugin> {
  return {
    async build(source: string): Promise<Plugin> {
      const results = await Promise.all(
        parsers.map((p) => Promise.resolve(p.parse(source))),
      );
      const raw = Object.assign({}, ...results) as Record<string, string>;
      const plugin: Record<string, unknown> = {};
      for (const [key, transformer] of Object.entries(fields)) {
        const value = raw[key];
        if (value !== undefined && transformer) {
          plugin[key] = transformer.transform(value);
        }
      }
      return plugin as Plugin;
    },
  };
}
