import random
path=r"TY_proj/py/rand_img_01.txt"
f=open(path,'w')
for i in range(0,64):
	print(random.randint(0,255),file=f)
f.close()
