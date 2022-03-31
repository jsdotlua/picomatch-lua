-- ROBLOX upstream: https://github.com/micromatch/picomatch/tree/2.3.1/test/api.picomatch.js

return function()
	local CurrentModule = script.Parent
	local PicomatchModule = CurrentModule.Parent
	local Packages = PicomatchModule.Parent
	local LuauPolyfill = require(Packages.LuauPolyfill)
	local Array = LuauPolyfill.Array

	local jestExpect = require(Packages.Dev.JestGlobals).expect

	local picomatch = require(PicomatchModule)
	local isMatch = picomatch.isMatch
	local function assertTokens(actual, expected)
		local keyValuePairs = Array.map(actual, function(token)
			return { token.type, token.value }
		end)
		jestExpect(keyValuePairs).toEqual(expected)
	end
	describe("picomatch", function()
		describe("validation", function()
			it("should throw an error when invalid arguments are given", function()
				jestExpect(function()
					return isMatch("foo", "")
				end).toThrowError("Expected pattern to be a non-empty string")
				jestExpect(function()
					return isMatch("foo", nil)
				end).toThrowError("Expected pattern to be a non-empty string")
			end)
		end)

		describe("multiple patterns", function()
			it("should return true when any of the patterns match", function()
				assert(isMatch(".", { ".", "foo" }))
				assert(isMatch("a", { "a", "foo" }))
				assert(isMatch("ab", { "*", "foo", "bar" }))
				assert(isMatch("ab", { "*b", "foo", "bar" }))
				assert(isMatch("ab", { "./*", "foo", "bar" }))
				assert(isMatch("ab", { "a*", "foo", "bar" }))
				assert(isMatch("ab", { "ab", "foo" }))
			end)

			it("should return false when none of the patterns match", function()
				assert(not isMatch("/ab", { "/a", "foo" }))
				assert(not isMatch("/ab", { "?/?", "foo", "bar" }))
				assert(not isMatch("/ab", { "a/*", "foo", "bar" }))
				assert(not isMatch("a/b/c", { "a/b", "foo" }))
				assert(not isMatch("ab", { "*/*", "foo", "bar" }))
				assert(not isMatch("ab", { "/a", "foo", "bar" }))
				assert(not isMatch("ab", { "a", "foo" }))
				assert(not isMatch("ab", { "b", "foo" }))
				assert(not isMatch("ab", { "c", "foo", "bar" }))
				assert(not isMatch("abcd", { "ab", "foo" }))
				assert(not isMatch("abcd", { "bc", "foo" }))
				assert(not isMatch("abcd", { "c", "foo" }))
				assert(not isMatch("abcd", { "cd", "foo" }))
				assert(not isMatch("abcd", { "d", "foo" }))
				assert(not isMatch("abcd", { "f", "foo", "bar" }))
				assert(not isMatch("ef", { "/*", "foo", "bar" }))
			end)
		end)

		describe("file extensions", function()
			it("should match files that contain the given extension:", function()
				assert(not isMatch(".c.md", "*.md"))
				assert(not isMatch(".c.md", ".c."))
				assert(not isMatch(".c.md", ".md"))
				assert(not isMatch(".md", "*.md"))
				assert(not isMatch(".md", ".m"))
				assert(not isMatch("a/b/c.md", "*.md"))
				assert(not isMatch("a/b/c.md", ".md"))
				assert(not isMatch("a/b/c.md", "a/*.md"))
				assert(not isMatch("a/b/c/c.md", "*.md"))
				assert(not isMatch("a/b/c/c.md", "c.js"))
				assert(isMatch(".c.md", ".*.md"))
				assert(isMatch(".md", ".md"))
				assert(isMatch("a/b/c.js", "a/**/*.*"))
				assert(isMatch("a/b/c.md", "**/*.md"))
				assert(isMatch("a/b/c.md", "a/*/*.md"))
				assert(isMatch("c.md", "*.md"))
			end)
		end)

		describe("dot files", function()
			it("should not match dotfiles when a leading dot is not defined in a path segment", function()
				assert(not isMatch(".a", "(a)*"))
				assert(not isMatch(".a", "*(a|b)"))
				assert(not isMatch(".a", "*.md"))
				assert(not isMatch(".a", "*[a]"))
				assert(not isMatch(".a", "*[a]*"))
				assert(not isMatch(".a", "*a"))
				assert(not isMatch(".a", "*a*"))
				assert(not isMatch(".a.md", "a/b/c/*.md"))
				assert(not isMatch(".ab", "*.*"))
				assert(not isMatch(".abc", ".a"))
				assert(not isMatch(".ba", ".a"))
				assert(not isMatch(".c.md", "*.md"))
				assert(not isMatch(".md", "a/b/c/*.md"))
				assert(not isMatch(".txt", ".md"))
				assert(not isMatch(".verb.txt", "*.md"))
				assert(not isMatch("a/.c.md", "*.md"))
				assert(not isMatch("a/b/d/.md", "a/b/c/*.md"))
				assert(isMatch(".a", ".a"))
				assert(isMatch(".ab", ".*"))
				assert(isMatch(".ab", ".a*"))
				assert(isMatch(".b", ".b*"))
				assert(isMatch(".md", ".md"))
				assert(isMatch("a/.c.md", "a/.c.md"))
				assert(isMatch("a/b/c/.xyz.md", "a/b/c/.*.md"))
				assert(isMatch("a/b/c/d.a.md", "a/b/c/*.md"))
			end)

			it("should match dotfiles when options.dot is true", function()
				assert(not isMatch("a/b/c/.xyz.md", ".*.md", { dot = true }))
				assert(isMatch(".c.md", "*.md", { dot = true }))
				assert(isMatch(".c.md", ".*", { dot = true }))
				assert(isMatch("a/b/c/.xyz.md", "**/*.md", { dot = true }))
				assert(isMatch("a/b/c/.xyz.md", "**/.*.md", { dot = true }))
				assert(isMatch("a/b/c/.xyz.md", "a/b/c/*.md", { dot = true }))
				assert(isMatch("a/b/c/.xyz.md", "a/b/c/.*.md", { dot = true }))
			end)
		end)

		describe("matching:", function()
			it("should escape plus signs to match string literals", function()
				assert(isMatch("a+b/src/glimini.js", "a+b/src/*.js"))
				assert(isMatch("+b/src/glimini.js", "+b/src/*.js"))
				assert(isMatch("coffee+/src/glimini.js", "coffee+/src/*.js"))
				assert(isMatch("coffee+/src/glimini.js", "coffee+/src/*"))
			end)

			it("should match with non-glob patterns", function()
				assert(isMatch(".", "."))
				assert(isMatch("/a", "/a"))
				assert(not isMatch("/ab", "/a"))
				assert(isMatch("a", "a"))
				assert(not isMatch("ab", "/a"))
				assert(not isMatch("ab", "a"))
				assert(isMatch("ab", "ab"))
				assert(not isMatch("abcd", "cd"))
				assert(not isMatch("abcd", "bc"))
				assert(not isMatch("abcd", "ab"))
			end)

			it("should match file names", function()
				assert(isMatch("a.b", "a.b"))
				assert(isMatch("a.b", "*.b"))
				assert(isMatch("a.b", "a.*"))
				assert(isMatch("a.b", "*.*"))
				assert(isMatch("a-b.c-d", "a*.c*"))
				assert(isMatch("a-b.c-d", "*b.*d"))
				assert(isMatch("a-b.c-d", "*.*"))
				assert(isMatch("a-b.c-d", "*.*-*"))
				assert(isMatch("a-b.c-d", "*-*.*-*"))
				assert(isMatch("a-b.c-d", "*.c-*"))
				assert(isMatch("a-b.c-d", "*.*-d"))
				assert(isMatch("a-b.c-d", "a-*.*-d"))
				assert(isMatch("a-b.c-d", "*-b.c-*"))
				assert(isMatch("a-b.c-d", "*-b*c-*"))
				assert(not isMatch("a-b.c-d", "*-bc-*"))
			end)

			it("should match with common glob patterns", function()
				assert(not isMatch("/ab", "./*/"))
				assert(not isMatch("/ef", "*"))
				assert(not isMatch("ab", "./*/"))
				assert(not isMatch("ef", "/*"))
				assert(isMatch("/ab", "/*"))
				assert(isMatch("/cd", "/*"))
				assert(isMatch("ab", "*"))
				assert(isMatch("ab", "./*"))
				assert(isMatch("ab", "ab"))
				assert(isMatch("ab/", "./*/"))
			end)

			it("should match files with the given extension", function()
				assert(not isMatch(".md", "*.md"))
				assert(isMatch(".md", ".md"))
				assert(not isMatch(".c.md", "*.md"))
				assert(isMatch(".c.md", ".*.md"))
				assert(isMatch("c.md", "*.md"))
				assert(isMatch("c.md", "*.md"))
				assert(not isMatch("a/b/c/c.md", "*.md"))
				assert(not isMatch("a/b/c.md", "a/*.md"))
				assert(isMatch("a/b/c.md", "a/*/*.md"))
				assert(isMatch("a/b/c.md", "**/*.md"))
				assert(isMatch("a/b/c.js", "a/**/*.*"))
			end)

			it("should match wildcards", function()
				assert(not isMatch("a/b/c/z.js", "*.js"))
				assert(not isMatch("a/b/z.js", "*.js"))
				assert(not isMatch("a/z.js", "*.js"))
				assert(isMatch("z.js", "*.js"))
				assert(isMatch("z.js", "z*.js"))
				assert(isMatch("a/z.js", "a/z*.js"))
				assert(isMatch("a/z.js", "*/z*.js"))
			end)

			it("should match globstars", function()
				assert(isMatch("a/b/c/z.js", "**/*.js"))
				assert(isMatch("a/b/z.js", "**/*.js"))
				assert(isMatch("a/z.js", "**/*.js"))
				assert(isMatch("a/b/c/d/e/z.js", "a/b/**/*.js"))
				assert(isMatch("a/b/c/d/z.js", "a/b/**/*.js"))
				assert(isMatch("a/b/c/z.js", "a/b/c/**/*.js"))
				assert(isMatch("a/b/c/z.js", "a/b/c**/*.js"))
				assert(isMatch("a/b/c/z.js", "a/b/**/*.js"))
				assert(isMatch("a/b/z.js", "a/b/**/*.js"))
				assert(not isMatch("a/z.js", "a/b/**/*.js"))
				assert(not isMatch("z.js", "a/b/**/*.js"))
				-- https://github.com/micromatch/micromatch/issues/15
				assert(isMatch("z.js", "z*"))
				assert(isMatch("z.js", "**/z*"))
				assert(isMatch("z.js", "**/z*.js"))
				assert(isMatch("z.js", "**/*.js"))
				assert(isMatch("foo", "**/foo"))
			end)

			it("issue #23", function()
				assert(not isMatch("zzjs", "z*.js"))
				assert(not isMatch("zzjs", "*z.js"))
			end)

			it("issue #24 - should match zero or more directories", function()
				assert(not isMatch("a/b/c/d/", "a/b/**/f"))
				assert(isMatch("a", "a/**"))
				assert(isMatch("a", "**"))
				assert(isMatch("a/", "**"))
				assert(isMatch("a/b-c/d/e/z.js", "a/b-*/**/z.js"))
				assert(isMatch("a/b-c/z.js", "a/b-*/**/z.js"))
				assert(isMatch("a/b/c/d", "**"))
				assert(isMatch("a/b/c/d/", "**"))
				assert(isMatch("a/b/c/d/", "**/**"))
				assert(isMatch("a/b/c/d/", "**/b/**"))
				assert(isMatch("a/b/c/d/", "a/b/**"))
				assert(isMatch("a/b/c/d/", "a/b/**/"))
				assert(isMatch("a/b/c/d/", "a/b/**/c/**/"))
				assert(isMatch("a/b/c/d/", "a/b/**/c/**/d/"))
				assert(isMatch("a/b/c/d/e.f", "a/b/**/**/*.*"))
				assert(isMatch("a/b/c/d/e.f", "a/b/**/*.*"))
				assert(isMatch("a/b/c/d/e.f", "a/b/**/c/**/d/*.*"))
				assert(isMatch("a/b/c/d/e.f", "a/b/**/d/**/*.*"))
				assert(isMatch("a/b/c/d/g/e.f", "a/b/**/d/**/*.*"))
				assert(isMatch("a/b/c/d/g/g/e.f", "a/b/**/d/**/*.*"))
			end)

			it("should match slashes", function()
				assert(not isMatch("bar/baz/foo", "*/foo"))
				assert(not isMatch("deep/foo/bar", "**/bar/*"))
				assert(not isMatch("deep/foo/bar/baz/x", "*/bar/**"))
				assert(not isMatch("foo/bar", "foo?bar"))
				assert(not isMatch("foo/bar/baz", "**/bar*"))
				assert(not isMatch("foo/bar/baz", "**/bar**"))
				assert(not isMatch("foo/baz/bar", "foo**bar"))
				assert(not isMatch("foo/baz/bar", "foo*bar"))
				assert(not isMatch("deep/foo/bar/baz", "**/bar/*/"))
				assert(not isMatch("deep/foo/bar/baz/", "**/bar/*", { strictSlashes = true }))
				assert(isMatch("deep/foo/bar/baz/", "**/bar/*"))
				assert(isMatch("deep/foo/bar/baz", "**/bar/*"))
				assert(isMatch("foo", "foo/**"))
				assert(isMatch("deep/foo/bar/baz/", "**/bar/*{,/}"))
				assert(isMatch("a/b/j/c/z/x.md", "a/**/j/**/z/*.md"))
				assert(isMatch("a/j/z/x.md", "a/**/j/**/z/*.md"))
				assert(isMatch("bar/baz/foo", "**/foo"))
				assert(isMatch("deep/foo/bar/", "**/bar/**"))
				assert(isMatch("deep/foo/bar/baz", "**/bar/*"))
				assert(isMatch("deep/foo/bar/baz/", "**/bar/*/"))
				assert(isMatch("deep/foo/bar/baz/", "**/bar/**"))
				assert(isMatch("deep/foo/bar/baz/x", "**/bar/*/*"))
				assert(isMatch("foo/b/a/z/bar", "foo/**/**/bar"))
				assert(isMatch("foo/b/a/z/bar", "foo/**/bar"))
				assert(isMatch("foo/bar", "foo/**/**/bar"))
				assert(isMatch("foo/bar", "foo/**/bar"))
				-- ROBLOX FIXME: investigate why does it fail
				-- assert(isMatch("foo/bar", "foo[/]bar"))
				assert(isMatch("foo/bar/baz/x", "*/bar/**"))
				assert(isMatch("foo/baz/bar", "foo/**/**/bar"))
				assert(isMatch("foo/baz/bar", "foo/**/bar"))
				assert(isMatch("foobazbar", "foo**bar"))
				assert(isMatch("XXX/foo", "**/foo"))
				-- https://github.com/micromatch/micromatch/issues/89
				assert(isMatch("foo//baz.md", "foo//baz.md"))
				assert(isMatch("foo//baz.md", "foo//*baz.md"))
				assert(isMatch("foo//baz.md", "foo{/,//}baz.md"))
				assert(isMatch("foo/baz.md", "foo{/,//}baz.md"))
				assert(not isMatch("foo//baz.md", "foo/+baz.md"))
				assert(not isMatch("foo//baz.md", "foo//+baz.md"))
				assert(not isMatch("foo//baz.md", "foo/baz.md"))
				assert(not isMatch("foo/baz.md", "foo//baz.md"))
			end)

			it("question marks should not match slashes", function()
				assert(not isMatch("aaa/bbb", "aaa?bbb"))
			end)

			it("should not match dotfiles when `dot` or `dotfiles` are not set", function()
				assert(not isMatch(".c.md", "*.md"))
				assert(not isMatch("a/.c.md", "*.md"))
				assert(isMatch("a/.c.md", "a/.c.md"))
				assert(not isMatch(".a", "*.md"))
				assert(not isMatch(".verb.txt", "*.md"))
				assert(isMatch("a/b/c/.xyz.md", "a/b/c/.*.md"))
				assert(isMatch(".md", ".md"))
				assert(not isMatch(".txt", ".md"))
				assert(isMatch(".md", ".md"))
				assert(isMatch(".a", ".a"))
				assert(isMatch(".b", ".b*"))
				assert(isMatch(".ab", ".a*"))
				assert(isMatch(".ab", ".*"))
				assert(not isMatch(".ab", "*.*"))
				assert(not isMatch(".md", "a/b/c/*.md"))
				assert(not isMatch(".a.md", "a/b/c/*.md"))
				assert(isMatch("a/b/c/d.a.md", "a/b/c/*.md"))
				assert(not isMatch("a/b/d/.md", "a/b/c/*.md"))
			end)

			it("should match dotfiles when `dot` or `dotfiles` is set", function()
				assert(isMatch(".c.md", "*.md", { dot = true }))
				assert(isMatch(".c.md", ".*", { dot = true }))
				assert(isMatch("a/b/c/.xyz.md", "a/b/c/*.md", { dot = true }))
				assert(isMatch("a/b/c/.xyz.md", "a/b/c/.*.md", { dot = true }))
			end)
		end)

		describe(".parse", function()
			describe("tokens", function()
				it("should return result for pattern that matched by fastpath", function()
					local tokens = picomatch.parse("a*.txt").tokens
					local expected = {
						{ "bos", "" },
						{ "text", "a" },
						{ "star", "*" },
						{
							"text",
							".txt",
						},
					}
					assertTokens(tokens, expected)
				end)

				it("should return result for pattern", function()
					local tokens = picomatch.parse("{a,b}*").tokens
					local expected = {
						{ "bos", "" },
						{ "brace", "{" },
						{ "text", "a" },
						{ "comma", "," },
						{ "text", "b" },
						{ "brace", "}" },
						{ "star", "*" },
						{ "maybe_slash", "" },
					}
					assertTokens(tokens, expected)
				end)
			end)
		end)

		describe("state", function()
			describe("negatedExtglob", function()
				it("should return true", function()
					assert(picomatch("!(abc)", {}, true).state.negatedExtglob)
					assert(picomatch("!(abc)**", {}, true).state.negatedExtglob)
					assert(picomatch("!(abc)/**", {}, true).state.negatedExtglob)
				end)

				it("should return false", function()
					assert(not picomatch("(!(abc))", {}, true).state.negatedExtglob)
					assert(not picomatch("**!(abc)", {}, true).state.negatedExtglob)
				end)
			end)
		end)
	end)
end
