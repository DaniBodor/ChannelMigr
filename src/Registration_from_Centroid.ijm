
rectHeight = 120;
minArea = 500;

selectImage(1);
close("\\Others");
run("Select None");



ori = getTitle();

run("Duplicate...", "duplicate channels=2");
Ch2 = getTitle();
Stack.setXUnit("px");
run("Properties...", "pixel_width=1 pixel_height=1");
run("Grays");


run("Duplicate...", "duplicate");
blur = getTitle();
run("Gaussian Blur...", "sigma=2 stack");


Xpos = newArray(nSlices);
Ypos = newArray(nSlices);

for (i = 0; i < nSlices; i++) {	
	setSlice(i+1);
	run("Select None");
	setAutoThreshold("Default dark");
	
	combineROIs();
	roiManager("select", 0);
	
	if (i == 0)	X0 = getValue("X");
	Xpos[i] = getValue("X")-X0;
	Ypos[i] = getValue("Y");
}

Array.getStatistics(Ypos, _, _, Ymean, _);

selectImage(Ch2);
Register_Movie(Ymean,Xpos);

makeLine(0, getHeight()/2, getWidth(), getHeight()/2);
run("Multi Kymograph", "linewidth=1");
kym = getTitle();


function combineROIs(){
	run("Analyze Particles...", "size="+minArea+"-Infinity clear add slice");
		
	if (roiManager("count") > 1){
		roiManager("Combine");
		roiManager("Add");
		
		while (roiManager("count") > 1){
			roiManager("select", 0);
			roiManager("delete");
		}
	}
}


function Register_Movie(Y,Reg_positions){
	makeRectangle(0, Y-rectHeight/2, getWidth(), rectHeight);
	run("Duplicate...", "duplicate channels=1-2");
	dupl = getTitle();
	Stack.setXUnit("px");
	run("Properties...", "pixel_width=1 pixel_height=1");
	
	for (i = 0; i < Reg_positions.length; i++) {
		displace = parseInt(Reg_positions[i]);
		Stack.setFrame(i+1);
		Stack.setChannel(1);
		run("Translate...", "x="+displace*-1+" y=0 interpolation=None slice");
		//Stack.setChannel(2);
		//run("Translate...", "x="+displace*-1+" y=0 interpolation=None slice");
	
	}
}	
