
rectHeight = 120;

input_txt = "C:/Users/dani/Documents/MyCodes/ChannelMigration_Speeds/resources/200502190132_ChannelMigration_Reg_Data.txt";
data_string = File.openAsString(input_txt);
lines = split(data_string,"\n");


basedir = getDirectory("Choose a Directory");
dlist = getFileList(basedir);

for (c = 1; c < lines.length; c++) {
//for (c = 3; c < 4; c++) {		// for testing purposes
	cell_data = split(lines[c],"\t");
	//cell_data [0] : dataframe index
	//cell_data [1] : exp#
	//cell_data [2] : cell name
	//cell_data [3] : Y_mean
	//cell_data [4] : direction
	//cell_data [5] : Registration data (poorly formatted)

	print(c,cell_data[1], cell_data [2]);

	folder = dlist[cell_data[1]-1];
	path = basedir + File.separator + folder + File.separator;
	if (File.exists(path + cell_data [2] + ".timecrop.tif"))	image_path = path + cell_data [2] + ".timecrop.tif";
	else														image_path = path + cell_data [2] + ".nd2";

	RegData = split(substring(cell_data[5],2,lengthOf(cell_data[5])-2),", ");
	savename = cell_data[1] + "_" + cell_data[2] + ".tif";
	
	open(image_path);
	Register_Movie(cell_data [3], RegData);

	if (cell_data [4] == "left")	run("Flip Horizontally", "stack");

	saveAs("Tiff", "C:/Users/dani/Documents/MyCodes/ChannelMigration_Speeds/output/200502190132_ChannelMigration/" + savename);
	run("Close All");
}




function Register_Movie(Y,Reg_positions){
	makeRectangle(0, Y-rectHeight/2, getWidth(), rectHeight);
	run("Duplicate...", "duplicate channels=1-2");
	dupl = getTitle();
	Stack.setXUnit("px");
	run("Properties...", "pixel_width=1 pixel_height=1");
	
	for (t = 0; t < Reg_positions.length; t++) {
		displace = -1 * parseInt(Reg_positions[t]);
		Stack.setFrame(t+1);
		
		for (w = 0; w < nChannels; w++) {
			Stack.setChannel(w+1);
			run("Translate...", "x="+displace+" y=0 interpolation=None slice");
		}	
	}
}	
