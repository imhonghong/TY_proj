#using python to solve first??

def read_img(file_path):
	img_in=[]
	f=open(file_path,'r')
	img_in=f.readlines()
	f.close
	return img_in
	#input : str
	#output: 1D list

def print_img(img_in):
	for i in range(0,64):
		if(img_in[i]>99):
			print(img_in[i])
		elif((img_in[i]<99)&&(img_in[i]>9)):
			print(f" {img_in[i]}")
		else:
			print(f"  {img_in[i]}")
		if( i%8==0 && i!=0 ):
			print(\n)

img_in_path=r'py/img1.txt'
img_in=read_img(img_in_path)
print_img(img_in)
