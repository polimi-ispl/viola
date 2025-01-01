classdef SBGEQ < audioPlugin

    properties
        f_s = 48000;
        x_1 = 0.5;
        x_2 = 0.5;
        x_3 = 0.5;
        x_4 = 0.5;
        x_5 = 0.5;
        x_6 = 0.5;
        x_7 = 0.5;
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
                'DisplayName' , '(P2)' , ...
                'DisplayNameLocation' , 'above' , ...
                'Style' , 'rotaryknob' , ...
                'Layout' , [ 4 2 ] , ...
                'Mapping' , { 'lin' , 0 , 1 } ) , ...
            audioPluginParameter( 'x_3' , ...
                'DisplayName' , '(P3)' , ...
                'DisplayNameLocation' , 'above' , ...
                'Style' , 'rotaryknob' , ...
                'Layout' , [ 4 3 ] , ...
                'Mapping' , { 'lin' , 0 , 1 } ) , ...
            audioPluginParameter( 'x_4' , ...
                'DisplayName' , '(P4)' , ...
                'DisplayNameLocation' , 'above' , ...
                'Style' , 'rotaryknob' , ...
                'Layout' , [ 7 1 ] , ...
                'Mapping' , { 'lin' , 0 , 1 } ) , ...
            audioPluginParameter( 'x_5' , ...
                'DisplayName' , '(P5)' , ...
                'DisplayNameLocation' , 'above' , ...
                'Style' , 'rotaryknob' , ...
                'Layout' , [ 7 2 ] , ...
                'Mapping' , { 'lin' , 0 , 1 } ) , ...
            audioPluginParameter( 'x_6' , ...
                'DisplayName' , '(P6)' , ...
                'DisplayNameLocation' , 'above' , ...
                'Style' , 'rotaryknob' , ...
                'Layout' , [ 7 3 ] , ...
                'Mapping' , { 'lin' , 0 , 1 } ) , ...
            audioPluginParameter( 'x_7' , ...
                'DisplayName' , '(P7)' , ...
                'DisplayNameLocation' , 'above' , ...
                'Style' , 'rotaryknob' , ...
                'Layout' , [ 10 1 ] , ...
                'Mapping' , { 'lin' , 0 , 1 } ) , ...
            audioPluginParameter( 'Volume' , ...
                'DisplayName' , 'Volume' , ...
                'DisplayNameLocation' , 'above' , ...
                'Style' , 'rotaryknob' , ...
                'Layout' , [ 4 5 ] , ... 
                'Mapping' , { 'lin' , 0 , 2 } ) , ...
            audioPluginParameter( 'Enable' , ...
                'Style' , 'vrocker' , ...
                'DisplayNameLocation' , 'none' , ...
                'Layout' , [ 7 5 ] , ... 
                'Mapping' , { 'enum' , 'OFF' , 'ON' } ) , ...
            audioPluginGridLayout( 'RowHeight' , [ 30 10 20 150 10 20 150 10 20 150 10 ] , ...
                'ColumnWidth' , [ 150 150 150 10 150 ] , ...
                'Padding' , [ 10 10 10 10 ] , ...
                'RowSpacing' , 0 , ...
                'ColumnSpacing' , 0 ) , ...
            'BackgroundImage' , 'background.png' , ...
            'PluginName' , 'SBGEQ' , ...
            'VendorName' , 'ISPL' , ...
            'VendorVersion' , '1.0.0' , ...
            'InputChannels' , 1 , ...
            'OutputChannels' , 1 );
    end

    properties ( Access = private )
        n;
        pos_Vin = [ 6 ];
        pos_R = [ 1 2 3 5 9 10 11 12 13 16 21 22 23 24 25 26 27 28 31 32 33 34 35 37 40 41 45 46 47 48 49 ];
        pos_C = [ 4 7 8 14 15 17 18 19 20 29 30 36 38 39 42 43 44 ];
        B_V; B_I;
        P; O;
        Z; S; 
        a; b;
        Rp;
        R_tol = 10 ^ ( -6 );
    end

    methods
            
        function p = SBGEQ
            s = coder.load( 'parsingResults.mat' );
            p.n = length( s.typeOrder );
            p.B_V = s.B_V;
            p.B_I = s.B_I;
            p.Rp = s.potRes;
            p.P = s.params;
            p.O = s.outPath;
            p.Z = zeros( p.n );
            p.S = zeros( p.n );
            initializeWaves( p );
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
            initializeWaves( p );
            updateS( p );
        end

        function set.x_1( p , value )
            p.x_1 = value;
            updateP1( p );
            updateS( p );
        end

        function set.x_2( p , value )
            p.x_2 = value;
            updateP2( p );
            updateS( p );
        end

        function set.x_3( p , value )
            p.x_3 = value;
            updateP3( p );
            updateS( p );
        end

        function set.x_4( p , value )
            p.x_4 = value;
            updateP4( p );
            updateS( p );
        end

        function set.x_5( p , value )
            p.x_5 = value;
            updateP5( p );
            updateS( p );
        end

        function set.x_6( p , value )
            p.x_6 = value;
            updateP6( p );
            updateS( p );
        end

        function set.x_7( p , value )
            p.x_7 = value;
            updateP7( p );
            updateS( p );
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
            updateP3( p );
            updateP4( p );
            updateP5( p );
            updateP6( p );
            updateP7( p );
        end

        function initializeWaves( p )
            p.a = zeros( p.n , 1 );
            p.b = zeros( p.n , 1 );
        end

        function initializeZ( p )
            p.Z( p.pos_Vin , p.pos_Vin ) = diag( p.P( p.pos_Vin , 1 ) );
            p.Z( p.pos_R , p.pos_R ) = diag( p.P( p.pos_R , 1 ) );
            p.Z( p.pos_C , p.pos_C ) = diag( 1 ./ ( 2 * p.P( p.pos_C , 1 ) * p.f_s ) );
        end

        function updateP1( p )
            p.Z( 5 , 5 ) = p.x_1 * p.Rp( 1 ) + p.R_tol;
        end

        function updateP2( p )
            p.Z( 10 , 10 ) = p.x_2 * p.Rp( 2 ) + p.R_tol;
            p.Z( 35 , 35 ) = ( 1 - p.x_2 ) * p.Rp( 2 ) + p.R_tol;
        end

        function updateP3( p )
            p.Z( 11 , 11 ) = p.x_3 * p.Rp( 3 ) + p.R_tol;
            p.Z( 37 , 37 ) = ( 1 - p.x_3 ) * p.Rp( 3 ) + p.R_tol;
        end

        function updateP4( p )
            p.Z( 32 , 32 ) = p.x_4 * p.Rp( 4 ) + p.R_tol;
            p.Z( 13 , 13 ) = ( 1 - p.x_4 ) * p.Rp( 4 ) + p.R_tol;
        end

        function updateP5( p )
            p.Z( 33 , 33 ) = p.x_5 * p.Rp( 5 ) + p.R_tol;
            p.Z( 40 , 40 ) = ( 1 - p.x_5 ) * p.Rp( 5 ) + p.R_tol;
        end

        function updateP6( p )
            p.Z( 12 , 12 ) = p.x_6 * p.Rp( 6 ) + p.R_tol;
            p.Z( 41 , 41 ) = ( 1 - p.x_6 ) * p.Rp( 6 ) + p.R_tol;
        end

        function updateP7( p )
            p.Z( 34 , 34 ) = p.x_7 * p.Rp( 7 ) + p.R_tol;
            p.Z( 16 , 16 ) = ( 1 - p.x_7 ) * p.Rp( 7 ) + p.R_tol;
        end

        function updateS( p )
            p.S = eye( p.n ) - 2 * p.Z * p.B_I' * ( ( p.B_V * p.Z * p.B_I' ) \ p.B_V );
        end

        function out = processBlock( p , in )
            blockSize = size( in , 1 );
            out = zeros( blockSize , 1 );
            for ii = 1 : blockSize
                p.b( p.pos_Vin ) = in( ii );
                p.b( p.pos_R ) = 0;
                p.b( p.pos_C ) = p.a( p.pos_C );
                p.a = p.S * p.b;
                out( ii ) = p.Volume * sum( ( p.a( p.O( : , 1 ) ) + p.b( p.O( : , 1 ) ) ) .* p.O( : , 2 ) ) / 2;
            end   
        end

    end
    
end