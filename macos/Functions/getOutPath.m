function [ outPath ] = getOutPath( tree , cotree , outNode )
    graphNodes = [ tree.Edges.EndNodes ; cotree.Edges.EndNodes ];
    graphIDs = [ tree.Edges.ID ; cotree.Edges.ID ];
    GND = min( graphNodes , [ ] , 'all' ); 
    G_aux = graph( [ tree.Edges ; cotree.Edges ] );
    [ path , ~ , outEdges ] = shortestpath( G_aux , GND , outNode + 1 );
    outEls = G_aux.Edges.ID( outEdges , : );
    outPath = zeros( length( outEls ) , 2 );
    for ii = 1 : length( outEls )
        idx_outEl = find( graphIDs == outEls( ii ) );
        endNodes = graphNodes( idx_outEl , : );
        if path( ii ) == endNodes( 1 ) && path( ii + 1 ) == endNodes( 2 )
            sgn = - 1;
        elseif path( ii + 1 ) == endNodes( 1 ) && path( ii ) == endNodes( 2 )
            sgn = 1;
        end
        outPath( ii , : ) = [ idx_outEl , sgn ];
    end
end

