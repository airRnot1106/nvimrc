package main

import (
	"context"
	"encoding/json"
	"time"

	"github.com/Shougo/goda-cmp.vim/cmp"
	"github.com/Shougo/goda.vim/sdk"
)

type lspItem struct {
	Word       string `json:"word"`
	Abbr       string `json:"abbr"`
	Kind       string `json:"kind"`
	FilterText string `json:"filterText"`
	SortText   string `json:"sortText"`
	Snippet    string `json:"snippet"`
	Edits      any    `json:"edits"`
	Encoding   string `json:"encoding"`
}

type lspResult struct {
	Done       bool      `json:"done"`
	Items      []lspItem `json:"items"`
	Incomplete bool      `json:"incomplete"`
}

type nvimLSP struct{}

func (nvimLSP) Name() string { return "nvimlsp" }

func (nvimLSP) Gather(ctx context.Context, h sdk.Host, c *cmp.Context) (cmp.Gathered, error) {
	id, err := h.Call(ctx, "luaeval", "require('nvimlsp_spike').start(_A)", c.Bufnr)
	if err != nil {
		return cmp.Gathered{}, err
	}
	tick := time.NewTicker(5 * time.Millisecond)
	defer tick.Stop()
	for {
		select {
		case <-ctx.Done():
			return cmp.Gathered{}, ctx.Err()
		case <-tick.C:
		}
		raw, err := h.Call(ctx, "luaeval", "require('nvimlsp_spike').poll(_A)", id)
		if err != nil {
			return cmp.Gathered{}, err
		}
		b, err := json.Marshal(raw)
		if err != nil {
			return cmp.Gathered{}, err
		}
		var r lspResult
		if err := json.Unmarshal(b, &r); err != nil {
			return cmp.Gathered{}, err
		}
		if !r.Done {
			continue
		}
		items := make([]cmp.Item, 0, len(r.Items))
		for _, it := range r.Items {
			items = append(items, cmp.Item{
				Word: it.Word, Abbr: it.Abbr, Kind: it.Kind, Dup: 1,
				FilterText: it.FilterText, SortText: it.SortText, UserData: it,
			})
		}
		return cmp.Gathered{Start: c.KeywordStart(), Items: items, Incomplete: r.Incomplete}, nil
	}
}

func (nvimLSP) OnCompleteDone(ctx context.Context, h sdk.Host, a cmp.DoneArgs) error {
	it, ok := a.Item.UserData.(lspItem)
	if !ok || (it.Snippet == "" && it.Edits == nil) {
		return nil
	}
	_, err := h.Call(ctx, "luaeval", "require('nvimlsp_spike').done(_A)", it)
	return err
}
