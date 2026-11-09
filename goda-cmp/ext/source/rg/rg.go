// Package rg is a source that offers the words starting with the typed text
// in the files under the current directory, found with ripgrep. It is a port
// of ddc-source-rg (https://github.com/Shougo/ddc-source-rg).
package rg

import (
	"bytes"
	"context"
	"errors"
	"fmt"
	"os/exec"
	"regexp"
	"slices"
	"strings"

	"github.com/Shougo/goda-cmp.vim/cmp"
	"github.com/Shougo/goda.vim/sdk"
)

// Params are the parameters of the source.
type Params struct {
	// Cmd is the ripgrep executable (default "rg").
	Cmd string `json:"cmd"`
	// Args come before the pattern and the directory. They must make the
	// output one match per line (default: see New).
	Args []string `json:"args"`
}

type source struct{ p Params }

// New returns the source, named "rg". Args defaults to --no-filename
// --no-heading --no-line-number --color never --only-matching --word-regexp
// --ignore-case.
func New(p Params) cmp.Source {
	if p.Cmd == "" {
		p.Cmd = "rg"
	}
	if p.Args == nil {
		p.Args = []string{
			"--no-filename",
			"--no-heading",
			"--no-line-number",
			"--color", "never",
			"--only-matching",
			"--word-regexp",
			"--ignore-case",
		}
	}
	return source{p}
}

func (source) Name() string { return "rg" }

// WithParams sets the parameters from Vim script (sourceParams).
func (s source) WithParams(p cmp.Params) (any, error) {
	np, err := cmp.PatchParams(s.p, p)
	if err != nil {
		return nil, err
	}
	return New(np), nil
}

func (s source) Gather(ctx context.Context, h sdk.Host, c *cmp.Context) (cmp.Gathered, error) {
	start := c.KeywordStart()
	v, err := h.Call(ctx, "getcwd")
	if err != nil {
		return cmp.Gathered{}, err
	}
	cwd, _ := v.(string)

	pattern := regexp.QuoteMeta(c.Input[start:]) + "[a-zA-Z0-9_-]+"
	cmd := exec.CommandContext(ctx, s.p.Cmd, append(slices.Clone(s.p.Args), pattern, cwd)...)
	var stdout, stderr bytes.Buffer
	cmd.Stdout, cmd.Stderr = &stdout, &stderr
	if err := cmd.Run(); err != nil {
		var exit *exec.ExitError
		switch {
		case ctx.Err() != nil:
			return cmp.Gathered{}, ctx.Err()
		case errors.As(err, &exit) && exit.ExitCode() == 1: // ripgrep found nothing
			return cmp.Gathered{Start: start}, nil
		}
		return cmp.Gathered{}, fmt.Errorf("%s: %w: %s", s.p.Cmd, err, strings.TrimSpace(stderr.String()))
	}
	return cmp.Gathered{Start: start, Items: items(stdout.String())}, nil
}

func items(output string) []cmp.Item {
	var out []cmp.Item
	seen := map[string]bool{}
	for line := range strings.Lines(output) {
		word := strings.TrimRight(line, "\r\n")
		if word != "" && !seen[word] {
			seen[word] = true
			out = append(out, cmp.Item{Word: word})
		}
	}
	return out
}
