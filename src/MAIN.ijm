current_dir = "C:\\Users\\dani\\Documents\\MyCodes\\ChannelMigration_Speeds"+File.separator;	// directory where the code is stored (above '/src')
start_index = 16;	// folder number to start with
anal_channel = 2;	// which channels to analyze

// TrackMate parameters passed to Python 
cell_radius		= 100;	// pixels. note that in manual trackmate settings it asks for diameter rather than radius
cell_thresh		= 0.25;
cell_linkdist	= 15;




///////////////////////////////////////////////////////////////////////////////////////////////////
// used for CURR_TIME function
P="P";
R="R";

data_basedir = getDirectory("");
dirname = File.getName(data_basedir)
subdir = getFileList(data_basedir);

out = current_dir + "output" + File.separator + CURR_TIME("",R)+"_"+dirname+File.separator;
File.makeDirectory(out);

// currently saving everything to single out folder
/*
//xml_out = out + "XMLs" + File.separator;
//File.makeDirectory(xml_out);
csv_out = out + "CSVs" + File.separator;
File.makeDirectory(csv_out);
log_out = out + "LOGs" + File.separator;
File.makeDirectory(log_out);
*/

py_src = current_dir + "src\\TrackMate_ChannelMigr.py";
py_as_string = File.openAsString(py_src);

macrostart = getTime();
start_time = CURR_TIME("",R);

progress_log = "[_Progress_Log.txt]";

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

progress_log_short=substring(progress_log, 1, lengthOf(progress_log)-1);
if (!isOpen(progress_log_short)){
	run("New... ", "name="+progress_log+" type=Table");
	waitForUser("organize log windows");
} else{
	print(progress_log,"\\Clear");
}


// loop through subfolders in data_basedir and create output folder
for (d=start_index-1; d<subdir.length; d++){
	dir = data_basedir+subdir[d];
	if (File.isDirectory(dir) && !startsWith(subdir[d],"_")){
		list = getFileList(dir);

		// loop through files inside subfolder
		for(i=0;i<list.length;i++){
			if (endsWith(list[i],".nd2") && !startsWith(list[i],"_")) {
				// open files
				CURR_TIME("opening file: "+list[i],P);
				open(dir+list[i]);
				A=getTitle();
				run("Properties...", "unit=px pixel_width=1 pixel_height=1");
				print(progress_log, d+1+"_"+list[i]);

				// print pixel settings
				print("\\Clear");
				getPixelSize(unit, pixelWidth, pixelHeight);
				interval = Stack.getFrameInterval();
				print("Pixel size is (" + pixelWidth + " x " + pixelHeight + ") " + unit);
				print("Average time interval is " + interval + "seconds\n");
				
				Stack.setChannel(anal_channel);
				Stack.setDisplayMode("grayscale");
				before=getTime();
				
				CURR_TIME ("run python on: " + list[i],P);
				print("\n");
				// the next lines will be called with the python py_as_string to generate the variable from this macro
				radius_line = "RADIUS = float("+ cell_radius +")\n";
				thresh_line = "THRESHOLD = float("+ cell_thresh +")\n";
				linkdist_line = "LINKING_MAX_DISTANCE = float("+ cell_linkdist +")\n"	;			
				channel_line = "TARGET_CHANNEL = " + anal_channel + "\n";
				//savename_line = "savename = r'"+out+d+1+"_"+list[i]+"_TM.xml'\n";		// not saving XMLs any more
				python_prefix = linkdist_line + thresh_line + radius_line + channel_line;// + savename_line;
				eval("python",python_prefix + py_as_string);

				repeat_python = 1;
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
							print("more than one track. new threshold =",new_thresh);
							for (q = 0; q < 3; q++) {
								if(isOpen(statsWindows[q])){
									selectWindow(statsWindows[q]);
									run("Close");
								}
							}
						} else if (nTracks == 0){
							n_repeats+=5;
							print(progress_log, "track duration too short");
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
							print(progress_log, "TrackMate unsuccesful on" + list[i]);
						} else{
							print(progress_log, "repeat python ("+n_repeats+") with threshold: "+new_thresh);
							thresh_line = "THRESHOLD = float("+ new_thresh +")\n";
							python_prefix = linkdist_line + thresh_line + radius_line + channel_line;// + savename_line;
							eval("python",python_prefix + py_as_string);
						}
					}
				}
				
				after=getTime();
				duration = round((after-before)/1000);
				CURR_TIME ("Trackmate finished ("+duration+" s)",P);
	
				//save spots statistics

				if (isOpen("Spots in tracks statistics")){
					selectWindow("Spots in tracks statistics");
					nSpots = getValue("results.count");
					saveAs("Results", out+d+1+"_"+list[i]+"_SpotsStats.csv");
					run("Close");
					selectWindow("Track statistics");
					nTracks = getValue("results.count");
					// not saving trackstats, because I want only the X-displacement, which isn't listed there
					run("Close");
					selectWindow("Links in tracks statistics");
					nLinks = getValue("results.count");
					run("Close");
					print("Tracks:",nTracks,"\nLinks:",nLinks,"\nSpots in tracks:",nSpots);
				} else {
					print("========================\n========================\nno tracks were found\n========================\n========================");
					print(progress_log, "no tracks were detected");
				}
				
				selectWindow("Log");
				saveAs("Text", out+d+1+"_"+list[i]+"_Log.txt");
				close();
				print(progress_log, IJ.freeMemory());
				for (q = 0; q < 10; q++) {
					run("Collect Garbage");
				}
				print(progress_log, IJ.freeMemory());
				selectWindow(progress_log_short);
				saveAs("Text", out+progress_log_short);
			}
		}
	}
}


CURR_TIME("finished",P);
macrofinish = getTime();
duration = round((macrofinish-macrostart)/1000);
print("\n############\nMACRO IS FINISHED!\ntotal duration: "+duration+" seconds\n############\n");
print(progress_log,"\n############\nMACRO IS FINISHED!\ntotal duration: "+duration+" seconds\n############\n");



function CURR_TIME(string,PrintOrReturn){
	getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
	current_date = "" + year-2000 + IJ.pad(month+1,2) + IJ.pad(dayOfMonth,2);
	
	hour = IJ.pad(hour,2);
	min = IJ.pad(minute,2);
	sec = IJ.pad(second,2);
	curr_time = hour+min+sec;
	if (lengthOf(string) > 0)	return_string = current_date+curr_time+"_"+string;
	else						return_string = current_date+curr_time;
	
	
	if (PrintOrReturn==R) 		return return_string;
	else if (PrintOrReturn==P) 	print (return_string);
}
