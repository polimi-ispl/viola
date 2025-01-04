close all
clearvars
clc

%% GENERAL PATH CONFIGURATION

% Only for reproducibility purposes
rng( 21 );

% Paths for functions and data
addpath( genpath( "Functions" ) , genpath( "Data" ) );

%% CONFIGURATION PARAMETERS

% LTspice netlist name
netlist = 'MXR';

% Node to measure the output voltage
outNode = 'N010';

% Tolerance for SIM iterative solver
tolSLV = 10 ^ ( -5 );

% Tolerance for DSR algorithm
tolDSR = 1000;

% The type for deployment 
% ('vst': .dll - 'vst3': .vst3 - 'exe': .exe - 'au': .au - 'auv3' )
pluginType = "vst";

% The code recognized by the DAW
pluginCode = "MXR";

% Title displayed in the user interface
pluginName = "MXR DISTORTION PLUS";

% Labels for each knob (circuit potentiometer)
potLabels = [ "Gain" , "Level" ];

%% NETLIST PROCESSING

[ Tree , Cotree , outNode , potsData , circuitClass ] = netlistParse( netlist , outNode );

%% WD MODEL GENERATION

[ typeOrder , params , potsOrder , Q , B , outPath ] = getPluginParams( Tree , Cotree , outNode , potsData , tolSLV , tolDSR );

%% CODE OPTIMIZATION & GUI CUSTOMIZATION

customizePlugin( circuitClass , pluginCode , pluginName , potsOrder , typeOrder , potLabels , Q , B );

%% PLUGIN DEPLOYMENT

disp("Audio plug-in deployment...")
eval( strcat( "generateAudioPlugin " , "-" , pluginType , " " , pluginCode ) );
