#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Fri Nov 20 15:08:48 2020

@author: tomslab
"""

import os
from argparse import ArgumentParser

def main(experiments_path):
    
    reading = os.listdir(experiments_path)
    
    all_counts_folder = experiments_path + '/all_counts_folder'
    command = 'mkdir '+all_counts_folder
    os.system(command)
    
    for line in reading:
        
        line = line.strip()
        command = 'cp '+experiments_path+'/'+line+'/'+line+'_all_counts.txt ' + all_counts_folder
        # print(command)
        os.system(command)
        
#enddef
    

'''MAIN PROGRAM'''

parser = ArgumentParser (
)

parser.add_argument(
    '-p','--experiments_path',
    dest='path',
    action='store',
    required=True,
    help='Path to the folder that contains the experiments folders.'
    )

args = parser.parse_args ()

path = args.path

main(path)