classdef DEMO < audioPlugin

    properties
        f_s = 48000;
        x_1 = 0.5;
        Volume = 1;
        Enable = 'ON';
    end

    properties ( Constant )
        PluginInterface = audioPluginInterface( ...
            audioPluginParameter( 'x_1' , ...
                'DisplayName' , 'LEVEL (P1)' , ...
                'DisplayNameLocation' , 'above' , ...
                'Style' , 'rotaryknob' , ...
                'Layout' , [ 4 1 ] , ...
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
            'PluginName' , 'DEMO' , ...
            'VendorName' , 'ISPL' , ...
            'VendorVersion' , '1.0.0' , ...
            'InputChannels' , 1 , ...
            'OutputChannels' , 1 );
    end

    properties ( Access = private )
        n;
        pos_Vin = [ 1 ];
        pos_R = [ 2 ];
        pos_C = [ 3 ];
        pos_D = [ 4 ];
        B;
        P; O;
        Z; S; 
        a; b;
        Ap;
        alpha; beta; pos; order;
        Rp;
        R_tol = 10 ^ ( -6 );
    end

    methods
            
        function p = DEMO
            s = coder.load( 'parsingResults.mat' );
            mna = coder.load( 'mnaData.mat' );
            p.n = length( s.typeOrder );
            p.B = s.B;
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

        function set.Enable( p , state )
            p.Enable = state;
        end

        function set.Volume( p , value )
            p.Volume = value;
        end

        function initializePots( p )
            updateP1( p );
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
            p.order = mna.order;
        end

        function initializeZ( p )
            p.Z( p.pos_Vin , p.pos_Vin ) = diag( p.P( p.pos_Vin , 1 ) );
            p.Z( p.pos_R , p.pos_R ) = diag( p.P( p.pos_R , 1 ) );
            p.Z( p.pos_C , p.pos_C ) = diag( 1 ./ ( 2 * p.P( p.pos_C , 1 ) * p.f_s ) );
        end

        function updateP1( p )
            p.Z( 2 , 2 ) = p.x_1 * p.Rp( 1 ) + p.R_tol;
        end

        function updateS( p )
            temp = diag( p.Z );
            Zp = diag( temp( p.order , 1 ) );
            Zp( p.pos , : ) = [ ];
            Zp( : , p.pos ) = [ ];
            Z_n = inv( p.Ap * inv( Zp ) * p.Ap' );
            p.Z( p.pos_D , p.pos_D ) = Z_n( p.beta , p.beta );
            p.S = eye( p.n ) - 2 * p.Z * p.B' * ( ( p.B * p.Z * p.B' ) \ p.B );
        end

        function out = processBlock( p , in )
            blockSize = size( in , 1 );
            out = zeros( blockSize , 1 );
            for ii = 1 : blockSize
                p.b( p.pos_Vin ) = in( ii );
                p.b( p.pos_R ) = 0;
                p.b( p.pos_C ) = p.a( p.pos_C );
                p.b( p.pos_D ) = extendedSchockleyDiodeScat( p.S( p.pos_D , : ) * p.b , p.Z( p.pos_D , p.pos_D ) , p.P( p.pos_D , 1 ) , p.P( p.pos_D , 2 ) , p.P( p.pos_D , 3 ) , p.P( p.pos_D , 4 ) , p.P( p.pos_D , 5 ) );
                p.a = p.S * p.b;
                out( ii ) = p.Volume * sum( ( p.a( p.O( : , 1 ) ) + p.b( p.O( : , 1 ) ) ) .* p.O( : , 2 ) ) / 2;
            end   
        end

    end
    
end