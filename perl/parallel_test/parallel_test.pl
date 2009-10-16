#!/usr/bin/perl

use strict;
use warnings;
use Perl6::Say;
use YAML;

use Time::HiRes;
use threads();
use LWP::Simple;
use Web::Scraper;
use Parallel::ForkManager;
use IPC::Shareable;

use Benchmark qw(timethese cmpthese);

my @links = test_urls();
my $result = timethese(10, {
	'single'       => sub { do_sthread(\@links);  },
	'multi_thread' => sub { do_mthread(\@links);  },
	'fork_manager' => sub { do_mprocess(\@links); }
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
	my $with_coro = shift || 0;
	my $s = scraper {
		process '//title', 'title' => 'TEXT';
	};
	return $s->scrape(get($url))->{'title'};
}

# シングルスレッドでリクエストを発行
sub do_sthread {
	my $links = shift;
	my $t1 = Time::HiRes::time;

	my @result;
	foreach my $link (@$links) {
		push(@result, get_title($link));
	}

	say "Single Thread Time took: ", Time::HiRes::time - $t1;
	return @result;
}

# マルチスレッドでリクエストを発行
sub do_mthread {
	my $links = shift;
	my $t1 = Time::HiRes::time;

	my @threads = map {
		threads->create(\&get_title, $_);
	} @$links;

	my @result;
	push (@result, $_->join) for @threads;

	say "Multi Thread Time took: ", Time::HiRes::time - $t1;
	return @result;
}

# Paralell::ForkManagerでの処理
sub do_mprocess {
	my $links = shift;

	my $t1 = Time::HiRes::time;
	my $pm = Parallel::ForkManager->new(10);
	my $handle = tie my @result, 'IPC::Shareable', undef, { destroy => 1 };
	@result = ();
	for my $link (@$links) {
		$pm->start and next;
		my $title = get_title($link);
		$handle->shlock;
		push(@result, $title);
		$handle->shunlock;
		$pm->finish;
	}
	$pm->wait_all_children;
	say "Multi Process Time took: ", Time::HiRes::time - $t1;
	return @result;
}

