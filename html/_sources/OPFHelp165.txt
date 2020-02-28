
.. index::
   pair: File; Formats

Beam Data File formats
----------------------

Since the 2003 version the Opposing Fields program caters for sites with more
than one linear accelerator. Each machine is defined by a beam data file
containing a list of photon energies with their associated parameters. The
name of the file defines the name of the machine. When it initialises the
program looks in the program directory for files with the extension '.bdf'
and places these names in a list. 

Since 2011 the data has been stored in text format. Although the data may be
examined using any text editor it should only be altered
using the 'Beam' program in the program directory. This program calculates
a check sum. If the calculated and stored check sums do not match the 
Opposing Fields program will not start.

Only a medical
physicist or authorised person should use the Beam program and utmost care
should be exercise to avoid accidentally altering the beam data.

The beam data format is as follows:

====    ===========
Line    Description
====    ===========
1       Title
2       Short machine name 
3       Number of photon energies
4       Program expiry date
-       Repeating block for each photon energy
5       Energy
6       Depth of d\ :sub:`max`\
7       Table factor
8       5 Tray factors
9       Regression parameters of the output factor curve
10      Number of lines of TMR values
11      Number of columns of TMR values
12      Field sizes for TMR table
13      Depth and TMR values
.       .
.       .
.       .
====    ===========


