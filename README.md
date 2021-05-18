# Contactless recordings of retinal activity using optically pumped magnetometers

Britta U. Westner, James I. Lubell, Mads Jensen, Sigbjørn Hokland, & Sarang S. Dalal
​
## Abstract
Optically pumped magnetometers (OPMs) have been adopted for the recording of brain activity. Without the need to be cooled to cryogenic temperatures, an array of these sensors can be placed more flexibly, which allows for the recording of neuronal structures other than neocortex. Here we use eight OPM sensors to record human retinal activity following flash stimulation. We compare this magnetoretinographic (MRG) activity to the simultaneously recorded electroretinogram of the eight participants. The MRG shows the familiar flash-evoked potentials (a-wave and b-wave) and shares a highly significant amount of information with the electroretinogram recording (both in a simultaneous and separate recording). We conclude that OPM sensors have the potential to become a contactless alternative to fiber electrodes for the recording of retinal activity. Such a contactless solution can benefit both clinical and neuroscientific settings. 

## This repository
This repository contains the data analysis scripts for [Westner et al., preprinted]()

The data analysis files are organized as follows:

### Reading data and preprocessing
* `analyze_mrg_data.m` reads and preprocesses the OPM MRG data
* `analyze_simultaneous_data.m` reads and preprocesses the simultaneous OPM MRG and ERG data

### Analyze data
* `compare_erg_mrg.m` computes the mutual information between MRG and ERG
* `compare_trial_rejection.m` compares the trial rejection rates across different data sets
* `compute_noise.m` computes the noise spectrum and SNR for the data sets

### Plotting
* `plot_grandaverages.m` plots the channels averaged across subjects

### Functions and utilities
The folder `functions` and `utilities` contain helper functions and extra resources for the data analysis.

## Dependencies
This project uses [FieldTrip](https://www.fieldtriptoolbox.org/) (dev. version Nov 3 2020).
