#using python to solve first??

def read_img(file_path):
	img_in=[]
	f=open.(file_path,'r')
	img_in=f.readlines()
	f.close
	return img_in
	#input : str
	#output: 1D list

img_in=read_img(r'py/img1.txt')
print(img_in)
