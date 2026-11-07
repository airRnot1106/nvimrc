package fuzzy

import (
	"context"
	"math"
	"os"
	"reflect"
	"strconv"
	"strings"
	"sync"
	"testing"

	"github.com/Shougo/goda-cmp.vim/cmp"
	"github.com/Shougo/goda-cmp.vim/cmp/cmptest"
)

func toItems(words ...string) []cmp.Item {
	items := make([]cmp.Item, len(words))
	for i, w := range words {
		items[i] = cmp.Item{Word: w}
	}
	return items
}

func toWords(items []cmp.Item) []string {
	words := make([]string, len(items))
	for i, it := range items {
		words[i] = it.Word
	}
	return words
}

func run(t testing.TB, f cmp.Filter, in cmp.FilterInput) []cmp.Item {
	t.Helper()
	out, err := f.Filter(context.Background(), in)
	if err != nil {
		t.Fatal(err)
	}
	return out
}

func lines(t testing.TB, path string) []string {
	t.Helper()
	b, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	return strings.Split(strings.TrimSuffix(string(b), "\n"), "\n")
}

// testdata/golden.txt is the output of ddc-fuzzy (see gen_golden.ts).
func TestCandidateOrderEqualsDdcFuzzy(t *testing.T) {
	corpus := lines(t, "testdata/corpus.txt")
	for _, row := range lines(t, "testdata/golden.txt") {
		fields := strings.Split(row, "\t")
		pattern, splitMode := fields[0], SplitMode(fields[2])
		ignoreCase, err := strconv.ParseBool(fields[1])
		if err != nil {
			t.Fatal(err)
		}
		want := []string{}
		for _, index := range strings.Fields(fields[3]) {
			i, err := strconv.Atoi(index)
			if err != nil {
				t.Fatal(err)
			}
			want = append(want, corpus[i])
		}
		t.Run(strings.Join(fields[:3], "/"), func(t *testing.T) {
			in := cmp.FilterInput{Complete: pattern, Items: toItems(corpus...), IgnoreCase: ignoreCase}
			in.Items = run(t, NewMatcher(MatcherParams{SplitMode: splitMode}), in)
			got := toWords(run(t, NewSorter(), in))
			if !reflect.DeepEqual(got, want) {
				t.Errorf("got %d words, want %d\ngot  %.200q\nwant %.200q", len(got), len(want), got, want)
			}
		})
	}
}

func TestMatcherSplitMode(t *testing.T) {
	words := []string{"axbxc", "a_bc", "a_b_c", "xabc"}
	for _, tt := range []struct {
		mode SplitMode
		want []string
	}{
		{"", words},
		{SplitCharacter, words},
		{SplitWord, []string{"a_bc", "a_b_c"}},
	} {
		in := cmp.FilterInput{Complete: "abc", Items: toItems(words...)}
		got := toWords(run(t, NewMatcher(MatcherParams{SplitMode: tt.mode}), in))
		if !reflect.DeepEqual(got, tt.want) {
			t.Errorf("%q: got %q, want %q", tt.mode, got, tt.want)
		}
	}
}

func TestMatcherIsCaseSensitiveWithoutIgnoreCase(t *testing.T) {
	in := cmp.FilterInput{Complete: "foo", Items: toItems("Foo", "foo")}
	if got := toWords(run(t, NewMatcher(MatcherParams{}), in)); !reflect.DeepEqual(got, []string{"foo"}) {
		t.Errorf("got %q", got)
	}
}

func TestMatcherAndSorterReadTheFilterText(t *testing.T) {
	items := []cmp.Item{{Word: "other", FilterText: "abc"}, {Word: "abc", FilterText: "a_b_c"}, {Word: "abc"}}
	in := cmp.FilterInput{Complete: "abc", Items: items}
	in.Items = run(t, NewMatcher(MatcherParams{}), in)
	got := run(t, NewSorter(), in)
	if want := []cmp.Item{items[0], items[2], items[1]}; !reflect.DeepEqual(got, want) {
		t.Errorf("got %+v", got)
	}
}

func TestSorterLeavesTheInputUntouched(t *testing.T) {
	items := toItems("xa", "a")
	run(t, NewSorter(), cmp.FilterInput{Complete: "a", Items: items})
	if items[0].Word != "xa" {
		t.Errorf("items = %q", toWords(items))
	}
}

func TestScore(t *testing.T) {
	for _, tt := range []struct {
		pattern, source string
		want            float64
	}{
		{"", "abc", math.Inf(-1)},
		{"a", "", math.Inf(-1)},
		{"ba", "abc", math.Inf(-1)},
		{"😀", "😀", math.Inf(-1)},
		{"a", "a", 1 + 0.1 + 0.01 + 0.001},
		{"ac", "abc", 0.5 + 0.1 + 1.0/3/100 + 1.0/3/1000},
		// "😀" counts as two characters of the source.
		{"a", "😀a", 1 + 1.0/3/10 + 0.01 + 1.0/3/1000},
	} {
		var c scorer
		got := c.score(appendUnits(nil, tt.pattern), appendUnits(nil, tt.source))
		if math.Abs(got-tt.want) > 1e-12 && got != tt.want {
			t.Errorf("score(%q, %q) = %v, want %v", tt.pattern, tt.source, got, tt.want)
		}
	}
}

func highlightHost() (*cmptest.Host, *sync.Map) {
	var options sync.Map
	return &cmptest.Host{Funcs: map[string]func(...any) (any, error){
		"execute": func(a ...any) (any, error) {
			options.Store("execute", a[0])
			return "", nil
		},
		"pum#set_option": func(a ...any) (any, error) {
			options.Store(a[0], a[1])
			return nil, nil
		},
	}}, &options
}

func TestConverterGivesTheHighlightToPumOnce(t *testing.T) {
	h, options := highlightHost()
	f := NewConverter(ConverterParams{})
	items := toItems("abc")
	for range 2 {
		if got := run(t, f, cmp.FilterInput{Complete: "a", Items: items, Host: h}); !reflect.DeepEqual(got, items) {
			t.Errorf("got %+v", got)
		}
	}
	if got, _ := options.Load("highlight_matches"); got != "FuzzyAccent" {
		t.Errorf("highlight_matches = %v", got)
	}
	if got, _ := options.Load("execute"); got != "highlight link FuzzyAccent Number" {
		t.Errorf("execute = %v", got)
	}
	if n := len(h.Calls()); n != 2 {
		t.Errorf("%d calls, want 2", n)
	}
}

func TestConverterTakesHlGroupFromParams(t *testing.T) {
	h, options := highlightHost()
	f, err := NewConverter(ConverterParams{}).(cmp.Configurable).WithParams(cmp.Params{"hlGroup": "Search"})
	if err != nil {
		t.Fatal(err)
	}
	run(t, f.(cmp.Filter), cmp.FilterInput{Items: toItems("abc"), Host: h})
	if got, _ := options.Load("highlight_matches"); got != "Search" {
		t.Errorf("highlight_matches = %v", got)
	}
}

func TestConverterKeepsTheItemsWithoutPum(t *testing.T) {
	items := toItems("abc")
	got := run(t, NewConverter(ConverterParams{}), cmp.FilterInput{Items: items, Host: &cmptest.Host{}})
	if !reflect.DeepEqual(got, items) {
		t.Errorf("got %+v", got)
	}
}
