close all; 
clearvars; 
clc;

%% DIGITECH OVERDRIVE PREAMP 250

addpath( '..\CommonFunctions\' );

%% Import input signal

inputName = 'AudioNorm48000';

[ x_in , f_s ] = audioread( [ 'Input\' , inputName , '.wav' ] );

%% Import ground-truth signal

[ y_GT , ~ ] = audioread( [ 'LTspice\' , inputName , '_LTspice.wav' ] ); 

%% Element parameters

a = 0.0125;
b = 81;
Rtol = 10 ^ ( -6 );

N_ser = 2;

I_s = 4.352 * 10 ^ ( -9 );
eta = 1.905; 
V_th = 25.8563 * 10 ^ ( -3 );
R_s = 10 ^ ( -3 );
R_p = 10 ^ 6;

x = 0.9;
y = 0.7;

RVin = 10 ^ ( -9 );
R1 = 2.2 * 10 ^ 6;     
R2 = 10 * 10 ^ 3;      
R3 = 10 ^ 6;     
R4 = 4.7 * 10 ^ 3;      
R5 = 10 ^ 6;   
R6 = 10 * 10 ^ 3; 
P1 = 500 * 10 ^ 3;
P2 = 100 * 10 ^ 3;
RG2 = ( 1 + a ) * ( 1 - b ^ ( x - 1 ) ) * P1 + Rtol;
RL1 = a * ( b ^ y - 1 ) * P2 + Rtol;
RL2 = ( 1 + a ) * ( 1 - b ^ ( y - 1 ) ) * P2 + Rtol;

C1 = 0.01 * 10 ^ ( -6 );
C2 = 0.047 * 10 ^ ( -6 );
C3 = 25 * 10 ^ ( -12 );
C4 = 4.7 * 10 ^ ( -6 );
C5 = 0.001 * 10 ^ ( -6 );

pos_C = [ 3 , 5 , 6 , 10 , 16 ];

%% Adaptation conditions

Z_D1 = 1;
Z_Ds1 = 1;
Z_Vin = RVin;
Z_R1 = R1;
Z_R2 = R2;
Z_R3 = R3;
Z_R4 = R4;
Z_R5 = R5;
Z_R6 = R6;
Z_RG2 = RG2;
Z_RL1 = RL1;
Z_RL2 = RL2;
Z_C1 = 1 / ( 2 * C1 * f_s );
Z_C2 = 1 / ( 2 * C2 * f_s );
Z_C3 = 1 / ( 2 * C3 * f_s );
Z_C4 = 1 / ( 2 * C4 * f_s );
Z_C5 = 1 / ( 2 * C5 * f_s );

%% Reference port resistances/conductances matrix

Z = diag( [ Z_RL1 , Z_Vin , Z_C1 , Z_R2 , Z_C2 , Z_C3 , Z_D1 , Z_R6 , Z_R4 , ...
            Z_C5 , Z_Ds1 , Z_RG2 , Z_R1 , Z_R3 , Z_R5 , Z_C4 , Z_RL2 ] );

%% Fundamental loop matrices

B_V = [ 0	0	0	0	0	0	1	0	0	1	0	0	0	0	0	0	0;
        0	0	0	0	0	0	1	0	0	0	1	0	0	0	0	0	0;
        0	1	1	1	-1	0	0	0	-1	0	0	1	0	0	0	0	0;
        0	-1	0	0	0	0	0	0	0	0	0	0	1	0	0	0	0;
        0	-1	-1	-1	0	0	0	0	0	0	0	0	0	1	0	0	0;
        0	0	0	0	0	-1	0	0	0	0	0	0	0	0	1	0	0;
        0	1	1	1	0	1	-1	1	0	0	0	0	0	0	0	1	0;
        -1	0	0	0	0	0	1	0	0	0	0	0	0	0	0	0	1 ];

B_I = [ 0	0	0	0	0	0	1	0	0	1	0	0	0	0	0	0	0
        0	0	0	0	0	0	1	0	0	0	1	0	0	0	0	0	0
        0	0	0	0	-1	-1	0	0	-1	0	0	1	0	0	0	0	0
        0	-1	0	0	0	0	0	0	0	0	0	0	1	0	0	0	0
        0	-1	-1	-1	0	0	0	0	0	0	0	0	0	1	0	0	0
        0	0	0	0	0	-1	0	0	0	0	0	0	0	0	1	0	0
        0	0	0	0	0	0	-1	1	0	0	0	0	0	0	0	1	0
        -1	0	0	0	0	0	1	0	0	0	0	0	0	0	0	0	1 ];

%% Number of samples/elements

L = length( x_in );
N = size( Z , 1 );

%% Tolerances

tol = 10 ^ ( -3 );
tol_DSR = 10 ^ 4;

%% WDF initialization

a = zeros( N , 1 );
b = zeros( N , 1 );

v = zeros( N , 1 );
v_old = v + tol;

R_th_D1 = Z_D1 + tol_DSR;
R_th_Ds1 = Z_Ds1;

y_out = zeros( L , 1 );

%% WDF simulation

time = tic;

k = 0;

while k < L

    k = k + 1;

    b( 2 ) = x_in( k );
    b( pos_C ) = a( pos_C );

    if abs( R_th_D1 - Z( 7 , 7 ) ) + abs( R_th_Ds1 - Z( 11 , 11 ) ) >= tol_DSR

        Z( 7 , 7 ) = R_th_D1;
        Z( 11 , 11 ) = R_th_Ds1;

        S = eye( N ) - 2 * Z * B_I' * ( ( B_V * Z * B_I' ) \ B_V );

    end

    while norm( v - v_old ) > tol

        v_old = v;

        b( 7 ) = extendedSchockleyDiodeScat( a( 7 ) , Z( 7 , 7 ) , 1 , I_s , eta , V_th , R_s , R_p );
        b( 11 ) = extendedSchockleyDiodeScat( a( 11 ) , Z( 11 , 11 ) , 1 , I_s , N_ser * eta , V_th , N_ser * R_s , N_ser * R_p );

        a = S * b;

        v = 0.5 * ( a + b );

    end

    i_D1 = 0.5 * ( a( 7 ) - b( 7 ) ) / Z( 7 , 7 );
    i_Ds1 = 0.5 * ( a( 11 ) - b( 11 ) ) / Z( 11 , 11 );

    R_th_D1 = extendedSchockleyDiodeRes( v( 7 ) , i_D1 , I_s , eta , V_th , R_s , R_p );
    R_th_Ds1 = extendedSchockleyDiodeRes( v( 11 ) , i_Ds1 , I_s , N_ser * eta , V_th , N_ser * R_s , N_ser * R_p );
    
    y_out( k ) = 0.5 * ( a( 1 ) + b( 1 ) );

    v_old = v + tol;

end

time = toc( time );

disp( [ 'Simulation time: ' , num2str( time ) ] );

%% Write output file

audiowrite( [ 'Output\' , inputName , '_WDF.wav' ] , y_out , f_s );

%% Output plot

plotGroundTruthWDF( y_out , y_GT , f_s , 'V' );

%% RTR 

RTR = time * f_s / L;

disp( [ 'RTR: ' , num2str( RTR ) ] );
