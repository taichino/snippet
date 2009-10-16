#!/usr/bin/perl

use strict;
use warnings;
use Perl6::Say;
use YAML;
use Time::HiRes;

use LWP::Simple;
use Web::Scraper;
use Coro;
use Coro::LWP;
use Benchmark qw(timethese cmpthese);

my @links = test_urls();
my $result = timethese(10, {
	'coro' => sub { do_coro(\@links); }
});
cmpthese($result);
exit;

# はてなブックマークから現在のホットエントリーのURLリストを取得
sub test_urls {
	my $source  = "http://b.hatena.ne.jp/hotentry";
	my $scraper = scraper {
		process '//div[@class="entry-body"]/h3/a', 'links[]' => '@href';
	};
	return @{$scraper->scrape(get($source))->{'links'}};
}

# 指定したURLにあるページのタイトルを取得する
sub get_title {
	my $url = shift;
	my $scraper = scraper {
		process '//title', 'title' => 'TEXT';
	};
	return $scraper->scrape(get($url))->{'title'};
}

# Coroでの処理
sub do_coro {
	my $links = shift;
	my $t1 = Time::HiRes::time;

	my (@coro, @result) = (), ();
	for my $link (@$links) {
		push @coro, async {
			push @result, get_title($link);
		};
	}
	$_->join for @coro;
	say "Coro Time took: ", Time::HiRes::time - $t1;
	return @result;
}
