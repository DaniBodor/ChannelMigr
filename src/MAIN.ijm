/*TO DO:
 * output data to correct folders
 * save general log (MyWindow) after each file
 * rename MyWindow log window
 * create python code to collect CSV data
 * create and annotate parameters to choose which channels to analyze and which folder (number) to start at
 * fix channel naming
 * make 2Xloop rather than copy/paste the patch/cell stuff 
 */


// patch part not used
patch_radius	= 2.5;	// pixels. note that in manual trackmate settings it asks for diameter rather than radius
patch_thresh	= 500;
patch_linkdist	= 6;

cell_radius		= 100;	// pixels. note that in manual trackmate settings it asks for diameter rather than radius
cell_thresh		= 0.5;
cell_linkdist	= 15;

analysis_channels = newArray(2);


basedir = getDirectory("");
subdir = getFileList(basedir);
out = basedir+"TrackMate_Analysis"+File.separator;
File.makeDirectory(out);

py = "C:\\Users\\dani\\Documents\\MyCodes\\ChannelMigration_Speeds\\src\\TrackMate_ChannelMigr.py";
py_as_string = File.openAsString(basedir+py);

macrostart = getTime();

// make sure any open windows, logs, etc are closed/cleared before starting
print ("\\Clear");
run("Close All");
run("Collect Garbage");
statsWindows = newArray("Spots in tracks statistics","Track statistics","Links in tracks statistics","Debug");
for (i = 0; i < statsWindows.length; i++) {
	if(isOpen(statsWindows[i])){
		selectWindow(statsWindows[i]);
		run("Close");
	}
}
if (!isOpen("My Window")){
	run("New... ", "name=[My Window] type=Table");
	waitForUser("organize log windows");
} else{
	print("[My Window]","\\Clear");
}


// loop through subfolders in basedir and create output folder
for (d=0;d<subdir.length;d++){
	dir = basedir+subdir[d];
//	print(subdir[d]);
	if (File.isDirectory(dir) && !startsWith(subdir[d],"_") && d != out){
	//if (File.isDirectory(dir)){
		list = getFileList(dir);

		// loop through files inside subfolder
		for(i=0;i<list.length;i++){
			print(list[i]);		//this print is kinda dumb because it gets cleared almost immediately
			if (endsWith(list[i],".nd2") && !startsWith(list[i],"_")) {
				// open files
				open(dir+list[i]);
				A=getTitle();
				print("[My Window]", d2s(d+8,0)+"_"+list[i]);

				// print pixel settings
				print("\\Clear");	//this print is kinda dumb
				getPixelSize(unit, pixelWidth, pixelHeight);
				interval = Stack.getFrameInterval();
				print("Pixel size is (" + pixelWidth + " x " + pixelHeight + ") " + unit);
				print("Average time interval is " + interval + "seconds\n");

				run("Properties...", "unit=px pixel_width=1 pixel_height=1");
				
				PRINT_TIME("opening file: "+list[i]);
				
				for (j=0;j<analysis_channels.length;j++){
					anal_channel = analysis_channels[j];
					data = list[i] + " --- Channel " + anal_channel;
					Stack.setChannel(anal_channel);
					Stack.setDisplayMode("grayscale");
					before=getTime();
					
					PRINT_TIME ("run python on: " + data);
					print("\n");
					// the next lines will be called with the python py_as_string to generate the variable from this macro
					if (anal_channel == 1){
						radius_line = "RADIUS = float("+ patch_radius +")\n";
						thresh_line = "THRESHOLD = float("+ patch_thresh +")\n";
						linkdist_line = "LINKING_MAX_DISTANCE = float("+ patch_linkdist +")\n";
					}
					else{
						radius_line = "RADIUS = float("+ cell_radius +")\n";
						thresh_line = "THRESHOLD = float("+ cell_thresh +")\n";
						linkdist_line = "LINKING_MAX_DISTANCE = float("+ cell_linkdist +")\n"	;			
					}
					channel_line = "TARGET_CHANNEL = " + anal_channel + "\n";
					//pydirname = substring(dir,0,lengthOf(dir)-1)+File.separator;
					savename_line = "savename = r'"+out+d2s(d+8,0)+"_"+data+"_TM.xml'\n";		//raw string passed (I hope)
					//print(savename_line);
					//waitForUser('string');

					python_prefix = linkdist_line + thresh_line + radius_line + channel_line + savename_line;
					eval("python",python_prefix + py_as_string);

					repeat_python = j;
					n_repeats = 0;
					new_thresh = cell_thresh;
					been_too_low = 0;
					been_too_high = 0;

					while (repeat_python == 1){
						if (isOpen("Track statistics")){
							selectWindow("Track statistics");
							nTracks = getValue("results.count");
							if (nTracks == 1){
								repeat_python = 0;
							} else if (nTracks >1){
								if(been_too_low>0){
									new_thresh = new_thresh/2;
								}
								else{
									new_thresh = new_thresh*2;
								}
								n_repeats++;
								print("more than one track. threshold =",new_thresh);
								for (q = 0; q < 3; q++) {
									if(isOpen(statsWindows[q])){
										selectWindow(statsWindows[q]);
										run("Close");
									}
								}
							} else if (nTracks == 0){
								n_repeats+=5;
								print("[My Window]", "track duration too short");
							}
						} else{
							new_thresh = new_thresh/2;
							n_repeats++;
							been_too_low = 1;
							print("======== no cell tracks. threshold =",new_thresh);
						}
						
						if (repeat_python == 1){
							if (n_repeats>5) {
								repeat_python = 0;
								print("[My Window]", "TrackMate unsuccesful on channel 2");
								//print("[My Window]", "last attempted threshold is: "+new_thresh);
							} else{
								print("[My Window]", "repeat python ("+n_repeats+") with threshold: "+new_thresh);
								thresh_line = "THRESHOLD = float("+ new_thresh +")\n";
								python_prefix = linkdist_line + thresh_line + radius_line + channel_line + savename_line;
								eval("python",python_prefix + py_as_string);
							}
						}
					}
					
					after=getTime();
					duration = round((after-before)/1000);
					PRINT_TIME ("Trackmate finished ("+duration+" s)");
		
					//save track and spots statistics

					if (isOpen("Spots in tracks statistics")){
						selectWindow("Spots in tracks statistics");
						nSpots = getValue("results.count");
						saveAs("Results", out+d2s(d+8,0)+"_"+data+"_SpotsStats.csv");
						run("Close");
						selectWindow("Track statistics");
						nTracks = getValue("results.count");
						//saveAs("Results", out+data+"TrackStats.csv");		//for some reason this window comes out empty...
						run("Close");
						selectWindow("Links in tracks statistics");
						nLinks = getValue("results.count");
						run("Close");
						print("Tracks:",nTracks,"\nLinks:",nLinks,"\nSpots in tracks:",nSpots);
					} else if (j==0){
						print("========================\n========================\nno tracks were found\n========================\n========================");
						print("[My Window]", "no patch-tracks were detected");
					}
				}
				
				selectWindow("Log");
				saveAs("Text", out+d2s(d+8, 0)+"_"+list[i]+"_Log.txt");
				close();
				print("[My Window]", IJ.freeMemory());
				for (q = 0; q < 10; q++) {
					run("Collect Garbage");
				}
				print("[My Window]", IJ.freeMemory());
			}
		}
	}
}


PRINT_TIME("finished");
macrofinish = getTime();
duration = round((macrofinish-macrostart)/1000);
print("\n############\nMACRO IS FINISHED!\ntotal duration: "+duration+" seconds\n############\n");





function PRINT_TIME(string){
	getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
	current_date = "" + year-2000 + IJ.pad(month+1,2) + IJ.pad(dayOfMonth,2);
	
	hour = IJ.pad(hour,2);
	min = IJ.pad(minute,2);
	sec = IJ.pad(second,2);
	curr_time = hour+":"+min+":"+sec;
	print(current_date,curr_time,"-",string);
}
