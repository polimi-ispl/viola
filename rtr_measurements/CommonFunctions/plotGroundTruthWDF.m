function plotGroundTruthWDF( y_WDF , y_GT , f_s , sigType )
    N_GT = length( y_GT );
    N_WDF = length( y_WDF );
    N = min( N_GT , N_WDF );
    switch sigType
        case 'V'
            T = 'V';
        case 'I'
            T = 'A';
    end
    figure;
    aspectRatio = 16 / 9;
    width = 600;
    height = width / aspectRatio;
    set( gcf , 'Position' , [ 100 , 100 , width , height ] );
    plot( ( 0 : N - 1 ) / f_s , y_GT( 1 : N ) , 'Color' , '#EDB120' , 'Linewidth' , 3 );
    hold on;
    plot( ( 0 : N - 1 ) / f_s , y_WDF( 1 : N ) , 'b--' , 'Linewidth' , 2 );
    grid on;
    xlim( [ 0 , ( N - 1 ) / f_s ] ); 
    delta = 0.1 * max( abs( y_GT ) , [ ] , 'all' );
    ylim( [ min( y_GT , [ ] , 'all' ) - delta , max( y_GT , [ ] , 'all' ) + delta ] );
    xlabel( '$t$ [s]' , 'Fontsize' , 20 , 'interpreter' , 'latex' );
    ylabel( [ '$v_{\mathrm{out}}(t)$ [' , T , ']' ] , 'Fontsize' , 20 , 'interpreter' , 'latex' );
    legend( 'LTspice' , 'WDF' , 'Fontsize' , 13 , 'interpreter' , 'latex' );
end
