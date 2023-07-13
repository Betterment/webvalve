require 'spec_helper'

RSpec.describe WebValve::ServiceUrlConverter do
  let(:url) { "http://bar.com" }

  subject { described_class.new(url: url) }

  describe '#regexp' do
    it "returns a regexp" do
      expect(subject.regexp).to be_a(Regexp)
    end

    context "with an empty url" do
      let(:url) { "" }

      it "matches empty string" do
        expect("").to match(subject.regexp)
      end

      it "matches a string starting with a URL delimiter because the rest is just interpreted as suffix" do
        expect(":do:do:dodo:do:do").to match(subject.regexp)
      end

      it "doesn't match a string that doesn't start with a delimiter" do
        expect("jamietart:do:do:dodo:do:do").not_to match(subject.regexp)
      end
    end

    context "with a boundary char on the end" do
      let(:url) { "http://bar.com/" }

      it "matches arbitrary suffixes" do
        expect("http://bar.com/baz/bump/beep").to match(subject.regexp)
      end
    end

    context "with multiple asterisks" do
      let(:url) { "http://bar.com/**/bump" }

      it "matches like a single asterisk" do
        expect("http://bar.com/foo/bump").to match(subject.regexp)
      end

      it "doesn't match like a filesystem glob" do
        expect("http://bar.com/foo/bar/bump").not_to match(subject.regexp)
      end
    end

    context "with a trailing *" do
      let(:url) { "http://bar.com/*" }

      it "matches when empty" do
        expect("http://bar.com/").to match(subject.regexp)
      end

      it "matches when existing" do
        expect("http://bar.com/foobaloo").to match(subject.regexp)
      end

      it "matches with additional tokens" do
        expect("http://bar.com/foobaloo/wink").to match(subject.regexp)
      end

      it "doesn't match when missing the trailing slash tho" do
        expect("http://bar.com").not_to match(subject.regexp)
      end
    end

    context "with a totally wildcarded protocol" do
      let(:url) { "*://bar.com" }

      it "matches http" do
        expect("http://bar.com/").to match(subject.regexp)
      end

      it "matches anything else" do
        expect("gopher://bar.com/").to match(subject.regexp)
      end

      it "matches empty" do
        expect("://bar.com").to match(subject.regexp)
      end
    end

    context "with a wildcarded partial protocol" do
      let(:url) { "http*://bar.com" }

      it "matches empty" do
        expect("http://bar.com/").to match(subject.regexp)
      end

      it "matches full" do
        expect("https://bar.com/").to match(subject.regexp)
      end
    end

    context "with a TLD that is a substring of another TLD" do
      let(:url) { "http://bar.co" }

      it "doesn't match a different TLD when extending" do
        expect("http://bar.com").not_to match(subject.regexp)
      end
    end

    context "with a wildcard subdomain" do
      let(:url) { "http://*.bar.com" }

      it "matches" do
        expect("http://foo.bar.com").to match(subject.regexp)
      end

      it "doesn't match when too many subdomains" do
        expect("http://beep.foo.bar.com").not_to match(subject.regexp)
      end
    end

    context "with a partial postfix wildcard subdomain" do
      let(:url) { "http://foo*.bar.com" }

      it "matches when present" do
        expect("http://foobaz.bar.com").to match(subject.regexp)
      end

      it "matches when empty" do
        expect("http://foo.bar.com").to match(subject.regexp)
      end

      it "doesn't match when out of order" do
        expect("http://bazfoo.bar.com").not_to match(subject.regexp)
      end
    end

    context "with a partial prefix wildcard subdomain" do
      let(:url) { "http://*baz.bar.com" }

      it "matches when present" do
        expect("http://foobaz.bar.com").to match(subject.regexp)
      end

      it "matches when empty" do
        expect("http://baz.bar.com").to match(subject.regexp)
      end
    end

    context "with a wildcarded basic auth url" do
      let(:url) { "http://*:*@bar.com" }

      it "matches when present" do
        expect("http://bilbo:baggins@bar.com").to match(subject.regexp)
      end

      it "doesn't match when malformed" do
        expect("http://bilbobaggins@bar.com").not_to match(subject.regexp)
      end

      it "doesn't match when missing password part" do
        expect("http://bilbo@bar.com").not_to match(subject.regexp)
      end
    end

    context "with a wildcarded path" do
      let(:url) { "http://bar.com/*/whatever" }

      it "matches with arbitrarily spicy but legal, non-URL-significant characters" do
        expect("http://bar.com/a0-_~[]!$'(),;%+/whatever").to match(subject.regexp)
      end

      it "doesn't match when you throw a URL-significant char in there" do
        expect("http://bar.com/life=love/whatever").not_to match(subject.regexp)
      end
    end

    context "with a wildcarded query param" do
      let(:url) { "http://bar.com/whatever?foo=*&bar=bump" }

      it "matches when present" do
        expect("http://bar.com/whatever?foo=baz&bar=bump").to match(subject.regexp)
      end

      it "doesn't match when you throw a URL-significant char in there" do
        expect("http://bar.com/whatever?foo=baz#&bar=bump").not_to match(subject.regexp)
      end
    end
  end
end
