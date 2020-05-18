
rectHeight = 120;
minArea = 500;
pixelsize = 0.1566487;
interval = 1/15;
blursigma = 2;
x_buffer = 8;
cropThresh = "Triangle";

quality_control = 1;
Reg_Types = newArray("Centroid","TrackMate","MultiStackReg","None","Unclear");



//selectImage(1);
//close("\\Others");
basedir = getDirectory("Choose a Directory");
dlist = getFileList(basedir);
out = "C:\\Users\\dani\\Documents\\MyCodes\\ChannelMigration_Speeds\\output\\Centroid_Registration"+File.separator;
run("Close All");
print("\\Clear");
headers = newArray("index","exp#","folder","file","y","dir","reg_type","centr_speed","TM_speed","points","TM_Reg","centr_Reg");
concatPrint(headers,"\t");
TrackMateRegistrationFolder = "C:\\Users\\dani\\Documents\\MyCodes\\ChannelMigration_Speeds\\output\\200502190132_ChannelMigration"+File.separator;
//MSR_Folder = "D:\\LMCB\\ChannelMigration\\_MultiStackReg_Exp1-12" + File.separator;
MSR_speeds_base = "D:\\LMCB\\ChannelMigration\\Lokesh_Dani" + File.separator;

input_txt = "C:/Users/dani/Documents/MyCodes/ChannelMigration_Speeds/resources/200502190132_ChannelMigration_TM_Data.txt";
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
	//cell_data [6] : TM velocity

	//print(c,cell_data[1], cell_data [2]);

	folder = dlist[cell_data[1]-1];
	path = basedir + File.separator + folder + File.separator;
	if (File.exists(path + cell_data [2] + ".timecrop.tif"))	image_path = path + cell_data [2] + ".timecrop.tif";
	else														image_path = path + cell_data [2] + ".nd2";

	savename = cell_data[1] + "_" + cell_data[2] + ".tif";
	open(image_path);
	ori = getTitle();
	if (cell_data [4] == "left")	run("Flip Horizontally", "stack");
	run("Select None");

	run("Duplicate...", "duplicate channels=2");
	Ch2 = getTitle();
	Stack.setXUnit("px");
	run("Properties...", "pixel_width=1 pixel_height=1");
	run("Grays");
	RegData = findCentroids();

	selectImage(ori);
	Register_Movie(cell_data [3], RegData);
	reg = getTitle();
	
	time = RegData.length - 1;
	px_speed = RegData[time] / time;
	realspeed = px_speed * pixelsize / interval;
	

	selectImage(reg);
	cropRegImage();

	
	if (quality_control == 1){
		selectImage(reg);
		rename("Centroid");
		reg=getTitle();
		
		makeKymo();
		rename("Centroid_Kymo");
		
		selectImage(reg);
		//roiManager("select", 1);
		roiManager("Show None");
		run("Grid...","Grid=Lines Area=1000 Color=Magenta Center");
		doCommand("Start Animation [\\]");

		open (TrackMateRegistrationFolder + savename);
		rename("TrackMate");
		roiManager("select", 1);
		run("Crop");
		makeKymo();
		rename("TM_Kymo");
		//roiManager("Show None");
		selectImage("TrackMate");
		run("Grid...","Grid=Lines Area=1000 Color=Magenta Center");
		doCommand("Start Animation [\\]");

		MSR_txt = MSR_speeds_base + folder + "Y_" + cell_data[2] + ".nd2.txt";
		print(MSR_txt);
		MSR_string = File.openAsString(MSR_txt);
		MSR_data = split(MSR_string,"\n");
		selectImage(Ch2);
		run("Select None");
		run("Duplicate...", "title=MSR duplicate");
		for (q = 0; q < MSR_data.length; q++) {
			setSlice(q+1);
			print(MSR_data[q]);
			print(MSR_data[q]+3);
			print(abs(parseInt(MSR_data[q]))+3);
			waitForUser("fdsfsdf");
			run("Translate...", "x="+abs(parseInt(MSR_data[q]))+" y=0 interpolation=None slice");
		}
waitForUser(2);
		roiManager("select", 1);
		getBoundingRect(x, y, width, height);
		makeRectangle(x, cell_data[3]-RectHeight/2, width, RectHeight)
		run("Crop");
		makeKymo();
		rename("MSR_Kymo");
		selectImage("MSR");
		run("Grid...","Grid=Lines Area=1000 Color=Magenta Center");
		doCommand("Start Animation [\\]");

		close(ori);
		close(Ch2);
		run("Tile");
//		selectImage(nImages);
//		run("Set... ", "zoom=100");
		Dialog.createNonBlocking(ori);
			Dialog.addMessage("Centroid speed:  " + d2s(realspeed,2));
			Dialog.addMessage("TrackMate speed: " + d2s(cell_data[6],2));
			Dialog.addChoice("Which registration works better?", Reg_Types, "Centroid");
			Dialog.addString("Comments: ", "");
			Dialog.setLocation(200,300); 
			Dialog.show();
		use_reg = Dialog.getChoice();
//		waitForUser("All OK?");
	}

	outdata = newArray(c,cell_data[1], folder, cell_data [2],cell_data[3], cell_data [4], use_reg, realspeed, cell_data [6], time+1, cell_data[5]);	
	concatPrint(Array.concat(outdata,RegData),"\t");

	run("Close All");
}









function findCentroids(){
	Xpos = newArray(nSlices);
	Ypos = newArray(nSlices);
	
	run("Duplicate...", "duplicate");
	blur = getTitle();
	run("Gaussian Blur...", "sigma="+blursigma+" stack");
	
	for (i = 0; i < nSlices; i++) {	
		setSlice(i+1);
		run("Select None");
		setAutoThreshold("Default dark");
		
		combineROIs();
		
		if (i == 0)		X0 = getValue("X");
		Xpos[i] = getValue("X")-X0;
		Ypos[i] = getValue("Y");
	}
	
	Array.getStatistics(Ypos, _, _, Ymean, _);

	output = Array.concat(Ymean,Xpos);	//currently unused, reading Ymean from trackmate
	close(blur);
	return Xpos;
}


function makeKymo(){
	run("Duplicate...", "duplicate channels="+2);
	Ch2_reg = getTitle();
	makeLine(0, getHeight()/2, getWidth(), getHeight()/2);
	run("Multi Kymograph", "linewidth=1");
	close(Ch2_reg);
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
	roiManager("select", 0);
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


function cropRegImage(){
	image = getTitle();
	
	run("Duplicate...", "duplicate channels="+2);
	ch2_reg = getTitle();
	run("Z Project...", "projection=[Max Intensity]");
	blurmax = getTitle();
	run("Gaussian Blur...", "sigma="+blursigma+" stack");
	setAutoThreshold(cropThresh + " dark");
	combineROIs();
	getBoundingRect(x, y, width, height);
	selectImage(image);
	makeRectangle  (x-x_buffer, 0, width+x_buffer*2, getHeight());
	roiManager("add");
	run("Crop");
	close(blurmax);
	close(ch2_reg);
}
