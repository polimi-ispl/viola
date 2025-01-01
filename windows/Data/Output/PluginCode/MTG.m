classdef MTG < audioPlugin

    properties
        f_s = 48000;
        x_1 = 0.5;
        x_2 = 0.5;
        x_3 = 0.5;
        x_4 = 0.5;
        x_5 = 0.5;
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
                'DisplayName' , 'Bass (P2)' , ...
                'DisplayNameLocation' , 'above' , ...
                'Style' , 'rotaryknob' , ...
                'Layout' , [ 4 2 ] , ...
                'Mapping' , { 'lin' , 0 , 1 } ) , ...
            audioPluginParameter( 'x_3' , ...
                'DisplayName' , 'Mid (P3)' , ...
                'DisplayNameLocation' , 'above' , ...
                'Style' , 'rotaryknob' , ...
                'Layout' , [ 7 1 ] , ...
                'Mapping' , { 'lin' , 0 , 1 } ) , ...
            audioPluginParameter( 'x_4' , ...
                'DisplayName' , 'Treble (P4)' , ...
                'DisplayNameLocation' , 'above' , ...
                'Style' , 'rotaryknob' , ...
                'Layout' , [ 7 2 ] , ...
                'Mapping' , { 'lin' , 0 , 1 } ) , ...
            audioPluginParameter( 'x_5' , ...
                'DisplayName' , 'Level (P5)' , ...
                'DisplayNameLocation' , 'above' , ...
                'Style' , 'rotaryknob' , ...
                'Layout' , [ 10 1 ] , ...
                'Mapping' , { 'lin' , 0 , 1 } ) , ...
            audioPluginParameter( 'Volume' , ...
                'DisplayName' , 'Volume' , ...
                'DisplayNameLocation' , 'above' , ...
                'Style' , 'rotaryknob' , ...
                'Layout' , [ 4 4 ] , ... 
                'Mapping' , { 'lin' , 0 , 2 } ) , ...
            audioPluginParameter( 'Enable' , ...
                'Style' , 'vrocker' , ...
                'DisplayNameLocation' , 'none' , ...
                'Layout' , [ 7 4 ] , ... 
                'Mapping' , { 'enum' , 'OFF' , 'ON' } ) , ...
            audioPluginGridLayout( 'RowHeight' , [ 30 10 20 150 10 20 150 10 20 150 10 ] , ...
                'ColumnWidth' , [ 150 150 10 150 ] , ...
                'Padding' , [ 10 10 10 10 ] , ...
                'RowSpacing' , 0 , ...
                'ColumnSpacing' , 0 ) , ...
            'BackgroundImage' , 'background.png' , ...
            'PluginName' , 'MTG' , ...
            'VendorName' , 'ISPL' , ...
            'VendorVersion' , '1.0.0' , ...
            'InputChannels' , 1 , ...
            'OutputChannels' , 1 );
    end

    properties ( Access = private )
        n;
        pos_Vin = [ 12 ];
        pos_V = [ 17 ];
        pos_R = [ 1 2 5 6 7 11 14 15 20 21 22 23 25 26 29 30 32 34 35 36 37 ];
        pos_C = [ 3 4 8 9 10 13 16 18 19 27 28 31 33 ];
        pos_Dap = [ 24 ];
        B_V; B_I;
        P; O;
        Z; S; 
        a; b;
        Ap; Up; Kp; H;
        alpha; beta; pos; order;
        Rp;
        R_tol = 10 ^ ( -6 );
    end

    methods
            
        function p = MTG
            s = coder.load( 'parsingResults.mat' );
            mna = coder.load( 'mnaData.mat' );
            p.n = length( s.typeOrder );
            p.B_V = s.B_V;
            p.B_I = s.B_I;
            p.Rp = s.potRes;
            p.P = s.params;
            p.O = s.outPath;
            p.Z = zeros( p.n );
            p.S = zeros( p.n );
            initializeWaves( p );
            setMnaData( p , mna );
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
        end

        function initializeWaves( p )
            p.a = zeros( p.n , 1 );
            p.b = zeros( p.n , 1 );
        end

        function setMnaData( p , mna )
            p.alpha = mna.alpha;
            p.beta = mna.beta;
            p.pos = mna.pos;
            A = mna.A;
            A( : , p.pos ) = [ ];
            A( p.alpha , : ) = [ ];
            p.Ap = A;
            U = mna.U;
            U( p.alpha , : ) = [ ];
            p.Up = U;
            K = mna.K;
            K( : , p.alpha ) = [ ];
            p.Kp = K;
            p.H = mna.H;  
            p.order = mna.order;
        end

        function initializeZ( p )
            p.Z( p.pos_Vin , p.pos_Vin ) = diag( p.P( p.pos_Vin , 1 ) );
            p.Z( p.pos_V , p.pos_V ) = diag( p.P( p.pos_V , 2 ) );
            p.Z( p.pos_R , p.pos_R ) = diag( p.P( p.pos_R , 1 ) );
            p.Z( p.pos_C , p.pos_C ) = diag( 1 ./ ( 2 * p.P( p.pos_C , 1 ) * p.f_s ) );
        end

        function updateP1( p )
            p.Z( 15 , 15 ) = p.x_1 * p.Rp( 1 ) + p.R_tol;
            p.Z( 30 , 30 ) = ( 1 - p.x_1 ) * p.Rp( 1 ) + p.R_tol;
        end

        function updateP2( p )
            p.Z( 23 , 23 ) = 0.0125 * ( 81 ^ p.x_2 - 1 ) * p.Rp( 2 ) + p.R_tol;
            p.Z( 21 , 21 ) = 1.0125 * ( 1 - 81 ^ ( p.x_2 - 1 ) ) * p.Rp( 2 ) + p.R_tol;
        end

        function updateP3( p )
            p.Z( 1 , 1 ) = 0.0125 * ( 81 ^ p.x_3 - 1 ) * p.Rp( 3 ) + p.R_tol;
            p.Z( 34 , 34 ) = 1.0125 * ( 1 - 81 ^ ( p.x_3 - 1 ) ) * p.Rp( 3 ) + p.R_tol;
        end

        function updateP4( p )
            p.Z( 20 , 20 ) = 0.0125 * ( 81 ^ p.x_4 - 1 ) * p.Rp( 4 ) + p.R_tol;
            p.Z( 26 , 26 ) = 1.0125 * ( 1 - 81 ^ ( p.x_4 - 1 ) ) * p.Rp( 4 ) + p.R_tol;
        end

        function updateP5( p )
            p.Z( 22 , 22 ) = p.x_5 * p.Rp( 5 ) + p.R_tol;
            p.Z( 7 , 7 ) = ( 1 - p.x_5 ) * p.Rp( 5 ) + p.R_tol;
        end

        function updateS( p )
            temp = diag( p.Z );
            Zp = diag( temp( p.order , 1 ) );
            Zp( p.pos , : ) = [ ];
            Zp( : , p.pos ) = [ ];
            Y_n_inv = inv( p.Ap * inv( Zp ) * p.Ap' );
            Z_n = Y_n_inv * ( eye( size( p.Ap , 1 ) ) + p.Up * inv( p.H - p.Kp * Y_n_inv * p.Up ) * p.Kp * Y_n_inv );
            p.Z( p.pos_Dap , p.pos_Dap ) = Z_n( p.beta , p.beta );
            p.S = eye( p.n ) - 2 * p.Z * p.B_I' * ( ( p.B_V * p.Z * p.B_I' ) \ p.B_V );
        end

        function out = processBlock( p , in )
            blockSize = size( in , 1 );
            out = zeros( blockSize , 1 );
            for ii = 1 : blockSize
                p.b( p.pos_Vin ) = in( ii );
                p.b( p.pos_V ) = p.P( p.pos_V , 1 );
                p.b( p.pos_R ) = 0;
                p.b( p.pos_C ) = p.a( p.pos_C );
                p.b( p.pos_Dap ) = antiExtSchockleyDiodeScat( p.S( p.pos_Dap , : ) * p.b , p.Z( p.pos_Dap , p.pos_Dap ) , p.P( p.pos_Dap , 1 ) , p.P( p.pos_Dap , 2 ) , p.P( p.pos_Dap , 3 ) , p.P( p.pos_Dap , 4 ) , p.P( p.pos_Dap , 5 ) );
                p.a = p.S * p.b;
                out( ii ) = p.Volume * sum( ( p.a( p.O( : , 1 ) ) + p.b( p.O( : , 1 ) ) ) .* p.O( : , 2 ) ) / 2;
            end   
        end

    end
    
end