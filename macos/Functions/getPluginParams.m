function [ typeOrder , params , potsOrder , Q , B , outPath ] = getPluginParams( Tree , Cotree , outNode , potsData , tolSLV , tolDSR )
    if isscalar( fieldnames( Tree ) )
        tree = Tree.tree;
        cotree = Cotree.cotree;
    else
        tree = Tree.tree_V;
        cotree = Cotree.cotree_V;
    end
    typeOrder = [ tree.Edges.TypeNumber ; cotree.Edges.TypeNumber ];
    params = [ tree.Edges.Parameters ; cotree.Edges.Parameters ];
    potsOrder = getPotsOrder( tree , cotree , potsData );
    [ Q , B ] = getQB( Tree , Cotree );
    if isfile( "Data/Output/NetlistParsing/mnaData.mat" )
        reorderMnaData( tree , cotree );
    end
    outPath = getOutPath( tree, cotree , outNode );
    save( "Data/Output/NetlistParsing/parsingResults.mat" , "typeOrder" , "params" , "potsOrder" , "outPath" , "tolSLV" , "tolDSR" , "-append" );
end

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