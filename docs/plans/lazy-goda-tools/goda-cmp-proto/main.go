package main

import (
	"os"

	"github.com/Shougo/goda-cmp.vim/cmp"
	"github.com/Shougo/goda-cmp.vim/ext/filter/matcherhead"
	"github.com/Shougo/goda-cmp.vim/ext/filter/sortertext"
	"github.com/Shougo/goda-cmp.vim/ext/source/lsp"
	"github.com/Shougo/goda-cmp.vim/ext/ui/pum"
)

func main() {
	b := cmp.New()
	b.AddUI(pum.New())
	src := os.Getenv("LSP_SRC")
	if src == "lua_ls" {
		b.AddSource(lsp.New(lsp.Params{Name: "lua_ls", Command: []string{"lua-language-server"}, Filetypes: []string{"lua"}, RootMarkers: []string{".git"}}))
	} else {
		src = "nvimlsp"
		b.AddSource(nvimLSP{})
	}
	b.AddFilter(matcherhead.New(matcherhead.Params{}))
	b.AddFilter(sortertext.New())
	b.PatchGlobal(cmp.Config{
		UI:      "pum",
		Sources: []string{src},
		SourceOptions: map[string]cmp.SourceOption{
			"_": {Matchers: []string{"matcherhead"}, Sorters: []string{"sortertext"}},
		},
	})
	b.Main()
}
