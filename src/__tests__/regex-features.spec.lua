-- ROBLOX upstream: https://github.com/micromatch/picomatch/tree/2.3.1/test/regex-features.js

return function()
	local LuauPolyfill = require("@pkg/@jsdotlua/luau-polyfill")
	local Boolean = LuauPolyfill.Boolean
	-- ROBLOX deviation: not supported in Lua
	-- local version = process.version

	local utils = require("../utils")
	local isMatch = require("../init").isMatch
	describe("regex features", function()
		describe("word boundaries", function()
			itFIXME("should support word boundaries", function()
				assert(isMatch("a", "a\\b"))
			end)

			itFIXME("should support word boundaries in parens", function()
				assert(isMatch("a", "(a\\b)"))
			end)
		end)

		describe("regex lookarounds", function()
			it("should support regex lookbehinds", function()
				if Boolean.toJSBoolean(utils.supportsLookbehinds()) then
					assert(isMatch("foo/cbaz", "foo/*(?<!d)baz"))
					assert(not Boolean.toJSBoolean(isMatch("foo/cbaz", "foo/*(?<!c)baz")))
					assert(not Boolean.toJSBoolean(isMatch("foo/cbaz", "foo/*(?<=d)baz")))
					assert(isMatch("foo/cbaz", "foo/*(?<=c)baz"))
				end
			end)
			-- ROBLOX deviation START: not supported in Lua
			itSKIP("should throw an error when regex lookbehinds are used on an unsupported node version", function()
				-- Reflect:defineProperty(process, "version", { value = "v6.0.0" })
				-- assert:throws(
				-- 	function()
				-- 		return isMatch("foo/cbaz", "foo/*(?<!c)baz")
				-- 	end,
				-- 	error("not implemented") --[[ ROBLOX TODO: Unhandled node for type: RegExpLiteral ]] --[[ /Node\.js v10 or higher/ ]]
				-- )
				-- Reflect:defineProperty(process, "version", { value = version })
			end)
			-- ROBLOX deviation END
		end)

		describe("regex back-references", function()
			it("should support regex backreferences", function()
				assert(not Boolean.toJSBoolean(isMatch("1/2", "(*)/\\1")))
				assert(isMatch("1/1", "(*)/\\1"))
				assert(isMatch("1/1/1/1", "(*)/\\1/\\1/\\1"))
				assert(not Boolean.toJSBoolean(isMatch("1/11/111/1111", "(*)/\\1/\\1/\\1")))
				assert(isMatch("1/11/111/1111", "(*)/(\\1)+/(\\1)+/(\\1)+"))
				assert(not Boolean.toJSBoolean(isMatch("1/2/1/1", "(*)/\\1/\\1/\\1")))
				assert(not Boolean.toJSBoolean(isMatch("1/1/2/1", "(*)/\\1/\\1/\\1")))
				assert(not Boolean.toJSBoolean(isMatch("1/1/1/2", "(*)/\\1/\\1/\\1")))
				assert(isMatch("1/1/1/1", "(*)/\\1/(*)/\\2"))
				assert(not Boolean.toJSBoolean(isMatch("1/1/2/1", "(*)/\\1/(*)/\\2")))
				assert(not Boolean.toJSBoolean(isMatch("1/1/2/1", "(*)/\\1/(*)/\\2")))
				assert(isMatch("1/1/2/2", "(*)/\\1/(*)/\\2"))
			end)
		end)

		describe("regex character classes", function()
			it("should not match with character classes when disabled", function()
				assert(not Boolean.toJSBoolean(isMatch("a/a", "a/[a-z]", { nobracket = true })))
				assert(not Boolean.toJSBoolean(isMatch("a/b", "a/[a-z]", { nobracket = true })))
				assert(not Boolean.toJSBoolean(isMatch("a/c", "a/[a-z]", { nobracket = true })))
			end)

			itFIXME("should match with character classes by default", function()
				assert(isMatch("a/a", "a/[a-z]"))
				assert(isMatch("a/b", "a/[a-z]"))
				assert(isMatch("a/c", "a/[a-z]"))
				assert(not Boolean.toJSBoolean(isMatch("foo/bar", "**/[jkl]*")))
				assert(isMatch("foo/jar", "**/[jkl]*"))
				assert(isMatch("foo/bar", "**/[^jkl]*"))
				assert(not Boolean.toJSBoolean(isMatch("foo/jar", "**/[^jkl]*")))
				assert(isMatch("foo/bar", "**/[abc]*"))
				assert(not Boolean.toJSBoolean(isMatch("foo/jar", "**/[abc]*")))
				assert(not Boolean.toJSBoolean(isMatch("foo/bar", "**/[^abc]*")))
				assert(isMatch("foo/jar", "**/[^abc]*"))
				assert(isMatch("foo/bar", "**/[abc]ar"))
				assert(not Boolean.toJSBoolean(isMatch("foo/jar", "**/[abc]ar")))
			end)

			itFIXME("should match character classes", function()
				assert(not Boolean.toJSBoolean(isMatch("abc", "a[bc]d")))
				assert(isMatch("abd", "a[bc]d"))
			end)

			itFIXME("should match character class alphabetical ranges", function()
				assert(not Boolean.toJSBoolean(isMatch("abc", "a[b-d]e")))
				assert(not Boolean.toJSBoolean(isMatch("abd", "a[b-d]e")))
				assert(isMatch("abe", "a[b-d]e"))
				assert(not Boolean.toJSBoolean(isMatch("ac", "a[b-d]e")))
				assert(not Boolean.toJSBoolean(isMatch("a-", "a[b-d]e")))
				assert(not Boolean.toJSBoolean(isMatch("abc", "a[b-d]")))
				assert(not Boolean.toJSBoolean(isMatch("abd", "a[b-d]")))
				assert(isMatch("abd", "a[b-d]+"))
				assert(not Boolean.toJSBoolean(isMatch("abe", "a[b-d]")))
				assert(isMatch("ac", "a[b-d]"))
				assert(not Boolean.toJSBoolean(isMatch("a-", "a[b-d]")))
			end)

			itFIXME("should match character classes with leading dashes", function()
				assert(not Boolean.toJSBoolean(isMatch("abc", "a[-c]")))
				assert(isMatch("ac", "a[-c]"))
				assert(isMatch("a-", "a[-c]"))
			end)

			itFIXME("should match character classes with trailing dashes", function()
				assert(not Boolean.toJSBoolean(isMatch("abc", "a[c-]")))
				assert(isMatch("ac", "a[c-]"))
				assert(isMatch("a-", "a[c-]"))
			end)

			itFIXME("should match bracket literals", function()
				assert(isMatch("a]c", "a[]]c"))
				assert(isMatch("a]c", "a]c"))
				assert(isMatch("a]", "a]"))
				assert(isMatch("a[c", "a[\\[]c"))
				assert(isMatch("a[c", "a[c"))
				assert(isMatch("a[", "a["))
			end)

			itFIXME("should support negated character classes", function()
				assert(not Boolean.toJSBoolean(isMatch("a]", "a[^bc]d")))
				assert(not Boolean.toJSBoolean(isMatch("acd", "a[^bc]d")))
				assert(isMatch("aed", "a[^bc]d"))
				assert(isMatch("azd", "a[^bc]d"))
				assert(not Boolean.toJSBoolean(isMatch("ac", "a[^bc]d")))
				assert(not Boolean.toJSBoolean(isMatch("a-", "a[^bc]d")))
			end)

			itFIXME("should match negated dashes", function()
				assert(not Boolean.toJSBoolean(isMatch("abc", "a[^-b]c")))
				assert(isMatch("adc", "a[^-b]c"))
				assert(not Boolean.toJSBoolean(isMatch("a-c", "a[^-b]c")))
			end)

			itFIXME("should match negated pm", function()
				assert(isMatch("a-c", "a[^\\]b]c"))
				assert(not Boolean.toJSBoolean(isMatch("abc", "a[^\\]b]c")))
				assert(not Boolean.toJSBoolean(isMatch("a]c", "a[^\\]b]c")))
				assert(isMatch("adc", "a[^\\]b]c"))
			end)

			itFIXME("should match alpha-numeric characters", function()
				assert(not Boolean.toJSBoolean(isMatch("0123e45g78", "[\\de]+")))
				assert(isMatch("0123e456", "[\\de]+"))
				assert(isMatch("01234", "[\\de]+"))
			end)

			itFIXME("should support valid regex ranges", function()
				assert(not Boolean.toJSBoolean(isMatch("a/a", "a/[b-c]")))
				assert(not Boolean.toJSBoolean(isMatch("a/z", "a/[b-c]")))
				assert(isMatch("a/b", "a/[b-c]"))
				assert(isMatch("a/c", "a/[b-c]"))
				assert(isMatch("a/b", "[a-z]/[a-z]"))
				assert(isMatch("a/z", "[a-z]/[a-z]"))
				assert(isMatch("z/z", "[a-z]/[a-z]"))
				assert(not Boolean.toJSBoolean(isMatch("a/x/y", "a/[a-z]")))
				assert(isMatch("a.a", "[a-b].[a-b]"))
				assert(isMatch("a.b", "[a-b].[a-b]"))
				assert(not Boolean.toJSBoolean(isMatch("a.a.a", "[a-b].[a-b]")))
				assert(not Boolean.toJSBoolean(isMatch("c.a", "[a-b].[a-b]")))
				assert(not Boolean.toJSBoolean(isMatch("d.a.d", "[a-b].[a-b]")))
				assert(not Boolean.toJSBoolean(isMatch("a.bb", "[a-b].[a-b]")))
				assert(not Boolean.toJSBoolean(isMatch("a.ccc", "[a-b].[a-b]")))
				assert(isMatch("a.a", "[a-d].[a-b]"))
				assert(isMatch("a.b", "[a-d].[a-b]"))
				assert(not Boolean.toJSBoolean(isMatch("a.a.a", "[a-d].[a-b]")))
				assert(isMatch("c.a", "[a-d].[a-b]"))
				assert(not Boolean.toJSBoolean(isMatch("d.a.d", "[a-d].[a-b]")))
				assert(not Boolean.toJSBoolean(isMatch("a.bb", "[a-d].[a-b]")))
				assert(not Boolean.toJSBoolean(isMatch("a.ccc", "[a-d].[a-b]")))
				assert(isMatch("a.a", "[a-d]*.[a-b]"))
				assert(isMatch("a.b", "[a-d]*.[a-b]"))
				assert(isMatch("a.a.a", "[a-d]*.[a-b]"))
				assert(isMatch("c.a", "[a-d]*.[a-b]"))
				assert(not Boolean.toJSBoolean(isMatch("d.a.d", "[a-d]*.[a-b]")))
				assert(not Boolean.toJSBoolean(isMatch("a.bb", "[a-d]*.[a-b]")))
				assert(not Boolean.toJSBoolean(isMatch("a.ccc", "[a-d]*.[a-b]")))
			end)

			itFIXME("should support valid regex ranges with glob negation patterns", function()
				assert(not Boolean.toJSBoolean(isMatch("a.a", "!*.[a-b]")))
				assert(not Boolean.toJSBoolean(isMatch("a.b", "!*.[a-b]")))
				assert(not Boolean.toJSBoolean(isMatch("a.a.a", "!*.[a-b]")))
				assert(not Boolean.toJSBoolean(isMatch("c.a", "!*.[a-b]")))
				assert(isMatch("d.a.d", "!*.[a-b]"))
				assert(isMatch("a.bb", "!*.[a-b]"))
				assert(isMatch("a.ccc", "!*.[a-b]"))
				assert(not Boolean.toJSBoolean(isMatch("a.a", "!*.[a-b]*")))
				assert(not Boolean.toJSBoolean(isMatch("a.b", "!*.[a-b]*")))
				assert(not Boolean.toJSBoolean(isMatch("a.a.a", "!*.[a-b]*")))
				assert(not Boolean.toJSBoolean(isMatch("c.a", "!*.[a-b]*")))
				assert(not Boolean.toJSBoolean(isMatch("d.a.d", "!*.[a-b]*")))
				assert(not Boolean.toJSBoolean(isMatch("a.bb", "!*.[a-b]*")))
				assert(isMatch("a.ccc", "!*.[a-b]*"))
				assert(not Boolean.toJSBoolean(isMatch("a.a", "![a-b].[a-b]")))
				assert(not Boolean.toJSBoolean(isMatch("a.b", "![a-b].[a-b]")))
				assert(isMatch("a.a.a", "![a-b].[a-b]"))
				assert(isMatch("c.a", "![a-b].[a-b]"))
				assert(isMatch("d.a.d", "![a-b].[a-b]"))
				assert(isMatch("a.bb", "![a-b].[a-b]"))
				assert(isMatch("a.ccc", "![a-b].[a-b]"))
				assert(not Boolean.toJSBoolean(isMatch("a.a", "![a-b]+.[a-b]+")))
				assert(not Boolean.toJSBoolean(isMatch("a.b", "![a-b]+.[a-b]+")))
				assert(isMatch("a.a.a", "![a-b]+.[a-b]+"))
				assert(isMatch("c.a", "![a-b]+.[a-b]+"))
				assert(isMatch("d.a.d", "![a-b]+.[a-b]+"))
				assert(not Boolean.toJSBoolean(isMatch("a.bb", "![a-b]+.[a-b]+")))
				assert(isMatch("a.ccc", "![a-b]+.[a-b]+"))
			end)

			itFIXME("should support valid regex ranges in negated character classes", function()
				assert(not Boolean.toJSBoolean(isMatch("a.a", "*.[^a-b]")))
				assert(not Boolean.toJSBoolean(isMatch("a.b", "*.[^a-b]")))
				assert(not Boolean.toJSBoolean(isMatch("a.a.a", "*.[^a-b]")))
				assert(not Boolean.toJSBoolean(isMatch("c.a", "*.[^a-b]")))
				assert(isMatch("d.a.d", "*.[^a-b]"))
				assert(not Boolean.toJSBoolean(isMatch("a.bb", "*.[^a-b]")))
				assert(not Boolean.toJSBoolean(isMatch("a.ccc", "*.[^a-b]")))
				assert(not Boolean.toJSBoolean(isMatch("a.a", "a.[^a-b]*")))
				assert(not Boolean.toJSBoolean(isMatch("a.b", "a.[^a-b]*")))
				assert(not Boolean.toJSBoolean(isMatch("a.a.a", "a.[^a-b]*")))
				assert(not Boolean.toJSBoolean(isMatch("c.a", "a.[^a-b]*")))
				assert(not Boolean.toJSBoolean(isMatch("d.a.d", "a.[^a-b]*")))
				assert(not Boolean.toJSBoolean(isMatch("a.bb", "a.[^a-b]*")))
				assert(isMatch("a.ccc", "a.[^a-b]*"))
			end)
		end)

		describe("regex capture groups", function()
			it('should support regex logical "or"', function()
				assert(isMatch("a/a", "a/(a|c)"))
				assert(not Boolean.toJSBoolean(isMatch("a/b", "a/(a|c)")))
				assert(isMatch("a/c", "a/(a|c)"))
				assert(isMatch("a/a", "a/(a|b|c)"))
				assert(isMatch("a/b", "a/(a|b|c)"))
				assert(isMatch("a/c", "a/(a|b|c)"))
			end)

			itFIXME("should support regex character classes inside extglobs", function()
				assert(not Boolean.toJSBoolean(isMatch("foo/bar", "**/!([a-k])*")))
				assert(not Boolean.toJSBoolean(isMatch("foo/jar", "**/!([a-k])*")))
				assert(not Boolean.toJSBoolean(isMatch("foo/bar", "**/!([a-i])*")))
				assert(isMatch("foo/bar", "**/!([c-i])*"))
				assert(isMatch("foo/jar", "**/!([a-i])*"))
			end)

			it("should support regex capture groups", function()
				assert(isMatch("a/bb/c/dd/e.md", "a/??/?/(dd)/e.md"))
				assert(isMatch("a/b/c/d/e.md", "a/?/c/?/(e|f).md"))
				assert(isMatch("a/b/c/d/f.md", "a/?/c/?/(e|f).md"))
			end)

			it("should support regex capture groups with slashes", function()
				assert(not Boolean.toJSBoolean(isMatch("a/a", "(a/b)")))
				assert(isMatch("a/b", "(a/b)"))
				assert(not Boolean.toJSBoolean(isMatch("a/c", "(a/b)")))
				assert(not Boolean.toJSBoolean(isMatch("b/a", "(a/b)")))
				assert(not Boolean.toJSBoolean(isMatch("b/b", "(a/b)")))
				assert(not Boolean.toJSBoolean(isMatch("b/c", "(a/b)")))
			end)

			it("should support regex non-capture groups", function()
				assert(isMatch("a/bb/c/dd/e.md", "a/**/(?:dd)/e.md"))
				assert(isMatch("a/b/c/d/e.md", "a/?/c/?/(?:e|f).md"))
				assert(isMatch("a/b/c/d/f.md", "a/?/c/?/(?:e|f).md"))
			end)
		end)

		describe("quantifiers", function()
			it("should support regex quantifiers by escaping braces", function()
				assert(isMatch("a   ", "a \\{1,5\\}", { unescape = true }))
				assert(not Boolean.toJSBoolean(isMatch("a   ", "a \\{1,2\\}", { unescape = true })))
				assert(not Boolean.toJSBoolean(isMatch("a   ", "a \\{1,2\\}")))
			end)

			it("should support extglobs with regex quantifiers", function()
				assert(not Boolean.toJSBoolean(isMatch("a  ", "@(!(a) \\{1,2\\})*", { unescape = true })))
				assert(not Boolean.toJSBoolean(isMatch("a ", "@(!(a) \\{1,2\\})*", { unescape = true })))
				assert(not Boolean.toJSBoolean(isMatch("a", "@(!(a) \\{1,2\\})*", { unescape = true })))
				assert(not Boolean.toJSBoolean(isMatch("aa", "@(!(a) \\{1,2\\})*", { unescape = true })))
				assert(not Boolean.toJSBoolean(isMatch("aaa", "@(!(a) \\{1,2\\})*", { unescape = true })))
				assert(not Boolean.toJSBoolean(isMatch("b", "@(!(a) \\{1,2\\})*", { unescape = true })))
				assert(not Boolean.toJSBoolean(isMatch("bb", "@(!(a) \\{1,2\\})*", { unescape = true })))
				assert(not Boolean.toJSBoolean(isMatch("bbb", "@(!(a) \\{1,2\\})*", { unescape = true })))
				assert(isMatch(" a ", "@(!(a) \\{1,2\\})*", { unescape = true }))
				assert(isMatch("b  ", "@(!(a) \\{1,2\\})*", { unescape = true }))
				assert(isMatch("b ", "@(!(a) \\{1,2\\})*", { unescape = true }))
				assert(isMatch("a   ", "@(!(a \\{1,2\\}))*"))
				assert(isMatch("a   b", "@(!(a \\{1,2\\}))*"))
				assert(isMatch("a  b", "@(!(a \\{1,2\\}))*"))
				assert(isMatch("a  ", "@(!(a \\{1,2\\}))*"))
				assert(isMatch("a ", "@(!(a \\{1,2\\}))*"))
				assert(isMatch("a", "@(!(a \\{1,2\\}))*"))
				assert(isMatch("aa", "@(!(a \\{1,2\\}))*"))
				assert(isMatch("b", "@(!(a \\{1,2\\}))*"))
				assert(isMatch("bb", "@(!(a \\{1,2\\}))*"))
				assert(isMatch(" a ", "@(!(a \\{1,2\\}))*"))
				assert(isMatch("b  ", "@(!(a \\{1,2\\}))*"))
				assert(isMatch("b ", "@(!(a \\{1,2\\}))*"))
			end)
		end)
	end)
end
