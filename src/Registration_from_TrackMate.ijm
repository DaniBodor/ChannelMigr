
rectHeight = 120;
Reg_positions = newArray(0, 0, 0, 0, 0, 1, 0, -2, -4, -5, -6, -6, -7, -6, -7, -6, -5, -5, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, 0, 2, 7, 11, 15, 20, 25, 30, 35, 39, 42, 47, 51, 51, 53, 57, 60, 65, 70, 75, 80, 85, 88, 91, 92, 95, 98, 99, 100, 102, 106, 108);
Ymean = 194;

ori = getTitle();


makeRectangle(0, Ymean-rectHeight/2, getWidth(), rectHeight);
run("Duplicate...", "duplicate channels=1-2");
dupl = getTitle();
Stack.setXUnit("px");
run("Properties...", "pixel_width=1 pixel_height=1");

for (i = 0; i < Reg_positions.length; i++) {
	Stack.setFrame(i+1);
	Stack.setChannel(1);
	run("Translate...", "x="+Reg_positions[i]*-1+" y=0 interpolation=None slice");
	Stack.setChannel(2);
	run("Translate...", "x="+Reg_positions[i]*-1+" y=0 interpolation=None slice");

}

