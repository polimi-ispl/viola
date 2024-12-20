function [ potsOrder ] = getPotsOrder( tree , cotree , potsData )
    ids = [ tree.Edges.ID ; cotree.Edges.ID ];
    nPots = size( potsData , 1 );
    potsOrder = zeros( nPots , 5 );
    for ii = 1 : nPots
        switch potsData( ii , 2 )
            case "lin"
                potsOrder( ii , 2 ) = 1;
            case "log"
                potsOrder( ii , 2 ) = 2;
            case "ilog"
                potsOrder( ii , 2 ) = 3;
        end
        potsOrder( ii , 3 ) = str2double( potsData( ii , 3 ) );
        switch potsData( ii , 1 )
            case "A"
                potsOrder( ii , 1 ) = 1;
                potsOrder( ii , 4 ) = find( ids == potsData( ii , 4 ) );
            case "B"
                potsOrder( ii , 1 ) = 2;
                potsOrder( ii , 4 ) = find( potsData( ii , 4 ) == ids );
            case "AB"
                potsOrder( ii , 1 ) = 3;
                potsOrder( ii , 4 ) = find( potsData( ii , 4 ) == ids );
                potsOrder( ii , 5 ) = find( potsData( ii , 5 ) == ids );
        end
    end
    potRes = potsOrder( : , 3 );
    save( "Data\Output\NetlistParsing\parsingResults.mat" , "potRes" );
end
