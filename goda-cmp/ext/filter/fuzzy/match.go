package fuzzy

import (
	"math"
	"slices"
	"strings"
	"unicode/utf16"
)

const threshold = 100

type utf16Units = []uint16

func appendUnits(dst utf16Units, s string) utf16Units {
	for _, r := range s {
		dst = utf16.AppendRune(dst, r)
	}
	return dst
}

func normalize(s string, ignoreCase bool) string {
	if ignoreCase {
		return strings.ToLower(s)
	}
	return s
}

func ctest(pattern, source utf16Units) bool {
	p := 0
	for _, u := range source {
		if p == len(pattern) {
			break
		}
		if pattern[p] == u {
			p++
		}
	}
	return p == len(pattern)
}

func isLower(u uint16) bool { return 'a' <= u && u <= 'z' }
func isUpper(u uint16) bool { return 'A' <= u && u <= 'Z' }

func wtest(pattern, source utf16Units) bool {
	p := 0
	continued := true
	for s, u := range source {
		if p == len(pattern) {
			break
		}
		begins := continued
		if s > 0 {
			prev := source[s-1]
			begins = begins || !(isLower(prev) || isUpper(prev)) || (isLower(prev) && isUpper(u))
		}
		continued = begins && pattern[p] == u
		if continued {
			p++
		}
	}
	return p == len(pattern)
}

type scorer struct {
	paths, next []int32
	order       []int32
}

func (c *scorer) score(pattern, source utf16Units) float64 {
	if len(pattern) == 0 || slices.ContainsFunc(pattern, func(u uint16) bool { return utf16.IsSurrogate(rune(u)) }) {
		return math.Inf(-1)
	}
	c.paths = c.paths[:0]
	for i, u := range source {
		if u == pattern[0] {
			c.paths = append(c.paths, int32(i))
		}
	}
	c.trim(1)
	for width := 1; width < len(pattern) && len(c.paths) > 0; width++ {
		c.next = c.next[:0]
		for o := 0; o < len(c.paths); o += width {
			path := c.paths[o : o+width]
			for j := int(path[width-1]) + 1; j < len(source); j++ {
				if source[j] == pattern[width] {
					c.next = append(append(c.next, path...), int32(j))
				}
			}
		}
		c.paths, c.next = c.next, c.paths
		c.trim(width + 1)
	}
	best := math.Inf(-1)
	for o := 0; o < len(c.paths); o += len(pattern) {
		best = max(best, scorePath(len(source), c.paths[o:o+len(pattern)]))
	}
	return best
}

func (c *scorer) trim(width int) {
	if len(c.paths)/width <= threshold {
		return
	}
	c.order = c.order[:0]
	for o := 0; o < len(c.paths); o += width {
		c.order = append(c.order, int32(o))
	}
	slices.SortFunc(c.order, func(a, b int32) int {
		for i := width - 1; i >= 0; i-- {
			if d := c.paths[int(a)+i] - c.paths[int(b)+i]; d != 0 {
				return int(d)
			}
		}
		return 0
	})
	c.next = c.next[:0]
	for _, o := range c.order[:threshold] {
		c.next = append(c.next, c.paths[o:int(o)+width]...)
	}
	c.paths, c.next = c.next, c.paths
}

func scorePath(sourceLen int, pos []int32) float64 {
	length := 1
	if len(pos) > 1 {
		length = int(pos[len(pos)-1]-pos[0]) + 1
	}
	groups := 1
	for i := 1; i < len(pos); i++ {
		if pos[i-1]+1 != pos[i] {
			groups++
		}
	}
	score := 1 / float64(groups)
	score += 1 / float64(pos[0]+1) / 10
	score += 1 / float64(length) / 100
	score += 1 / float64(sourceLen) / 1000
	return score
}
