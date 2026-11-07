package nvimlsp

import (
	"context"
	"encoding/json"
	"errors"
	"reflect"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/Shougo/goda-cmp.vim/cmp"
	"github.com/Shougo/goda-cmp.vim/cmp/cmptest"
	"github.com/Shougo/goda.vim/sdk"
)

// neovim fakes lua/goda_cmp_lsp.lua behind Host.Call: the answers of poll
// come from a script, and what the source sends is kept for the test.
type neovim struct {
	mu           sync.Mutex
	polls        []string // what poll answers, one per call; "" afterwards
	noClients    bool
	starts       []map[string]any
	cancels      []any
	resolves     []map[string]any
	confirms     []map[string]any
	resolved     string // the item a resolve request answers with
	resolveError string // the error it answers with instead
	shows        []shown
	hides        int
}

// shown is one list the UI got.
type shown struct {
	col   int
	items []cmp.Item
}

func (n *neovim) host() *cmptest.Host {
	return &cmptest.Host{Funcs: map[string]func(...any) (any, error){
		"luaeval": n.luaeval,
		"goda_cmp_testui#test#show": func(a ...any) (any, error) {
			n.mu.Lock()
			defer n.mu.Unlock()
			m := a[0].(map[string]any)
			n.shows = append(n.shows, shown{m["col"].(int), m["items"].([]cmp.Item)})
			return nil, nil
		},
		"goda_cmp_testui#test#hide": func(...any) (any, error) {
			n.mu.Lock()
			defer n.mu.Unlock()
			n.hides++
			return nil, nil
		},
		"goda_cmp#_items": func(...any) (any, error) { return nil, nil },
	}}
}

func (n *neovim) luaeval(a ...any) (any, error) {
	n.mu.Lock()
	defer n.mu.Unlock()
	expr := a[0].(string)
	switch expr {
	case startExpr:
		n.starts = append(n.starts, a[1].(map[string]any))
		if n.noClients {
			return int64(0), nil
		}
		return int64(7), nil
	case pollExpr:
		if len(n.polls) == 0 {
			return "", nil
		}
		next := n.polls[0]
		n.polls = n.polls[1:]
		return next, nil
	case cancelExpr:
		n.cancels = append(n.cancels, a[1])
		return nil, nil
	case resolveExpr:
		n.resolves = append(n.resolves, a[1].(map[string]any))
		if n.resolveError != "" {
			n.polls = append(n.polls, `{"done":true,"stale":false,"results":[{"clientId":1,"error":"`+n.resolveError+`"}]}`)
		} else if n.resolved != "" {
			n.polls = append(n.polls, answered(result(1, "utf-16", n.resolved)))
		}
		return int64(8), nil
	case confirmExpr:
		var c map[string]any
		if err := json.Unmarshal([]byte(a[1].(string)), &c); err != nil {
			return nil, err
		}
		n.confirms = append(n.confirms, c)
		return nil, nil
	}
	return nil, errors.New("unexpected luaeval: " + expr)
}

func (n *neovim) cancelled() []any {
	n.mu.Lock()
	defer n.mu.Unlock()
	return append([]any(nil), n.cancels...)
}

// result is the answer of one client, in the shape poll sends it.
func result(id int, encoding, body string) string {
	b, _ := json.Marshal(map[string]any{
		"clientId": id, "offsetEncoding": encoding, "resolvable": true, "result": json.RawMessage(body),
	})
	return string(b)
}

// answered is a poll answer with every client done.
func answered(results ...string) string {
	return `{"done":true,"stale":false,"results":[` + strings.Join(results, ",") + `]}`
}

func newContext(input, after string) *cmp.Context {
	return &cmp.Context{Seq: 1, Tick: 3, Bufnr: 1, Lnum: 5, Input: input, NextInput: after, Mode: "i"}
}

// gather returns the last thing the source emitted.
func gather(t *testing.T, s *Source, n *neovim, c *cmp.Context) cmp.Gathered {
	t.Helper()
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	g, err := s.Gather(ctx, n.host(), c)
	if err != nil {
		t.Fatal(err)
	}
	return g
}

func words(items []cmp.Item) []string {
	out := make([]string, len(items))
	for i, it := range items {
		out[i] = it.Word
	}
	return out
}

func TestStartFollowsTheServersRange(t *testing.T) {
	// "日本語😀" is 13 bytes, 5 UTF-16 units and 4 code points.
	const prefix = "日本語😀"
	edit := func(start, end int) string {
		b, _ := json.Marshal(map[string]any{"label": "foo", "textEdit": map[string]any{
			"newText": "foo",
			"range": map[string]any{
				"start": map[string]int{"line": 4, "character": start},
				"end":   map[string]int{"line": 4, "character": end},
			},
		}})
		return `[` + string(b) + `]`
	}
	tests := []struct {
		name     string
		encoding string
		input    string
		body     string
		start    int
		word     string
	}{
		{"a UTF-16 range after wide characters maps to bytes", "utf-16", prefix + ".fo", edit(6, 8), 14, "foo"},
		{"a UTF-8 range after wide characters is already in bytes", "utf-8", prefix + ".fo", edit(14, 16), 14, "foo"},
		{"a UTF-32 range counts code points", "utf-32", prefix + ".fo", edit(5, 7), 14, "foo"},
		{"a range that starts before the keyword moves the start left", "utf-16", "foo-ba", edit(0, 6), 0, "foo"},
		{"a range at the indentation starts the word at the first letter", "utf-16", "    fo", edit(0, 6), 4, "foo"},
		{
			"an insert and replace edit uses its insert range", "utf-16", "x.fo",
			`[{"label":"foo","textEdit":{"newText":"foo",
				"insert":{"start":{"line":4,"character":2},"end":{"line":4,"character":4}},
				"replace":{"start":{"line":4,"character":0},"end":{"line":4,"character":6}}}}]`,
			2, "foo",
		},
		{
			"a default edit range applies to items without a text edit", "utf-16", "foo-ba",
			`{"itemDefaults":{"editRange":{"start":{"line":4,"character":4},"end":{"line":4,"character":6}}},
			  "items":[{"label":"bar"}]}`,
			4, "bar",
		},
		{
			"a default insert and replace range applies to items without a text edit", "utf-16", "foo-ba",
			`{"itemDefaults":{"editRange":{
				"insert":{"start":{"line":4,"character":4},"end":{"line":4,"character":6}},
				"replace":{"start":{"line":4,"character":4},"end":{"line":4,"character":8}}}},
			  "items":[{"label":"bar","textEditText":"baz"}]}`,
			4, "baz",
		},
		{"an item without a range starts at the keyword", "utf-16", "x.fo", `[{"label":"foo"}]`, 2, "foo"},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			n := &neovim{polls: []string{answered(result(1, tt.encoding, tt.body))}}
			g := gather(t, New(Params{}), n, newContext(tt.input, ""))
			if g.Start != tt.start {
				t.Errorf("start = %d, want %d", g.Start, tt.start)
			}
			if got := words(g.Items); !reflect.DeepEqual(got, []string{tt.word}) {
				t.Errorf("words = %q, want %q", got, tt.word)
			}
		})
	}
}

func TestEditsThatLeaveTheCursorLineAreNotOffered(t *testing.T) {
	item := func(startLine, endLine int) string {
		b, _ := json.Marshal(map[string]any{"label": "foo", "textEdit": map[string]any{
			"newText": "foo",
			"range": map[string]any{
				"start": map[string]int{"line": startLine, "character": 0},
				"end":   map[string]int{"line": endLine, "character": 2},
			},
		}})
		return string(b)
	}
	body := `[` + item(3, 3) + `,` + item(3, 4) + `,{"label":"kept"}]`
	n := &neovim{polls: []string{answered(result(1, "utf-16", body))}}
	g := gather(t, New(Params{}), n, newContext("fo", ""))
	if got := words(g.Items); !reflect.DeepEqual(got, []string{"kept"}) {
		t.Errorf("words = %q", got)
	}
}

func TestItemsWithDifferentRangesShareTheLeftmostStart(t *testing.T) {
	body := `[{"label":"bar-baz","filterText":".bar-baz","textEdit":{"newText":"[\"bar-baz\"]",
			"range":{"start":{"line":4,"character":3},"end":{"line":4,"character":6}}}},
		{"label":"bar","filterText":"bar","textEdit":{"newText":"bar",
			"range":{"start":{"line":4,"character":4},"end":{"line":4,"character":6}}}},
		{"label":"baz"}]`
	n := &neovim{polls: []string{answered(result(1, "utf-16", body))}}
	g := gather(t, New(Params{}), n, newContext("foo.ba", ""))
	if g.Start != 3 {
		t.Fatalf("start = %d, want 3", g.Start)
	}
	if got, want := words(g.Items), []string{`["bar-baz"]`, ".bar", ".baz"}; !reflect.DeepEqual(got, want) {
		t.Errorf("words = %q, want %q", got, want)
	}
	if got := g.Items[1].Filter(); got != ".bar" {
		t.Errorf("filter text = %q, want it to start where the word starts", got)
	}
	if got := g.Items[1].Display(); got != "bar" {
		t.Errorf("display = %q, want the label", got)
	}
}

func TestServerFieldsReachThePopup(t *testing.T) {
	body := `{"isIncomplete":false,"items":[
		{"label":"read","kind":3,"sortText":"0001","filterText":"rd","detail":"fn","documentation":{"kind":"markdown","value":"reads"},
		 "labelDetails":{"detail":"(path)","description":"node:fs"}},
		{"label":"plain"},
		{"label":"function ()","kind":15,"insertTextFormat":2,"insertText":"function ${1:name}()\n\t$0\nend"},
		{"label":"•atan2","insertText":"atan2"}]}`
	n := &neovim{polls: []string{answered(result(1, "utf-16", body))}}
	g := gather(t, New(Params{}), n, newContext("", ""))

	read := g.Items[0]
	if read.Kind != "Function" || read.SortText != "0001" || read.Filter() != "rd" || read.Abbr != "read(path) node:fs" {
		t.Errorf("read = %+v", read)
	}
	if read.Info != "fn\n\nreads" {
		t.Errorf("info = %q", read.Info)
	}
	if plain := g.Items[1]; plain.Kind != "Text" || plain.Sort() != "plain" {
		t.Errorf("an item without kind or sortText = %+v", plain)
	}
	snippet := g.Items[2]
	if snippet.Word != "function" || snippet.Abbr != "function ()~" || snippet.Kind != "Snippet" {
		t.Errorf("snippet = %+v", snippet)
	}
	if label := g.Items[3]; label.Word != "atan2" || label.Abbr != "•atan2" {
		t.Errorf("a decorated label = %+v", label)
	}
}

// The items of ddc-source-lsp's confirm tests, whose servers each use the range
// and the filter text in their own way.
func TestItemsOfRealServersMatchWhatIsTyped(t *testing.T) {
	tests := []struct {
		name   string
		input  string
		body   string
		start  int
		word   string
		filter string
	}{
		{
			"vscode-html-language-server fixes the indentation", "  </d",
			`[{"label":"/div","filterText":"  </div","textEdit":{"newText":"</div",
				"range":{"start":{"line":4,"character":0},"end":{"line":4,"character":5}}}}]`,
			2, "</div", "</div",
		},
		{
			"clangd replaces the dot with an arrow", "obj.p",
			`[{"label":" prop","filterText":"prop","textEdit":{"newText":"->prop",
				"range":{"start":{"line":4,"character":3},"end":{"line":4,"character":5}}}}]`,
			3, "->prop", ".prop",
		},
		{
			"typescript-language-server replaces the dot with brackets", "[].S",
			`[{"label":"Symbol","filterText":".Symbol","textEdit":{"newText":"[Symbol]",
				"range":{"start":{"line":4,"character":2},"end":{"line":4,"character":4}}}}]`,
			2, "[Symbol]", ".Symbol",
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			n := &neovim{polls: []string{answered(result(1, "utf-16", tt.body))}}
			g := gather(t, New(Params{}), n, newContext(tt.input, "foo"))
			if g.Start != tt.start || g.Items[0].Word != tt.word {
				t.Errorf("start %d word %q, want %d %q", g.Start, g.Items[0].Word, tt.start, tt.word)
			}
			if got := g.Items[0].Filter(); got != tt.filter || !strings.HasPrefix(got, tt.input[tt.start:]) {
				t.Errorf("filter %q, want %q starting with %q", got, tt.filter, tt.input[tt.start:])
			}
		})
	}
}

func TestPopupWordIsTheTextUpToTheFirstStopCharacter(t *testing.T) {
	tests := []struct{ text, want string }{
		{"foo", "foo"},
		{"foo(bar)", "foo"},
		{"foo = 1", "foo"},
		{"foo\nbar", "foo"},
		{`["bar-baz"]`, `["bar-baz"]`},
		{"(foo bar) baz", "(foo bar)"},
		{"foo.bar", "foo.bar"},
	}
	for _, tt := range tests {
		if got := selectText(tt.text); got != tt.want {
			t.Errorf("selectText(%q) = %q, want %q", tt.text, got, tt.want)
		}
	}
}

func TestSnippetTextOfThePopupIsWhatTheSnippetInsertsByDefault(t *testing.T) {
	tests := []struct{ snippet, want string }{
		{"foo($1)", "foo()"},
		{"${1:name} = $0", "name = "},
		{"${1|a,b|}", "a"},
		{`\$x`, "$x"},
		{"${1:${2:nested}}", "nested"},
	}
	for _, tt := range tests {
		if got := stripSnippet(tt.snippet); got != tt.want {
			t.Errorf("stripSnippet(%q) = %q, want %q", tt.snippet, got, tt.want)
		}
	}
}

func TestClientsAreMergedEachWithItsOwnEncoding(t *testing.T) {
	const input = "日本語😀.fo"
	rangeAt := func(character int) string {
		b, _ := json.Marshal(map[string]any{
			"start": map[string]int{"line": 4, "character": character},
			"end":   map[string]int{"line": 4, "character": character + 2},
		})
		return string(b)
	}
	fast := `[{"label":"fast","textEdit":{"newText":"fast","range":` + rangeAt(6) + `}}]`
	slow := `[{"label":"slow","textEdit":{"newText":"slow","range":` + rangeAt(14) + `}}]`
	n := &neovim{polls: []string{
		`{"done":false,"stale":false,"results":[` + result(1, "utf-16", fast) + `]}`,
		"",
		answered(result(2, "utf-8", slow)),
	}}
	var emitted []cmp.Gathered
	err := New(Params{}).GatherStream(context.Background(), n.host(), newContext(input, ""), func(g cmp.Gathered) error {
		emitted = append(emitted, g)
		return nil
	})
	if err != nil {
		t.Fatal(err)
	}
	if len(emitted) != 2 {
		t.Fatalf("emitted %d times, want once per client", len(emitted))
	}
	if got := words(emitted[0].Items); !reflect.DeepEqual(got, []string{"fast"}) {
		t.Errorf("first emit = %q, want the fast client alone", got)
	}
	last := emitted[1]
	if got := words(last.Items); !reflect.DeepEqual(got, []string{"fast", "slow"}) {
		t.Errorf("last emit = %q", got)
	}
	if last.Start != 14 {
		t.Errorf("start = %d, want both ranges to map to byte 14", last.Start)
	}
	for i, id := range []int{1, 2} {
		if got := last.Items[i].UserData.(*itemData).client.ID; got != id {
			t.Errorf("item %d belongs to client %d, want %d", i, got, id)
		}
	}
}

func TestIncompleteListIsAskedAgainAsIncomplete(t *testing.T) {
	s := New(Params{})
	n := &neovim{polls: []string{
		answered(result(1, "utf-16", `{"isIncomplete":true,"items":[{"label":"foo"}]}`),
			result(2, "utf-16", `{"isIncomplete":false,"items":[{"label":"bar"}]}`)),
		answered(result(1, "utf-16", `{"isIncomplete":false,"items":[{"label":"foo"}]}`)),
		answered(result(1, "utf-16", `[]`)),
	}}
	if g := gather(t, s, n, newContext("f", "")); !g.Incomplete {
		t.Error("one incomplete client must make the list incomplete")
	}
	if g := gather(t, s, n, newContext("fo", "")); g.Incomplete {
		t.Error("a complete list must not be incomplete")
	}
	gather(t, s, n, newContext("foo", ""))
	got := []any{n.starts[0]["incomplete"], n.starts[1]["incomplete"], n.starts[2]["incomplete"]}
	if want := []any{false, true, false}; !reflect.DeepEqual(got, want) {
		t.Errorf("incomplete told to the clients = %v, want %v", got, want)
	}
}

func TestResultsWithoutItemsGiveNoCandidates(t *testing.T) {
	for _, body := range []string{`null`, `[]`, `{"isIncomplete":false,"items":[]}`} {
		n := &neovim{polls: []string{answered(result(1, "utf-16", body))}}
		if g := gather(t, New(Params{}), n, newContext("fo", "")); len(g.Items) != 0 {
			t.Errorf("%s: items = %v", body, g.Items)
		}
	}
}

func TestBufferWithoutClientsAsksNothingMore(t *testing.T) {
	n := &neovim{noClients: true}
	g := gather(t, New(Params{}), n, newContext("fo", ""))
	if len(g.Items) != 0 || len(n.cancels) != 0 {
		t.Errorf("items %v, cancels %v", g.Items, n.cancels)
	}
}

func TestCommandLineIsNotAsked(t *testing.T) {
	n := &neovim{}
	c := newContext("fo", "")
	c.Mode = "c"
	gather(t, New(Params{}), n, c)
	if len(n.starts) != 0 {
		t.Errorf("starts = %v", n.starts)
	}
}

func TestContextEndCancelsTheRequest(t *testing.T) {
	n := &neovim{}
	ctx, cancel := context.WithCancel(context.Background())
	done := make(chan error, 1)
	go func() {
		_, err := New(Params{}).Gather(ctx, n.host(), newContext("fo", ""))
		done <- err
	}()
	time.Sleep(3 * pollInterval)
	cancel()
	select {
	case err := <-done:
		if !errors.Is(err, context.Canceled) {
			t.Errorf("err = %v", err)
		}
	case <-time.After(5 * time.Second):
		t.Fatal("the gather kept running after its context ended")
	}
	if want := []any{7}; !reflect.DeepEqual(n.cancels, want) {
		t.Errorf("cancels = %v, want %v", n.cancels, want)
	}
}

func TestFinishedRequestIsNotCancelled(t *testing.T) {
	n := &neovim{polls: []string{answered(result(1, "utf-16", `[{"label":"foo"}]`))}}
	gather(t, New(Params{}), n, newContext("fo", ""))
	if len(n.cancels) != 0 {
		t.Errorf("cancels = %v", n.cancels)
	}
}

func TestSupersededEmitEndsTheRequest(t *testing.T) {
	n := &neovim{polls: []string{`{"done":false,"stale":false,"results":[` + result(1, "utf-16", `[]`) + `]}`}}
	superseded := errors.New("superseded")
	err := New(Params{}).GatherStream(context.Background(), n.host(), newContext("fo", ""), func(cmp.Gathered) error {
		return superseded
	})
	if !errors.Is(err, superseded) {
		t.Fatalf("err = %v", err)
	}
	if len(n.cancels) != 1 {
		t.Errorf("cancels = %v, want the unanswered clients cancelled", n.cancels)
	}
}

// engine is a real goda-cmp engine with the source, a test UI and a second
// source that always offers "other".
type engine struct {
	t  *testing.T
	p  sdk.Plugin
	n  *neovim
	h  *cmptest.Host
	op cmp.SourceOption
}

type otherSource struct{}

func (otherSource) Name() string { return "other" }
func (otherSource) Gather(_ context.Context, _ sdk.Host, c *cmp.Context) (cmp.Gathered, error) {
	return cmp.Gathered{Start: c.KeywordStart(), Items: []cmp.Item{{Word: "other"}}}, nil
}

func newEngine(t *testing.T, n *neovim, p Params, sources ...string) *engine {
	t.Helper()
	b := cmp.New()
	b.AddUI(cmptest.NewUI("test"))
	b.AddSource(New(p))
	b.AddSource(otherSource{})
	b.PatchGlobal(cmp.Config{
		UI:      "test",
		Sources: sources,
		SourceOptions: map[string]cmp.SourceOption{
			"nvimlsp": {Mark: "[LSP]", IsVolatile: new(true), ForceCompletionPattern: `\.\w*|:\w*|->\w*`},
		},
	})
	plugin, err := b.Plugin()
	if err != nil {
		t.Fatal(err)
	}
	return &engine{t: t, p: plugin, n: n, h: n.host()}
}

func (e *engine) complete(input, after string) {
	e.t.Helper()
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	c := map[string]any{
		"seq": int64(1), "tick": int64(3), "bufnr": 1, "lnum": 5, "col": len(input) + 1,
		"input": input, "nextinput": after, "filetype": "lua", "mode": "i", "event": "TextChangedI",
	}
	if _, err := e.p.Handlers()["complete"](ctx, e.h, []any{c}); err != nil {
		e.t.Fatal(err)
	}
}

func (e *engine) call(method string, ref string) {
	e.t.Helper()
	if _, err := e.p.Handlers()[method](context.Background(), e.h, []any{ref}); err != nil {
		e.t.Fatal(err)
	}
}

func (e *engine) last() shown {
	e.t.Helper()
	if len(e.n.shows) == 0 {
		e.t.Fatal("nothing was shown")
	}
	return e.n.shows[len(e.n.shows)-1]
}

func TestForceCompletionPatternAsksRightAfterTheDot(t *testing.T) {
	n := &neovim{polls: []string{answered(result(1, "utf-16", `[{"label":"upper"}]`))}}
	e := newEngine(t, n, Params{}, "nvimlsp")
	e.complete("string.", "")
	got := e.last()
	if got.col != len("string.")+1 {
		t.Errorf("col = %d", got.col)
	}
	if words := words(got.items); !reflect.DeepEqual(words, []string{"upper"}) {
		t.Errorf("words = %q", words)
	}
	if got.items[0].Menu != "[LSP]" {
		t.Errorf("menu = %q, want the mark", got.items[0].Menu)
	}
}

func TestSlowClientDoesNotLoseItsAnswerToHideTimeout(t *testing.T) {
	n := &neovim{}
	for range int(300 * time.Millisecond / pollInterval) {
		n.polls = append(n.polls, "")
	}
	n.polls = append(n.polls, answered(result(1, "utf-16", `[{"label":"late"}]`)))
	e := newEngine(t, n, Params{}, "nvimlsp")
	e.complete("la", "")
	if got := words(e.last().items); !reflect.DeepEqual(got, []string{"late"}) {
		t.Errorf("words = %q", got)
	}
}

func TestRequestOfOlderTextLeavesThePopupOpen(t *testing.T) {
	for _, input := range []string{"fo", "string."} {
		n := &neovim{polls: []string{`{"done":true,"stale":true}`}}
		e := newEngine(t, n, Params{}, "nvimlsp")
		e.complete(input, "")
		if n.hides != 0 {
			t.Errorf("%q: the popup was closed, which accepts the selected item", input)
		}
		if len(n.shows) == 0 {
			t.Errorf("%q: the UI got no list, which it would drop for its older text", input)
		}
	}
}

func TestNoCandidatesForTheCurrentTextClosesThePopup(t *testing.T) {
	n := &neovim{polls: []string{answered(result(1, "utf-16", `[]`))}}
	e := newEngine(t, n, Params{}, "nvimlsp")
	e.complete("fo", "")
	if n.hides == 0 {
		t.Error("the popup stayed open")
	}
}

func TestGarbledAnswerLeavesTheOtherSources(t *testing.T) {
	n := &neovim{polls: []string{`{"done":tru`}}
	e := newEngine(t, n, Params{}, "nvimlsp", "other")
	e.complete("ot", "")
	if got := words(e.last().items); !reflect.DeepEqual(got, []string{"other"}) {
		t.Errorf("words = %q", got)
	}
}

func TestMalformedItemLeavesTheOtherItems(t *testing.T) {
	body := `{"items":[{"label":42},{"textEdit":"nonsense","label":"bad"},{"insertText":"no label"},{"label":"good"}]}`
	n := &neovim{polls: []string{answered(result(1, "utf-16", body))}}
	g := gather(t, New(Params{}), n, newContext("", ""))
	if got := words(g.Items); !reflect.DeepEqual(got, []string{"good"}) {
		t.Errorf("words = %q", got)
	}
}

func TestClientThatFailedGivesNoCandidates(t *testing.T) {
	failed := `{"clientId":1,"offsetEncoding":"utf-16","resolvable":false,"error":"boom"}`
	n := &neovim{polls: []string{answered(failed, result(2, "utf-16", `[{"label":"good"}]`))}}
	g := gather(t, New(Params{}), n, newContext("", ""))
	if got := words(g.Items); !reflect.DeepEqual(got, []string{"good"}) {
		t.Errorf("words = %q", got)
	}
}

func TestResolveFillsTheDocumentation(t *testing.T) {
	n := &neovim{
		polls:    []string{answered(result(1, "utf-16", `{"itemDefaults":{"data":{"id":1}},"items":[{"label":"foo"}]}`))},
		resolved: `{"label":"foo","detail":"fn foo()","documentation":"does foo"}`,
	}
	e := newEngine(t, n, Params{EnableResolveItem: true}, "nvimlsp")
	e.complete("fo", "")
	ref := e.last().items[0].Ref
	out, err := e.p.Handlers()["resolve"](context.Background(), e.h, []any{ref})
	if err != nil {
		t.Fatal(err)
	}
	if got := out.(map[string]any)["info"]; got != "fn foo()\n\ndoes foo" {
		t.Errorf("info = %q", got)
	}
	if len(n.resolves) != 1 {
		t.Fatalf("resolves = %v", n.resolves)
	}
	var sent struct {
		Data struct {
			ID int `json:"id"`
		} `json:"data"`
	}
	if err := json.Unmarshal([]byte(n.resolves[0]["item"].(string)), &sent); err != nil {
		t.Fatal(err)
	}
	if sent.Data.ID != 1 {
		t.Errorf("the server got %s, want the default data in it", n.resolves[0]["item"])
	}

	// A second selection of the same item asks the server no more.
	e.call("resolve", ref)
	if len(n.resolves) != 1 {
		t.Errorf("resolves = %d, want the first answer kept", len(n.resolves))
	}
}

func TestMergedDefaultDataReachesResolve(t *testing.T) {
	body := `{"applyKind":{"data":2},"itemDefaults":{"data":{"a":1,"b":1}},"items":[{"label":"foo","data":{"b":2}}]}`
	n := &neovim{polls: []string{answered(result(1, "utf-16", body))}, resolved: `{"label":"foo"}`}
	e := newEngine(t, n, Params{EnableResolveItem: true}, "nvimlsp")
	e.complete("fo", "")
	e.call("resolve", e.last().items[0].Ref)
	var sent struct {
		Data map[string]int `json:"data"`
	}
	if err := json.Unmarshal([]byte(n.resolves[0]["item"].(string)), &sent); err != nil {
		t.Fatal(err)
	}
	if want := map[string]int{"a": 1, "b": 2}; !reflect.DeepEqual(sent.Data, want) {
		t.Errorf("data = %v, want %v", sent.Data, want)
	}
}

func TestClientWithoutResolveIsNotAsked(t *testing.T) {
	plain := `{"clientId":1,"offsetEncoding":"utf-16","resolvable":false,"result":[{"label":"foo"}]}`
	n := &neovim{polls: []string{answered(plain)}}
	e := newEngine(t, n, Params{EnableResolveItem: true}, "nvimlsp")
	e.complete("fo", "")
	e.call("resolve", e.last().items[0].Ref)
	if len(n.resolves) != 0 {
		t.Errorf("resolves = %v", n.resolves)
	}
}

func TestResolveIsOffUnlessEnabled(t *testing.T) {
	n := &neovim{polls: []string{answered(result(1, "utf-16", `[{"label":"foo"}]`))}}
	e := newEngine(t, n, Params{}, "nvimlsp")
	e.complete("fo", "")
	ref := e.last().items[0].Ref
	e.call("resolve", ref)
	e.call("done", ref)
	if len(n.resolves) != 0 {
		t.Errorf("resolves = %v", n.resolves)
	}
}

func TestAcceptedItemBringsItsResolvedEdits(t *testing.T) {
	body := `[{"label":"join","insertTextFormat":2,"textEdit":{"newText":"join($1)",
		"range":{"start":{"line":4,"character":0},"end":{"line":4,"character":4}}}}]`
	n := &neovim{
		polls: []string{answered(result(1, "utf-16", body))},
		resolved: `{"label":"join","command":{"title":"t","command":"c"},"additionalTextEdits":[{"newText":"import x\n",
			"range":{"start":{"line":0,"character":0},"end":{"line":0,"character":0}}}]}`,
	}
	e := newEngine(t, n, Params{EnableResolveItem: true, EnableAdditionalTextEdit: true}, "nvimlsp")
	e.complete("jo", "in rest")
	e.call("done", e.last().items[0].Ref)
	if len(n.confirms) != 1 {
		t.Fatalf("confirms = %v", n.confirms)
	}
	c := n.confirms[0]
	want := map[string]any{
		"bufnr": 1.0, "lnum": 5.0, "input": "jo", "word": "join", "start": 0.0, "tail": 2.0, "text": "join($1)",
		"snippet": true, "clientId": 1.0, "offsetEncoding": "utf-16",
	}
	for k, v := range want {
		if c[k] != v {
			t.Errorf("%s = %v, want %v", k, c[k], v)
		}
	}
	if edits, _ := c["additionalTextEdits"].([]any); len(edits) != 1 {
		t.Errorf("additionalTextEdits = %v", c["additionalTextEdits"])
	}
	if c["command"] == nil {
		t.Error("the resolved command is missing")
	}
}

func TestAdditionalTextEditsAreOffUnlessEnabled(t *testing.T) {
	body := `[{"label":"foo","additionalTextEdits":[{"newText":"x",
		"range":{"start":{"line":0,"character":0},"end":{"line":0,"character":0}}}]}]`
	n := &neovim{polls: []string{answered(result(1, "utf-16", body))}}
	e := newEngine(t, n, Params{}, "nvimlsp")
	e.complete("fo", "")
	e.call("done", e.last().items[0].Ref)
	if _, ok := n.confirms[0]["additionalTextEdits"]; ok {
		t.Errorf("confirm = %v", n.confirms[0])
	}
}

func TestFailedResolveStillConfirmsTheItem(t *testing.T) {
	n := &neovim{polls: []string{answered(result(1, "utf-16", `[{"label":"foo"}]`))}, resolveError: "boom"}
	e := newEngine(t, n, Params{EnableResolveItem: true}, "nvimlsp")
	e.complete("fo", "")
	e.call("done", e.last().items[0].Ref)
	if len(n.confirms) != 1 {
		t.Errorf("confirms = %v", n.confirms)
	}
}

func TestPartialResolveAnswerKeepsWhatTheItemHad(t *testing.T) {
	body := `[{"label":"•atan2","insertText":"atan2","additionalTextEdits":[{"newText":"import\n",
		"range":{"start":{"line":0,"character":0},"end":{"line":0,"character":0}}}]}]`
	n := &neovim{polls: []string{answered(result(1, "utf-16", body))}, resolved: `{"label":"•atan2","documentation":"d"}`}
	e := newEngine(t, n, Params{EnableResolveItem: true, EnableAdditionalTextEdit: true}, "nvimlsp")
	e.complete("at", "")
	e.call("done", e.last().items[0].Ref)
	c := n.confirms[0]
	if c["text"] != "atan2" {
		t.Errorf("text = %v", c["text"])
	}
	if edits, _ := c["additionalTextEdits"].([]any); len(edits) != 1 {
		t.Errorf("additionalTextEdits = %v", c["additionalTextEdits"])
	}
}

func TestResolveOfOlderTextLeavesTheItemUnresolved(t *testing.T) {
	n := &neovim{polls: []string{answered(result(1, "utf-16", `[{"label":"foo"}]`))}}
	e := newEngine(t, n, Params{EnableResolveItem: true}, "nvimlsp")
	e.complete("fo", "")
	n.polls = []string{`{"done":true,"stale":true}`}
	ref := e.last().items[0].Ref
	e.call("resolve", ref)
	n.polls = []string{`{"done":true,"stale":true}`}
	e.call("resolve", ref)
	if len(n.resolves) != 2 {
		t.Errorf("resolves = %d, want the next selection to ask again", len(n.resolves))
	}
}

func TestResolveWithoutAnAnswerIsCancelledWithItsContext(t *testing.T) {
	n := &neovim{polls: []string{answered(result(1, "utf-16", `[{"label":"foo"}]`))}}
	e := newEngine(t, n, Params{EnableResolveItem: true}, "nvimlsp")
	e.complete("fo", "")
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Millisecond)
	defer cancel()
	if _, err := e.p.Handlers()["resolve"](ctx, e.h, []any{e.last().items[0].Ref}); err == nil {
		t.Error("the unanswered request ended without an error")
	}
	// The engine stops waiting at the deadline, and the source ends right after.
	for deadline := time.Now().Add(5 * time.Second); len(n.cancelled()) == 0 && time.Now().Before(deadline); {
		time.Sleep(pollInterval)
	}
	if got, want := n.cancelled(), []any{8}; !reflect.DeepEqual(got, want) {
		t.Errorf("cancels = %v, want %v", got, want)
	}
}

func TestItemOfAnotherSourceIsLeftAlone(t *testing.T) {
	n := &neovim{}
	a := cmp.DoneArgs{Context: newContext("fo", ""), Item: cmp.Item{Word: "foo"}}
	s := New(Params{EnableResolveItem: true})
	if err := s.OnCompleteDone(context.Background(), n.host(), a); err != nil {
		t.Error(err)
	}
	if _, err := s.Resolve(context.Background(), n.host(), a); err != nil {
		t.Error(err)
	}
	if p, err := s.Preview(context.Background(), n.host(), a); err != nil || p.Kind != "" {
		t.Errorf("preview = %+v, %v", p, err)
	}
	if len(n.confirms)+len(n.resolves) != 0 {
		t.Errorf("confirms %v, resolves %v", n.confirms, n.resolves)
	}
}

func TestPreviewShowsDetailAndDocumentation(t *testing.T) {
	n := &neovim{
		polls: []string{answered(result(1, "utf-16", `[{"label":"join"}]`))},
		resolved: `{"label":"join","detail":"function join()",
			"documentation":{"kind":"markdown","value":"line 1\nline 2"}}`,
	}
	e := newEngine(t, n, Params{}, "nvimlsp")
	e.complete("jo", "")
	out, err := e.p.Handlers()["preview"](context.Background(), e.h, []any{e.last().items[0].Ref})
	if err != nil {
		t.Fatal(err)
	}
	m := out.(map[string]any)
	if m["kind"] != cmp.PreviewMarkdown {
		t.Errorf("kind = %v", m["kind"])
	}
	want := []any{"```lua", "function join()", "```", "---", "line 1", "line 2"}
	if !reflect.DeepEqual(m["contents"], want) {
		t.Errorf("contents = %q", m["contents"])
	}
}

func TestPreviewOfASnippetShowsItsBody(t *testing.T) {
	body := `[{"label":"for","kind":15,"insertTextFormat":2,"insertText":"for ${1:i} do\n\t$0\nend"}]`
	n := &neovim{polls: []string{answered(result(1, "utf-16", body))}}
	e := newEngine(t, n, Params{}, "nvimlsp")
	e.complete("fo", "")
	out, err := e.p.Handlers()["preview"](context.Background(), e.h, []any{e.last().items[0].Ref})
	if err != nil {
		t.Fatal(err)
	}
	want := []any{"```lua", "for i do", "\t", "end", "```"}
	if got := out.(map[string]any)["contents"]; !reflect.DeepEqual(got, want) {
		t.Errorf("contents = %q", got)
	}
}

func TestParametersComeFromVimScript(t *testing.T) {
	made, err := New(Params{}).WithParams(cmp.Params{"enableResolveItem": true})
	if err != nil {
		t.Fatal(err)
	}
	if !made.(*Source).p.EnableResolveItem {
		t.Error("enableResolveItem was not applied")
	}
	if _, err := New(Params{}).WithParams(cmp.Params{"snippetEngine": "x"}); err == nil {
		t.Error("an unknown parameter must be refused")
	}
}
