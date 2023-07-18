require 'spec_helper'

RSpec.describe WebValve::ServiceUrlConverter do
  let(:url) { "http://bar.com" }

  subject { described_class.new(url: url) }

  describe '#template' do
    it "returns a template" do
      expect(subject.template).to be_an(Addressable::Template)
    end

    it "matches arbitrary path" do
      expect(subject.template.match("http://bar.com/foo/bar/baz")).to be_present
    end

    it "matches arbitrary query params" do
      expect(subject.template.match("http://bar.com?foo=bar&baz=bump")).to be_present
    end

    context "with a regexp" do
      let(:url) { %r{\Ahttp://foo\.com} }

      it "returns the same object" do
        expect(subject.template).to be_a(Regexp)
        expect(subject.template).to equal(url)
      end
    end

    context "with an Addressable::Template" do
      let(:url) { Addressable::Template.new("http://foo.com{/path*}") }

      it "returns the same object" do
        expect(subject.template).to be_an(Addressable::Template)
        expect(subject.template).to equal(url)
      end
    end

    context "with a fragment" do
      let(:url) { "http://foo.com#now" }

      it "raises an error" do
        expect { subject.template }.to raise_error(/fragment will never match/i)
      end
    end

    context "with an empty url" do
      let(:url) { "" }

      it "matches empty string" do
        expect(subject.template.match("")).to be_present
      end

      it "matches a string starting with a URL delimiter because the rest is just interpreted as suffix" do
        expect(subject.template.match("//foo")).to be_present
      end

      it "doesn't match a string that doesn't start with a delimiter" do
        expect(subject.template.match("http://foo")).to eq(nil)
      end
    end

    context "with a boundary char on the end" do
      let(:url) { "http://bar.com/" }

      it "matches arbitrary suffixes" do
        expect(subject.template.match("http://bar.com/baz/bump/beep")).to be_present
      end
    end

    context "with multiple asterisks" do
      let(:url) { "http://bar.com/**/bump" }

      it "matches like a single asterisk" do
        expect(subject.template.match("http://bar.com/foo/bump")).to be_present
      end

      it "doesn't match like a filesystem glob" do
        expect(subject.template.match("http://bar.com/foo/bar/bump")).to eq(nil)
      end
    end

    context "with a trailing *" do
      let(:url) { "http://bar.com/*" }

      it "matches when empty" do
        expect(subject.template.match("http://bar.com/")).to be_present
      end

      it "matches when existing" do
        expect(subject.template.match("http://bar.com/foobaloo")).to be_present
      end

      it "matches with additional tokens" do
        expect(subject.template.match("http://bar.com/foobaloo/wink")).to be_present
      end

      it "doesn't match when missing the trailing slash tho" do
        expect(subject.template.match("http://bar.com")).to eq(nil)
      end
    end

    context "with a totally wildcarded protocol" do
      let(:url) { "*://bar.com" }

      it "matches http" do
        expect(subject.template.match("http://bar.com/")).to be_present
      end

      it "matches anything else" do
        expect(subject.template.match("gopher://bar.com/")).to be_present
      end
    end

    context "with a wildcarded partial protocol" do
      let(:url) { "http*://bar.com" }

      it "matches empty" do
        expect(subject.template.match("http://bar.com/")).to be_present
      end

      it "matches full" do
        expect(subject.template.match("https://bar.com/")).to be_present
      end
    end

    context "with a TLD that is a substring of another TLD" do
      let(:url) { "http://bar.co" }

      it "doesn't match a different TLD when extending" do
        expect(subject.template.match("http://bar.com")).to eq(nil)
      end
    end

    context "with a wildcard subdomain" do
      let(:url) { "http://*.bar.com" }

      it "matches" do
        expect(subject.template.match("http://foo.bar.com")).to be_present
      end

      it "matches with extra subdomains" do
        expect(subject.template.match("http://beep.foo.bar.com")).to be_present
      end
    end

    context "with a partial postfix wildcard subdomain" do
      let(:url) { "http://foo*.bar.com" }

      it "matches when present" do
        expect(subject.template.match("http://foobaz.bar.com")).to be_present
      end

      it "matches when empty" do
        expect(subject.template.match("http://foo.bar.com")).to be_present
      end

      it "doesn't match when out of order" do
        expect(subject.template.match("http://bazfoo.bar.com")).to eq(nil)
      end
    end

    context "with a partial prefix wildcard subdomain" do
      let(:url) { "http://*baz.bar.com" }

      it "matches when present" do
        expect(subject.template.match("http://foobaz.bar.com")).to be_present
      end

      it "matches when empty" do
        expect(subject.template.match("http://baz.bar.com")).to be_present
      end
    end

    context "with a wildcarded basic auth url" do
      let(:url) { "http://*:*@bar.com" }

      it "matches when present" do
        expect(subject.template.match("http://bilbo:baggins@bar.com")).to be_present
      end

      it "doesn't match when malformed" do
        expect(subject.template.match("http://bilbobaggins@bar.com")).to eq(nil)
      end

      it "doesn't match when missing password part" do
        expect(subject.template.match("http://bilbo@bar.com")).to eq(nil)
      end
    end

    context "with a wildcarded path" do
      let(:url) { "http://bar.com/*/whatever" }

      it "matches with a wildcarded path segment" do
        expect(subject.template.match("http://bar.com/big/whatever")).to be_present
      end

      it "doesn't match when you throw an extra directory level in there" do
        expect(subject.template.match("http://bar.com/big/bag/whatever")).to eq(nil)
      end

      it "doesn't match when you throw a URL-significant char in there" do
        expect(subject.template.match("http://bar.com/life=love/whatever")).to eq(nil)
      end
    end

    context "with a wildcarded query param" do
      let(:url) { "http://bar.com/whatever?foo=*&bar=bump" }

      it "matches when present" do
        expect(subject.template.match("http://bar.com/whatever?foo=baz&bar=bump")).to be_present
      end

      it "doesn't match when you throw a URL-significant char in there" do
        expect(subject.template.match("http://bar.com/whatever?foo=baz#&bar=bump")).to eq(nil)
      end
    end
  end
end
