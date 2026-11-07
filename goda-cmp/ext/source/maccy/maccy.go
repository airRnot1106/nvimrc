// Package maccy is a completion source for the recent clipboard history of
// Maccy. It is a port of ddc-source-maccy
// (https://github.com/airRnot1106/ddc-source-maccy) without its Vim support:
// OnCompleteDone needs Neovim.
package maccy

import (
	"context"
	"database/sql"
	"fmt"
	"net/url"
	"os"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/Shougo/goda-cmp.vim/cmp"
	"github.com/Shougo/goda.vim/sdk"
	_ "modernc.org/sqlite"
)

// Params are the parameters of the source. The zero value gathers nothing.
type Params struct {
	// RecentMs is how old a clip may be.
	RecentMs int `json:"recentMs"`
	// CacheTtlMs is how long the result of a query is reused; 0 or less
	// disables the cache.
	CacheTtlMs int `json:"cacheTtlMs"`
	// Types are the pasteboard types to read, such as
	// "public.utf8-plain-text".
	Types []string `json:"types"`
	// DBPath is Maccy's Storage.sqlite; a leading "~" is the home directory.
	DBPath string `json:"dbPath"`
	// MaxByteLength drops the longer clips.
	MaxByteLength int `json:"maxByteLength"`
	// Dedupe keeps only the newest clip of each value.
	Dedupe bool `json:"dedupe"`
	// TrimTrailingNewline removes the trailing newlines of a clip, before
	// Dedupe compares it, and drops a clip with nothing else.
	TrimTrailingNewline bool `json:"trimTrailingNewline"`
	// ExcludeAfterUse hides a clip accepted MaxUseCount times. Copying it
	// again makes it new.
	ExcludeAfterUse bool `json:"excludeAfterUse"`
	MaxUseCount     int  `json:"maxUseCount"`
}

// clip is one history entry. Its line breaks are "\n".
type clip struct {
	value    string
	copiedAt int64 // Unix seconds
}

type source struct {
	p   Params
	now func() time.Time
	// One value per set of parameters makes one cache per set.
	cache *clipCache
	// Shared by all values: a use of a clip does not depend on the parameters.
	uses *useCounts
}

// New returns the source, named "maccy".
func New(p Params) cmp.Source {
	return &source{p: p, now: time.Now, cache: &clipCache{}, uses: &useCounts{counts: map[clip]int{}}}
}

func (*source) Name() string { return "maccy" }

// WithParams sets the parameters from Vim script (sourceParams).
func (s *source) WithParams(p cmp.Params) (any, error) {
	np, err := cmp.PatchParams(s.p, p)
	if err != nil {
		return nil, err
	}
	return &source{p: np, now: s.now, cache: &clipCache{}, uses: s.uses}, nil
}

func (s *source) Gather(ctx context.Context, _ sdk.Host, c *cmp.Context) (cmp.Gathered, error) {
	now := s.now()
	clips, err := s.cache.get(now, time.Duration(s.p.CacheTtlMs)*time.Millisecond, func() ([]clip, error) {
		return load(ctx, s.p, now)
	})
	if err != nil {
		return cmp.Gathered{}, err
	}
	if s.p.ExcludeAfterUse {
		clips = s.uses.unused(clips, s.p.MaxUseCount)
	}
	items := make([]cmp.Item, 0, len(clips))
	for _, cl := range clips {
		first, _, _ := strings.Cut(cl.value, "\n")
		items = append(items, cmp.Item{
			Word:     first,
			Abbr:     relativeTime(now.Unix()-cl.copiedAt) + "  " + fold(cl.value),
			Info:     cl.value,
			UserData: cl,
		})
	}
	return cmp.Gathered{Start: c.KeywordStart(), Items: items}, nil
}

// OnCompleteDone counts the use and inserts the lines after the first one,
// which is the word the UI inserted.
func (s *source) OnCompleteDone(ctx context.Context, h sdk.Host, a cmp.DoneArgs) error {
	cl, ok := a.Item.UserData.(clip)
	if !ok {
		return nil
	}
	if s.p.ExcludeAfterUse {
		s.uses.record(cl)
	}
	_, rest, ok := strings.Cut(cl.value, "\n")
	if !ok {
		return nil
	}
	tail := strings.Split(rest, "\n")
	v, err := h.Call(ctx, "nvim_win_get_cursor", 0)
	if err != nil {
		return err
	}
	var cursor [2]int // the 1-based row and the 0-based byte column
	if err := sdk.Decode(v, &cursor); err != nil {
		return err
	}
	row, col := cursor[0], cursor[1]
	if _, err := h.Call(ctx, "nvim_buf_set_text", 0, row-1, col, row-1, col, append([]string{""}, tail...)); err != nil {
		return err
	}
	_, err = h.Call(ctx, "nvim_win_set_cursor", 0, []int{row + len(tail), len(tail[len(tail)-1])})
	return err
}

// clipCache reuses the last clips while they are fresh. Holding the lock
// across fetch makes concurrent requests share one query.
type clipCache struct {
	mu    sync.Mutex
	clips []clip
	at    time.Time
}

func (c *clipCache) get(now time.Time, ttl time.Duration, fetch func() ([]clip, error)) ([]clip, error) {
	c.mu.Lock()
	defer c.mu.Unlock()
	if !c.at.IsZero() && now.Sub(c.at) < ttl {
		return c.clips, nil
	}
	clips, err := fetch()
	if err != nil {
		return nil, err
	}
	c.clips, c.at = clips, now
	return clips, nil
}

// useCounts counts how often each clip was accepted. A copy again has a new
// copiedAt, so it is another key.
type useCounts struct {
	mu     sync.Mutex
	counts map[clip]int
}

func (u *useCounts) record(cl clip) {
	u.mu.Lock()
	defer u.mu.Unlock()
	u.counts[cl]++
}

// unused returns the clips used fewer than limit times and forgets the counts
// of what is no longer in clips.
func (u *useCounts) unused(clips []clip, limit int) []clip {
	u.mu.Lock()
	defer u.mu.Unlock()
	live := make(map[clip]int, len(u.counts))
	out := make([]clip, 0, len(clips))
	for _, cl := range clips {
		n, used := u.counts[cl]
		if used {
			live[cl] = n
		}
		if n < limit {
			out = append(out, cl)
		}
	}
	u.counts = live
	return out
}

// Maccy stores Core Data timestamps: seconds since 2001-01-01 UTC.
const coreDataEpoch = 978307200

// load reads the clips, newest first. The connection lives for one query, so
// that nothing holds Maccy's database between two refreshes of the cache.
func load(ctx context.Context, p Params, now time.Time) ([]clip, error) {
	if p.DBPath == "" || len(p.Types) == 0 || p.MaxByteLength <= 0 {
		return nil, nil
	}
	db, err := sql.Open("sqlite", dsn(p.DBPath))
	if err != nil {
		return nil, err
	}
	defer db.Close()

	cutoff := now.Unix() - int64(p.RecentMs/1000) - coreDataEpoch
	args := make([]any, 0, len(p.Types)+2)
	for _, t := range p.Types {
		args = append(args, t)
	}
	args = append(args, p.MaxByteLength, cutoff)
	rows, err := db.QueryContext(ctx, fmt.Sprintf(`
		SELECT item.ZLASTCOPIEDAT, CAST(c.ZVALUE AS TEXT)
		FROM ZHISTORYITEMCONTENT c
		JOIN ZHISTORYITEM item ON item.Z_PK = c.ZITEM
		WHERE c.ZTYPE IN (?%s)
		  AND LENGTH(c.ZVALUE) <= ?
		  AND item.ZLASTCOPIEDAT >= ?
		ORDER BY item.ZLASTCOPIEDAT DESC`, strings.Repeat(", ?", len(p.Types)-1)), args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var clips []clip
	seen := map[string]bool{}
	for rows.Next() {
		var copiedAt float64
		var value string
		if err := rows.Scan(&copiedAt, &value); err != nil {
			return nil, err
		}
		value = lineBreaks.Replace(strings.ToValidUTF8(value, "\uFFFD"))
		if p.TrimTrailingNewline {
			value = strings.TrimRight(value, "\n")
			if value == "" {
				continue
			}
		}
		if p.Dedupe {
			if seen[value] {
				continue
			}
			seen[value] = true
		}
		clips = append(clips, clip{value, int64(copiedAt) + coreDataEpoch})
	}
	return clips, rows.Err()
}

var lineBreaks = strings.NewReplacer("\r\n", "\n", "\r", "\n")

// dsn is the SQLite URI of path. mode=ro, not immutable=1, because Maccy's
// latest clips may be in the write-ahead log.
func dsn(path string) string {
	if path == "~" || strings.HasPrefix(path, "~/") {
		path = os.Getenv("HOME") + path[1:]
	}
	return (&url.URL{Scheme: "file", Path: path, RawQuery: "mode=ro"}).String()
}

// fold is the one-line form of a value, for the popup.
func fold(value string) string {
	return strings.ReplaceAll(strings.TrimSpace(value), "\n", "↵")
}

// relativeTime is the age of a clip in seconds, in its largest unit.
func relativeTime(age int64) string {
	if age < 1 {
		return "now"
	}
	for _, u := range []struct {
		below, per int64
		unit       string
	}{{60, 1, "s"}, {3600, 60, "m"}, {86400, 3600, "h"}, {604800, 86400, "d"}} {
		if age < u.below {
			return strconv.FormatInt(age/u.per, 10) + u.unit
		}
	}
	return strconv.FormatInt(age/604800, 10) + "w"
}
