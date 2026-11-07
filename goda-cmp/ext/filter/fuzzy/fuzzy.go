// Package fuzzy holds the filters matcherfuzzy, sorterfuzzy and
// converterfuzzy, a port of ddc-fuzzy (https://github.com/tani/ddc-fuzzy).
//
// Like the original, the matcher and the sorter are case sensitive unless the
// source option ignoreCase is set. They read Item.Filter(), which is the word
// of the original unless the source set a filter text or matcherKey is used.
package fuzzy

import (
	"context"
	"fmt"
	"log"
	"slices"
	"sync/atomic"

	"github.com/Shougo/goda-cmp.vim/cmp"
)

// SplitMode says which characters of a candidate the typed characters match.
type SplitMode string

const (
	// SplitCharacter matches any character: "abc" matches "axbxc".
	SplitCharacter SplitMode = "character"
	// SplitWord matches where a word begins: "abc" matches "a_bc" and
	// "a_b_c", but not "axbxc".
	SplitWord SplitMode = "word"
)

// MatcherParams are the settings of matcherfuzzy.
type MatcherParams struct {
	// SplitMode is SplitCharacter unless it is SplitWord.
	SplitMode SplitMode `json:"splitMode"`
}

type matcher struct{ p MatcherParams }

// NewMatcher returns the filter named "matcherfuzzy".
func NewMatcher(p MatcherParams) cmp.Filter { return matcher{p} }

func (matcher) Name() string { return "matcherfuzzy" }

// WithParams sets the parameters from Vim script (filterParams).
func (f matcher) WithParams(p cmp.Params) (any, error) {
	np, err := cmp.PatchParams(f.p, p)
	if err != nil {
		return nil, err
	}
	return NewMatcher(np), nil
}

func (f matcher) Filter(_ context.Context, in cmp.FilterInput) ([]cmp.Item, error) {
	test := ctest
	if f.p.SplitMode == SplitWord {
		test = wtest
	}
	pattern := appendUnits(nil, normalize(in.Complete, in.IgnoreCase))
	var out []cmp.Item
	var source units
	for i := range in.Items {
		source = appendUnits(source[:0], normalize(in.Items[i].Filter(), in.IgnoreCase))
		if test(pattern, source) {
			out = append(out, in.Items[i])
		}
	}
	return out, nil
}

type sorter struct{}

// NewSorter returns the filter named "sorterfuzzy": the best matches first,
// and candidates with equal scores in the order they came.
func NewSorter() cmp.Filter { return sorter{} }

func (sorter) Name() string { return "sorterfuzzy" }

func (sorter) Filter(_ context.Context, in cmp.FilterInput) ([]cmp.Item, error) {
	type ranked struct {
		score float64
		index int
	}
	pattern := appendUnits(nil, normalize(in.Complete, in.IgnoreCase))
	ranks := make([]ranked, len(in.Items))
	var c scorer
	var source units
	for i := range in.Items {
		source = appendUnits(source[:0], normalize(in.Items[i].Filter(), in.IgnoreCase))
		ranks[i] = ranked{c.score(pattern, source), i}
	}
	slices.SortStableFunc(ranks, func(a, b ranked) int {
		switch {
		case a.score > b.score:
			return -1
		case a.score < b.score:
			return 1
		}
		return 0
	})
	out := make([]cmp.Item, len(ranks))
	for i, r := range ranks {
		out[i] = in.Items[r.index]
	}
	return out, nil
}

// ConverterParams are the settings of converterfuzzy.
type ConverterParams struct {
	// HlGroup is the highlight group of the matched text (default
	// "FuzzyAccent", linked to Number).
	HlGroup string `json:"hlGroup"`
}

type converter struct {
	p    ConverterParams
	done *atomic.Bool
}

// NewConverter returns the filter named "converterfuzzy".
//
// cmp.Item has no field for the highlights of single characters, which is
// what the original adds to each item. This filter leaves the items as they
// are and gives HlGroup to pum.vim's highlight_matches option instead, so the
// matched text is highlighted from the first to the last typed character.
func NewConverter(p ConverterParams) cmp.Filter {
	if p.HlGroup == "" {
		p.HlGroup = "FuzzyAccent"
	}
	return converter{p, &atomic.Bool{}}
}

func (converter) Name() string { return "converterfuzzy" }

// WithParams sets the parameters from Vim script (filterParams).
func (f converter) WithParams(p cmp.Params) (any, error) {
	np, err := cmp.PatchParams(f.p, p)
	if err != nil {
		return nil, err
	}
	return NewConverter(np), nil
}

func (f converter) Filter(ctx context.Context, in cmp.FilterInput) ([]cmp.Item, error) {
	if in.Host != nil && !f.done.Load() {
		if err := f.setHighlight(ctx, in); err != nil {
			log.Printf("converterfuzzy: %v", err)
		} else {
			f.done.Store(true)
		}
	}
	return in.Items, nil
}

func (f converter) setHighlight(ctx context.Context, in cmp.FilterInput) error {
	if _, err := in.Host.Call(ctx, "execute", "highlight link FuzzyAccent Number"); err != nil {
		return fmt.Errorf("highlight: %w", err)
	}
	if _, err := in.Host.Call(ctx, "pum#set_option", "highlight_matches", f.p.HlGroup); err != nil {
		return fmt.Errorf("pum#set_option: %w", err)
	}
	return nil
}

var (
	_ cmp.Configurable = matcher{}
	_ cmp.Configurable = converter{}
)
