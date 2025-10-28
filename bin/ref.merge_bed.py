#!/usr/bin/env python
import re,sys
files=sys.argv[1]
n=0
fp=open(files,'r')
for i in fp:
    i=re.sub('\n','',i)
    j=i.split()
    if n==0:
        contig=j[0]
        start=int(j[1])
        end=int(j[2])
        n=1
    else:
        if j[0]==contig:
            if int(j[1])<=end:
                if int(j[2])>=end:
                    end=int(j[2])
            else:
                print(contig+'\t'+str(start)+'\t'+str(end))
                start=int(j[1])
                end=int(j[2])
        else:
            print(contig+'\t'+str(start)+'\t'+str(end))
            contig=j[0]
            start=int(j[1])
            end=int(j[2])
print(contig+'\t'+str(start)+'\t'+str(end))
fp.close()

