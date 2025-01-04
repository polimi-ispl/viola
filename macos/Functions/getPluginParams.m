function [ typeOrder , params , potsOrder , Q , B , outPath ] = getPluginParams( Tree , Cotree , outNode , potsData , tolSLV , tolDSR )
    disp("Generating the WDF...")

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
