run("Duplicate...", "duplicate channels=2");
setAutoThreshold("Default dark");
Stack.setXUnit("px");
run("Properties...", "pixel_width=1 pixel_height=1");
run("Analyze Particles...", "size=3500-Infinity pixel clear slice");
Y = getResult("Y", 0)
makeLine(0, Y, getWidth(), Y);
run("Multi Kymograph", "linewidth=1");
run("Set... ", "zoom=400 x=256 y=30");

setTool("line");
pos = newArray("front","rear","nucleus");
speeds = newArray(3);
for(i=0;i<3;i++){
	run("Select None");
	waitForUser("draw line "+pos[i]);
	speed = getSpeed();
	speeds[i] = speed;
}
print(speeds[0] +"\t"+ speeds[1] +"\t"+ speeds[2]);
selectWindow("Log");


function getSpeed(){
	displacement = getValue("Width") * 0.1566487;
	time = getValue("Height") /15;	
	speed = (displacement/time);
	
	if (getValue("Width") < getWidth())	return speed;
	else 							return "X";
	
}
