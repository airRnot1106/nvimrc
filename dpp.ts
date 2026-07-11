import { dirname, fromFileUrl, join } from "@std/path";
import {
  BaseConfig,
  ConfigArguments,
  ConfigReturn,
} from "@shougo/dpp-vim/config";
import { Plugin } from "@shougo/dpp-vim/types";
import type { LazyMakeStateResult } from "@shougo/dpp-ext-lazy";
import { flexibleParser, functionParser } from "./lib/parser.ts";
import {
  extractFunctionBody,
  passThrough,
  toBoolean,
  toJsonValue,
  toStringArray,
} from "./lib/transformer.ts";
import { createPluginBuilder } from "./lib/builder.ts";

const selfPath = fromFileUrl(import.meta.url);
const configDir = dirname(selfPath);
const pluginsDir = join(configDir, "lua/plugins");
const libDir = join(configDir, "lib");

export class Config extends BaseConfig {
  override async config(args: ConfigArguments): Promise<ConfigReturn> {
    args.contextBuilder.setGlobal({
      protocols: ["git"],
      extParams: {
        installer: {
          minCommitDays: 7,
          maxInactiveDays: 180,
        },
      },
    });

    const plugins: Plugin[] = [];
    const checkFiles = [selfPath, pluginsDir, libDir];

    for await (const entry of Deno.readDir(libDir)) {
      if (!entry.name.endsWith(".ts")) continue;
      checkFiles.push(join(libDir, entry.name));
    }

    for await (const entry of Deno.readDir(pluginsDir)) {
      if (!entry.name.endsWith(".lua")) continue;
      const filePath = join(pluginsDir, entry.name);
      checkFiles.push(filePath);
      const source = await Deno.readTextFile(filePath);

      const builder = createPluginBuilder(
        [flexibleParser(args.denops, filePath), functionParser()],
        {
          name: passThrough(),
          repo: passThrough(),
          rev: passThrough(),
          depends: toStringArray(),
          if: toBoolean(),
          lazy: toBoolean(),
          on_cmd: toJsonValue(),
          on_event: toJsonValue(),
          on_ft: toJsonValue(),
          on_map: toJsonValue(),
          lua_add: extractFunctionBody(),
          lua_source: extractFunctionBody(),
          extAttrs: toJsonValue(),
        },
      );

      const plugin = await builder.build(source);

      plugins.push(plugin);
    }

    const [context, options] = await args.contextBuilder.get(args.denops);

    const lazyResult = await args.dpp.extAction(
      args.denops,
      context,
      options,
      "lazy",
      "makeState",
      { plugins },
    ) as LazyMakeStateResult | undefined;
    const stateLines = lazyResult?.stateLines ?? [];

    return { plugins, stateLines, checkFiles };
  }
}
