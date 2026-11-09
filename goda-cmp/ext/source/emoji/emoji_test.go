package emoji_test

import (
	"context"
	"reflect"
	"testing"

	"github.com/Shougo/goda-cmp.vim/cmp"
	"github.com/Shougo/goda-cmp.vim/cmp/cmptest"
	"goda-cmp-config/ext/source/emoji"
)

const keywordPattern = `[a-zA-Z_:]\w*`

// complete runs input through the engine with the options of lua/plugins/ddc.lua
// and returns what the UI was asked to show.
func complete(t *testing.T, input string) (col int, items []cmp.Item) {
	t.Helper()
	b := cmp.New().AddUI(cmptest.NewUI("test")).AddSource(emoji.New()).AddFilter(emoji.NewMatcher())
	b.PatchGlobal(cmp.Config{
		UI:      "test",
		Sources: []string{"emoji"},
		SourceOptions: map[string]cmp.SourceOption{
			"emoji": {Mark: "[E]", Matchers: []string{"emoji"}, Sorters: []string{}, KeywordPattern: keywordPattern},
		},
	})
	p, err := b.Plugin()
	if err != nil {
		t.Fatal(err)
	}
	h := &cmptest.Host{Funcs: map[string]func(...any) (any, error){
		"goda_cmp_testui#test#show": func(a ...any) (any, error) {
			m := a[0].(map[string]any)
			col, items = m["col"].(int), m["items"].([]cmp.Item)
			return nil, nil
		},
		"goda_cmp_testui#test#hide": func(...any) (any, error) { return nil, nil },
	}}
	request := map[string]any{
		"seq": int64(1), "tick": int64(1), "bufnr": int64(1), "lnum": int64(1),
		"col": int64(len(input) + 1), "input": input,
	}
	if _, err := p.Handlers()["complete"](context.Background(), h, []any{request}); err != nil {
		t.Fatal(err)
	}
	return col, items
}

func TestColonInputOffersEmojiByName(t *testing.T) {
	col, items := complete(t, "hello :smiling_face_with_sun")
	want := []cmp.Item{{
		Word: "\U0001F60E", Abbr: "\U0001F60E", Kind: ":smiling_face_with_sunglasses:", Menu: "[E]", Source: "emoji",
		UserData: emoji.Metadata{Name: ":smiling_face_with_sunglasses:", Emoji: "\U0001F60E"},
	}}
	for i := range items {
		items[i].Ref = ""
	}
	if !reflect.DeepEqual(items, want) {
		t.Errorf("items = %+v", items)
	}
	if col != 7 {
		t.Errorf("col = %d, want 7", col)
	}
}

func TestInputWithoutColonOffersNothing(t *testing.T) {
	if _, items := complete(t, "smil"); len(items) != 0 {
		t.Errorf("items = %+v", items)
	}
}

func TestNameIsCaseSensitive(t *testing.T) {
	if _, items := complete(t, ":afghanistan"); len(items) != 0 {
		t.Errorf("items = %+v", items)
	}
	if _, items := complete(t, ":Afghanistan"); len(items) != 1 {
		t.Errorf("items = %+v", items)
	}
}

func TestAliasesAreOffered(t *testing.T) {
	if _, items := complete(t, ":sunglasses"); len(items) == 0 {
		t.Error("no items")
	}
}

func TestMatcherDropsItemsOfOtherSources(t *testing.T) {
	out, err := emoji.NewMatcher().Filter(context.Background(), cmp.FilterInput{Complete: "", Items: []cmp.Item{{Word: ":smile:"}}})
	if err != nil {
		t.Fatal(err)
	}
	if len(out) != 0 {
		t.Errorf("out = %+v", out)
	}
}
