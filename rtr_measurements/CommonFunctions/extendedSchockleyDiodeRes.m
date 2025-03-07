function [ R_th ] = extendedSchockleyDiodeRes( v , i , I_s , eta , V_th , R_s , R_p )
    df_i = - 1 - R_s / R_p - R_s * I_s * exp( ( v - R_s * i ) / ( eta * V_th ) ) / ( eta * V_th );
    df_v = 1 / R_p + I_s * exp( ( v - R_s * i ) / ( eta * V_th ) ) / ( eta * V_th );
    R_th = - df_i / df_v;
end