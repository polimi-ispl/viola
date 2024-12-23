close all
clearvars
clc

%% GENERAL PATH CONFIGURATION

rng( 21 );
addpath( genpath( "Functions" ) , genpath( "Data" ) );

%% CONFIGURATION PARAMETERS

% LTspice netlist name
netlist = 'EHBMP';

% Node to measure the output voltage
outNode = 'N016';

% Tolerance for SIM iterative solver
tolSLV = 1e-5;

% Tolerance for DSR algorithm
tolDSR = 1e3;

% The type for deployment 
% ('vst': .dll - 'vst3': .vst3 - 'exe': .exe - 'au': .au - 'auv3' )
pluginType = "au";

% The code recognized by the DAW
pluginCode = "EHBMP";

% Title displayed in the user interface
pluginName = "ELECTRO-HARMONIX BIG MUFF PI";

% Labels for each knob (circuit potentiometer)
potLabels = [ "Drive" , "Tone" , "Level" ];

%% NETLIST PROCESSING

[ Tree , Cotree , outNode , potsData , circuitClass ] = netlistParse( netlist , outNode );

%% WD MODEL GENERATION

[ typeOrder , params , potsOrder , Q , B , outPath ] = getPluginParams( Tree , Cotree , outNode , potsData , tolSLV , tolDSR );

%% CODE OPTIMIZATION & GUI CUSTOMIZATION

customizePlugin( circuitClass , pluginCode , pluginName , potsOrder , typeOrder , potLabels , Q , B );

%% PLUGIN DEPLOYMENT

eval( strcat( "generateAudioPlugin " , "-" , pluginType , " " , pluginCode ) );