package maccy

import (
	"context"
	"database/sql"
	"os"
	"path/filepath"
	"reflect"
	"sync"
	"testing"
	"time"

	"github.com/Shougo/goda-cmp.vim/cmp"
	"github.com/Shougo/goda-cmp.vim/cmp/cmptest"
)

const plainText = "public.utf8-plain-text"

var testNow = time.Unix(1_800_000_000, 0)

type fixture struct {
	t    *testing.T
	path string
	db   *sql.DB
}

func newFixture(t *testing.T) *fixture {
	t.Helper()
	path := filepath.Join(t.TempDir(), "Storage dir", "Storage.sqlite")
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		t.Fatal(err)
	}
	db, err := sql.Open("sqlite", path)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { db.Close() })
	for _, stmt := range []string{
		`PRAGMA journal_mode=WAL`,
		`CREATE TABLE ZHISTORYITEM (Z_PK INTEGER PRIMARY KEY, ZLASTCOPIEDAT TIMESTAMP)`,
		`CREATE TABLE ZHISTORYITEMCONTENT (Z_PK INTEGER PRIMARY KEY, ZITEM INTEGER, ZTYPE VARCHAR, ZVALUE BLOB)`,
	} {
		if _, err := db.Exec(stmt); err != nil {
			t.Fatal(err)
		}
	}
	return &fixture{t, path, db}
}

func (f *fixture) copied(age time.Duration, typ, value string) {
	f.t.Helper()
	at := float64(testNow.Add(-age).UnixMilli())/1000 - coreDataEpoch
	r, err := f.db.Exec(`INSERT INTO ZHISTORYITEM (ZLASTCOPIEDAT) VALUES (?)`, at)
	if err != nil {
		f.t.Fatal(err)
	}
	id, err := r.LastInsertId()
	if err != nil {
		f.t.Fatal(err)
	}
	if _, err := f.db.Exec(`INSERT INTO ZHISTORYITEMCONTENT (ZITEM, ZTYPE, ZVALUE) VALUES (?, ?, ?)`, id, typ, []byte(value)); err != nil {
		f.t.Fatal(err)
	}
}

func (f *fixture) source(p Params) *source {
	if p.DBPath == "" {
		p.DBPath = f.path
	}
	if p.Types == nil {
		p.Types = []string{plainText}
	}
	if p.MaxByteLength == 0 {
		p.MaxByteLength = 10000
	}
	if p.RecentMs == 0 {
		p.RecentMs = 30000
	}
	s := New(p).(*source)
	s.now = func() time.Time { return testNow }
	return s
}

func gather(t *testing.T, s *source) []cmp.Item {
	t.Helper()
	g, err := s.Gather(context.Background(), nil, &cmp.Context{Input: ""})
	if err != nil {
		t.Fatal(err)
	}
	return g.Items
}

func words(items []cmp.Item) []string {
	out := []string{}
	for _, it := range items {
		out = append(out, it.Word)
	}
	return out
}

func wantWords(t *testing.T, items []cmp.Item, want ...string) {
	t.Helper()
	if want == nil {
		want = []string{}
	}
	if got := words(items); !reflect.DeepEqual(got, want) {
		t.Errorf("words %q, want %q", got, want)
	}
}

func TestGatherOffersOnlyClipsWithinRecentMsNewestFirst(t *testing.T) {
	f := newFixture(t)
	f.copied(40*time.Second, plainText, "too old")
	f.copied(29*time.Second, plainText, "older")
	f.copied(time.Second, plainText, "newer")
	wantWords(t, gather(t, f.source(Params{RecentMs: 30000})), "newer", "older")
}

func TestGatherSkipsOtherTypesAndLongerValues(t *testing.T) {
	f := newFixture(t)
	f.copied(time.Second, "public.html", "html")
	f.copied(time.Second, plainText, "12345")
	f.copied(time.Second, plainText, "123456")
	wantWords(t, gather(t, f.source(Params{MaxByteLength: 5})), "12345")
}

func TestGatherWithSeveralTypesReadsEachOfThem(t *testing.T) {
	f := newFixture(t)
	f.copied(2*time.Second, "a", "first")
	f.copied(time.Second, "b'c", "second")
	f.copied(time.Second, "d", "third")
	wantWords(t, gather(t, f.source(Params{Types: []string{"a", "b'c"}})), "second", "first")
}

func TestGatherWithIncompleteParamsDoesNotOpenTheDatabase(t *testing.T) {
	for _, p := range []Params{
		{Types: []string{plainText}, MaxByteLength: 1},
		{DBPath: "/nonexistent", MaxByteLength: 1},
		{DBPath: "/nonexistent", Types: []string{plainText}},
	} {
		s := New(p).(*source)
		wantWords(t, gather(t, s))
	}
}

func TestGatherOfAMissingDatabaseFailsWithoutCreatingIt(t *testing.T) {
	path := filepath.Join(t.TempDir(), "Storage.sqlite")
	s := New(Params{DBPath: path, Types: []string{plainText}, MaxByteLength: 1, RecentMs: 1000}).(*source)
	if _, err := s.Gather(context.Background(), nil, &cmp.Context{}); err == nil {
		t.Error("no error")
	}
	if _, err := os.Stat(path); err == nil {
		t.Error("the read-only open created the database")
	}
}

func TestLoadCannotWriteTheDatabase(t *testing.T) {
	f := newFixture(t)
	db, err := sql.Open("sqlite", dsn(f.path))
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()
	if _, err := db.Exec(`DELETE FROM ZHISTORYITEM`); err == nil {
		t.Error("a write succeeded")
	}
}

func TestItemsKeepTheFirstLineAsWordAndTheWholeValueAsInfo(t *testing.T) {
	f := newFixture(t)
	f.copied(90*time.Second, plainText, "  a\r\nb\rc  ")
	got := gather(t, f.source(Params{RecentMs: 100000}))
	if len(got) != 1 {
		t.Fatalf("items %+v", got)
	}
	it := got[0]
	if it.Word != "  a" || it.Abbr != "1m  a↵b↵c" || it.Info != "  a\nb\nc  " {
		t.Errorf("item %+v", it)
	}
}

func TestGatherStartsAtTheKeyword(t *testing.T) {
	f := newFixture(t)
	g, err := f.source(Params{}).Gather(context.Background(), nil, &cmp.Context{Input: "x = fo"})
	if err != nil || g.Start != 4 {
		t.Errorf("start %d, err %v", g.Start, err)
	}
}

func TestDedupeKeepsTheNewestClipOfEachValue(t *testing.T) {
	f := newFixture(t)
	f.copied(3*time.Second, plainText, "foo")
	f.copied(2*time.Second, plainText, "bar")
	f.copied(time.Second, plainText, "foo")
	items := gather(t, f.source(Params{Dedupe: true}))
	wantWords(t, items, "foo", "bar")
	if items[0].Abbr != "1s  foo" {
		t.Errorf("abbr %q", items[0].Abbr)
	}
	wantWords(t, gather(t, f.source(Params{})), "foo", "bar", "foo")
}

func TestTrimTrailingNewlineCollapsesClipsBeforeDedupe(t *testing.T) {
	f := newFixture(t)
	f.copied(3*time.Second, plainText, "foo")
	f.copied(2*time.Second, plainText, "foo\n")
	f.copied(time.Second, plainText, "\r\n\r\n")
	items := gather(t, f.source(Params{Dedupe: true, TrimTrailingNewline: true}))
	wantWords(t, items, "foo")
	if items[0].Info != "foo" {
		t.Errorf("info %q", items[0].Info)
	}
}

func TestExcludeAfterUseHidesAClipUsedMaxUseCountTimes(t *testing.T) {
	f := newFixture(t)
	f.copied(time.Second, plainText, "foo")
	s := f.source(Params{ExcludeAfterUse: true, MaxUseCount: 2})
	for _, want := range [][]string{{"foo"}, {"foo"}, nil} {
		items := gather(t, s)
		wantWords(t, items, want...)
		if len(items) > 0 {
			if err := s.OnCompleteDone(context.Background(), nil, cmp.DoneArgs{Item: items[0]}); err != nil {
				t.Fatal(err)
			}
		}
	}
}

func TestMaxUseCountZeroHidesEveryClip(t *testing.T) {
	f := newFixture(t)
	f.copied(time.Second, plainText, "foo")
	wantWords(t, gather(t, f.source(Params{ExcludeAfterUse: true, MaxUseCount: 0})))
}

func TestCopyingAUsedClipAgainOffersIt(t *testing.T) {
	f := newFixture(t)
	f.copied(2*time.Second, plainText, "foo")
	s := f.source(Params{ExcludeAfterUse: true, MaxUseCount: 1, Dedupe: true})
	items := gather(t, s)
	if err := s.OnCompleteDone(context.Background(), nil, cmp.DoneArgs{Item: items[0]}); err != nil {
		t.Fatal(err)
	}
	wantWords(t, gather(t, s))
	f.copied(time.Second, plainText, "foo")
	wantWords(t, gather(t, s), "foo")
}

func TestUseIsForgottenOnceTheClipLeavesTheRecentWindow(t *testing.T) {
	uses := useCounts{counts: map[clip]int{}}
	cl := clip{"foo", 100}
	uses.record(cl)
	if got := uses.unused([]clip{cl}, 1); len(got) != 0 {
		t.Fatalf("offered %v", got)
	}
	uses.unused(nil, 1)
	if got := uses.unused([]clip{cl}, 1); len(got) != 1 {
		t.Errorf("offered %v", got)
	}
}

func TestUsesSurviveWithParams(t *testing.T) {
	f := newFixture(t)
	f.copied(time.Second, plainText, "foo")
	s := f.source(Params{ExcludeAfterUse: true, MaxUseCount: 1})
	items := gather(t, s)
	if err := s.OnCompleteDone(context.Background(), nil, cmp.DoneArgs{Item: items[0]}); err != nil {
		t.Fatal(err)
	}
	v, err := s.WithParams(cmp.Params{"recentMs": 20000})
	if err != nil {
		t.Fatal(err)
	}
	wantWords(t, gather(t, v.(*source)))
}

func TestCacheServesTheSameClipsUntilTheTtlEnds(t *testing.T) {
	f := newFixture(t)
	f.copied(2*time.Second, plainText, "old")
	s := f.source(Params{CacheTtlMs: 500})
	wantWords(t, gather(t, s), "old")

	f.copied(time.Second, plainText, "new")
	s.now = func() time.Time { return testNow.Add(499 * time.Millisecond) }
	wantWords(t, gather(t, s), "old")
	s.now = func() time.Time { return testNow.Add(500 * time.Millisecond) }
	wantWords(t, gather(t, s), "new", "old")
}

func TestCacheTtlZeroReadsTheDatabaseEveryTime(t *testing.T) {
	f := newFixture(t)
	s := f.source(Params{})
	wantWords(t, gather(t, s))
	f.copied(time.Second, plainText, "new")
	wantWords(t, gather(t, s), "new")
}

func TestConcurrentGathersShareOneQuery(t *testing.T) {
	var cache clipCache
	var calls int
	var wg sync.WaitGroup
	for range 8 {
		wg.Go(func() {
			_, _ = cache.get(testNow, time.Second, func() ([]clip, error) {
				calls++
				return []clip{}, nil
			})
		})
	}
	wg.Wait()
	if calls != 1 {
		t.Errorf("%d queries", calls)
	}
}

func TestAFailedQueryIsNotCached(t *testing.T) {
	f := newFixture(t)
	f.copied(time.Second, plainText, "foo")
	s := f.source(Params{CacheTtlMs: 1000})
	ctx, cancel := context.WithCancel(context.Background())
	cancel()
	if _, err := s.Gather(ctx, nil, &cmp.Context{}); err == nil {
		t.Fatal("no error")
	}
	wantWords(t, gather(t, s), "foo")
}

func TestOnCompleteDoneInsertsTheLinesAfterTheFirst(t *testing.T) {
	var set, cursor []any
	h := &cmptest.Host{Funcs: map[string]func(...any) (any, error){
		"nvim_win_get_cursor": func(...any) (any, error) { return []any{int64(3), int64(7)}, nil },
		"nvim_buf_set_text":   func(a ...any) (any, error) { set = a; return nil, nil },
		"nvim_win_set_cursor": func(a ...any) (any, error) { cursor = a; return nil, nil },
	}}
	s := New(Params{}).(*source)
	it := cmp.Item{UserData: clip{value: "a\nb\n日本語"}}
	if err := s.OnCompleteDone(context.Background(), h, cmp.DoneArgs{Item: it}); err != nil {
		t.Fatal(err)
	}
	if want := []any{0, 2, 7, 2, 7, []string{"", "b", "日本語"}}; !reflect.DeepEqual(set, want) {
		t.Errorf("set %v", set)
	}
	if want := []any{0, []int{5, 9}}; !reflect.DeepEqual(cursor, want) {
		t.Errorf("cursor %v", cursor)
	}
}

func TestOnCompleteDoneOfASingleLineTouchesNothing(t *testing.T) {
	h := &cmptest.Host{}
	s := New(Params{}).(*source)
	it := cmp.Item{UserData: clip{value: "a"}}
	if err := s.OnCompleteDone(context.Background(), h, cmp.DoneArgs{Item: it}); err != nil {
		t.Fatal(err)
	}
	if len(h.Calls()) != 0 {
		t.Errorf("calls %+v", h.Calls())
	}
}

func TestRelativeTimeUsesTheLargestUnit(t *testing.T) {
	for age, want := range map[int64]string{
		-5: "now", 0: "now", 1: "1s", 59: "59s", 60: "1m", 3599: "59m", 3600: "1h",
		86399: "23h", 86400: "1d", 604799: "6d", 604800: "1w", 3 * 604800: "3w",
	} {
		if got := relativeTime(age); got != want {
			t.Errorf("relativeTime(%d) = %q, want %q", age, got, want)
		}
	}
}

func TestDsnExpandsTheHomeDirectoryAndEscapesThePath(t *testing.T) {
	t.Setenv("HOME", "/home/test")
	for path, want := range map[string]string{
		"~/a b/c?d.sqlite": "file:///home/test/a%20b/c%3Fd.sqlite?mode=ro",
		"/abs/~/x":         "file:///abs/~/x?mode=ro",
	} {
		if got := dsn(path); got != want {
			t.Errorf("dsn(%q) = %q, want %q", path, got, want)
		}
	}
}
