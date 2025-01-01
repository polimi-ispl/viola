function reorderMnaData( tree , cotree )
    ids_new = [ tree.Edges.ID ; cotree.Edges.ID ];
    str = load( "Data/Output/NetlistParsing/mnaIds.mat" );
    ids_old = str.ids;
    order = zeros( length( ids_new ) , 1 );
    for ii = 1 : length( ids_new )
        order( ii ) = find( ids_old( ii ) == ids_new );
    end
    pos = str.pos;
    A = str.A;
    save( "Data/Output/NetlistParsing/mnaData.mat" , "A" , "pos" , "order" , "-append" )
end