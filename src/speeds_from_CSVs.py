# -*- coding: utf-8 -*-
"""
Created on Fri Apr 24 17:32:53 2020

@author: dani
"""

import pandas as pd
import os
#from pathlib import Path


px_size = 0.156648
t_intv = 4/60
unit_conversion = px_size / t_intv

analysis_folder = '200502190132_ChannelMigration'


#parent = Path(__file__).parent.parent
#current = Path(str(parent)+'/output/'+analysis_folder)
#print(parent)
#print(current)
current = r'C:/Users/dani/Documents/MyCodes/ChannelMigration_Speeds/output/' +  analysis_folder

#subdirs = os.listdir(current)

columns = ['exp#','cell#','speed','*speed*','t0','points','time_gap','filename']
outdf = pd.DataFrame(columns=columns)
import_columns = ['POSITION_X','POSITION_Y','POSITION_T','FRAME']

#for exp in subdirs:
CSV_list = [f for f in os.listdir(current) if f.endswith('.csv')]

for file in CSV_list:
#        print('{}/{}'.format(current,file))
    filepath = '{}/{}'.format(current,file)
    try:
        data = pd.read_csv(filepath, usecols=import_columns)
    except pd.errors.EmptyDataError:
        print ('empty CSV: ' + file)
#    data = pd.read_csv('{}/{}'.format(current,file) )
    else:


        t0 = data.FRAME[0]
        
        distance = abs(data.POSITION_X.iloc[-1] - data.POSITION_X.iloc[0])
        tot_time = data.FRAME.iloc[-1] - data.FRAME[0]
        speed = distance / tot_time * unit_conversion
        
        exp_no = file[:file.index('_')]
#        prefix = '{}_{}_{}_{}'.format(file[:9],file[9],file[10:12],file[12])
        number = file[file.index('_')+1:file.index('.')]
        
        for i in range(len(data)):
            if i == 0:
                displ = 0
            else:
                displ += abs(data.POSITION_X[i]-data.POSITION_X[i-1])
        displ_speed = displ / tot_time * unit_conversion
        
        if tot_time != len(data)-1:
            nonlin = '*****'
        else:
            nonlin=''

        outdf.loc[len(outdf)] = [exp_no,number,speed,displ_speed,t0,len(data),nonlin,file]
    
    
            
print('ready')