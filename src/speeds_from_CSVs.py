# -*- coding: utf-8 -*-
"""
Created on Fri Apr 24 17:32:53 2020

@author: dani
"""

import pandas as pd
import os
#import csv
#import numpy as np
#from pathlib import Path


px_size = 0.156648
t_intv = 4/60
unit_conversion = px_size / t_intv

analysis_folder = '200502190132_ChannelMigration'


#parent = Path(__file__).parent.parent
#current = Path(str(parent)+'/output/'+analysis_folder)
#print(parent)
#print(current)
parent = r'C:/Users/dani/Documents/MyCodes/ChannelMigration_Speeds/'
current = parent + r'output/' +  analysis_folder


neg_migrators = ['MM_F_00_2_019', 'CM_B_GB_1_008', '190319_CM_B_GX_3_009']
directions = ['left','right']


columns = ['exp#','cell_name','velocity','speed','t0','points','Y_mean','direction','time_gap','filename','TimeReg']
outdf = pd.DataFrame(columns=columns)
import_columns = ['POSITION_X','POSITION_Y','POSITION_T','FRAME']

CSV_list = [f for f in os.listdir(current) if f.endswith('.csv')]

#get cell list
with open(parent + r'resources/Cells_used.csv', 'r') as file:
    cell_list = [line.rstrip('\n') for line in file]


for file in CSV_list:
#        print('{}/{}'.format(current,file))
    filepath = '{}/{}'.format(current,file)
    try:
        data = pd.read_csv(filepath, usecols=import_columns)
    except pd.errors.EmptyDataError:
        print ('empty CSV: ' + file)
#    data = pd.read_csv('{}/{}'.format(current,file) )
    else:
        cell_name = file[file.index('_')+1:file.index('.')]
        
        if cell_name in cell_list:
    
            # get time = 0 
            t0 = data.FRAME[0]
            
            distance = data.POSITION_X.iloc[-1] - data.POSITION_X.iloc[0]
            tot_time = data.FRAME.iloc[-1] - data.FRAME[0]
            speed = abs(distance) / tot_time * unit_conversion
            
            exp_no = file[:file.index('_')]
    #        prefix = '{}_{}_{}_{}'.format(file[:9],file[9],file[10:12],file[12])
            cell_name = file[file.index('_')+1:file.index('.')]
            
            for i in range(len(data)):
                if i == 0:
                    displ = 0
                else:
                    displ += abs(data.POSITION_X[i]-data.POSITION_X[i-1])
            displ_speed = displ / tot_time * unit_conversion
            
            # set direction of migration (pos to right, neg to left)
            swap_dir = 0
            if file in neg_migrators:
                swapdir = 1
            if distance<0:
                direction = directions[1-swapdir]
            else:
                direction = directions[0+swapdir]
    
            # Check if there are missing or duplicate timepoints        
            if tot_time != len(data)-1:
                nonlin = '*****'
            else:
                nonlin=''
            
            # Make list of registration points
            TimeReg = [int(round(x-data.POSITION_X.iloc[0])) for x in data.POSITION_X]
            
            # Get mean Y_pos
            Ymean = int(round(data.POSITION_Y.mean()))
    
            outdf.loc[len(outdf)] = [exp_no,cell_name,speed,displ_speed,t0,len(data),Ymean,direction,nonlin,file,TimeReg]
    
export_columns = ['exp#','cell_name','Y_mean','direction','TimeReg']
outdf[export_columns].to_csv(current + '_Reg_Data.csv')
            
print('ready')