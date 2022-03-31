-- ROBLOX upstream: https://github.com/micromatch/picomatch/tree/2.3.1/test/extglobs.js

return function()
	local CurrentModule = script.Parent
	local PicomatchModule = CurrentModule.Parent
	local Packages = PicomatchModule.Parent

	local jestExpect = require(Packages.Dev.JestGlobals).expect

	local match = require(CurrentModule.support.match)
	local Picomatch = require(PicomatchModule)
	local isMatch, makeRe = Picomatch.isMatch, Picomatch.makeRe
	--[[*
	 * Ported from Bash 4.3 and 4.4 unit tests
	 ]]
	describe("extglobs", function()
		it("should throw on imbalanced sets when `optionsBrackets` is true", function()
			local opts = { strictBrackets = true }
			jestExpect(function()
				return makeRe("a(b", opts)
			end).toThrowError('Missing closing: ")"')
			jestExpect(function()
				return makeRe("a)b", opts)
			end).toThrowError('Missing opening: "("')
		end)

		it("should escape special characters immediately following opening parens", function()
			assert(isMatch("cbz", "c!(.)z"))
			assert(not isMatch("cbz", "c!(*)z"))
			assert(isMatch("cccz", "c!(b*)z"))
			assert(isMatch("cbz", "c!(+)z"))
			assert(isMatch("cbz", "c!(?)z"))
			assert(isMatch("cbz", "c!(@)z"))
		end)

		it("should not convert capture groups to extglobs", function()
			-- ROBLOX FIXME: RegExp doesn't contain 'source' property
			-- jestExpect(makeRe("c!(?:foo)?z").source).toEqual("^(?:c!(?:foo)?z)$")
			assert(not isMatch("c/z", "c!(?:foo)?z"))
			assert(isMatch("c!fooz", "c!(?:foo)?z"))
			assert(isMatch("c!z", "c!(?:foo)?z"))
		end)

		describe("negation", function()
			it("should support negation extglobs as the entire pattern", function()
				assert(not isMatch("abc", "!(abc)"))
				assert(not isMatch("a", "!(a)"))
				assert(isMatch("aa", "!(a)"))
				assert(isMatch("b", "!(a)"))
			end)

			it("should support negation extglobs as part of a pattern", function()
				assert(isMatch("aac", "a!(b)c"))
				assert(not isMatch("abc", "a!(b)c"))
				assert(isMatch("acc", "a!(b)c"))
				assert(isMatch("abz", "a!(z)"))
				assert(not isMatch("az", "a!(z)"))
			end)

			it("should support excluding dots with negation extglobs", function()
				assert(not isMatch("a.", "a!(.)"))
				assert(not isMatch(".a", "!(.)a"))
				assert(not isMatch("a.c", "a!(.)c"))
				assert(isMatch("abc", "a!(.)c"))
			end)

			-- See https://github.com/micromatch/picomatch/issues/83
			it("should support stars in negation extglobs", function()
				assert(not isMatch("/file.d.ts", "/!(*.d).ts"))
				assert(isMatch("/file.ts", "/!(*.d).ts"))
				assert(isMatch("/file.something.ts", "/!(*.d).ts"))
				assert(isMatch("/file.d.something.ts", "/!(*.d).ts"))
				assert(isMatch("/file.dhello.ts", "/!(*.d).ts"))
				assert(not isMatch("/file.d.ts", "**/!(*.d).ts"))
				assert(isMatch("/file.ts", "**/!(*.d).ts"))
				assert(isMatch("/file.something.ts", "**/!(*.d).ts"))
				assert(isMatch("/file.d.something.ts", "**/!(*.d).ts"))
				assert(isMatch("/file.dhello.ts", "**/!(*.d).ts"))
			end)

			-- See https://github.com/micromatch/picomatch/issues/93
			it("should support stars in negation extglobs with expression after closing parenthesis", function()
				-- Nested expression after closing parenthesis
				assert(not isMatch("/file.d.ts", "/!(*.d).{ts,tsx}"))
				assert(isMatch("/file.ts", "/!(*.d).{ts,tsx}"))
				assert(isMatch("/file.something.ts", "/!(*.d).{ts,tsx}"))
				assert(isMatch("/file.d.something.ts", "/!(*.d).{ts,tsx}"))
				assert(isMatch("/file.dhello.ts", "/!(*.d).{ts,tsx}")) -- Extglob after closing parenthesis
				assert(not isMatch("/file.d.ts", "/!(*.d).@(ts)"))
				assert(isMatch("/file.ts", "/!(*.d).@(ts)"))
				assert(isMatch("/file.something.ts", "/!(*.d).@(ts)"))
				assert(isMatch("/file.d.something.ts", "/!(*.d).@(ts)"))
				assert(isMatch("/file.dhello.ts", "/!(*.d).@(ts)"))
			end)

			it("should support negation extglobs in patterns with slashes", function()
				assert(not isMatch("foo/abc", "foo/!(abc)"))
				assert(isMatch("foo/bar", "foo/!(abc)"))
				assert(not isMatch("a/z", "a/!(z)"))
				assert(isMatch("a/b", "a/!(z)"))
				assert(not isMatch("c/z/v", "c/!(z)/v"))
				assert(isMatch("c/a/v", "c/!(z)/v"))
				assert(isMatch("a/a", "!(b/a)"))
				assert(not isMatch("b/a", "!(b/a)"))
				assert(not isMatch("foo/bar", "!(!(foo))*"))
				assert(isMatch("a/a", "!(b/a)"))
				assert(not isMatch("b/a", "!(b/a)"))
				assert(isMatch("a/a", "(!(b/a))"))
				assert(isMatch("a/a", "!((b/a))"))
				assert(not isMatch("b/a", "!((b/a))"))
				assert(not isMatch("a/a", "(!(?:b/a))"))
				assert(not isMatch("b/a", "!((?:b/a))"))
				assert(isMatch("a/a", "!(b/(a))"))
				assert(not isMatch("b/a", "!(b/(a))"))
				assert(isMatch("a/a", "!(b/a)"))
				assert(not isMatch("b/a", "!(b/a)"))
			end)

			it("should not match slashes with extglobs that do not have slashes", function()
				assert(not isMatch("c/z", "c!(z)"))
				assert(not isMatch("c/z", "c!(z)z"))
				assert(not isMatch("c/z", "c!(.)z"))
				assert(not isMatch("c/z", "c!(*)z"))
				assert(not isMatch("c/z", "c!(+)z"))
				assert(not isMatch("c/z", "c!(?)z"))
				assert(not isMatch("c/z", "c!(@)z"))
			end)

			it("should support matching slashes with extglobs that have slashes", function()
				assert(not isMatch("c/z", "a!(z)"))
				assert(not isMatch("c/z", "c!(.)z"))
				assert(not isMatch("c/z", "c!(/)z"))
				assert(not isMatch("c/z", "c!(/z)z"))
				assert(not isMatch("c/b", "c!(/z)z"))
				assert(isMatch("c/b/z", "c!(/z)z"))
			end)

			it("should support negation extglobs following !", function()
				assert(isMatch("abc", "!!(abc)"))
				assert(not isMatch("abc", "!!!(abc)"))
				assert(isMatch("abc", "!!!!(abc)"))
				assert(not isMatch("abc", "!!!!!(abc)"))
				assert(isMatch("abc", "!!!!!!(abc)"))
				assert(not isMatch("abc", "!!!!!!!(abc)"))
				assert(isMatch("abc", "!!!!!!!!(abc)"))
			end)

			it("should support nested negation extglobs", function()
				assert(isMatch("abc", "!(!(abc))"))
				assert(not isMatch("abc", "!(!(!(abc)))"))
				assert(isMatch("abc", "!(!(!(!(abc))))"))
				assert(not isMatch("abc", "!(!(!(!(!(abc)))))"))
				assert(isMatch("abc", "!(!(!(!(!(!(abc))))))"))
				assert(not isMatch("abc", "!(!(!(!(!(!(!(abc)))))))"))
				assert(isMatch("abc", "!(!(!(!(!(!(!(!(abc))))))))"))
				assert(isMatch("foo/abc", "foo/!(!(abc))"))
				assert(not isMatch("foo/abc", "foo/!(!(!(abc)))"))
				assert(isMatch("foo/abc", "foo/!(!(!(!(abc))))"))
				assert(not isMatch("foo/abc", "foo/!(!(!(!(!(abc)))))"))
				assert(isMatch("foo/abc", "foo/!(!(!(!(!(!(abc))))))"))
				assert(not isMatch("foo/abc", "foo/!(!(!(!(!(!(!(abc)))))))"))
				assert(isMatch("foo/abc", "foo/!(!(!(!(!(!(!(!(abc))))))))"))
			end)

			it("should support multiple !(...) extglobs in a pattern", function()
				assert(not isMatch("moo.cow", "!(moo).!(cow)"))
				assert(not isMatch("foo.cow", "!(moo).!(cow)"))
				assert(not isMatch("moo.bar", "!(moo).!(cow)"))
				assert(isMatch("foo.bar", "!(moo).!(cow)"))
				assert(not isMatch("a   ", "@(!(a) )*"))
				assert(not isMatch("a   b", "@(!(a) )*"))
				assert(not isMatch("a  b", "@(!(a) )*"))
				assert(not isMatch("a  ", "@(!(a) )*"))
				assert(not isMatch("a ", "@(!(a) )*"))
				assert(not isMatch("a", "@(!(a) )*"))
				assert(not isMatch("aa", "@(!(a) )*"))
				assert(not isMatch("b", "@(!(a) )*"))
				assert(not isMatch("bb", "@(!(a) )*"))
				assert(isMatch(" a ", "@(!(a) )*"))
				assert(isMatch("b  ", "@(!(a) )*"))
				assert(isMatch("b ", "@(!(a) )*"))
				assert(not isMatch("c/z", "a*!(z)"))
				assert(isMatch("abz", "a*!(z)"))
				assert(isMatch("az", "a*!(z)"))
				assert(not isMatch("a", "!(a*)"))
				assert(not isMatch("aa", "!(a*)"))
				assert(not isMatch("ab", "!(a*)"))
				assert(isMatch("b", "!(a*)"))
				assert(not isMatch("a", "!(*a*)"))
				assert(not isMatch("aa", "!(*a*)"))
				assert(not isMatch("ab", "!(*a*)"))
				assert(not isMatch("ac", "!(*a*)"))
				assert(isMatch("b", "!(*a*)"))
				assert(not isMatch("a", "!(*a)"))
				assert(not isMatch("aa", "!(*a)"))
				assert(not isMatch("bba", "!(*a)"))
				assert(isMatch("ab", "!(*a)"))
				assert(isMatch("ac", "!(*a)"))
				assert(isMatch("b", "!(*a)"))
				assert(not isMatch("a", "!(*a)*"))
				assert(not isMatch("aa", "!(*a)*"))
				assert(not isMatch("bba", "!(*a)*"))
				assert(not isMatch("ab", "!(*a)*"))
				assert(not isMatch("ac", "!(*a)*"))
				assert(isMatch("b", "!(*a)*"))
				assert(not isMatch("a", "!(a)*"))
				assert(not isMatch("abb", "!(a)*"))
				assert(isMatch("ba", "!(a)*"))
				assert(isMatch("aa", "a!(b)*"))
				assert(not isMatch("ab", "a!(b)*"))
				assert(not isMatch("aba", "a!(b)*"))
				assert(isMatch("ac", "a!(b)*"))
			end)

			it("should multiple nested negation extglobs", function()
				assert(isMatch("moo.cow", "!(!(moo)).!(!(cow))"))
			end)

			it("should support logical-or inside negation !(...) extglobs", function()
				assert(not isMatch("ac", "!(a|b)c"))
				assert(not isMatch("bc", "!(a|b)c"))
				assert(isMatch("cc", "!(a|b)c"))
			end)

			it("should support multiple logical-ors negation extglobs", function()
				assert(not isMatch("ac.d", "!(a|b)c.!(d|e)"))
				assert(not isMatch("bc.d", "!(a|b)c.!(d|e)"))
				assert(not isMatch("cc.d", "!(a|b)c.!(d|e)"))
				assert(not isMatch("ac.e", "!(a|b)c.!(d|e)"))
				assert(not isMatch("bc.e", "!(a|b)c.!(d|e)"))
				assert(not isMatch("cc.e", "!(a|b)c.!(d|e)"))
				assert(not isMatch("ac.f", "!(a|b)c.!(d|e)"))
				assert(not isMatch("bc.f", "!(a|b)c.!(d|e)"))
				assert(isMatch("cc.f", "!(a|b)c.!(d|e)"))
				assert(isMatch("dc.g", "!(a|b)c.!(d|e)"))
			end)

			it("should support nested logical-ors inside negation extglobs", function()
				assert(isMatch("ac.d", "!(!(a|b)c.!(d|e))"))
				assert(isMatch("bc.d", "!(!(a|b)c.!(d|e))"))
				assert(not isMatch("cc.d", "!(a|b)c.!(d|e)"))
				assert(isMatch("cc.d", "!(!(a|b)c.!(d|e))"))
				assert(isMatch("cc.d", "!(!(a|b)c.!(d|e))"))
				assert(isMatch("ac.e", "!(!(a|b)c.!(d|e))"))
				assert(isMatch("bc.e", "!(!(a|b)c.!(d|e))"))
				assert(isMatch("cc.e", "!(!(a|b)c.!(d|e))"))
				assert(isMatch("ac.f", "!(!(a|b)c.!(d|e))"))
				assert(isMatch("bc.f", "!(!(a|b)c.!(d|e))"))
				assert(not isMatch("cc.f", "!(!(a|b)c.!(d|e))"))
				assert(not isMatch("dc.g", "!(!(a|b)c.!(d|e))"))
			end)
		end)

		describe("file extensions", function()
			it("should support matching file extensions with @(...)", function()
				assert(not isMatch(".md", "@(a|b).md"))
				assert(not isMatch("a.js", "@(a|b).md"))
				assert(not isMatch("c.md", "@(a|b).md"))
				assert(isMatch("a.md", "@(a|b).md"))
				assert(isMatch("b.md", "@(a|b).md"))
			end)

			it("should support matching file extensions with +(...)", function()
				assert(not isMatch(".md", "+(a|b).md"))
				assert(not isMatch("a.js", "+(a|b).md"))
				assert(not isMatch("c.md", "+(a|b).md"))
				assert(isMatch("a.md", "+(a|b).md"))
				assert(isMatch("aa.md", "+(a|b).md"))
				assert(isMatch("ab.md", "+(a|b).md"))
				assert(isMatch("b.md", "+(a|b).md"))
				assert(isMatch("bb.md", "+(a|b).md"))
			end)

			it("should support matching file extensions with *(...)", function()
				assert(not isMatch("a.js", "*(a|b).md"))
				assert(not isMatch("c.md", "*(a|b).md"))
				assert(isMatch(".md", "*(a|b).md"))
				assert(isMatch("a.md", "*(a|b).md"))
				assert(isMatch("aa.md", "*(a|b).md"))
				assert(isMatch("ab.md", "*(a|b).md"))
				assert(isMatch("b.md", "*(a|b).md"))
				assert(isMatch("bb.md", "*(a|b).md"))
			end)

			it("should support matching file extensions with ?(...)", function()
				assert(not isMatch("a.js", "?(a|b).md"))
				assert(not isMatch("bb.md", "?(a|b).md"))
				assert(not isMatch("c.md", "?(a|b).md"))
				assert(isMatch(".md", "?(a|b).md"))
				assert(isMatch("a.md", "?(a|ab|b).md"))
				assert(isMatch("a.md", "?(a|b).md"))
				assert(isMatch("aa.md", "?(a|aa|b).md"))
				assert(isMatch("ab.md", "?(a|ab|b).md"))
				assert(isMatch("b.md", "?(a|ab|b).md")) -- See https://github.com/micromatch/micromatch/issues/186
				assert(isMatch("ab", "+(a)?(b)"))
				assert(isMatch("aab", "+(a)?(b)"))
				assert(isMatch("aa", "+(a)?(b)"))
				assert(isMatch("a", "+(a)?(b)"))
			end)
		end)

		describe("statechar", function()
			it("should support ?(...) extglobs ending with statechar", function()
				assert(not isMatch("ax", "a?(b*)"))
				assert(isMatch("ax", "?(a*|b)"))
			end)

			it("should support *(...) extglobs ending with statechar", function()
				assert(not isMatch("ax", "a*(b*)"))
				assert(isMatch("ax", "*(a*|b)"))
			end)

			it("should support @(...) extglobs ending with statechar", function()
				assert(not isMatch("ax", "a@(b*)"))
				assert(isMatch("ax", "@(a*|b)"))
			end)

			it("should support ?(...) extglobs ending with statechar_", function()
				assert(not isMatch("ax", "a?(b*)"))
				assert(isMatch("ax", "?(a*|b)"))
			end)

			it("should support !(...) extglobs ending with statechar", function()
				assert(isMatch("ax", "a!(b*)"))
				assert(not isMatch("ax", "!(a*|b)"))
			end)
		end)

		it("should match nested directories with negation extglobs", function()
			assert(isMatch("a", "!(a/**)"))
			assert(not isMatch("a/", "!(a/**)"))
			assert(not isMatch("a/b", "!(a/**)"))
			assert(not isMatch("a/b/c", "!(a/**)"))
			assert(isMatch("b", "!(a/**)"))
			assert(isMatch("b/c", "!(a/**)"))
			assert(isMatch("a/a", "a/!(b*)"))
			assert(not isMatch("a/b", "a/!(b*)"))
			assert(not isMatch("a/b/c", "a/!(b/*)"))
			assert(not isMatch("a/b/c", "a/!(b*)"))
			assert(isMatch("a/c", "a/!(b*)"))
			assert(isMatch("a/a/", "a/!(b*)/**"))
			assert(isMatch("a/a", "a/!(b*)"))
			assert(isMatch("a/a", "a/!(b*)/**"))
			assert(not isMatch("a/b", "a/!(b*)/**"))
			assert(not isMatch("a/b/c", "a/!(b*)/**"))
			assert(isMatch("a/c", "a/!(b*)/**"))
			assert(isMatch("a/c", "a/!(b*)"))
			assert(isMatch("a/c/", "a/!(b*)/**"))
		end)

		it("should support *(...)", function()
			assert(isMatch("a", "a*(z)"))
			assert(isMatch("az", "a*(z)"))
			assert(isMatch("azz", "a*(z)"))
			assert(isMatch("azzz", "a*(z)"))
			assert(not isMatch("abz", "a*(z)"))
			assert(not isMatch("cz", "a*(z)"))
			assert(not isMatch("a/a", "*(b/a)"))
			assert(not isMatch("a/b", "*(b/a)"))
			assert(not isMatch("a/c", "*(b/a)"))
			assert(isMatch("b/a", "*(b/a)"))
			assert(not isMatch("b/b", "*(b/a)"))
			assert(not isMatch("b/c", "*(b/a)"))
			assert(not isMatch("cz", "a**(z)"))
			assert(isMatch("abz", "a**(z)"))
			assert(isMatch("az", "a**(z)"))
			assert(not isMatch("c/z/v", "*(z)"))
			assert(isMatch("z", "*(z)"))
			assert(not isMatch("zf", "*(z)"))
			assert(not isMatch("fz", "*(z)"))
			assert(not isMatch("c/a/v", "c/*(z)/v"))
			assert(isMatch("c/z/v", "c/*(z)/v"))
			assert(not isMatch("a.md.js", "*.*(js).js"))
			assert(isMatch("a.js.js", "*.*(js).js"))
		end)

		it("should support +(...) extglobs", function()
			assert(not isMatch("a", "a+(z)"))
			assert(isMatch("az", "a+(z)"))
			assert(not isMatch("cz", "a+(z)"))
			assert(not isMatch("abz", "a+(z)"))
			assert(not isMatch("a+z", "a+(z)"))
			assert(isMatch("a+z", "a++(z)"))
			assert(not isMatch("c+z", "a+(z)"))
			assert(not isMatch("a+bz", "a+(z)"))
			assert(not isMatch("az", "+(z)"))
			assert(not isMatch("cz", "+(z)"))
			assert(not isMatch("abz", "+(z)"))
			assert(not isMatch("fz", "+(z)"))
			assert(isMatch("z", "+(z)"))
			assert(isMatch("zz", "+(z)"))
			assert(isMatch("c/z/v", "c/+(z)/v"))
			assert(isMatch("c/zz/v", "c/+(z)/v"))
			assert(not isMatch("c/a/v", "c/+(z)/v"))
		end)

		it("should support ?(...) extglobs", function()
			assert(isMatch("a?z", "a??(z)"))
			assert(isMatch("a.z", "a??(z)"))
			assert(not isMatch("a/z", "a??(z)"))
			assert(isMatch("a?", "a??(z)"))
			assert(isMatch("ab", "a??(z)"))
			assert(not isMatch("a/", "a??(z)"))
			assert(not isMatch("a?z", "a?(z)"))
			assert(not isMatch("abz", "a?(z)"))
			assert(not isMatch("z", "a?(z)"))
			assert(isMatch("a", "a?(z)"))
			assert(isMatch("az", "a?(z)"))
			assert(not isMatch("abz", "?(z)"))
			assert(not isMatch("az", "?(z)"))
			assert(not isMatch("cz", "?(z)"))
			assert(not isMatch("fz", "?(z)"))
			assert(not isMatch("zz", "?(z)"))
			assert(isMatch("z", "?(z)"))
			assert(not isMatch("c/a/v", "c/?(z)/v"))
			assert(not isMatch("c/zz/v", "c/?(z)/v"))
			assert(isMatch("c/z/v", "c/?(z)/v"))
		end)

		it("should support @(...) extglobs", function()
			assert(isMatch("c/z/v", "c/@(z)/v"))
			assert(not isMatch("c/a/v", "c/@(z)/v"))
			assert(isMatch("moo.cow", "@(*.*)"))
			assert(not isMatch("cz", "a*@(z)"))
			assert(isMatch("abz", "a*@(z)"))
			assert(isMatch("az", "a*@(z)"))
			assert(not isMatch("cz", "a@(z)"))
			assert(not isMatch("abz", "a@(z)"))
			assert(isMatch("az", "a@(z)"))
		end)

		it("should match exactly one of the given pattern:", function()
			assert(not isMatch("aa.aa", "(b|a).(a)"))
			assert(not isMatch("a.bb", "(b|a).(a)"))
			assert(not isMatch("a.aa.a", "(b|a).(a)"))
			assert(not isMatch("cc.a", "(b|a).(a)"))
			assert(isMatch("a.a", "(b|a).(a)"))
			assert(not isMatch("c.a", "(b|a).(a)"))
			assert(not isMatch("dd.aa.d", "(b|a).(a)"))
			assert(isMatch("b.a", "(b|a).(a)"))
			assert(not isMatch("aa.aa", "@(b|a).@(a)"))
			assert(not isMatch("a.bb", "@(b|a).@(a)"))
			assert(not isMatch("a.aa.a", "@(b|a).@(a)"))
			assert(not isMatch("cc.a", "@(b|a).@(a)"))
			assert(isMatch("a.a", "@(b|a).@(a)"))
			assert(not isMatch("c.a", "@(b|a).@(a)"))
			assert(not isMatch("dd.aa.d", "@(b|a).@(a)"))
			assert(isMatch("b.a", "@(b|a).@(a)"))
		end)

		itFIXME("should pass tests from rosenblatt's korn shell book", function()
			-- This one is the only difference, since picomatch does not match empty strings.
			assert(not isMatch("", "*(0|1|3|5|7|9)"))
			assert(isMatch("137577991", "*(0|1|3|5|7|9)"))
			assert(not isMatch("2468", "*(0|1|3|5|7|9)"))
			assert(isMatch("file.c", "*.c?(c)"))
			assert(not isMatch("file.C", "*.c?(c)"))
			assert(isMatch("file.cc", "*.c?(c)"))
			assert(not isMatch("file.ccc", "*.c?(c)"))
			assert(isMatch("parse.y", "!(*.c|*.h|Makefile.in|config*|README)"))
			assert(not isMatch("shell.c", "!(*.c|*.h|Makefile.in|config*|README)"))
			assert(isMatch("Makefile", "!(*.c|*.h|Makefile.in|config*|README)"))
			assert(not isMatch("Makefile.in", "!(*.c|*.h|Makefile.in|config*|README)"))
			assert(not isMatch("VMS.FILE;", "*\\;[1-9]*([0-9])"))
			assert(not isMatch("VMS.FILE;0", "*\\;[1-9]*([0-9])"))
			assert(isMatch("VMS.FILE;1", "*\\;[1-9]*([0-9])"))
			assert(isMatch("VMS.FILE;139", "*\\;[1-9]*([0-9])"))
			assert(not isMatch("VMS.FILE;1N", "*\\;[1-9]*([0-9])"))
		end)

		itFIXME("tests derived from the pd-ksh test suite", function()
			assert(isMatch("abcx", "!([*)*"))
			assert(isMatch("abcz", "!([*)*"))
			assert(isMatch("bbc", "!([*)*"))
			assert(isMatch("abcx", "!([[*])*"))
			assert(isMatch("abcz", "!([[*])*"))
			assert(isMatch("bbc", "!([[*])*"))
			assert(isMatch("abcx", "+(a|b\\[)*"))
			assert(isMatch("abcz", "+(a|b\\[)*"))
			assert(not isMatch("bbc", "+(a|b\\[)*"))
			assert(isMatch("abcx", "+(a|b[)*"))
			assert(isMatch("abcz", "+(a|b[)*"))
			assert(not isMatch("bbc", "+(a|b[)*"))
			assert(not isMatch("abcx", "[a*(]*z"))
			assert(isMatch("abcz", "[a*(]*z"))
			assert(not isMatch("bbc", "[a*(]*z"))
			assert(isMatch("aaz", "[a*(]*z"))
			assert(isMatch("aaaz", "[a*(]*z"))
			assert(not isMatch("abcx", "[a*(]*)z"))
			assert(not isMatch("abcz", "[a*(]*)z"))
			assert(not isMatch("bbc", "[a*(]*)z"))
			assert(not isMatch("abc", "+()c"))
			assert(not isMatch("abc", "+()x"))
			assert(isMatch("abc", "+(*)c"))
			assert(not isMatch("abc", "+(*)x"))
			assert(not isMatch("abc", "no-file+(a|b)stuff"))
			assert(not isMatch("abc", "no-file+(a*(c)|b)stuff"))
			assert(isMatch("abd", "a+(b|c)d"))
			assert(isMatch("acd", "a+(b|c)d"))
			assert(not isMatch("abc", "a+(b|c)d"))
			assert(isMatch("abd", "a!(b|B)"))
			assert(isMatch("acd", "a!(@(b|B))"))
			assert(isMatch("ac", "a!(@(b|B))"))
			assert(not isMatch("ab", "a!(@(b|B))"))
			assert(not isMatch("abc", "a!(@(b|B))d"))
			assert(not isMatch("abd", "a!(@(b|B))d"))
			assert(isMatch("acd", "a!(@(b|B))d"))
			assert(isMatch("abd", "a[b*(foo|bar)]d"))
			assert(not isMatch("abc", "a[b*(foo|bar)]d"))
			assert(not isMatch("acd", "a[b*(foo|bar)]d"))
		end)

		itFIXME("stuff from korn's book", function()
			assert(not isMatch("para", "para+([0-9])"))
			assert(not isMatch("para381", "para?([345]|99)1"))
			assert(not isMatch("paragraph", "para*([0-9])"))
			assert(not isMatch("paramour", "para@(chute|graph)"))
			assert(isMatch("para", "para*([0-9])"))
			assert(isMatch("para.38", "para!(*.[0-9])"))
			assert(isMatch("para.38", "para!(*.[00-09])"))
			assert(isMatch("para.graph", "para!(*.[0-9])"))
			assert(isMatch("para13829383746592", "para*([0-9])"))
			assert(isMatch("para39", "para!(*.[0-9])"))
			assert(isMatch("para987346523", "para+([0-9])"))
			assert(isMatch("para991", "para?([345]|99)1"))
			assert(isMatch("paragraph", "para!(*.[0-9])"))
			assert(isMatch("paragraph", "para@(chute|graph)"))
		end)

		it("simple kleene star tests", function()
			assert(not isMatch("foo", "*(a|b[)"))
			assert(not isMatch("(", "*(a|b[)"))
			assert(not isMatch(")", "*(a|b[)"))
			assert(not isMatch("|", "*(a|b[)"))
			assert(isMatch("a", "*(a|b)"))
			assert(isMatch("b", "*(a|b)"))
			assert(isMatch("b[", "*(a|b\\[)"))
			assert(isMatch("ab[", "+(a|b\\[)"))
			assert(not isMatch("ab[cde", "+(a|b\\[)"))
			assert(isMatch("ab[cde", "+(a|b\\[)*"))
			assert(isMatch("foo", "*(a|b|f)*"))
			assert(isMatch("foo", "*(a|b|o)*"))
			assert(isMatch("foo", "*(a|b|f|o)"))
			assert(isMatch("*(a|b[)", "\\*\\(a\\|b\\[\\)"))
			assert(not isMatch("foo", "*(a|b)"))
			assert(not isMatch("foo", "*(a|b\\[)"))
			assert(isMatch("foo", "*(a|b\\[)|f*"))
		end)

		itFIXME("should support multiple extglobs:", function()
			assert(isMatch("moo.cow", "@(*).@(*)"))
			assert(isMatch("a.a", "*.@(a|b|@(ab|a*@(b))*@(c)d)"))
			assert(isMatch("a.b", "*.@(a|b|@(ab|a*@(b))*@(c)d)"))
			assert(not isMatch("a.c", "*.@(a|b|@(ab|a*@(b))*@(c)d)"))
			assert(not isMatch("a.c.d", "*.@(a|b|@(ab|a*@(b))*@(c)d)"))
			assert(not isMatch("c.c", "*.@(a|b|@(ab|a*@(b))*@(c)d)"))
			assert(not isMatch("a.", "*.@(a|b|@(ab|a*@(b))*@(c)d)"))
			assert(not isMatch("d.d", "*.@(a|b|@(ab|a*@(b))*@(c)d)"))
			assert(not isMatch("e.e", "*.@(a|b|@(ab|a*@(b))*@(c)d)"))
			assert(not isMatch("f.f", "*.@(a|b|@(ab|a*@(b))*@(c)d)"))
			assert(isMatch("a.abcd", "*.@(a|b|@(ab|a*@(b))*@(c)d)"))
			assert(not isMatch("a.a", "!(*.a|*.b|*.c)"))
			assert(not isMatch("a.b", "!(*.a|*.b|*.c)"))
			assert(not isMatch("a.c", "!(*.a|*.b|*.c)"))
			assert(isMatch("a.c.d", "!(*.a|*.b|*.c)"))
			assert(not isMatch("c.c", "!(*.a|*.b|*.c)"))
			assert(isMatch("a.", "!(*.a|*.b|*.c)"))
			assert(isMatch("d.d", "!(*.a|*.b|*.c)"))
			assert(isMatch("e.e", "!(*.a|*.b|*.c)"))
			assert(isMatch("f.f", "!(*.a|*.b|*.c)"))
			assert(isMatch("a.abcd", "!(*.a|*.b|*.c)"))
			assert(isMatch("a.a", "!(*.[^a-c])"))
			assert(isMatch("a.b", "!(*.[^a-c])"))
			assert(isMatch("a.c", "!(*.[^a-c])"))
			assert(not isMatch("a.c.d", "!(*.[^a-c])"))
			assert(isMatch("c.c", "!(*.[^a-c])"))
			assert(isMatch("a.", "!(*.[^a-c])"))
			assert(not isMatch("d.d", "!(*.[^a-c])"))
			assert(not isMatch("e.e", "!(*.[^a-c])"))
			assert(not isMatch("f.f", "!(*.[^a-c])"))
			assert(isMatch("a.abcd", "!(*.[^a-c])"))
			assert(not isMatch("a.a", "!(*.[a-c])"))
			assert(not isMatch("a.b", "!(*.[a-c])"))
			assert(not isMatch("a.c", "!(*.[a-c])"))
			assert(isMatch("a.c.d", "!(*.[a-c])"))
			assert(not isMatch("c.c", "!(*.[a-c])"))
			assert(isMatch("a.", "!(*.[a-c])"))
			assert(isMatch("d.d", "!(*.[a-c])"))
			assert(isMatch("e.e", "!(*.[a-c])"))
			assert(isMatch("f.f", "!(*.[a-c])"))
			assert(isMatch("a.abcd", "!(*.[a-c])"))
			assert(not isMatch("a.a", "!(*.[a-c]*)"))
			assert(not isMatch("a.b", "!(*.[a-c]*)"))
			assert(not isMatch("a.c", "!(*.[a-c]*)"))
			assert(not isMatch("a.c.d", "!(*.[a-c]*)"))
			assert(not isMatch("c.c", "!(*.[a-c]*)"))
			assert(isMatch("a.", "!(*.[a-c]*)"))
			assert(isMatch("d.d", "!(*.[a-c]*)"))
			assert(isMatch("e.e", "!(*.[a-c]*)"))
			assert(isMatch("f.f", "!(*.[a-c]*)"))
			assert(not isMatch("a.abcd", "!(*.[a-c]*)"))
			assert(not isMatch("a.a", "*.!(a|b|c)"))
			assert(not isMatch("a.b", "*.!(a|b|c)"))
			assert(not isMatch("a.c", "*.!(a|b|c)"))
			assert(isMatch("a.c.d", "*.!(a|b|c)"))
			assert(not isMatch("c.c", "*.!(a|b|c)"))
			assert(isMatch("a.", "*.!(a|b|c)"))
			assert(isMatch("d.d", "*.!(a|b|c)"))
			assert(isMatch("e.e", "*.!(a|b|c)"))
			assert(isMatch("f.f", "*.!(a|b|c)"))
			assert(isMatch("a.abcd", "*.!(a|b|c)"))
			assert(isMatch("a.a", "*!(.a|.b|.c)"))
			assert(isMatch("a.b", "*!(.a|.b|.c)"))
			assert(isMatch("a.c", "*!(.a|.b|.c)"))
			assert(isMatch("a.c.d", "*!(.a|.b|.c)"))
			assert(isMatch("c.c", "*!(.a|.b|.c)"))
			assert(isMatch("a.", "*!(.a|.b|.c)"))
			assert(isMatch("d.d", "*!(.a|.b|.c)"))
			assert(isMatch("e.e", "*!(.a|.b|.c)"))
			assert(isMatch("f.f", "*!(.a|.b|.c)"))
			assert(isMatch("a.abcd", "*!(.a|.b|.c)"))
			assert(not isMatch("a.a", "!(*.[a-c])*"))
			assert(not isMatch("a.b", "!(*.[a-c])*"))
			assert(not isMatch("a.c", "!(*.[a-c])*"))
			assert(not isMatch("a.c.d", "!(*.[a-c])*"))
			assert(not isMatch("c.c", "!(*.[a-c])*"))
			assert(isMatch("a.", "!(*.[a-c])*"))
			assert(isMatch("d.d", "!(*.[a-c])*"))
			assert(isMatch("e.e", "!(*.[a-c])*"))
			assert(isMatch("f.f", "!(*.[a-c])*"))
			assert(not isMatch("a.abcd", "!(*.[a-c])*"))
			assert(isMatch("a.a", "*!(.a|.b|.c)*"))
			assert(isMatch("a.b", "*!(.a|.b|.c)*"))
			assert(isMatch("a.c", "*!(.a|.b|.c)*"))
			assert(isMatch("a.c.d", "*!(.a|.b|.c)*"))
			assert(isMatch("c.c", "*!(.a|.b|.c)*"))
			assert(isMatch("a.", "*!(.a|.b|.c)*"))
			assert(isMatch("d.d", "*!(.a|.b|.c)*"))
			assert(isMatch("e.e", "*!(.a|.b|.c)*"))
			assert(isMatch("f.f", "*!(.a|.b|.c)*"))
			assert(isMatch("a.abcd", "*!(.a|.b|.c)*"))
			assert(not isMatch("a.a", "*.!(a|b|c)*"))
			assert(not isMatch("a.b", "*.!(a|b|c)*"))
			assert(not isMatch("a.c", "*.!(a|b|c)*"))
			assert(isMatch("a.c.d", "*.!(a|b|c)*"))
			assert(not isMatch("c.c", "*.!(a|b|c)*"))
			assert(isMatch("a.", "*.!(a|b|c)*"))
			assert(isMatch("d.d", "*.!(a|b|c)*"))
			assert(isMatch("e.e", "*.!(a|b|c)*"))
			assert(isMatch("f.f", "*.!(a|b|c)*"))
			assert(not isMatch("a.abcd", "*.!(a|b|c)*"))
		end)

		it("should correctly match empty parens", function()
			assert(not isMatch("def", "@()ef"))
			assert(isMatch("ef", "@()ef"))
			assert(not isMatch("def", "()ef"))
			assert(isMatch("ef", "()ef"))
		end)

		itFIXME("should match escaped parens", function()
			-- ROBLOX FIXME: need a test for platform
			local isWindows = false
			if isWindows then
				assert(isMatch("a\\(b", "a\\\\\\(b"))
			end
			assert(isMatch("a(b", "a(b"))
			assert(isMatch("a(b", "a\\(b"))
			assert(not isMatch("a((b", "a(b"))
			assert(not isMatch("a((((b", "a(b"))
			assert(not isMatch("ab", "a(b"))
			assert(isMatch("a(b", "a\\(b"))
			assert(not isMatch("a((b", "a\\(b"))
			assert(not isMatch("a((((b", "a\\(b"))
			assert(not isMatch("ab", "a\\(b"))
			assert(isMatch("a(b", "a(*b"))
			assert(isMatch("a(ab", "a\\(*b"))
			assert(isMatch("a((b", "a(*b"))
			assert(isMatch("a((((b", "a(*b"))
			assert(not isMatch("ab", "a(*b"))
		end)

		itFIXME("should match escaped backslashes", function()
			assert(isMatch("a(b", "a\\(b"))
			assert(isMatch("a((b", "a\\(\\(b"))
			assert(isMatch("a((((b", "a\\(\\(\\(\\(b"))
			assert(not isMatch("a(b", "a\\\\(b"))
			assert(not isMatch("a((b", "a\\\\(b"))
			assert(not isMatch("a((((b", "a\\\\(b"))
			assert(not isMatch("ab", "a\\\\(b"))
			assert(not isMatch("a/b", "a\\\\b"))
			assert(not isMatch("ab", "a\\\\b"))
		end)

		-- these are not extglobs, and do not need to pass, but they are included
		-- to test integration with other features
		itFIXME("should support regex characters", function()
			local fixtures = {
				"a c",
				"a.c",
				"a.xy.zc",
				"a.zc",
				"a123c",
				"a1c",
				"abbbbc",
				"abbbc",
				"abbc",
				"abc",
				"abq",
				"axy zc",
				"axy",
				"axy.zc",
				"axyzc",
			}
			-- ROBLOX FIXME: need a test for platform
			local isWindows = false
			if isWindows then
				jestExpect(match({ "a\\b", "a/b", "ab" }, "a/b")).toEqual({ "a/b" })
			end
			jestExpect(match({ "a/b", "ab" }, "a/b")).toEqual({ "a/b" })
			jestExpect(match(fixtures, "ab?bc")).toEqual({ "abbbc" })
			jestExpect(match(fixtures, "ab*c")).toEqual({ "abbbbc", "abbbc", "abbc", "abc" })
			jestExpect(match(fixtures, "a+(b)bc")).toEqual({ "abbbbc", "abbbc", "abbc" })
			jestExpect(match(fixtures, "^abc$")).toEqual({})
			jestExpect(match(fixtures, "a.c")).toEqual({ "a.c" })
			jestExpect(match(fixtures, "a.*c")).toEqual({ "a.c", "a.xy.zc", "a.zc" })
			jestExpect(match(fixtures, "a*c")).toEqual({
				"a c",
				"a.c",
				"a.xy.zc",
				"a.zc",
				"a123c",
				"a1c",
				"abbbbc",
				"abbbc",
				"abbc",
				"abc",
				"axy zc",
				"axy.zc",
				"axyzc",
			})
			jestExpect(match(fixtures, "a[\\w]+c")).toEqual(
				{ "a123c", "a1c", "abbbbc", "abbbc", "abbc", "abc", "axyzc" }
				-- , "Should match word characters"
			)
			jestExpect(match(fixtures, "a[\\W]+c")).toEqual(
				{ "a c", "a.c" }
				-- , "Should match non-word characters"
			)
			jestExpect(match(fixtures, "a[\\d]+c")).toEqual(
				{ "a123c", "a1c" }
				-- , "Should match numbers"
			)
			jestExpect(match({ "foo@#$%123ASD #$$%^&", "foo!@#$asdfl;", "123" }, "[\\d]+")).toEqual({ "123" })
			jestExpect(match({ "a123c", "abbbc" }, "a[\\D]+c")).toEqual(
				{ "abbbc" }
				-- , "Should match non-numbers"
			)
			jestExpect(match({ "foo", " foo " }, "(f|o)+\\b")).toEqual(
				{ "foo" }
				-- , "Should match word boundaries"
			)
		end)
	end)
end
