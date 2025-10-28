#!/usr/bin/env python
import re,sys
score=sys.argv[1]
fp=open("sorted.best1",'r')
for i in fp:
    i=re.sub('\n','',i)
    j=i.split()
    if float(j[5])>float(score):
        print(i)
fp.close()
