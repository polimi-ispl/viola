function [ Tree , Cotree , outNode , potsData , tempChoice ] = netlistParse( netlist , outNode )
    if isfile( "Data/Output/NetlistParsing/mnaData.mat" )
        delete( "Data/Output/NetlistParsing/mnaData.mat" );
    end
    if isfile( "Data/Output/NetlistParsing/mnaIds.mat" )
        delete( "Data/Output/NetlistParsing/mnaIds.mat" );
    end
    [ netData , types ] = cleanNetlist( netlist );
    [ netData , potsData , types ] = handlePots( netData , types );
    [ Graph , outNode , tempChoice ] = getGraph( netData , types , outNode );
    [ Tree , Cotree ] = getTreeCotree( Graph );
end

