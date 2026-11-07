// Package emoji is a source that offers emoji by their names, and the matcher
// for it. It is a port of ddc-emoji (https://github.com/gamoutatsumi/ddc-emoji).
//
// Every name begins with a colon, as in ":smile:", so the source needs a
// keywordPattern that keeps the colon, such as `[a-zA-Z_:]\w*`.
package emoji

//go:generate deno run --allow-write=table.go gen.ts

import (
	"context"
	"strings"
	"sync"

	"github.com/Shougo/goda-cmp.vim/cmp"
	"github.com/Shougo/goda.vim/sdk"
)

// Metadata is the UserData of the items.
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

// New returns the source, named "emoji". It offers every emoji and leaves the
// choice to NewMatcher.
func New() cmp.Source { return source{} }

func (source) Name() string { return "emoji" }

func (source) Gather(_ context.Context, _ sdk.Host, c *cmp.Context) (cmp.Gathered, error) {
	return cmp.Gathered{Start: c.KeywordStart(), Items: items()}, nil
}

type matcher struct{}

// NewMatcher returns the filter named "emoji": the items of this source whose
// name starts with the typed text.
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
