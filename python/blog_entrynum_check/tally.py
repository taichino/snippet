#!/usr/bin/python
# -*- coding: utf-8 -*-

from __future__ import with_statement

import sys
import MySQLdb

def main(order):
  pagesize = 1000
  with MySQLdb.connect(db='hatena', user='hatena', passwd='hatena') as cur:
    cur.execute("SELECT entry_num, %s FROM diaries WHERE entry_num > 0 AND %s > 0 ORDER BY %s DESC" % (order, order, order))
    diaries = cur.fetchall()
    pages = len(diaries) / pagesize + (1 if len(diaries) % pagesize else 0)
    for i in range(pages):
      targets = diaries[i*pagesize:(i+1)*pagesize]
      total = sum([d[0] for d in targets])
      avg   = float(total)/len(targets)
      print "%d - %d, %s" % (i*pagesize + 1, (i+1)*pagesize, avg)

if __name__ == '__main__':
  main(sys.argv[1])
