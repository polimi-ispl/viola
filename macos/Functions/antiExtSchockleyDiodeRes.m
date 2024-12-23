function [ R_th ] = antiExtSchockleyDiodeRes( v , i , I_s , eta , V_th , R_s , R_p )
    beta = eta * V_th;
    hypTerm = 2 * I_s * cosh( ( v - R_s * i ) / beta ) / beta;
    R_p_inv = 1 / R_p;
    R_th = ( R_s * ( hypTerm + R_p_inv ) + 1 ) / ( hypTerm + R_p_inv );
end