package main

import (
	"github.com/Shougo/goda-cmp.vim/cmp"
	"github.com/Shougo/goda-cmp.vim/ext/filter/sortercmdlinehistory"
	"github.com/Shougo/goda-cmp.vim/ext/source/around"
	"github.com/Shougo/goda-cmp.vim/ext/source/buffer"
	"github.com/Shougo/goda-cmp.vim/ext/source/cmdline"
	"github.com/Shougo/goda-cmp.vim/ext/source/cmdlinehistory"
	"github.com/Shougo/goda-cmp.vim/ext/source/file"
	"github.com/Shougo/goda-cmp.vim/ext/source/mocword"
	"github.com/Shougo/goda-cmp.vim/ext/ui/pum"

	"github.com/airRnot1106/goda-cmp-source-maccy/ext/source/maccy"
	"github.com/airRnot1106/goda-cmp-source-nvimlsp/ext/source/nvimlsp"
	"goda-cmp-config/ext/filter/fuzzy"
	"goda-cmp-config/ext/source/copilot"
	"goda-cmp-config/ext/source/rg"
)

const pathKeywordPattern = `[a-zA-Z0-9_.~-]*/[a-zA-Z0-9_.~/-]*`

func main() {
	b := cmp.New()
	b.AddUI(pum.New())

	b.AddSource(maccy.New(maccy.Params{
		RecentMs:            30000,
		CacheTtlMs:          2000,
		Types:               []string{"public.utf8-plain-text"},
		DBPath:              "~/Library/Containers/org.p0deje.Maccy/Data/Library/Application Support/Maccy/Storage.sqlite",
		MaxByteLength:       10000,
		Dedupe:              true,
		TrimTrailingNewline: true,
		ExcludeAfterUse:     true,
		MaxUseCount:         1,
	}))
	b.AddSource(copilot.New(copilot.Params{Copilot: "lua"}))
	b.AddSource(nvimlsp.New(nvimlsp.Params{EnableResolveItem: true, EnableAdditionalTextEdit: true}))
	b.AddSource(around.New(around.Params{}))
	b.AddSource(buffer.New(buffer.Params{
		RequireSameFiletype: new(false),
		LimitBytes:          5000000,
		FromAltBuf:          true,
		ForceCollect:        true,
	}))
	b.AddSource(rg.New(rg.Params{}))
	b.AddSource(mocword.New(mocword.Params{}))
	b.AddSource(file.New(file.Params{}))
	b.AddSource(cmdline.New())
	b.AddSource(cmdlinehistory.New(cmdlinehistory.Params{}))

	b.AddFilter(fuzzy.NewMatcher(fuzzy.MatcherParams{}))
	b.AddFilter(fuzzy.NewSorter())
	b.AddFilter(fuzzy.NewConverter(fuzzy.ConverterParams{}))
	b.AddFilter(sortercmdlinehistory.New(sortercmdlinehistory.Params{}))

	b.PatchGlobal(cmp.Config{
		UI: "pum",
		// Moving between candidates that differ by a trailing character looks like a backspace, which closes the popup otherwise.
		BackspaceCompletion: new(true),
		AutoCompleteEvents: []string{
			"CmdlineChanged",
			"CmdlineEnter",
			"InsertEnter",
			"TextChangedI",
			"TextChangedP",
		},
		Sources: []string{"maccy", "copilot", "nvimlsp", "around", "buffer", "rg", "mocword", "file"},
		CmdlineSources: map[string][]string{
			":": {"cmdline", "cmdlinehistory", "rg", "file"},
		},
		SourceOptions: map[string]cmp.SourceOption{
			"_": {
				Matchers:              []string{"matcherfuzzy"},
				Sorters:               []string{"sorterfuzzy"},
				Converters:            []string{"converterfuzzy"},
				MinAutoCompleteLength: new(2),
				MaxItems:              new(500),
			},
			"around": {Mark: "[A]"},
			"buffer": {Mark: "[B]"},
			"cmdline": {
				Mark:                  "[C]",
				MinAutoCompleteLength: new(1),
			},
			"cmdlinehistory": {
				Mark:                  "history",
				MaxItems:              new(10),
				Sorters:               []string{"sortercmdlinehistory"},
				MinAutoCompleteLength: new(1),
			},
			"copilot": {
				Mark:                  "[Copilot]",
				Matchers:              []string{},
				MinAutoCompleteLength: new(0),
				IsVolatile:            new(true),
				Timeout:               new(5000),
			},
			"file": {
				Mark:                   "[F]",
				MaxItems:               new(3),
				IsVolatile:             new(true),
				KeywordPattern:         pathKeywordPattern,
				ForceCompletionPattern: `\S/\S*`,
				MinAutoCompleteLength:  new(1),
			},
			"maccy": {
				Mark:                  "[Maccy]",
				MaxItems:              new(3),
				Matchers:              []string{},
				Sorters:               []string{},
				Converters:            []string{},
				IsVolatile:            new(true),
				MinAutoCompleteLength: new(0),
			},
			"nvimlsp": {
				Mark:                   "[LSP]",
				IsVolatile:             new(true),
				ForceCompletionPattern: `\.\w*|:\w*|->\w*`,
			},
			"mocword": {
				Mark:                  "[M]",
				MaxItems:              new(8),
				IsVolatile:            new(true),
				KeywordPattern:        `[a-zA-Z]+(?: +[a-zA-Z]*)*`,
				MinAutoCompleteLength: new(3),
			},
			"rg": {
				Mark:                  "[R]",
				MinAutoCompleteLength: new(4),
			},
		},
	})

	b.Main()
}
