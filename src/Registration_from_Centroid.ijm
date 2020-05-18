
rectHeight = 120;
minArea = 500;
pixelsize = 0.1566487;
interval = 1/15;


//selectImage(1);
//close("\\Others");
basedir = getDirectory("Choose a Directory");
dlist = getFileList(basedir);
out = "C:\\Users\\dani\\Documents\\MyCodes\\ChannelMigration_Speeds\\output\\Centroid_Registration"+File.separator;
run("Close All");
print("\\Clear");
headers = newArray("index","exp#","folder","file","y","dir","speed","points","RegData");
concatPrint(headers,"\t");

input_txt = "C:/Users/dani/Documents/MyCodes/ChannelMigration_Speeds/resources/200502190132_ChannelMigration_Reg_Data.txt";
data_string = File.openAsString(input_txt);
lines = split(data_string,"\n");


for (c = 1; c < lines.length; c++) {
//for (c = 3; c < 4; c++) {		// for testing purposes
	cell_data = split(lines[c],"\t");
	//cell_data [0] : dataframe index
	//cell_data [1] : exp#
	//cell_data [2] : cell name
	//cell_data [3] : Y_mean
	//cell_data [4] : direction
	//cell_data [5] : TrackMate registration data (not used!)

	//print(c,cell_data[1], cell_data [2]);

	folder = dlist[cell_data[1]-1];
	path = basedir + File.separator + folder + File.separator;
	if (File.exists(path + cell_data [2] + ".timecrop.tif"))	image_path = path + cell_data [2] + ".timecrop.tif";
	else														image_path = path + cell_data [2] + ".nd2";

	savename = cell_data[1] + "_" + cell_data[2] + ".tif";
	open(image_path);
	ori = getTitle();
	run("Select None");

	run("Duplicate...", "duplicate channels=2");
	Ch2 = getTitle();
	Stack.setXUnit("px");
	run("Properties...", "pixel_width=1 pixel_height=1");
	run("Grays");
	if (cell_data [4] == "left")	run("Flip Horizontally", "stack");
	RegData = findCentroids();

	selectImage(ori);
	Register_Movie(cell_data [3], RegData);
	reg = getTitle();
	
	time = RegData.length - 1;
	px_speed = RegData[time] / time;
	realspeed = px_speed * pixelsize / interval;
	
	outdata = newArray(c,cell_data[1], cell_data [2],folder,cell_data[3], cell_data [4],realspeed, time+1);
	concatPrint(Array.concat(outdata,RegData),"\t");
	makeKymo(2);

	selectImage(reg);
	saveAs("Tiff", out + savename);
	run("Close All");
}









function findCentroids(){
	Xpos = newArray(nSlices);
	Ypos = newArray(nSlices);
	
	run("Duplicate...", "duplicate");
	blur = getTitle();
	run("Gaussian Blur...", "sigma=2 stack");
	
	for (i = 0; i < nSlices; i++) {	
		setSlice(i+1);
		run("Select None");
		setAutoThreshold("Default dark");
		
		combineROIs();
		roiManager("select", 0);
		
		if (i == 0)		X0 = getValue("X");
		Xpos[i] = getValue("X")-X0;
		Ypos[i] = getValue("Y");
	}
	
	Array.getStatistics(Ypos, _, _, Ymean, _);

	output = Array.concat(Ymean,Xpos);	//currently unused, reading Ymean from trackmate
	return Xpos;
}


function makeKymo(channel){
	Stack.setChannel(channel);
	run("Duplicate...", "duplicate channels="+channel);
	temp = getTitle();
	makeLine(0, getHeight()/2, getWidth(), getHeight()/2);
	run("Multi Kymograph", "linewidth=1");
	close(temp);
	waitForUser("Kymo OK?");
}

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
	Stack.getDimensions(_, _, nChannels, _, _);
	
	for (t = 0; t < Reg_positions.length; t++) {
		displace = -1 * parseInt(Reg_positions[t]);
		Stack.setFrame(t+1);

		for (w = 0; w < nChannels; w++) {
			Stack.setChannel(w+1);
			run("Translate...", "x="+displace+" y=0 interpolation=None slice");
		}	
	}
}	

function concatPrint(array,end){
	line = "";
	for (i = 0; i < array.length; i++) {
		line = line + array[i] + end;
	}
	print(line); 
}
