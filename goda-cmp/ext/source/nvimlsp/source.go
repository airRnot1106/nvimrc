// The source polls Neovim for the answers. A notification from Neovim cannot
// reach it during a gather: goda.vim handles the notifications of the editor
// one at a time, and cmp.complete, which runs the gather, is one of them.
package nvimlsp

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"log"
	"maps"
	"strings"
	"sync"
	"time"

	"github.com/Shougo/goda-cmp.vim/cmp"
	"github.com/Shougo/goda.vim/sdk"
)

const (
	startExpr   = "require('goda_cmp_lsp').start(_A)"
	pollExpr    = "require('goda_cmp_lsp').poll(_A)"
	cancelExpr  = "require('goda_cmp_lsp').cancel(_A)"
	resolveExpr = "require('goda_cmp_lsp').resolve(_A)"
	confirmExpr = "require('goda_cmp_lsp').confirm(_A)"
)

const pollInterval = time.Millisecond

const resolveTimeout = time.Second

type Params struct {
	EnableResolveItem        bool `json:"enableResolveItem"`
	EnableAdditionalTextEdit bool `json:"enableAdditionalTextEdit"`
}

type Source struct {
	p Params

	mu             sync.Mutex
	incompleteWord word
}

type word struct{ bufnr, lnum, start int }

func New(p Params) *Source { return &Source{p: p} }

func (*Source) Name() string { return "nvimlsp" }

func (s *Source) WithParams(p cmp.Params) (any, error) {
	np, err := cmp.PatchParams(s.p, p)
	if err != nil {
		return nil, err
	}
	return New(np), nil
}

func (s *Source) Gather(ctx context.Context, h sdk.Host, c *cmp.Context) (cmp.Gathered, error) {
	return cmp.Collect(ctx, h, c, s)
}

// It is a stream because the engine leaves a
// plain source out of a request after hideTimeout, which vtsls can exceed.
func (s *Source) GatherStream(ctx context.Context, h sdk.Host, c *cmp.Context, emit func(cmp.Gathered) error) error {
	if c.Mode != "" && c.Mode != "i" {
		return nil
	}
	r := newRequest(c)
	id, err := s.start(ctx, h, r, c.Tick)
	if err != nil || id == 0 {
		return err
	}
	var found []candidate
	incomplete := false
	return await(ctx, h, id, func(a *answer) error {
		if a.Stale {
			return emit(r.placeholder())
		}
		for _, res := range a.Results {
			if res.Error != "" {
				log.Printf("nvimlsp: client %d: %s", res.ID, res.Error)
				continue
			}
			list, err := decodeCompletion(res.Result)
			if err != nil {
				log.Printf("nvimlsp: client %d: %v", res.ID, err)
				continue
			}
			found = append(found, r.candidates(res.client, &list)...)
			incomplete = incomplete || list.IsIncomplete
		}
		if a.Done {
			s.setIncomplete(r, incomplete)
		}
		return emit(r.gathered(found, incomplete))
	})
}

func await(ctx context.Context, h sdk.Host, id int, each func(*answer) error) error {
	running := true
	defer func() {
		if !running {
			return
		}
		if err := h.Notify(context.Background(), "luaeval", cancelExpr, id); err != nil {
			log.Printf("nvimlsp: cancel: %v", err)
		}
	}()
	tick := time.NewTicker(pollInterval)
	defer tick.Stop()
	for {
		select {
		case <-ctx.Done():
			return ctx.Err()
		case <-tick.C:
		}
		a, err := poll(ctx, h, id)
		if err != nil {
			return err
		}
		if a == nil {
			continue
		}
		running = !a.Done
		if err := each(a); err != nil {
			return err
		}
		if a.Done {
			return nil
		}
	}
}

func (s *Source) start(ctx context.Context, h sdk.Host, r *request, tick int64) (int, error) {
	v, err := h.Call(ctx, "luaeval", startExpr, map[string]any{
		"bufnr":      r.bufnr,
		"tick":       tick,
		"lnum":       r.lnum,
		"input":      r.input,
		"incomplete": s.wasIncomplete(r),
	})
	if err != nil {
		return 0, err
	}
	var id int
	if err := sdk.Decode(v, &id); err != nil {
		return 0, fmt.Errorf("nvimlsp: start answered %v: %w", v, err)
	}
	return id, nil
}

func (s *Source) wasIncomplete(r *request) bool {
	s.mu.Lock()
	defer s.mu.Unlock()
	return s.incompleteWord == r.word()
}

func (s *Source) setIncomplete(r *request, incomplete bool) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.incompleteWord = word{}
	if incomplete {
		s.incompleteWord = r.word()
	}
}

type client struct {
	ID         int    `json:"clientId"`
	Encoding   string `json:"offsetEncoding"`
	Resolvable bool   `json:"resolvable"`
}

type clientResult struct {
	client
	Result json.RawMessage `json:"result"`
	Error  string          `json:"error"`
}

type answer struct {
	Done    bool           `json:"done"`
	Stale   bool           `json:"stale"`
	Results []clientResult `json:"results"`
}

func poll(ctx context.Context, h sdk.Host, id int) (*answer, error) {
	v, err := h.Call(ctx, "luaeval", pollExpr, id)
	if err != nil {
		return nil, err
	}
	text, _ := v.(string)
	if text == "" {
		return nil, nil
	}
	var a answer
	if err := json.Unmarshal([]byte(text), &a); err != nil {
		return nil, fmt.Errorf("nvimlsp: poll: %w", err)
	}
	return &a, nil
}

type itemData struct {
	client   client
	request  *request
	list     *completionList
	raw      json.RawMessage
	item     completionItem
	resolved bool
}

func (d *itemData) resolve(ctx context.Context, h sdk.Host) (*itemData, error) {
	if d.resolved || !d.client.Resolvable {
		return d, nil
	}
	raw := d.list.filled(d.raw, &d.item)
	v, err := h.Call(ctx, "luaeval", resolveExpr, map[string]any{
		"clientId": d.client.ID,
		"bufnr":    d.request.bufnr,
		"item":     string(raw),
	})
	if err != nil {
		return d, err
	}
	var id int
	if err := sdk.Decode(v, &id); err != nil {
		return d, fmt.Errorf("nvimlsp: resolve answered %v: %w", v, err)
	}
	if id == 0 {
		return d, nil
	}
	ctx, cancel := context.WithTimeout(ctx, resolveTimeout)
	defer cancel()
	out := d
	err = await(ctx, h, id, func(a *answer) error {
		for _, res := range a.Results {
			if res.Error != "" {
				return errors.New(res.Error)
			}
			merged, err := overlay(raw, res.Result)
			if err != nil {
				return err
			}
			var ci completionItem
			if err := json.Unmarshal(merged, &ci); err != nil {
				return err
			}
			out = &itemData{client: d.client, request: d.request, list: d.list, raw: merged, item: ci, resolved: true}
		}
		return nil
	})
	if err != nil {
		return d, fmt.Errorf("nvimlsp: resolve: %w", err)
	}
	return out, nil
}

func overlay(item, resolved json.RawMessage) (json.RawMessage, error) {
	if len(resolved) == 0 || string(resolved) == "null" {
		return item, nil
	}
	var base, over map[string]json.RawMessage
	if err := json.Unmarshal(item, &base); err != nil {
		return nil, err
	}
	if err := json.Unmarshal(resolved, &over); err != nil {
		return nil, err
	}
	maps.Copy(base, over)
	return json.Marshal(base)
}

func (s *Source) Resolve(ctx context.Context, h sdk.Host, a cmp.DoneArgs) (cmp.Item, error) {
	d, ok := a.Item.UserData.(*itemData)
	if !ok || !s.p.EnableResolveItem {
		return a.Item, nil
	}
	r, err := d.resolve(ctx, h)
	if err != nil {
		return a.Item, err
	}
	it := a.Item
	it.UserData = r
	// pum.vim reports each info update as a new selection, so an unchanged info is left out to end the exchange.
	it.Info = ""
	if info := r.item.info(); info != a.Item.Info {
		it.Info = info
	}
	return it, nil
}

type confirmation struct {
	Bufnr               int             `json:"bufnr"`
	Lnum                int             `json:"lnum"`
	Input               string          `json:"input"`
	Word                string          `json:"word"`
	Start               int             `json:"start"`
	Tail                int             `json:"tail"`
	Text                string          `json:"text"`
	Snippet             bool            `json:"snippet"`
	ClientID            int             `json:"clientId"`
	OffsetEncoding      string          `json:"offsetEncoding"`
	AdditionalTextEdits json.RawMessage `json:"additionalTextEdits,omitempty"`
	Command             json.RawMessage `json:"command,omitempty"`
}

func (s *Source) OnCompleteDone(ctx context.Context, h sdk.Host, a cmp.DoneArgs) error {
	d, ok := a.Item.UserData.(*itemData)
	if !ok {
		return nil
	}
	if s.p.EnableResolveItem {
		r, err := d.resolve(ctx, h)
		if err != nil {
			log.Printf("nvimlsp: %v", err)
		}
		d = r
	}
	e, ok := d.request.edit(&d.item, d.client.Encoding)
	if !ok {
		return nil
	}
	c := confirmation{
		Bufnr:          d.request.bufnr,
		Lnum:           d.request.lnum,
		Input:          d.request.input,
		Word:           a.Item.Word,
		Start:          e.start,
		Tail:           max(0, e.end-len(d.request.input)),
		Text:           e.text,
		Snippet:        d.item.isSnippet(),
		ClientID:       d.client.ID,
		OffsetEncoding: d.client.Encoding,
		Command:        d.item.Command,
	}
	if s.p.EnableAdditionalTextEdit {
		c.AdditionalTextEdits = d.item.AdditionalTextEdits
	}
	b, err := json.Marshal(c)
	if err != nil {
		return err
	}
	_, err = h.Call(ctx, "luaeval", confirmExpr, string(b))
	return err
}

func (s *Source) Preview(ctx context.Context, h sdk.Host, a cmp.DoneArgs) (cmp.Preview, error) {
	d, ok := a.Item.UserData.(*itemData)
	if !ok {
		return cmp.Preview{}, nil
	}
	r, err := d.resolve(ctx, h)
	if err != nil {
		log.Printf("nvimlsp: %v", err)
	}
	fence := func(body string) []string {
		lines := []string{"```" + a.Context.Filetype}
		lines = append(lines, splitLines(body)...)
		return append(lines, "```")
	}
	ci := &r.item
	if ci.Kind == kindSnippet {
		if e, ok := r.request.edit(ci, r.client.Encoding); ok {
			return cmp.Preview{Kind: cmp.PreviewMarkdown, Contents: fence(stripSnippet(e.text))}, nil
		}
	}
	var contents []string
	add := func(lines ...string) {
		if len(contents) > 0 {
			contents = append(contents, "---")
		}
		contents = append(contents, lines...)
	}
	if ci.Detail != "" {
		add(fence(ci.Detail)...)
	}
	if doc := documentation(ci.Documentation); doc != "" {
		add(splitLines(doc)...)
	}
	return cmp.Preview{Kind: cmp.PreviewMarkdown, Contents: contents}, nil
}

func splitLines(s string) []string {
	return strings.Split(strings.ReplaceAll(strings.ReplaceAll(s, "\r\n", "\n"), "\r", "\n"), "\n")
}

var (
	_ cmp.StreamSource  = (*Source)(nil)
	_ cmp.Resolver      = (*Source)(nil)
	_ cmp.CompleteDoner = (*Source)(nil)
	_ cmp.Previewer     = (*Source)(nil)
	_ cmp.Configurable  = (*Source)(nil)
)
