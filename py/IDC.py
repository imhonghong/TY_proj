def read_img(file_path):
	img_in_s=[]
	f=open(file_path,'r')
	img_in_s=f.readlines()
	f.close
	img_in_t=list(map(int, img_in_s))
	return img_in_t
	#input : str
	#output: 1D list

def print_img(img_in):
	print("------------------------------------------------------")
	for i in range(0,64):
		if(img_in[i]>99):
			print(img_in[i], end =" |  ")
		elif((img_in[i]<100)&(img_in[i]>9)):
			print(f" {img_in[i]}", end =" |  ")
		else:
			print(f"  {img_in[i]}", end =" |  ")

		if(i%8 == 7):
			print()
			print("------------------------------------------------------")



def print_op_area(opX,opY,img_in):
    print(img_in[(opY-1)*8+opX-1],",",img_in[(opY-1)*8+opX])
    print(img_in[opY*8+opX-1],",",img_in[opY*8+opX])


img_in_path=r'D:\visual_code\IDC\test_img_01.txt'


img_in=read_img(img_in_path)

cmd=5 #5:avg,6:Mirror X,7:mirrorY
opX=5
opY=2
img_temp=[]
for i in range (0,64):
    img_temp.append(img_in[i])
	
print_op_area(opX,opY,img_temp)


if(cmd==1):
	opY_now=opY
	if(opY_now>1):
		opY=opY-1
if(cmd==2):
	opY_now=opY
	if(opY_now<7):
		opY=opY+1
if(cmd==3):
	opX_now=opX
	if(opX_now>1):
		opX=opX-1
if(cmd==4):
	opX_now=opX
	if(opX_now<7):
		opX=opX+1
if(cmd==5):
	img_temp[(opY-1)*8+opX-1]=img_temp[(opY-1)*8+opX]=img_temp[opY*8+opX-1]=img_temp[opY*8+opX]=int((img_temp[(opY-1)*8+opX-1]+img_temp[(opY-1)*8+opX]+img_temp[opY*8+opX-1]+img_temp[opY*8+opX])/4)
if(cmd==6):
    img_temp[(opY-1)*8+opX-1], img_temp[(opY-1)*8+opX] = img_temp[(opY-1)*8+opX], img_temp[(opY-1)*8+opX-1]
    img_temp[opY*8+opX-1], img_temp[opY*8+opX] = img_temp[opY*8+opX], img_temp[opY*8+opX-1]
if(cmd==7):
	img_temp[(opY-1)*8+opX-1],img_temp[opY*8+opX-1]=img_temp[opY*8+opX-1],img_temp[(opY-1)*8+opX-1]
	img_temp[(opY-1)*8+opX],img_temp[opY*8+opX]=img_temp[opY*8+opX],img_temp[(opY-1)*8+opX]
	
print("X,Y: ",opX,opY)
print_op_area(opX,opY,img_temp)
print_img(img_temp)


f=open(img_in_path,'w')
for i in range(0,64):
    print(img_temp[i],file=f)
f.close()
