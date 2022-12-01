#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Thu Jan 14 17:40:32 2021

@author: tomslab
"""

from argparse import ArgumentParser
import os
import csv

def escritura(lista, nombre):

    archivo = open(nombre, 'w')
    archivo.close()    
    
    for linea in lista:
        
        with open(nombre, mode='a') as result_file:
            line_writer = csv.writer(result_file, delimiter='\t', quotechar='"', quoting=csv.QUOTE_MINIMAL)
        
            line_writer.writerow(linea)  
            
#enddef
      
def main(all_files_folder, output): 

    result = []
    files = os.listdir(all_files_folder)
    
    os.chdir(all_files_folder)
    for x in range(len(files)):
        
        if x == 0:
            
            file = open(files[x], 'r')
            for line in file:
                
                line = line.strip().split('\t')
                result.append(line)
                
        else:
            
            file = open(files[x], 'r')
            counter = 0
            
            for line in file:
                
                line = line.strip().split('\t')
                sublist = line[6:len(line)]
                result[counter] = result[counter]+sublist
    
                counter = counter + 1
                
    escritura(result, output)
    
#enddef

'''MAIN PROGRAM'''

if __name__ == '__main__':
    
    parser = ArgumentParser ()

    parser.add_argument(
        '-i','--input',
        dest='path',
        action='store',
        required=True,
        help='Path of the folder that contains the experiments files'
        )
    
    parser.add_argument(
        '-o','--output',
        dest='output',
        action='store',
        required=True,
        help='Path of the output.'
        )
    
    args = parser.parse_args ()
    
    all_files_folder = args.path
    output = args.output
    
    main(all_files_folder, output)