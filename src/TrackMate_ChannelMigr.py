#### set parameters:
### spot detection
DO_SUBPIXEL_LOCALIZATION = True
#RADIUS = 7.5
#THRESHOLD = 0.25
DO_MEDIAN_FILTERING = False
#TARGET_CHANNEL = 1			### commented out here because given as function in initiating script
### LAP tracker
#LINKING_MAX_DISTANCE = 15.0
#gap closing
ALLOW_GAP_CLOSING = False
GAP_CLOSING_MAX_DISTANCE = 15.0
MAX_FRAME_GAP = 0	
#splitting
ALLOW_TRACK_SPLITTING = False	
SPLITTING_MAX_DISTANCE = 15.0
#merging
ALLOW_TRACK_MERGING = False
MERGING_MAX_DISTANCE = 15.0


import sys
from ij import IJ, ImagePlus, ImageStack, WindowManager
from fiji.plugin.trackmate import Model, Settings, TrackMate, SelectionModel, Logger
from fiji.plugin.trackmate.detection import LogDetectorFactory, DogDetectorFactory
from fiji.plugin.trackmate.tracking.sparselap import SparseLAPTrackerFactory
from fiji.plugin.trackmate.tracking.oldlap import LAPTrackerFactory
from fiji.plugin.trackmate.tracking import LAPUtils
from fiji.plugin.trackmate.visualization.hyperstack import HyperStackDisplayer
from fiji.plugin.trackmate.features import FeatureFilter


from fiji.plugin.trackmate.io import TmXmlReader, TmXmlWriter
from fiji.plugin.trackmate.util import TMUtils
from fiji.plugin.trackmate.action import ExportStatsToIJAction, ExportTracksToXML
from fiji.plugin.trackmate.detection import DetectorKeys

from fiji.plugin.trackmate.features import FeatureAnalyzer, ModelFeatureUpdater, SpotFeatureCalculator
from fiji.plugin.trackmate.features.spot import SpotContrastAndSNRAnalyzerFactory, SpotContrastAndSNRAnalyzer
from fiji.plugin.trackmate.features.track import TrackDurationAnalyzer, TrackSpeedStatisticsAnalyzer

import fiji.plugin.trackmate.features.track.TrackDurationAnalyzer as TrackDurationAnalyzer
import fiji.plugin.trackmate.features.SpotFeatureCalculator as SpotFeatureCalculator
import fiji.plugin.trackmate.features.spot.SpotContrastAndSNRAnalyzer as SpotContrastAndSNRAnalyzer
import fiji.plugin.trackmate.features.spot.SpotIntensityAnalyzerFactory as SpotIntensityAnalyzerFactory


    



# Get currently selected image
imp = WindowManager.getCurrentImage()
#imp = IJ.openImage('http://fiji.sc/samples/FakeTracks.tif')
#imp.show()


#----------------------------
# Create the model object now
#----------------------------

# Some of the parameters we configure below need to have
# a reference to the model at creation. So we create an
# empty model now.

model = Model()

# Send all messages to ImageJ log window.
model.setLogger(Logger.IJ_LOGGER)



#------------------------
# Prepare settings object
#------------------------

settings = Settings()
settings.setFrom(imp)
settings.addSpotAnalyzerFactory(SpotIntensityAnalyzerFactory())
settings.addSpotAnalyzerFactory(SpotContrastAndSNRAnalyzerFactory())

# Configure detector - We use the Strings for the keys
settings.detectorFactory = LogDetectorFactory()
settings.detectorSettings = {
    'DO_SUBPIXEL_LOCALIZATION' : DO_SUBPIXEL_LOCALIZATION,
    'RADIUS' : RADIUS,
    'TARGET_CHANNEL' : TARGET_CHANNEL,
    'THRESHOLD' : THRESHOLD,
    'DO_MEDIAN_FILTERING' : DO_MEDIAN_FILTERING,
}



# Configure spot filters on contrast
if TARGET_CHANNEL == 1:
	filter1 = FeatureFilter('CONTRAST', 0.13, True)
	settings.addSpotFilter(filter1)

# Configure tracker
#		from http://forum.imagej.net/t/trackmate-scripting-automatically-exporting-spots-in-tracks-links-in-tracks-tracks-statistics-and-branching-analysis-to-csv/6256
settings.trackerFactory = SparseLAPTrackerFactory()
settings.trackerSettings = LAPUtils.getDefaultLAPSettingsMap() # almost good enough


settings.trackerSettings['LINKING_MAX_DISTANCE'] = LINKING_MAX_DISTANCE
settings.trackerSettings['LINKING_FEATURE_PENALTIES'] = {}
#gap closing
settings.trackerSettings['ALLOW_GAP_CLOSING'] = ALLOW_GAP_CLOSING
settings.trackerSettings['GAP_CLOSING_MAX_DISTANCE'] = GAP_CLOSING_MAX_DISTANCE
settings.trackerSettings['MAX_FRAME_GAP'] = MAX_FRAME_GAP
settings.trackerSettings['GAP_CLOSING_FEATURE_PENALTIES'] = {}
#splitting
settings.trackerSettings['ALLOW_TRACK_SPLITTING'] = ALLOW_TRACK_SPLITTING
settings.trackerSettings['SPLITTING_MAX_DISTANCE'] = SPLITTING_MAX_DISTANCE
settings.trackerSettings['SPLITTING_FEATURE_PENALTIES'] = {}
#merging
settings.trackerSettings['ALLOW_TRACK_MERGING'] = ALLOW_TRACK_MERGING
settings.trackerSettings['MERGING_MAX_DISTANCE'] = MERGING_MAX_DISTANCE
settings.trackerSettings['MERGING_FEATURE_PENALTIES'] = {}
#etc
#settings.trackerSettings['ALTERNATIVE_LINKING_COST_FACTOR'] = 1.05
#settings.trackerSettings['BLOCKING_VALUE'] = Infinity
#settings.trackerSettings['CUTOFF_PERCENTILE'] = 0.9


# Configure track filter for cells to remove short duplicate tracks
if TARGET_CHANNEL == 2:
	settings.addTrackAnalyzer(TrackDurationAnalyzer())
	filter2 = FeatureFilter('TRACK_DURATION', 99.99, True)
	settings.addTrackFilter(filter2)

#-------------------
# Instantiate plugin
#-------------------

trackmate = TrackMate(model, settings)

#--------
# Process
#--------

ok = trackmate.checkInput()
if not ok:
    sys.exit("A:" + str(trackmate.getErrorMessage()))

ok = trackmate.process()
if not ok:
    sys.exit("B: " + str(trackmate.getErrorMessage()))


#----------------
# Display results
#----------------

selectionModel = SelectionModel(model)
displayer =  HyperStackDisplayer(model, selectionModel, imp)
displayer.render()
displayer.refresh()

# Echo results with the logger we set at start:
model.getLogger().log(str(model))

# Export stats to results table
### UNDER CONSTRUCTION
ExportStatsToIJAction(selectionModel).execute(trackmate)




IJ.log("\nTracker settings as follows:")
for x in settings.trackerSettings:
	IJ.log(' - ' + x + ' : ' + str(settings.trackerSettings[x]))

IJ.log("\nDetector settings as follows:")
for x in settings.detectorSettings:
	IJ.log(' - ' + x + ' : ' + str(settings.detectorSettings[x]))
IJ.log("")


#### Save XML file
#IJ.log("save XML file as: "+savename)
#outfile = TmXmlWriter(File(savename))
outfile.appendModel(model)
outfile.writeToFile()



### end script
quit()
