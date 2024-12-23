function [ netData , types ] = cleanNetlist( netlist )
    netData = readmatrix( [ netlist , '.txt' ] , 'OutputType' , 'string' , 'Delimiter' , " " , 'Range' , 2 );
    availableTypes = [ 'V' , 'I' , 'R' , 'P' , 'C' , 'L' , 'D' , 'O' ];
    for ii = size( netData , 1 ) : - 1 : 1
        id = convertStringsToChars( netData( ii , 1 ) );
        if id( 1 ) == 'X'
            id = id( 2 : end );
            netData( ii , 1 ) = string( id );
        end
        if ~ismember( id( 1 ) , availableTypes )
            netData( ii , : ) = [ ];
        end
    end
    types = string( regexp( netData( : , 1 ) , '[A-Za-z]+' , 'match' ) );
end

