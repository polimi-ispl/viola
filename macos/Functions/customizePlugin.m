function customizePlugin( circuitClass , pluginCode , pluginName , potsData , typeOrder , potLabels , Q , B )
    disp("Generating the audio plug-in...")

    [ template , class ] = chooseSourceCode( circuitClass );
    file = fread( fopen( template , "r" ) , "*char" )';
    nPots = size( potsData , 1 );
    file = customName( file , pluginCode );
    file = potParams( file , nPots );
    file = createGUI( file , nPots , potLabels , pluginName );
    file = potInitSet( file , potsData , class );
    file = getUpFuncs( file , potsData );
    [ file , scatMatExpr ] = setMatrices( file , Q , B );
    file = setTypeVecs( file , typeOrder );
    file = linearRefScat( file , typeOrder );
    if strcmp( circuitClass , 'one_non_lin' ) | strcmp( circuitClass , 'one_non_lin_opamp')
        file = nlPosition( file , typeOrder );
        file = nlScatStage( file , typeOrder );
    elseif strcmp( circuitClass , 'non_lin' ) | strcmp( circuitClass , 'non_lin_opamp' )
	file = nonLinearImpInit( file , typeOrder );
        file = stdSIM ( file , typeOrder );
        file = DSR( file , scatMatExpr , typeOrder );
    end
    fprintf( fopen( "Data/Output/PluginCode/" + pluginCode + ".m" , "w" ) , "%s" , file );
end

function [ template , class ] = chooseSourceCode( circuitClass )
    if strcmp( circuitClass , 'lin' ) |  strcmp( circuitClass , 'lin_opamp' )
        template = "LinearPluginTemplate.txt";
        class = "lin";
    elseif strcmp( circuitClass , 'one_non_lin' ) |  strcmp( circuitClass , 'one_non_lin_opamp' )
        template = "OneNonLinearPluginTemplate.txt";
        class = "one_non_lin";
    elseif strcmp( circuitClass , 'non_lin' ) |  strcmp( circuitClass , 'non_lin_opamp' )
        template = "NonLinearPluginTemplate.txt";
        class = "non_lin";
    end
end

function [ file ] = customName( f , pluginCode )
    old = "TemplateMonoPlugin";
    new = pluginCode;
    file = stringReplace( f , old , new );
end

function [ file , scatMatExpr ] = setMatrices( f , Q , B )
    b12 = blanks( 12 );
    nl = newline;
    old1 = "% CIRCUIT MATRICES DECLARATION";
    old2 = "% CIRCUIT MATRICES DEFINITION";
    old3 = "% SCATTERING MATRIX FUNCTION";
    if isscalar( fieldnames( Q ) )
        if size( Q.Q , 1 ) < size( B.B )
            new1 = "Q;";
            new2 = "p.Q = s.Q;";
            new3 = "2 * p.Q' * ( ( p.Q * ( Z \ p.Q' ) ) \ p.Q ) / p.Z - eye( p.n );";
        else
            new1 = "B;";
            new2 = "p.B = s.B;";
            new3 = "eye( p.n ) - 2 * p.Z * p.B' * ( ( p.B * p.Z * p.B' ) \ p.B );";
        end
    else
        if size( Q.Q_V , 1 ) < size( B.B_V )
            new1 = "Q_V; Q_I;";
            new2 = [ "p.Q_V = s.Q_V;" , nl , b12 , "p.Q_I = s.Q_I;" ];
            new3 = "2 * p.Q_V' * ( ( p.Q_I * ( Z \ p.Q_V' ) ) \ p.Q_I ) / p.Z - eye( p.n );";
        else
            new1 = "B_V; B_I;";
            new2 = [ "p.B_V = s.B_V;" , nl , b12 , "p.B_I = s.B_I;" ];
            new3 = "eye( p.n ) - 2 * p.Z * p.B_I' * ( ( p.B_V * p.Z * p.B_I' ) \ p.B_V );";
        end
    end
    scatMatExpr = new3;
    f = stringReplace( f , old1 , new1 );
    f = stringReplace( f , old2 , new2 );
    file = stringReplace( f , old3 , new3 );
end

function [ file ] = potParams( f , nPots )
    b8 = blanks( 8 );
    nl = newline;
    old = "% POTENTIOMETERS PARAMETER";
    new = strings( 1 , 3 * nPots );
    for ii = 1 : nPots 
        parString = "x_" + num2str( ii ) + " = 0.5;";
        new( 3 * ii - 2 : 3 * ii ) = [ b8 , parString , nl ];
    end
    new( 1 ) = [ ];
    new( end ) = [ ];
    file = stringReplace( f , old , new );
end

function [ file ] = potInitSet( f , potsData , class )
    nPots = size( potsData , 1 );
    b8 = blanks( 8 );
    b12 = blanks( 12 );
    nl = newline;
    old1 = "% POTENTIOMETERS SETTER";
    old2 = "% POTENTIOMETERS INITIALIZATION";
    if strcmp( class , 'lin' ) | strcmp( class , 'one_non_lin' )
        updateS = [ b12 , "updateS( p );" , nl ];
    else
        updateS = strings( 1 , 3 );
    end
    new1 = strings( 1 , 16 * nPots );
    new2 = strings( 1 , 3 * nPots );
    for ii = 1 : nPots
        N = num2str( ii );
        funcString = [ b8 , "function set.x_" + N + "( p , value )" , nl ];
        setString = [ b12 , "p.x_" + N + " = value;" , nl ];
        updateString = [ b12 , "updateP" + N + "( p );" , nl ];
        endString = [ b8 , "end" , nl , nl ];
        new1( 16 * ii - 15 : 16 * ii ) = [ funcString , setString , updateString , updateS , endString ];
        new2( 3 * ii - 2 : 3 * ii ) = updateString;
    end
    new1( 1 ) = [ ];
    new1( end - 1 : end ) = [ ];
    new2( 1 ) = [ ];
    new2( end ) = [ ];
    f = stringReplace( f , old1 , new1 );
    file = stringReplace( f , old2 , new2 );
end

function [ file ] = getUpFuncs( f , potsData )
    nPots = size( potsData , 1 );
    b8 = blanks( 8 );
    b12 = blanks( 12 );
    nl = newline;
    old = "% POTENTIOMETERS UPDATER";
    new = strings( 1 , 10 * nPots );
    for ii = 1 : nPots
        N = num2str( ii );
        funcString = [ b8 , "function updateP" + N + "( p )" , nl ];
        X = potsData( ii , 1 );
        Y = potsData( ii , 2 );
        if X == 1
            m = num2str( potsData( ii , 4 ) );
            if Y == 1
                upFunc = "p.Z( " + m + " , " + m + " ) = p.x_" + N + " * p.Rp( " + N + " ) + p.R_tol;";
            elseif Y == 2
                upFunc = "p.Z( " + m + " , " + m + " ) = 0.0125 * ( 81 ^ p.x_" + N + " - 1 ) * p.Rp( " + N + " ) + p.R_tol;";
            else 
                upFunc = "p.Z( " + m + " , " + m + " ) = 0.25 * log( 1 + p.x_" + N + " / 0.0125 ) * p.Rp( " + N + " ) / log( 3 ) + p.R_tol;";
            end
        elseif X == 2
            m = num2str( potsData( ii , 4 ) );
            if Y == 1
                upFunc = "p.Z( " + m + " , " + m + " ) = ( 1 - p.x_" + N + " ) * p.Rp( " + N + " ) + p.R_tol;";
            elseif Y == 2
                upFunc = "p.Z( " + m + " , " + m + " ) = 1.0125 * ( 1 - 81 ^ ( p.x_" + N + " - 1 ) ) * p.Rp( " + N + " ) + p.R_tol;";
            else
                upFunc = "p.Z( " + m + " , " + m + " ) = 0.25 * log( 1.0125 / ( p.x_" + N + " + 0.0125 ) ) * p.Rp( " + N + " ) / log( 3 ) + p.R_tol;";
            end
        else
            m = num2str( potsData( ii , 4 ) );
            p = num2str( potsData( ii , 5 ) );
            if Y == 1               
                upFunc = "p.Z( " + m + " , " + m + " ) = p.x_" + N + " * p.Rp( " + N + " ) + p.R_tol;" + nl + b12 + ...
                         "p.Z( " + p + " , " + p + " ) = ( 1 - p.x_" + N + " ) * p.Rp( " + N + " ) + p.R_tol;";
            elseif Y == 2
                upFunc = "p.Z( " + m + " , " + m + " ) = 0.0125 * ( 81 ^ p.x_" + N + " - 1 ) * p.Rp( " + N + " ) + p.R_tol;" + nl + b12 + ...
                         "p.Z( " + p + " , " + p + " ) = 1.0125 * ( 1 - 81 ^ ( p.x_" + N + " - 1 ) ) * p.Rp( " + N + " ) + p.R_tol;";
            else
                upFunc = "p.Z( " + m + " , " + m + " ) = 0.25 * log( 1 + p.x_" + N + " / 0.0125 ) * p.Rp( " + N + " ) / log( 3 ) + p.R_tol;" + nl + b12 + ...
                         "p.Z( " + p + " , " + p + " ) = 0.25 * log( 1.0125 / ( p.x_" + N + " + 0.0125 ) ) * p.Rp( " + N + " ) / log( 3 ) + p.R_tol;";
            end
        end
        upString = [ b12 , upFunc , nl ];
        endString = [ b8 , "end" , nl , nl ];
        new( 10 * ii - 9 : 10 * ii ) = [ funcString , upString , endString ];
    end
    new( 1 ) = [ ];
    new( end - 1 : end ) = [ ];
    file = stringReplace( f , old , new );
end

function [ file ] = createGUI( f , nPots , potLabels , pluginName )
    potSize = 150;
    b12 = blanks( 12 );
    b16 = blanks( 16 );
    nl = newline;
    len = length( potLabels );
    if len < nPots
        aux = strings( 1 , nPots - len );
        potLabels = [ potLabels , aux ];
    end
    if nPots == 0
        nRows = 2;
        nCols = 1;
    elseif nPots == 1 || nPots == 2
        nRows = 2;
        nCols = 2;  
    else
        if mod( sqrt( nPots ) , 1 ) == 0
            nRows = sqrt( nPots );
            nCols = sqrt( nPots ) + 1;
        else
            nRows = floor( sqrt( nPots ) ) + 1;
            nCols = ceil( nPots / nRows ) + 1;
        end
    end
    generateBackground( nRows , nCols , potSize , pluginName );
    old1 = "% POTENTIOMETERS GUI";
    old2 = "% VOLUME LAYOUT";
    old3 = "% BYPASS LAYOUT";
    old4 = "% GRID LAYOUT";
    new1 = strings( 1 , 18 * nPots );
    for ii = 1 : nPots
        row = 3 * floor( ( ii - 1 ) / ( nCols - 1 ) ) + 4;
        col = mod( ii - 1 , nCols - 1 ) + 1;
        if potLabels( ii ) ~= ""
            lbl = potLabels( ii ) + " ";
        else
            lbl = "";
        end
        paramString = [ b12 , "audioPluginParameter( 'x_" + num2str( ii ) + "' , ..." , nl ];
        dispString = [ b16 , "'DisplayName' , '" + lbl + "(P" + num2str( ii ) + ")' , ..." , nl ];
        hideString = [ b16 , "'DisplayNameLocation' , 'above' , ..." , nl ];
        styleString = [ b16 , "'Style' , 'rotaryknob' , ..." , nl ];
        layoutString = [ b16 , "'Layout' , [ " + num2str( row ) + " " + num2str( col ) + " ] , ..." , nl ];
        mapString = [ b16 , "'Mapping' , { 'lin' , 0 , 1 } ) , ..." , nl ];
        new1( 18 * ii - 17 : 18 * ii ) = [ paramString , dispString , hideString , styleString , layoutString , mapString ];
    end
    new1( 1 ) = [ ];
    new1( end ) = [ ];
    new2 = "[ 4 " + num2str( nCols + 1 ) + " ]";
    new3 = "[ 7 " + num2str( nCols + 1 ) + " ]";
    rowString = strings( 1 , 3 * nRows );
    for ii = 1 : nRows
        rowString( 3 * ii - 2 : 3 * ii ) = [ "10 20 " , num2str( potSize ) , " " ];
    end
    rowString( end ) = [ ];
    colString = strings( 1 , 2 * nCols );
    for ii = 1 : nCols
        colString( 2 * ii - 1 : 2 * ii ) = [ num2str( potSize ) , " " ];
    end
    colString( end ) = [ ];
    new4 = [ "audioPluginGridLayout( 'RowHeight' , [ 30 " , rowString , " 10 ] , ..." , nl , ...
             b16 , "'ColumnWidth' , [ " , colString( 1 : end - 1 ) , "10 " , colString( end ) , " ] , ..." , nl , ...
             b16 , "'Padding' , [ 10 10 10 10 ] , ..." , nl , ...
             b16 , "'RowSpacing' , 0 , ..." , nl , ...
             b16 , "'ColumnSpacing' , 0 ) , ..." ];
    f = stringReplace( f , old1 , new1 );
    f = stringReplace( f , old2 , new2 );
    f = stringReplace( f , old3 , new3 );
    file = stringReplace( f , old4 , new4 );
end

function generateBackground( nRows , nCols , potSize , pluginName )
    colorX = [ 0.8 ; 0.6 ; 1 ];
    xHeight = nRows * ( potSize + 30 );
    xWidth = ( nCols - 1 ) * potSize;
    X = ones( xHeight , xWidth , 3 );
    for ii = 1 : 3
        X( : , : , ii ) = colorX( ii ) * X( : , : , ii );
    end
    colorY = [ 0.8 ; 0.6 ; 1 ];
    yHeight = xHeight;
    yWidth = potSize;
    Y = ones( yHeight , yWidth , 3 );
    for ii = 1 : 3
        Y( : , : , ii ) = colorY( ii ) * Y( : , : , ii );
    end
    colorU = [ 0.898 ; 0.8 ; 1 ];
    uHeight = 30;
    uWidth =  10 + size( X , 2 ) + size( Y , 2 );
    U = ones( uHeight , uWidth , 3 );
    for ii = 1 : 3
        U( : , : , ii ) = colorU( ii ) * U( : , : , ii );
    end
    totHeight = 30 + size( X , 1 ) + size( U , 1 );
    totWidth = 20 + size( U , 2 );
    Z = zeros( totHeight , totWidth , 3 );
    Z( 11 : 10 + size( U , 1 ) , 11 : 10 + size( U , 2 ) , : ) = U;
    Z( 51 : 50 + size( X , 1 ) , 11 : 10 + size( X , 2 ) , : ) = X;
    Z( 51 : 50 + size( Y , 1 ) , 21 + size( X , 2 ) : 20 + size( X , 2 ) + size( Y , 2 ) , : ) = Y;
    posText = [ totWidth / 2 , 25 ];
    Z = insertText( Z , posText , pluginName , FontSize=16 , BoxOpacity = 0 , TextColor = "black" , AnchorPoint="Center" );
    logo = im2double( imread( 'Data/Input/Assets/logo.png' ) );
    logoHeight = size( logo , 1 );
    logoWidth = size( logo , 2 );
    posLogoSx = totWidth - logoWidth - 15;
    posLogoUp = totHeight - logoHeight - 15;
    Z( posLogoUp : posLogoUp + logoHeight - 1 , posLogoSx : posLogoSx + logoWidth - 1 , : ) = logo;
    imwrite( Z , "Data/Output/Assets/background.png" );
end

function [ file ] = setTypeVecs( f , typeOrder )
    b8 = blanks( 8 );
    nl = newline;
    uniqueTypes = unique( typeOrder );
    old = "% TYPE VECTORS";
    new = strings( 1, 4 * length( uniqueTypes ) );
    for ii = 1 : length( uniqueTypes )
        switch uniqueTypes( ii )
            case 1
                typeStr = "pos_Vin = ";
            case 2
                typeStr = "pos_V = ";
            case 3
                typeStr = "pos_Iin = ";
            case 4
                typeStr = "pos_I = ";
            case 5
                typeStr = "pos_R = ";
            case 6 
                typeStr = "pos_C = ";
            case 7
                typeStr = "pos_L = ";
            case 8
                typeStr = "pos_D = ";
            case 9 
                typeStr = "pos_Dser = ";
            case 10
                typeStr = "pos_Dap = ";
        end
        posVec = find( typeOrder == uniqueTypes( ii ) )';
        new( 4 * ii - 3 : 4 * ii ) = [ b8 , typeStr , "[ " + sprintf( '%d ' , posVec ) + "];" , nl ];
    end
    new( : , 1 ) = [ ];
    new( end) = [ ];
    file = stringReplace( f , old , new );
end

function [ file ] = linearRefScat( f , typeOrder )
    b12 = blanks( 12 );
    b16 = blanks( 16 );
    nl = newline;
    uniqueLinTypes = unique( typeOrder( typeOrder < 8 ) );
    old1 = "% LINEAR ELEMENTS SCATTERING";
    old2 = "% LINEAR IMPEDANCES INITIALIZATION";
    new1 = strings( 1 , 3 * length( uniqueLinTypes ) );
    new2 = strings( 1 , 3 * length( uniqueLinTypes ) );
    for ii = 1 : length( uniqueLinTypes )
        switch uniqueLinTypes( ii )
            case 1
                scatString = "p.b( p.pos_Vin ) = in( ii );";
                refString = "p.Z( p.pos_Vin , p.pos_Vin ) = diag( p.P( p.pos_Vin , 1 ) );";
            case 2
                scatString = "p.b( p.pos_V ) = p.P( p.pos_V , 1 );";
                refString = "p.Z( p.pos_V , p.pos_V ) = diag( p.P( p.pos_V , 2 ) );";
            case 3
                scatString = "p.b( p.pos_Iin ) = in( ii );";
                refString = "p.Z( p.pos_Iin , p.pos_Iin ) = diag( p.P( p.pos_Iin , 1 ) );";
            case 4
                scatString = "p.b( p.pos_I ) = p.P( p.pos_I , 1 );";
                refString = "p.Z( p.pos_I , p.pos_I ) = diag( p.P( p.pos_I , 2 ) );";
            case 5
                scatString = "p.b( p.pos_R ) = 0;";
                refString = "p.Z( p.pos_R , p.pos_R ) = diag( p.P( p.pos_R , 1 ) );";
            case 6 
                scatString = "p.b( p.pos_C ) = p.a( p.pos_C );";
                refString = "p.Z( p.pos_C , p.pos_C ) = diag( 1 ./ ( 2 * p.P( p.pos_C , 1 ) * p.f_s ) );";
            case 7
                scatString = "p.b( p.pos_L ) = - p.a( p.pos_L );"; 
                refString = "p.Z( p.pos_L , p.pos_L ) = diag( 2 * p.P( p.pos_L , 1 ) * p.f_s );";
        end
        new1( 3 * ii - 2 : 3 * ii ) = [ b16 , scatString , nl ];
        new2( 3 * ii - 2 : 3 * ii ) = [ b12 , refString , nl ];
    end
    new1( 1 ) = [ ];
    new1( end ) = [ ];
    new2( 1 ) = [ ];
    new2( end ) = [ ];
    f = stringReplace( f , old1 , new1 );
    file = stringReplace( f , old2 , new2 );
end

function [ file ] = nonLinearImpInit( f , typeOrder )
    b12 = blanks( 12 );
    nl = newline;
    uniqueNonLinTypes = unique( typeOrder( typeOrder >= 8 ) );
    old = "% NONLINEAR IMPEDANCES INITIALIZATION";
    new = strings( 1 , 3 * length( uniqueNonLinTypes ) );
    for ii = 1 : length( uniqueNonLinTypes )
        switch uniqueNonLinTypes( ii )
            case 8
                refString = "p.Z( p.pos_D , p.pos_D ) = eye( length( p.pos_D ) );";
            case 9
                refString = "p.Z( p.pos_Dser , p.pos_Dser ) = eye( length( p.pos_Dser ) );";
            case 10
                refString = "p.Z( p.pos_Dap , p.pos_Dap ) = eye( length( p.pos_Dap ) );";
        end
        new( 3 * ii - 2 : 3 * ii ) = [ b12 , refString , nl ];
    end
    new( 1 ) = [ ];
    new( end ) = [ ];
    file = stringReplace( f , old , new );
end

function [ file ] = stdSIM( f , typeOrder )
    b16 = blanks( 16 );
    b20 = blanks( 20 );
    nl = newline;
    old = '% ITERATIVE SOLVER';
    dsrString = "% DSR";
    cycleInitString = [ b16 , "while norm( p.v - p.v_old ) >= p.tol_SLV" , nl ];
    oldSigString = [ b20 , "p.v_old = p.v;" , nl ];
    scatString = strings( 0 );
    if ismember( 8 , typeOrder )
        scatString = [ scatString , b20 , "p.b( p.pos_D ) = diodeScat( p.a( p.pos_D ) , p.Z( p.pos_D , p.pos_D ) , p.P( p.pos_D , : ) );" , nl ];
    end
    if ismember( 9 , typeOrder )
        scatString = [ scatString , b20 , "p.b( p.pos_Dser ) = diodeScat( p.a( p.pos_Dser ) , p.Z( p.pos_Dser , p.pos_Dser ) , p.P( p.pos_Dser , : ) );" , nl ];
    end
    if ismember( 10 , typeOrder )
        scatString = [ scatString , b20 , "p.b( p.pos_Dap ) = antiDiodeScat( p.a( p.pos_Dap ) , p.Z( p.pos_Dap , p.pos_Dap ) , p.P( p.pos_Dap , : ) );" , nl ];
    end
    updateString = [ b20 , "p.a = p.S * p.b;" , nl ];
    voltString = [ b20 , "p.v = 0.5 * ( p.a + p.b );" , nl ];
    endString = [ b16 , "end" , nl ];
    currString = [ b16 , "p.i = 0.5 * ( p.a - p.b ) ./ diag( p.Z );" , nl ];
    refResString = strings( 0 );
    if ismember( 8 , typeOrder )
        refResString = [ refResString , b16 , "p.R_th( p.pos_D ) = diodeRefPortRes( p.v( p.pos_D ) , p.i( p.pos_D ) , p.P( p.pos_D , : ) );" , nl ];
    end
    if ismember( 9 , typeOrder )
        refResString = [ refResString , b16 , "p.R_th( p.pos_Dser ) = diodeRefPortRes( p.v( p.pos_Dser ) , p.i( p.pos_Dser ) , p.P( p.pos_Dser , : ) );" , nl ];
    end
    if ismember( 10 , typeOrder )
        refResString = [ refResString , b16 , "p.R_th( p.pos_Dap ) = antiDiodeRefPortRes( p.v( p.pos_Dap ) , p.i( p.pos_Dap ) , p.P( p.pos_Dap , : ) );" , nl ];
    end
    new = [ dsrString , cycleInitString , oldSigString , scatString , updateString , voltString , endString , currString , refResString ];
    new( end ) = [ ];
    file = stringReplace( f , old , new );
end

function [ file ] = DSR( f , scatMatExpr , typeOrder )
    b16 = blanks( 16 );
    b20 = blanks( 20 );
    nl = newline;
    old = '% DSR';
    condString = strings( 0 );
    zUpdateString = strings( 0 );
    ifString = "if sum( [ ";
    if ismember( 8 , typeOrder )
        condString = [ condString , "sum( abs( diag( p.Z( p.pos_D , p.pos_D ) ) - p.R_th( p.pos_D ) ) ) " ];
        zUpdateString = [ zUpdateString , b20 , "p.Z( p.pos_D , p.pos_D ) = diag( p.R_th( p.pos_D ) );" , nl ];
    end
    if ismember( 9 , typeOrder )
        condString = [ condString , "sum( abs( diag( p.Z( p.pos_Dser , p.pos_Dser ) ) - p.R_th( p.pos_Dser ) ) ) " ];
        zUpdateString = [ zUpdateString , b20 , "p.Z( p.pos_Dser , p.pos_Dser ) = diag( p.R_th( p.pos_Dser ) );" , nl ];
    end
    if ismember( 10 , typeOrder )
        condString = [ condString , "sum( abs( diag( p.Z( p.pos_Dap , p.pos_Dap ) ) - p.R_th( p.pos_Dap ) ) ) " ];
        zUpdateString = [ zUpdateString , b20 , "p.Z( p.pos_Dap , p.pos_Dap ) = diag( p.R_th( p.pos_Dap ) );" , nl ];
    end
    condString = [ condString , "] ) >= p.tol_DSR" , nl ];
    sUpdateString = [ b20 , "p.S = " + scatMatExpr , nl ];
    endString = [ b16 , "end" , nl ];
    new = [ ifString , condString , zUpdateString , sUpdateString , endString ];
    file = stringReplace( f , old , new );
end

function file = nlScatStage( f , typeOrder )
    old = '% NONLINEAR ELEMENT SCATTERING';
    if ismember( 8 , typeOrder )
        new = "p.b( p.pos_D ) = extendedSchockleyDiodeScat( p.S( p.pos_D , : ) * p.b , p.Z( p.pos_D , p.pos_D ) , p.P( p.pos_D , 1 ) , p.P( p.pos_D , 2 ) , p.P( p.pos_D , 3 ) , p.P( p.pos_D , 4 ) , p.P( p.pos_D , 5 ) );";
    elseif ismember( 9 , typeOrder )
        new = "p.b( p.pos_Dser ) = extendedSchockleyDiodeScat( p.S( p.pos_Dser , : ) * p.b , p.Z( p.pos_Dser , p.pos_Dser ) , p.P( p.pos_Dser , 1 ) , p.P( p.pos_Dser , 2 ) , p.P( p.pos_Dser , 3 ) , p.P( p.pos_Dser , 4 ) , p.P( p.pos_Dser , 5 ) );";
    elseif ismember( 10 , typeOrder )
        new = "p.b( p.pos_Dap ) = antiExtSchockleyDiodeScat( p.S( p.pos_Dap , : ) * p.b , p.Z( p.pos_Dap , p.pos_Dap ) , p.P( p.pos_Dap , 1 ) , p.P( p.pos_Dap , 2 ) , p.P( p.pos_Dap , 3 ) , p.P( p.pos_Dap , 4 ) , p.P( p.pos_Dap , 5 ) );";
    end
    file = stringReplace( f , old , new );
end

function file = nlPosition( f , typeOrder )
    old = '% NONLINEAR POSITION';
    if ismember( 8 , typeOrder )
        new = "p.pos_D";
    elseif ismember( 9 , typeOrder )
        new = "p.pos_Dser";
    elseif ismember( 10 , typeOrder )
        new = "p.pos_Dap";
    end
    file = stringReplace( f , old , new );
end

function [ string ] = stringReplace( string , old , new )
    new = cellstr( new );
    new = horzcat( new{ : } );
    string = strrep( string , old , new );
end
