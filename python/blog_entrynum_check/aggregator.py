#!/opt/local/bin/python2.5
# -*- coding: utf-8 -*-
from __future__ import with_statement

import re
import urllib
import MySQLdb
from BeautifulSoup import BeautifulSoup

def parse_page(url):
  soup = BeautifulSoup(urllib.urlopen(url).read())

  next    = soup.find('a', attrs={'rel':'next'})['href']
  diaries = []
  for d in soup.findAll('tr', attrs={'id':'models'}):
    tds   = d.findAll('td')
    title = tds[3].find('a').contents[0]
    url   = tds[3].find('a')['href']
    b_num = tds[4].find('b').decodeContents()
    s_num = tds[7].decodeContents()
    diaries.append([title, url, b_num, s_num])
  return (next, diaries)

if __name__ == '__main__':
  page = 1
  next_url = 'http://tophatenar.com/ranking/bookmark/1?blog=hatena'
  while True:
    print "processing page %d" % page
    next_url, diaries = parse_page(next_url)
    with MySQLdb.connect(host='localhost', db='hatena', user='hatena', passwd='hatena') as cur:
      for d in diaries:
        cur.execute("INSERT INTO diaries(url, bookmarks, subscribers) values('%s', %s, %s)" % (d[1], int(d[2]), int(d[3])))
    if not next_url:
      break
    next_url = 'http://tophatenar.com' + next_url
    page += 1
