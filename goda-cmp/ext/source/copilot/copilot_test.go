package copilot

import (
	"context"
	"reflect"
	"strings"
	"testing"
	"time"

	"github.com/Shougo/goda-cmp.vim/cmp"
	"github.com/Shougo/goda-cmp.vim/cmp/cmptest"
)

// answering is a luaeval whose poll is pending for the given number of calls,
// then returns answer.
func answering(pending int, answer any) *cmptest.Host {
	return &cmptest.Host{Funcs: map[string]func(...any) (any, error){
		"luaeval": func(a ...any) (any, error) {
			if !strings.Contains(a[0].(string), ".poll(") {
				return nil, nil
			}
			if pending > 0 {
				pending--
				return nil, nil
			}
			return answer, nil
		},
	}}
}

func gather(t *testing.T, h *cmptest.Host, c *cmp.Context) []cmp.Gathered {
	t.Helper()
	var emitted []cmp.Gathered
	err := New(Params{Copilot: "lua"}).(source).GatherStream(context.Background(), h, c, func(g cmp.Gathered) error {
		emitted = append(emitted, g)
		return nil
	})
	if err != nil {
		t.Fatal(err)
	}
	return emitted
}

func TestGatherStreamEmitsAnEmptyListBeforeTheAnswer(t *testing.T) {
	h := answering(2, []any{"  foo(bar)"})
	got := gather(t, h, &cmp.Context{Input: "  fo", Seq: 7})
	if len(got) != 2 || len(got[0].Items) != 0 {
		t.Fatalf("emitted %+v", got)
	}
	want := []cmp.Item{{Word: "foo(bar)", Info: "foo(bar)"}}
	if !reflect.DeepEqual(got[1].Items, want) || got[1].Start != 2 {
		t.Errorf("answer %+v", got[1])
	}
	if !got[0].Incomplete || !got[1].Incomplete {
		t.Errorf("not incomplete: %+v", got)
	}
	if calls := h.Calls(); !reflect.DeepEqual(calls[0].Args[1], int64(7)) {
		t.Errorf("request %+v", calls[0])
	}
}

func TestGatherStreamWithoutSuggestionsEmitsNoItems(t *testing.T) {
	got := gather(t, answering(0, []any{}), &cmp.Context{Input: "fo"})
	if len(got) != 2 || len(got[1].Items) != 0 {
		t.Errorf("emitted %+v", got)
	}
}

func TestGatherStreamStopsWhenTheContextEnds(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 3*pollInterval)
	defer cancel()
	begin := time.Now()
	err := New(Params{Copilot: "lua"}).(source).GatherStream(ctx, answering(1<<30, nil), &cmp.Context{Input: "fo"},
		func(cmp.Gathered) error { return nil })
	if err != context.DeadlineExceeded {
		t.Errorf("err %v after %v", err, time.Since(begin))
	}
}

func TestGatherWithoutTheLuaIntegrationAsksNothing(t *testing.T) {
	h := &cmptest.Host{}
	g, err := New(Params{Copilot: "vim"}).Gather(context.Background(), h, &cmp.Context{Input: "fo"})
	if err != nil || len(g.Items) != 0 || len(h.Calls()) != 0 {
		t.Errorf("%+v %v, calls %+v", g, err, h.Calls())
	}
}

func TestItemOfSeveralLinesIsShownOnOneLine(t *testing.T) {
	it := item("    if x {\n\t  y()\n    }", 4)
	want := cmp.Item{
		Word:     "if x {??  y()?    }",
		Abbr:     "if x {^J^I  y()^J    }",
		Info:     "if x {\n()\n}",
		UserData: "if x {\n\t  y()\n    }",
	}
	if !reflect.DeepEqual(it, want) {
		t.Errorf("got %+v, want %+v", it, want)
	}
}

func TestItemStartsAtTheByteOffsetOfMultibyteInput(t *testing.T) {
	if it := item("日本語foo", len("日本語")); it.Word != "foo" {
		t.Errorf("word %q", it.Word)
	}
}

func TestItemBeyondTheSuggestionHasAnEmptyWord(t *testing.T) {
	if it := item("ab", 5); it.Word != "" {
		t.Errorf("word %q", it.Word)
	}
}

func TestOnCompleteDoneReplacesThePlaceholderWithTheLines(t *testing.T) {
	h := answering(0, nil)
	it := item("foo\n  bar", 0)
	if err := New(Params{}).(source).OnCompleteDone(context.Background(), h, cmp.DoneArgs{Item: it}); err != nil {
		t.Fatal(err)
	}
	want := []any{"foo?  bar", []string{"foo", "  bar"}}
	if calls := h.Calls(); len(calls) != 1 || !reflect.DeepEqual(calls[0].Args[1], want) {
		t.Errorf("calls %+v", calls)
	}
}

func TestOnCompleteDoneOfASingleLineCallsNothing(t *testing.T) {
	h := &cmptest.Host{}
	if err := New(Params{}).(source).OnCompleteDone(context.Background(), h, cmp.DoneArgs{Item: item("foo", 0)}); err != nil {
		t.Fatal(err)
	}
	if len(h.Calls()) != 0 {
		t.Errorf("calls %+v", h.Calls())
	}
}
