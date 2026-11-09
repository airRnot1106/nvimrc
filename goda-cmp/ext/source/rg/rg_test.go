package rg

import (
	"context"
	"os"
	"os/exec"
	"path/filepath"
	"reflect"
	"strings"
	"testing"
	"time"

	"github.com/Shougo/goda-cmp.vim/cmp"
	"github.com/Shougo/goda-cmp.vim/cmp/cmptest"
)

func host(cwd string) *cmptest.Host {
	return &cmptest.Host{Funcs: map[string]func(...any) (any, error){
		"getcwd": func(...any) (any, error) { return cwd, nil },
	}}
}

// script returns an executable that runs body with sh.
func script(t *testing.T, body string) string {
	t.Helper()
	path := filepath.Join(t.TempDir(), "fake-rg")
	if err := os.WriteFile(path, []byte("#!/bin/sh\n"+body+"\n"), 0o755); err != nil {
		t.Fatal(err)
	}
	return path
}

func gather(t *testing.T, ctx context.Context, cmd, input string) (cmp.Gathered, error) {
	t.Helper()
	return New(Params{Cmd: cmd}).Gather(ctx, host(t.TempDir()), &cmp.Context{Input: input})
}

func TestExitOneMeansNoCandidatesAndNoError(t *testing.T) {
	g, err := gather(t, context.Background(), script(t, "exit 1"), "x foo")
	if err != nil {
		t.Fatal(err)
	}
	if len(g.Items) != 0 || g.Start != 2 {
		t.Errorf("got %+v", g)
	}
}

func TestExitTwoFailsWithTheMessageOfRipgrep(t *testing.T) {
	g, err := gather(t, context.Background(), script(t, "echo partial; echo broken >&2; exit 2"), "foo")
	if err == nil || !strings.Contains(err.Error(), "broken") {
		t.Errorf("err = %v", err)
	}
	if len(g.Items) != 0 {
		t.Errorf("items = %+v", g.Items)
	}
}

func TestMissingCommandFails(t *testing.T) {
	if _, err := gather(t, context.Background(), filepath.Join(t.TempDir(), "none"), "foo"); err == nil {
		t.Error("no error")
	}
}

func TestCancelledRequestReturnsTheContextError(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 50*time.Millisecond)
	defer cancel()
	if _, err := gather(t, ctx, script(t, "exec sleep 10"), "foo"); err != context.DeadlineExceeded {
		t.Errorf("err = %v", err)
	}
}

func TestOutputBecomesUniqueWordsInOrder(t *testing.T) {
	g, err := gather(t, context.Background(), script(t, `printf 'foo\r\nbar\n\nfoo\nbaz'`), "ba")
	if err != nil {
		t.Fatal(err)
	}
	var words []string
	for _, it := range g.Items {
		words = append(words, it.Word)
	}
	if want := []string{"foo", "bar", "baz"}; !reflect.DeepEqual(words, want) {
		t.Errorf("words = %q, want %q", words, want)
	}
}

func TestArgumentsAreParamsPatternAndCwd(t *testing.T) {
	cwd := t.TempDir()
	src := New(Params{Cmd: script(t, `for a in "$@"; do echo "$a"; done`), Args: []string{"--flag"}})
	g, err := src.Gather(context.Background(), host(cwd), &cmp.Context{Input: "foo"})
	if err != nil {
		t.Fatal(err)
	}
	var got []string
	for _, it := range g.Items {
		got = append(got, it.Word)
	}
	if want := []string{"--flag", "foo[a-zA-Z0-9_-]+", cwd}; !reflect.DeepEqual(got, want) {
		t.Errorf("args = %q, want %q", got, want)
	}
}

func TestParamsComeFromVimScript(t *testing.T) {
	src, err := New(Params{}).(cmp.Configurable).WithParams(cmp.Params{"cmd": "/bin/rg", "args": []any{"-w"}})
	if err != nil {
		t.Fatal(err)
	}
	want := Params{Cmd: "/bin/rg", Args: []string{"-w"}}
	if got := src.(source).p; !reflect.DeepEqual(got, want) {
		t.Errorf("params = %+v", got)
	}
}

func TestRipgrep(t *testing.T) {
	if _, err := exec.LookPath("rg"); err != nil {
		t.Skip("rg is not installed")
	}
	cwd := t.TempDir()
	text := "alphabet alphanumeric Alpha-beta alpha alphabet\nalp.ha alp.habet\n"
	if err := os.WriteFile(filepath.Join(cwd, "a.txt"), []byte(text), 0o644); err != nil {
		t.Fatal(err)
	}
	for _, tt := range []struct {
		input string
		want  []string
	}{
		{"alph", []string{"alphabet", "alphanumeric", "Alpha-beta", "alpha"}},
		{"nothinglikethis", nil},
	} {
		g, err := New(Params{}).Gather(context.Background(), host(cwd), &cmp.Context{Input: tt.input})
		if err != nil {
			t.Fatalf("%s: %v", tt.input, err)
		}
		var words []string
		for _, it := range g.Items {
			words = append(words, it.Word)
		}
		if !reflect.DeepEqual(words, tt.want) {
			t.Errorf("%s: words = %q, want %q", tt.input, words, tt.want)
		}
	}
}

func TestRipgrepTakesTheTypedTextLiterally(t *testing.T) {
	if _, err := exec.LookPath("rg"); err != nil {
		t.Skip("rg is not installed")
	}
	cwd := t.TempDir()
	if err := os.WriteFile(filepath.Join(cwd, "a.txt"), []byte("alpxhabet alp.habet\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	b := cmp.New().AddUI(cmptest.NewUI("test")).AddSource(New(Params{}))
	b.PatchGlobal(cmp.Config{
		UI:            "test",
		Sources:       []string{"rg"},
		SourceOptions: map[string]cmp.SourceOption{"rg": {KeywordPattern: `[\w.]+`}},
	})
	p, err := b.Plugin()
	if err != nil {
		t.Fatal(err)
	}
	var shown []cmp.Item
	h := host(cwd)
	h.Funcs["goda_cmp_testui#test#show"] = func(a ...any) (any, error) {
		shown = a[0].(map[string]any)["items"].([]cmp.Item)
		return nil, nil
	}
	h.Funcs["goda_cmp_testui#test#hide"] = func(...any) (any, error) { return nil, nil }
	input := "alp.h"
	request := map[string]any{
		"seq": int64(1), "tick": int64(1), "bufnr": int64(1), "lnum": int64(1),
		"col": int64(len(input) + 1), "input": input,
	}
	if _, err := p.Handlers()["complete"](context.Background(), h, []any{request}); err != nil {
		t.Fatal(err)
	}
	if len(shown) != 1 || shown[0].Word != "alp.habet" {
		t.Errorf("shown = %+v", shown)
	}
}
