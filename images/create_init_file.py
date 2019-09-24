from PIL import Image, ImageDraw

#open the image to be pixelated
image_file = "gradient.png"
img = Image.open(image_file)
img_width = img.size[0]
img_height = img.size[1]
#print("opened %s [%d x %d]" % (image_file,img_width,img_height))

rgb_img = img.convert('RGB')

#split the image into squares
for x in range(0,img_width):
    r, g, b = rgb_img.getpixel((x, 0))
    print("%2x%2x%2x" % (r,g,b))




