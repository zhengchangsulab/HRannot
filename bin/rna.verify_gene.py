#!/usr/bin/env python
import re,sys
shortest=sys.argv[1]
fp=open("rna_uniq_cds.fa",'r')
for i in fp:
    i=re.sub('\n','',i)
    if re.match('>',i):
        name=i[1:]
    else:
        string=i
        while re.search('ATG',string):
            a=re.search('ATG',string)
            a1=a.end()
            a2=a.start()
            for i in range(a1,len(string),3):
                s=string[i:i+3]
                if s=='TAG' or s=='TAA' or s=='TGA':
                    if len(string[a2:i+3])>=int(shortest):
                        print('>'+name+'-'+str(len(string[a2:i+3])))
                        print(string[a2:i+3])
                    break
            string=string[a1:]
fp.close()
