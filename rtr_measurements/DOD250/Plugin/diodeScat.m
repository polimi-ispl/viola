function [ b ] = diodeScat( a , Z , pars )
    I_s = pars( : , 1 );
    eta = pars( : , 2 );
    V_th = pars( : , 3 );
    R_s = pars( : , 4 );
    R_p = pars( : , 5 );
    b = arrayfun( @extendedSchockleyDiodeScat , a , diag( Z ) , I_s , eta , V_th , R_s , R_p );
end
