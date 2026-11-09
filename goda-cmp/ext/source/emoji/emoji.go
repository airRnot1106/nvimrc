// Package emoji is a port of ddc-emoji (https://github.com/gamoutatsumi/ddc-emoji).
package emoji

//go:generate deno run --allow-write=table.go gen.ts

import (
	"context"
	"strings"
	"sync"

	"github.com/Shougo/goda-cmp.vim/cmp"
	"github.com/Shougo/goda.vim/sdk"
)

type Metadata struct {
	Name  string
	Emoji string
}

var items = sync.OnceValue(func() []cmp.Item {
	out := make([]cmp.Item, len(table))
	for i, m := range table {
		out[i] = cmp.Item{Word: m.Emoji, Abbr: m.Emoji, Kind: m.Name, UserData: m}
	}
	return out
})

type source struct{}

func New() cmp.Source { return source{} }

func (source) Name() string { return "emoji" }

func (source) Gather(_ context.Context, _ sdk.Host, c *cmp.Context) (cmp.Gathered, error) {
	return cmp.Gathered{Start: c.KeywordStart(), Items: items()}, nil
}

type matcher struct{}

func NewMatcher() cmp.Filter { return matcher{} }

func (matcher) Name() string { return "emoji" }

func (matcher) Filter(_ context.Context, in cmp.FilterInput) ([]cmp.Item, error) {
	var out []cmp.Item
	for _, it := range in.Items {
		if m, ok := it.UserData.(Metadata); ok && strings.HasPrefix(m.Name, in.Complete) {
			out = append(out, it)
		}
	}
	return out, nil
}
