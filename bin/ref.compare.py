#!/usr/bin/env python
import re,sys
prefix=sys.argv[1]
overlap=sys.argv[2]
identity=sys.argv[3]

ll=prefix.split(',')
h={}
for a in ll:
    n=0
    iden=0
    fp=open('best1_'+a,'r')
    for i in fp:
        i=re.sub('\n','',i)
        j=i.split()
        n+=1
        iden+=float(j[5])
    fp.close()
    h[a]=iden/n
fp.close()

sorted_items=sorted(h.items(),key=lambda item:item[1],reverse=True)
sorted_h=dict(sorted_items)
fp1=open('species.sort.txt','w')
for i in sorted_h.keys():
    fp1.write(i+'\t'+str(sorted_h[i])+'\n')
fp1.close()

current=[]
n=0
for ii in sorted_h.keys():
    fp=open('sorted_best1_'+ii,'r')
    for i in fp:
        i=re.sub('\n','',i)
        j=i.split()
        if n==0:
            current.append(i)
        else:
            label=0
            current_list=[]
            gene_list=[]
            for a in current:
                b=a.split()
                current_list.append([b[1],b[2],b[3],b[4]])
                gene_list.append(b[6])
            for a in current:
                b=a.split()
                if j[1]==b[1] and j[4]==b[4]:
                    if int(j[2])>=int(b[2]) and int(j[2])<=int(b[3]):
                        length=max(int(b[3])-int(b[2]),int(j[3])-int(j[2]))*float(overlap)
                        if ((int(j[2])-int(b[2]))>length or (int(b[3])-int(j[2]))>length) and float(j[5])>float(b[5]) and j[6] not in gene_list and [j[1],j[2],j[3],j[4]] not in current_list:
                            label=1
                            removes=a
                            new=i
                            break
                        else:
                            label=2
                            break
                    elif int(j[3])>=int(b[2]) and int(j[3])<=int(b[3]):
                        length=max(int(b[3])-int(b[2]),int(j[3])-int(j[2]))*float(overlap)
                        if ((int(j[3])-int(b[2]))>length or (int(b[3])-int(j[3]))>length) and float(j[5])>float(b[5]) and j[6] not in gene_list and [j[1],j[2],j[3],j[4]] not in current_list:
                            label=1
                            removes=a
                            new=i
                            break
                        else:
                            label=2
                            break
                    else:
                        pass
            if label==1:
                current.remove(removes)
                current.append(new)
            elif label==0:
                if float(j[5])>float(identity) and j[6] not in gene_list:
                    current.append(i)
            else:
                pass
    fp.close()
    n=1

for i in current:
    print(i)
