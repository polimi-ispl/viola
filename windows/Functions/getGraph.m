function [ Graph , outNode , tempChoice ] = getGraph( netData , types , outNode )
    if ~any( types == 'OA' )
        [ G , outNode ] = getUsualGraph( netData , outNode );
        Graph = struct( 'G' , G );
        if ~any( types == "D" ) && ~any( types == "Dser" ) && ~any( types == "Dap" )
            tempChoice = 'lin';
        elseif ( sum( types == "D" ) + sum( types == "Dser" ) + sum( types == "Dap" ) ) == 1
            tempChoice = 'one_non_lin';
            [ A , U , K , H , alpha , beta , pos , ids ] = getMnaData( G );
            save( "Data\Output\NetlistParsing\mnaData.mat" , "U" , "K" , "H" , "alpha" , "beta" );
            save( "Data\Output\NetlistParsing\mnaIds.mat" , "A" , "ids" , "pos" );
        else
            tempChoice = 'non_lin';
        end
    else
        [ G_V , G_I , G , outNode ] = getVoltCurrGraphs( netData , types , outNode );
        Graph = struct( 'G_V' , G_V , 'G_I' , G_I );
        if ~any( types == "D" ) && ~any( types == "Dser" ) && ~any( types == "Dap" )
            tempChoice = 'lin_opamp';
        elseif ( sum( types == "D" ) + sum( types == "Dser" ) + sum( types == "Dap" ) ) == 1
            tempChoice = 'one_non_lin_opamp';
            [ A , U , K , H , alpha , beta , pos , ids ] = getMnaData( G );
            save( "Data\Output\NetlistParsing\mnaData.mat" , "U" , "K" , "H" , "alpha" , "beta" );
            save( "Data\Output\NetlistParsing\mnaIds.mat" , "A" , "ids" , "pos" );
        else
            tempChoice = 'non_lin_opamp';
        end
    end
end

function [ G , outNode ] = getUsualGraph( netData , outNode )
    ids = netData( : , 1 );
    types = string( regexp( ids , '[A-Za-z]+' , 'match' ) );
    typeNums = extractTypeNums( types ); 
    nodes = str2double( string( regexp( netData( : , 2 : 3 ) , '[0-9]+' , 'match' ) ) );
    if ~isa( outNode , 'double' )
        outNode = str2double( string( regexp( outNode , '[0-9]+' , 'match' ) ) );
    end
    params = extractParams( netData , types );
    table_G = table( nodes + 1 , types , typeNums , ids , params , 'VariableNames' , { 'EndNodes' , 'Type' , 'TypeNumber' , 'ID' , 'Parameters' } );
    G = digraph( table_G );
end

function [ G_V , G_I , G , outNode ] = getVoltCurrGraphs( netData , types , outNode )
    [ netData_V , netData_I , netData_G , outNode ] = handleOpamps( netData , types , outNode );
    ids = netData_V( : , 1 );
    ids_G = netData_G( : , 1 );
    types = string( regexp( ids , '[A-Za-z]+' , 'match' ) );
    types_G = string( regexp( ids_G , '[A-Za-z]+' , 'match' ) );
    typeNums = extractTypeNums( types ); 
    nodes_V = str2double( string( regexp( netData_V( : , 2 : 3 ) , '[0-9]+' , 'match' ) ) );
    nodes_I = str2double( string( regexp( netData_I( : , 2 : 3 ) , '[0-9]+' , 'match' ) ) );
    nodes_G = str2double( string( regexp( netData_G( : , 2 : 3 ) , '[0-9]+' , 'match' ) ) );
    if min( nodes_V , [ ] , 'all' ) ~= 0
        deltaN = min( nodes_V , [ ] , 'all' );
        nodes_V = nodes_V - deltaN;
        outNode = outNode - deltaN;
    end
    if min( nodes_I , [ ] , 'all' ) ~= 0
        deltaN = min( nodes_I , [ ] , 'all' );
        nodes_I = nodes_I - deltaN;
    end
    params = extractParams( netData_V , types );
    table_G_V = table( nodes_V + 1 , types , typeNums , ids , params , 'VariableNames' , { 'EndNodes' , 'Type' , 'TypeNumber' , 'ID' , 'Parameters' } );
    table_G_I = table( nodes_I + 1 , types , typeNums , ids , params , 'VariableNames' , { 'EndNodes' , 'Type' , 'TypeNumber' , 'ID' , 'Parameters' } );
    table_G = table( nodes_G + 1 , types_G , ids_G , 'VariableNames' , { 'EndNodes' , 'Type' , 'ID' } );
    G_V = digraph( table_G_V );
    G_I = digraph( table_G_I );
    G = digraph( table_G );
end

function [ netData_V , netData_I , netData_G , outNode ] = handleOpamps( netData , types , outNode )
    negPins = netData( types == 'OA' , 2 );
    posPins = netData( types == 'OA' , 3 );
    outPins = netData( types == 'OA' , 4 );
    netData_G = netData( types ~= 'OA' , : );
    nullData = strings( length( negPins ) , size( netData , 2 ) );
    norData = strings( length( negPins ) , size( netData , 2 ) );
    for ii = 1 : length( negPins )
        nullData( ii , 1 ) = "NULL" + num2str( ii );
        nullData( ii , 2 : 3 ) = [ negPins( ii ) , posPins( ii ) ];
        norData( ii , 1 ) = "NOR" + num2str( ii );
        norData( ii , 2 : 3 ) = [ "0" , outPins( ii ) ];
    end
    netData_G = [ netData_G ; nullData ; norData ]; 
    netData_V = netData( types ~= 'OA' , : );
    netData_I = netData( types ~= 'OA' , : );
    for ii = 1 : length( negPins )
        netData_V( netData_V == negPins( ii ) ) = posPins( ii );
        netData_I( netData_I == outPins( ii ) ) = 0;
        if outNode == negPins( ii )
            outNode = posPins( ii );
        end
    end
    negPins = str2double( string( regexp( negPins , '[0-9]+' , 'match' ) ) );
    posPins = str2double( string( regexp( posPins , '[0-9]+' , 'match' ) ) );
    outPins = str2double( string( regexp( outPins , '[0-9]+' , 'match' ) ) );
    outNode = str2double( string( regexp( outNode , '[0-9]+' , 'match' ) ) );
    nodes_V = str2double( string( regexp( netData_V( : , 2 : 3 ) , '[0-9]+' , 'match' ) ) );
    nodes_I = str2double( string( regexp( netData_I( : , 2 : 3 ) , '[0-9]+' , 'match' ) ) );
    for ii = 1 : length( negPins )
        if negPins( ii ) > posPins( ii )
            nodes_V( nodes_V > negPins( ii ) ) = nodes_V( nodes_V > negPins( ii ) ) - 1;
            negPins( negPins > negPins( ii ) ) = negPins( negPins > negPins( ii ) ) - 1;
            posPins( posPins > negPins( ii ) ) = posPins( posPins > negPins( ii ) ) - 1;
            outNode( outNode > negPins( ii ) ) = outNode( outNode > negPins( ii ) ) - 1;
        elseif negPins( ii ) < posPins( ii )
            nodes_V( nodes_V < negPins( ii ) ) = nodes_V( nodes_V < negPins( ii ) ) + 1;
            negPins( negPins < negPins( ii ) ) = negPins( negPins < negPins( ii ) ) + 1;
            posPins( posPins < negPins( ii ) ) = posPins( posPins < negPins( ii ) ) + 1;
            outNode( outNode < negPins( ii ) ) = outNode( outNode < negPins( ii ) ) + 1;
        end
        if outPins( ii ) > 0
            nodes_I( nodes_I > outPins( ii ) ) = nodes_I( nodes_I > outPins( ii ) ) - 1;
            outPins( outPins > outPins( ii ) ) = outPins( outPins > outPins( ii ) ) - 1;
        end
    end
    netData_V( : , 2 : 3 ) = nodes_V;
    netData_I( : , 2 : 3 ) = nodes_I;
end

function [ params ] = extractParams( netData , types )
    nEl = length( types );
    params = zeros( nEl , 5 );
    for ii = 1 : nEl
        params( ii , : ) = extractElValues( types( ii ) , netData( ii , : ) );
    end
end

function [ values ] = extractElValues( type , elData )
    values = zeros( 1 , 5 );
    switch type
        case 'Vin'
            values( 1 ) = 10 ^ ( -9 );
        case 'V'
            values( 1 ) = eng2num( elData( 4 ) );
            values( 2 ) = 10 ^ ( -9 );
        case 'Iin'
            values( 1 ) = 10 ^ 9;
        case 'I'
            values( 1 ) = eng2num( elData( 4 ) );
            values( 2 ) = 10 ^ 9;
        case 'R'
            values( 1 ) = eng2num( elData( 4 ) );
        case 'C'
            values( 1 ) = eng2num( elData( 4 ) );
        case 'L'
            values( 1 ) = eng2num( elData( 4 ) );
        case 'D'
            I_s = convertStringsToChars( elData( 6 ) );
            I_s = eng2num( I_s( 4 : end ) );
            eta = convertStringsToChars( elData( 7 ) );
            eta = eng2num( eta( 5 : end ) );
            V_th = convertStringsToChars( elData( 8 ) );
            V_th = eng2num( V_th( 5 : end ) );
            R_s = convertStringsToChars( elData( 9 ) );
            R_s = eng2num( R_s( 4 : end) );
            R_p = convertStringsToChars( elData( 10 ) );
            R_p = eng2num( R_p( 4 : end ) );
            values = [ I_s , eta , V_th , R_s , R_p ];
        case 'Dser'
            I_s = convertStringsToChars( elData( 6 ) );
            I_s = eng2num( I_s( 4 : end ) );
            eta = convertStringsToChars( elData( 7 ) );
            eta = eng2num( eta( 5 : end ) );
            V_th = convertStringsToChars( elData( 8 ) );
            V_th = eng2num( V_th( 5 : end ) );
            R_s = convertStringsToChars( elData( 9 ) );
            R_s = eng2num( R_s( 4 : end) );
            R_p = convertStringsToChars( elData( 10 ) );
            R_p = eng2num( R_p( 4 : end ) );
            n = convertStringsToChars( elData( 11 ) );
            n = eng2num( n( 3 : end ) );
            values = [ I_s , n * eta , V_th , n * R_s , n * R_p ];
        case 'Dap'
            I_s = convertStringsToChars( elData( 6 ) );
            I_s = eng2num( I_s( 4 : end ) );
            eta = convertStringsToChars( elData( 7 ) );
            eta = eng2num( eta( 5 : end ) );
            V_th = convertStringsToChars( elData( 8 ) );
            V_th = eng2num( V_th( 5 : end ) );
            R_s = convertStringsToChars( elData( 9 ) );
            R_s = eng2num( R_s( 4 : end) );
            R_p = convertStringsToChars( elData( 10 ) );
            R_p = eng2num( R_p( 4 : end ) );
            n = convertStringsToChars( elData( 11 ) );
            n = eng2num( n( 3 : end ) );
            values = [ I_s , n * eta , V_th , n * R_s , n * R_p ];
        otherwise
            error( 'Invalid element type' );
    end
end

function [ typeNums ] = extractTypeNums( types )
    nEl = length( types );
    typeNums = zeros( nEl , 1 );
    for ii = 1 : nEl
        typeNums( ii ) = extractElTypeNum( types( ii ) );
    end
end

function [ typeNum ] = extractElTypeNum( type )
    switch type
        case 'Vin'
            typeNum = 1;
        case 'V'
            typeNum = 2;
        case 'Iin'
            typeNum = 3;
        case 'I'
            typeNum = 4;
        case 'R'
            typeNum = 5;
        case 'C'
            typeNum = 6;
        case 'L'
            typeNum = 7;
        case 'D'
            typeNum = 8;
        case 'Dser'
            typeNum = 9;
        case 'Dap'
            typeNum = 10;
        otherwise
            error( 'Invalid element type' );
    end
end

function [ A , U , K , H , alpha , beta , pos , ids ] = getMnaData( G )
    A = full( incidence( G ) );
    if ~any( G.Edges.Type == "NULL" )
        U = [ ];
        K = [ ];
        H = [ ];
    else
        A( : , G.Edges.Type == "NULL" | G.Edges.Type == "NOR" ) = [ ];
        U = - full( incidence( G ) );
        U( : , G.Edges.Type ~= "NOR" ) = [ ];
        K = - full( incidence( G ) )';
        K( G.Edges.Type ~= "NULL" , : ) = [ ];
        H = zeros( size( K , 1 ) );
    end
        idx_remove = find( G.Edges.Type == "NULL" | G.Edges.Type == "NOR" );
        G = rmedge( G , idx_remove );
        pos = find( G.Edges.Type == 'D' | G.Edges.Type == 'Dser' | G.Edges.Type == 'Dap' );
        alpha = G.Edges.EndNodes( pos , 1 );
        beta = G.Edges.EndNodes( pos , 2 );
        ids = G.Edges.ID;
end