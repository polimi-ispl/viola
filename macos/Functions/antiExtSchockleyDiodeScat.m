function [ b ] = antiExtSchockleyDiodeScat( a , Z , I_s , eta , V_th , R_s , R_p )
    mod_a = abs( a );
    sgn_a = sign( a );
    alpha = ( 2 * R_p * I_s * Z + mod_a * ( R_p + R_s - Z ) ) / ( R_p + R_s + Z );
    beta = 2 * eta * V_th * Z / ( R_s + Z );
    gamma = R_p * I_s * ( R_s + Z ) / ( eta * V_th * ( R_p + R_s + Z ) );
    delta = mod_a * ( Z - R_s ) / ( 2 * eta * V_th * Z );
    b = sgn_a * ( alpha - beta * enhancedOmegaW( log( gamma ) + delta + alpha / beta ) );
end
