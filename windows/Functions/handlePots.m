function [ netData , potsData , types ] = handlePots( netData , types )
    ids = netData( : , 1 );
    netData( ids == "Ra" | ids == "Rb" , : ) = [ ];
    resistorsID = netData( types == "R" , 1 );
    resistorNums = str2double( string( regexp( resistorsID , '[0-9]+' , 'match' ) ) );
    resistorsCounter = max( resistorNums ) + 1;
    firstLetter = string( regexp( types , '[A-Z]+' , 'match' ) );
    netDataPots = netData( firstLetter == 'P' , : );
    potNum = str2double( string( regexp( netDataPots( : , 1 ) , '[0-9]+' , 'match' ) ) );
    [ ~ , idx ] = sortrows( potNum );
    netDataPots = netDataPots( idx , : );
    potsData = strings( 0 , 5 );
    newData = strings( 0 , size( netData , 2 ) );
    empty = strings( 1 , size( netData , 2 ) - 4 );
    for ii = 1 : size( netDataPots , 1 )
        id = netDataPots( ii , 1 ); 
        potType = string( regexp( id , '[a-z]+' , 'match' ) );
        nodes = netDataPots( ii , 2 : 4 );
        Rp = convertStringsToChars( netDataPots( ii , 7 ) );
        Rp = eng2num( Rp( 4 : end ) );
        x = convertStringsToChars( netDataPots( ii , 8 ) ); 
        x = eng2num( x( 3 : end ) );
        switch potType
            case 'lin'
                Ra = Rp * x + 10 ^ ( -6 );
                Rb = Rp * ( 1 - x ) + 10 ^ ( -6 );
            case 'log'
                Ra = 0.0125 * Rp * ( 81 ^ x - 1 ) + 10 ^ ( -6 );
                Rb = 1.0125 * Rp * ( 1 - 81 ^ ( x - 1 ) ) + 10 ^ ( -6 );
            case 'ilog'
                Ra = Rp * ( 1 + 0.0125 * ( 1 - 81 ^ ( 1 - x ) ) ) + 10 ^ ( -6 );
                Rb = 0.0125 * Rp * ( 81 ^ ( 1 - x ) - 1 ) + 10 ^ ( -6 );
            otherwise
                error( 'Invalid potentiometer type' );
        end
        if nodes( 1 ) == nodes( 2 )
            R_23_id = strcat( "R" , num2str( resistorsCounter ) );
            R_23_row = [ R_23_id , nodes( 2 ) , nodes( 3 ) , num2str( Rb ) , empty ];
            newData = [ newData ; R_23_row ];
            potRow = [ "B" , potType , num2str( Rp ) , R_23_id , " " ];
            potsData = [ potsData ; potRow ];
        elseif nodes( 2 ) == nodes( 3 )
            R_12_id = strcat( "R" , num2str( resistorsCounter ) );
            R_12_row = [ R_12_id , nodes( 1 ) , nodes( 2 ) , num2str( Ra ) , empty ];
            newData = [ newData ; R_12_row ];
            potRow = [ "A" , potType , num2str( Rp ) , R_12_id , " " ];
            potsData = [ potsData ; potRow ];
        else
            R_12_id = strcat( "R" , num2str( resistorsCounter ) );
            R_12_row = [ R_12_id , nodes( 1 ) , nodes( 2 ) , num2str( Ra ) , empty ];
            resistorsCounter = resistorsCounter + 1;
            R_23_id = strcat( "R" , num2str( resistorsCounter ) );
            R_23_row = [ R_23_id , nodes( 2 ) , nodes( 3 ) , num2str( Rb ) , empty ];
            newData = [ newData ; R_12_row ; R_23_row ];
            potRow = [ "AB" , potType , num2str( Rp ) , R_12_id , R_23_id ];
            potsData = [ potsData ; potRow ];
        end
            resistorsCounter = resistorsCounter + 1;
            netData( netData( : , 1 ) == id , : ) = [ ];
    end
    netData = [ netData ; newData ];
    types = string( regexp( netData( : , 1 ) , '[A-Za-z]+' , 'match' ) );
end