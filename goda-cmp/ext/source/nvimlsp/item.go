package nvimlsp

import (
	"bytes"
	stdcmp "cmp"
	"encoding/json"
	"strings"

	"github.com/Shougo/goda-cmp.vim/cmp"
)

const (
	snippetFormat  = 2
	kindSnippet    = 15
	applyKindMerge = 2
	// snippetIndicator marks a snippet in the popup, as in ddc-source-lsp.
	snippetIndicator = "~"
)

type position struct {
	Line      int `json:"line"`
	Character int `json:"character"`
}

type lspRange struct {
	Start position `json:"start"`
	End   position `json:"end"`
}

// textEdit is a TextEdit (Range) or an InsertReplaceEdit (Insert, Replace).
type textEdit struct {
	NewText string    `json:"newText"`
	Range   *lspRange `json:"range,omitempty"`
	Insert  *lspRange `json:"insert,omitempty"`
	Replace *lspRange `json:"replace,omitempty"`
}

// insertRange is the range an accepted item replaces. It is the insert range
// of an InsertReplaceEdit, ddc-source-lsp's default confirmBehavior.
func (e *textEdit) insertRange() *lspRange {
	if e.Insert != nil {
		return e.Insert
	}
	return e.Range
}

type completionItem struct {
	Label        string `json:"label"`
	LabelDetails *struct {
		Detail      string `json:"detail"`
		Description string `json:"description"`
	} `json:"labelDetails"`
	Kind                int             `json:"kind"`
	Detail              string          `json:"detail"`
	Documentation       json.RawMessage `json:"documentation"`
	SortText            string          `json:"sortText"`
	FilterText          string          `json:"filterText"`
	InsertText          string          `json:"insertText"`
	InsertTextFormat    int             `json:"insertTextFormat"`
	TextEdit            *textEdit       `json:"textEdit"`
	TextEditText        string          `json:"textEditText"`
	AdditionalTextEdits json.RawMessage `json:"additionalTextEdits"`
	Command             json.RawMessage `json:"command"`
	Data                json.RawMessage `json:"data"`
}

func (ci *completionItem) isSnippet() bool { return ci.InsertTextFormat == snippetFormat }

func (ci *completionItem) info() string {
	doc := documentation(ci.Documentation)
	switch {
	case ci.Detail == "":
		return doc
	case doc == "":
		return ci.Detail
	}
	return ci.Detail + "\n\n" + doc
}

// abbr is what the popup shows for the item.
func (ci *completionItem) abbr() string {
	s := ci.Label
	if ci.LabelDetails != nil {
		s += ci.LabelDetails.Detail
	}
	if ci.isSnippet() {
		s += snippetIndicator
	}
	if ci.LabelDetails != nil && ci.LabelDetails.Description != "" {
		s += " " + ci.LabelDetails.Description
	}
	return s
}

// documentation reads a string or a MarkupContent.
func documentation(raw json.RawMessage) string {
	if len(raw) == 0 {
		return ""
	}
	var s string
	if json.Unmarshal(raw, &s) == nil {
		return s
	}
	var mc struct {
		Value string `json:"value"`
	}
	if json.Unmarshal(raw, &mc) == nil {
		return mc.Value
	}
	return ""
}

var kindNames = [...]string{
	"", "Text", "Method", "Function", "Constructor", "Field", "Variable",
	"Class", "Interface", "Module", "Property", "Unit", "Value", "Enum",
	"Keyword", "Snippet", "Color", "File", "Reference", "Folder",
	"EnumMember", "Constant", "Struct", "Event", "Operator", "TypeParameter",
}

func kindName(k int) string {
	if k > 0 && k < len(kindNames) {
		return kindNames[k]
	}
	return kindNames[1]
}

// editRange is itemDefaults.editRange: a Range or {insert, replace}.
type editRange struct {
	lspRange
	Insert  *lspRange `json:"insert"`
	Replace *lspRange `json:"replace"`
}

type itemDefaults struct {
	EditRange        *editRange      `json:"editRange"`
	InsertTextFormat int             `json:"insertTextFormat"`
	InsertTextMode   int             `json:"insertTextMode"`
	Data             json.RawMessage `json:"data"`
}

// applyKind says how itemDefaults combine with an item's own value (LSP
// 3.18). Neovim's default capabilities announce support for it.
type applyKind struct {
	Data int `json:"data"`
}

type completionList struct {
	IsIncomplete bool              `json:"isIncomplete"`
	ItemDefaults *itemDefaults     `json:"itemDefaults"`
	ApplyKind    *applyKind        `json:"applyKind"`
	Items        []json.RawMessage `json:"items"`
}

// decodeCompletion reads a completion result: null, CompletionItem[] or a
// CompletionList. Items stay raw, since completionItem/resolve gets them back.
func decodeCompletion(raw json.RawMessage) (completionList, error) {
	var l completionList
	s := bytes.TrimSpace(raw)
	switch {
	case len(s) == 0 || string(s) == "null":
		return l, nil
	case s[0] == '[':
		return l, json.Unmarshal(s, &l.Items)
	}
	return l, json.Unmarshal(s, &l)
}

// fill gives ci the defaults of the list it came in.
func (l *completionList) fill(ci *completionItem) {
	d := l.ItemDefaults
	if d == nil {
		return
	}
	if ci.InsertTextFormat == 0 {
		ci.InsertTextFormat = d.InsertTextFormat
	}
	ci.Data = l.data(ci.Data)
	if ci.TextEdit == nil && d.EditRange != nil {
		e := &textEdit{NewText: stdcmp.Or(ci.TextEditText, ci.InsertText, ci.Label)}
		if d.EditRange.Insert != nil {
			e.Insert, e.Replace = d.EditRange.Insert, d.EditRange.Replace
		} else {
			e.Range = &d.EditRange.lspRange
		}
		ci.TextEdit = e
	}
}

// data combines an item's data with the default, by applyKind.
func (l *completionList) data(own json.RawMessage) json.RawMessage {
	def := l.ItemDefaults.Data
	if len(own) == 0 {
		return def
	}
	if len(def) == 0 || l.ApplyKind == nil || l.ApplyKind.Data != applyKindMerge {
		return own
	}
	var a, b map[string]json.RawMessage
	if json.Unmarshal(def, &a) != nil || json.Unmarshal(own, &b) != nil {
		return own
	}
	for k, v := range b {
		a[k] = v
	}
	merged, err := json.Marshal(a)
	if err != nil {
		return own
	}
	return merged
}

// filled is raw with what fill gave ci, for completionItem/resolve.
func (l *completionList) filled(raw json.RawMessage, ci *completionItem) json.RawMessage {
	d := l.ItemDefaults
	if d == nil {
		return raw
	}
	var m map[string]json.RawMessage
	if json.Unmarshal(raw, &m) != nil {
		return raw
	}
	set := func(key string, v any) {
		if b, err := json.Marshal(v); err == nil {
			m[key] = b
		}
	}
	if len(ci.Data) > 0 {
		m["data"] = ci.Data
	}
	if ci.TextEdit != nil {
		set("textEdit", ci.TextEdit)
	}
	if ci.InsertTextFormat != 0 {
		set("insertTextFormat", ci.InsertTextFormat)
	}
	if _, ok := m["insertTextMode"]; !ok && d.InsertTextMode != 0 {
		set("insertTextMode", d.InsertTextMode)
	}
	b, err := json.Marshal(m)
	if err != nil {
		return raw
	}
	return b
}

// request is the text of one completion request.
type request struct {
	bufnr, lnum int
	input       string // the line before the cursor
	after       string // the line after the cursor
	keyword     int    // where the keyword before the cursor starts
}

func newRequest(c *cmp.Context) *request {
	return &request{bufnr: c.Bufnr, lnum: c.Lnum, input: c.Input, after: c.NextInput, keyword: c.KeywordStart()}
}

func (r *request) word() word { return word{r.bufnr, r.lnum, r.keyword} }

// edit is what accepting an item does to the line, in bytes of the request's
// line.
type edit struct {
	start, end int
	text       string
}

// edit returns false for an edit that does not stay on the cursor line, which
// the popup cannot offer.
func (r *request) edit(ci *completionItem, encoding string) (edit, bool) {
	if ci.TextEdit == nil {
		return edit{r.keyword, len(r.input), stdcmp.Or(ci.InsertText, strings.TrimSpace(ci.Label))}, true
	}
	rg := ci.TextEdit.insertRange()
	if rg == nil || rg.Start.Line != r.lnum-1 || rg.End.Line != r.lnum-1 {
		return edit{}, false
	}
	line := r.input + r.after
	start := min(byteOffset(line, rg.Start.Character, encoding), len(r.input))
	return edit{start, byteOffset(line, rg.End.Character, encoding), ci.TextEdit.NewText}, true
}

// wordStart is where the popup starts the word of an edit. Some servers start
// the range at the indentation before the keyword.
func (r *request) wordStart(e edit) int {
	if e.start >= r.keyword {
		return e.start
	}
	blank := r.input[e.start:r.keyword]
	return e.start + len(blank) - len(strings.TrimLeft(blank, " \t"))
}

// filterText is what matchers compare with the text from start to the cursor.
// clangd completes "obj.p" to "obj->prop" with the range on the dot and the
// filter text "prop", which needs the dot to be compared at all.
func (r *request) filterText(ci *completionItem, start int) string {
	filter := strings.TrimLeft(stdcmp.Or(ci.FilterText, ci.Label), " \t")
	if start < r.keyword {
		if gap := r.input[start:r.keyword]; !strings.HasPrefix(filter, gap) {
			return gap + filter
		}
	}
	return filter
}

// candidate is an item and where its word starts.
type candidate struct {
	item  cmp.Item
	start int
}

// candidates converts the items of one client's answer.
func (r *request) candidates(cl client, l *completionList) []candidate {
	out := make([]candidate, 0, len(l.Items))
	for _, raw := range l.Items {
		var ci completionItem
		if json.Unmarshal(raw, &ci) != nil || ci.Label == "" {
			continue
		}
		l.fill(&ci)
		e, ok := r.edit(&ci, cl.Encoding)
		if !ok {
			continue
		}
		start := r.wordStart(e)
		out = append(out, candidate{
			item: cmp.Item{
				Word:       popupWord(&ci, e.text),
				Abbr:       ci.abbr(),
				Kind:       kindName(ci.Kind),
				Info:       ci.info(),
				FilterText: r.filterText(&ci, start),
				SortText:   stdcmp.Or(ci.SortText, ci.Label),
				Dup:        1,
				UserData:   &itemData{client: cl, request: r, list: l, raw: raw, item: ci},
			},
			start: start,
		})
	}
	return out
}

// popupWord is the text shown in the buffer while the item is selected. The
// text of the item replaces it on accept.
func popupWord(ci *completionItem, text string) string {
	if ci.isSnippet() {
		text = stripSnippet(text)
	}
	s := selectText(strings.TrimSpace(text))
	if i := strings.IndexAny(s, "\r\n"); i >= 0 {
		s = s[:i]
	}
	return stdcmp.Or(s, strings.TrimSpace(ci.Label))
}

// placeholder is the answer to a request of older text. A request that ends
// without items makes the engine close the popup, and pum.vim takes that as
// accepting the item the user just moved to. A list goes to the UI instead,
// which drops it because of its older text. The word matches what is typed and
// is not empty, so that matchers and the engine keep it.
func (r *request) placeholder() cmp.Gathered {
	item := cmp.Item{Word: r.input[r.keyword:] + "_"}
	return cmp.Gathered{Start: r.keyword, Items: []cmp.Item{item}, Incomplete: true}
}

// gathered expresses the candidates relative to the leftmost start, the one
// column the popup replaces from.
func (r *request) gathered(found []candidate, incomplete bool) cmp.Gathered {
	start := r.keyword
	for i, c := range found {
		if i == 0 || c.start < start {
			start = c.start
		}
	}
	items := make([]cmp.Item, len(found))
	for i, c := range found {
		it := c.item
		if pre := r.input[start:c.start]; pre != "" {
			it.Word = pre + it.Word
			it.FilterText = pre + it.FilterText
		}
		items[i] = it
	}
	return cmp.Gathered{Start: start, Items: items, Incomplete: incomplete}
}
