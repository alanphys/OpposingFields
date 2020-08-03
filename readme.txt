Opposing Fields Readme file
(c) Yenzakahle Medical Physics Inc 1994-2020

1) Licence
Please read the file Licence.txt. This means that if as a result of using this program you fry your patients, trash your linac, nuke the cat, blow the city power in a ten block radius and generally cause global thermonuclear meltdown! Sorry, you were warned!


2) Introduction
In this age of VMAT and Monte Carlo algorithms the Opposing Fields program is looking rather dated. However, it is refusing to lay down and die and it appears there is still a role for point dose calculations. 

The Opposing Fields program allows the easy calculation of simple radiotherapy treatment plans. Despite its name, it cannot only do opposing parallel fields, but can also calculate plans for single fields as well. For each type of field it can do isocentric treatment, fixed SSD treatment (SSD = 100 cm), and also variable SSD treatments.

The Opposing Fields program owes its simplicity to the fact that it uses central axis point calculations in contrast to more complicated three-dimensional treatment planners, which calculate a matrix of dose points. This places some limitations on the use of the Opposing Fields program, but it is not meant to replace the more expensive three-dimensional treatment planners but instead to serve as supplement or as a check against these more complex programs.

Opposing Fields should not be used where there is a high degree of tissue inhomogeneity, uneven surfaces or radiosensitive structures. The Opposing Fields program in effect assumes that the patient is a uniform homogeneous water equivalent rectangle.

3) Installation.
Please start by printing a standard treatment plan from the old version. This plan will be used to verify that the installation of the new version is correct.

3.1) Uninstalling
It is no longer necessary to uninstall previous versions of OPF before installing a new version. The installation utility will backup existing data files and install new files. However, to be safe please save your own copy of your data files.

Select 'Start', 'Settings', 'Control Panel'
Double click on the 'Add/Remove Programs' Icon or 'Programs and Features'
Select the 'Opposing Fields' program by clicking on it
Click on the 'Add/Remove' button
Click on the 'OK' button and close the Control Panel

3.2) Installing
Logon to Windows using an account with administrator privileges. Open Windows Explorer and navigate to the appropriate directory. Select "OPFsetup.exe" and double click. Press the 'OK' button. Complete the installation by responding to the instructions onscreen. When the installation is complete, enter and print the same treatment plan that was printed previously. The results must be the same.

Note: From version 3.0 beam data files are no longer distributed with the Opposing Fields program. If you are upgrading an existing installation your beam data files will still be available in the installation directory. However, it is strongly recommended to copy the data files into the program data directory by opening the beam module by selecting 'Settings, Manage machines', opening the appropriate beam data file and clicking 'Finish'.

For new installations the beam data file must be created or imported if one is provided. Select 'Settings, Manage machines', open the appropriate beam data file and click 'Finish'.

4) Running the Opposing Field program.
Select 'Start', 'Programs', 'Opposing Fields'. Alternatively, double click the Opposing Fields icon on the Windows desktop.

5) Using the Opposing Fields program.
Enter the appropriate data into each field. Press <Tab> to move from one field to the next. When the information has been entered click on 'Calculate' to display the treatment plan. Click on 'Print' or the print button to print the plan. Click on the close button to exit.  For further information please refer to the manual or on-line help.

6) Bugs
There are, of course, no bugs. However, should the program behave in a way that you do not understand or deliver results that you do not expect I would like to know about it. You can report issues at https://github.com/alanphys/OpposingFields/issues.

7) Release notes
These detail new or changed functionality in the software. Please see the History for bug fixes.

Version 3.1
Beam data files are no longer stored with the executable but in the appropriate program data directory. If no data exists in the config directory the program will look in the executable dir to accommodate legacy installations. Edited beam files are automatically stored in the program data config dir.

Version 3.0 (2020)
This version is characterised by a conceptual change in the way the Opposing Fields program is distributed. Although it has always been freely available it was in the past restricted to areas over which the author had personal oversight. The code and executables of this version are now released as open source. The author will no longer distribute data files and maintenance of the data is the sole responsibility of the user.

This version incorporates the beam definition module which was previously available as a separate program. An authorisation module has also been added to control access to the beam definition module and to provide user identification on the plan.

An About module has been added giving this readme, the licence and credits. The data expiry check has been removed. The error and messaging systems has been refactored and consolidated.

Version 2.4 (2014)
Altered output to pdf. Plans can be saved as PDF's. Disabled compensators. Added status bar and error reporting.

Version 2.3 (2012)
Added online help

Version 2.2 (2009)
Ported to Lazarus and Free Pascal. (There was a short lived Kylix version). Help is disabled.

Version 2.1 (2003)
Added multiple machines. Included compensators.

Version 2.0 (2000)
Windows version. Incorporates definable beam parameters stored in machine and patient files.

Version 1.0 (1994)
Dos version using Turbo Pascal. Parameters are hard coded.

8) History
Core elements of the opposing fields program have been around since 1994 when the first DOS version came out. In 1999 work began on porting it to Windows 95 using Delphi.
1/2/2000   On-line and context sensitive help has now been added.
           The length and breadth fields have been swapped.
           The Presentation field is disabled for single beams.
4/2/2000   Windows version released as 2.0
24/2/2000  altered field size on output
           patient diameter print only on opposing field
           swapped FSX and FSY fields in output factor ST
           increase max SSD to 230 cm
           increase max diameter to 50 cm
30/5/2001  Format of the output has been slightly altered to shorten it.
           The program has been compiled under Delphi 5, which uses aligned fields unlike previous versions. This means that this version of the program cannot read files from previous versions.
           fixed save bug
           fixed variable SSD bug
12/6/2002  Reference dose added.
           Automatic date entry added
           Definable expiry date added.
27/6/2003  add multiple machines
           fixed save on close bug
8/8/2003   altered skin dose depth from 0.03 to 0.1
19/8/2003  fixed variable SSD print
           fixed update fields before exit
           included compensator option
7/7/2003   Support for multiple beam data files/linacs added.
9/2/2004   added initialise with dmax for dose to maximum
10/3/2004  disable TDepth for Single field dose to maximum
5/6/2009   Ported to Lazarus
           Use CRC for integrity verification instead of checksum
           Fix exit bug
           Help disabled for the moment
21/4/2008  convert to TMR tables
20/6/2008  reduce depth range to 25 to conform with diam of 50
1/2/2011   fixed date format error, fixed various error checks
2/7/2012   added on line help and web help server
10/1/2013  fixed TMR bug on smallest field
16/10/2014 altered output to pdf
17/10/2014 disable compensators
20/10/2014 added status bar and error reporting
           added DR no
22/10/2014 set save default to My Documents/Patients
18/11/2014 fixed inconsistent save action and directories
12/7/2016  fixed defines for windows 64 bit
24/4/2019  fixed beam empty cell and data errors
10/7/2019  fix spelling Normalisation 
           added standard about unit
5/2/2020   remove expiry check
7//2/2020  fix save as file name error
           update statusbar messaging system and refactor
           implemented login module
28/2/2020  remove definitions from beam unit and use from opfunit
17/3/2020  add refresh linac list on beam module exit
24/3/2020  store all beam config files automatically in program config dir
           look in program data confid dir first for beam file
16/4/2020  fix various memory leaks
3/8/2020   correct title of login module
