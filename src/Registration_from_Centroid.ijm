/*
 * 	
 */



rectHeight = 120;
minArea = 500;
pixelsize = 0.1566487;
interval = 1/15;
blursigma = 2;
x_buffer = 8;
cropThresh = "Triangle";

Reg_Types = newArray("Centroid","TrackMate","MultiStackReg","None","Unclear");

run("Close All");
print("\\Clear");

//selectImage(1);
//close("\\Others");



// define file locations, etc.
//basedir = getDirectory("Choose a Directory");
basedir = "D:\\LMCB\\ChannelMigration\\Raw"+File.separator;
dlist = getFileList(basedir);
out = "C:\\Users\\dani\\Documents\\MyCodes\\ChannelMigration_Speeds\\output\\Centroid_Registration"+File.separator;
headers = newArray("index","exp#","folder","file","y","dir","reg_type","centr_speed","TM_speed","MSR_speed_approx","points","TM_Reg","centr_Reg");
concatPrint(headers,"\t");
TrackMateRegistrationFolder = "C:\\Users\\dani\\Documents\\MyCodes\\ChannelMigration_Speeds\\output\\200502190132_ChannelMigration"+File.separator;
//MSR_Folder = "D:\\LMCB\\ChannelMigration\\_MultiStackReg_Exp1-12" + File.separator;
MSR_speeds_base = "D:\\LMCB\\ChannelMigration\\Lokesh_Dani" + File.separator;

input_txt = "C:/Users/dani/Documents/MyCodes/ChannelMigration_Speeds/resources/200502190132_ChannelMigration_TM_Data.txt";
data_string = File.openAsString(input_txt);
lines = split(data_string,"\n");


// run through data list to find which cells to use
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

	// find correct image file
	folder = dlist[cell_data[1]-1];
	path = basedir + File.separator + folder + File.separator;
	if (File.exists(path + cell_data [2] + ".timecrop.tif"))	image_path = path + cell_data [2] + ".timecrop.tif";
	else														image_path = path + cell_data [2] + ".nd2";

	savename = cell_data[1] + "_" + cell_data[2] + ".tif";
	open(image_path);
	ori = getTitle();
	if (cell_data [4] == "left")	run("Flip Horizontally", "stack");
	run("Select None");

	// Register based on Centroids
	run("Duplicate...", "duplicate channels=2");
	Ch2 = getTitle();
	Stack.setXUnit("px");
	run("Properties...", "pixel_width=1 pixel_height=1");
	run("Grays");
	RegData = findCentroids();

	selectImage(ori);
	Register_Movie(cell_data [3], RegData);
	centr_reg = getTitle();
	cropRegImage();
	
	selectImage(ori);
	roiManager("add");
	roiManager("select", roiManager("count")-1);
	roiManager("rename", "Cell_Y full width");
	
	
	// output data
	time = RegData.length - 1;
	px_speed = RegData[time] / time;
	realspeed = px_speed * pixelsize / interval;
		
	
	// display centroid image + kymograph
	centr_reg = displayRegType(centr_reg,"Centroid",2);

	// display TrackMate registration + kymograph
	open (TrackMateRegistrationFolder + savename);
	roiManager("select", 1);
	run("Crop");
	TM = displayRegType(getTitle(),"TrackMate",2);

	// create MSR from text
	MSR_txt = MSR_speeds_base + folder + "Y_" + cell_data[2] + ".nd2.txt";
	MSR_string = File.openAsString(MSR_txt);
	MSR_data = split(MSR_string,"\n");

	if (MSR_data[0] != "0"){
		waitForUser(ori+"\n MSR doesn't start at 0")
	}
	MSR_data[0] = 0;
	for (l = 1; l < MSR_data.length; l++) {
		if (cell_data [4] == "right")		MSR_data[l] = parseInt(MSR_data[l]) + MSR_data[l-1];
		else 								MSR_data[l] = (-1 * parseInt(MSR_data[l])) + MSR_data[l-1];
	}

	selectImage(ori);
	Register_Movie(cell_data [3], MSR_data);

	roiManager("select", 1);
	MSR_speed = MSR_data[MSR_data.length-1]/(MSR_data.length-1);
	MSR_speed = MSR_speed * pixelsize / interval;
	run("Crop");
	MSR_im = displayRegType(getTitle(),"MSR",2);

	// display and wait for user to determine best registration
	close(ori);
	close(Ch2);
	run("Tile");
	displayAll(3);
	Dialog.createNonBlocking(ori);
		Dialog.addMessage("Centroid speed:  " + d2s(realspeed,2));
		Dialog.addMessage("TrackMate speed: " + d2s(cell_data[6],2));
		Dialog.addMessage("MSR speed: " + d2s(MSR_speed,2));
		
		Dialog.addChoice("Which registration works better?", Reg_Types, "Centroid");
		Dialog.addString("Comments: ", "");
		Dialog.setLocation(400,300); 
		Dialog.show();
	use_reg = Dialog.getChoice();

	selectImage(id)

	outdata = newArray(c,cell_data[1], folder, cell_data [2],cell_data[3], cell_data [4], use_reg, realspeed, cell_data [6], MSR_speed, time+1, cell_data[5]);	
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


function makeKymo(channel){
	run("Duplicate...", "duplicate channels="+channel);
	temp = getTitle();
	makeLine(0, getHeight()/2, getWidth(), getHeight()/2);
	run("Multi Kymograph", "linewidth=1");
	close(temp);
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
	roiManager("rename", "Wide cell outline");
}


function Register_Movie(Y,Reg_positions){
	// duplicate rectangle at cell height
	makeRectangle(0, Y-rectHeight/2, getWidth(), rectHeight);
	run("Duplicate...", "duplicate channels=1-2");
	dupl = getTitle();
	Stack.setXUnit("px");
	run("Properties...", "pixel_width=1 pixel_height=1");
	Stack.getDimensions(_, _, nChannels, _, _);

	// Make Register 
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
	roiManager("select", roiManager("count")-1);
	roiManager("rename", "Bounding box");
	run("Crop");
	close(blurmax);
	close(ch2_reg);
}

function displayRegType(image_id,reg_type,channel){
	selectImage(image_id);
	getMinAndMax(min, max);
	rename(reg_type);
	
	makeKymo(channel);
	rename(reg_type + "_Kymo");
	
	selectImage(reg_type);
	setSlice(channel);
	roiManager("Show None");
	setMinAndMax(min*10, max*0.8);
	run("Grid...","Grid=Lines Area=1000 Color=Magenta Center");
	doCommand("Start Animation [\\]");

	return getTitle();
}


function displayAll(nTypes){
	h_buffer = 12;
	w_buffer = 6;
	selectImage(1);
	getMinAndMax(min, max);
	new_h = (getHeight() + h_buffer) * nTypes;
	new_w = getWidth() * 2 + w_buffer;
	Stack.getDimensions(width, height, channels, slices, frames)

	newImage("Movie", "16-bit black", new_w, new_h, frames);
	new = getTitle();

	for (i = 0; i < frames; i++) {
		for (j = 0; j < nTypes; j++) {
			// copy/paste movie frame
			selectImage(j*2+1);		// selects correct movie
			Stack.setFrame(i+1);			// selects correct frame
			run("Copy");

			selectImage(new);
			setSlice(i+1);
			makeRectangle (0, (h_buffer+height)*j + h_buffer, width, height);
			run("Paste");

			// copy/paste kymo
			selectImage(j*2+2);		// selects correct kymo
			run("Copy");
			
			selectImage(new);
			makeRectangle(width+w_buffer, (h_buffer+height)*j + h_buffer + (height-frames)/2, width, frames);
			run("Paste");

			 drawString(Reg_Types[j], w_buffer, (h_buffer+height)*j + h_buffer);
		}
	}

	// nice display
	run("Select None");
	run("Grid...","Grid=Lines Area=1000 Color=Magenta Center");
	setMinAndMax(min*10, max*0.8);
	doCommand("Start Animation [\\]");
}



