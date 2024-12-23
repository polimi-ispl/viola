function [ R_th ] = extendedSchockleyDiodeRes( v , i , I_s , eta , V_th , R_s , R_p )
    beta = eta * V_th;
    expTerm = exp( ( v - R_s * i ) / beta ) / beta;
    R_p_inv = 1 / R_p;
    df_i = - 1 - R_s * ( R_p_inv + I_s * expTerm );
    df_v = R_p_inv + I_s * expTerm;
    R_th = - df_i / df_v;
end