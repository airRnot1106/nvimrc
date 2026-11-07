// Package copilot is a completion source for GitHub Copilot through
// copilot.lua. It is a port of ddc-source-copilot
// (https://github.com/Shougo/ddc-source-copilot, MIT license, Copyright
// Shougo Matsushita) without its copilot.vim integration. The Lua side is
// lua/goda_cmp_copilot.lua of this configuration.
package copilot

import (
	"context"
	"strings"
	"time"
	"unicode"

	"github.com/Shougo/goda-cmp.vim/cmp"
	"github.com/Shougo/goda.vim/sdk"
)

// Params are the parameters of the source.
type Params struct {
	// Copilot is the integration to use. Only "lua" gathers anything.
	Copilot string `json:"copilot"`
}

// copilot.lua answers through a Lua callback, and Lua cannot reach a Gather
// in progress, so the source asks for the answer repeatedly.
const pollInterval = 20 * time.Millisecond

const placeholder = "?"

type source struct{ p Params }

// New returns the source, named "copilot".
func New(p Params) cmp.Source { return source{p} }

func (source) Name() string { return "copilot" }

// WithParams sets the parameters from Vim script (sourceParams).
func (s source) WithParams(p cmp.Params) (any, error) {
	np, err := cmp.PatchParams(s.p, p)
	if err != nil {
		return nil, err
	}
	return New(np), nil
}

func (s source) Gather(ctx context.Context, h sdk.Host, c *cmp.Context) (cmp.Gathered, error) {
	return cmp.Collect(ctx, h, c, s)
}

// GatherStream emits an empty list first: an answer takes longer than
// hideTimeout, and the popup of the other sources must stay open meanwhile.
func (s source) GatherStream(ctx context.Context, h sdk.Host, c *cmp.Context, emit func(cmp.Gathered) error) error {
	start := c.KeywordStart()
	if err := emit(cmp.Gathered{Start: start, Incomplete: true}); err != nil {
		return err
	}
	if s.p.Copilot != "lua" {
		return nil
	}
	if _, err := h.Call(ctx, "luaeval", `require("goda_cmp_copilot").request(_A)`, c.Seq); err != nil {
		return err
	}
	ticker := time.NewTicker(pollInterval)
	defer ticker.Stop()
	for {
		select {
		case <-ctx.Done():
			return ctx.Err()
		case <-ticker.C:
		}
		v, err := h.Call(ctx, "luaeval", `require("goda_cmp_copilot").poll(_A)`, c.Seq)
		if err != nil {
			return err
		}
		if v == nil {
			continue
		}
		var texts []string
		if err := sdk.Decode(v, &texts); err != nil {
			return err
		}
		items := make([]cmp.Item, 0, len(texts))
		for _, text := range texts {
			items = append(items, item(text, start))
		}
		return emit(cmp.Gathered{Start: start, Items: items, Incomplete: true})
	}
}

// OnCompleteDone puts the suggestion in place of its placeholder word.
func (source) OnCompleteDone(ctx context.Context, h sdk.Host, a cmp.DoneArgs) error {
	text, ok := a.Item.UserData.(string)
	if !ok {
		return nil
	}
	_, err := h.Call(ctx, "luaeval", `require("goda_cmp_copilot").accept(_A[1], _A[2])`,
		[]any{a.Item.Word, strings.Split(text, "\n")})
	return err
}

// item makes the candidate of a suggestion, whose text starts at the
// beginning of the line. A popup item holds one line, so a text with control
// characters is shown and inserted in a printable form; UserData keeps the
// text for OnCompleteDone.
func item(text string, start int) cmp.Item {
	completion := text[min(start, len(text)):]
	it := cmp.Item{Word: completion, Info: dedent(text)}
	if strings.ContainsFunc(completion, unicode.IsControl) {
		it.Word = printable(completion, func(rune) string { return placeholder })
		it.Abbr = printable(completion, caret)
		it.UserData = completion
	}
	return it
}

func printable(s string, replace func(rune) string) string {
	var b strings.Builder
	for _, r := range s {
		if unicode.IsControl(r) {
			b.WriteString(replace(r))
		} else {
			b.WriteRune(r)
		}
	}
	return b.String()
}

// caret is Vim's display of a control character, such as ^J.
func caret(r rune) string {
	switch {
	case r <= 0x1f:
		return "^" + string(r+0x40)
	case r == 0x7f:
		return "^?"
	}
	return "~" + string(r-0x40)
}

// dedent removes the indent of the first line from every line.
func dedent(text string) string {
	n := len(text) - len(strings.TrimLeftFunc(text, unicode.IsSpace))
	lines := strings.Split(text, "\n")
	for i, l := range lines {
		lines[i] = l[min(n, len(l)):]
	}
	return strings.Join(lines, "\n")
}
