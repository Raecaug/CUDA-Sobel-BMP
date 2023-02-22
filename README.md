##Class:        Introduction to Operating Systems##
##Date:         11/16/18##

#FILES:#
main.cu: Contains all code necessary to compile and run the broken Sobel algorithm provided by professor. 

README.txt: Contains instructions for compiling, and running this code on a Palmetto node with a GPU, by using the CUDA API.


In order to optimize data transfers from host to device(the GPU) it is required that this program be compiled and tested on a GPU of the Pascal architecture or newer. Use a Tesla P100 GPU, as this is what we used for running and testing our program. You can request a P100 GPU by using the following line when starting a node on Palmetto: 

"qsub -I  -l select=1:ncpus=4:ngpus=1:gpu_model=p100:mem=6gb,walltime=2:00:00"


#IMPORTANT NOTE FOR RUNNING AND COMPILING:#
This code will ONLY COMPILE AND RUN on a Palmetto node that has the cuda-toolkit/9.2 module installed. In order to add this module to a running node use the following command:

"module add cuda-toolkit/9.2"


#COMPILATION INSTRUCTIONS:#
The following line will compile main.cu into a binary executable called 'convert'. NOTE, the nvcc compiler is only made available after running the above module add command. Otherwise, Palmetto will report that nvcc is an unknown command. Compiliation line:

"nvcc main.cu -o convert"


#RUNTIME INSTRUCTIONS:#
The compiled program can be run using the following command structure. If invalid arguments are passed, the program will inform you and crash. The following is the proper runtime command:

"./convert [TARGET FILENAME] [THREADS]"

DO NOT FORGET to run the module add command for CUDA version 9.2 before running, or this program WILL NOT EXECUTE CORRECTLY.
