classdef DOD < audioPlugin

    properties
        f_s = 48000;
        x_1 = 0.5;
        x_2 = 0.5;
        Volume = 1;
        Enable = 'ON';
    end

    properties ( Constant )
        PluginInterface = audioPluginInterface( ...
            audioPluginParameter( 'x_1' , ...
                'DisplayName' , 'Gain (P1)' , ...
                'DisplayNameLocation' , 'above' , ...
                'Style' , 'rotaryknob' , ...
                'Layout' , [ 4 1 ] , ...
                'Mapping' , { 'lin' , 0 , 1 } ) , ...
            audioPluginParameter( 'x_2' , ...
                'DisplayName' , 'Level (P2)' , ...
                'DisplayNameLocation' , 'above' , ...
                'Style' , 'rotaryknob' , ...
                'Layout' , [ 7 1 ] , ...
                'Mapping' , { 'lin' , 0 , 1 } ) , ...
            audioPluginParameter( 'Volume' , ...
                'DisplayName' , 'Volume' , ...
                'DisplayNameLocation' , 'above' , ...
                'Style' , 'rotaryknob' , ...
                'Layout' , [ 4 3 ] , ... 
                'Mapping' , { 'lin' , 0 , 2 } ) , ...
            audioPluginParameter( 'Enable' , ...
                'Style' , 'vrocker' , ...
                'DisplayNameLocation' , 'none' , ...
                'Layout' , [ 7 3 ] , ... 
                'Mapping' , { 'enum' , 'OFF' , 'ON' } ) , ...
            audioPluginGridLayout( 'RowHeight' , [ 30 10 20 150 10 20 150 10 ] , ...
                'ColumnWidth' , [ 150 10 150 ] , ...
                'Padding' , [ 10 10 10 10 ] , ...
                'RowSpacing' , 0 , ...
                'ColumnSpacing' , 0 ) , ...
            'BackgroundImage' , 'background.png' , ...
            'PluginName' , 'DOD' , ...
            'VendorName' , 'ISPL' , ...
            'VendorVersion' , '1.0.0' , ...
            'InputChannels' , 1 , ...
            'OutputChannels' , 1 );
    end

    properties ( Access = private )
        n;
        pos_Vin = [ 2 ];
        pos_R = [ 1 4 8 9 12 13 14 15 17 ];
        pos_C = [ 3 5 6 10 16 ];
        pos_D = [ 7 ];
        pos_Dser = [ 11 ];
        B_V; B_I;
        P; O;
        Z; S; 
        a; b;
        v; v_old; i;
        R_th;
        Rp; 
        tol_SLV;
        tol_DSR;
        R_tol = 10 ^ ( -6 );
    end

    methods
            
        function p = DOD
            s = coder.load( 'parsingResults.mat' );
            p.n = length( s.typeOrder );
            p.B_V = s.B_V;
            p.B_I = s.B_I;
            p.Rp = s.potRes;
            p.P = s.params;
            p.O = s.outPath;
            p.tol_SLV = s.tolSLV;
            p.tol_DSR = s.tolDSR;
            p.Z = zeros( p.n );
            p.S = zeros( p.n );
            initializeVecs( p );
        end

        function out = process( p , in )
            if strcmp( p.Enable , 'ON' )
                out = processBlock( p , in );                   
            else
                out = in;
            end
        end

        function reset( p )
            p.f_s = getSampleRate( p );
            initializeZ( p );
            initializePots( p );
            initializeVecs( p );
        end

        function set.x_1( p , value )
            p.x_1 = value;
            updateP1( p );
        end

        function set.x_2( p , value )
            p.x_2 = value;
            updateP2( p );
        end

        function set.Enable( p , state )
            p.Enable = state;
        end

        function set.Volume( p , value )
            p.Volume = value;
        end

        function initializePots( p )
            updateP1( p );
            updateP2( p );
        end

        function initializeVecs( p )
            p.a = zeros( p.n , 1 );
            p.b = zeros( p.n , 1 );
            p.v = zeros( p.n , 1 );
            p.v_old = p.v + p.tol_SLV;
            p.i = zeros( p.n , 1 );
            p.R_th = ones( p.n , 1 ) + p.tol_DSR;
        end

        function initializeZ( p )
            p.Z( p.pos_Vin , p.pos_Vin ) = diag( p.P( p.pos_Vin , 1 ) );
            p.Z( p.pos_R , p.pos_R ) = diag( p.P( p.pos_R , 1 ) );
            p.Z( p.pos_C , p.pos_C ) = diag( 1 ./ ( 2 * p.P( p.pos_C , 1 ) * p.f_s ) );
            p.Z( p.pos_D , p.pos_D ) = eye( length( p.pos_D ) );
            p.Z( p.pos_Dser , p.pos_Dser ) = eye( length( p.pos_Dser ) );
        end

        function updateP1( p )
            p.Z( 12 , 12 ) = 0.0125 * ( 1 - 81 ^ ( p.x_1 - 1 ) ) * p.Rp( 1 ) + p.R_tol;
        end

        function updateP2( p )
            p.Z( 1 , 1 ) = 0.0125 * ( 81 ^ p.x_2 - 1 ) * p.Rp( 2 ) + p.R_tol;
            p.Z( 17 , 17 ) = 0.0125 * ( 1 - 81 ^ ( p.x_2 - 1 ) ) * p.Rp( 2 ) + p.R_tol;
        end

        function out = processBlock( p , in )
            blockSize = size( in , 1 );
            out = zeros( blockSize , 1 );
            for ii = 1 : blockSize
                p.b( p.pos_Vin ) = in( ii );
                p.b( p.pos_R ) = 0;
                p.b( p.pos_C ) = p.a( p.pos_C );
                if sum( [ sum( abs( diag( p.Z( p.pos_D , p.pos_D ) ) - p.R_th( p.pos_D ) ) ) sum( abs( diag( p.Z( p.pos_Dser , p.pos_Dser ) ) - p.R_th( p.pos_Dser ) ) ) ] ) >= p.tol_DSR
                    p.Z( p.pos_D , p.pos_D ) = diag( p.R_th( p.pos_D ) );
                    p.Z( p.pos_Dser , p.pos_Dser ) = diag( p.R_th( p.pos_Dser ) );
                    p.S = eye( p.n ) - 2 * p.Z * p.B_I' * ( ( p.B_V * p.Z * p.B_I' ) \ p.B_V );
                end
                while norm( p.v - p.v_old ) >= p.tol_SLV
                    p.v_old = p.v;
                    p.b( p.pos_D ) = diodeScat( p.a( p.pos_D ) , p.Z( p.pos_D , p.pos_D ) , p.P( p.pos_D , : ) );
                    p.b( p.pos_Dser ) = diodeScat( p.a( p.pos_Dser ) , p.Z( p.pos_Dser , p.pos_Dser ) , p.P( p.pos_Dser , : ) );
                    p.a = p.S * p.b;
                    p.v = 0.5 * ( p.a + p.b );
                end
                p.i = 0.5 * ( p.a - p.b ) ./ diag( p.Z );
                p.R_th( p.pos_D ) = diodeRefPortRes( p.v( p.pos_D ) , p.i( p.pos_D ) , p.P( p.pos_D , : ) );
                p.R_th( p.pos_Dser ) = diodeRefPortRes( p.v( p.pos_Dser ) , p.i( p.pos_Dser ) , p.P( p.pos_Dser , : ) );
                out( ii ) = p.Volume * sum( ( p.a( p.O( : , 1 ) ) + p.b( p.O( : , 1 ) ) ) .* p.O( : , 2 ) ) / 2;
                p.v_old = p.v + p.tol_SLV;
            end   
        end

    end
    
end