module Homebrew
  class TestCase < ::Minitest::Test
    require "test/support/helper/fs_leak_logger"
    require "test/support/helper/lifecycle_enforcer"
    require "test/support/helper/shutup"
    require "test/support/helper/version_assertions"
    include Test::Helper::FSLeakLogger
    include Test::Helper::LifecycleEnforcer
    include Test::Helper::Shutup
    include Test::Helper::VersionAssertions

    TEST_SHA1   = "deadbeefdeadbeefdeadbeefdeadbeefdeadbeef".freeze
    TEST_SHA256 = "deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef".freeze

    def setup
      super

      @__argv = ARGV.dup
      @__env = ENV.to_hash # dup doesn't work on ENV
    end

    def teardown
      ARGV.replace(@__argv)
      ENV.replace(@__env)

      Tab.clear_cache

      coretap = CoreTap.new
      paths_to_delete = [
        HOMEBREW_LINKED_KEGS,
        HOMEBREW_PINNED_KEGS,
        HOMEBREW_CELLAR.children,
        HOMEBREW_CACHE.children,
        HOMEBREW_LOCK_DIR.children,
        HOMEBREW_LOGS.children,
        HOMEBREW_TEMP.children,
        HOMEBREW_PREFIX/".git",
        HOMEBREW_PREFIX/"bin",
        HOMEBREW_PREFIX/"share",
        HOMEBREW_PREFIX/"opt",
        HOMEBREW_PREFIX/"Caskroom",
        HOMEBREW_LIBRARY/"Taps/caskroom",
        HOMEBREW_LIBRARY/"Taps/homebrew/homebrew-bundle",
        HOMEBREW_LIBRARY/"Taps/homebrew/homebrew-foo",
        HOMEBREW_LIBRARY/"Taps/homebrew/homebrew-services",
        HOMEBREW_LIBRARY/"Taps/homebrew/homebrew-shallow",
        HOMEBREW_REPOSITORY/".git",
        coretap.path/".git",
        coretap.alias_dir,
        coretap.formula_dir.children,
        coretap.path/"formula_renames.json",
      ].flatten
      FileUtils.rm_rf paths_to_delete

      super
    end

    def formula(name = "formula_name", path = Formulary.core_path(name), spec = :stable, alias_path: nil, &block)
      @_f = Class.new(Formula, &block).new(name, path, spec, alias_path: alias_path)
    end

    def mktmpdir(prefix_suffix = nil, &block)
      Dir.mktmpdir(prefix_suffix, HOMEBREW_TEMP, &block)
    end

    def needs_compat
      skip "Requires compat/ code" if ENV["HOMEBREW_NO_COMPAT"]
    end

    def needs_python
      skip "Requires Python" unless which("python")
    end

    def assert_nothing_raised
      yield
    end

    def assert_eql(exp, act, msg = nil)
      msg = message(msg, "") { diff exp, act }
      assert exp.eql?(act), msg
    end

    def refute_eql(exp, act, msg = nil)
      msg = message(msg) do
        "Expected #{mu_pp(act)} to not be eql to #{mu_pp(exp)}"
      end
      refute exp.eql?(act), msg
    end

    def dylib_path(name)
      Pathname.new("#{TEST_FIXTURE_DIR}/mach/#{name}.dylib")
    end

    def bundle_path(name)
      Pathname.new("#{TEST_FIXTURE_DIR}/mach/#{name}.bundle")
    end

    # Use a stubbed {Formulary::FormulaLoader} to make a given formula be found
    # when loading from {Formulary} with `ref`.
    def stub_formula_loader(formula, ref = formula.full_name)
      loader = mock
      loader.stubs(:get_formula).returns(formula)
      Formulary.stubs(:loader_for).with(ref, from: :keg).returns(loader)
      Formulary.stubs(:loader_for).with(ref, from: nil).returns(loader)
    end
  end
end
