
rectHeight = 120;

input_csv = "C:/Users/dani/Documents/MyCodes/ChannelMigration_Speeds/resources/200502190132_ChannelMigration_Reg_Data.csv";
input_txt = "C:/Users/dani/Documents/MyCodes/ChannelMigration_Speeds/resources/200502190132_ChannelMigration_Reg_Data.txt";
data_string = File.openAsString(input_txt);
lines = split(data_string,"\n");

//print(lines[1]);

basedir = getDirectory("Choose a Directory");
dlist = getFileList(basedir);

for (c = 1; c < lines.length; c++) {
//for (c = 3; c < 4; c++) {
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

/*	print(dlist[9]);
	print(path);
	print(cell_data [2]);
	print(image_path);
	fjkgsd
*/
	RegData = split(substring(cell_data[5],2,lengthOf(cell_data[5])-2),", ");
	savename = cell_data[1] + "_" + cell_data[2] + ".tif";
	
	open(image_path);
	Register_Movie(cell_data [3], RegData);

	if (cell_data [4] == "left")	run("Flip Horizontally", "stack");

	saveAs("Tiff", "C:/Users/dani/Documents/MyCodes/ChannelMigration_Speeds/output/200502190132_ChannelMigration/" + savename);
	run("Close All");
}




function Register_Movie(Ymean,Reg_positions){
	makeRectangle(0, Ymean-rectHeight/2, getWidth(), rectHeight);
	run("Duplicate...", "duplicate channels=1-2");
	dupl = getTitle();
	Stack.setXUnit("px");
	run("Properties...", "pixel_width=1 pixel_height=1");
	
	for (i = 0; i < Reg_positions.length; i++) {
		displace = parseInt(Reg_positions[i]);
		Stack.setFrame(i+1);
		Stack.setChannel(1);
		run("Translate...", "x="+displace*-1+" y=0 interpolation=None slice");
		Stack.setChannel(2);
		run("Translate...", "x="+displace*-1+" y=0 interpolation=None slice");
	
	}
}	
