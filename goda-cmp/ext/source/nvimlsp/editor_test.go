package nvimlsp

import (
	"context"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"github.com/Shougo/goda-cmp.vim/cmp"
	"github.com/Shougo/goda-cmp.vim/cmp/cmptest"
)

func TestMain(m *testing.M) {
	if os.Getenv("NVIMLSP_PLUGIN") != "" {
		b := cmp.New()
		b.AddUI(cmptest.NewUI("test"))
		b.AddSource(New(Params{EnableResolveItem: true, EnableAdditionalTextEdit: true}))
		b.PatchGlobal(cmp.Config{
			UI:      "test",
			Sources: []string{"nvimlsp"},
			SourceOptions: map[string]cmp.SourceOption{
				"nvimlsp": {Mark: "[LSP]"},
			},
		})
		b.Main()
		return
	}
	os.Exit(m.Run())
}

func nvim(t *testing.T, script string, env ...string) {
	t.Helper()
	bin, err := exec.LookPath("nvim")
	if err != nil {
		t.Skip("nvim is not installed")
	}
	ctx, cancel := context.WithTimeout(context.Background(), time.Minute)
	defer cancel()
	cmd := exec.CommandContext(ctx, bin, "-l", script)
	cmd.Env = append(os.Environ(), env...)
	if out, err := cmd.CombinedOutput(); err != nil {
		t.Fatalf("%s: %v\n%s", script, err, out)
	}
}

func moduleDir(t *testing.T, module string) string {
	t.Helper()
	out, err := exec.Command("go", "list", "-m", "-f", "{{.Dir}}", module).Output()
	if err != nil {
		t.Fatalf("go list %s: %v", module, err)
	}
	return strings.TrimSpace(string(out))
}

func TestLuaSideWithFakeClients(t *testing.T) {
	nvim(t, filepath.Join("testdata", "goda_cmp_lsp_test.lua"))
}

func TestCompletionRoundTripThroughNeovim(t *testing.T) {
	self, err := os.Executable()
	if err != nil {
		t.Fatal(err)
	}
	nvim(t, filepath.Join("testdata", "round_trip.lua"),
		"NVIMLSP_PLUGIN=1",
		"NVIMLSP_BIN="+self,
		"GODA_RTP="+moduleDir(t, "github.com/Shougo/goda.vim"),
		"GODA_CMP_RTP="+moduleDir(t, "github.com/Shougo/goda-cmp.vim"),
	)
}
