package nvimlsp

import "strings"

// Position encodings of LSP. "utf-16" is the protocol's default.
const (
	encUTF8  = "utf-8"
	encUTF16 = "utf-16"
)

// byteOffset converts a character offset in the units of enc into a byte
// offset in line, clamped to the line.
func byteOffset(line string, char int, enc string) int {
	if char <= 0 {
		return 0
	}
	if enc == encUTF8 {
		return min(char, len(line))
	}
	n := 0
	for i, r := range line {
		if n >= char {
			return i
		}
		if enc == encUTF16 && r >= 0x10000 {
			n += 2
		} else {
			n++
		}
	}
	return len(line)
}

// selectText cuts an item's text to the word the popup inserts, as
// ddc-source-lsp's createSelectText: up to the first stop character after a
// letter or digit, outside of pairs.
func selectText(s string) string {
	alnumSeen := false
	var closers []byte
	for i := range len(s) {
		c := s[i]
		alnum := isAlnum(c)
		if !alnumSeen {
			if closer := pairCloser(c); closer != 0 {
				closers = append(closers, closer)
			}
		}
		if alnumSeen && !alnum && len(closers) == 0 {
			if strings.IndexByte("'\"=$()[]<>{} \t\n\r", c) >= 0 {
				return s[:i]
			}
		} else {
			alnumSeen = alnumSeen || alnum
		}
		if n := len(closers); n > 0 && c == closers[n-1] {
			closers = closers[:n-1]
		}
	}
	return s
}

func pairCloser(c byte) byte {
	switch c {
	case '(':
		return ')'
	case '[':
		return ']'
	case '{':
		return '}'
	case '<':
		return '>'
	case '"', '\'':
		return c
	}
	return 0
}

func isAlnum(c byte) bool {
	return c >= '0' && c <= '9' || c >= 'A' && c <= 'Z' || c >= 'a' && c <= 'z'
}

// stripSnippet turns snippet syntax into the plain text it inserts by
// default: tab stops vanish, placeholders keep their default, choices keep
// the first one.
func stripSnippet(s string) string {
	var b strings.Builder
	stripInto(&b, s, false)
	return b.String()
}

// stripInto writes the text of s and returns how many bytes it consumed.
// Inside a placeholder (nested) it stops at the closing brace.
func stripInto(b *strings.Builder, s string, nested bool) int {
	i := 0
	for i < len(s) {
		c := s[i]
		switch {
		case c == '\\' && i+1 < len(s):
			b.WriteByte(s[i+1])
			i += 2
		case c == '}' && nested:
			return i
		case c == '$' && i+1 < len(s) && isDigit(s[i+1]):
			i++
			for i < len(s) && isDigit(s[i]) {
				i++
			}
		case c == '$' && i+1 < len(s) && s[i+1] == '{':
			i += 2
			for i < len(s) && (isAlnum(s[i]) || s[i] == '_') {
				i++
			}
			if i < len(s) && s[i] == ':' {
				i++
				i += stripInto(b, s[i:], true)
			} else if i < len(s) && s[i] == '|' {
				i++
				end := strings.IndexAny(s[i:], ",|")
				if end < 0 {
					end = len(s) - i
				}
				b.WriteString(s[i : i+end])
				if closing := strings.Index(s[i:], "|}"); closing >= 0 {
					i += closing + 1
				} else {
					i = len(s)
				}
			}
			if i < len(s) && s[i] == '}' {
				i++
			}
		default:
			b.WriteByte(c)
			i++
		}
	}
	return i
}

func isDigit(c byte) bool { return c >= '0' && c <= '9' }
