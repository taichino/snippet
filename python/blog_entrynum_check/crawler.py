#!/usr/bin/python
# -*- coding: utf-8 -*-

import sys
import urllib
import pymysql
from python_prefork import PythonPrefork
from BeautifulSoup import BeautifulSoup

def main():
  pp = PythonPrefork()
  while not pp.signal_received:
    if pp.start(): continue
    run()
    pp.finish()
  pp.wait_all_children()

def run():
  con = pymysql.connect(host='localhost', db='hatena', user='hatena', passwd='hatena')
  cur = con.cursor()
  cur.execute("SELECT queue_wait('crawler_queue:fail_cnt<3')")
  if cur.execute("SELECT id, fail_cnt FROM crawler_queue"):
    try:
      (id, fail_cnt) = cur.fetchone()
      cur.execute("SELECT id, url FROM diaries WHERE id = %s", (id,))
      (id, url) = cur.fetchone()
      print "processing %s" % url
      (entry_num) = parse_dairy(url)
      cur.execute("UPDATE diaries SET entry_num = %s WHERE id = %s", (entry_num,id))
      con.commit()
    except:
      print sys.exc_info()
      cur.execute("INSERT INTO crawler_queue(id, fail_cnt) VALUES(%s, %s)", (id, fail_cnt+1))
  cur.execute("SELECT queue_end()")

def parse_dairy(url):
  url += 'about'
  soup = BeautifulSoup(urllib.urlopen(url).read())
  section = soup.find("div", attrs={"class":"section"})
  return section.find("ul").find("li").find("strong").decodeContents()

if __name__ == '__main__':
  main()
