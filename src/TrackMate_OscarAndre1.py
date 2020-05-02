
import os
#from os import path

#from java.lang import Long
#from java.lang import String
#from java.lang.Long import longValue
#from java.util import ArrayList
#from jarray import array
#from java.lang.reflect import Array
#import java
#import csv
from ij import IJ


# TrackMate Dependencies
from fiji.plugin.trackmate import Model
from fiji.plugin.trackmate import Settings
from fiji.plugin.trackmate import TrackMate
from fiji.plugin.trackmate import SelectionModel
from fiji.plugin.trackmate import Logger
from fiji.plugin.trackmate.detection import LogDetectorFactory
from fiji.plugin.trackmate.tracking.sparselap import SparseLAPTrackerFactory
from fiji.plugin.trackmate.tracking import LAPUtils
import fiji.plugin.trackmate.visualization.hyperstack.HyperStackDisplayer as HyperStackDisplayer
import fiji.plugin.trackmate.features.FeatureFilter as FeatureFilter
import sys
import fiji.plugin.trackmate.features.track.TrackDurationAnalyzer as TrackDurationAnalyzer

#from fiji.plugin.trackmate.tracking.kdtree import NearestNeighborTrackerFactory
import fiji.plugin.trackmate.features.TrackFeatureCalculator as TrackFeatureCalculator
import fiji.plugin.trackmate.action.ExportStatsToIJAction as ExportStatsToIJAction
#import fiji.plugin.trackmate.action.ExportAllSpotsStatsAction as ExportAllSpotsStatsAction
#import fiji.plugin.trackmate.action.TrackBranchAnalysis as TrackBranchAnalysis

#from java.io import File
#from fiji.plugin.trackmate.io import TmXmlWriter



#-------- Trackmate----------

#----------------------------
# Create the model object now
#----------------------------
    
# Some of the parameters we configure below need to have
# a reference to the model at creation. So we create an
# empty model now.

    
model = Model()
IJ.log (str(dir(model.logger)))
#------------------------
# Prepare settings object
#------------------------
       
settings = Settings()

# Set logger
model.setLogger(Logger.IJ_LOGGER)
       
# Configure detector - We use the Strings for the keys
settings.detectorFactory = LogDetectorFactory()
settings.detectorSettings = { 
    'DO_SUBPIXEL_LOCALIZATION' : True,
    'RADIUS' : 17.5,
    'TARGET_CHANNEL' : 2,
    'THRESHOLD' : 0.1,
    'DO_MEDIAN_FILTERING' : False,
}  
    
# Configure spot filters - Classical filter on quality
filter1 = FeatureFilter('QUALITY', 0.1, True)
settings.addSpotFilter(filter1)
     
# Configure tracker - We want to allow merges and fusions
settings.trackerFactory = SparseLAPTrackerFactory()
settings.trackerSettings = LAPUtils.getDefaultLAPSettingsMap()
settings.trackerSettings['ALLOW_TRACK_SPLITTING'] = False
settings.trackerSettings['ALLOW_TRACK_MERGING'] = False
settings.trackerSettings['LINKING_MAX_DISTANCE'] = 15.0
settings.trackerSettings['GAP_CLOSING_MAX_DISTANCE'] = 15.0
settings.trackerSettings['MAX_FRAME_GAP'] = 0


#settings.trackerFactory = NearestNeighborTrackerFactory()
#settings.trackerSettings = settings.trackerFactory.getDefaultSettings();
#settings.trackerSettings['LINKING_MAX_DISTANCE'] = 30.0
IJ.log (str(settings.trackerSettings))
    
# Configure track analyzers - Later on we want to filter out tracks 
# based on their displacement, so we need to state that we want 
# track displacement to be calculated. By default, out of the GUI, 
# not features are calculated. 
    
# The displacement feature is provided by the TrackDurationAnalyzer.
    
settings.addTrackAnalyzer(TrackDurationAnalyzer())
    
# Configure track filters - We want to get rid of the two immobile spots at 
# the bottom right of the image. Track displacement must be above 10 pixels.
    
#filter2 = FeatureFilter('TRACK_DISPLACEMENT', 10, True)
#settings.addTrackFilter(filter2)

# Configure track filter for cells to remove short duplicate tracks
settings.addTrackAnalyzer(TrackDurationAnalyzer())
filter2 = FeatureFilter('TRACK_DURATION', 99.99, True)
settings.addTrackFilter(filter2)

    
# Send all messages to ImageJ log window.
model.setLogger(Logger.IJ_LOGGER)

inputfolder = 'D:/LMCB/TrackMateTester/'
outputfolder = inputfolder + 'output/'



for folders in os.listdir(inputfolder):
    
    # Specific for mac computers, leave this (wont hurt on PC)
    if not folders.endswith('.DS_Store'):

        # If outputfolder does not exist, create it
        if not os.path.isdir(outputfolder + folders):
            os.makedirs(outputfolder + folders)

        # For all files(images) in folder

        for files in os.listdir(inputfolder + folders):
            imp = IJ.openImage(inputfolder + folders + '/' + files)

            ##
            #imp.show()
            
            #Save resultant image using Bio-Formats
            imp = IJ.getImage();

            # Trackmate
            settings.setFrom(imp)
            trackmate = TrackMate(model, settings)

	        #--------
	        # Process
	        #--------

            ok = trackmate.checkInput()
            print (ok)
            IJ.log(str(ok)+" - trackmate.checkInput")
            if not ok:
            	IJ.log (str(trackmate.getErrorMessage()))
                sys.exit(str(trackmate.getErrorMessage()))#

            ok = trackmate.process()
            IJ.log(str(ok)+" - trackmate.process")
            print (ok)
    
            if not ok:
                IJ.log (str(trackmate.getErrorMessage()))
                sys.exit(str(trackmate.getErrorMessage()))

            model.getLogger().log('Found ' + str(model.getTrackModel().nTracks(True)) + ' tracks.')
            selectionModel = SelectionModel(model)
            displayer = HyperStackDisplayer(model, selectionModel, imp)
            displayer.render()
            displayer.refresh()

    
            # The feature model, that stores edge and track features
            fm = model.getFeatureModel()

            model.getLogger().log(str(model))
    

            TrackFeatureCalculator(model,settings).process()
            ExportStatsToIJAction().execute(trackmate)
            IJ.selectWindow('Track statistics');
            IJ.saveAs('Results', outputfolder + folders + '/Track statistics_' + str(files) + '.csv');
            IJ.selectWindow('Spots in tracks statistics');
            IJ.saveAs('Results', outputfolder + folders + '/Spots in tracks statistics_' + str(files) + '.csv');

        

print("Done")
#success = uploadImage(str2d, gateway)
#gateway.disconnect()	
quit()