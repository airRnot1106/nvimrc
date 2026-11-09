package fuzzy

import (
	"context"
	"os"
	"strings"
	"testing"

	"github.com/Shougo/goda-cmp.vim/cmp"
)

func BenchmarkChain(b *testing.B) {
	path := os.Getenv("FUZZY_BENCH_WORDS")
	if path == "" {
		b.Skip("FUZZY_BENCH_WORDS is not set")
	}
	items := toItems(lines(b, path)...)
	matcher, sorter, converter := NewMatcher(MatcherParams{}), NewSorter(), NewConverter(ConverterParams{})
	ctx := context.Background()
	for _, pattern := range strings.Fields(os.Getenv("FUZZY_BENCH_PATTERNS")) {
		b.Run(pattern, func(b *testing.B) {
			for b.Loop() {
				in := cmp.FilterInput{Complete: pattern, Items: items}
				in.Items, _ = matcher.Filter(ctx, in)
				in.Items, _ = sorter.Filter(ctx, in)
				in.Items = in.Items[:min(len(in.Items), 500)]
				_, _ = converter.Filter(ctx, in)
			}
		})
	}
}
